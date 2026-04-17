---
name: consensus-engine
description: "Use when a single-validator PASS is not enough confidence — high-stakes features (payments, auth, data migrations, security surfaces), pre-ship release gates, regression review on large refactors, flake hunting, and audit trails for regulated work. Spawns N (≥2, default 3) independent validator agents against the same journey list, each with its own isolated evidence subdirectory, then synthesizes their per-journey verdicts into a single consensus verdict with a confidence score (UNANIMOUS → HIGH, MAJORITY → MEDIUM, SPLIT → LOW). Disagreements trigger root-cause investigation before the final verdict is emitted. Reach for it on phrases like 'consensus validation', 'multi-agent verdict', 'get a second opinion', 'validate with N agents', 'pre-ship gate', 'confidence-scored verdict', 'agreement-based review', or when you want to catch flaky behavior with parallel independent runs. Not for coverage fan-out (use parallel-validation or forge-team); not without a validation plan (run create-validation-plan first); not on a failing preflight."
triggers:
  - "consensus validation"
  - "multi-reviewer validation"
  - "multi-agent validation"
  - "validate with consensus"
  - "unanimous validation"
  - "consensus verdict"
  - "get a second opinion"
  - "confidence score"
  - "confidence-scored verdict"
  - "N independent validators"
  - "pre-ship gate"
  - "flake hunting"
---

# Consensus Engine

Orchestrate the CONSENSUS engine: spawn N (≥2, default 3) independent validator agents
against the **same** feature, let each capture evidence blindly, then synthesize their
per-journey verdicts into a single consensus verdict with a confidence score derived
from the level of agreement. Disagreements trigger root-cause investigation before a
final verdict is emitted.

This skill is the top-level orchestration protocol for the consensus engine. It reuses
the parallel-validation fan-out pattern but differs in intent: every validator receives
the **same** journey list (not partitioned work) and the goal is **agreement**, not
**coverage**.

The authoritative contract for this skill is `rules/consensus-engine.md`. In any
conflict between this SKILL.md and the rule, the rule wins.

## When to Use

- **High-stakes features** where a single-validator PASS is insufficient confidence
  (payments, auth, data migrations, security-sensitive surfaces)
- **Regression review** before merging a large refactor — N validators each re-run the
  regression suite and must agree the change is safe
- **Pre-ship gate** in release pipelines — block the ship if validators disagree,
  forcing explicit human review of the dissent rather than silent single-validator pass
- **Flake hunting** — if a journey passed once but you suspect timing-dependent
  behavior, N independent runs either agree (stable) or split (flaky)
- **Audit trails** for regulated work — an evidence package with N independent
  verdicts is more defensible than a single verdict

Do **not** use when:
- Journeys are independent and coverage matters more than agreement → use
  `skills/parallel-validation` or `skills/forge-team` instead
- The project has no validation plan yet → run `skills/create-validation-plan` first
- Preflight has not been run → consensus cannot start on a broken build; run
  `skills/preflight` first

## Protocol

### Step 1 — Read the validation plan

Load the existing validation plan (from `skills/create-validation-plan` output or the
project's agreed journey list). Every validator receives the **identical** journey
list. Do not partition, do not reorder, do not hide any journey from any validator —
independence requires identical inputs.

Verify:
- Plan exists and lists ≥1 journey with explicit PASS criteria
- Each journey has evidence requirements defined
- Preflight has passed (build compiles, services running)

If any of these fail, STOP. Do not spawn validators against a broken plan or a broken
system.

### Step 2 — Spawn ≥2 validators in parallel

For each validator `N` in `1..validator_count` (default 3), launch a consensus
validator agent via the Task tool with `run_in_background=true`. Each validator gets:

- The full, identical journey list
- An exclusive evidence subdirectory: `e2e-evidence/consensus/validator-{N}/`
- The Iron Rules (no mocks, no test files, cite specific evidence)
- An explicit "you are validator N of M, working independently" framing
- A strict instruction: **do not read other validators' evidence directories**

Example launch sequence (conceptual — use the Task tool):

```
Validator 1: Task(subagent_type="consensus-validator", run_in_background=true,
                  prompt="...journeys... evidence dir: e2e-evidence/consensus/validator-1/")
Validator 2: Task(subagent_type="consensus-validator", run_in_background=true,
                  prompt="...journeys... evidence dir: e2e-evidence/consensus/validator-2/")
Validator 3: Task(subagent_type="consensus-validator", run_in_background=true,
                  prompt="...journeys... evidence dir: e2e-evidence/consensus/validator-3/")
```

Launch all validators in a single message (parallel tool calls) so they start as close
in time as possible. Staggered starts bias later validators with environmental drift
(caches, state accumulation).

### Step 3 — Monitor validators (never interfere)

Poll validator status via `TaskOutput`. Coordinator responsibilities are strictly
limited:

- **Watch** for completion (each validator writes `verdict.md` to its own subdir)
- **Do not** answer validator questions that would bias them toward a verdict
- **Do not** inspect validator evidence mid-run
- **Do not** write anything to any validator's subdirectory
- **Do not** share one validator's progress with another

If a validator is stuck >10 minutes on the same journey, it may be reassigned or
restarted — but only with a **fresh** evidence subdirectory. Never resume a stalled
validator's partial evidence; stale evidence is worse than missing evidence.

### Step 4 — Spawn the consensus-synthesizer agent

When **all** validators have completed (every `validator-N/verdict.md` exists and is
non-empty), and **only** then, spawn the `consensus-synthesizer` agent via the Task
tool. Partial synthesis is forbidden — a missing validator means incomplete input and
the synthesizer cannot compute a meaningful agreement ratio.

The synthesizer receives:
- The list of validator evidence directories
- The path to emit the unified report (`e2e-evidence/consensus/report.md`)
- The active `rules/consensus-engine.md` synthesis states table

The synthesizer applies `skills/consensus-synthesis` to compute per-journey verdicts
and confidence scores.

### Step 5 — If disagreement detected, invoke disagreement analysis

The synthesizer reports a disagreement whenever any journey is not UNANIMOUS
(MAJORITY_PASS, MAJORITY_FAIL, or SPLIT per `rules/consensus-engine.md`). On
disagreement, invoke `skills/consensus-disagreement-analysis` before emitting the
final report. That skill:

- Uses `skills/sequential-analysis` to root-cause the divergence
- Classifies the cause (flake, environmental drift, evidence interpretation,
  genuine bug discovered by minority)
- Either resolves the disagreement (promoting the correct verdict with a citation)
  or escalates as `DISAGREEMENT_UNRESOLVED` with LOW confidence

Never silently drop the minority. Every dissent is recorded in the report, whether
resolved or escalated.

### Step 6 — Emit the unified consensus report

The synthesizer writes `e2e-evidence/consensus/report.md` using
`templates/consensus-report.md`. The report includes:

- Per-journey synthesis state, final verdict, confidence tier
- Vote tabulation (per-validator PASS/FAIL for each journey)
- Evidence citations (which validator's evidence supports the final verdict)
- Dissent record (which validators disagreed and why, if applicable)
- Overall run verdict (weakest-journey rule — one SPLIT → overall
  DISAGREEMENT_UNRESOLVED)

Only the synthesizer writes this file. The coordinator does **not** edit the report;
its job is done when the report exists.

## File Ownership

Consensus file ownership is absolute. A write outside the allowed slice invalidates
the independence guarantee and the run must be discarded. See
`rules/consensus-engine.md §File Ownership` for the authoritative table.

| Role | Writes To | Reads From |
|------|-----------|------------|
| **Coordinator** (this skill) | *nothing* | `validator-N/verdict.md` (completion detection only) |
| **Validator-N** | `e2e-evidence/consensus/validator-{N}/` exclusively | source code, runtime artifacts |
| **Synthesizer** | `e2e-evidence/consensus/report.md` exclusively | all `validator-N/` directories |

```
e2e-evidence/
  consensus/
    validator-1/     ← Validator 1 ONLY
      step-01-*.{png,json,txt}
      verdict.md
    validator-2/     ← Validator 2 ONLY
      step-01-*.{png,json,txt}
      verdict.md
    validator-3/     ← Validator 3 ONLY
      step-01-*.{png,json,txt}
      verdict.md
    report.md        ← Synthesizer ONLY
```

The coordinator owning nothing is the load-bearing invariant — a coordinator that
captures evidence has an implicit bias toward its own observations and contaminates
the independence property that gives consensus its value.

## Integration

| Skill | Relationship |
|-------|-------------|
| `skills/parallel-validation` | Source of the fan-out orchestration pattern. Consensus reuses the parallel spawn/monitor/collect cycle but every agent receives the identical journey list rather than partitioned work. |
| `skills/sequential-analysis` | Invoked by `skills/consensus-disagreement-analysis` when validators disagree. Provides the root-cause methodology for resolving divergence. |
| `agents/verdict-writer` | The consensus-synthesizer is a specialization of verdict-writer — it applies the synthesis states table and confidence formula on top of the standard verdict-writing discipline. |
| `skills/preflight` | MUST run before spawning validators. Consensus cannot start on a broken build; a failing preflight invalidates all downstream verdicts regardless of validator agreement. |
| `skills/consensus-synthesis` | The voting and confidence-scoring skill used by the synthesizer agent. Defines UNANIMOUS → HIGH, MAJORITY → MEDIUM, SPLIT → LOW. |
| `skills/consensus-disagreement-analysis` | Invoked in Step 5 when any journey is not UNANIMOUS. Uses sequential-analysis to classify and resolve divergence. |
| `rules/consensus-engine.md` | Authoritative contract. Defines roles, file ownership, synthesis states, confidence formula, and iron rules. This skill implements that contract. |
| `templates/consensus-report.md` | Report format emitted by the synthesizer in Step 6. |

## Iron Rules (carry-over)

1. **No mocks, stubs, or test doubles.** Validators validate the real system.
2. **No test files.** Validation captures evidence, it does not author code.
3. **No unauthored verdicts.** Every PASS/FAIL cites specific evidence with a file path.
4. **No cross-validator contamination.** Validators do not read each other's evidence.
5. **No partial synthesis.** All N validators must complete before the synthesizer runs.
6. **No silent dissent.** Every minority verdict is recorded, resolved, or escalated.
7. **No coordinator evidence.** The coordinator spawns, monitors, and hands off — nothing else.
