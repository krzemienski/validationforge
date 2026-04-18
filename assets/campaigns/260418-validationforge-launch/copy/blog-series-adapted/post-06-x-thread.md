---
post_id: post-06
channel: X / Twitter (thread)
send_week: Week 7
tweet_count: 6
companion_repo: https://github.com/krzemienski/auto-claude-worktrees
rewrite_note: Calendar-framed rewrite, 2026-04-18. Built from the campaign narrative, not from the prior source-faithful draft. Contains zero dollar figures — the prior version contained an unverified $380 number that the user flagged.
voice_anchor: personal-brand-launch-post.md
---

# Post 6 — X Thread (6 tweets)

### 1/6 — Hook

> I gave an AI 194 tasks, 194 isolated copies of a codebase, and told it to build.
>
> The execution agents were not the hard part.
>
> The QA pipeline was.

(150 chars)

### 2/6 — The setup

> Five-stage pipeline:
> 1. Ideation — normalize the backlog
> 2. Spec gen — concrete acceptance criteria
> 3. Worktree spawn — 194 git worktrees, 194 Claude Code sessions
> 4. QA review — diff vs spec, verdict written
> 5. Merge queue — topological sort by file overlap
>
> Ran overnight.

(275 chars)

### 3/6 — The signal

> First-pass QA rejection rate: ~23%.
>
> That number is the entire interesting finding.
>
> Anyone can run 194 agents in parallel. The question is what fraction of their output is mergeable.
>
> The answer is decided upstream of any execution agent.

(245 chars)

### 4/6 — Spec quality determined everything

> Tasks with 5+ concrete acceptance criteria → ~90% success.
> Tasks with 2 or fewer vague criteria → under 50%.
>
> Same model. Same infra. Same QA agent.
>
> The variance was almost entirely in how well the input was specified.

(228 chars)

### 5/6 — The reframe

> The execution agents were commodity. The differentiating components were:
>
> - Spec generator (upstream — decides everything)
> - QA reviewer (downstream — catches what the spec missed)
> - Merge queue with topo sort (prevents cascading conflicts)
>
> Model is not the bottleneck.

(275 chars)

### 6/6 — Repo + LinkedIn

> Open-source: the 5-stage pipeline, worktree orchestration, QA verdict schema, topological merge queue, per-task telemetry so you can compute your own cost numbers.
>
> Repo: github.com/krzemienski/auto-claude-worktrees
> Long version: [LINKEDIN_URL]

(254 chars — incl. 23 for repo URL + 23 for LinkedIn placeholder)

---

## Posting Protocol

1. **Time:** Thursday or Friday, 9:30-10:30am ET. Engineering audience leans in late-week for "weekend reading" content; this thread reads as a writeup, not breaking news.
2. **Reply chain:** Post all six tweets as a single thread, no gap longer than 10 seconds between posts so the algorithm batches them.
3. **First reply:** Pin a follow-up reply to T6 with the repo URL as a clickable card preview. X downranks links inside the main thread; the reply gets the card.
4. **No dollar number ever.** If anyone asks "how much did it cost," reply with "depends on model pricing, retry rate, and cache hit ratio in your environment — the repo logs per-task tokens and time so you can compute it for your run." Do not extrapolate.
5. **Quote-tweet seed:** Have one or two trusted peers quote-tweet T1 with a one-liner reaction (not a generic "great thread"). Quote-tweets boost reach harder than retweets right now.
6. **Reply discipline:** First 30 minutes is the engagement window. Respond to every reply with one substantive sentence. Bait the "but does it actually work" replies into the repo, not into a debate.
7. **Do not edit T1.** Edits reset the impression count on most clients.
8. **Companion drop:** ~6 hours later, post a single standalone tweet with a screenshot of the QA-rejection-rate breakdown by spec quality. Caption: *"This is the chart. The model is not the bottleneck."* No link. Let people find the thread.

---

*Companion repo: github.com/krzemienski/auto-claude-worktrees*
*Long-form version: LinkedIn (Week 7, slot 2)*
