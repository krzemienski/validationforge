---
title: "5 questions every engineering leader should ask before adopting agentic dev"
subtitle: "And the consulting-grade answers that surface in nearly every conversation"
author: "Nick Krzemienski"
date: "2026-04-18"
github_repo: "https://github.com/krzemienski/validationforge"
tags:
  - agentic-development
  - ai-validation
  - claude-code
  - validationforge
  - engineering-leadership
  - cto-strategy
  - evidence-based-shipping
published: false
---

<!-- TODO hero image: creatives/screenshots/vf-week4-five-questions-engineering-leaders-hero.png -->

# 5 questions every engineering leader should ask before adopting agentic dev

I've spent the last six weeks at the implementation layer of agentic development — running 23,479 Claude Code sessions, shipping 3.4 million lines of AI-generated code across 27 projects, and open-sourcing a verification framework called ValidationForge. The launch piece on the validation gap got more inbound from engineering leaders than any post I've written.

The same five questions came up in nearly every conversation. Some came from CTOs at Series B startups deciding whether to formalize agentic dev as company strategy. Some came from VPs of engineering at 500-person companies whose teams had already started using Claude Code without a top-down policy and needed to know if they should sanction it or stop it. Some came from staff engineers who'd been told by their leadership to "figure out the AI thing" and had no map.

This post is my attempt to answer those five questions in the depth they deserve. None of these answers are short. None of them are abstract. If you're an engineering leader staring at this decision and the existing material on the internet feels like it was written by people who haven't actually shipped agentic-dev code at scale — this post is for you.

I'm not going to use bullet points where prose is better. I'm not going to give you a framework where a direct answer is better. The five questions are real and the answers are what I would say in a paid consulting engagement, modulo the team-specific tailoring you'd get in that context.

---

## Question 1: How do we know the code the agent ships actually works?

This is the question every other question collapses into eventually. It is the question that separates teams who are succeeding with agentic dev from teams who are about to have a quarter-long quality crisis.

The honest answer is that the gates most teams currently rely on — type-checking, linting, unit tests, CI green — are necessary but not sufficient. Those gates were designed for a world where humans wrote code slowly and the bottleneck was producing the code. They were a reasonable proxy for "the feature works" because the human had been close enough to the code to know whether the tests were the right tests.

In a world where the agent writes both the code and the tests, "the build passes and tests are green" means the agent has been internally consistent with itself. That is not the same thing as the feature working when a real user touches it. Mock-based testing is structurally blind to several categories of bugs that ship reliably in agentic-dev workflows: API field renames that the mock didn't know about, time-dependent logic that the mock skipped, real-system state that the mock didn't have, and rendered-UI behavior that JSDOM never paints.

The path forward is what I've been calling Evidence-Based Shipping: every claim of completion has to cite specific evidence captured from the real running system. Not unit tests against mocks. Real curl against real APIs. Real simulator runs for mobile. Real browser runs (Playwright or equivalent) for web. Real shell invocations for CLIs. The output of validation is a structured directory of artifacts — screenshots, response bodies, build logs — plus a written verdict that says PASS or FAIL per user-facing journey and cites specific evidence files.

This sounds expensive. It is less expensive than you'd guess. The categories of test you actually need shrink dramatically once your verification gate is real-system; you stop writing the mock-based tests that wouldn't have caught the bugs anyway. Net team velocity goes up, not down, after about a six-week implementation period. The expensive part isn't the verification — it's the discipline to enforce it consistently when the agent is producing code faster than your old habits can verify it.

If you take only one thing from this post: the question "how do we know it works" cannot be answered with "the tests pass" anymore. Decide now what your team's answer is going to be, before you have an incident that decides for you.

---

## Question 2: When do I let the agent run autonomously vs. requiring human review?

This is the question I get asked second-most. It usually comes from a CTO who's seen the velocity gains and is trying to figure out where the autonomy budget tops out.

The wrong answer is "always" or "never." Both of those framings come from people who haven't actually shipped at the autonomy levels they're recommending. The right answer is a function of two variables: the change's blast radius if wrong, and the verification gate's confidence on this specific change.

Blast radius is the cost of being wrong. A README typo edit has roughly zero blast radius — if the agent writes it incorrectly, you fix it in the next commit and nobody notices. A schema migration on the production user table has very high blast radius — if the agent writes it incorrectly, you may have hours of downtime, data corruption, or rollback complexity. The autonomy budget should scale inversely with blast radius. README edits can run fully autonomously in a loop overnight if you want. Schema migrations should never run without explicit human review of both the change and the verification evidence, even if the agent is technically capable of writing them.

Verification gate confidence is the second axis. If your gate is real-system validation with cited evidence, your confidence on any given change is high — you can let the agent operate more autonomously because the gate will catch issues before they reach production. If your gate is "the unit tests pass," your confidence is low — you should require human review on more changes because the gate is less reliable.

In practice this means a 2x2 matrix that I draw on a whiteboard in roughly every consulting engagement:

```
                        LOW BLAST RADIUS         HIGH BLAST RADIUS
LOW GATE CONFIDENCE:    Auto with monitoring     Block — require human review
HIGH GATE CONFIDENCE:   Auto (full speed)        Auto with mandatory human sign-off
```

Most teams I work with start in the bottom-left quadrant for everything because they assume their gate is reliable. The first incident moves them to a more conservative posture. The right move is to invest in moving up the gate-confidence axis (better verification) rather than just clamping down on autonomy across the board (which destroys the velocity gains).

If your team is making autonomy decisions without explicit reference to both axes, you're flying blind. Make the matrix. Map your change types onto it. Revisit it quarterly.

---

## Question 3: How do we keep the team's skills sharp when the agent is doing most of the typing?

This question comes from senior engineers and engineering managers more than from CTOs. It is a real concern and I'm increasingly convinced it's the under-discussed problem in agentic dev adoption.

The honest version of the concern: when the agent writes the code, the engineer doesn't fully internalize how the code works. The engineer becomes a reviewer rather than a builder. Over enough quarters, the engineer's instinct for "this design is wrong" atrophies because the engineer hasn't been practicing the instinct on first-principles work. When the engineer eventually has to operate without the agent — to debug a production incident at 2am, to design a new system from scratch, to interview a candidate — the skill has decayed.

I don't have a complete answer here. Nobody does yet; the data is too new. But I have a working hypothesis from watching what successful teams do.

Successful teams treat agent-assisted work and unassisted work as two different modes that engineers should both practice. Some portion of every sprint, the engineer does the work without the agent — designs the system from scratch, writes the first draft of the code by hand, debugs with print statements rather than asking the agent to find the bug. Not because the unassisted version is better; it usually isn't. Because the practice keeps the underlying skill sharp.

This is the same logic as why pilots still practice manual landings even though autopilot lands the plane in normal operations. Autopilot makes the routine landings safer. Pilots who can't land manually are dangerous when the autopilot fails. The same applies to agentic dev — the agent makes the routine work faster, but engineers who can't operate without the agent become liabilities when the agent's output needs to be questioned.

In practice this means agentic-dev policies should include some explicit "manual mode" allocation. Maybe 10-20% of an engineer's time, depending on their seniority. The exact percentage is negotiable; the existence of the allocation is not.

If your team has not had this conversation yet, have it before you have a problem. The teams I've seen handle this badly handled it badly because they treated agentic dev as pure productivity gain and didn't notice the skill atrophy until two years in. By then it's expensive to reverse.

---

## Question 4: How do I make the agentic-dev decision defensible to my board, my customers, or my regulator?

This is the question I get from CTOs at Series B and later companies. It's also the question I get from anyone shipping into regulated industries — fintech, healthcare, defense, government. The version they ask out loud is some variant of "how do we explain this if something goes wrong." The version they're really asking is "how do we make sure we have a defensible process before something goes wrong."

The defensibility question has three dimensions: what code the agent wrote, why you decided to ship it, and what evidence you have that it works.

The first dimension — what code the agent wrote — is solvable with discipline. Every commit should be attributable. The agent's contributions should be tagged in commit messages or PR metadata so you can produce, on demand, a list of changes that originated from agent suggestions versus human ones. This is annoying to set up. It is much less annoying to set up than to retroactively figure out months later when a regulator or a customer asks.

The second dimension — why you decided to ship — is solvable with policy. You should have a written agentic-dev policy that says, in plain terms, what your team is and isn't using AI for, what the human-review thresholds are, and how those thresholds relate to risk categories. The policy doesn't have to be long. It does have to exist and be referenced in pull-request templates so nobody can claim they didn't know.

The third dimension — what evidence you have that it works — is the hardest one and the one most teams are unprepared for. "Our test suite passed" is not a defensible answer to a regulator who understands software testing. "Our verification framework runs against the real system, captures evidence to a structured directory, and produces written verdicts that cite specific artifacts" is a defensible answer. The difference between those two answers is not subtle and your regulator (or your enterprise customer's procurement team) will notice.

ValidationForge is one implementation of the third dimension. There will be others. The category — auditable verification with evidence-cited verdicts for AI-generated code — is going to become a procurement requirement at the F500 level within 18 months. Teams that have it before then will be in much better procurement position than teams scrambling to add it under deadline pressure.

If your board, your customers, or your regulator is going to ask the agentic-dev question in the next 12 months, start the documentation now. The expensive part is the discipline to do it consistently; the policy and the framework are the easy part.

---

## Question 5: When should we stop using agentic dev for a particular task?

This is the question almost no one asks me, and it's the most important one.

The framing is uncomfortable: agentic dev is not the right tool for every task. There are categories of work where the agent is faster, cheaper, and at least as accurate as a human engineer. There are also categories of work where the agent is slower, more expensive, or systematically incorrect. Most teams I see use the agent on every task by default, including tasks where the agent is clearly the wrong tool. This is sub-optimal in both directions: it wastes the agent's time on tasks the human would do better, and it wastes the human's time on tasks the agent would do better.

The categories where the agent is the right tool, in my experience: routine refactors with clear acceptance criteria, scaffolding new files from established patterns, debugging issues with concrete error messages, exploring an unfamiliar codebase, generating documentation from existing code, writing one-off scripts and data-processing tasks.

The categories where the agent is the wrong tool, in my experience: novel algorithm design where the right answer requires deep insight, security-critical code that needs to be reasoned about with worst-case adversarial thinking, performance-critical code where the right answer requires understanding hardware behavior, anything involving novel cryptographic implementations, anything involving regulatory interpretation, debugging issues where the symptom is far from the cause.

The boundary between these two categories is not fixed. Models improve. Tooling improves. The list will look different in twelve months than it does today. But the principle holds: there are tasks where you should turn the agent off and use your senior engineers, and your team should know which tasks those are.

The teams that get this wrong tend to make one of two mistakes. The first mistake is "agent for everything" — they let the agent attempt tasks it's structurally bad at, accept its plausible-looking outputs, and ship subtle bugs. The second mistake is "agent for nothing critical" — they restrict the agent to trivial work out of risk-aversion and lose the productivity gains entirely. The right posture is in between, and it requires explicit team-level conversation about which tasks the agent is genuinely good at.

If your team has not had this conversation, you are probably in one of the two failure modes already. Have it.

---

## What I'd ask next

These five questions are not exhaustive. They're the ones I get asked most by engineering leaders who are paying for the conversation. There are others — how to structure the agentic-dev policy in writing, how to handle the cultural shift from "engineers as builders" to "engineers as reviewers," how to negotiate licensing for AI providers when the work product is partially AI-generated, how to handle IP and copyright concerns at the margin. Those will be future posts.

If you're an engineering leader and this post resonated, the highest-leverage thing you can do today is sit with your senior engineering team and answer these five questions in writing. Not perfectly. Just on the record. The conversation forces clarity about positions your team is currently holding implicitly and inconsistently. It's the cheapest, highest-impact intervention I know of.

If you'd rather have someone help you work through these questions in the context of your specific stack, your specific team, and your specific risk tolerance — that's the kind of consulting engagement I'm taking on this quarter. I'm currently engaged with two organizations and have capacity for one more by the end of May. The fastest way to start is a LinkedIn DM with a one-paragraph note on which of the five questions is most pressing for you and where you'd like to be on it in 90 days.

If you want the open-source verification framework that backs the answers in this post, it's at [github.com/krzemienski/validationforge](https://github.com/krzemienski/validationforge). Free, MIT licensed, no telemetry. It's not the only valid implementation of Evidence-Based Shipping, but it's a working one and the receipts are in the repo.

Compilation is necessary. It is not sufficient.

The next bar is evidence — and the next leadership conversation is about what your team's evidence posture should be.
