# Scenario 03: iOS Deeplink

Benchmark fixture representing an iOS project with **full ValidationForge enforcement
infrastructure** installed but **zero evidence captured** — hooks and rules exist, but
no validation journeys were ever executed against the real simulator.

**Expected grade: F (aggregate ~30/100)**

## Scenario Description

An iOS deeplink flow (`myapp://product/123`) is implemented but never validated against
a real simulator. The team installed ValidationForge hooks and rules (good enforcement
discipline), yet skipped all evidence capture. No journeys were executed, no evidence
files exist, and no verdict reports were written.

## Score Breakdown

| Dimension        | Weight | Score | Rationale |
|-----------------|--------|-------|-----------|
| Coverage         |  35%   |   0   | No journey subdirs in e2e-evidence/; no plans/ dir |
| Evidence Quality |  30%   |   0   | e2e-evidence/ has only .gitkeep (excluded); no real files |
| Enforcement      |  25%   |  90   | hooks (+20) + no test files (+20) + no mock patterns (+20) + rules (+20) + e2e-evidence/ dir (+10); no .vf/config (-10) |
| Speed            |  10%   |  80   | default (no .vf/last-run.json) |
| **Aggregate**    |        | **30** | **Grade F** |

## Structure

```
scenario-03-ios-deeplink/
├── README.md
├── hooks/
│   └── hooks.json              — VF hooks configuration (enforcement present)
├── .claude/
│   └── rules/
│       └── validation-discipline.md — No-mock mandate and evidence standards
└── e2e-evidence/
    └── .gitkeep                — Directory exists but no journeys executed
```

## What Is Missing (intentionally)

- `e2e-evidence/deeplink-validation/` — no journey subdirectory; never executed
- `e2e-evidence/report.md` — no verdict report
- `plans/` — no pre-execution validation plan
- `.vf/config.json` — no VF configuration

## What Is Present (intentionally)

- `hooks/hooks.json` — enforcement infrastructure installed (+20)
- `.claude/rules/validation-discipline.md` — validation rules present (+20)
- `e2e-evidence/` — directory exists (but empty) (+10)
- No `src/` or `lib/` directories → no test/spec files (+20) → no mock patterns (+20)

## Benchmark Use

This fixture validates that the scoring system correctly penalizes projects that
install enforcement infrastructure but never execute validation journeys. A team
that configured hooks and rules but skipped the actual validation runs earns F —
enforcement alone cannot substitute for real evidence.

The contrast with scenario-01 (Grade C) and scenario-02 (Grade F with evidence but
no enforcement) demonstrates that both enforcement AND evidence are required for a
passing grade.
