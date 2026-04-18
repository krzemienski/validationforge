---
channel: X / Twitter
thread_length: 8 tweets
send_week: Week 6 — Thu May 29, 2026 (companion to LinkedIn long-form)
source_post: /Users/nick/Desktop/blog-series/posts/post-07-prompt-engineering-stack/post.md
companion_repo: https://github.com/krzemienski/shannon-framework
linkedin_url_placeholder: {LINKEDIN_URL}
voice: Direct. Technical. Slightly contrarian. No emojis. No hashtags.
note: 8 tweets — opener hook, 5 layer/hook highlights, the receipt, the close. Cleaner than 1-tweet-per-layer (would be 9 + filler).
---

### 1/8 — credibility hook

> 14 rules in my CLAUDE.md.
>
> The agent followed 11.
>
> The other 3:
> 47 test files created despite a clear ban.
> 112 edits to files it never read.
> 63 fake "complete" claims.
>
> Writing better rules does not fix this.

(220 chars)

---

### 2/8 — the diagnosis

> The agent understands every rule. It can recite them.
>
> Then 11 tool calls deep, with 30K tokens of context competing, those rules lose salience.
>
> A single-layer system cannot maintain discipline across a long session.
>
> You need a stack.

(252 chars)

---

### 3/8 — the principle

> Borrowed from Claude Shannon: reliable communication over a noisy channel needs redundant encoding.
>
> An LLM context window is a noisy channel.
>
> Say the same thing 7 ways through 7 mechanisms. The message gets through.

(229 chars)

---

### 4/8 — the stack

> 7 layers, each reinforcing the same rules:
>
> 1. Global CLAUDE.md
> 2. Rules directory (.claude/rules/*.md)
> 3. Hooks (block / warn / remind)
> 4. Skills (structured workflows)
> 5. Agents (specialized roles)
> 6. MCP tools (interface constraints)
> 7. Session-start hooks

(279 chars)

---

### 5/8 — the killer hook

> block-test-files.js dropped test file creation from a 23% violation rate to 0%.
>
> 50 lines of deterministic JavaScript. Checks the filename. Returns block or allow.
>
> No LLM cost. No judgment calls. The agent literally cannot write the file.

(248 chars)

---

### 6/8 — what works, what does not

> I built 23 hooks. 5 survived.
>
> Pattern: if the violation is detectable from tool inputs alone, a hook works.
>
> Filename pattern: yes.
> "Function should be under 50 lines": no.
>
> Hooks enforce safety invariants, not style preferences.

(253 chars)

---

### 7/8 — the receipt

> Aggregate violation rate across 23,479 sessions: 3.1 per session → 0.4 per session.
>
> 87% reduction.
>
> CLAUDE.md alone: 60% compliance.
> Hooks alone: 75%.
> Skills alone: 80%.
> All 7 layers: 95%+.

(208 chars)

---

### 8/8 — the close

> Every hook + skill in this post is in the repo. Drop into .claude/.
>
> Start with 3 hooks: block-test-files, read-before-edit, validation-not-compilation.
>
> Repo: github.com/krzemienski/shannon-framework
> Long-form: {LINKEDIN_URL}

(238 chars)

---

## Posting Protocol

- **Day:** Thursday May 29, 2026 — same morning as LinkedIn long-form (8:30am ET on LinkedIn, X thread 9:30am ET to let LI seed first)
- **Format:** T1 standalone, T2-T8 reply-threaded. T8 contains both the repo URL and the LinkedIn permalink (replace `{LINKEDIN_URL}`)
- **Pin:** rotate the pin from Monday's Post 1 thread to this one Thursday morning
- **Asset:** attach the existing hero PNG from `~/Desktop/blog-series/posts/post-07-prompt-engineering-stack/assets/` to T1 only. The 7-layer Mermaid diagram from the source post can also be attached to T4 as a static PNG export — it is the most screenshot-worthy artifact in the thread
- **Code snippet handling:** the `block-test-files.js` snippet does not fit in T5 verbatim — the prose summary above is the X-native version. If a reader asks for the code, reply with a screenshot of lines 127-167 from the source post and link to the file in the shannon-framework repo
- **Engagement targets:** this thread is the most "shippable" piece in the series — the readers most likely to quote-tweet are people who already use Claude Code daily. Reply within 15 minutes for the first 2 hours
- **Followup:** Friday morning reply-quote one of the engineers who shares it with their own war story. Real practitioners citing each other carries more weight than any growth tactic
- **Do not:** do not lead with the repo URL in T1. Reach gets capped at the link-truncation point. The repo goes in T8 only
