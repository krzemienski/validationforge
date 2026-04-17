# Forge Execution Rules

> **Canonical phase definitions live in [`execution-workflow.md`](./execution-workflow.md).**
> This rule file layers forge-specific discipline on top of the shared 7-phase
> pipeline — fix-loop caps, state persistence, parallel-execution safety. If you
> are looking for *what* each phase does, read `execution-workflow.md` first.

## Phase Gate Protocol (forge enforcement)

Forge commands (`/forge-execute`, `/forge-team`, `/validate-sweep`) execute the
pipeline defined in `execution-workflow.md` with these additional constraints:

- **Sequential — never skip a phase.** A forge run refuses to advance past a
  phase whose exit criteria are unmet. The order is fixed.
- **Preflight is a hard gate.** If preflight fails, Execute does not start.
  `execution-workflow.md` treats preflight as advisory for ad-hoc `/validate`;
  forge treats it as blocking.
- **Partial verdicts are forbidden.** The verdict writer must see evidence for
  every journey before emitting the unified report — no journey may be dropped
  silently to "keep the pipeline green."

## Fix Loop Discipline

- Maximum **3 fix attempts** per journey.
- Each attempt MUST produce NEW evidence under a fresh
  `e2e-evidence/forge-attempt-N/` subdirectory — never reuse prior evidence.
- Each attempt MUST target a DIFFERENT root cause. Retrying the same fix
  counts as a failed attempt.
- After 3 failed attempts, mark the journey as `UNFIXABLE` and continue the
  rest of the run. Do not block other journeys on one stuck flow.
- Log every attempt (cause hypothesis, fix applied, outcome) in the forge
  state file below.

## State Persistence

- Write state to `.validationforge/forge-state.json` after every phase
  transition.
- State fields: `run_id`, `current_phase`, `journey_verdicts{}`,
  `attempt_counts{}`, `timestamps{}`, `source_ref` (git SHA).
- **On resume:** read state and continue from the last incomplete phase.
  Never restart a completed phase on resume — it can contaminate the fresh
  evidence invariant above.
- **On completion:** archive state alongside the final report
  (`.validationforge/runs/<run_id>/forge-state.json`) and clear the active
  state file.

## Evidence Chain of Custody

- Evidence is captured at execution time, never fabricated after the fact.
- Every evidence file must be non-empty and contain actual observations.
- Evidence file names follow the pattern
  `step-{NN}-{description}.{ext}`.
- Each journey directory must have an `evidence-inventory.txt` listing all
  evidence files with byte counts.
- Timestamps in evidence must match the execution timeline (no retroactive
  timestamp editing).

## Parallel Execution Safety

When running journeys in parallel (via `/forge-team` or `parallel-validation`):

- Each journey owns its evidence subdirectory exclusively. Cross-writes
  invalidate the run.
- Shared resources (dev server, database, simulator) must be accessed
  safely — forge assumes read-mostly or serialized-write access.
- If a journey modifies shared state, subsequent journeys must account for
  it or the run is partitioned into sequential phases.
