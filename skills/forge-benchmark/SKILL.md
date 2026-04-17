---
name: forge-benchmark
description: "Use to measure how mature a project's validation posture is — not whether a single validation run passed, but whether the team has built good validation habits. Scores across 4 weighted dimensions: Coverage (35% — what fraction of features have journeys), Evidence Quality (30% — are evidence files actually reviewed vs just captured), Enforcement (25% — are hooks/rules active), Speed (10% — time per validation run). Produces an A-F grade and per-dimension breakdown via scripts/benchmark/score-project.sh. Reach for it on phrases like 'benchmark our validation', 'validation maturity score', 'how good is our validation', 'posture report', or when tracking validation improvement over time."
triggers:
  - "benchmark validation"
  - "validation score"
  - "how good is our validation"
  - "validation posture"
  - "validation maturity"
  - "coverage score"
  - "posture report"
context_priority: reference
---

# forge-benchmark

Score validation posture across 4 dimensions. Track trends over time and compare against baseline targets.

## How to run it

The skill ships a self-contained scorer at `scripts/score-project.sh` (bundled alongside
this SKILL.md). Point it at any project directory:

```bash
bash scripts/score-project.sh /path/to/project
```

With no argument it scores the current working directory. Output is a markdown report
on stdout plus a JSON snapshot saved to `<project>/.vf/benchmarks/benchmark-YYYY-MM-DD.json`.

An identical copy is also maintained at the ValidationForge repo root under
`scripts/benchmark/score-project.sh` for convenience when invoking from CI pipelines —
both versions are kept in sync.

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

## Sample end-to-end output

Running `bash scripts/score-project.sh .` against a well-instrumented ValidationForge
project prints an annotated transcript followed by the report:

```
=== ValidationForge 4-Dimension Benchmark Scorer ===
Project: /Users/me/projects/storefront

[enforcement] +20: hooks infrastructure found
[enforcement] +20: no test/spec files in src/ or lib/
[enforcement] +20: no mock/stub patterns in src/
[enforcement] +20: .claude/rules/ has 8 markdown rule file(s)
[enforcement] +10: e2e-evidence/ directory exists
[enforcement]  +0: no .vf/config.json
Enforcement score: 90 / 100

[evidence] total files: 47
[evidence] non-empty (>10 bytes): 47
[evidence] verdict/report files: 4
Evidence Quality score: 100 / 100

[coverage] evidence journey subdirs: 6
[coverage] +10: plans/ has 12 markdown plan file(s)
Coverage score: 95 / 100

[speed] last run duration: 184s
Speed score: 80 / 100

=== BENCHMARK RESULTS ===
Aggregate: 92 / 100
Grade: A
{"coverage":95,"evidence":100,"enforcement":90,"speed":80,"aggregate":92,"grade":"A"}
```

The last line is a single-line JSON summary suitable for piping into CI dashboards or
appending to `.vf/benchmark-history.json` for trend analysis.

## Interpreting a drop in score

If the aggregate fell since last run, compare the per-dimension scores in the two most
recent `.vf/benchmarks/benchmark-*.json` files. Typical regression patterns:

- **Evidence Quality dropped** → a validator started capturing empty files or the
  verdict file was deleted. Check `e2e-evidence/*/step-*.{png,json,txt}` for zero-byte
  files.
- **Coverage dropped** → journey subdirectories disappeared (evidence purged by
  `/validate --clean`?) or new features shipped without new journeys being added.
- **Enforcement dropped** → someone committed a `*.test.*` file into `src/`, a mock
  pattern appeared, or rules/hooks got deleted. Re-run with `bash scripts/score-project.sh`
  to see exactly which +20 slot zeroed out.
- **Speed dropped** → the most recent validation run in `.vf/last-run.json` took longer
  than the previous 120-second / 300-second thresholds; usually network or CI-agent
  contention rather than a real regression.
