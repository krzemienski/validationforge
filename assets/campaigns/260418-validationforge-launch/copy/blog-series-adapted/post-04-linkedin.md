---
channel: LinkedIn (long-form excerpt — Dev.to is primary canonical)
word_count_target: 1400-1800
send_week: Week 8 — Thu Jun 11
source_post: /Users/nick/Desktop/blog-series/posts/post-04-ios-streaming-bridge/post.md
companion_repo: https://github.com/krzemienski/claude-ios-streaming-bridge
series: Post 4 of 18 — "The Five-Layer Streaming Bridge"
importance: 7/10 — niche but deep
voice_notes: Direct, technical, war-story driven. No emojis. Hook lives in the absurdity (10 hops per token). Plant consulting line near bottom. Edit in your voice before posting.
---

# Ten network hops per token, five layers, four failed architectures — and the "complicated" solution turned out to be the only simple one

I wanted one thing. Claude streaming into a SwiftUI view, token by token. It took me four failed architectures to realize the obvious approach was structurally impossible.

This is a war story for anyone who has tried to put a Claude Code-style streaming experience inside a native iOS client and discovered that none of the SDKs were designed for it.

## The problem nobody warns you about

Claude Code has streaming. The terminal shows tokens arriving in real time. The Python SDK streams. The JavaScript SDK streams. Connecting an iOS app should be straightforward.

It is not.

Claude Code does not use API keys. It uses an OAuth session token that the CLI manages internally. You cannot import an HTTP client in Swift, hit the Anthropic API, and parse the SSE stream. The authentication boundary is fundamentally different from what an iOS developer expects, and that single fact blows up every "obvious" architecture.

I learned this the hard way across a single project: 4,241 source files, 1,563,570 lines of code, 128 `xcode_build` invocations, 2,165 `simulator_screenshot` calls. The iOS simulator became my second screen. Build, screenshot, tap, verify. Repeat thousands of times.

## Four architectures that died, in order

**Attempt 1: Direct API calls from Swift.** Import URLSession, hit the Anthropic endpoint, parse SSE. An afternoon's work.

`anthropic.AuthenticationError: No API key provided`

There is no API key to provide. The CLI manages a session token that refreshes automatically, and that token exchange is not exposed as a public interface. The API itself is not designed for direct mobile-client access. Dead end at the authentication layer.

**Attempt 2: JavaScript SDK via a Node subprocess.** Spawn Node from Swift, pipe the official JS SDK's output back. Simple IPC.

The subprocess launched. The SDK authenticated. Then silence. No output. No error. Just a hanging process consuming CPU.

SwiftNIO event loops do not pump RunLoop. Two correct runtimes that become incorrect when composed. Dead end at the event-loop layer.

**Attempt 3: Swift ClaudeCodeSDK in Vapor.** Two Swift processes, app and server, talking over localhost HTTP. The type system aligns. Should be clean.

`FileHandle.readabilityHandler needs RunLoop which NIO doesn't provide`

ClaudeCodeSDK uses Foundation's `FileHandle`, which requires a `RunLoop`. Vapor uses SwiftNIO, which provides `EventLoop`. The callbacks register, then never fire. Two Swift frameworks that are individually correct and architecturally incompatible.

**Attempt 4: Direct CLI invocation.** Shell out to the `claude` CLI from Swift. The simplest possible approach.

`Error: Claude Code cannot run inside another Claude Code instance`

The CLI checks for `CLAUDECODE=1` at startup. The parent process's environment propagates to the child. The CLI sees the variable and refuses to start. Ambient environment contamination, five levels deep. Dead end at the process-environment layer.

## The architecture that survived

After four failures, the pattern clicked. Each attempt failed at a boundary: authentication, event loop, concurrency model, or environment. The solution was to make each boundary explicit, with a dedicated layer for each translation.

Five layers, ten hops per token:

| Layer | File | Job |
|---|---|---|
| 1. Transport | `SSEClient.swift` | HTTP connection, SSE parsing, heartbeat watchdog, reconnection |
| 2. Execution | `ClaudeExecutorService.swift` | Process spawn, env sanitization, GCD stdout reading, timeouts |
| 3. Types | `StreamingTypes.swift` | StreamMessage enum, content blocks, codable conformance |
| 4. Bridge | `sdk-wrapper.py` | Claude Agent SDK async iteration, NDJSON emission, flush control |
| 5. ViewModel | `ChatViewModel.swift` | Message accumulation, text dedup, observation bindings, UI state |

The SwiftUI app sends an HTTP POST to a local Vapor server. Vapor's `ClaudeExecutorService` actor spawns a Python subprocess. Python invokes the Claude CLI with environment variables stripped. The CLI authenticates via OAuth and calls the Anthropic API. The response travels back through every layer in reverse. Five hops out, five hops back.

Every layer exists because I tried to remove it and the system broke. Remove Python and Swift cannot authenticate. Remove Vapor and the app cannot maintain a persistent SSE connection to a subprocess. Remove the StreamMessage type layer and snake_case JSON from Python crashes the Swift decoder. Remove the ViewModel and `@Observable` bindings fire on every SSE line, flooding SwiftUI with 200 re-renders per second.

> More layers meant fewer failure modes. Each layer does exactly one translation. When a bug shows up, it lives in exactly one layer, and the layer boundaries tell you which one.

## The bugs that hide in streams

Static analysis cannot catch streaming bugs. The types compile. The logic looks correct. The bug only surfaces when real tokens flow through the system at real speeds.

**Bug 1: Block-buffered stdout.** Python's subprocess stdout is block-buffered by default, not line-buffered. The bridge wrote NDJSON events to stdout, but Python's runtime held them in a 4KB buffer. Swift received nothing for seconds, then a burst of stale tokens all at once.

The user experience was terrible. No text for three seconds, then half a paragraph appearing instantaneously. The fix was one line — `sys.stdout.flush()` after every write — that took hours of debugging to find. I almost scrapped the entire Python bridge and rewrote it in Go before realizing the problem was a single missing function call. Think about that for a second. I was ready to throw away an entire architecture layer over a buffer flush.

**Bug 2: Text duplication.** The assistant was saying everything twice. "Hello, how can I help you?" rendered as "Hello, how can I help you?Hello, how can I help you?".

Each `assistant` event in Claude's streaming protocol contains the **accumulated** text so far, not a delta. Append (`+=`) is wrong. Assignment (`=`) is right. But streamEvent deltas work the opposite way — each contains only the new characters since the last delta. Two event types, opposite semantics, same data shape. The type system in `StreamingTypes.swift` separates them at the enum level so the developer cannot get this wrong silently.

**Bug 3: Environment contamination.** The `CLAUDECODE=1` problem from attempt four persisted into the working bridge. Vapor inherited the parent environment, passed it to the actor, which passed it to the Python subprocess, which passed it to the CLI. Five layers deep, and the variable from the outermost process still poisoned the innermost one.

The fix is belt-and-suspenders: strip Claude variables in the shell command AND in `Process.environment`. Without both, the entire bridge fails silently on the last hop. No error message. No stderr output. Just a zero-byte response and a confused developer staring at process exit code 1.

## The process lifecycle trap

Swift's `Process` class has a subtle but devastating API design issue.

When you read from a process's stdout pipe and reach EOF, the natural assumption is that the process has exited. It has not. There is a race condition between the pipe closing and the process terminating. Read `process.terminationStatus` before the process has actually exited and Foundation throws `NSInvalidArgumentException` — a runtime crash, not a compiler error.

But there is a second trap inside `waitUntilExit()`. If the subprocess writes more than 64KB to its stdout pipe before you drain it, the pipe buffer fills. The process blocks waiting for the pipe to drain. Your code blocks on `waitUntilExit()` waiting for the process to finish. Deadlock. Neither side can proceed.

The only correct order is: drain the pipe first, wait for exit second, read termination status third. The `ClaudeExecutorService` handles this by reading stdout on a dedicated GCD queue that drains continuously. Miss either constraint and the bridge fails intermittently under load — the worst kind of failure, because it passes every check during development and only surfaces in production.

## Two-tier timeouts because one is not enough

Streaming creates a timeout problem that request-response architectures do not have. How long is too long to wait? A deadlocked process produces no output. A legitimate large response produces output continuously for minutes. A single timeout cannot tell the difference.

The bridge uses two independent timeouts. **Initial timeout (30 seconds)** fires if zero bytes arrive on stdout after process launch — catches a stuck CLI from authentication failure or environment contamination. The first chunk of data cancels it. **Total timeout (5 minutes)** fires regardless of output — catches runaway processes producing output that will never finish.

Both implemented as `DispatchWorkItem` instances on a global queue, which avoids any RunLoop dependency. Critical for Vapor/NIO compatibility, where the wrong concurrency primitive produced two of my four failed architectures.

## Performance: what ten hops actually cost

The first question everyone asks. Does five layers kill performance?

Cold start is painful — about 12 seconds. Python interpreter initialization, SDK import, CLI authentication. But the warm path is fast. Per-token overhead of the bridge runs under 5 milliseconds, against typical Anthropic API latency of 45-50ms per token. The bridge is under 10% of total latency once warm. Effectively invisible.

Architectural overhead matters at connection time, not at streaming time. Users tolerate a slow initial connection if subsequent streaming feels instantaneous. The SSEClient shows "Connecting..." during cold start and "Taking longer than expected..." after 5 seconds, which sets expectations correctly. The perceived experience is what matters.

## What this taught me

The streaming bridge was the foundation that made everything else work. Without reliable token-by-token streaming, the iOS client was just a request-response interface — type a message, wait, see the complete response. With streaming, users read the first sentence while Claude is still generating the tenth. Perceived latency drops from 15 seconds (full response time) to under 1 second (first token time). Same underlying speed. Completely different product.

Seven hard-won patterns for anyone building a streaming bridge:

1. Flush stdout. Every language buffers process output by default.
2. Distinguish accumulated from incremental in your protocol. Document it. Enforce it in types.
3. Strip inherited environment variables. Belt-and-suspenders, both shell and Process API.
4. Drain pipes before waiting for exit. Read first, wait second, read status third.
5. Use two-tier timeouts. Stuck processes and long processes need different strategies.
6. Cancel SSE on background. Do not try to be clever about iOS background networking.
7. Use `OSAllocatedUnfairLock` on hot paths. Actor hops are safe but slow per-token.

This is the same six weeks that produced ValidationForge. The pattern in both projects is the same: every "obvious" approach failed because it tried to skip a boundary, and the working solution was the one that made every boundary explicit. In the streaming bridge it was authentication, event loop, concurrency, environment. In ValidationForge it was the boundary between "the agent says it works" and "the running system shows it works." Both took longer than I expected. Both produced architectures that look more complicated than they are.

The companion repo has the complete Swift Package: `SSEClient`, `ClaudeExecutorService`, `StreamingTypes`, and the Python `sdk-wrapper.py` bridge. Add via SPM, point at your backend, get token-by-token streaming from Claude into SwiftUI.

→ **github.com/krzemienski/claude-ios-streaming-bridge**

## What I am open to

If your team is building a native client on top of an LLM streaming protocol — iOS, Android, anywhere — and you are seeing the kind of intermittent failures that pass every CI gate and only surface in production, I am taking on a small number of advisory engagements this quarter. The shape that fits best is engineering leadership at a 50 to 500 person organization, four to eight weeks, mix of strategy and hands-on implementation. LinkedIn DM with a one-paragraph note on where you are now and where you would like to be in 90 days. I respond within two business days.

Five layers. Ten hops per token. Simpler than every "simpler" alternative I tried.

---

*Nick Krzemienski — building things that look more complicated than they are because the simpler versions did not work. claude-ios-streaming-bridge is on GitHub at github.com/krzemienski/claude-ios-streaming-bridge. ValidationForge is at github.com/krzemienski/validationforge.*
