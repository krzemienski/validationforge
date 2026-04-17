---
name: Autonomous Loop Controller
date: 2026-04-16
status: active
---

# Loop Controller

Defines the autonomous loop that drives this campaign to completion with no user
intervention unless a phase exhausts retries. The main orchestrator (the Claude
conversation) executes this protocol by reading `GAP-REGISTER.md` and phase files,
dispatching sub-agents, and updating state.

## State file

Path: `logs/state.json` (relative to plan dir).

Schema:

```json
{
  "current_phase": "P02",
  "attempt": 1,
  "status": "IN_PROGRESS",
  "started": "2026-04-16T17:20:00-04:00",
  "history": [
    {
      "phase": "P01",
      "attempt": 1,
      "verdict": "PASS",
      "evidence_dir": "evidence/01-active-plan/",
      "verdict_path": "validators/P01-verdict.md",
      "closed_at": "2026-04-16T18:45:00-04:00"
    }
  ],
  "blocked": [],
  "gap_closure": {
    "P01": "CLOSED", "P06": "CLOSED",
    "H-ORPH-1": "OPEN", "H-ORPH-2": "OPEN", "H-ORPH-3": "OPEN"
  }
}
```

Field semantics:

| field | type | notes |
|-------|------|-------|
| `current_phase` | string | `P00`..`P13` or `DONE` |
| `attempt` | int | 1..3 inclusive; 3 exceeds → escalate |
| `status` | enum | `IDLE` · `EXECUTOR_RUNNING` · `VALIDATOR_RUNNING` · `IN_PROGRESS` · `DONE` · `HALTED` |
| `started` | ISO 8601 | local TZ |
| `history[]` | array | append-only; one row per attempt |
| `blocked[]` | array of gap IDs | BLOCKED_WITH_USER rows |
| `gap_closure` | map | gap ID → status (mirrors GAP-REGISTER.md column) |

## Loop protocol

```
┌────────────────────────────────────────┐
│ 1. READ state.json                     │
│ 2. IF current_phase == DONE → exit     │
│ 3. READ phase-NN-*.md for current_phase│
│ 4. DISPATCH executor sub-agent         │
│    status → EXECUTOR_RUNNING           │
│ 5. WAIT executor to report             │
│ 6. DISPATCH validator sub-agent        │
│    status → VALIDATOR_RUNNING          │
│ 7. WAIT validator verdict              │
│ 8. IF verdict == PASS:                 │
│      mark phase CLOSED                 │
│      close all phase's gap IDs         │
│      advance current_phase             │
│      attempt → 1                       │
│    ELSE IF verdict == FAIL:            │
│      attempt += 1                      │
│      IF attempt > 3:                   │
│        mark BLOCKED_WITH_USER          │
│        status → HALTED                 │
│        ESCALATE to user, wait          │
│    ELSE IF verdict == INCONCLUSIVE:    │
│      request validator to re-run with  │
│      more evidence (counts as attempt) │
│ 9. UPDATE state.json, commit evidence  │
│10. GOTO 1                              │
└────────────────────────────────────────┘
```

## Dispatch rules

**Executor sub-agent.** Type: `fullstack-developer` for implementation phases,
`researcher` for read-only scan phases, `oh-my-claudecode:executor` as generic
fallback. Prompt MUST include:
- Phase file path (absolute)
- `GAP-REGISTER.md` path
- Evidence output dir (absolute)
- Concrete PASS criteria (copied from phase file, not referenced)
- Work context: `/Users/nick/Desktop/validationforge`
- Reports path: `/Users/nick/Desktop/validationforge/plans/reports/`
- Plans path: `/Users/nick/Desktop/validationforge/plans/`

**Validator sub-agent.** Type: `code-reviewer` or `researcher` (read-only). Prompt:
- Phase file path
- Evidence dir
- PASS criteria list (verbatim)
- Output path: `validators/<phase-id>-verdict.md`
- Instruction: verdict must be `PASS` only if every PASS criterion is cited with a
  specific evidence file path and byte count > 0; else `FAIL`; `INCONCLUSIVE` only
  if evidence absent, not merely ambiguous.

**Never** self-validate. Main orchestrator never writes verdict files.

## Concurrency

Phases run sequentially. Within a phase, a phase may spawn parallel worker
sub-agents — but the validator always runs after all workers have completed.

## Regression gate (Phase 12)

After Phase 11 closes, Phase 12 re-dispatches validators for Phases 02, 03, 05
against the latest repo state. If any regression validator returns FAIL, state
snaps back to that phase with attempt=1 and the loop resumes.

## Escalation

When a phase exhausts 3 attempts:
1. Write `logs/escalation-<phase>.md` with:
   - Phase ID, gap IDs
   - All 3 executor outputs summarized
   - All 3 validator verdicts quoted
   - Specific artifact the validator wants but cannot find
2. Notify user. Wait for user to either:
   - Mark `BLOCKED_WITH_USER` and continue; OR
   - Provide guidance and reset `attempt → 1`; OR
   - Cancel campaign.

## Commit cadence

After every phase PASS: one commit with message
`feat(gap-remediation): close <gap-ids> via phase <PID>` and the evidence dir
staged. No commits for FAIL attempts. Evidence is kept but uncommitted for
failed attempts.

## Starting the loop

From main orchestrator:

1. Ensure `logs/state.json` exists (Phase 00 creates it).
2. Follow protocol above.
3. Do not skip phases unless explicitly marked BLOCKED_WITH_USER.

Phase 00 (preflight) creates the initial state and resolves unresolved questions
U1–U3 from `plan.md`. The loop does not begin Phase 01 until Phase 00 is CLOSED.

## Safety invariants

- **No phase completes without a verdict.md file.** If the validator errors, the
  phase stays IN_PROGRESS.
- **No gap changes to CLOSED without a verdict citing its ID as PASSED.**
- **No evidence file may be empty** (enforced by `hooks/evidence-quality-check.js`).
- **No mocks** (enforced by `hooks/mock-detection.js`).
- **No test files** (enforced by `hooks/block-test-files.js`).
- **`.vf/benchmarks/` grade must not drop** during the campaign; Phase 12 asserts
  grade ≥ A (96).
