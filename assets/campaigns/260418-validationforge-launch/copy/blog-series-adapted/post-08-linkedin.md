---
title: "Ralph Orchestrator: How I Slept While My Agent Finished 28 Tasks"
channel: LinkedIn (long-form)
companion_blog_post: 8 of 18
companion_repo: github.com/krzemienski/ralph-orchestrator-guide
target_word_count: 2000-2400
voice_notes: Direct, technical, slightly contrarian. Lead with the 1:47 AM Telegram story. No emojis. Soft consulting CTA at end.
---

# Ralph Orchestrator: How I Slept While My Agent Finished 28 Tasks

1:47 AM on a Wednesday. I typed `/guidance Wrap the existing code, don't replace it` into Telegram from under the covers, rolled over, and went back to sleep. By morning, 28 of 30 tasks were complete.

The agent hadn't stopped working. It didn't need to. Every task was scoped to a single hat, every hat terminated after emitting one event, and the orchestrator spawned the next hat automatically. No human in the loop except for two course corrections I sent from bed.

That overnight run wasn't an accident. It was the result of solving a problem that had cost me weeks: agents that forget their own plans.

## The problem that started everything

Three hours into an API migration, the context window filled. I started a new session, and the agent re-implemented the first endpoint. The one it had finished two hours earlier. Zero memory of the previous work. The codebase had no record either — the work hadn't been committed yet.

I started tracking the waste. Across the `ralph-orchestrator` project alone — 1,045 files, 335,290 lines of code, 57 agent spawns — I estimated roughly 5 hours of productive agent time lost to context degradation. The pattern repeated. The agent would start strong: clear plan, fast execution, precise code. Then degrade. By minute 40, it was operating on vibes — reviewing code against criteria it invented in the moment, not the criteria from its own plan written 30 minutes earlier.

The 150,000-token context window isn't a luxury. It's a trap. The more an agent accumulates — code, errors, intermediate reasoning, tool outputs — the less reliably it retrieves any single piece. The plan it wrote at token 5,000 is effectively invisible by token 120,000. The agent isn't broken. The architecture is.

The insight that became Ralph was obvious once I stopped fighting it: **the agent's work artifacts should persist on the filesystem, not in the context window.** Plans written to disk. Task lists as files. Build results saved as JSON events. Everything the next agent needs to continue should exist as a file, not as conversation history.

## One hat, one event, then stop

The fundamental design principle borrows from Edward de Bono's Six Thinking Hats. In the original, participants wear metaphorical hats to enforce a single mode of thinking at a time. White hat for facts. Red hat for emotions. Black hat for caution. Trying to think analytically and creatively at the same time produces neither good analysis nor good creativity.

The same principle applies to AI agents, but the stakes are higher. When an agent tries to plan, implement, test, and review in one session, the context window fills with code, error messages, and intermediate reasoning. By the review phase, 80% of the context is consumed. The review becomes a formality. The agent has already committed to the approach contextually and can't step back from its own work.

The data was clear:

- **Hat-scoped sessions** (40K tokens of focused context): 94% task completion, 2% contradiction rate
- **Monolithic sessions** (150K tokens of accumulated context): 67% completion, 34% contradictions

That contradiction rate is what convinced me. A contradiction means the agent did something that directly conflicted with its own earlier decision. Approving code that violated a rule it had just written. Refactoring a function it had marked as final ten minutes earlier. One in three monolithic sessions contained the agent arguing with itself. Hat-scoped sessions nearly eliminated this.

Each hat starts with fresh context. A hat never transitions to another hat within the same session. It does its job, emits a single event, and terminates. The orchestrator reads the event and decides what comes next. The agent doesn't decide when to stop. The task list does.

## What a hat actually looks like

A hat is a TOML configuration block that defines the scope, constraints, and output contract for a single agent session. The `write_allowed` and `write_denied` fields define the file boundary. A Builder cannot touch `docs/` or test files. A Reviewer's config sets `write_allowed = []` entirely — it reads, emits a verdict, stops. The `emit_event` field is the exit contract: the orchestrator won't spawn the next hat until it sees `build.complete` on the event stream.

This is what "one hat, one event" means in practice. The configuration makes the constraint explicit and machine-readable. The orchestrator does not trust the agent to know when it's done. It waits for the event.

## The six hats

Across 10 named worktrees running Ralph loops, I converged on six hat types — Planner, Builder, Reviewer, Fixer, Verifier, Writer. Each one has a single responsibility, an explicit set of files it can touch, and a single exit event. Planner reads the codebase and emits a task list but cannot write code. Builder writes code and cannot review or document. Reviewer critiques and cannot edit. Fixer applies targeted fixes and cannot add features. Verifier checks acceptance criteria and modifies nothing. Writer documents and cannot touch implementation.

The events between hats are routing signals, not data transport. `plan.complete` spawns a Builder. `build.complete` spawns a Reviewer. `review.verdict` with issues spawns a Fixer. `review.verdict` with zero issues converges the loop and terminates it.

I caught the value of this protocol early. A Builder agent finished implementing a feature, then reviewed its own code within the same session. The self-review passed. Of course it did. When the Reviewer hat ran in a separate session — different agent instance, no memory of writing the code — it found six issues. Genuine critical distance only exists where there is no shared context. Like asking a novelist to review the chapter they finished ten minutes ago.

## Convergence-driven termination

Convergence detection is the key to the whole system. When the Reviewer produces zero critical findings, the loop terminates. No arbitrary iteration count. No time limit. The loop runs until the Reviewer has nothing critical left to say.

Some tasks converge in 2 iterations. Others take 14. The system doesn't care about the number. It cares about the quality gate.

The longest Ralph loop I recorded ran in the `smart-deer` worktree: 14 iterations out of a maximum 100. It was debugging an SSE race condition — the kind of bug that requires reproducing, fixing, verifying, and then re-verifying because the fix for the race condition introduced a different timing issue. Across 10 named worktrees, iteration counts varied by task complexity. Average: 10.2 iterations per worktree session.

The stop hook enforced continuation, firing 30 times per session and checking whether tasks remained. The agent doesn't decide when to stop. The task list does. This distinction matters more than it sounds. Left to its own judgment, an agent will stop when it *believes* the work is done. With Ralph, it stops when the filesystem *proves* the work is done. All tasks closed, all reviews passed, all verifications green.

## Filesystem as memory

Ralph state lives entirely on the filesystem. Nothing critical exists only in the context window. Working notes in `scratchpad.md`. Cross-session learnings in `memories.md`. Decisions recorded with confidence scores. Every state transition emits a JSON event to an append-only log. Tasks live as individual JSON files with explicit lifecycle states: pending, ready, active, done, failed.

The `ready` state matters more than it looks. A task marked `ready` is eligible for the next agent to pick up. A task in `pending` still has unsatisfied dependencies. This prevents agents from starting work that depends on incomplete prerequisites.

I learned this the hard way. Two agents wrote to the task list file at the same moment. The file corrupted. Three tasks disappeared, two more had truncated descriptions. I lost 45 minutes reconstructing state from agent logs. The fix was `flock()` on every task state transition. Boring. Reliable. Done.

CLI startup time matters here too. Agents call the task management CLI 200+ times per session. At 3ms per call, the overhead is invisible. A slow CLI (even 100ms) would add 20 seconds of latency per session, and agents would start caching task state in their context window instead of checking the source of truth. The moment an agent caches state locally, it diverges from reality. Performance is a correctness property here, not just a UX property.

## Three modes for three problem shapes

Ralph is the default single-agent execution loop. One agent, cycling through hats, converging on completion. Two other modes earned their place as project complexity grew.

**Ultrawork** is Ralph with parallelism. After the Planner decomposes work into independent tasks, multiple Builder hats execute simultaneously, each in isolation. A merge step reconciles outputs, then a single Reviewer evaluates the combined result. Best for work that decomposes cleanly: "implement these five API endpoints" where each is independent.

**Team mode** is multi-agent coordination. A Lead agent manages the pipeline. Each teammate owns distinct files with no overlapping edits. The Lead resolves conflicts. The Tester verifies. Bounded fix loops prevent infinite cycling. Best for large-scale work spanning specialists.

Most of my work uses Ralph. Overnight runs. Debugging sessions. "Fix this and don't stop until it works." Ultrawork activates when I have ten or more independent tasks. Team mode is for the big pushes — shipping a complete feature across frontend, backend, and infrastructure.

## The six tenets

Six principles govern how Ralph loops operate. I arrived at each one through a specific failure.

**The boulder never stops.** The stop hook fires at the end of every agent session. If tasks remain `ready` or `pending`, the orchestrator spawns the next hat. The name inverts Sisyphus: the boulder never stops because the work actually gets done.

**The plan is disposable.** A new plan costs about $0.05 in tokens. Fighting a bad plan costs $0.45 to $0.60 and produces worse results. The moment a plan isn't working, discard it and regenerate. I learned this watching an agent spend 40 minutes trying to make a recursive approach work for a problem that needed iteration. New plan in 8 seconds.

**Telegram as control plane.** The `/guidance` command injects a directive into the agent's next hat session. "Wrap the existing code, don't replace it" was six words sent at 1:47 AM that saved the agent from a 2-hour dead end. Course correction, not micromanagement.

**QA is non-negotiable.** Every Builder output passes through a Reviewer. Without enforcement, the agent will skip review when it "feels confident." Confidence and correctness do not correlate.

**Fresh context beats accumulated context.** The foundational insight. Everything else in Ralph exists to enforce it.

**`tools.denied` is a safety net.** Dangerous operations get blocked explicitly in every hat's TOML config. `git push --force`. `rm -rf`. `DROP TABLE`. An agent in a Fixer hat at 3 AM should not be able to force-push to main. Autonomous systems operating unsupervised need guardrails — the same way production databases have read-only replicas and deploy pipelines have approval gates.

## What it actually cost

Mixed-model routing cuts costs roughly 40% compared to running the most capable model on every hat. Each hat gets the model that matches its cognitive demand. Planner needs strong reasoning. Builder needs speed. Reviewer needs analytical depth. Fixer needs targeted precision.

The 28-of-30 overnight run: 5 Planner calls, 30 Builder, 28 Reviewer, 4 Fixer cycles, 2 failures (both due to ambiguous specs, not agent errors). Total: approximately $4.20.

$0.15 per task, running autonomously for 7 hours while I slept. I still find that number hard to believe. It's not the cost that's surprising — it's that the work was actually correct, because the gates were correct.

## What I'd change

Ralph isn't perfect. The event format is too minimal — routing signals aren't enough. The Fixer hat frequently needs to understand *why* the Reviewer flagged an issue, not just *that* it did. I've started embedding structured context — file, line, violation type — in events. Slightly larger event files, fewer wasted Fixer iterations.

The convergence threshold should be dynamic. A fixed threshold of zero critical issues works for most tasks, but a refactoring task will always produce one "suggestion" that's technically an issue but not worth fixing. A dynamic threshold that learns from the task type would help. I'm not sure what the right learning signal is. I'm noodling on it.

Ralplan — the consensus planning loop that runs before code gets written — should support asynchronous Critic feedback. Right now the Critic blocks until the Planner revises. For large plans, the Critic should approve section-by-section, letting the Builder start on approved sections while the Planner fixes rejected ones.

## Why this matters beyond agent tooling

The Ralph principles — filesystem-first state, hat-scoped context, convergence-driven termination — became the foundation for everything else I built across the same six-week period that produced ValidationForge, the open-source verification framework I shipped a few weeks before this post. Same underlying conviction. Autonomous AI systems need machine-verifiable checkpoints, not the agent's confident assertion that the work is done. Ralph enforces it at the orchestration layer. ValidationForge enforces it at the validation layer. Both reject self-certification and demand external evidence. That convergence is not a coincidence — it's what happens when you spend 23,479 sessions watching agents tell you they finished work they didn't.

## Try it

The companion repo at **github.com/krzemienski/ralph-orchestrator-guide** contains the hat rotation orchestrator, convergence detection, pattern definitions, and runnable simulations. The principle behind the system is simple: **an agent that does one thing well, then stops, is more reliable than an agent that tries to do everything at once.** Ralph is the enforcement mechanism.

The boulder never stops. But it does reach the top.

---

If you're an engineering leader rolling out long-running autonomous agents at meaningful scale — and trying to figure out how to keep velocity high without paying for it in 2 AM incidents — I'm taking on a small number of advisory engagements this quarter. The fastest way to reach me is a LinkedIn DM with a one-paragraph note on where you are and where you'd like to be in 90 days.

The blog post this is adapted from is post 8 of 18 in a series on agentic development at scale. Repo and full post linked below.

---

*Nick Krzemienski — building ValidationForge. Six weeks, 23,479 sessions, 3.4M lines of AI code, and a stubborn opinion that AI-generated artifacts should ship with receipts. github.com/krzemienski/ralph-orchestrator-guide*
