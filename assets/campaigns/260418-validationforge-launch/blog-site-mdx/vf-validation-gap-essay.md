---
title: "The Validation Gap in AI-Assisted Development"
subtitle: "Five bugs that shipped through every gate, and why mock-based testing is now structurally blind"
author: "Nick Krzemienski"
date: "2026-04-18"
github_repo: "https://github.com/krzemienski/validationforge"
tags:
  - agentic-development
  - ai-validation
  - claude-code
  - validationforge
  - compilation-theater
  - evidence-based-shipping
published: false
---

<!-- TODO hero image: creatives/screenshots/vf-validation-gap-essay-hero.png -->

# The Validation Gap in AI-Assisted Development

Last quarter I shipped 3.4 million lines of code across 27 projects in 42 days. I wrote almost none of it directly. Claude Code generated the bulk; I orchestrated, reviewed, and pressed Enter.

The output was extraordinary. Features that would have been weeks of work shipped in afternoons. Bug fixes that would have required deep context-switches got resolved while I focused elsewhere. The leverage was real and it changed how I work.

But after 23,479 sessions, a pattern surfaced that I cannot stop thinking about: **AI assistants are extremely good at producing code that compiles, type-checks, and passes its own tests — but those properties are no longer reliable signals that the feature actually works.**

I want to talk about the gap, why mocks make it worse, and what I built to close it.

---

## Five real bugs that shipped despite passing every test

Over those 42 days I tracked five categories of production bugs that made it through the existing quality gates. Each of them is a category, not a single incident — and each represents a class of failure where mock-based testing is structurally blind.

**1. The API field rename.** A backend service renamed a response field from `users` to `data`. The frontend test had a mock returning `{users: [...]}`. The mock didn't know about the rename. The test passed. The frontend crashed in production the moment a real request returned `{data: [...]}`. Time to detect: 14 minutes after deploy. Time to root-cause: another 40, mostly spent staring at green test runs.

**2. The JWT expiry change.** Security tightened token lifetime from 60 minutes to 15 minutes. The token-refresh logic had a unit test where the mock skipped time entirely. The test passed because the test never had to wait for a real expiry. Production users got logged out mid-session, and the refresh endpoint had a bug nobody had ever exercised.

**3. The iOS deep link regression.** A navigation refactor changed how deep links resolved. The unit tests had a mock URL handler that returned the expected screen. They passed. `xcrun simctl openurl` opened the wrong screen on the actual simulator. Two days of "but the tests are green" before someone ran the simulator.

**4. The database migration.** A schema change deduplicated email addresses. The migration had a unit test against a clean in-memory database with no duplicates. The test passed. The real database, of course, had duplicates. Migration failed on the first row. Production rollback at 2am.

**5. The CSS grid overflow.** A layout change introduced a horizontal overflow on screens narrower than 768px. The component test rendered nothing — JSDOM doesn't paint. The test passed. The Playwright screenshot in the eventual incident review showed the overflow clearly. The first signal had been a customer support ticket.

These aren't horror stories I'm cherry-picking. These are the categories of bug that mocks structurally cannot detect — because in each case, the mock returned what the test expected, and the real system had changed.

---

## The deeper problem: "build passing" became the bar

There's a quieter shift underneath the bugs. As AI-generated code volume grew, the implicit quality bar in many teams (mine included) slid from "the feature works" to "the build passes and the type-checker is happy." That slide makes sense in the moment — when an agent produces 5,000 lines in an hour, you cannot manually verify every behavior. You lean on the gates that scale: compilation, type-checking, unit tests.

But those gates were designed for code humans wrote slowly. They were designed for a world where the bottleneck was producing the code, and the gates protected against careless mistakes. In that world, "the build passes and tests are green" was a reasonable proxy for "the feature works," because the human had been close enough to the code to know whether the tests were the right tests.

In a world where an agent writes the code and the tests, "the build passes and tests are green" means **the agent agrees with itself**. That is not the same thing.

I started calling this **Compilation Theater** — the practice of treating build success as evidence that AI-generated code works. Like security theater, it produces visible activity (CI green, type-checker happy, unit tests passing) without producing the underlying property (the feature actually behaves correctly when a real user touches it).

---

## What I think the missing gate looks like

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

Source, install instructions, and the self-validation evidence directory: [github.com/krzemienski/validationforge](https://github.com/krzemienski/validationforge)

I'd genuinely like to hear: what's the validation gap pattern you've shipped through? I'll add it to the running list.

---

*If your team is rolling out agentic development at meaningful scale and the verification gap above is starting to feel real — that's the kind of advisory engagement I'm taking on this quarter. A LinkedIn DM with a one-paragraph note on where you are now is the fastest way to start.*
