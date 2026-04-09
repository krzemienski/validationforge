# Benchmark Calibration

Weight rationale and empirical calibration evidence for the 4-dimension scoring model
(Coverage 35%, Evidence Quality 30%, Enforcement 25%, Speed 10%).

Calibration run: 2026-04-08. Six data points: 5 synthetic scenario fixtures plus VF
self-assessment. All scores produced by `scripts/benchmark/score-project.sh`.

---

## Weight Rationale

### Coverage — 35% (Primary Signal)

Coverage anchors the model because unvalidated journeys cannot ship. A project with 0%
coverage fails the fundamental promise of ValidationForge regardless of how sophisticated
its enforcement tooling is. The 35% weight ensures that a perfect enforcement score (25%)
combined with perfect evidence quality (30%) cannot compensate for zero coverage — the
maximum possible aggregate without any coverage is 55, a failing score.

**Why not higher?** Beyond 35%, coverage would dominate so heavily that a project with
one well-evidenced journey would outscore a project with strong enforcement and rich
evidence across multiple partial journeys. 35% is the highest weight that lets enforcement
and evidence quality together outweigh coverage when both are near-ceiling.

### Evidence Quality — 30% (Second Signal)

Evidence quality determines whether a PASS verdict is trustworthy. A 0-byte screenshot
is categorically different from a file containing an observed server response. The 30%
weight reflects that high coverage with zero-quality evidence is almost as dangerous as
no coverage — it produces false confidence.

**Why not higher?** Evidence quality can only be as meaningful as the journeys that
generate it. Weighting evidence above coverage would reward teams that write lavish
evidence files for a single journey while ignoring the rest of the system.

### Enforcement — 25% (Third Signal)

Enforcement hooks and rules prevent regression between sessions. Without block-test-files,
a future session can introduce mocks. Without validation-discipline rules, iron rules erode
silently. Enforcement is weighted below coverage and evidence because it is a prerequisite
for sustained posture rather than a direct measure of what has been validated today.

**Why not lower?** A project with zero enforcement has no structural guarantee that the
next session will maintain its current score. The 25% weight ensures that enforcement gaps
produce a materially lower aggregate, incentivising installation of hooks before shipping.

### Speed — 10% (Lowest Weight)

A slow but thorough validation run is strictly better than a fast incomplete one. Speed
rewards projects that have accumulated timing data in `.vf/last-run.json` and rewards
pipeline efficiency, but it must never override correctness. The 10% weight ensures speed
cannot make a failing project pass, and cannot push a marginal project from D to C.

**Default behaviour:** Projects with no `.vf/last-run.json` receive a default speed score
of 80 (B range), reflecting that timing data absence is not itself a failure — it simply
means the project has not yet accumulated a measurement baseline.

**Weight sum check:** 35 + 30 + 25 + 10 = 100.

---

## Grade Boundaries

| Grade | Score Range | Interpretation                                      |
|-------|-------------|-----------------------------------------------------|
| A     | 90–100      | Production ready. All dimensions healthy.           |
| B     | 80–89       | Minor issues. Shippable with low risk.              |
| C     | 70–79       | Needs attention. Coverage or evidence gaps present. |
| D     | 60–69       | Significant gaps. Do not ship without remediation.  |
| F     | <60         | Failing. Must remediate before validation is credible. |

---

## Grade Boundary Validation

Five synthetic fixtures plus VF self-assessment confirm that the grade boundaries
differentiate projects with meaningfully different validation postures.

| Scenario                  | Coverage | Evidence | Enforcement | Speed | Aggregate | Result |
|---------------------------|----------|----------|-------------|-------|-----------|--------|
| scenario-01-api-rename    |    60    |    82    |     90      |  80   |    76     |   C    |
| scenario-02-jwt-expiry    |    50    |    70    |     50      |  80   |    59     |   F    |
| scenario-03-ios-deeplink  |     0    |     0    |     90      |  80   |    30     |   F    |
| scenario-04-db-migration  |    60    |   100    |    100      |  80   |    84     |   B    |
| scenario-05-css-overflow  |     0    |     0    |      0      |  80   |     8     |   F    |
| VF self-assessment        |    60    |   100    |     90      |  80   |    81     |   B    |

### Calibration Observations

Grade B floor (80): scenario-04-db-migration (84) and VF self-assessment (81) both reach B
with enforcement at 90–100, evidence at 100, and coverage at 60. The ceiling on B is set by
coverage — to reach A, coverage must clear 80 while the other dimensions remain at ceiling.

Grade F ceiling (59): scenario-02-jwt-expiry confirms that evidence quality (70) alone
cannot compensate for enforcement gaps (50) and incomplete coverage (50). A project with
observable evidence but no hooks or rules to enforce discipline sits at the F/D boundary.

### Differentiation Check

The six data points span the full grading range:

- **A**: not yet reached by any fixture (coverage ceiling required)
- **B**: scenario-04 (84), VF self (81) — enforcement + evidence carry coverage gap
- **C**: scenario-01 (76) — good enforcement, partial evidence, coverage at 60
- **D**: not yet represented — requires aggregate 60–69
- **F**: scenario-02 (59), scenario-03 (30), scenario-05 (8)

The absence of a D-range fixture is noted. A D score would require, for example, partial
enforcement (around 50), moderate evidence (around 60), and coverage at 50, yielding
approximately (50×35 + 60×30 + 50×25 + 80×10) / 100 = 55 — still F. Achieving D in
practice requires coverage of at least 60 paired with weak evidence and moderate enforcement.

---

## Known Calibration Limitations

1. **Speed default bias:** All 6 calibration data points use the default speed score of 80
   because no fixture has a `.vf/last-run.json`. The speed dimension is structurally
   under-exercised in this calibration run.

2. **Coverage ceiling at 60:** Both B-range projects score 60 on coverage. The A boundary
   (90+) requires coverage above 80. No fixture currently demonstrates A-range coverage,
   meaning the A grade is theoretically defined but empirically unconfirmed.

3. **Enforcement binary tendency:** The enforcement scorer grants 0, 50, 90, or 100 based
   on which infrastructure files are present. The midpoint scores (50, 90) could be
   refined with finer-grained detection of partial hook installations.
