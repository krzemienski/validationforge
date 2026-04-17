---
phase: P11
name: Spec 015 quarantine decision
date: 2026-04-16
status: pending
gap_ids: [M6]
executor: researcher
validator: code-reviewer
depends_on: [P00]
---

# Phase 11 — Spec 015 Quarantine Decision

## Why

Per CAMPAIGN_STATE.md, Spec 015 (history tracking) was quarantined with
~17K net deletions. Policy: revisit 2026-07-01, drop 2026-10-01. Decision
U3 from Phase 00 answers: cherry-pick or drop entirely.

## Pass criteria

1. `evidence/11-spec-015/diff-review.md` summarises:
   - What Spec 015 deleted (grep CAMPAIGN_STATE + quarantine branch diff)
   - What it added
   - Why it was quarantined (risk classification)
2. Decision recorded in `docs/SPEC-015-DISPOSITION.md`:
   - `DROP` → full removal, quarantine branch deleted, VALIDATION_MATRIX
     updated to note closure
   - `CHERRY_PICK` → specific commits listed; applied as a new plan with
     manual review; quarantine status remains until cherry-pick plan closes
3. `VALIDATION_MATRIX.md` updated to reflect decision.
4. `CAMPAIGN_STATE.md` updated to reflect decision.

## Inputs

- `logs/decisions.md` (U3)
- `CAMPAIGN_STATE.md` (Spec 015 rows)
- `VALIDATION_MATRIX.md` (Spec 015 row)
- Git quarantine branch (executor discovers via `git branch -a | grep 015`)

## Steps

1. Dispatch executor.
2. Executor discovers quarantine branch; captures `git log` summary.
3. Executor writes diff review.
4. Per U3: execute DROP or CHERRY_PICK workflow.
5. Update matrix + state files.
6. Dispatch validator.

## Evidence outputs

| File | Source |
|------|--------|
| `evidence/11-spec-015/branch-log.txt` | `git log <quarantine-branch>` |
| `evidence/11-spec-015/diff-review.md` | executor synthesis |
| `docs/SPEC-015-DISPOSITION.md` | decision document |
| `evidence/11-spec-015/matrix-diff.patch` | VALIDATION_MATRIX.md diff |
| `evidence/11-spec-015/state-diff.patch` | CAMPAIGN_STATE.md diff |

## Failure modes

- **Quarantine branch missing / already merged / already deleted:** record
  actual state; close gap as "already handled" citing git history.
- **Cherry-pick introduces regression:** roll back; escalate; phase FAILs.
- **Decision U3 unclear:** escalate to user; do not auto-drop.

## Duration estimate

1–3 hours.
