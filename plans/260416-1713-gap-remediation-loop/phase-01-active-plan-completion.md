---
phase: P01
name: Execute active plan 260411-2305 Phases C→H
date: 2026-04-16
status: pending
gap_ids: [P01, P06]
executor: fullstack-developer
validator: code-reviewer
depends_on: [P00]
---

# Phase 01 — Active Plan 260411-2305 Completion

## Why

`plans/260411-2305-gap-validation/run.sh` scripts Phases C–H (hook verification,
platform detection, benchmark evidence capture). These were in-flight when the
campaign paused. Execute end-to-end and capture evidence per phase marker.

Also closes deferred Phase 6b from `260411-2242-vf-gap-closure` — external repo
benchmark resume.

## Pass criteria

<validation_gate id="VG-01" blocking="true">
  <prerequisites>
    - P00 verdict = PASS (state.json cites P00 closed_at)
    - `.vf/.gap-validation.lock` does NOT exist (else previous run in progress)
    - `plans/260411-2305-gap-validation/run.sh` exists and is executable
    - `evidence/00-preflight/demo-matrix.md` enumerates available demo dirs
  </prerequisites>
  <execute>
    `cd plans/260411-2305-gap-validation && bash run.sh 2>&1 | tee -a ../../260416-1713-gap-remediation-loop/evidence/01-active-plan/run.log`
  </execute>
  <capture>
    - `evidence/01-active-plan/run.log` (full stdout+stderr)
    - `evidence/01-active-plan/phase-markers.txt` from
      `grep -E '^--- PHASE [A-Z]+ (START|END)' evidence/01-active-plan/run.log`
    - `evidence/01-active-plan/run-exit-code.txt` (from `echo $? > …` after tee)
  </capture>
  <pass_criteria>
    1. `phase-markers.txt` contains ALL of these verbatim literals (source: run.sh:43-570):
       `--- PHASE PREFLIGHT START ---`, `--- PHASE PREFLIGHT END`,
       `--- PHASE C START ---`, `--- PHASE C END`,
       `--- PHASE D START ---`, `--- PHASE D END`,
       `--- PHASE E START ---`, `--- PHASE E END`,
       `--- PHASE F START ---`, `--- PHASE F END`,
       `--- PHASE G START ---`, `--- PHASE G END`,
       `--- PHASE H START ---`, `--- PHASE H END`
    2. For each of PREFLIGHT, C, D, E, F, G, H: at least ONE non-empty file exists under
       `plans/260411-2305-gap-validation/evidence/` with mtime between run start/end.
    3. `evidence/01-active-plan/summary.md` produced with per-phase verdict
       (PASS / FAIL / SKIPPED) AND cites at least one evidence file path per phase.
    4. Phase 6b benchmark condition satisfied by ONE of:
       a. run.sh produced `.vf/benchmarks/benchmark-260416-*.json` (mtime after run start); OR
       b. executor ran `/validate-benchmark` against demo dirs enumerated in demo-matrix.md.
          MINIMUM 2 platforms (API confirmed on disk: `demo/python-api/`).
          STRETCH 3 platforms only if a second demo was scaffolded in P00.
          If fewer than 2 usable demos exist, this criterion becomes BLOCKED_WITH_USER
          with a follow-up `plans/260416-*-demo-scaffolding/` stub opened in P13.
    5. `run-exit-code.txt` contains `0`. If non-zero, phase FAILs; report MUST include:
       - last phase marker emitted before failure (from phase-markers.txt)
       - stderr tail of 50 lines
       - resume instruction referencing the specific phase to re-enter
  </pass_criteria>
  <review>
    Validator cats phase-markers.txt, counts 14 matching lines against the regex
    `^--- PHASE [A-Z]+ (START|END)`. Cats run-exit-code.txt. Opens each evidence
    path cited in summary.md and asserts `wc -c` > 0.
  </review>
  <verdict>PASS → advance P04 + P06. FAIL → escalate per LOOP-CONTROLLER attempts.</verdict>
  <mock_guard>
    run.sh intentionally probes the block-test-files hook at Phase C-M2 (`probe.test.ts`)
    and asserts the Write is REJECTED. Do NOT disable the hook to let the probe succeed.
  </mock_guard>
</validation_gate>

### Demo precondition note

As of 2026-04-16 only `demo/python-api/` exists on disk (app.py, requirements.txt, README.md).
`demo/nextjs-web/`, iOS demo, and CLI demo are absent. The original "3 platforms (API, Web,
CLI)" phrasing from the plan draft is aspirational. Phase 00 MUST produce
`demo-matrix.md` to freeze which platforms actually exist at the start of the campaign;
this phase reads that matrix and adjusts VG-01 criterion #4 accordingly without silently
downgrading the claim.

## Inputs

- `plans/260411-2305-gap-validation/run.sh`
- `plans/260411-2305-gap-validation/evidence/`
- `plans/260411-2305-gap-validation/plan-diffs/`
- `plans/260411-2242-vf-gap-closure/benchmark-resume-evidence.md`

## Steps

1. Dispatch executor (fullstack-developer).
2. Executor:
   - `cd plans/260411-2305-gap-validation && bash run.sh 2>&1 | tee ../../260416-1713-gap-remediation-loop/evidence/01-active-plan/run.log`
   - For each phase marker in run.log, verify evidence file exists + non-empty.
   - Summarise into `evidence/01-active-plan/summary.md`.
3. If Phase 6b portion of `run.sh` is not present, executor additionally runs:
   - `/validate-benchmark` against 3 external demo dirs (`demo/nextjs-web`,
     `demo/python-api`, `demo/<third-platform>`)
   - Each run writes `.vf/benchmarks/benchmark-260416-*.json`
4. Dispatch validator. Validator reads `summary.md` + every cited evidence file.

## Evidence outputs

| File | Source |
|------|--------|
| `evidence/01-active-plan/run.log` | `run.sh` stdout+stderr |
| `evidence/01-active-plan/summary.md` | Executor synthesis |
| `evidence/01-active-plan/phase-C.txt` ... `phase-H.txt` | per-phase copies |
| `.vf/benchmarks/benchmark-260416-*.json` | Phase 6b benchmark output |

## Failure modes

- **run.sh fails at Phase C:** Report exact stderr + attempt salvage by rerunning
  single phase. On 3rd failed attempt escalate per LOOP-CONTROLLER.md.
- **No third demo platform exists:** document explicitly; run 6b against the two
  that do exist; note blocker for future.
- **Benchmark drops below A:** halt before Phase 12; do not commit; escalate.

## Duration estimate

2–4 hours.
