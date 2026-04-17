# P08 Pivot Rationale

## Decision recorded
- `logs/decisions.md` line 9: `U1: test`

## P05 prerequisite verdict
- `validators/P05-verdict.md` line 5: `verdict: FAIL`
- P05 disposition: `B5 stays OPEN — recommend mark BLOCKED_WITH_USER and advance to P06`

## Why the TEST branch is infeasible

VG-P08 (test branch) prerequisite: "P05 verdict = PASS (scoreboard provides a defect for FORGE test branch)."

P05 returned FAIL. The scoreboard shows `N_scope = 0` — all 5 benchmark scenarios are
`BLOCKED_WITH_USER` because no demo app ships pre-existing oracles (real committed defects
with reproducible evidence). Without an in-scope P05 defect, `/forge-execute` has no
real-system target to attempt a fix loop against.

## Iron Rule constraint

Running `/forge-execute` against a fabricated defect (authored specifically to give FORGE
a target) would constitute creating a synthetic oracle — equivalent to a test fixture.
This violates the No-Mock Iron Rule (`CLAUDE.md` item 2, `.claude/rules/no-mocks.md`).

The Iron Rule reads: "IF the real system does not work, FIX THE REAL SYSTEM. Never create
mocks, stubs, test doubles, fakes, or `*.test.*` / `*.spec.*` files."

## Decision

Execute the DEFER branch (VG-P08 lines 57–91):
1. Write `docs/ENGINES-DEFERRED.md` with measurable exit criteria.
2. Scrub forbidden phrases from all scrub-target docs.
3. Capture before/after grep evidence + diff patch.

U1=test intent cannot be honored without first unblocking B5 (requires out-of-campaign
scaffolding: real demo apps + pre-committed oracles). That work is queued in P13 stubs
P13-S1..S5 authored by the P05 executor.

## Campaign-level note

This pivot does not invalidate the FORGE or CONSENSUS design. It records that neither
engine has been executed end-to-end against a real external repo at campaign time.
Deferment exits when measurable criteria in `docs/ENGINES-DEFERRED.md` are satisfied.

---
Date: 2026-04-16
Author: fullstack-developer (P08 executor)
