---
name: forge-benchmark
description: "Measure validation posture across 5 dimensions with trend tracking"
allowed-tools: "Read, Write, Bash, Glob, Grep"
---

# /forge-benchmark

Score your project's validation posture.

## Dimensions

| Dimension | Weight | Target |
|-----------|--------|--------|
| Coverage | 30% | >80% features validated |
| Detection | 25% | >70% defect detection |
| Evidence Quality | 25% | >90% cited evidence |
| Speed | 10% | <5 min/journey |
| Cost | 10% | Decreasing trend |

## Grades

A (90+), B (80-89), C (70-79), D (60-69), F (<60)

## Usage

```
/forge-benchmark                # Run benchmark, compare to history
/forge-benchmark --report       # Generate detailed report only
```

History tracked in `.validationforge/benchmark-history.json`.

Invoke the `forge-benchmark` skill to execute.
