---
channel: X / Twitter
thread_length: 10 tweets
send_week: Week 6 — Mon May 26, 2026 (companion to LinkedIn long-form)
source_post: /Users/nick/Desktop/blog-series/posts/post-01-series-launch/post.md
companion_repo: https://github.com/krzemienski/agentic-development-guide
linkedin_url_placeholder: {LINKEDIN_URL}
voice: Direct. Technical. Slightly contrarian. No emojis. No hashtags.
---

### 1/10 — credibility hook

> 23,479 AI coding sessions in 42 days.
>
> 3,474,754 lines of interaction data.
> 27 projects.
> 14 companion repos.
>
> Here is the pattern I did not expect to find.

(168 chars)

---

### 2/10 — the inversion

> Agents are not generators.
>
> They are readers that occasionally write.
>
> Read-to-Write ratio across the dataset: 9.6 to 1.
>
> For every file an agent writes, it reads nearly ten.

(172 chars)

---

### 3/10 — the tool leaderboard

> What agents actually do with their time:
>
> Read: 87,152
> Bash: 82,552
> Grep: 21,821
> Edit: 19,979
>
> 79% of tool calls are understanding code.
> 11% are changing it.
>
> The thesis of the entire series.

(207 chars)

---

### 4/10 — failure mode 1

> Amnesia.
>
> One agent introduced the same SwiftUI retain cycle three times across three weeks.
>
> Built an SQLite-backed observation store with semantic search.
>
> Repeated mistakes dropped 73%.

(186 chars)

---

### 5/10 — failure mode 2

> Completion theater.
>
> Delete Account button. Correct icon. Correct dialog. Correct spinner.
>
> Function body: a TODO comment.
>
> Every automated check passed.
>
> Hooks now block this. 642 fires in the dataset.

(208 chars)

---

### 6/10 — failure mode 3

> Wrong model for the job.
>
> Opus to fix a typo. Haiku to design a schema.
>
> Routing by complexity (Haiku lookups, Sonnet implementation, Opus architecture) cut costs 82%.
>
> Three rules. No ML. No classifier.

(214 chars)

---

### 7/10 — emergent orchestration

> 4,534 sessions I started.
> 18,945 spawned by other agents.
>
> 81% of all sessions were agents spawning agents.
>
> I did not design that. It emerged because single-agent workflows kept hitting the failure modes.

(213 chars)

---

### 8/10 — what survived

> Four patterns survived contact with real codebases:
>
> 1. Consensus gates ($0.15 each)
> 2. Functional validation (no mocks ever)
> 3. Fresh context over accumulated context
> 4. Filesystem as persistence layer
>
> Everything else was a good idea that did not hold up.

(263 chars)

---

### 9/10 — the receipt

> One project: 4,241 sessions. 149 Swift files. 24 screens. 13 themes. macOS companion.
>
> Total Claude API cost: ~$380.
>
> That number only works because of routing. All-Opus would have been $8.40 per 26 invocations vs $1.52 routed.

(231 chars)

---

### 10/10 — the close

> 18 posts. Every claim traced to a real session. Every system has a working companion repo.
>
> Series hub: github.com/krzemienski/agentic-development-guide
>
> Long-form on LinkedIn: {LINKEDIN_URL}

(195 chars)

---

## Posting Protocol

- **Day:** Monday May 26, 2026 — same morning as LinkedIn long-form drops (8:30am ET on LinkedIn, X thread launches 9:30am ET so the LI post has time to seed engagement before it gets X-amplified)
- **Format:** post T1 as a standalone tweet, then reply-thread T2-T10. T10 contains both the repo URL and the LinkedIn permalink (replace `{LINKEDIN_URL}`)
- **Pin:** pin T1 for 7 days; replace existing pinned thread on Monday morning
- **First-2-hour discipline:** reply within 15 minutes to every quote-tweet and substantive reply for the first 2 hours; X algo weights early engagement velocity heavily
- **Asset:** attach the existing hero PNG from `~/Desktop/blog-series/posts/post-01-series-launch/assets/` to T1 only (1200x628 Twitter card spec). Do not attach images to T2-T10 — kills thread reach
- **Cross-link discipline:** the LinkedIn URL goes in T10 only, not T1. Putting the LI link in T1 caps reach at the truncation point
- **Mute words to monitor:** "AI hype," "vibe coding," "just use Cursor" — engage if substantive, ignore if noise
- **Followup:** Tuesday morning reply-quote a single substantive critic with a data citation. This signals "real account, real receipts" to the algo and to humans
