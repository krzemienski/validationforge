---
name: forge-benchmark
skill_name: forge-benchmark
review_date: 2026-04-16
reviewer: P07-R2
---

## Frontmatter Check

| Field | Status | Notes |
|-------|--------|-------|
| name | ✅ PASS | "forge-benchmark" |
| description | ✅ PASS | 125 chars; clear summary of 4-dimension scoring |
| triggers | ✅ PASS | 3 trigger phrases; all realistic |
| context_priority | ✅ PASS | "reference" — correct. Benchmark is post-validation measurement. |
| YAML parses | ✅ PASS | Valid |

## Body-Description Alignment

**Description claims:**
> Score validation posture on 4 dimensions: Coverage (35%), Evidence Quality (30%), Enforcement (25%), Speed (10%). A-F grade via scripts/benchmark/score-project.sh.

**Body delivers:**
- 4 dimensions with weights exactly as claimed (lines 18-25)
- Coverage formula with journey count tiers (lines 26-32)
- Evidence Quality formula: non-empty ratio + verdict bonus (lines 33-38)
- Enforcement scoring: 6 vectors summing to 110 possible (lines 39-47)
- Speed tiering: <120s=100, <300s=80, <600s=60, ≥600s=40 (lines 48-52)
- A-F grading system (lines 72-79)
- Script reference: scripts/benchmark/score-project.sh (line 11)

**Verdict:** ✅ **PASS** — Body delivers completely.

## Scoring Design Quality

- Coverage: Tiered to favor 4+ journeys (85 points). Bonus for plans/ documentation.
- Evidence Quality: Penalizes empty files (0 bytes invalid). Bonus for verdict file (drives verdict writing).
- Enforcement: Overcounted (110 possible, capped at 100) to incentivize compliance.
- Speed: Linear tiering with reasonable baselines.

Well-designed dimensions that drive VF discipline (no-mock, evidence quality, enforcement).

## Verdict

**Status:** ✅ **PASS**

Scoring dimensions are thoughtful, formulas are clear, output format is actionable. No blocking issues.

### Proposed Patches
None required.
