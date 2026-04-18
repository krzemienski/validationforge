---
post_id: post-05
channel: LinkedIn (native long-form post)
send_week: Week 7
word_count_target: 1800-2200
companion_repo: https://github.com/krzemienski/claude-sdk-bridge
rewrite_note: Calendar-framed rewrite, 2026-04-18. Replaces the prior source-faithful adaptation, which drifted from the master 10-week calendar narrative. This version is built from the campaign brief's Evidence-Based Shipping thesis and the personal-brand voice exemplar — not from the original blog post draft.
voice_anchor: personal-brand-launch-post.md
forbidden_phrasings: synergy, leverage, platform-as-buzzword, "I'm excited to announce", game-changer, AI-powered, "in today's fast-paced world"
---

# 5 Layers to Call an API: 4 Failed Attempts and What Polyglot Architecture Taught Me About Reliability

I needed to call one API. It took five layers, four failed attempts, and roughly thirty hours of debugging to get there. The architecture that finally worked is the architecture I would have laughed at if you had drawn it on a whiteboard.

## The job that should have taken an afternoon

The job, on paper, was small. I had a Swift app on macOS. I needed it to talk to the Claude Code SDK, get a structured response, and render it back in the UI. One language, one HTTP endpoint, one library. The kind of integration that should be a chunk of an afternoon. Maybe a long one if the auth is awkward.

It took the rest of the week.

The thing I want to write about is not the bug count. The bug count is incidental. The interesting thing is that every "obvious" architecture I tried failed, and each one failed for a structurally different reason. By the time the system was actually working, the diagram had five layers in it, and every layer was load-bearing. Every layer existed because I tried to remove it and failed.

If you do polyglot work — a Swift app calling a Python service, a Go binary embedding a Node tool, an iOS shell-out to anything — this is the failure mode you are going to hit, and the lesson I extracted is the lesson I would have wanted before I started.

## Attempt 1: just call the API directly from Swift

The first thing I tried was the obvious thing. Swift can do HTTP. The SDK has an OpenAPI surface. URLSession exists. Write the request, ship it.

What I missed was the auth model. The Claude Code SDK expects a host environment initialized through the CLI — credentials cached in a specific location, env vars the CLI sets on first run, an OAuth flow that runs interactively the first time. You do not get to skip that bootstrap and just hand the SDK a bearer token.

From a Swift app process that has never run the CLI, the auth tokens are missing in the way that makes every request fail at the auth layer before the body is even read. You can paper over it by manually setting env vars and cache files, but you are reverse-engineering the bootstrap behavior of a tool that is allowed to change. That is not a bridge. That is a brittle workaround pretending to be a bridge.

Ruled out.

## Attempt 2: shell out to a Node subprocess running the JS SDK

The second attempt was to let Node handle the SDK and just stream results back to Swift. Node has an official Claude Code SDK. The auth model is whatever the host CLI already set up. Spawn a Node child process, write a tiny script that calls the SDK, pipe the output back, parse it in Swift.

The auth problem went away. The new problem was concurrency.

The Node SDK is built around the Node event loop — NIO for I/O multiplexing, async iterators for streaming, the standard event-loop pattern throughout. Spawn it as a child process from Swift, the Node loop is alive inside the child, but Swift's RunLoop on the parent does not know how to integrate with what the child is doing. Read the pipe synchronously, you block the main thread. Wrap it in a `DispatchSourceRead`, the Node SDK's streamed-output buffering does not align with the chunk boundaries you get from the kernel pipe. You end up half-parsing JSON across reads and reconstructing event boundaries in Swift code that has no business knowing how the Node SDK frames messages.

The bridge worked until the SDK started streaming. Then everything on top of the pipe was a guess about how the other event loop was going to flush. Mismatch at the concurrency-model boundary, no clean fix from the parent side.

Ruled out.

## Attempt 3: use the Swift SDK from inside Vapor

There is a Swift port of the Claude Code SDK. Of course there is. So the next attempt was to host the bridge inside a Vapor server that the macOS app could talk to over local HTTP. Same machine, same process tree, but now the SDK is in a Swift runtime so the language barrier is gone.

The Swift SDK uses `FileHandle.readabilityHandler` for async reads from the underlying CLI process. `readabilityHandler` is built on `RunLoop`. It needs an active run loop on the thread that registered the handler to fire callbacks. Vapor, like most modern Swift server frameworks, does not run on `RunLoop`. It runs on SwiftNIO's `EventLoop`, a different model entirely. Two pieces of Apple's own infrastructure that do not interoperate.

Inside Vapor, the readability handler registers but the callbacks never fire, because there is no `RunLoop` on the EventLoop thread to drive them. The bridge silently hangs. No errors. No exception. Request comes in, handler registers, nothing happens, and you watch a request timeout with no traceable cause until you realize you are running two incompatible async runtimes in the same process and one is starving the other.

Ruled out. The fix would be to fork the SDK or host two concurrency models in one process, neither of which is a thing you want in a production bridge.

## Attempt 4: just shell out to the Claude Code CLI directly

If the SDKs are the problem, drop the SDKs. Spawn the `claude` binary as a subprocess from Swift, pass the prompt on the command line, capture stdout, parse the response. No SDK, no event-loop interoperability, no auth gymnastics. The CLI already knows how to authenticate.

This almost worked. It worked from a clean shell. It worked from a script invoked outside Claude Code. It did not work when the parent process was itself a Claude Code session.

The CLI has nesting detection. If it detects that it has been invoked from inside another Claude Code session — by checking environment variables and process ancestry — it refuses to run. The reasoning is defensible. Nested sessions can produce billing surprises, recursive token expansion, and confusing transcripts. From a tool-author perspective, refusing to nest is a reasonable default.

From a bridge-author perspective, it means the moment the Swift app is being driven from inside a Claude Code session — which is exactly the workflow I was building for — the entire bridge dies because the child detects its grandparent and refuses to start.

Ruled out. And at this point I had spent more hours on the integration than the integration was worth on its own merits, which is the moment in any project where you need to either give up or change frames.

## Attempt 5: a Python subprocess that talks NDJSON over Unix pipes

The fifth attempt is the one that worked, and it is the one that looks ugly on a diagram. The architecture is:

1. Swift app on top.
2. A small Python subprocess hosting a thin wrapper around the Python Claude Code SDK.
3. That subprocess scrubs its environment to remove the parent's nesting markers before invoking anything.
4. The Python wrapper writes responses to stdout as newline-delimited JSON.
5. Swift reads stdout via `Pipe` and `FileHandle`, splits on newlines, decodes each line as a JSON event, and dispatches it.

Five layers. Two languages. One Unix pipe. NDJSON as the wire protocol. It feels wrong. It is not wrong.

It works because every layer in the diagram is doing exactly one job, and each job is to translate between exactly two concurrency models that cannot speak to each other directly:

- Layer 1 (Swift app) speaks Swift Concurrency / RunLoop.
- Layer 2 (Pipe + FileHandle) speaks bytes. Bytes have no concurrency model. That is the whole point.
- Layer 3 (Python subprocess) speaks Python's asyncio.
- Layer 4 (Python SDK wrapper) speaks the SDK's internal event model.
- Layer 5 (Claude Code CLI, invoked by Python) speaks whatever the CLI speaks internally, but to the Python parent it is just another subprocess.

Each layer translates between exactly two concurrency models. None of them try to translate across more than one boundary at a time. That is the whole architecture. The reason every previous attempt failed is that it tried to span two or three concurrency models in a single hop, and there was no clean joint where the impedance mismatch could be absorbed.

## Why Unix pipes are the lowest common denominator

Unix pipes do not care what concurrency model you are using. A pipe is a kernel-managed byte buffer with two file descriptors hanging off it. Write from a coroutine, read from a thread, drain from an event loop — the pipe does not know and does not care. Kernel handles the buffering. Backpressure is `EAGAIN` when the writer's buffer is full and blocking reads (or `select`/`kqueue`) when the reader's is empty.

NDJSON extends the same idea one level up. Every line is a complete event. No streaming parser state across reads. Newline? Event. No newline? Accumulate and wait. No framing protocol to negotiate, no schema handshake, no version negotiation. Just lines, each a self-contained JSON object.

Pipes for transport, NDJSON for framing — the closest thing Unix has to a universal IPC mechanism that does not pin you to a specific runtime. Every language that can spawn a process can use it. Every language with a JSON parser can read it. Every concurrency model can wait on a file descriptor. No impedance mismatch, because the protocol is too primitive to have one.

## The generalizable lesson

One rule came out of this that has held up across every polyglot bridge I have built since.

**Polyglot architectures break at the concurrency-model boundary, not at the language boundary.**

A Swift call into a Python library is not hard because of syntax. It is hard because the two concurrency models are not interchangeable, and any direct binding has to pick which one wins. FFI bindings push that choice onto the caller invisibly until something blocks. Subprocesses with byte-stream protocols push it onto the kernel, which is genuinely indifferent.

When you design a bridge, the first question is not "which language on each side." It is "how many concurrency models will this layer span." If the answer is more than one, you need a translation layer at that boundary — almost always a process boundary with a byte-stream protocol on top.

This is also why microservices work in heterogeneous environments where shared libraries fail. Not because microservices are better. Because process boundaries with HTTP or NDJSON or gRPC on the wire absorb the concurrency-model mismatch in a place it cannot leak out.

## What this has to do with the rest of the work I'm shipping

I'm writing this in the same period that produced ValidationForge — the validation framework I open-sourced last week, born out of six weeks and 23,479 Claude Code sessions where agentic systems kept "succeeding" in ways that were not actually true. Agentic development at scale exposes integration failure modes that single-runtime, single-language software did not produce often enough to teach us about.

The 5-layer bridge is one shape of that. ValidationForge addresses another — the one where the agent declares completion and the system silently disagrees. Same underlying problem: confident outputs are not enough. The bridge has to actually move bytes. The verdict has to actually cite evidence.

The companion repo ships a working reference implementation: Swift → Python NDJSON bridge, env-var scrubbing, FileHandle reader, Python wrapper, small example app.

→ **github.com/krzemienski/claude-sdk-bridge**

Read it, fork it, take what you need. The interesting part is not the code. The interesting part is the diagram and why every layer in it has to be there.

## If you are building bridges like this

I am taking on a small number of advisory engagements this quarter for teams building polyglot agentic systems — the kind where a native client has to drive an AI runtime that lives in a different language ecosystem, and the integration has gotten harder than the team expected. The shape of the engagement is usually 2-4 weeks, mostly architecture review and bridge design, with one working reference implementation handed back at the end. If your team has spent more than a week on an integration that should have been an afternoon, that is the signal I would pay attention to. The fastest way to reach me is a LinkedIn DM with one paragraph on the system you are trying to bridge.

---

Five layers. Two languages. One pipe. Every layer earned its place by being the one I tried to remove and could not. If your bridge is shorter and works under load, congratulations. If your bridge is shorter and half-works, the problem is at the seam where two concurrency models are pretending to be compatible.

The companion repo has the receipts.

→ **github.com/krzemienski/claude-sdk-bridge**

---

*Nick Krzemienski — building polyglot bridges, validation frameworks, and a stubborn opinion that working systems beat elegant diagrams. github.com/krzemienski*
