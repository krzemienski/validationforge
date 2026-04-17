---
phase: P06
name: Skill remediation (260411-1731 Phases 1-6)
date: 2026-04-16
status: pending
gap_ids: [R1, R2, R3, R4]
executor: fullstack-developer
validator: code-reviewer
depends_on: [P03]
---

# Phase 06 — Skill Remediation (260411-1731 P1-P6)

## Why

Plan `260411-1731-skill-optimization-remediation` was declared complete in its
frontmatter but Phases 1–6 were never executed. Researcher 1 identified 4 open
work items:
- R1: body-description consistency audit (read-only pre-trim)
- R2: trim 4 over-length descriptions (`stitch-integration`,
      `verification-before-completion`, `visual-inspection`, `web-testing`)
- R3: fix `forge-benchmark` body: sync 5 → 4 dimensions table
- R4: context bloat trim — target total SKILL body = 9,000 chars

## Pass criteria

1. `evidence/06-skill-remed/audit.md` exists with one row per skill showing
   body-description congruence (PASS/SUBTLE/FAIL).
2. 4 over-length description fields now ≤ 1,024 chars each. Diffs attached.
3. `skills/forge-benchmark/SKILL.md` body has 4 dimensions table matching the
   weights used in `scripts/benchmark/score-project.sh`.
4. Aggregate body char count ≤ 9,000 (`wc -c` over `skills/*/SKILL.md` bodies
   minus frontmatter).
5. `evidence/06-skill-remed/final-count.txt` proves char budget met.
6. No skill description semantic meaning lost — validator spot-checks 5 trimmed
   skills and confirms trigger text still activates.

## Inputs

- `plans/260411-1731-skill-optimization-remediation/plan.md`
- `skills/*/SKILL.md`
- `scripts/benchmark/score-project.sh` (for forge-benchmark weight source of truth)

## Steps

1. Dispatch executor.
2. Executor writes `audit.md` (R1).
3. Executor trims 4 over-length descriptions (R2).
4. Executor updates `forge-benchmark` body (R3) — table matches script weights.
5. Executor trims context bloat across all 48 SKILL bodies (R4) to ≤ 9,000 chars.
6. Executor captures pre/post char counts.
7. Dispatch validator with 5-skill spot-check criterion.

## Evidence outputs

| File | Source |
|------|--------|
| `evidence/06-skill-remed/audit.md` | R1 output |
| `evidence/06-skill-remed/trim-descriptions.patch` | R2 diff |
| `evidence/06-skill-remed/forge-benchmark.patch` | R3 diff |
| `evidence/06-skill-remed/context-trim.patch` | R4 diff |
| `evidence/06-skill-remed/pre-count.txt` | pre char-count |
| `evidence/06-skill-remed/final-count.txt` | post char-count |
| `evidence/06-skill-remed/spot-check.md` | Validator 5-skill verify |

## Failure modes

- **Char budget cannot be met without losing activation quality:** document
  tradeoff; escalate to user for acceptance; phase FAILs until resolved.
- **forge-benchmark script changes weights during this phase:** re-sync body.

## Duration estimate

4–6 hours (manual, careful text editing + spot check).
