# Scenario 01: API Rename

Benchmark fixture representing a project with full ValidationForge infrastructure
and one completed API validation journey.

**Expected grade: C (aggregate ~76/100)**

## Scenario Description

An API endpoint is renamed from `/api/v1/users` to `/api/v2/users`. The team has
ValidationForge fully set up (hooks, rules, evidence directory, plans) and ran one
API validation journey capturing two evidence steps.

## Score Breakdown

| Dimension        | Weight | Score | Rationale |
|-----------------|--------|-------|-----------|
| Coverage         |  35%   |  60   | 1 journey (50) + plans/ exists (+10) |
| Evidence Quality |  30%   |  82   | 4 files, 3 non-empty; report.md present |
| Enforcement      |  25%   |  90   | hooks+rules+e2e-evidence present; no .vf/config |
| Speed            |  10%   |  80   | default (no .vf/last-run.json) |
| **Aggregate**    |        |  **76** | Grade C |

## Structure

```
scenario-01-api-rename/
├── README.md
├── hooks/
│   └── hooks.json              — VF hooks configuration
├── .claude/
│   └── rules/
│       └── validation-discipline.md — No-mock mandate and evidence standards
├── e2e-evidence/
│   ├── api-validation/
│   │   ├── step-01-api-response.json  — HTTP request/response capture
│   │   ├── step-02-field-check.json   — Schema validation results
│   │   └── evidence-inventory.txt     — Minimal (intentionally ≤10 bytes)
│   └── report.md               — Validation verdict report
└── plans/
    └── validation-plan.md      — Pre-execution validation plan
```

## Benchmark Use

This fixture is used to verify the scoring system differentiates projects with
partial validation coverage. A team that validated only 1 journey (out of many
possible) with full VF infrastructure should score C, not A or B.
