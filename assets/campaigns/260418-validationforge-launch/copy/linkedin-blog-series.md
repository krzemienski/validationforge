# LinkedIn Blog Series (3 parts)

All posts published natively to LinkedIn (no Medium/Substack mirror during sprint). Plain text + occasional embedded screenshot. No carousels.

---

## Part 1 — Wed Apr 22 (Day 5)

### Title
> The Validation Gap in AI-Assisted Development

### Body

Last quarter I shipped 3.4 million lines of code across 27 projects in 42 days. I wrote almost none of it directly. Claude Code generated the bulk; I orchestrated, reviewed, and pressed Enter.

The output was extraordinary. Features that would have been weeks of work shipped in afternoons. Bug fixes that would have required deep context-switches got resolved while I focused elsewhere. The leverage was real and it changed how I work.

But after 23,479 sessions, a pattern surfaced that I cannot stop thinking about: **AI assistants are extremely good at producing code that compiles, type-checks, and passes its own tests — but those properties are no longer reliable signals that the feature actually works.**

I want to talk about the gap, why mocks make it worse, and what I built to close it.

---

**Five real bugs that shipped despite passing every test**

Over those 42 days I tracked five categories of production bugs that made it through the existing quality gates. Each of them is a category, not a single incident — and each represents a class of failure where mock-based testing is structurally blind.

**1. The API field rename.** A backend service renamed a response field from `users` to `data`. The frontend test had a mock returning `{users: [...]}`. The mock didn't know about the rename. The test passed. The frontend crashed in production the moment a real request returned `{data: [...]}`. Time to detect: 14 minutes after deploy. Time to root-cause: another 40, mostly spent staring at green test runs.

**2. The JWT expiry change.** Security tightened token lifetime from 60 minutes to 15 minutes. The token-refresh logic had a unit test where the mock skipped time entirely. The test passed because the test never had to wait for a real expiry. Production users got logged out mid-session, and the refresh endpoint had a bug nobody had ever exercised.

**3. The iOS deep link regression.** A navigation refactor changed how deep links resolved. The unit tests had a mock URL handler that returned the expected screen. They passed. `xcrun simctl openurl` opened the wrong screen on the actual simulator. Two days of "but the tests are green" before someone ran the simulator.

**4. The database migration.** A schema change deduplicated email addresses. The migration had a unit test against a clean in-memory database with no duplicates. The test passed. The real database, of course, had duplicates. Migration failed on the first row. Production rollback at 2am.

**5. The CSS grid overflow.** A layout change introduced a horizontal overflow on screens narrower than 768px. The component test rendered nothing — JSDOM doesn't paint. The test passed. The Playwright screenshot in the eventual incident review showed the overflow clearly. The first signal had been a customer support ticket.

These aren't horror stories I'm cherry-picking. These are the categories of bug that mocks structurally cannot detect — because in each case, the mock returned what the test expected, and the real system had changed.

---

**The deeper problem: "build passing" became the bar**

There's a quieter shift underneath the bugs. As AI-generated code volume grew, the implicit quality bar in many teams (mine included) slid from "the feature works" to "the build passes and the type-checker is happy." That slide makes sense in the moment — when an agent produces 5,000 lines in an hour, you cannot manually verify every behavior. You lean on the gates that scale: compilation, type-checking, unit tests.

But those gates were designed for code humans wrote slowly. They were designed for a world where the bottleneck was producing the code, and the gates protected against careless mistakes. In that world, "the build passes and tests are green" was a reasonable proxy for "the feature works," because the human had been close enough to the code to know whether the tests were the right tests.

In a world where an agent writes the code and the tests, "the build passes and tests are green" means **the agent agrees with itself**. That is not the same thing.

I started calling this **Compilation Theater** — the practice of treating build success as evidence that AI-generated code works. Like security theater, it produces visible activity (CI green, type-checker happy, unit tests passing) without producing the underlying property (the feature actually behaves correctly when a real user touches it).

---

**What I think the missing gate looks like**

The gate that's missing sits between compilation and human review. I'd call it **Evidence-Based Shipping**: every claim that a feature is complete must cite specific evidence captured from the real running system.

In practice that means:

- Validation runs against the real system through the same interfaces a real user would touch (HTTP for APIs, the simulator for iOS, the rendered browser for web, the shell for CLIs).
- The output is a structured directory of artifacts: screenshots, response bodies, build logs, console output.
- A written verdict says PASS or FAIL per user-facing journey, and cites specific evidence files for each claim.
- Confident prose without evidence citations is rejected. "I think it works" is not a verdict.

This is not novel as an idea. End-to-end testing has existed forever. What's different is the enforcement posture: when an AI agent is the author, the harness needs to **block** the agent from short-circuiting the gate (by writing a mock instead of running the real system, by claiming "done" without an evidence citation).

I built ValidationForge to be that harness. It's a free, open-source Claude Code plugin. The PreToolUse hook layer blocks mock and test-file creation in `src/`. A `/validate` command runs a 7-phase pipeline. Every verdict cites evidence.

I ran it against itself last week: 6 of 6 validation journeys PASS, 13 of 13 criteria, 0 fix attempts. The complete evidence directory is committed in the repo so anyone can audit the actual artifacts rather than trust my claim about them.

But the tool is the smaller part. The bigger part is the discipline. Whether you use ValidationForge or build your own version, the gate has to exist. **Compilation is necessary. It is not sufficient.**

Source, install instructions, and the self-validation evidence directory: https://github.com/krzemienski/validationforge

I'd genuinely like to hear: what's the validation gap pattern you've shipped through? I'll add it to the running list.

---

## Part 2 — Sat Apr 25 (Day 8)

### Title
> What I Learned Shipping ValidationForge (Mid-Sprint Lessons)

### Body

Five days into the ValidationForge launch, the most useful thing I've learned isn't from the metrics — it's from the comments.

I'm halfway through a 14-day organic launch sprint for a Claude Code plugin I built (the one I wrote about earlier this week — see Part 1). $0 spend, no paid amplification, single channel-by-channel push across X, Reddit, Discord, and LinkedIn. The honest mid-sprint scorecard:

- GitHub stars: {N} (target 100 by Day 14)
- Top X thread: {M} impressions, {K} replies
- r/ClaudeAI post: {U} upvotes, {C} comments — most engagement of the week
- LinkedIn Part 1: {I} impressions, {R} reactions
- Discord: 4 servers seeded, {D} new install mentions

But the numbers aren't the lesson. The lesson is what people actually said back, especially the things I didn't expect.

---

**Lesson 1: "I have this exact bug pattern" came from everywhere**

The single most-replied comment archetype, across every channel, was a variant of: "I shipped a bug like that last month. Same shape. Mock said one thing, real system said another."

I expected to have to convince people the validation gap was real. I did not. Most working engineers shipping AI-assisted code have a personal incident in mind. The category is recognized. What's missing is a name for it and a tool that addresses it.

The implication for anyone marketing developer tools: **don't spend your reach budget convincing the audience the problem exists**. They already know. Spend it on the specific shape of the solution.

---

**Lesson 2: "Receipts" outperformed "manifesto" by an order of magnitude**

I had two parallel content tracks: receipt-style posts (here is a real verdict file from a real run) and manifesto-style posts (here is the principle of Evidence-Based Shipping).

Engagement on the receipts: roughly 5x the manifestos. Every single post that included an actual file path and a screenshot of real terminal output landed harder than the equivalent argument-shaped post.

This is humbling for someone who likes writing arguments. The lesson: **the artifact is the argument**. A screenshot of a real verdict file with a real citation is a better case for Evidence-Based Shipping than any sentence I can write about it.

---

**Lesson 3: The sharpest critique was the most useful**

A commenter on Hacker News (well — the equivalent comment in r/programming, ahead of the planned HN drop) wrote: "This is just structured exception reporting for AI-generated code." I took that personally for about 30 seconds, then realized it was a better description of ValidationForge than the one I had been using.

Structured exception reporting for AI-generated code. That's exactly what the evidence directory is. That's exactly what the verdict layer does. The framing makes the value clearer than my own framing did.

I'm stealing it for Part 3.

---

**Lesson 4: The "no telemetry" line worked harder than I expected**

The README has a line: "no telemetry on by default." I included it as a hygiene checkbox. It turned out to be the most-quoted line in DMs I've received from teams considering adoption. Engineers are deeply tired of dev tools that phone home by default.

The implication beyond this launch: **silence about telemetry is read as suspicion**. Saying "no telemetry, here's where to verify" reads as trust-building. I'll keep that line load-bearing.

---

**Lesson 5: Composability messaging matters more than differentiation messaging**

I prepared for the "so why not just use Playwright" question. I prepared for "isn't this just integration testing." Those questions came up and the prepared answers worked.

What I did NOT prepare for, and got asked surprisingly often: "does this play nicely with OMC / Superpowers / [other plugin]?"

Engineers in plugin ecosystems are pattern-matching for **additive** tools, not replacement tools. Every minute I spent explaining how VF composes with OMC and Superpowers (use those to build, use VF to verify) earned more goodwill than every minute I spent explaining what makes VF different from existing E2E frameworks.

The implication: **in a healthy ecosystem, "additive to" beats "different from."** I'll re-tune the rest of the launch around this.

---

**What I'd do differently if I were starting over today**

Three concrete things:

1. **Land Show HN earlier.** I have HN scheduled for Day 11 (Tuesday Apr 28). The buildup was worthwhile, but in retrospect the first wave of earned attention from the X/Reddit drops would have been better leveraged with HN at Day 7. The post-spike runway matters more than the pre-spike priming.

2. **Demo against more OSS repos, fewer LinkedIn posts.** The receipts of running `/validate` against real OSS projects — finding actual bugs the maintainers didn't know about — drew the strongest engagement. I have three of those scheduled across the remaining week. I should have planned six.

3. **Cut the middle LinkedIn post.** This one. (You're reading it.) The mid-sprint check-in has value, but the cost is real estate that could have hosted a more substantive technical deep-dive. If you're planning a launch sprint, plan two long-form essays, not three.

---

**What's next**

Wave 4 of the launch is Show HN on Tuesday morning. Wave 5 is the retrospective — Part 3 of this series — with real numbers on Day 14.

If you want to see what I'm posting, the X handle is in my profile. If you want to try the tool, install instructions and the self-validation evidence directory are at:

https://github.com/krzemienski/validationforge

And if you've shipped a bug a mock couldn't catch, drop the pattern in the comments. I'm building a running list.

---

## Part 3 — Thu Apr 30 (Day 13)

### Title
> Two Weeks of Evidence-Based Shipping: Results

### Body

Two weeks ago I started a 14-day organic launch sprint for ValidationForge — a Claude Code plugin I built to enforce evidence-based validation for AI-generated code. $0 spend. No paid amplification. Single-channel posts written by hand across X, Reddit, Discord, and LinkedIn. One Show HN spike on Day 11.

Here is the honest scoreboard.

---

**The numbers**

| Metric | Target | Actual | Status |
|---|---|---|---|
| GitHub stars | 100 | {N} | {✓ / ✗} |
| Show HN points | 50+ (front page) | {P} | {Front page / not} |
| r/ClaudeAI top post | — | {U} upvotes | — |
| r/LocalLLaMA top post | — | {U} upvotes | — |
| r/programming top post | — | {U} upvotes | — |
| LinkedIn cumulative impressions | 5K | {I} | {✓ / ✗} |
| Plugin marketplace installs | 25 | {V} | {✓ / ✗} |
| External issues / PRs | — | {E} | — |
| Discord ecosystem mentions | 50 | {D} | {✓ / ✗} |

(Numbers will be filled in at publish time.)

I will not pretend the numbers are the point. They are a lagging indicator of three things that mattered more, which I want to write about honestly.

---

**What worked**

**1. Receipts outperformed everything else by an order of magnitude.**
Posts that included a real file path, a real terminal screenshot, or a real evidence directory listing landed roughly 5× harder than equivalent posts that argued the principle without showing the artifact. The lesson is uncomfortable for anyone who likes writing arguments: the artifact IS the argument. A screenshot of `e2e-evidence/journey-3/step-04-curl-response.json` with the real response body visible is a better case for Evidence-Based Shipping than any sentence I can write.

**2. The "no mocks" hook was the easiest thing to explain and the hardest thing to argue against.**
"There's a hook that blocks Claude from creating mock files in `src/`" is a sentence anyone in the audience could process in three seconds and either nod at or push back on. The pushback was substantive (legitimate uses of mocks for pure-logic units, which I agree with), but the framing was clear. Clarity beat cleverness every time.

**3. Composability messaging was warmer than differentiation messaging.**
Every minute I spent explaining how VF composes with OMC and Superpowers earned more goodwill than every minute I spent explaining what makes VF different from existing E2E frameworks. In a healthy plugin ecosystem, "additive to" beats "different from."

---

**What didn't work**

**1. The middle LinkedIn post was redundant.**
Part 2 (the mid-sprint check-in) had real signal — the 5 lessons were genuinely earned — but in retrospect it competed for attention with the more substantive Part 1 and Part 3. If I were running this again I'd plan two long-form essays, not three. I owe Part 2 readers an apology for using their attention on what amounted to a process post when I could have used it for a technical deep-dive.

**2. I scheduled Show HN too late.**
Day 11 of 14 sounded right when I planned it (build up audience first, drop the spike when there's a tail to amplify). In retrospect Day 7 would have been better. The pre-spike buildup mattered less than I thought; the post-spike runway mattered more. If you've shipped one Show HN you have one data point. I should have weighted the data point higher.

**3. I underweighted "demo against OSS repos."**
The receipts of running `/validate` against real public projects — sometimes finding bugs the maintainers didn't know about — drew the strongest individual reactions of the entire campaign. I had three of those planned. I should have planned six. Every one of them moved the needle more than any post I wrote about the principle.

---

**What surprised me**

**1. Everyone has an incident.**
I expected to spend reach budget convincing engineers the validation gap was real. I did not. Almost every substantive comment opened with "I shipped a bug like that last month." The audience already knew the category. They were waiting for a name and a tool.

**2. The sharpest critique came from a comment I almost defended against.**
Someone wrote: "this is just structured exception reporting for AI-generated code." It is a sharper description of VF than the one I had been using. The instinct is to defend; the better move was to integrate. The framing now lives in the README.

**3. The ecosystem responded faster than the standalone audience.**
The single biggest engagement spike came from one OMC contributor quote-tweeting the launch with their own integration use case. Two-degree network effects in a plugin ecosystem move faster than first-degree network effects in the broader dev community. This argues for more time spent on integration guides and less time on standalone-feature marketing in any future launch.

---

**What's next**

ValidationForge V1 is what you see in the repo today. V1.5 will functionally verify the CONSENSUS engine (multi-reviewer agreement gate, currently scaffolded but not yet end-to-end tested). V2.0 will functionally verify the FORGE engine (autonomous build → validate → fix loop). Both are in the repo; both need their own self-validation runs before I'd recommend depending on them.

Beyond that, the bigger play is the principle. Evidence-Based Shipping is too important to belong to one plugin. If you build your own implementation in your stack, in your harness, with your evidence schema — please tell me. The methodology matters more than the tool.

Thank you to everyone who replied with bug patterns, raised the sharpest critiques, opened issues, sent DMs, and amplified the receipts. This was the most useful two weeks of feedback I've gotten on a side project in a long time.

Source, evidence directory, install instructions: https://github.com/krzemienski/validationforge

If you ship AI-assisted code: **what's in your `e2e-evidence/` directory right now?**
