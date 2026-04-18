---
channel: X / Twitter (thread)
tweet_count: 6
send_week: Week 8 — Thu Jun 11 (paired with LinkedIn excerpt + Dev.to canonical)
source_post: /Users/nick/Desktop/blog-series/posts/post-04-ios-streaming-bridge/post.md
companion_repo: https://github.com/krzemienski/claude-ios-streaming-bridge
linkedin_pair: post-04-linkedin.md
---

# Post 4 — X Thread: The Five-Layer iOS Streaming Bridge

### 1/6 — Hook

> Ten network hops per token.
>
> SwiftUI → Vapor → actor → Python subprocess → Claude CLI → Anthropic API → and back through every layer in reverse.
>
> Sounds insane. Took 4 failed architectures to discover it was the only one that worked.
>
> A streaming bridge story.

(260 chars)

### 2/6 — The four dead ends

> 1: Direct Swift API. No API key. OAuth only.
>
> 2: Node SDK subprocess. SwiftNIO + Node loops don't pump each other.
>
> 3: Swift SDK in Vapor. FileHandle needs RunLoop. NIO has EventLoop.
>
> 4: Spawn the CLI. CLAUDECODE=1 poisons the child.

(247 chars)

### 3/6 — The pattern

> Every failure was at a boundary: auth, event loop, concurrency, environment.
>
> Fix: make every boundary explicit. One layer per translation.
>
> 5 layers. Each does one job.
>
> More layers, fewer failure modes. Bugs live in exactly one place, and the boundaries name it.

(275 chars)

### 4/6 — The bug that almost killed the bridge

> Streaming appeared broken. 3 seconds of silence, then a burst of stale tokens.
>
> I was ready to scrap Python entirely and rewrite in Go.
>
> The fix was one line: sys.stdout.flush() after every write.
>
> Python block-buffers stdout by default. NDJSON expects line-buffering.

(279 chars)

### 5/6 — Process lifecycle trap

> Swift's Process deadlocks if you waitUntilExit() before draining stdout.
>
> 64KB pipe buffer fills. Process blocks. Your code blocks. Stalemate.
>
> Correct order: drain pipe, then wait for exit, then read terminationStatus.
>
> Miss it and the bridge fails only under production load.

(277 chars)

### 6/6 — Repo + LinkedIn

> Cold start: ~12s. Warm per-token overhead: <5ms against ~50ms API latency. Bridge is invisible.
>
> Full Swift Package + Python bridge: github.com/krzemienski/claude-ios-streaming-bridge
>
> Long-form on LinkedIn: [LINKEDIN_URL_PLACEHOLDER]
>
> 5 layers. Simpler than every simpler alternative I tried.

(280 chars)

---

## Posting Protocol

- **Day/time:** Thu Jun 11, post between 9:00-10:00 AM ET (matches Week 8 Thu calendar slot, after Mon Code Tales thread).
- **Pair:** LinkedIn excerpt (post-04-linkedin.md) publishes 30 min before X thread; Dev.to canonical publishes simultaneously. Replace `[LINKEDIN_URL_PLACEHOLDER]` in T6 with the live LinkedIn URL.
- **Reply boost:** Quote-tweet T1 four hours later with the architecture diagram (mermaid `graph TB` from source post, rendered as PNG) showing the 5 layers and 10 hops.
- **Engagement:** When iOS devs reply with "why not just use [X]?" — link to the specific failed-architecture section of the Dev.to canonical, not a prose response. The receipts are in the repo.
- **Cross-post:** /r/swift on Fri Jun 12 morning, title: "I built a 5-layer SSE bridge to stream Claude into SwiftUI. Here is why every 'simpler' attempt failed."
- **Forbidden in replies:** "AI-powered", "game-changer", "leverage", "synergy". Stay direct. Stay technical. The story is the architecture, not the marketing.
