# A Single AI Agent Said "Looks Correct." Three Agents Found the P2 Bug.

**Channels:** LinkedIn (native long-form article) + cross-post HN + Reddit r/programming + Dev.to.
**Word count target:** 1,800-2,200 (body, excluding frontmatter and sign-off).
**Send week:** Week 5 — Mon May 18, 8:30am ET.
**Source post:** /Users/nick/Desktop/blog-series/posts/post-02-multi-agent-consensus/post.md
**Companion repo:** github.com/krzemienski/multi-agent-consensus
**Voice notes:** Direct, technical, slightly contrarian. No emojis. Lead with the bug. Diagnose the gap. Ship the artifact.

---

A single AI agent reviewed my iOS streaming code and said "looks correct." Three agents found a P2 bug on line 926 that had been corrupting messages for three days.

That gap between one confident wrong answer and three analyses converging on the real problem is why every code change in my system now goes through a unanimous consensus gate before it ships. I have watched solo agents approve broken code across 929 agent spawns. The fix isn't a smarter agent. The fix is three agents that disagree with each other until they converge.

## The Bug On Line 926

Line 926 of the iOS streaming message handler:

```swift
message.text += textBlock.text
```

Should have been:

```swift
message.text = textBlock.text
```

One character. `+=` instead of `=`. The streaming system accumulated text blocks from the Claude API. Each block contained the full message up to that point, not a delta. So `+=` appended the full accumulated text to what was already there. After three blocks, "Hello" became "HHeHelHello." A five-sentence response turned into an unreadable wall of duplicated text, growing with each chunk.

There was a second root cause, subtler than the first. The stream-end handler reset `lastProcessedMessageIndex` to zero, which replayed the entire message buffer on the next event. Combined with `+=`, messages grew exponentially.

Three days. This sat in the codebase for three days while I shipped on top of it.

I ran a solo agent review on the streaming module first. It read the file top to bottom, checked types, verified function signatures matched the protocol. No issues found. Code was syntactically valid. Types correct. Protocol conformance complete. Everything a single-pass review checks came back clean.

Then I ran three agents with different review mandates against the same code. Alpha caught the `+=`. The API documentation says each text block contains the full message so far, so appending makes no sense. Bravo came at it from a completely different angle: what happens when one stream ends and another begins? That index reset replays the entire buffer. Lead pointed out that the module's own doc comments explicitly say text blocks are cumulative, and the implementation contradicts the docs. Three reasoning paths. Same conclusion.

## Why One Agent Isn't Enough

Ever sat through a code review where the reviewer just agreed with everything? That is what happens when the same entity writes and reviews code. Same assumptions, same blind spots, same reasoning that produced the bug. I have watched this play out across 929 agent spawns. It isn't theoretical.

The Frankenstein merge made it concrete. Two agents worked on the same backend service. Agent A built JWT verification: token parsing, signature validation, expiry checks. Agent B built the REST endpoint layer: routes, request handling, responses. Neither knew the other existed.

The merge produced valid code. TypeScript compiled clean. Linter passed. The application served raw JWT verification internals as a REST endpoint. Token payloads. Signature validation state. Expiry calculations. All exposed to unauthenticated callers.

A security vulnerability that passed every static check because each agent's contribution was individually correct. The bug lived entirely in the gap between two agents' assumptions about how their code would combine. No single-agent review would have caught it, because each agent would just confirm its own work looked fine.

## Three Roles, Not Three Copies

The system does not run three identical agents. Same prompt three times just gives you three copies of the same blind spot. Each agent gets a different review mandate targeting a different failure domain.

**Lead** handles architecture and consistency. Does this change fit existing patterns? Does it introduce duplicate abstractions? Lead would not have found the `+=` bug. That is not an architecture issue. But Lead caught the Frankenstein merge immediately because the merged code blew right through the service's architectural boundaries.

**Alpha** does line-by-line logic. Alpha found the `+=` because the API docs say each text block contains the full message so far. If `message.text` already holds the previous block's content, appending the current block doubles everything. Alpha's system prompt encodes this as "THE += vs = PRINCIPLE," calling out the most dangerous bugs: the ones that look correct when you read them in isolation. The bug only shows up when you think about what the data actually contains.

**Bravo** thinks about runtime. Will this work deployed? Race conditions? Realistic failure modes? Bravo found the index reset by reasoning through the streaming lifecycle: stream ends, next stream begins, index goes to zero, handler replays every message from the buffer. Bravo's prompt says it plainly: "Alpha reads code. You RUN things."

Lead found the scope: both SDK and CLI execution paths shared the flaw. Alpha found the line and the semantic error. Bravo found the user-visible symptom: sending "What is 2+2?" produced "Four.Four." during streaming. None of those would have been enough alone. Together, complete picture.

## The Gate Is The Simplest Part

A `ThreadPoolExecutor` runs all three agents in parallel. Each agent runs as a separate `claude --print` subprocess with its role-specific system prompt. No shared state during evaluation. The gate checks for unanimity.

Unanimous voting. Not majority. Any agent raises a concern, the gate blocks. This is deliberately conservative, and that is the whole point. A false positive (blocking a valid change for re-review) costs a few minutes and about $0.15. A false negative (shipping the `+=` bug) costs three days of broken messages and trust you cannot buy back.

The re-validation step is critical and easy to miss. When a gate fails and you fix the issue, ALL THREE agents re-validate, not just the one that originally failed. This catches fixes that solve one problem but introduce a new one that only a different agent's perspective would spot. Three fix cycles maximum. If three agents cannot agree after three rounds, escalation goes to a human. In practice, most gates converge on the first or second cycle.

## Four Phases, Four Gates

The framework is not just one gate. It runs four phases, each with its own checkpoint:

```
explore  →  Gate 1  →  audit  →  Gate 2  →  fix  →  Gate 3  →  verify  →  Gate 4
```

**Explore** maps the codebase. All three agents independently trace the architecture. The gate makes sure everyone has a complete picture before the deep audit. This prevents the failure mode where an agent audits code it doesn't understand.

**Audit** is the deep review. This is where the `+=` got caught.

**Fix** verifies fixes actually address the findings. All three agents check independently. Catches the "fix that creates a new bug" pattern.

**Verify** is end-to-end. Does the system actually work? Bravo's biggest moment.

Lead runs on Opus for deeper architectural reasoning. Alpha and Bravo run on Sonnet, fast enough for line-level analysis and system-level checks. All three run in parallel, so wall-clock time equals the slowest agent (typically 15-30 seconds per gate). Four-gate pipeline: roughly $0.60 total.

## Prompts That Learn

Here is the part I did not expect. Each agent's system prompt accumulates real bug patterns over time. After 200 gates, Alpha has 47 specific patterns to check. Bravo has 31. Lead has 22. Every bug the system catches becomes a permanent instruction.

When a bug gets caught, I extract the detection heuristic (what made it catchable) and encode it as six lines in the relevant agent's prompt. Alpha's 47 patterns cover streaming semantics, off-by-one errors in pagination, optional chaining pitfalls, async race conditions. Each one is a scar from a real incident.

Maintenance cost? Basically zero. They are version-controlled text files. When something slips through, I add a pattern. After 200 gates, the system catches things gate 1 would have missed. The prompts compound.

## File Ownership: Preventing The Frankenstein Merge

Multi-agent teams have a coordination problem consensus alone does not solve: who owns which files?

The Frankenstein merge happened because two agents edited adjacent code without knowing about each other. File ownership via glob patterns prevents it. Before an agent writes to a file, the orchestrator checks the ownership map. File belongs to another agent? Blocked. Two agents literally cannot edit the same file.

Humans notice when they are about to touch someone else's code. The directory is unfamiliar, the patterns look different, the imports are foreign. Agents do not have that spatial awareness. They will edit whatever the prompt tells them to, regardless of who else is working in the same area. Programmatic enforcement replaces the social awareness humans take for granted.

When two agents genuinely need the same file, the lead makes the change and distributes the result. Single writer, everyone else reads.

## Scaling Consensus To Planning

The same three-perspective pattern works for planning. Three agents: Planner, Architect, and Critic.

Planner decomposes work into tasks. Architect evaluates technical soundness. The Critic's job is to break things. Challenge every assumption, find the failure mode the other two are too close to see. The Critic is not trying to help. It is trying to find what goes wrong.

The war story that proved this: a Supabase auth migration. Planner decomposed it into 14 tasks. Clean decomposition, reasonable ordering, 1-2 hours each. Architect vetoed it. Why? Supabase Row Level Security policies reference `auth.uid()`, which returns Supabase's internal user ID, not a custom JWT's subject claim. Seven of the 14 tasks assumed RLS compatibility. They would have compiled. They would have passed type checks. They would have failed silently at runtime, letting any authenticated user read any other user's data.

The Critic piled on: no rollback strategy. If task 9 fails, tasks 1-8 already modified the auth schema. Only recovery is a full database restore.

Three rounds of iteration. Final plan: 11 tasks instead of 14, an RLS compatibility layer, and rollback checkpoints at tasks 4, 7, and 10. Cost of those three planning rounds: under $2. Cost of shipping a silent auth bypass: I do not want to think about it.

## When Not To Use Consensus

It costs money. Roughly $0.15 per gate, $0.60 for a four-phase pipeline. So when is it worth it?

**Always use it for:** changes touching shared state, auth, data persistence, or streaming. Multi-agent merges where code from different agents gets combined. Cross-module or interface changes. Anything involving security, user data, or payments.

**Skip it for:** string constant updates, typo fixes, log line additions. Single-file changes with zero behavioral impact.

**Know its limits.** For genuinely novel work where no agent has relevant experience, consensus can produce false confidence. Three agents agreeing does not mean they are right if none of them has seen the problem domain before. I am honestly not sure how to solve that one yet. If three agents cannot agree in five rounds, the disagreement is real and needs a human.

## The Asymmetry That Makes It Work

False positive: gate blocks a valid change. Costs five minutes and $0.15 for re-review. False negative: gate ships the `+=` bug. Costs three days of corrupted messages and user trust you cannot buy back. Every design choice here leans toward the first failure mode. Unanimous voting. Distinct mandates. Institutional knowledge. File ownership. Full re-validation after fixes. All weighted the same direction.

False positive rate runs around 8%. The bugs the other 92% catches would have shipped. The `+=` would have corrupted every message in the iOS app. The Frankenstein merge would have exposed JWT internals to unauthenticated callers. The Supabase RLS gap would have been a data breach.

Run it against your own codebase:

```bash
pip install multi-agent-consensus
consensus run --target ./your-project
```

The repo includes the streaming audit example with the exact gate output that caught the `+=` bug, plus the role definitions, the orchestrator, and the four-phase pipeline.

→ **github.com/krzemienski/multi-agent-consensus**

This consensus framework was built during the same 90-day stretch that produced ValidationForge — the no-mock validation platform that captures the evidence side of the same problem (github.com/krzemienski/validationforge for that one).

If you are running AI agents in production and you keep finding bugs that compiled clean, type-checked clean, and shipped broken anyway, the gap is not in the agents. It is in the review layer. I am taking on a small number of advisory engagements this quarter for engineering teams adopting agentic development at scale — specifically helping leadership build verification gates that match the velocity gains. If your team is shipping AI-generated code and starting to feel the validation pain, send me a LinkedIn DM with a one-paragraph note on where you are now and where you would like to be in 90 days. I will respond within two business days.

The fastest growing failure mode in agentic dev right now is one confident agent approving its own work. The cheapest fix is three agents that disagree until they converge.

---

*Nick Krzemienski — building consensus gates and ValidationForge. 23,479 sessions, 27 projects, one stubborn opinion: AI-generated code should ship with three independent verdicts. github.com/krzemienski/multi-agent-consensus*
