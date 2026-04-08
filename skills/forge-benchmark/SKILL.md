---
name: forge-benchmark
description: Measure validation posture across five dimensions. Track trends over time and compare against baseline targets.
---

# forge-benchmark

Measure validation posture across five dimensions. Track trends over time and compare against baseline targets.

## Trigger

- "benchmark validation", "validation score", "how good is our validation"
- After completing a validation run

## Dimensions

| Dimension | Weight | What It Measures | Target |
|-----------|--------|-----------------|--------|
| Coverage | 30% | Validated features / Total discoverable features | >80% |
| Detection | 25% | Real defects found / Known defects injected or present | >70% |
| Evidence Quality | 25% | Evidence with specific observations / Total evidence files | >90% |
| Speed | 10% | Validation time relative to project size | <5 min/journey |
| Cost | 10% | API calls + agent spawns per validation run | Decreasing trend |

### Coverage Metrics

- **Feature Discovery**: Count routes, endpoints, screens, commands
- **Journey Coverage**: Journeys that exercise each feature
- **Gap Ratio**: Features with zero journey coverage
- Formula: `coverage = covered_features / total_features * 100`

### Detection Metrics

- **True Positives**: Real bugs found by validation
- **False Negatives**: Known bugs that validation missed
- **Detection Rate**: `true_positives / (true_positives + false_negatives) * 100`
- Measured by reviewing fix commits after validation runs

### Evidence Quality Metrics

- **Citation Rate**: Evidence files that contain specific observations (not just "exists")
- **Non-Empty Rate**: Evidence files > 0 bytes with actual content
- **Inventory Completeness**: Journeys with complete evidence-inventory.txt
- Formula: `quality = cited_evidence / total_evidence * 100`

### Speed Metrics

- **Total Run Time**: Wall clock time for complete validation
- **Per-Journey Time**: Average time per journey
- **Preflight Time**: Time spent on build/environment checks
- Target: Under 5 minutes per journey average

### Cost Metrics

- **Agent Spawns**: Number of subagents used
- **Tool Calls**: Total MCP and tool invocations
- **Trend**: Should decrease as validation matures (cached knowledge, fewer false starts)

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
total = (coverage * 0.30) + (detection * 0.25) + (quality * 0.25) + (speed * 0.10) + (cost * 0.10)
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

Save to `.validationforge/benchmark-history.json`:

```json
{
  "benchmarks": [
    {
      "date": "2026-03-07",
      "score": 82,
      "grade": "B",
      "dimensions": {
        "coverage": 85,
        "detection": 78,
        "evidence_quality": 92,
        "speed": 70,
        "cost": 65
      },
      "features_total": 24,
      "features_covered": 20,
      "journeys": 12,
      "evidence_files": 48
    }
  ]
}
```

## Report Format

```markdown
# Validation Benchmark Report

## Score: 82/100 (Grade: B)
## Trend: +5 from previous (77 → 82)

| Dimension | Score | Weight | Weighted | Target | Status |
|-----------|-------|--------|----------|--------|--------|
| Coverage | 85 | 30% | 25.5 | >80% | PASS |
| Detection | 78 | 25% | 19.5 | >70% | PASS |
| Evidence Quality | 92 | 25% | 23.0 | >90% | PASS |
| Speed | 70 | 10% | 7.0 | <5m/j | WARN |
| Cost | 65 | 10% | 6.5 | ↓trend | WARN |

## Recommendations
1. Speed: Consider parallel validation to reduce per-journey time
2. Cost: Cache platform detection results between runs
```
