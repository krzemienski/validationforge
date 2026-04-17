# Evidence Summary Dashboard

**Project:** validationforge
**Run Date:** 2026-04-17T05:42:26Z
**Generator:** ValidationForge

## Overall Verdict: PASS

## Summary

| Metric | Value |
|--------|-------|
| Total Journeys | 1 |
| PASS | 1 |
| FAIL | 0 |
| Aggregate Quality Score | 85 / 100 |
| Quality Grade | B |

## Journey Results

| Journey | Verdict | Confidence | Evidence Count | Quality Score | Link |
|---------|---------|------------|----------------|---------------|------|
| web-validation | PASS | HIGH | 13 | 85 | [VERDICT.md](web-validation/VERDICT.md) |

## Evidence Index

Every evidence artifact captured during this run, grouped by journey. Each entry links to the file on disk relative to this dashboard.

### web-validation

- [`web-validation/VERDICT.md`](web-validation/VERDICT.md)
- [`web-validation/evidence-inventory.txt`](web-validation/evidence-inventory.txt)
- [`web-validation/expanded/VERDICT.md`](web-validation/expanded/VERDICT.md)
- [`web-validation/expanded/mobile-about.png`](web-validation/expanded/mobile-about.png)
- [`web-validation/expanded/mobile-homepage.png`](web-validation/expanded/mobile-homepage.png)
- [`web-validation/expanded/mobile-post07.png`](web-validation/expanded/mobile-post07.png)
- [`web-validation/expanded/post01-full.png`](web-validation/expanded/post01-full.png)
- [`web-validation/expanded/post09-full.png`](web-validation/expanded/post09-full.png)
- [`web-validation/expanded/post18-full.png`](web-validation/expanded/post18-full.png)
- [`web-validation/step-01-homepage-full.png`](web-validation/step-01-homepage-full.png)
- [`web-validation/step-02-post03-viewport.png`](web-validation/step-02-post03-viewport.png)
- [`web-validation/step-03-post03-full.png`](web-validation/step-03-post03-full.png)
- [`web-validation/step-04-post04-navigation.png`](web-validation/step-04-post04-navigation.png)



## Historical Comparison

**Trend:** STABLE (quality score 0, pass rate 0%)

Compared to prior run at `2026-04-17T05:28:10Z`.

| Metric | Prior | Current | Delta |
|--------|-------|---------|-------|
| Pass Rate | 100% | 100% | 0% |
| Quality Score | 85 | 85 | 0 |
| Total Journeys | 1 | 1 | 0 |
| PASS | 1 | 1 | 0 |
| FAIL | 0 | 0 | 0 |

- **New journeys:** _(none)_
- **Removed journeys:** _(none)_
- **Regressed (PASS → FAIL):** _(none)_
- **Recovered (FAIL → PASS):** _(none)_

## How to Read This Dashboard

- **Verdict** — PASS means every acceptance criterion for the journey was backed by specific, cited evidence. FAIL means at least one criterion was missing evidence or contradicted by the captured artifacts.
- **Confidence** — HIGH when multiple independent evidence types corroborate the verdict; MEDIUM when evidence is present but thin; LOW when the verdict rests on a single artifact.
- **Evidence Count** — Number of non-empty artifacts under the journey's evidence directory. Zero-byte files are excluded.
- **Quality Score** — 0–100 score per the ValidationForge evidence rubric (evidence_exists 30, evidence_cites_specific_files 25, screenshots_describe_observations 20, verdicts_cite_evidence 15, no_false_claims 10). See `commands/validate-benchmark.md` for the full rubric.
- **Quality Grade** — A (≥90), B (≥80), C (≥70), D (≥60), F (<60). Matches `scripts/benchmark/aggregate-results.sh`.

## Related Artifacts

- Full verdict report: `e2e-evidence/report.md`
- Per-journey verdicts: `e2e-evidence/<journey>/VERDICT.md`
- Raw evidence files: `e2e-evidence/<journey>/`
- Historical snapshots: `e2e-evidence/.history/`
