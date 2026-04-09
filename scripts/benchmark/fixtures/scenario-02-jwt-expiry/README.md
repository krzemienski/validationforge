# Scenario 02: JWT Expiry

Benchmark fixture representing a project with evidence captured but **no ValidationForge
enforcement infrastructure** installed — no hooks, no rules, no VF config.

**Expected grade: F (aggregate ~59/100)**

## Scenario Description

An authentication flow validates JWT token expiry handling. A developer manually
captured a login response JSON as evidence, but no ValidationForge hooks or rules
were ever installed. There are no plans, no verdict reports, and no automation
preventing mock usage.

## Score Breakdown

| Dimension        | Weight | Score | Rationale |
|-----------------|--------|-------|-----------|
| Coverage         |  35%   |  50   | 1 journey (auth-validation); no plans/ dir |
| Evidence Quality |  30%   |  70   | 2 files, both non-empty; no report.md verdict |
| Enforcement      |  25%   |  50   | e2e-evidence/ present (+10), no test files (+20), no mock patterns (+20); no hooks, no rules, no .vf/config |
| Speed            |  10%   |  80   | default (no .vf/last-run.json) |
| **Aggregate**    |        | **59** | **Grade F** |

## Structure

```
scenario-02-jwt-expiry/
├── README.md
└── e2e-evidence/
    └── auth-validation/
        ├── step-01-login-response.json  — Login response capture (non-empty)
        └── evidence-inventory.txt       — Basic inventory (non-empty, no verdict)
```

## What Is Missing (intentionally)

- `hooks/hooks.json` — no hook infrastructure
- `.claude/rules/` — no validation discipline rules
- `.vf/config.json` — no VF configuration
- `plans/` — no pre-execution validation plan
- `e2e-evidence/report.md` — no verdict report (no +30 evidence quality bonus)

## Benchmark Use

This fixture validates that the scoring system correctly penalizes projects that
capture some evidence but have zero enforcement infrastructure. A developer who
manually saves one JSON file without VF setup should score F, not D or higher.

The absence of a verdict report (report.md) also demonstrates that evidence alone
without a structured PASS/FAIL verdict is insufficient for a passing grade.
