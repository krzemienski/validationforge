---
title: "What didn't work in the ValidationForge launch"
subtitle: "Real numbers, real misses, and what I'm changing for V1.5"
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

<!-- TODO hero image: creatives/screenshots/vf-week3-reflection-what-didnt-work-hero.png -->

# What didn't work in the ValidationForge launch

Two weeks ago I open-sourced ValidationForge — a Claude Code plugin that enforces evidence-based validation for AI-generated code. I ran a 14-day organic launch sprint with $0 paid amplification. Yesterday was the last day of that sprint.

I've already written the success-flavored retrospective. This is not that post. This post is the things that did not work, the calls I'd take back, and what I'm changing for the next release. I'm publishing it because the honest version is more useful to me — and probably to anyone else launching dev tools in this category — than another win lap.

If you saw the launch and have ideas of your own about what worked and didn't, the comments are open. I'd rather hear what I missed than be told what I got right.

---

## What didn't work

**1. The middle LinkedIn post (Part 2 of the project series) was redundant.**

I planned a three-part long-form series on LinkedIn. Parts 1 and 3 carried the load — Part 1 introduced the validation gap with real numbers, Part 3 was the results retrospective with cited metrics. Part 2 was a mid-sprint check-in that, in retrospect, competed for attention with the bookend posts and added very little new signal. I would estimate two-thirds of the people who read Part 1 didn't read Part 2 because they were waiting for Part 3.

The lesson: long-form series on LinkedIn should be two posts, not three. The middle post almost always becomes a process update that adds noise. If I were doing this again I would plan a hero post and a retro post, and use any bandwidth between them on a different channel — probably a 5-tweet X thread or a focused Reddit drop, both of which performed better than Part 2 did.

**2. I scheduled the Show HN drop too late.**

Show HN went up on Day 11 of a 14-day sprint. The buildup was real — by Day 11 I had a small audience already engaged from the X drumbeat, the Reddit drops, and the LinkedIn posts. But in retrospect Day 7 would have been better. The buildup mattered less than I thought. The post-spike runway mattered more.

What actually drove the late-launch traction was not the buildup — it was the receipts I had accumulated over the first six days that I could cite in HN comments. If I were doing this again, I would land HN on Day 7 with the same receipt arsenal, then use Days 8-14 to ride the post-spike attention into the LinkedIn long-form essay rather than building toward HN as a climax.

If you've shipped one Show HN, you have one data point. I should have weighted that data point more aggressively in my planning.

**3. I underweighted "demo against a real OSS project."**

The receipts that drew the strongest individual engagement across every channel — by a noticeable margin — were the times I ran `/validate` against a public OSS project I'd never seen, posted the verdict (sometimes PASS, sometimes FAIL with cited evidence), and tagged the maintainer. Those posts moved the needle more than any conceptual essay I wrote.

I had three of those scheduled for the 14 days. I should have planned six. They are cheap to produce — the run takes maybe 10 minutes, the screenshot takes another 5, the post takes 10 — and the conversion to repo stars is the highest of any content I produced.

The lesson generalizes beyond my campaign: in dev tool launches, **the demo IS the marketing**. Not "the demo supports the marketing." The demo is the entire argument. Everything else is connective tissue.

**4. The r/programming post did less than I expected.**

I spent disproportionate effort drafting and refining the r/programming post — the manifesto-angle one with the bug-category table and the Compilation Theater framing. It got moderate engagement and exactly zero stars I could attribute back to it.

In retrospect, r/programming is the wrong sub for this kind of launch. The audience leans toward general software engineering, not AI-assisted dev specifically. The launch resonated on r/ClaudeAI (warmest by far), r/LocalLLaMA (technical and curious), and on r/ExperiencedDevs (leadership-perspective). r/programming is a much bigger sub but the audience overlap with VF's actual users is thinner than the subscriber count would suggest.

Lesson: subreddit subscriber count is a vanity metric. The right question is "what fraction of this sub's regular readers would actually install my thing." For r/programming, the answer was very small. For r/ClaudeAI, the answer was much higher despite the smaller absolute audience.

**5. I didn't have a clear handoff plan from launch attention to ongoing attention.**

The hardest moment in any launch is Day 15. The sprint is over, the spike has decayed, and the audience that just discovered you is deciding whether to keep paying attention or unfollow. I did not have a plan for this moment — I had a plan for getting attention, but no plan for what to do with it once I had it.

What I'm doing about this in real time: the next four weeks of content are going to be lower-volume but higher-substance. One LinkedIn long-form essay per week. Three X threads per week, all receipt-driven. No begging-for-attention posts. The goal of post-launch content is to retain the audience earned during launch by giving them more substance, not more noise.

If I were doing the launch again, I would build the post-launch content calendar before Day 1, not figure it out on Day 15.

---

## What I got right (briefly)

For balance: the receipts-driven approach worked. The self-validation result (6/6 PASS, 0 fix attempts, complete evidence directory committed to the repo) was the most-cited piece of social proof across every channel. The "no telemetry by default" line drove more positive DMs than I expected. The integration guides for OMC and Superpowers earned warm reception from the plugin ecosystem maintainers. The X-and-LinkedIn cross-promotion pattern (LinkedIn essay → X thread referencing it 30 minutes later) outperformed posting on the two channels independently.

If you want the full positive numbers, the launch retrospective post has them. I'm focused here on what to fix.

---

## What I'm changing for the next release

ValidationForge V1.5 ships in roughly 6 weeks. The release adds the CONSENSUS engine — multi-reviewer agreement gates where three independent AI reviewers have to agree before a change is considered green. Same self-validation discipline applies; the receipts will be in the repo before I post anything.

Three changes to the launch playbook based on this retrospective:

1. **Show HN on Day 4, not Day 11.** Use the post-spike runway aggressively rather than building toward the spike.
2. **Six OSS-repo demo posts, not three.** The demo is the marketing.
3. **Two LinkedIn long-form posts, not three.** Hero + retro. Skip the middle.

I'm also shifting the post-launch calendar to start on Day 1, not Day 15. The audience earned during the spike is fragile; they need substance immediately after the spike to convert from launch-attention into ongoing-attention.

---

## What I'd ask the audience

If you launched a dev tool this year and have learnings of your own about post-launch attention retention — what worked for you on Day 15 through Day 45? I'm building a small playbook for the V1.5 launch and would rather steal good ideas than reinvent them.

Particularly interested in the channels that surprised you. The launch I just ran taught me that subreddit subscriber count is a poor predictor of actual conversion, that LinkedIn long-form outperforms what the dev community believes about LinkedIn, and that Discord ecosystem drops are higher-leverage than they look.

DMs are open. Comments are open. The repo is at [github.com/krzemienski/validationforge](https://github.com/krzemienski/validationforge) if you want to see the actual receipt directories from the launch.

If you're an engineering leader rolling out agentic dev at scale and the verification gap I described in last week's essay is starting to feel real on your team — that's the conversation I'm taking on a small number of advisory engagements for this quarter. A LinkedIn DM with a one-paragraph note on where you are now is the fastest way to start.

The next bar is evidence. The receipts are in the repo. Tell me what to do better.
