# X / Twitter Copy: 14-Day Drumbeat

All copy is **draft-ready**. Edit in voice before posting. Each post is timestamped to the planned send slot. Replace `{LINK}` with the live repo URL or sub-path before sending.

Naming: **D{n}-{slot}** = Day n, send slot (am/pm/eve).

---

## D1 — Sat Apr 18

### D1-am (9:00am ET) — Tease
> Two weeks. $0 spend. One question:
>
> Can a Claude Code plugin earn 100 GitHub stars by proving every claim with cited evidence?
>
> Starting now. Watch this thread.
>
> {LINK: github.com/krzemienski/validationforge}

### D1-pm (1:00pm ET) — Repo polish announcement
> Spent the morning getting the repo ready for launch:
> – README polished
> – Demo GIF re-rendered (10s loop, no music)
> – self-validation evidence directory committed
> – install instructions verified end-to-end
>
> Tomorrow: the receipts.

### D1-eve (7:30pm ET) — Hook seed
> "Build passing" is not the same as "feature working."
>
> AI assistants ship code at 100x speed. Validation hasn't moved. We've made "it compiled" the quality bar.
>
> That's compilation theater. There's a better gate.

---

## D2 — Sun Apr 19

### D2-am (9:00am ET) — The first receipt
> Ran ValidationForge against itself.
>
> Result: 6/6 journeys PASS. 13/13 criteria. 0 fix attempts.
>
> The full e2e-evidence directory is committed to the repo. No screenshots, no fakes — just the real artifacts.
>
> {LINK: github.com/krzemienski/validationforge/tree/main/e2e-evidence/self-validation}

### D2-pm (1:00pm ET) — One specific receipt
> One file from yesterday's self-validation:
>
> `e2e-evidence/self-validation/journey-3/step-04-curl-response.json`
>
> The verdict cites this exact path. You can read the response body and judge the PASS yourself.
>
> That's the bar.

---

## D3 — Mon Apr 20

### D3-am (9:00am ET) — BIG THREAD (8 tweets)

**1/8**
> I shipped 3.4M lines of AI-generated code across 27 projects in 42 days.
>
> Every single one passed unit tests.
>
> At least 5 shipped with bugs unit tests literally cannot catch.
>
> Here's what I built to fix that. 🧵

**2/8**
> Pattern 1: API field rename.
>
> Mock returns `users`. Real API returns `data`. Test passes. Frontend crashes.
>
> The mock never knew the contract changed.

**3/8**
> Pattern 2: JWT expiry reduced 60min → 15min.
>
> Mock skips time. Token-refresh logic never tested under real expiry. Ships broken.

**4/8**
> Pattern 3: iOS deep link after nav refactor.
>
> Mock URL handler "works." `simctl openurl` opens the wrong screen.
>
> User-facing bug. Zero test signal.

**5/8**
> Pattern 4: DB migration on real data with duplicate emails.
>
> Mock DB has clean data. Migration "succeeds." Real migration fails on dupes. Production rollback.

**6/8**
> Pattern 5: CSS grid overflow on small screens.
>
> Mocks don't render. JSDOM doesn't paint. Component "tests" pass. Real Playwright screenshot shows the overflow.

**7/8**
> Common thread: mocks drift from reality.
>
> Build passing ≠ feature working.
>
> So I built ValidationForge — a Claude Code plugin that BLOCKS test/mock file creation in src/ and forces validation through real interfaces. curl the actual API. Boot the actual simulator. Capture real screenshots.

**8/8**
> Then it makes Claude write a verdict. PASS or FAIL. Each verdict cites specific evidence — file path, exact log line, exact HTTP response.
>
> Self-validated 6/6 PASS. Free, MIT, install in Claude Code:
>
> `/plugin marketplace add krzemienski/validationforge`
>
> {LINK: github.com/krzemienski/validationforge}

### D3-eve (7:30pm ET) — Discord drop announcement
> Just dropped ValidationForge in:
> – Anthropic Discord #showcase
> – OMC server
> – Superpowers community
>
> If you're in any of those — would love your eyes. Especially the integration guides for OMC and Superpowers.

---

## D4 — Tue Apr 21

### D4-am (9:00am ET) — r/ClaudeAI drop announcement
> Posted on r/ClaudeAI:
>
> "I built a plugin that blocks Claude from creating mock files. 6/6 self-validation PASS."
>
> Reading every comment for the next 4 hours. Bring the hard questions.
>
> {LINK to Reddit post}

### D4-pm (1:00pm ET) — Receipt of the day
> Today's receipt: ran `/validate` against a real OSS Next.js project (anonymized).
>
> Result: 4/5 PASS, 1 FAIL with verdict citing the exact failing API response.
>
> Screenshot below shows the verdict. The full evidence directory is on disk locally — happy to share with the maintainer.
>
> [SCREENSHOT: terminal verdict output with file path visible]

---

## D5 — Wed Apr 22

### D5-am (9:00am ET) — LinkedIn Part 1 amplification
> New essay on LinkedIn:
>
> "The Validation Gap in AI-Assisted Development"
>
> 23,479 sessions. 3.4M lines. 5 bugs nobody's tests caught. The case for Evidence-Based Shipping.
>
> {LINK to LinkedIn post}

### D5-eve (7:30pm ET) — Hook reinforcement
> A test that passes because the mock returns what the test expects is not a test.
>
> It's an agreement between two things you wrote.
>
> Real systems don't sign that agreement.

---

## D6 — Thu Apr 23

### D6-am (9:00am ET) — Demo day
> Today: live `/validate` run against a real OSS API project.
>
> Going to try to break my own tool by picking a project I've never seen.
>
> Pulling the repo now. Posting the verdict — PASS or FAIL — in 2 hours.

### D6-pm (1:00pm ET) — Result
> Verdict: 5 journeys validated. 4 PASS, 1 FAIL.
>
> The FAIL: the project's `/users` endpoint returns 500 when the `Accept` header is missing. Real curl found it. Tests didn't.
>
> Filed an issue with the maintainer. Evidence directory attached.

---

## D7 — Fri Apr 24

### D7-am (10:00am ET) — r/LocalLLaMA drop announcement
> Posted on r/LocalLLaMA:
>
> "Open-source: validation harness for AI-generated code. Works with any Claude-compatible agent."
>
> Lots of "but does it work with my agent" — answering each one.
>
> {LINK to Reddit post}

### D7-eve (7:30pm ET) — Mid-sprint check-in
> 7 days in. Star count: {N}. HN drop: 4 days out.
>
> What's working: receipts. People love seeing actual file paths.
> What's not: anything that sounds like "manifesto" without a demo behind it.
>
> Adjusting Wave 3 accordingly.

---

## D8 — Sat Apr 25

### D8-am (9:00am ET) — LinkedIn Part 2 amplification
> Mid-sprint LinkedIn essay:
>
> "What I Learned Shipping ValidationForge"
>
> The most-asked question, the most-cutting critique, the surprising correction.
>
> {LINK to LinkedIn post}

### D8-pm (1:00pm ET) — Iron rule reinforcement
> Iron rule of this launch:
>
> Every public claim cites evidence.
>
> If I say "VF caught a bug," there's a file path and a verdict. If there isn't, I don't say it.

---

## D9 — Sun Apr 26

### D9-am (9:00am ET) — Quiet day, engagement focus
> Reading every comment from this week's posts. Replying to the harder ones.
>
> Mid-thread: someone asked "why not just use Playwright in CI?"
>
> Long answer in the thread. Short answer: VF wraps Playwright + others in a uniform evidence schema and a verdict layer. CI runs the suite. VF makes the verdict auditable.

---

## D10 — Mon Apr 27

### D10-am (8:00am ET) — r/programming drop announcement
> Posted on r/programming:
>
> "Compilation isn't validation: a new gate for AI-assisted development"
>
> Manifesto angle. Bracing for skepticism. Bringing receipts.
>
> {LINK to Reddit post}

### D10-eve (7:30pm ET) — Show HN tomorrow tease
> Tomorrow morning: Show HN.
>
> If you've followed along, the receipts are ready, the manifesto is written, the demo runs.
>
> Wish me luck. Or roast me. Either improves the post.

---

## D11 — Tue Apr 28 — **SHOW HN DAY**

### D11-am (8:05am ET) — Show HN announcement (5 min after submission)
> Just posted on HN: Show HN: ValidationForge – Claude Code plugin that blocks AI-generated mocks.
>
> {LINK to HN submission}
>
> If you read it, please leave a comment — even critical. Comments matter more than upvotes.

### D11-pm (1:00pm ET) — HN engagement update
> 4 hours into the HN drop. Top comment: "isn't this just integration testing rebranded?"
>
> No. Reply with the distinction lives at: {LINK to HN comment}.
>
> tl;dr: integration tests verify YOU wrote the contract. VF verifies the contract still holds in the running system AI built today.

### D11-eve (7:30pm ET) — Day-end status
> HN day status: {N points}, {M comments}, {K stars}.
>
> Did not expect: how many people have a story about "AI-generated code that compiled but broke prod."
>
> The validation gap is real. Everyone has receipts.

---

## D12 — Wed Apr 29

### D12-am (9:00am ET) — HN follow-up
> 24h after Show HN:
> – {N} GitHub stars
> – {M} thoughtful comments
> – {K} new contributors / issues opened
>
> Next: writing the retrospective. Will post Day 14.

### D12-pm (1:00pm ET) — Receipt
> Today's receipt: ran `/validate` against a project a HN commenter sent me.
>
> Found 2 real bugs they didn't know about. Sending them the evidence directory.
>
> This is the loop I want to be in.

---

## D13 — Thu Apr 30

### D13-am (9:00am ET) — LinkedIn Part 3 amplification
> Final LinkedIn essay:
>
> "Two Weeks of Evidence-Based Shipping: Results"
>
> Honest numbers. What worked. What didn't. What I'd do differently.
>
> {LINK to LinkedIn post}

### D13-eve (7:30pm ET) — Retrospective thread (8 tweets) preview
> Tomorrow morning: 14-day launch retrospective thread. Real numbers, real lessons, real misses.
>
> Going to publish things I got wrong. That's the bar.

---

## D14 — Fri May 1

### D14-am (9:00am ET) — Retrospective thread (8 tweets)

**1/8**
> 14 days. $0 spend. ValidationForge launch retrospective. Real numbers, no spin. 🧵

**2/8**
> Stars: {N} (target was 100). HN: {points}, {rank}. Reddit best post: {N upvotes}. LinkedIn cumulative: {N impressions}.

**3/8**
> What worked best: receipts. Every time I posted a real file path, engagement spiked. Every time I posted a "manifesto" without a receipt, it died.

**4/8**
> What worked least: anything that sounded like "we built this to revolutionize..." Even when I rewrote it, the rewrite still showed up in someone's quote-tweet.

**5/8**
> Surprising: how many people DM'd "I have the same bug pattern, can VF help?" The audience already knows the validation gap exists. They just hadn't named it.

**6/8**
> Best comment I got, on HN: "this is just structured exception reporting for AI-generated code." That's a better description than I had. Stealing it.

**7/8**
> What I'd do differently:
> – Land HN earlier (Day 7 not Day 11) — the buildup was less valuable than the post-spike runway
> – More OSS demos. Way more.
> – Fewer LinkedIn posts. The middle one was redundant.

**8/8**
> Next: CONSENSUS engine launch in ~6 weeks. Same playbook, sharper. Thanks for following along — and for the receipts you sent back.
>
> {LINK: github.com/krzemienski/validationforge}

---

## Reserve / Fill-in Bank

Use these if a planned post lands flat or you need a Day 9 fill:

- "If your test passed but the feature didn't, you have a mock drift bug."
- "PASS without citation isn't PASS."
- "Type-checking is necessary. It is not sufficient."
- "Receipts > rhetoric."
- "What's in your `e2e-evidence/` directory right now?"
