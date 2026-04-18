---
post_id: post-05
channel: X / Twitter (thread)
send_week: Week 7
tweet_count: 6
companion_repo: https://github.com/krzemienski/claude-sdk-bridge
rewrite_note: Calendar-framed rewrite, 2026-04-18. Built from the campaign narrative, not from the prior source-faithful draft.
voice_anchor: personal-brand-launch-post.md
---

# Post 5 — X Thread (6 tweets)

### 1/6 — Hook

> I needed to call one API. It took five layers, four failed attempts, and roughly thirty hours of debugging to get there.
>
> The architecture that finally worked is the one I would have laughed at on a whiteboard.

(229 chars)

### 2/6 — The four attempts

> Swift app → Claude Code SDK. Should be an afternoon. Was a week.
>
> 1: Direct from Swift. Auth model needs the CLI bootstrap.
> 2: Node subprocess. Concurrency mismatch (NIO vs Swift RunLoop).
> 3: Swift SDK in Vapor. readabilityHandler needs RunLoop. EventLoop ≠ RunLoop.

(263 chars)

### 3/6 — Attempt 4 (the one that almost worked)

> 4: Shell out to the Claude Code CLI directly.
>
> Worked from a clean shell. Did not work from inside a Claude Code session.
>
> The CLI has nesting detection. It refuses to run when its grandparent is itself.
>
> Defensible default. Killed my bridge.

(244 chars)

### 4/6 — Attempt 5 (the one that worked)

> Python subprocess that scrubs the parent's env vars, hosts the Python SDK, writes NDJSON to stdout. Swift reads the pipe, splits on newlines, decodes each line.
>
> Five layers. Two languages. One Unix pipe. NDJSON as the wire format.
>
> It is ugly. It works.

(259 chars)

### 5/6 — The lesson

> Polyglot architectures break at the concurrency-model boundary, not the language boundary.
>
> Swift Concurrency, Node NIO, Vapor EventLoop, Python asyncio — none of these speak to each other directly.
>
> Pipes + NDJSON are the lowest common denominator. The kernel does not care.

(275 chars)

### 6/6 — Repo + LinkedIn

> Every layer in my bridge exists because I tried to remove it and failed.
>
> Working reference implementation (Swift → Python NDJSON bridge, env scrubbing, FileHandle reader):
> github.com/krzemienski/claude-sdk-bridge
>
> Long version: [LINKEDIN_URL]

(245 chars — incl. 23 for repo URL + 23 for LinkedIn placeholder)

---

## Posting Protocol

1. **Time:** Tuesday or Wednesday, 9:30-10:30am ET. Engineering audience is on X mid-morning weekday.
2. **Reply chain:** Post all six tweets as a single thread, no gap longer than 10 seconds between posts so the algorithm batches them.
3. **First reply:** Pin a follow-up reply to T6 with the same repo URL as a clickable card preview. X downranks links inside the main thread; the reply gets the card.
4. **Quote-tweet seed:** Have one or two trusted peers quote-tweet T1 with their own one-liner reaction (not a generic "great thread"). Quote-tweets boost reach harder than retweets right now.
5. **Reply discipline:** First 30 minutes is the engagement window. Respond to every reply with one substantive sentence. Do not link out from replies — keep readers on the thread.
6. **Do not edit T1.** Edits reset the impression count on most clients.
7. **Companion drop:** ~6 hours later, post a single standalone tweet with the diagram screenshot of the 5-layer bridge and a one-line caption: *"Every layer earned its place by being the one I tried to remove and could not."* Do not link the thread; let people find it.

---

*Companion repo: github.com/krzemienski/claude-sdk-bridge*
*Long-form version: LinkedIn (Week 7, slot 1)*
