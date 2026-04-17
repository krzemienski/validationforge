---
phase: P13
name: Campaign closeout + handoff
date: 2026-04-16
status: pending
gap_ids: []
executor: researcher
validator: code-reviewer
depends_on: [P12]
---

# Phase 13 — Campaign Closeout + Handoff

## Why

Phase 12 proved no regressions and benchmark is ≥ A. All gaps are CLOSED. This
phase ships the artifacts, flips plan status, tags git, and writes the closeout
summary so the next session knows the campaign is done.

## Pass criteria

1. `evidence/13-closeout/CAMPAIGN-SUMMARY.md` exists and contains:
   - Campaign duration (P00 start → P12 PASS)
   - Gaps closed per phase (count + IDs)
   - Benchmark before / after
   - BLOCKED_WITH_USER items (if any) with user-facing note
   - Recommended next steps for V1.5+
2. `plan.md` frontmatter flipped: `status: complete`.
3. `GAP-REGISTER.md` change log appended with final entry.
4. Git tag `vf-gap-remediation-260416-complete` created on the final commit.
5. README.md updated with current benchmark grade + link to campaign summary.
6. Any BLOCKED_WITH_USER items are also opened as tracking plans under
   `plans/260416-*-<slug>/` to ensure they aren't forgotten.
7. `logs/state.json` `current_phase == "DONE"`.

## Inputs

- `GAP-REGISTER.md`
- All `validators/P??-verdict.md`
- `evidence/12-regression/`
- `.vf/benchmarks/` (latest + previous)
- README.md

## Steps

1. Dispatch executor (researcher).
2. Executor synthesises CAMPAIGN-SUMMARY.md.
3. Executor flips plan.md status; updates README with benchmark link.
4. For every BLOCKED_WITH_USER: executor scaffolds a follow-up plan dir with
   stub plan.md.
5. Commit: `feat(gap-remediation): campaign closeout — <count> gaps closed`.
6. `git tag vf-gap-remediation-260416-complete`.
7. Dispatch validator to verify every pass criterion.

## Evidence outputs

| File | Source |
|------|--------|
| `evidence/13-closeout/CAMPAIGN-SUMMARY.md` | executor synthesis |
| `evidence/13-closeout/plan-status-diff.patch` | plan.md status flip |
| `evidence/13-closeout/readme-diff.patch` | README update |
| `evidence/13-closeout/tag-commit.txt` | `git tag` output + commit SHA |
| `evidence/13-closeout/followup-plans.md` | list of new plan dirs (if any) |

## Failure modes

- **Any verdict file missing:** halt; this phase cannot run until Phase 12
  produces the missing verdict.
- **Tag already exists:** delete only after confirming with user (risky).
- **README update conflicts with concurrent doc work:** rebase; re-apply.

## Duration estimate

45–90 min.
