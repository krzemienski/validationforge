---
title: "Patterns I've noticed from teams doing Evidence-Based Shipping right"
subtitle: "Three patterns that keep showing up across stacks — and the discipline that ties them together"
author: "Nick Krzemienski"
date: "2026-04-18"
github_repo: "https://github.com/krzemienski/validationforge"
tags:
  - agentic-development
  - ai-validation
  - claude-code
  - validationforge
  - evidence-based-shipping
  - engineering-culture
  - patterns
published: false
---

<!-- TODO hero image: creatives/screenshots/vf-week4-patterns-from-teams-doing-ebs-hero.png -->

# Patterns I've noticed from teams doing Evidence-Based Shipping right

A month ago I open-sourced ValidationForge and named the principle behind it Evidence-Based Shipping — the discipline of requiring every claim of completion in AI-assisted development to cite specific evidence captured from the running system.

I expected the post to land. I did not expect what happened next: the DMs and comments revealed that a surprising number of teams had already been doing variations of this without naming it. The implementation details differed. The underlying instinct was identical. Some had built internal tooling. Some had built it into their PR templates. Some had built it into their incident-review process and were back-propagating the discipline upstream into their build process.

I've been collecting the patterns. Three of them keep showing up in the conversations I've had with engineering teams over the past four weeks — and they generalize far past my one tool. I want to lay them out in the abstract because the abstract version is what transfers across stacks, not any specific team's implementation. If any of these patterns match something your team is already doing, you're further along than you think.

---

## Pattern 1: Evidence from compliance tooling, repurposed for development

Some engineering organizations already have infrastructure that captures real-system evidence — not because anyone on the dev side asked for it, but because a compliance team, security team, or auditor needed an auditable trail of "what was running in production at any given timestamp." These tools typically produce: a screenshot of the production deploy, the response body of a smoke test against canonical endpoints, the build log line confirming the deploy succeeded, sometimes a synthetic-transaction verdict posted to a central log.

What I keep seeing: teams that started with compliance-driven evidence capture in 2022 or 2023, and only later — as AI-assisted development volume grew — realized the compliance tooling had quietly become their most reliable quality gate. Because it was the only tool running against the real system rather than against developers' assumptions of the real system.

The pattern generalizes: if your organization has any compliance, audit, or incident-review tooling that captures real-system evidence, you may already have most of an Evidence-Based Shipping infrastructure without realizing it. The move is to wire it back into the development loop — reference the evidence files in PR descriptions, require the verdict as a merge check, link the compliance trail in the feature rollout plan — not to build it from scratch.

---

## Pattern 2: The PR-template verification-evidence field

The cheapest, highest-leverage pattern I've seen multiple teams converge on independently: changing their pull-request template to require a "Verification Evidence" field that links to specific artifacts — a screenshot, a Looker dashboard query, a Datadog trace, a curl response saved to a gist. Pull requests without an evidence field are not merged. Reviewers are empowered to challenge the evidence as insufficient and request more. Authors respond by capturing more evidence, not by arguing the existing evidence is enough.

What's elegant about this pattern is how cheap it is. There's no new tooling. There's no new automation. There's no AI involved. There's a PR template field and a reviewer norm. Teams I've compared notes with estimate the change cost roughly four to eight hours of internal documentation and conversation, produced a measurable drop in production incidents within one quarter, and left the actual CI/CD infrastructure untouched.

The lesson generalizes even more broadly: most teams don't need a verification framework. Most teams need a PR template and the discipline to enforce it. A framework is a force multiplier for teams that already have the discipline; it is not a substitute for the discipline. If your team isn't ready for the discipline yet, no framework will save you. If your team is ready, even a very small framework is a 10x multiplier.

---

## Pattern 3: The domain-natural verification artifact

The third pattern is the one I think about most often, because it reframes the question of "what does Evidence-Based Shipping look like in practice" in a way that finally scales across domains.

For a web application, the domain-natural verification artifact is a rendered screenshot — Playwright or Puppeteer captures the exact pixels a real user would see. For an API, it's a real HTTP response — curl against the actual endpoint, response body saved. For a CLI, it's real stdout and exit code — run the binary, capture what it produced. For a database migration, it's the actual database state before and after — a diff of the schema, a row count of the affected tables. For an ML pipeline, it's a precision/recall delta on a held-out validation set. For an audio or signal-processing library, it's a before/after spectrogram of a canonical input file.

The pattern I've watched successful teams converge on: they don't try to invent a universal verification artifact. They ask what their domain naturally produces, and they make capturing that artifact cheap and required. For the team building a signal-processing library, the spectrogram is impossible to fake — there's either a real waveform through a real pipeline or there isn't. For the team building a web app, the screenshot is impossible to fake — there's either a real rendered pixel state or there isn't.

The work is to find the unfake-able artifact for your domain, then make capturing it so cheap it can be a default part of every PR. The teams that nail this step see their quality-incident rate drop within one sprint. The teams that try to pick an artifact from someone else's domain usually end up with verification theater — artifacts that look impressive but don't actually constrain anything about the code being shipped.

There is no universal verification artifact. There is only the one that makes the most sense for what you're shipping. Find yours. Make capturing it cheap. Make it required. Then iterate.

---

## What I'm taking from this

After six weeks of running ValidationForge against real projects and hearing about how other teams are independently arriving at similar disciplines, I'm increasingly convinced that the principle generalizes far past any one tool. The principle is older than AI-assisted development. AI-assisted development just made the verification gap visible enough that more teams started taking it seriously.

If you're a team that has been quietly building your own version of this and would be open to being spotlighted in a future post — DM me. I'm collecting these patterns as a working library and I think the broader engineering community benefits from seeing what real teams have built rather than just what I've built.

If you're an engineering leader trying to get your team to adopt the discipline and you'd like help thinking through what your domain-natural verification artifact should be, that's the kind of question I'm having with the consulting engagements I'm taking on this quarter. The remaining May slot is filled, but I'm taking June and Q3 inquiries now. DM with a one-paragraph note on what you ship and what evidence you currently capture.

The deeper observation from spotlighting these three teams: nobody waited for permission. Each of them saw the verification gap, named it for themselves, and built whatever made sense in their domain. That is the right model. The principle is portable. The implementation is yours.

The receipts are wherever you choose to capture them.
