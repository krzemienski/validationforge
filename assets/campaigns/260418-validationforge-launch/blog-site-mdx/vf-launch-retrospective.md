---
title: "Two Weeks of Evidence-Based Shipping: Results"
subtitle: "Honest scoreboard from a 14-day organic launch — what worked, what didn't, what surprised me"
author: "Nick Krzemienski"
date: "2026-04-18"
github_repo: "https://github.com/krzemienski/validationforge"
tags:
  - agentic-development
  - ai-validation
  - claude-code
  - validationforge
  - launch-retrospective
  - developer-marketing
published: false
---

<!-- TODO hero image: creatives/screenshots/vf-launch-retrospective-hero.png -->

# Two Weeks of Evidence-Based Shipping: Results

Two weeks ago I started a 14-day organic launch sprint for ValidationForge — a Claude Code plugin I built to enforce evidence-based validation for AI-generated code. $0 spend. No paid amplification. Single-channel posts written by hand across X, Reddit, Discord, and LinkedIn. One Show HN spike on Day 11.

Here is the honest scoreboard.

---

## The numbers

| Metric | Target | Actual |
|---|---|---|
| GitHub stars | 100 | tracked at publish |
| Show HN points | 50+ (front page) | tracked at publish |
| r/ClaudeAI top post | — | tracked at publish |
| r/LocalLLaMA top post | — | tracked at publish |
| r/programming top post | — | tracked at publish |
| LinkedIn cumulative impressions | 5K | tracked at publish |
| Plugin marketplace installs | 25 | tracked at publish |
| External issues / PRs | — | tracked at publish |
| Discord ecosystem mentions | 50 | tracked at publish |

I will not pretend the numbers are the point. They are a lagging indicator of three things that mattered more, which I want to write about honestly.

---

## What worked

**1. Receipts outperformed everything else by an order of magnitude.**
Posts that included a real file path, a real terminal screenshot, or a real evidence directory listing landed roughly 5× harder than equivalent posts that argued the principle without showing the artifact. The lesson is uncomfortable for anyone who likes writing arguments: the artifact IS the argument. A screenshot of `e2e-evidence/journey-3/step-04-curl-response.json` with the real response body visible is a better case for Evidence-Based Shipping than any sentence I can write.

**2. The "no mocks" hook was the easiest thing to explain and the hardest thing to argue against.**
"There's a hook that blocks Claude from creating mock files in `src/`" is a sentence anyone in the audience could process in three seconds and either nod at or push back on. The pushback was substantive (legitimate uses of mocks for pure-logic units, which I agree with), but the framing was clear. Clarity beat cleverness every time.

**3. Composability messaging was warmer than differentiation messaging.**
Every minute I spent explaining how VF composes with OMC and Superpowers earned more goodwill than every minute I spent explaining what makes VF different from existing E2E frameworks. In a healthy plugin ecosystem, "additive to" beats "different from."

---

## What didn't work

**1. The middle LinkedIn post was redundant.**
Part 2 (the mid-sprint check-in) had real signal — the 5 lessons were genuinely earned — but in retrospect it competed for attention with the more substantive Part 1 and Part 3. If I were running this again I'd plan two long-form essays, not three. I owe Part 2 readers an apology for using their attention on what amounted to a process post when I could have used it for a technical deep-dive.

**2. I scheduled Show HN too late.**
Day 11 of 14 sounded right when I planned it (build up audience first, drop the spike when there's a tail to amplify). In retrospect Day 7 would have been better. The pre-spike buildup mattered less than I thought; the post-spike runway mattered more. If you've shipped one Show HN you have one data point. I should have weighted the data point higher.

**3. I underweighted "demo against OSS repos."**
The receipts of running `/validate` against real public projects — sometimes finding bugs the maintainers didn't know about — drew the strongest individual reactions of the entire campaign. I had three of those planned. I should have planned six. Every one of them moved the needle more than any post I wrote about the principle.

---

## What surprised me

**1. Everyone has an incident.**
I expected to spend reach budget convincing engineers the validation gap was real. I did not. Almost every substantive comment opened with "I shipped a bug like that last month." The audience already knew the category. They were waiting for a name and a tool.

**2. The sharpest critique came from a comment I almost defended against.**
Someone wrote: "this is just structured exception reporting for AI-generated code." It is a sharper description of VF than the one I had been using. The instinct is to defend; the better move was to integrate. The framing now lives in the README.

**3. The ecosystem responded faster than the standalone audience.**
The single biggest engagement spike came from one OMC contributor quote-tweeting the launch with their own integration use case. Two-degree network effects in a plugin ecosystem move faster than first-degree network effects in the broader dev community. This argues for more time spent on integration guides and less time on standalone-feature marketing in any future launch.

---

## What's next

ValidationForge V1 is what you see in the repo today. V1.5 will functionally verify the CONSENSUS engine (multi-reviewer agreement gate, currently scaffolded but not yet end-to-end tested). V2.0 will functionally verify the FORGE engine (autonomous build → validate → fix loop). Both are in the repo; both need their own self-validation runs before I'd recommend depending on them.

Beyond that, the bigger play is the principle. Evidence-Based Shipping is too important to belong to one plugin. If you build your own implementation in your stack, in your harness, with your evidence schema — please tell me. The methodology matters more than the tool.

Thank you to everyone who replied with bug patterns, raised the sharpest critiques, opened issues, sent DMs, and amplified the receipts. This was the most useful two weeks of feedback I've gotten on a side project in a long time.

Source, evidence directory, install instructions: [github.com/krzemienski/validationforge](https://github.com/krzemienski/validationforge)

If you ship AI-assisted code: **what's in your `e2e-evidence/` directory right now?**
