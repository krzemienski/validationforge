---
name: Gap Remediation Autonomous Loop
date: 2026-04-16
mode: deep
status: complete
owner: main orchestrator
type: functional-validation-plan
blockedBy: []
blocks:
  - 260411-2305-gap-validation
  - 260411-1731-skill-optimization-remediation
supersedes: []
---

# Gap Remediation Autonomous Loop

Close every remaining ValidationForge gap identified across 8 prior plans + 14 state
docs + inventory audit. Zero mocks. Every phase gate is functional, evidence-backed,
and validated by a read-only sub-agent. Loop runs autonomously until every gap is
CLOSED or explicitly BLOCKED with user escalation.

## Sources

- `plans/reports/researcher-260416-1707-plan-progress-audit.md` — 8 plans scanned
- `plans/reports/researcher-260416-1707-inventory-audit.md` — CLAUDE.md vs disk
- `plans/reports/researcher-260416-1707-state-doc-scan.md` — 14 state docs
- `plans/260416-1713-gap-remediation-loop/GAP-REGISTER.md` — consolidated gaps
- `plans/260416-1713-gap-remediation-loop/LOOP-CONTROLLER.md` — loop protocol

## Acceptance (campaign is DONE when all are true)

1. Every row in `GAP-REGISTER.md` has status `CLOSED` or `BLOCKED_WITH_USER`.
2. Every phase has a `validators/<phase-id>-verdict.md` written by a sub-agent
   cited as PASS against pre-declared PASS criteria.
3. `evidence/` contains one sub-directory per phase with non-empty artifacts.
4. Benchmark re-run ≥ Grade A (96/100) persisted to `.vf/benchmarks/`.
5. CLAUDE.md inventory counts match disk exactly (commands, skills, hooks).
6. Regression gate re-runs Phases 02, 03, 05 after P12 and all still PASS.

## Iron Rules (enforced by hooks)

- No test files under `src/` or `lib/` (`hooks/block-test-files.js`)
- No mock/stub patterns in source (`hooks/mock-detection.js`)
- Every TaskUpdate→completed requires evidence citation
  (`hooks/evidence-gate-reminder.js`)
- Build success ≠ validation (`hooks/validation-not-compilation.js`)
- All evidence files must be non-empty (`hooks/evidence-quality-check.js`)

## Phase Index

| # | Phase | Gap IDs | Validator | Evidence path |
|---|-------|---------|-----------|---------------|
| 00 | Preflight + baseline snapshot | — | validator-00 | `evidence/00-preflight/` |
| 01 | Active plan 260411-2305 C→H run | P01, P06 | validator-01 | `evidence/01-active-plan/` |
| 02 | Orphan hook decision + registration | H-ORPH-1..3 | validator-02 | `evidence/02-orphan-hooks/` |
| 03 | Inventory sync (CLAUDE.md vs disk) | INV-1..3 | validator-03 | `evidence/03-inventory/` |
| 04 | Platform detection on external repos | H4 | validator-04 | `evidence/04-platform-detect/` |
| 05 | Benchmark 5-scenario proof (B5) | B5 | validator-05 | `evidence/05-benchmark/` |
| 06 | Skill remediation (260411-1731 P1-P6) | R1..R4 | validator-06 | `evidence/06-skill-remed/` |
| 07 | Skill deep-review sweep (38 remaining) | H1 | validator-07 | `evidence/07-skill-review/` |
| 08 | CONSENSUS + FORGE engines: test or defer | M1, M2 | validator-08 | `evidence/08-engines/` |
| 09 | Evidence retention + `.gitignore` | M4 | validator-09 | `evidence/09-retention/` |
| 10 | Config profile enforcement wiring | M7 | validator-10 | `evidence/10-config-profiles/` |
| 11 | Spec 015 quarantine decision | M6 | validator-11 | `evidence/11-spec-015/` |
| 12 | Full regression + final benchmark | ALL | validator-12 | `evidence/12-regression/` |
| 13 | Campaign closeout + handoff | — | validator-13 | `evidence/13-closeout/` |

Phase 00 runs once. Phases 01–11 run in the autonomous loop. Phase 12 runs after all
of 01–11 report PASS. Phase 13 only runs after Phase 12 PASS.

## Sub-Agent Topology

```
Main orchestrator (this conversation)
│
├── Loop controller (logical; Main drives it via LOOP-CONTROLLER.md)
│
├── Executor sub-agents (one per phase attempt)
│   └── Implements steps in phase-NN-*.md, writes to evidence/NN-*/
│
├── Validator sub-agents (one per phase attempt, separate context)
│   └── Read-only; reads phase file + evidence; writes verdict.md
│
└── Regression sub-agent (P12 only)
    └── Re-runs validators for P02, P03, P05; flags regressions
```

Each executor AND each validator runs in an isolated context (via Agent tool).
The main orchestrator coordinates but does not implement or self-verify.

## Phase Sizing

Target 2–5 focused tasks per phase. Each phase has a blocking Phase Validation Gate.
Evidence must compound: Phase N prerequisites include "Phase N-1 verdict = PASS".

## How To Run

1. From project root:
   ```
   /ck-plan  — this plan already exists; resume from LOOP-CONTROLLER.md
   ```
2. Loop controller reads phase index, checks verdict status, dispatches next phase.
3. If any phase hits 3 failed attempts, loop halts and escalates to user.
4. User may intervene or mark BLOCKED_WITH_USER to continue past it.

## Non-Goals

- No new commands, skills, hooks, or agents beyond what gap remediation needs.
- No refactor beyond the specific inventory sync + orphan hook decisions.
- No new platforms (L1 deferred to V1.5).
- No npm/GitHub Actions distribution (L2/L3 deferred).
- No HTML dashboard (L4 deferred).
- No telemetry implementation (L5 deferred; `vf-telemetry` command stays as-is).

## Unresolved Questions (to resolve in Phase 00)

- U1: Treat CONSENSUS/FORGE (M1, M2) as blocking or defer to V1.5/V2.0?
- U2: Is a 10-skill deep-review sufficient (H1) or must all 48 be reviewed before
  campaign closes? Default: review all 48, in sweeps of 8.
- U3: Spec 015 decision — cherry-pick or drop?

## Decision Log

See `logs/decisions.md` (created during Phase 00).
