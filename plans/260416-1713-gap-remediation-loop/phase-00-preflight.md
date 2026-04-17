---
phase: P00
name: Preflight + baseline snapshot
date: 2026-04-16
status: pending
gap_ids: []
executor: researcher
validator: code-reviewer
---

# Phase 00 — Preflight + Baseline Snapshot

## Why

Campaign cannot begin until the initial state is captured and ambiguous questions
(U1–U3 from `plan.md`) are resolved. This phase is read-only except for writing
baseline snapshots and `logs/state.json`.

## Pass criteria

1. `logs/state.json` exists with valid schema (see LOOP-CONTROLLER.md) and
   `current_phase == "P00"` then advances to `"P01"`.
2. `evidence/00-preflight/baseline.md` exists and contains:
   - Git branch + HEAD SHA
   - Output of `git status --short` (expected: clean or only plan dir)
   - `.vf/benchmarks/` latest file path + score
   - Count of skills (disk), commands (disk), hooks (disk), agents (disk), rules (disk)
3. `evidence/00-preflight/inventory-diff.txt` exists with CLAUDE.md vs disk diff.
4. `evidence/00-preflight/active-plan-state.md` exists with summary of
   `plans/260411-2305-gap-validation/run.sh` phases and their current evidence.
5. `logs/decisions.md` exists with answers to U1, U2, U3 (from user, via
   AskUserQuestion).
6. No hooks/policies modified.

## Inputs

- `CLAUDE.md` for claimed inventory
- `plans/260411-2305-gap-validation/run.sh`
- `plans/260411-2305-gap-validation/evidence/`
- `.vf/benchmarks/benchmark-2026-04-11.json`
- `GAP-REGISTER.md`

## Steps

1. Dispatch executor sub-agent (researcher) with this phase file.
2. Executor runs:
   - `git rev-parse HEAD`, `git status --short`, `git branch --show-current`
   - `ls -1 .vf/benchmarks/`, read newest
   - `ls -1 skills/`, `ls -1 commands/`, `ls -1 hooks/`, `ls -1 agents/`, `ls -1 rules/`
   - Read CLAUDE.md inventory section; diff against disk counts
   - Read `plans/260411-2305-gap-validation/run.sh` and list phase markers
   - Write all outputs to `evidence/00-preflight/`
3. Main orchestrator asks user the three unresolved questions via AskUserQuestion:
   - **U1:** CONSENSUS/FORGE → test in Phase 08 or defer to V1.5/V2.0?
   - **U2:** Skill deep-review scope for Phase 07 — all 38 remaining, or top-20?
   - **U3:** Spec 015 disposition — cherry-pick features or drop entirely?
4. Answers written verbatim to `logs/decisions.md`.
5. Main orchestrator writes initial `logs/state.json` with `current_phase: "P00"`
   then flips to `"P01"` once validator returns PASS.
6. Dispatch validator sub-agent (code-reviewer) with this phase file + criteria.

## Evidence outputs

| File | Source |
|------|--------|
| `evidence/00-preflight/baseline.md` | Executor synthesis |
| `evidence/00-preflight/inventory-diff.txt` | Executor diff |
| `evidence/00-preflight/active-plan-state.md` | Executor summary |
| `evidence/00-preflight/git-status.txt` | `git status --short` output |
| `evidence/00-preflight/git-head.txt` | `git rev-parse HEAD` |
| `logs/decisions.md` | Main orchestrator (user answers) |
| `logs/state.json` | Main orchestrator |

## Validator prompt (expand from validator-template.md)

Phase: P00
Criteria: all 6 listed above
Output: `validators/P00-verdict.md`

## Failure modes

- **Git state dirty beyond plan dir:** halt; ask user to commit or stash before
  proceeding.
- **No benchmark files:** record as risk; do NOT block — Phase 05/12 will regenerate.
- **User declines to answer U1–U3:** default: U1=defer, U2=top-20, U3=drop. Record
  decision + rationale. Flag for Phase 13 review.

## Duration estimate

30–45 min (mostly executor scanning + user Q&A).
