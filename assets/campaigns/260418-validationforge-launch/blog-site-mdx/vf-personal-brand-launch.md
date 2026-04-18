---
title: "What 23,479 AI Coding Sessions Taught Me About Shipping Real Software"
subtitle: "And why I just open-sourced the framework I built to solve it"
author: "Nick Krzemienski"
date: "2026-04-18"
github_repo: "https://github.com/krzemienski/validationforge"
tags:
  - agentic-development
  - ai-validation
  - claude-code
  - validationforge
  - evidence-based-shipping
  - engineering-leadership
published: false
---

<!-- TODO hero image: creatives/screenshots/vf-personal-brand-launch-hero.png -->

# What 23,479 AI Coding Sessions Taught Me About Shipping Real Software

*And why I just open-sourced the framework I built to solve it.*

## The number that changed how I think about quality

Over the last six weeks I ran 23,479 coding sessions through Claude Code, distributed across 27 production-track projects. Output: roughly 3.4 million lines of AI-generated code, give or take a refactor.

That isn't a vanity metric. It's the number of times I watched an AI agent do something I would have done by hand a year ago, faster than I would have done it.

Most of that code shipped. Some of it didn't. The interesting story isn't the volume. It's the pattern that emerged in the gap between code that the AI declared "done" and code that actually worked when a real user touched it.

Five times in 42 days, code passed every gate I had set up — type-check, lint, unit test, CI green — and still broke in production. Not because the AI was sloppy. Because the gates I had inherited were designed for a different era of software development.

That observation is what produced ValidationForge. It's also what shifted how I now advise teams adopting agentic development. I want to lay out both, because they are connected — and because I think the deeper pattern generalizes far past my one tool.

## The five bug categories that forced the rethink

I tracked every production incident across those six weeks. Five categories kept repeating, each one a class of failure where mock-based testing is structurally blind.

**1. The API field rename.** Backend renamed a response field from `users` to `data`. Frontend's mocked unit test still returned the old field name. Test passed. Frontend crashed the moment a real request returned the new schema. The mock and the test agreed with each other. The real system had moved on. Time to detection: 14 minutes after deploy. Time to root-cause: another 40, mostly spent staring at a green test run that should have caught it but couldn't have.

**2. The JWT expiry change.** Security tightened token lifetime from 60 minutes to 15. The token-refresh logic had a unit test that mocked time entirely. The test never had to wait for a real expiry, so it never exercised the code path that ran when a real token actually expired. Real users got logged out mid-session, the refresh endpoint had a bug nobody had ever exercised, and the test suite happily reported that everything was fine.

**3. The iOS deep-link regression.** Navigation refactor. The unit tests had a mock URL handler that returned the expected screen. They passed. `xcrun simctl openurl` opened the wrong screen on the actual simulator. Two days of "but the tests are green" before someone actually ran the simulator and saw the bug — a bug that would have been caught in five minutes by anyone who tapped a deep link manually. The mocks kept everyone confident while the real product was broken.

**4. The DB migration on real data.** Schema change deduplicated email addresses. Unit test ran against a clean in-memory database with no duplicates. Migration "succeeded." Production database, of course, had duplicates accumulated over years. Migration failed on the first row. Production rollback at 2am. The clean mock database had certified a migration that the real database immediately rejected.

**5. The CSS overflow on small screens.** A layout change introduced horizontal overflow under 768px. The component test rendered nothing — JSDOM doesn't paint. The test passed. The bug was caught not by the test suite but by a customer support ticket from a user on an older Android phone. The first signal of a visual regression came from outside the engineering organization entirely.

These are not horror stories I am cherry-picking. They are categories. If you ship AI-assisted code at any meaningful volume, you have hit at least one of these patterns this quarter, and probably more than one. The common thread is uncomfortable to say out loud: when the agent writes both the production code and the test, "the build passes and tests are green" means the agent agrees with itself. That is not the same thing as the feature working.

## Compilation theater

I started calling this *Compilation Theater*. Like security theater, it produces visible activity — green CI, type-checker happy, unit tests passing, dashboards lighting up — without producing the underlying property anyone actually cares about. Namely, that the feature works when a real user touches it.

The deeper problem is that the implicit quality bar in many engineering organizations has slid downward as AI-generated code volume has grown. When an agent produces five thousand lines in an hour, you cannot manually verify every behavior. You lean on the gates that scale: compilation, type-checking, unit tests. Those gates were designed for a world where humans wrote code slowly and the bottleneck was producing the code. They were a reasonable proxy for "the feature works" because the human had been close enough to the code to know whether the tests were the right tests.

In a world where the agent writes both the code and the tests, those gates measure something different. They measure internal consistency, not correspondence to reality. They confirm that the agent has been logically consistent with itself, not that the running system behaves the way the user experiences it. That is a meaningful distinction, and it is the distinction that is currently producing the production incidents I'm watching teams ship.

The natural reaction is to bring in QA. That is not the answer either, and it's worth saying why. Traditional QA scales linearly with surface area. Agentic dev scales the surface area faster than QA can keep up. By the time a human QA engineer has manually verified one feature, the agent has produced three more. The verification gate has to scale with the velocity of the production gate, or it stops being a gate at all.

What's needed is not more QA. What's needed is structurally different verification — verification that runs against the real system, captures evidence automatically, and rejects completion claims that don't cite that evidence. That's the gap I've been working on closing.

## What I built

ValidationForge is the framework I wish had existed when I started running these sessions. It is a Claude Code plugin (also installable as an OpenCode plugin) that does a few stubborn things on purpose:

- A pre-tool hook **blocks AI agents from creating test, mock, or stub files inside `src/`**. The agent has to validate against the real running system or not at all. No more "I wrote a test that mocks the failing dependency" as a way to claim done. The hook is fifty lines of deterministic JavaScript with no LLM cost. It just refuses to let the file get written, and the agent has to find another path.
- A `/validate` workflow runs a seven-phase pipeline against the actual application: detect the platform, plan the user-facing journeys, run preflight build checks, execute through the same interfaces a real user would touch (curl for APIs, the simulator for iOS, Playwright for web, the shell for CLIs), analyze captured evidence, and write a formal PASS/FAIL verdict.
- Every verdict must **cite specific evidence** — a screenshot file path, the exact HTTP response body, the line of build output. Confident prose without an evidence citation is rejected by the harness. "I think it works" is not a verdict. "Verdict: PASS, evidence: `e2e-evidence/journey-3/step-04-curl-response.json` line 12 confirms the renamed field is being returned and parsed correctly" is a verdict.
- Captured evidence is stored to a structured `e2e-evidence/{journey}/step-NN-*.{ext}` directory and committed alongside the code. The verdict is auditable forever. Six months from now, when someone asks "how do we know this feature works," the answer is a file path, not a memory.

I ran ValidationForge against itself last week, because asking other people to trust your verification framework when you haven't pointed it at your own code is unserious. Six of six validation journeys PASS. Thirteen of thirteen criteria. Zero fix attempts. The complete evidence directory is committed in the public repo so anyone can read the actual artifacts rather than trust my claim about them. If something is wrong with one of the verdicts, you can argue with the file directly.

The repository is open source under the MIT license. Free. No telemetry on by default. Composes cleanly with the rest of the Claude Code plugin ecosystem — oh-my-claudecode (OMC) for orchestration, Superpowers for TDD discipline, ECC for multi-language rules. The integration guides are in the repo. The intent has always been that ValidationForge sits alongside the tools you already use, adds the verification layer, and stays out of the way of everything else.

→ **[github.com/krzemienski/validationforge](https://github.com/krzemienski/validationforge)**

## What this taught me about agentic development at scale

The framework matters. The principle behind it matters more, and I want to name it because I think it generalizes beyond any one tool.

The principle is **Evidence-Based Shipping**: every claim of completion must cite specific evidence captured from the running system. No tool is required to enforce it. A team can adopt it tomorrow with a wiki page, a pull request template that requires an evidence link, and the discipline to actually use them. The discipline is the contribution. Tooling makes the discipline cheaper to enforce; it doesn't replace it.

Adopting agentic development at organizational scale is not primarily a tooling problem. It is a verification problem. The teams I have watched succeed all converge on the same handful of practices, regardless of which AI assistant they happen to be using:

1. **They treat the agent's "done" as a hypothesis, not a conclusion.** Every "I'm finished with this feature" is taken as the start of verification, not the end of work.
2. **They make evidence of correctness a first-class artifact**, not a side effect of CI. Evidence directories are versioned. Verdicts are written. Pull requests link to them.
3. **They block the agent from short-circuiting the gate** — writing a mock instead of running the real system, claiming success without an evidence citation, marking a test as skipped to make CI pass. If the gate can be circumvented, it will be.
4. **They version the evidence alongside the code**, so verdicts are auditable months later. Knowing "the test passed at the time" is not the same as having the actual response body the test saw.
5. **They keep humans in the verification loop** even as production code loops run autonomously. The autonomy budget for the agent shrinks as the change blast radius grows. A README typo edit can run without human review. A schema migration cannot.

The teams that struggle adopt the agent's velocity without adopting any of those gates. They ship faster for two months and then have a catastrophic incident that resets their confidence and their leadership's appetite for the technology. I have watched this play out enough times now that I can predict the timeline. It is roughly seven to nine weeks from "we're shipping AI-generated code in production" to the first incident that produces an incident review where the phrase "but the tests passed" appears unironically.

## The three failure modes I see most often

When I'm called in to help a team that's already in this position, the underlying failure usually breaks down into one of three modes. They look different on the surface but they all collapse to the same root cause: a verification gate that hasn't kept up with the production gate.

**Failure mode one: Velocity-quality whiplash.** The team adopts agentic dev, ships faster, leadership is delighted, the sprint velocity chart goes parabolic. Then a quarter later, the on-call rotation starts burning out from incidents the test suite never caught. The team's response is to slow down, which destroys the productivity gains, which makes leadership skeptical of the AI investment. The right response is not to slow down. It is to upgrade the verification posture so velocity and quality can both stay high. That requires explicit investment in the gate, not just the production loop.

**Failure mode two: The skeptic schism.** Half the team is bullish on agentic dev and ships AI-generated PRs at high volume. The other half is skeptical, refuses to merge them without manual review of every line, and becomes a bottleneck. The conflict is usually framed as "the skeptics don't trust the agent." The actual problem is that there's no shared verification gate both sides can agree on. With Evidence-Based Shipping, the skeptics aren't reviewing the agent's prose claims of correctness — they're reviewing the cited evidence files. That's a much faster and more objective review, and it dissolves most of the tribal conflict because both sides are now arguing about artifacts, not feelings.

**Failure mode three: The lone-wolf champion.** One developer adopts agentic dev personally, ships massive output, looks like a 10x engineer for a quarter. Then they leave or get promoted, and nobody else can replicate their workflow because all the verification was implicit in their head. The team is left with a codebase that "worked when Sarah was here" and no documented gate for verifying it still works after every refactor. Evidence-Based Shipping makes this transferable. The verdict files document what the verification was, who could re-run it, and what the evidence actually showed. Sarah leaves; her verdicts stay; her successor can keep shipping.

If your team is in any of these modes right now, you are not unique. You are at the leading edge of a curve a lot of organizations are about to ride down.

## What I'm doing next

ValidationForge V1 is what's in the repo today. V1.5 will functionally verify the CONSENSUS engine — multi-reviewer agreement gates, three independent AI reviewers examining the same change from different perspectives. Three independent verdicts have to agree before the change is considered green. V2.0 will functionally verify the FORGE engine — autonomous build → validate → fix loops with a three-strike protocol, where the agent can iterate but is hard-capped on retries before escalating to a human. Both are scaffolded in the current release; both will get the same self-validation treatment before I recommend depending on them. The receipts will be public when they are.

Beyond the tool, I am writing a longer piece on what the next-decade verification stack looks like for AI-assisted development. That piece will argue that the categories of tooling that made unit testing standard in the 2000s and continuous integration standard in the 2010s now need a third pillar: continuous verification against the running system. ValidationForge is one implementation. There will be others. The category is the contribution.

I am also taking on a small number of advisory and consulting engagements this quarter for organizations rolling out agentic development at meaningful scale. The engagements I'm best-suited for, and most interested in, look like this:

- **Engineering leadership at a 50-500 person org** that has adopted (or is about to adopt) AI coding assistants and needs a verification posture that scales with the velocity gains. Typical engagement: 4-8 weeks, mix of strategy work with the leadership team and hands-on implementation with one or two engineering teams. Outcome: an internal version of Evidence-Based Shipping tailored to your stack, with hooks installed, dashboards wired, and at least one team running it for a full release cycle.
- **Series B-C startups** that are shipping fast on AI-assisted code and are starting to feel the validation pain — usually triggered by an enterprise customer asking "how do you verify this code works" or a board member asking the same question with a different motivation. Typical engagement: 6 weeks, with a board-readable deliverable on AI code quality posture and a working implementation in one critical product surface area.
- **Regulated industries** (fintech, healthcare, defense) where "the AI wrote it and the tests pass" is not going to fly with auditors and never was. Typical engagement: longer, more technical, evidence-trail focused. Outcome: an audit-ready verification posture that satisfies the specific regulatory regime you operate under.

I am not the right person for: pure implementation contracting, replacing your QA function, training engineering teams on prompt engineering basics, or one-off "just look at our codebase and tell us what to do" engagements with no implementation budget. I'd rather be honest about that up front than waste anyone's time.

If your team is somewhere on this curve — or if you're trying to answer the "how do we ship this AI-generated code with confidence" question for a board, a CTO, or a regulated customer — I am open to a conversation. The fastest way to reach me is a LinkedIn DM with a one-paragraph note on where you are now and where you would like to be in 90 days. I'll respond within two business days and we can decide from there whether a 30-minute call makes sense.

If you want to follow the work without committing to anything: the repo is open, the evidence directories are public, and I am publishing receipts, retrospectives, and demos as I ship. Everything is in public on purpose. It is the same discipline I am advocating for.

Compilation is necessary. It is not sufficient.

The next bar is evidence.

---

*Nick Krzemienski — building ValidationForge. Six weeks, 23,479 sessions, 3.4M lines, and one stubborn opinion: AI-generated code should ship with receipts. [github.com/krzemienski/validationforge](https://github.com/krzemienski/validationforge)*
