# X/Twitter Thread — Post 2: Three Agents Found The P2 Bug

**Send:** Mon May 18, 8:30am ET (paired with LinkedIn long-form drop)
**Length:** 8 tweets
**Companion repo:** github.com/krzemienski/multi-agent-consensus

---

### 1/8 — Hook (credibility + bug)

> A single AI agent reviewed my iOS streaming code and said "looks correct."
>
> Three agents found a P2 bug on line 926 that had been corrupting messages for 3 days.
>
> The fix isn't a smarter agent. It's three agents that disagree until they converge.

Char count: 268

---

### 2/8 — The actual bug

> Line 926:
>
> message.text += textBlock.text
>
> Should have been =, not +=.
>
> Each Claude API block contains the FULL message so far, not a delta. So += doubled everything.
>
> "Hello" became "HHeHelHello." Five sentences became an unreadable wall.

Char count: 252

---

### 3/8 — Why solo review missed it

> Solo agent review: "looks correct."
>
> Types valid. Function signatures match. Protocol conformance complete. Everything a single-pass review checks came back clean.
>
> When the same entity writes AND reviews code, you get a review that shares the bug's blind spots.

Char count: 272

---

### 4/8 — Three roles, not three copies

> Same prompt three times = three copies of the same blind spot.
>
> Lead = architecture & consistency
> Alpha = line-by-line logic
> Bravo = runtime behavior
>
> Different mandates. Different failure domains. Different lenses on the same code.

Char count: 248

---

### 5/8 — The Frankenstein merge

> Two agents on one backend.
> A built JWT verification.
> B built the REST endpoints.
> Neither knew the other existed.
>
> Result: raw JWT internals served as a public REST endpoint. Token payloads exposed to unauthenticated callers.
>
> Compiled clean. Linter happy. Catastrophic.

Char count: 280

---

### 6/8 — The economics

> Unanimous voting. Any agent raises a concern, gate blocks.
>
> False positive (re-review valid code): 5 min, $0.15.
> False negative (ship the += bug): 3 days of corrupted messages.
>
> Every design choice leans toward the first failure mode.

Char count: 244

---

### 7/8 — What 200 gates taught me

> After 200 gates:
> - Alpha: 47 bug patterns
> - Bravo: 31
> - Lead: 22
>
> Every caught bug becomes 6 lines in the agent's prompt. Permanent. Version-controlled. Free.
>
> The prompts compound. After 200 gates the system catches things gate 1 missed.

Char count: 256

---

### 8/8 — Repo + LinkedIn

> Full breakdown: the gate code, the role definitions, the streaming audit example with the exact JSON output that caught the += bug.
>
> Repo: https://github.com/krzemienski/multi-agent-consensus
>
> LinkedIn long-form: [LinkedIn URL — fill at post time]

Char count: 188 (URL counts as 23 each)

---

## Posting Protocol

**Best send time:** Mon May 18, 8:30am ET. Aligns with LinkedIn drop and US East Coast morning attention.

**Pin recommendation:** Pin tweet 1 of this thread for the full week. The "+=" hook outperforms generic credibility hooks in the engagement data we have so far.

**Engagement window:** First 2 hours are critical. Reply to every quote-tweet and substantive reply within that window. The algorithm rewards thread authors who keep conversations live.

**Cross-link strategy:** When the LinkedIn URL is live, paste it as a reply to tweet 8 (not in the main tweet body) so the link preview does not fight the thread aesthetic.

**Companion media:** If posting with a screenshot, use the actual gate JSON output from `examples/streaming-audit/gate2-result.json` in the repo, not a mockup. The credibility comes from real terminal output.

**Reply hooks for engagement:** Tweets 2 (the actual bug) and 5 (Frankenstein merge) are the most quote-tweet-able. Engineers who have shipped a `+=` bug will say so. Engineers who have shipped an auth bug will say so. Lean into both.

**Do not reply with:** "thanks!" "appreciate it!" — the algorithm penalizes empty replies. Reply with a follow-up insight or a sharper version of the same point.
