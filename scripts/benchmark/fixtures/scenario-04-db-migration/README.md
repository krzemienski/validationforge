# Scenario 04: DB Migration

Benchmark fixture representing a project with **full ValidationForge infrastructure**
and one completed database migration validation journey — hooks, rules, VF config,
evidence, and plans all present.

**Expected grade: B (aggregate ~84/100)**

## Scenario Description

A database migration adds a `last_login_at` timestamp column and a unique index on
`users.email`. The team has ValidationForge fully set up (hooks, rules, .vf/config,
evidence directory, plans) and ran one DB validation journey capturing three evidence
steps: migration output, schema verification, and duplicate-key constraint check.

## Score Breakdown

| Dimension        | Weight | Score | Rationale |
|-----------------|--------|-------|-----------|
| Coverage         |  35%   |  60   | 1 journey (50) + plans/ exists (+10) |
| Evidence Quality |  30%   | 100   | 6 files, all non-empty; VERDICT.md + report.md present (+30 bonus) |
| Enforcement      |  25%   | 100   | hooks+rules+e2e-evidence+.vf/config all present; no test/mock files |
| Speed            |  10%   |  80   | default (no .vf/last-run.json) |
| **Aggregate**    |        | **84** | **Grade B** |

## Structure

```
scenario-04-db-migration/
├── README.md
├── hooks/
│   └── hooks.json              — VF hooks configuration
├── .claude/
│   └── rules/
│       └── validation-discipline.md — No-mock mandate and evidence standards
├── .vf/
│   └── config.json             — VF configuration (standard enforcement)
├── e2e-evidence/
│   ├── db-validation/
│   │   ├── step-01-migration-output.md  — Migration run output capture
│   │   ├── step-02-schema-verify.json   — Schema introspection results
│   │   ├── step-03-duplicate-check.md   — Unique index constraint test
│   │   ├── evidence-inventory.txt       — Evidence inventory
│   │   └── VERDICT.md                   — Journey-level verdict
│   └── report.md               — Unified validation verdict report
└── plans/
    ├── migration-plan.md       — Database migration execution plan
    └── validation-plan.md      — Pre-execution validation plan
```

## What Makes This a Grade B (not A)

- Only **1 of 3 planned journeys** was executed (missing rollback and performance journeys)
- Coverage score is 60/100 — partial coverage drives aggregate below A threshold
- All executed evidence is complete and correctly cited (Evidence Quality = 100)
- Full enforcement infrastructure installed (Enforcement = 100)

A grade A would require ≥3 journey subdirectories in e2e-evidence/ to push coverage to 80+.

## Benchmark Use

This fixture validates that the scoring system correctly rewards full enforcement
infrastructure and high-quality evidence while still penalizing incomplete coverage.
A team with excellent tooling that only validated one journey out of many possible
should score B — better than C (partial enforcement) but below A (full coverage).
