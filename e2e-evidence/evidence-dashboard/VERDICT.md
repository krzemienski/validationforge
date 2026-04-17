# Evidence Summary Dashboard — Feature Verdict

**Feature:** 012-evidence-summary-dashboard
**Subtask:** subtask-5-1-real-run (Phase 5 — Integration Verification with Real Evidence)
**Target script:** `scripts/generate-dashboard.sh`
**Target evidence dir:** `e2e-evidence/` (pre-existing real `web-validation/` from a past run)
**Run date:** 2026-04-17T05:42:26Z
**Validator:** ValidationForge functional-validation protocol (real-system run, no mocks)

## Command Executed

```
bash scripts/generate-dashboard.sh --evidence-dir e2e-evidence --project-name validationforge
```

Exit code: **0**

JSON summary line emitted to stdout (the generator contract from subtask-1-3):

```
{"dashboard_md":"e2e-evidence/dashboard.md","dashboard_html":"e2e-evidence/dashboard.html","quality_score":85,"grade":"B","pass":1,"fail":0,"total":1}
```

## Acceptance Criteria — from spec.md

| # | Criterion | Verdict | Evidence |
|---|-----------|---------|----------|
| 1 | Dashboard generated automatically after `/validate` completes | **PASS** | Generator runs end-to-end with exit 0 and writes `e2e-evidence/dashboard.md` (3534 B) and `e2e-evidence/dashboard.html` (17752 B) on a single invocation. The wiring into `commands/validate.md` REPORT stage was completed in subtask-3-3; this subtask verifies the script those wires invoke. See `step-01-dashboard-md-content.md` for the full markdown output and `step-02-dashboard-html-rendered.png` for the rendered HTML. |
| 2 | Shows PASS/FAIL verdict per journey with evidence citations | **PASS** | `step-01-dashboard-md-content.md` lines 19–23 contain the Journey Results table row: `\| web-validation \| PASS \| HIGH \| 13 \| 85 \| [VERDICT.md](web-validation/VERDICT.md) \|` — the verdict cell links to the journey's underlying VERDICT.md which itself cites screenshots step-01..step-04. The screenshot `step-02-dashboard-html-rendered.png` shows the same row in the rendered "Journey Results" table with the PASS pill and "VERDICT.md" hyperlink in the Link column. |
| 3 | Includes evidence quality score per journey | **PASS** | Quality Score column = `85` for `web-validation`. Aggregate quality score = `85 / 100`, Quality Grade = `B`. Visible in `step-01-dashboard-md-content.md` (Summary table lines 11–17 and Journey Results column 5) and in `step-02-dashboard-html-rendered.png` (top-right "QUALITY GRADE" stat card showing `B 85/100` and Journey Results "Quality" column showing `85/100`). Score breakdown is captured in `step-03-quality-score-output.txt`. |
| 4 | Links to individual evidence files (screenshots, API responses, logs) | **PASS** | The Evidence Index section in `step-01-dashboard-md-content.md` lists all 13 non-empty evidence files under `web-validation/` as relative-path markdown links (lines 31–43). Cross-checked against `find e2e-evidence/web-validation -type f` — every one of the 13 actual files is linked, none missing: `VERDICT.md`, `evidence-inventory.txt`, `expanded/VERDICT.md`, 6 expanded PNGs, and 4 step PNGs. The HTML rendering in `step-02-dashboard-html-rendered.png` shows the same files as clickable hyperlinks in the "Evidence Index" panel. |
| 5 | Historical comparison if previous validation runs exist | **PASS** | A prior run snapshot existed at `e2e-evidence/.history/run-2026-04-17T05-28-10Z.json`. After this run, a second snapshot was written: `e2e-evidence/.history/run-2026-04-17T05-42-26Z.json`. The dashboard rendered the "Historical Comparison" section (lines 47–64 of `step-01-dashboard-md-content.md`) with trend `STABLE`, prior vs current pass-rate (100% → 100%, Δ 0%), quality score (85 → 85, Δ 0), and explicit New / Removed / Regressed / Recovered journey lists. The same section is visible in `step-02-dashboard-html-rendered.png` ("Historical Comparison" card with the STABLE pill and the per-metric delta table). |
| 6 | Viewable as both HTML (in browser) and markdown (in terminal/GitHub) | **PASS** | Two output files produced in a single run with default `--format both`: `e2e-evidence/dashboard.md` (3534 B, GitHub-flavored markdown — readable in terminal via `cat`/`less` and on GitHub) and `e2e-evidence/dashboard.html` (17752 B, self-contained HTML with inline CSS, zero external assets). Browser render verified by Playwright (`step-02-dashboard-html-rendered.png`); console: 0 errors, 0 failed requests, 0 page errors (`step-03-quality-score-output.txt` "Browser console check" section). |

## Subtask-5-1 Specific Acceptance Gates

| Gate | Verdict | Evidence |
|------|---------|----------|
| (a) `dashboard.md` exists and contains a PASS verdict row for `web-validation` linking to `web-validation/VERDICT.md` | **PASS** | `step-01-dashboard-md-content.md` line 23: `\| web-validation \| PASS \| HIGH \| 13 \| 85 \| [VERDICT.md](web-validation/VERDICT.md) \|`. File is 3534 bytes, non-empty (`test -s` returns true). |
| (b) Every evidence file under `web-validation/` is linked from the Evidence Index section | **PASS** | 13 files found by `find e2e-evidence/web-validation -type f` ↔ 13 link lines in the `### web-validation` Evidence Index block (lines 29–43). Diff shows zero missing entries, zero extras. |
| (c) `dashboard.html` renders without browser console errors when opened | **PASS** | Playwright (chromium 1208) loaded `file://…/e2e-evidence/dashboard.html` with `waitUntil: 'networkidle'`. Listeners on `console`, `pageerror`, and `requestfailed` collected: `errors: []`, `consoleCount: 0`, `consoleMessages: []`. Captured in `step-03-quality-score-output.txt`. |
| (d) Overall grade is A or B given existing evidence is high-quality | **PASS** | Aggregate score = 85, grade = `B`. Threshold table from `scripts/benchmark/aggregate-results.sh`: A ≥90, B ≥80. 85 is comfortably in the B band, satisfying the gate. |

## Overall Verdict: PASS

All six product-level acceptance criteria from `spec.md` and all four subtask-5-1 verification gates are satisfied with cited evidence captured in this directory.

## What This Run Proves

1. The generator script works end-to-end against a real, untouched evidence directory captured by an earlier `/validate` run on `blog-series/site` — no mocks, no synthetic fixtures.
2. The markdown ↔ HTML outputs are consistent: every value visible in `step-01-dashboard-md-content.md` (verdict, score, grade, evidence count, file list, trend) is also visible in the rendered screenshot `step-02-dashboard-html-rendered.png`.
3. History archival + trend comparison works: the run consumed the prior snapshot, computed STABLE deltas, and wrote a new snapshot for future runs to consume.
4. The HTML is genuinely self-contained: Playwright reported zero failed network requests, confirming no external CSS/font/script dependencies leaked through.
5. The quality scoring rubric correctly recognizes the existing `web-validation/` evidence as high-quality (B/85), neither inflating it to A nor under-grading it.

## What This Run Does NOT Prove (in scope of subtask-5-1)

1. The historical-comparison logic with **multiple** prior runs and **regressed/recovered journeys** (covered in subtask-5-2).
2. The benchmark integration confirming the new `evidence-dashboard` skill is counted (covered in subtask-5-3).
3. The `/validate-dashboard` slash command end-to-end (the command surface is implemented in subtask-3-2 and wired in subtask-3-3, and this run validates the underlying script those layers invoke).

## Files in This Evidence Directory

- `step-01-dashboard-md-content.md` — Verbatim copy of the generated `e2e-evidence/dashboard.md`
- `step-02-dashboard-html-rendered.png` — Full-page Playwright screenshot of `file://…/e2e-evidence/dashboard.html` at 1280px viewport width
- `step-03-quality-score-output.txt` — Generator stdout JSON, parsed fields, score breakdown, history snapshot contents, trend computation, and browser console-error check results
- `evidence-inventory.txt` — Inventory of files in this directory
- `VERDICT.md` — This file
