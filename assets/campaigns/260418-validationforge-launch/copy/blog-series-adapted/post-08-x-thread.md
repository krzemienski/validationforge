---
title: "Ralph Orchestrator: 28 Tasks Done While I Slept"
channel: X / Twitter
companion_blog_post: 8 of 18
companion_repo: github.com/krzemienski/ralph-orchestrator-guide
total_tweets: 8
voice_notes: Lead with the 1:47 AM Telegram-from-bed story. Direct, technical, slightly contrarian. No emojis.
---

### 1/8 — The hook

> 1:47 AM. From under the covers, I sent one Telegram message:
>
> "Wrap the existing code, don't replace it."
>
> Rolled over. Went back to sleep.
>
> By morning, my agent had finished 28 of 30 tasks. Autonomously. For about $4.
>
> Here's how Ralph works.

(264 chars)

### 2/8 — The problem

> Three hours into an API migration, the context window filled.
>
> New session. Same agent. Re-implemented an endpoint it had already finished.
>
> Across one project: 5 hours of agent time lost to context degradation. The plan written at token 5,000 was invisible by token 120,000.

(279 chars)

### 3/8 — The insight

> The 150K context window isn't a luxury. It's a trap.
>
> The fix wasn't a bigger window.
>
> It was moving the agent's work artifacts off the context window and onto the filesystem. Plans as files. Tasks as JSON. Events appended to a log.
>
> Memory is disk, not chat history.

(272 chars)

### 4/8 — One hat, one event, then stop

> Borrowed from de Bono's Six Thinking Hats. Each agent session wears exactly one hat:
>
> Planner. Builder. Reviewer. Fixer. Verifier. Writer.
>
> A hat does its job, emits one event, and terminates. The orchestrator decides what comes next.
>
> The agent doesn't decide when to stop.

(279 chars)

### 5/8 — The data that convinced me

> Hat-scoped sessions (40K tokens):
> 94% completion. 2% contradiction rate.
>
> Monolithic sessions (150K tokens):
> 67% completion. 34% contradictions.
>
> One in three monolithic sessions: agent argued with itself. Approving code that violated rules it had just written.

(264 chars)

### 6/8 — Why separation works

> A Builder reviewing its own code passed every check. Of course it did.
>
> A Reviewer hat in a separate session — same model, no shared context — found 6 issues.
>
> Critical distance only exists where there is no shared memory.

(245 chars)

### 7/8 — The cost

> The 28-of-30 overnight run:
>
> 5 Planner calls
> 30 Builder calls
> 28 Reviewer calls
> 4 Fixer cycles
> 2 ambiguous specs (failed)
>
> Total: ~$4.20 for 28 tasks.
>
> $0.15 per completed task. 7 hours autonomous. I slept through it.
>
> The work was actually correct.

(266 chars)

### 8/8 — Repo + full post

> Hat rotation orchestrator, convergence detection, runnable simulations, the six tenets — all in the companion repo.
>
> Repo: github.com/krzemienski/ralph-orchestrator-guide
>
> Full post (8 of 18 on agentic dev at scale): [LINKEDIN_URL]

(244 chars, with two URLs at 23 each)

---

## Posting Protocol

**Cadence:** post all 8 tweets as a single thread. Reply-chain, not standalone posts.

**Visual attachments — recommended but not mandatory.** This thread is text-led (the Telegram story is the hook, not an image). Optional attachments from `~/Desktop/blog-series/posts/post-08-ralph-orchestrator/assets/`:

| Tweet | Optional visual |
|---|---|
| 1/8 | Screenshot of the actual Telegram thread (redact phone metadata) |
| 4/8 | `post8-hat-system.svg` rendered as PNG |
| 5/8 | Bar chart of the 94% vs 67% completion numbers (build from `post8-iteration-loop.svg` or hand-roll) |
| 6/8 | `post8-ralph-architecture.svg` rendered as PNG |
| 7/8 | Screenshot of the actual cost breakdown from billing dashboard (redact account info) |
| 8/8 | `linkedin-card.html` rendered, OR `twitter-card.html` rendered |

**SVG → PNG:** X does not render SVG inline. Pre-render to PNG at 1600x900 minimum.

**The Telegram screenshot in 1/8 is the highest-leverage attachment.** A real screenshot of "1:47 AM" with the actual `/guidance` command is the single visual that sells the thread. If you only attach one image, attach that.

**URL placeholder:** replace `[LINKEDIN_URL]` in tweet 8 with the live LinkedIn post URL after the LinkedIn version goes up. Post the LinkedIn version 30-60 minutes before the X thread.

**Best posting window:** Thu Jun 18, 9:30am ET (cross-references the LinkedIn post that goes up Thu morning). HN submission goes up the same morning at 8:30am ET — submit, then post the X thread an hour later so HN traffic and X traffic don't compete for engagement attention.

**Engagement:** quote-tweet 1/8 from your own account 24 hours later with one observation about how the overnight run pattern generalizes (or doesn't) for the replies you got. Do not boost your own thread without adding new signal.

**Cross-post candidates:** the same content shape works as a r/rust submission (architecture-focused) and an HN Show-HN-style submission (focus on the cost number and the autonomy outcome, not the hat metaphor — HN has metaphor allergy).
