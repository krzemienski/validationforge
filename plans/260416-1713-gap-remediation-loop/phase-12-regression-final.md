---
phase: P12
name: Full regression + final benchmark
date: 2026-04-16
status: pending
gap_ids: [ALL]
executor: fullstack-developer
validator: code-reviewer (team)
depends_on: [P01, P02, P03, P04, P05, P06, P07, P08, P09, P10, P11]
---

# Phase 12 — Full Regression + Final Benchmark

## Why

Phases 01–11 closed individual gaps. Before declaring the campaign done we
must prove no phase introduced a regression in earlier phases, and the
project-level benchmark did not degrade.

## Pass criteria

1. Regression validators re-dispatched for Phases 02, 03, and 05 with the
   *current* repo state — all must return PASS.
   - Phase 02 regression: orphan-hook disposition still in effect
   - Phase 03 regression: CLAUDE.md inventory still matches disk
   - Phase 05 regression: 5/5 benchmark scoreboard still achievable
2. Full project benchmark re-run via `/validate-benchmark`:
   - Grade ≥ A (96/100)
   - Written to `.vf/benchmarks/benchmark-260416-campaign.json`
3. Every verdict file under `validators/` still marks its phase PASS.
4. `GAP-REGISTER.md` shows zero OPEN rows (all CLOSED or BLOCKED_WITH_USER).
5. `logs/state.json` `current_phase == "DONE"` OR `"P13"` if closeout queued.
6. No uncommitted changes except the plan/evidence dirs themselves.

## Inputs

- Every `validators/P??-verdict.md`
- Every `evidence/??-*/`
- `GAP-REGISTER.md`
- `.vf/benchmarks/`
- `CLAUDE.md`, `SKILLS.md`, `COMMANDS.md`, `hooks/hooks.json`

## Steps

1. Dispatch 3 regression sub-agents in parallel (one each for Phase 02, 03,
   05). Each reads the latest repo state, not the evidence captured at the
   time of closure.
2. Dispatch executor to re-run `/validate-benchmark`.
3. Compare new benchmark to baseline.
4. Write `evidence/12-regression/summary.md`.
5. Dispatch overall validator to cross-check all verdict files.

## Evidence outputs

| File | Source |
|------|--------|
| `evidence/12-regression/phase-02-regression.md` | regression validator 02 |
| `evidence/12-regression/phase-03-regression.md` | regression validator 03 |
| `evidence/12-regression/phase-05-regression.md` | regression validator 05 |
| `evidence/12-regression/benchmark-before.json` | copy of pre-campaign benchmark |
| `evidence/12-regression/benchmark-after.json` | new benchmark |
| `evidence/12-regression/summary.md` | executor synthesis |

## Failure modes

- **Any regression FAILs:** loop snaps back to that phase with attempt=1; this
  phase cannot close until regression clears.
- **Benchmark below A:** halt; escalate; do not advance to P13.
- **Validator cross-check finds a verdict file marking PASS but citing an
  evidence file that's been deleted/modified:** phase FAIL; re-validate.

## Duration estimate

2–3 hours.
