# Scenario 05: CSS Overflow

Benchmark fixture representing a project with **zero ValidationForge infrastructure**
— no hooks, no rules, no evidence directory, no plans — and active anti-patterns
including test files and mock usage in source code.

**Expected grade: F (aggregate ~8/100)**

## Scenario Description

A CSS overflow handling utility is built to truncate overflowing text in container
elements. The team never set up ValidationForge. Instead of real validation journeys,
they wrote Jest unit tests with mocked DOM objects. No evidence of real system
interaction exists. No hooks prevent future mock usage.

## Score Breakdown

| Dimension        | Weight | Score | Rationale |
|-----------------|--------|-------|-----------|
| Coverage         |  35%   |   0   | No e2e-evidence/ directory; no plans/ |
| Evidence Quality |  30%   |   0   | No e2e-evidence/ directory |
| Enforcement      |  25%   |   0   | No hooks, test files in src/, mock patterns in src/, no rules, no e2e-evidence/, no .vf/config |
| Speed            |  10%   |  80   | default (no .vf/last-run.json) |
| **Aggregate**    |        |   **8** | **Grade F** |

## Structure

```
scenario-05-css-overflow/
├── README.md
└── src/
    ├── app.js            — CSS overflow utility (contains jest.mock anti-pattern)
    └── styles.test.js    — Unit tests (anti-pattern: no real validation journeys)
```

## What Makes This a Grade F

- **No e2e-evidence/** directory → Coverage = 0, Evidence Quality = 0
- **Test files in src/** (`styles.test.js`) → Enforcement loses +20
- **Mock patterns in src/** (`jest.mock` in `app.js`) → Enforcement loses +20
- **No hooks** → Enforcement loses +20
- **No .claude/rules/** → Enforcement loses +20
- **No .vf/config.json** → Enforcement loses +10
- Only Speed contributes (default 80), yielding aggregate ≈ 8

## Benchmark Use

This fixture validates that the scoring system assigns the lowest possible grade
to a project with zero validation infrastructure and active anti-patterns. A team
relying entirely on unit tests with mocks — and no real system validation — should
score F, demonstrating that compilation success and test coverage are not substitutes
for ValidationForge evidence-based validation.
