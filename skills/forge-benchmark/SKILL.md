---
name: forge-benchmark
description: "Score validation posture on 4 dimensions: Coverage (35%), Evidence Quality (30%), Enforcement (25%), Speed (10%). Produces A-F grade via scripts/benchmark/score-project.sh. Use after validation, pre-release."
context_priority: reference
---

# forge-benchmark

Score validation posture across 4 dimensions. Track trends over time and compare against baseline targets.

Implementation: `scripts/benchmark/score-project.sh`

## Trigger

- "benchmark validation", "validation score", "how good is our validation"
- After completing a validation run

## Dimensions

| Dimension | Weight | What It Measures | Target |
|-----------|--------|-----------------|--------|
| Coverage | 35% | Journey subdirs in e2e-evidence/ + plan files | >80 |
| Evidence Quality | 30% | Non-empty evidence files ratio + verdict file bonus | >90 |
| Enforcement | 25% | Hooks, no test/mock files, rules, e2e-evidence dir, .vf/config | >80 |
| Speed | 10% | Validation duration from .vf/last-run.json | <120s=100, <300s=80 |

### Coverage (35%)

- Journey count tiers: 0 dirs=0, ≤2=50, ≤4=70, >4=85
- +10 bonus if `plans/` has markdown files
- Cap at 100
- Source: `find e2e-evidence -mindepth 1 -maxdepth 1 -type d`

### Evidence Quality (30%)

- Non-empty rate: files >10 bytes / total files × 70
- Verdict bonus: +30 if any `*VERDICT*` or `report.md` exists
- Formula: `quality = (non_empty / total) * 70 + verdict_bonus`

### Enforcement (25%)

- +20: hooks/hooks.json or .claude/hooks/ exists
- +20: no *.test.* or *.spec.* in src/ or lib/
- +20: no jest.mock/sinon/.mock/.stub patterns in src/
- +20: .claude/rules/ has *.md files
- +10: e2e-evidence/ directory exists
- +10: .vf/config.json exists

### Speed (10%)

- Reads `duration_seconds` from `.vf/last-run.json`
- <120s=100, <300s=80, <600s=60, ≥600s=40
- Default 80 if no timing data

## Benchmark Process

### Step 1: Collect Metrics

Scan the project for:
- All discoverable features (routes, endpoints, screens)
- Existing validation plans and journey counts
- Evidence directory contents and quality
- Previous validation run timing (from forge-state.json)

### Step 2: Score Each Dimension

Apply formulas above. Each dimension scores 0-100.

### Step 3: Calculate Weighted Score

```
aggregate = (coverage * 35 + evidence_quality * 30 + enforcement * 25 + speed * 10) / 100
```

### Step 4: Assign Grade

| Grade | Score | Meaning |
|-------|-------|---------|
| A | 90-100 | Excellent validation posture |
| B | 80-89 | Good, minor gaps |
| C | 70-79 | Adequate, notable gaps |
| D | 60-69 | Below standard |
| F | <60 | Insufficient validation |

### Step 5: Record and Compare

Saved to `.vf/benchmarks/benchmark-<date>.json`:

```json
{
  "timestamp": "2026-04-11T17:30:00Z",
  "project_dir": "/path/to/project",
  "dimensions": {
    "coverage": { "score": 95, "weight": 35, "journey_count": 8, "plans_found": 33 },
    "evidence_quality": { "score": 100, "weight": 30 },
    "enforcement": { "score": 70, "weight": 25 },
    "speed": { "score": 80, "weight": 10 }
  },
  "aggregate": 88,
  "grade": "B"
}
```

## Report Format

```markdown
# Validation Benchmark Report

## Score: 88/100 (Grade: B)

| Dimension        | Weight | Score |
|------------------|--------|-------|
| Coverage         |   35%  |  95   |
| Evidence Quality |   30%  |  100  |
| Enforcement      |   25%  |  70   |
| Speed            |   10%  |  80   |

## Recommendations
- Enforcement: +20 possible from .claude/rules/*.md, +10 from .vf/config.json
- Coverage: already near max; maintain journey subdir discipline
```
