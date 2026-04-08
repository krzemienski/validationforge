# Benchmarking Rules

## Metric Collection

```
RULE: Benchmark every validation run
  After validate-sweep completes, collect metrics automatically.

RULE: Never estimate metrics
  All metrics must be calculated from actual evidence files and timestamps.

RULE: Track trends
  Append to .vf/benchmark-history.json after every run.
  Never overwrite history — only append.
```

## Metric Integrity

```
RULE: Coverage = actual validated / actual total
  Do not count planned-but-not-executed journeys as coverage.

RULE: Evidence quality = files examined / files claimed
  Empty files (0 bytes) do not count as evidence.

RULE: Speed = wall clock time
  Measure from validate-sweep start to verdict completion.
  Do not subtract "waiting" time — real time matters.

RULE: Detection accuracy requires follow-up
  True positive rate can only be calculated AFTER fixes confirm defects.
  Track "pending verification" separately from "confirmed."
```

## Comparative Analysis

```
RULE: Same project for trends
  Only compare benchmark runs for the same project.
  Cross-project comparison uses normalized metrics only.

RULE: Baseline before changes
  When changing validation approach, benchmark BEFORE and AFTER.
  Without a baseline, improvement claims are invalid.

RULE: Fair comparison with alternatives
  When comparing VF vs unit tests vs manual:
  - Measure the same features
  - Count the same defect types
  - Use the same time window
```

## Reporting

```
RULE: Every benchmark report includes raw data
  Link to actual evidence files, not just percentages.

RULE: Highlight regressions
  If any metric decreased from previous run, flag it prominently.

RULE: Actionable recommendations
  Every benchmark report ends with specific improvement suggestions.
```
