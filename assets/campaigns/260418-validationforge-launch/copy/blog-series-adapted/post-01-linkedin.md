---
channels: LinkedIn (native long-form article) + personal blog (canonical)
word_count: ~2,180
send_week: Week 6 — Mon May 26, 2026 (8:30am ET)
source_post: /Users/nick/Desktop/blog-series/posts/post-01-series-launch/post.md
companion_repo: https://github.com/krzemienski/agentic-development-guide
voice: Direct. Technical. Slightly contrarian. No emojis.
role_in_calendar: Series anchor — overview post landing AFTER Posts 2 + 3 (Week 5) so readers arrive primed.
---

# 23,479 AI Coding Sessions in 42 Days. Here Is the Pattern.

I averaged 559 AI coding sessions per day for 42 days straight. Not prompts. Sessions. Each one a self-contained agent with its own context window, its own task, its own tools.

23,479 total. 3,474,754 lines of interaction data across 27 projects. If you read the bug story and the no-unit-tests piece I shared last week, this is the dataset behind both. Eighteen posts, every claim traceable to a real session, every system backed by a [companion repo](https://github.com/krzemienski/agentic-development-guide) you can clone and run.

## The short version

AI agents fail in predictable ways.

They forget across sessions. They declare victory without evidence. They build features that look correct but do nothing. They pick expensive models for trivial tasks. They corrupt each other's work when they edit the same file.

Every system I built over those 42 days — consensus gates, functional validation, cross-session memory, orchestration loops, enforcement hooks — exists because one of those failures hit me in production. Not in a sandbox. In code I shipped or was about to ship.

## The numbers

23,479 sessions. I started 4,534 of them. The other 18,945 were agents spawning agents. An orchestrator delegates to a reviewer, the reviewer spawns a verifier, the verifier reports back up the chain. That's a 1:4.2 ratio. Every time I kicked off a session, the system spawned roughly four more on its own.

The tool leaderboard tells you what agents actually do with their time:

- Read: 87,152 invocations
- Bash: 82,552
- Grep: 21,821
- Edit: 19,979
- Glob: 11,769
- Write: 9,066

Throw Read, Bash, Grep, and Glob into one bucket — "understanding code" — and you get 203,294 invocations, 79.1% of all tool calls. Edit and Write together, the bucket where agents actually change code, are 11.3%.

Agents spend roughly 80% of their tool invocations understanding code and 20% changing it. That ratio is the thesis of this entire series.

But here is the number that changed how I think about all of this: the Read-to-Write ratio is 9.6:1. For every file an agent writes from scratch, it reads nearly ten. Agents are not generators. They are readers that occasionally write.

The most productive thing an AI agent does isn't writing code. It's understanding the code that already exists.

## Five failure modes

Every system in the rest of the series exists because one of these broke something in production. They showed up in the first week and never stopped.

**Amnesia.** An agent makes the same mistake in session 500 that it made in session 5. Context windows reset between sessions. I watched an agent introduce the same SwiftUI retain cycle three separate times across three weeks. Same view, same cycle, same fix. The third time, I built a cross-session memory system: an SQLite-backed observation store with semantic search and automatic pruning. Repeated mistakes dropped 73% across the projects where I deployed it.

**Confidence without evidence.** An agent reports "feature complete" without proof. Build passes. TypeScript shows zero errors. Victory declared. Feature does nothing. An empty `onClick` handler passed every automated check — syntactically valid, correctly typed, properly imported, zero functional behavior. The `block-test-files` hook fired 642 times across these sessions, preventing agents from writing tests that mirror their own assumptions instead of exercising real features through real UI.

**Completion theater.** Picture a Delete Account button with the correct icon, the correct confirmation dialog, and the correct loading spinner, where the `onClick` handler calls a function with the correct signature and the function body is a TODO comment. Every automated check passed. Every. Single. One. The three-layer validation stack catches this class of failure through real interactions: 7,985 iOS simulator calls (taps, gestures, accessibility queries, screenshots) and 2,068 browser automation calls. Real buttons. Real forms. Real validation.

**Wrong model for the job.** Using Opus to fix a typo. Using Haiku to design a database schema. Why would you do either? Routing by complexity (Haiku for lookups, Sonnet for implementation, Opus for architecture) cut costs by 82% with equivalent output quality. Three rules, no machine learning, no classifier.

**Coordination failures.** Two agents edit the same file. The merge produces valid code that serves JWT verification internals as a REST endpoint. Token payloads, signature validation state, expiry calculations, all exposed to unauthenticated callers. File ownership maps with glob patterns fixed it.

If you ship AI-assisted code at any meaningful volume, you have hit at least one of these in the last 90 days. Probably more than one.

## From autocomplete to operating system

The turning point was a framing shift: stop using AI as autocomplete and start treating it as a team of specialized workers.

Autocomplete operates inside a single context window. A team operates across multiple context windows with coordination protocols between them. The context window isn't just a limitation. It's an architecture boundary. Each agent gets a fresh window, a specific role, and a defined scope. The orchestrator coordinates across those boundaries using the filesystem, not shared memory.

4,534 human-initiated sessions versus 23,479 total tells the story: 81% of all sessions were agents spawning other agents. The coordination layer (2,827 Task spawns, 4,852 TaskUpdates, 2,182 TaskCreates, 1,720 SendMessages) is an organizational layer running on top of Claude Code. I didn't plan it that way. It emerged because single-agent workflows kept hitting the five failure modes above.

Here is what that looks like in practice. One session in the iOS streaming project: the orchestrator needed to consolidate five incomplete iOS specifications into one production spec. It spawned 13 different team configurations over the course of the session. First a design team, one architect and three validators. The architect drafted; the validators reviewed independently and voted. When consensus was reached, the orchestrator dissolved the team and created an implementation team: one executor, three new validators. When implementation gates passed, a final consensus checkpoint team produced the unanimous PASS/FAIL verdict. Eighty agent operations total. I typed one sentence to start it.

> Agents are not generators. They are readers that occasionally write.

## Four patterns that survived

Across 23,479 sessions, four patterns survived contact with real codebases. Everything else was a good idea that didn't hold up.

**Consensus gates.** No single agent reviews its own work. Three agents with different system prompts evaluate every change. Unanimous agreement required. Cost: $0.15 per gate. The three-agent review caught the `+=` bug that had been hiding for three days. Alpha flagged the operator as inconsistent with the API's full-message response format. Bravo flagged the index reset as a state management hazard. Lead flagged both as violations of the streaming module's own documentation comments. One iOS audit session generated 75 TaskCreate operations across a 10-gate consensus validation.

**Functional validation.** No mocks, no stubs, no unit tests. Build the real system, run it, exercise it through the actual UI, capture screenshots as evidence. The iOS numbers from the full dataset: 2,620 screen taps, 2,165 screenshots, 1,239 accessibility tree queries. The browser numbers: 604 clicks, 524 navigations, 465 screenshots. One session ran 674 Playwright tool calls in a single validation pass. That session caught a stale `.next` cache bug that `next build` said didn't exist. I'm still annoyed about that one. I spent two hours blaming my code before the agent proved it was a build cache issue.

**Fresh context over accumulated context.** Long-running sessions accumulate stale assumptions. I have watched an agent confidently reference code it read 30 minutes ago that another agent had since rewritten. The fix: short-lived agents with fresh context. Give each agent exactly the files it needs, let it do one thing, and kill it. A PDCA loop for algorithm tuning showed what this enables: 12 cycles, each a fresh agent reading the previous cycle's results from disk, improving detection accuracy from 78% to 97%.

**Filesystem as persistence layer.** Agents can't share memory. They can share files. Plans, reports, validation evidence, consensus votes — all written to disk in structured formats. When an agent needs context from a previous agent's work, it reads a file, not a chat history. One validation gate from a real session required 8 criteria, each with specific evidence. The criterion "EventBus emits events" had this evidence: `curl emit&count=10` returns `{"emitted":10, "subscriberCount":1, "ringBufferSize":10}`. Not "it works" but "here is the exact JSON proving it works." This evidence-on-disk pattern scales because every agent reads the same files. No shared state, no message passing, no coordination protocol beyond the filesystem itself.

## The economics

The largest project in the dataset: 4,241 session files, 1,563,570 lines of data, 4.6GB. 149 Swift files, 24 screens, a macOS companion, 13 visual themes. Total Claude API cost: approximately $380.

That cost only makes sense with model routing. For 26 invocations across the same workflow:

- All Opus: $8.40
- All Sonnet: $3.12
- Routed (Haiku / Sonnet / Opus): $1.52

82% savings. A project with 200 consensus gates costs $30 with routing versus $168 without. Three rules: lookups go to Haiku, implementation goes to Sonnet, architecture review and complex debugging go to Opus.

The adversarial planning system showed why planning consensus pays for itself. A Supabase auth migration got decomposed into 14 tasks by the Planner. Looked clean. The Architect vetoed it. Supabase Row Level Security policies reference `auth.uid()`, which returns Supabase's internal user ID, not a custom JWT's subject claim. Seven of the 14 tasks assumed RLS compatibility. They would have compiled. They would have passed type checks. They would have failed silently at runtime, allowing unauthorized data access. Three rounds of adversarial review caught it. Cost of those review rounds: under $2. Cost of shipping a silent auth bypass: I don't want to think about it.

## What you walk away with

Read the rest of the series and you'll have a working playbook:

- A consensus gate framework that catches bugs single-agent reviews miss ($0.15 per gate)
- A functional validation protocol that replaces unit tests with real UI interaction
- An orchestration system that coordinates multiple agents without file conflicts
- A cross-session memory store that keeps agents from repeating the same mistakes
- A model routing strategy that cuts API costs by 82%
- A prompt engineering stack that composes seven layers of context (the next post)
- Enforcement hooks that stop agents from cutting corners

Each post has a companion repo. Each repo has working code. Each claim traces back to one of 23,479 real sessions generating 3,474,754 lines of data over 42 days. No fabricated examples. No mock data. Just what actually works when you run AI agents at scale.

This is the same period that produced ValidationForge — the no-mock validation plugin I open-sourced earlier this month. The Iron Rules in that repo and the patterns in this series come from the same sessions.

## The companion repository

The hub repo at [`agentic-development-guide`](https://github.com/krzemienski/agentic-development-guide) indexes all 14 unique companion repos across the series. Each one is a working codebase. Not a tutorial, not a skeleton. The actual code that ran in these sessions. Clone it, pick a post, run the companion code. Everything in this series is designed to be reproduced, not just read.

If you are an engineering leader trying to figure out the verification posture your team needs as AI-assisted code volume grows, or if you're at the lone-wolf-champion stage where one developer ships massive output and nobody else can reproduce the workflow, that is the conversation I am most interested in this quarter. A LinkedIn DM with a one-paragraph note on where you are now and where you'd like to be in 90 days is the fastest way to start. I respond within two business days.

Compilation is necessary. It is not sufficient.

The next bar is evidence.

---

*Nick Krzemienski — 23,479 sessions, 3.4M lines, 27 projects, 14 companion repos, one stubborn opinion: AI-generated code should ship with receipts. Series hub: github.com/krzemienski/agentic-development-guide*
