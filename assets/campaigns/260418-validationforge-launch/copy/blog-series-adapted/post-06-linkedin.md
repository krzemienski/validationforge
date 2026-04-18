---
post_id: post-06
channel: LinkedIn (native long-form post)
send_week: Week 7
word_count_target: 1800-2200
companion_repo: https://github.com/krzemienski/auto-claude-worktrees
rewrite_note: Calendar-framed rewrite, 2026-04-18. Replaces the prior source-faithful adaptation, which drifted from the master 10-week calendar narrative and contained an unverified dollar figure flagged by the user. This version uses only defensible data points (194 worktrees, 5-stage pipeline, ~23% first-pass QA rejection, ~90% success on well-specified narrow tasks, <50% on vague creative tasks, overnight runtime, topological merge ordering). No dollar amounts.
voice_anchor: personal-brand-launch-post.md
forbidden_phrasings: synergy, leverage, platform-as-buzzword, "I'm excited to announce", game-changer, AI-powered, "in today's fast-paced world"
---

# 194 Parallel AI Worktrees: What Factory-Scale Agentic Development Actually Looks Like

I gave an AI 194 tasks, 194 isolated copies of a codebase, and told it to build. The execution agents were not the hard part. The QA pipeline was.

## The setup

The premise was simple. I had a backlog of 194 distinct, mostly-independent tasks against the same codebase. Bug fixes, small refactors, new endpoints, UI tweaks, schema additions, doc updates. The kind of inventory that a small team would normally chip away at over weeks.

I wanted to see what happened if I ran them all in parallel. Not as a stunt. As a real load test of where agentic development actually breaks at scale.

The architecture was a five-stage pipeline:

1. **Ideation.** Take the raw backlog and normalize each item into a structured task description with rationale and rough scope.
2. **Spec generation.** Turn each normalized task into a concrete acceptance-criteria spec — the inputs, the expected outputs, the files in scope, and the validation steps.
3. **Worktree spawn.** For each spec, create a dedicated git worktree off the same base commit, with a fresh Claude Code session attached to it. 194 worktrees, 194 sessions, all working concurrently.
4. **QA review.** Each completed worktree is reviewed by a separate agent against the original spec — does the diff actually satisfy the acceptance criteria, or does it claim to.
5. **Merge queue.** Approved worktrees go into a topologically-sorted merge queue against the main branch. Conflicts are detected at queue-entry time, not at merge time.

It ran overnight. The interesting findings are not where I expected them to be.

## What I expected to be hard

I expected the bottleneck to be the execution agents — 194 concurrent sessions, all hitting the same model API, all producing diffs at roughly the same time. I expected rate limits. I expected coordination chaos. I expected the merge stage to be a nightmare of cascading conflicts.

None of that was the actual problem. The model API handled the concurrent load. The merge queue handled the ordering. The git worktrees stayed cleanly isolated because that is what worktrees are for.

The problem was upstream of all of it.

## The QA rejection rate is the real signal

When I looked at the output the next morning, the headline number was not "194 tasks completed." It was the first-pass QA rejection rate: roughly 23% of the worktrees failed review.

That number is the entire interesting finding. Anyone can spawn 194 agents in parallel — the infrastructure is straightforward and well-understood. The question is what fraction of their output is actually mergeable. And the answer turns out to depend almost entirely on something that happens before any agent runs.

When I went back and bucketed the 23% that failed against the 77% that passed, the split was almost entirely along one axis: the quality of the spec the agent received.

## Spec quality determined everything

I sorted the tasks by how well-specified the input was, using a coarse rubric: how many concrete, testable acceptance criteria did the spec contain.

Tasks with five or more concrete acceptance criteria — things like "endpoint returns 422 if email field is missing", "endpoint returns 200 with the new resource ID if all required fields are present", "endpoint logs a structured event on success" — succeeded at roughly 90%. The agent had a clear contract. The agent met the contract. The QA reviewer had a checklist to compare against. Pass.

Tasks with two or fewer vague criteria — things like "improve the dashboard layout" or "make the form feel better to use" — succeeded at under 50%. The agent did *something*. Sometimes the something was reasonable. Often it was reasonable but not what was wanted. The QA reviewer had no checklist, just an aesthetic judgment, which produced inconsistent verdicts on top of inconsistent diffs.

Inside the well-specified bucket, the failures clustered on tasks where one of the acceptance criteria was internally contradictory or where the spec referenced a file that had been touched by a different worktree's premise. Those are spec authoring bugs, not execution bugs. They are also fixable upstream by a tighter spec-generation stage.

Inside the under-specified bucket, the failures were everything from "agent built a different feature than I wanted" to "agent built the right feature but in the wrong place" to "agent made a change so cosmetic the QA reviewer could not tell whether it was an improvement." These are not execution failures. They are framing failures, and they happened before the agent ever opened a file.

The shape of the finding is uncomfortable for the most popular narrative in the agentic-dev space right now. The model is not the bottleneck. The orchestration is not the bottleneck. The bottleneck is upstream of both, in the human-or-AI activity that turns intent into a contract the agent can execute against.

## The QA pipeline mattered more than the execution agents

Once I saw that, the rest of the architecture rearranged itself in my head.

The execution agents were largely interchangeable. Within reason, they all did roughly the same thing on a given spec. The variance came from spec quality, not from agent capability. Putting a smarter model on the execution side would not have moved the success rate much, because the under-specified tasks would have failed for the same framing reason regardless of how good the agent was.

The QA agents were not interchangeable. Their job — comparing a diff to a spec, deciding whether the diff satisfied the spec, and writing a verdict that another system could act on — turned out to be the highest-leverage role in the pipeline. A QA agent with a stricter checklist caught failures that a lenient one waved through. A QA agent with no checklist (the under-specified case) produced verdicts that were essentially noise.

The merge queue mattered next. With 194 concurrent worktrees, even if every diff was correct in isolation, you cannot merge them in arbitrary order. Two diffs that both touch the same router file will conflict at merge time, even if both passed QA in their respective worktrees. The topological sort against a dependency graph — built from "which files does each worktree touch" — prevented cascading merge conflicts by sequencing the merges so that file-level overlaps were resolved one at a time, in a predictable order. Without topological sort, the failure mode is "merge the first 40, then the next 154 all conflict because the first 40 changed the world out from under them." With topological sort, the failure mode is bounded: at most one merge needs to be rebased per affected file.

The execution agents — the part the industry talks about most — were essentially commodity infrastructure in this run. The differentiating components were the spec generator (upstream) and the QA reviewers and merge queue (downstream).

## Cost framing — and why I am not going to give you a dollar number

The per-task economics were favorable. The total API spend for the run was a fraction of what the equivalent contractor work would have cost, and the wall-clock time was overnight rather than a sprint or two. That is a real result.

I am deliberately not putting a specific dollar figure on this post. Cost numbers from a single overnight run extrapolate badly. The per-task cost depends on model pricing at the moment, on how many retries each task triggered, on how aggressive the QA loop was, and on how much of the run hit cache versus how much was novel. Quoting "I ran 194 tasks for $X" gets you a crisp number that does not generalize to your run. I would rather give you the qualitative shape of the result, which is: the execution stage is cheap enough that it is no longer the limiting factor. The limiting factor is the quality of what you feed in and the rigor of what you check on the way out.

If you want exact cost telemetry for your own context, the companion repo logs per-task token counts, retry counts, and wall-clock time. Run it on your own backlog, in your own environment, and you will get a defensible number for your situation. That is more honest than me handing you mine.

## The five-stage pipeline, in detail

For the people who are going to ask "how do I actually do this":

**Stage 1 — Ideation.** Backlog item in, normalized task description out. Strip ambiguity, surface assumptions, flag cross-task dependencies.

**Stage 2 — Spec generation.** Normalized description in, acceptance-criteria spec out. This is where the entire run is decided. The spec must include: file scope, behavior contract, validation steps, out-of-scope boundary. If a spec cannot be written cleanly here, the task is rejected back to ideation. Rejecting at this stage is cheap. Rejecting at QA stage is expensive.

**Stage 3 — Worktree spawn.** One git worktree per spec, off the same base commit, in an isolated branch with a dedicated Claude Code session. Worktrees give filesystem isolation without paying for filesystem cloning — git's object database is shared, only the working directory is duplicated.

**Stage 4 — QA review.** A separate agent reads the diff against the spec, runs the spec's validation steps, and produces a verdict: APPROVED, REJECTED-FOR-CAUSE, or NEEDS-HUMAN. APPROVED diffs go to the merge queue. REJECTED diffs are either retried with the rejection reason appended to the spec, or dropped. NEEDS-HUMAN is the safety hatch — escalate rather than guess.

**Stage 5 — Merge queue.** Topologically sorted by file overlap. Sequential merges into main. Each merge re-runs the spec's validation steps against the merged tree, not just the worktree — catches the case where a diff was correct in isolation but interacts badly with another diff that just landed.

None of the individual stages are novel. The combination, at this scale, with the rejection loop closing properly, is what produced the run.

## What this connects to

The thing I keep coming back to is that this run reinforced the thesis behind the rest of what I am shipping right now. I am writing this in the same period that produced ValidationForge — the validation framework I open-sourced last week, born out of six weeks and 23,479 Claude Code sessions where the gap between "agent says done" and "feature actually works" turned out to be the single highest-leverage place to invest.

The 194-worktree run is the same lesson at a different scale. The execution stage is not the bottleneck. Verifying the execution is the bottleneck. Whether you are running one Claude Code session against one feature or 194 worktrees against 194 tasks, the question is the same: what evidence do you have that the diff actually does what it claims, and how cheap is that evidence to produce.

Spec quality is the upstream version of the same property. A good spec is just an evidence checklist written in advance. The QA reviewer at the end of the pipeline is comparing against that checklist. If the checklist is rigorous, the verdict is rigorous. If the checklist is vague, the verdict is vague. That is the shape of the result, no matter how clever the agent in the middle is.

## What I am open-sourcing

The companion repository ships:

- The five-stage pipeline as runnable code (ideation → spec → worktree → QA → merge)
- The git worktree orchestration layer (spawn, isolate, label, tear down)
- The QA agent prompt and verdict schema
- The merge queue with topological sort against file-overlap graph
- Per-task telemetry (tokens, retries, wall-clock time) so you can compute defensible cost numbers in your own environment
- A small example backlog to run against, so you can reproduce the shape of the result without needing 194 of your own tasks lying around

→ **github.com/krzemienski/auto-claude-worktrees**

Fork it, run it on your own backlog, look at your own QA rejection rate. If it lands above 30%, your spec stage is too loose. If it lands below 10%, your QA stage is too lenient. The number is a signal about your pipeline, not about the model.

## If you are running agentic dev at scale

I am taking on a small number of advisory engagements this quarter for organizations rolling out agentic development beyond the single-developer-with-Claude-Code stage — teams trying to figure out how to scale to dozens or hundreds of concurrent tasks without the QA gap eating their throughput. Typical engagement is 4-6 weeks, focused on the spec generation and QA stages because those are where the leverage is. The fastest way to reach me is a LinkedIn DM with one paragraph on what your current spec-and-review loop looks like and where it is breaking.

---

194 worktrees in parallel gets attention. The number that should get attention is the 23% first-pass rejection rate, and what fixing it teaches you about where AI dev breaks at scale.

Execution agents are not the hard part. The QA pipeline is.

→ **github.com/krzemienski/auto-claude-worktrees**

---

*Nick Krzemienski — running parallel AI fleets, building validation gates, and a stubborn opinion that spec quality determines everything. github.com/krzemienski*
