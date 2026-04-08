---
name: validate-benchmark
description: Benchmark validation coverage, speed, and evidence quality against baseline metrics
triggers:
  - "validate benchmark"
  - "benchmark validation"
  - "validation metrics"
  - "validation score"
---

# Validate Benchmark

Measure and score your project's validation posture across four dimensions: coverage, speed, evidence quality, and enforcement compliance. Produces a quantitative benchmark report that can be tracked over time.

## Usage

```
/validate-benchmark                        # Full benchmark
/validate-benchmark --baseline             # Save current scores as baseline
/validate-benchmark --compare              # Compare against saved baseline
/validate-benchmark --ci                   # Machine-readable output for CI
```

## Four Benchmark Dimensions

### 1. Coverage Score (0-100)

Measures what percentage of the application has validation journeys defined.

```
Coverage = (validated_journeys / total_discoverable_features) × 100
```

**Discovery method:**
- Scan routes/endpoints (API coverage)
- Scan pages/screens (UI coverage)
- Scan CLI commands (CLI coverage)
- Scan user flows (journey coverage)

| Score | Rating | Meaning |
|-------|--------|---------|
| 90-100 | Excellent | Nearly all features have validation journeys |
| 70-89 | Good | Major features covered, some gaps |
| 50-69 | Fair | Core flows covered, significant gaps |
| <50 | Poor | Most features lack validation |

### 2. Evidence Quality Score (0-100)

Measures the rigor of captured evidence.

```
Quality = weighted_average(
  evidence_exists_per_journey × 30%,
  evidence_cites_specific_files × 25%,
  screenshots_describe_observations × 20%,
  verdicts_cite_evidence × 15%,
  no_false_claims × 10%
)
```

**Checks:**
- Does each journey have evidence files?
- Do verdict entries reference specific evidence files?
- Are screenshot descriptions observational (not assumed)?
- Are PASS verdicts backed by citations?
- Are FAIL verdicts accompanied by root cause?

| Score | Rating |
|-------|--------|
| 90-100 | Court-grade evidence |
| 70-89 | Solid evidence trail |
| 50-69 | Evidence gaps |
| <50 | Evidence theater |

### 3. Enforcement Score (0-100)

Measures hook compliance and discipline adherence.

```
Enforcement = (
  hooks_installed × 20% +
  no_test_files_in_project × 20% +
  no_mocks_in_codebase × 20% +
  rules_installed × 20% +
  evidence_dir_exists × 10% +
  config_level_set × 10%
)
```

**Checks:**
```bash
# Test file detection
find src/ -name "*.test.*" -o -name "*.spec.*" -o -name "__tests__" | wc -l

# Mock detection
grep -rn "jest.mock\|sinon\|mock(\|stub(\|vi.mock" src/ --include="*.{ts,js,tsx,jsx}" | wc -l

# Hook installation
jq '.hooks' hooks/hooks.json

# Rules installation
ls .claude/rules/validation-*.md 2>/dev/null | wc -l
```

### 4. Speed Score (0-100)

Measures validation execution efficiency.

```
Speed = based on validation time relative to project size

Small project (<10 files):  PASS if <2 min, WARN if <5 min
Medium project (10-50):     PASS if <5 min, WARN if <10 min
Large project (50+):        PASS if <10 min, WARN if <20 min
```

## Aggregate Score

```
ValidationForge Score = (Coverage × 0.35) + (Evidence × 0.30) + (Enforcement × 0.25) + (Speed × 0.10)
```

| Score | Grade | Meaning |
|-------|-------|---------|
| 90-100 | A | Production-ready validation posture |
| 80-89 | B | Strong validation, minor gaps |
| 70-79 | C | Adequate, needs improvement |
| 60-69 | D | Significant gaps |
| <60 | F | Validation theater — looks good, isn't |

## Baseline Management

### Save Baseline

```
/validate-benchmark --baseline
```

Saves current scores to `.vf/benchmarks/baseline.json`:

```json
{
  "timestamp": "2026-03-07T21:00:00Z",
  "scores": {
    "coverage": 72,
    "evidence": 85,
    "enforcement": 90,
    "speed": 78,
    "aggregate": 80
  },
  "details": {
    "total_journeys": 12,
    "validated_journeys": 9,
    "evidence_files": 34,
    "test_files_found": 0,
    "mocks_found": 0,
    "hooks_installed": 5,
    "rules_installed": 5
  }
}
```

### Compare Against Baseline

```
/validate-benchmark --compare
```

```markdown
## Benchmark Comparison

| Dimension | Baseline | Current | Delta |
|-----------|----------|---------|-------|
| Coverage | 72 | 85 | +13 |
| Evidence | 85 | 88 | +3 |
| Enforcement | 90 | 90 | 0 |
| Speed | 78 | 82 | +4 |
| **Aggregate** | **80** | **86** | **+6** |

Trend: IMPROVING
```

## CI Output

```
/validate-benchmark --ci
```

Produces machine-readable JSON to stdout + exit code:

```json
{
  "grade": "B",
  "aggregate": 82,
  "coverage": 75,
  "evidence": 88,
  "enforcement": 90,
  "speed": 72,
  "pass": true
}
```

Exit codes:
- `0` — Grade A or B (aggregate >= 80)
- `1` — Grade C or D (aggregate 60-79)
- `2` — Grade F (aggregate < 60)

## Evidence Structure

```
.vf/benchmarks/
  baseline.json              # Saved baseline
  benchmark-YYYY-MM-DD.json  # Historical snapshots
  report.md                  # Latest human-readable report
```

## Report Template

```markdown
# ValidationForge Benchmark Report

**Project:** {name}
**Date:** YYYY-MM-DD
**Grade:** {A-F}

## Scores

| Dimension | Score | Weight | Weighted | Rating |
|-----------|-------|--------|----------|--------|
| Coverage | XX | 35% | XX | {rating} |
| Evidence Quality | XX | 30% | XX | {rating} |
| Enforcement | XX | 25% | XX | {rating} |
| Speed | XX | 10% | XX | {rating} |
| **Aggregate** | | | **XX** | **{grade}** |

## Recommendations

1. {specific improvement with expected score impact}
2. {specific improvement with expected score impact}

## Comparison to Baseline

{delta table if baseline exists}
```

## Competitive Context

This benchmark measures YOUR validation posture. It does not compare against other tools or plugins. The scoring rubric is absolute — based on validation engineering best practices:

- **No mocks in codebase** is worth 20 enforcement points
- **Every journey has evidence** is worth 30 evidence points
- **Evidence cites specific files** is worth 25 evidence points
- **All hooks active** is worth 20 enforcement points

These scores are meaningful because they measure real validation discipline, not test coverage percentages that can be gamed with shallow tests.
