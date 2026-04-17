---
name: evidence-dashboard
description: >
  Generates and interprets the evidence summary dashboard — a structured
  visualization of captured validation evidence, per-journey verdicts, quality
  scores, and historical trends. Use after /validate completes, or manually for
  audit review of an existing e2e-evidence/ directory.
---

# Evidence Summary Dashboard

## Scope

Applies after validation evidence has been captured under `e2e-evidence/`. Transforms
raw evidence files and per-journey VERDICT.md artifacts into an actionable summary
at `e2e-evidence/dashboard.md` and `e2e-evidence/dashboard.html`, plus a historical
snapshot at `e2e-evidence/.history/run-*.json`. The dashboard is the artifact
engineering leads review to make ship / no-ship decisions — without it, evidence
lives in a tree of files nobody scrolls through.

Does NOT handle: capturing evidence (use `e2e-validate`), defining PASS criteria
(use `create-validation-plan`), or benchmarking the plugin itself (use
`forge-benchmark`).

## Quick Start

```bash
# Auto-invoked after /validate completes. Manual invocation:
bash scripts/generate-dashboard.sh --evidence-dir e2e-evidence --project-name myapp

# Markdown-only (for terminal/GitHub review):
bash scripts/generate-dashboard.sh --format md

# Skip history archival (one-off audit run):
bash scripts/generate-dashboard.sh --no-history
```

Outputs land in `e2e-evidence/`. Open `dashboard.html` in a browser for the visual
view; paste `dashboard.md` into a PR for async review.

## Inputs — e2e-evidence/ Structure Contract

The generator scans this shape. Deviation means missing data in the dashboard.

```
e2e-evidence/
  {journey-slug}/                   # One directory per validated journey
    VERDICT.md                      # Required: status (PASS/FAIL), confidence, citations
    evidence-inventory.txt          # Recommended: listing of evidence files
    step-01-{description}.png       # Screenshot evidence
    step-02-{description}.json      # API response / structured evidence
    step-03-{description}.log       # Console/build log evidence
  report.md                         # Top-level verdict report (from verdict-writer)
  .history/                         # Auto-created; .gitignored by default
    run-YYYY-MM-DDTHH-MM-SSZ.json   # Per-run snapshot for trend comparison
```

**VERDICT.md parsing contract:** generator extracts (in order) the `Overall Verdict`
line, falling back to `Verdict:`, falling back to whole-file `**PASS**` / `**FAIL**`
markers. Confidence is read from a `Confidence:` line (HIGH/MEDIUM/LOW); when
absent, it is derived from evidence count and citation density.

**0-byte files are invalid evidence.** They are counted, flagged in the dashboard,
and penalized in the quality score (`no_false_claims` dimension).

## Outputs

| File | Purpose | Consumer |
|------|---------|----------|
| `e2e-evidence/dashboard.md` | Markdown summary with journey table, evidence index, historical delta | Humans in terminal, PR reviewers, GitHub |
| `e2e-evidence/dashboard.html` | Self-contained HTML (inline CSS, no CDN, no JS libs) with stat cards and collapsible journey cards | Engineering leads in browser, offline file:// review |
| `e2e-evidence/.history/run-*.json` | Per-run snapshot: timestamp, counts, aggregate quality, per-journey entries | Trend comparison on subsequent runs |

The HTML output is fully offline — no external network requests. Safe to attach to
tickets or share over email without breaking when opened in a restricted
environment.

## Quality Score Rubric

Per-journey score is 0–100, computed from the same 5-dimension weighting used by
`/validate-benchmark` (see `commands/validate-benchmark.md` for the canonical
definition). The dashboard aggregates per-journey scores into a project grade.

| Dimension | Weight | Signal |
|-----------|--------|--------|
| evidence_exists | 30 | At least one non-empty evidence file is present in the journey dir |
| evidence_cites_specific_files | 25 | VERDICT.md references evidence files by relative path |
| screenshots_describe_observations | 20 | VERDICT.md contains observational verbs (shows/displays/rendered/visible/confirms) — not just "captured" |
| verdicts_cite_evidence | 15 | PASS/FAIL lines are followed by evidence citations, not bare status |
| no_false_claims | 10 | 0-byte evidence files reduce this dimension — empty files are invalid evidence |

Aggregate score = average of per-journey scores. Grade thresholds mirror
`scripts/benchmark/aggregate-results.sh`: A ≥ 90, B ≥ 80, C ≥ 70, D ≥ 60, else F.

## How to Read the Dashboard

### Grade Tiers

| Grade | Score | Read As |
|-------|-------|---------|
| A | 90–100 | Court-grade evidence trail. Ship with confidence. |
| B | 80–89 | Solid evidence. Review any `no_false_claims` deductions before shipping. |
| C | 70–79 | Evidence gaps. Investigate journeys scoring below 70 before claiming complete. |
| D | 60–69 | Significant gaps. Evidence is thin — re-run with richer capture before a ship decision. |
| F | < 60 | Evidence theater. Verdicts are not supportable; do not ship. |

### Trend Indicators

Appears only when `.history/` holds 2+ snapshots. Based on quality score delta vs.
most recent prior run:

| Indicator | Threshold | Meaning |
|-----------|-----------|---------|
| IMPROVING | Δ ≥ +3 | Evidence quality or pass rate rising |
| STABLE | −3 < Δ < +3 | Quality held constant between runs |
| REGRESSING | Δ ≤ −3 | Quality or pass rate dropping — investigate before the next ship |

The delta table also surfaces `new_journeys`, `removed_journeys`, `regressed_journeys`
(PASS → FAIL), and `recovered_journeys` (FAIL → PASS). Regressions always warrant
attention regardless of the aggregate delta.

### Evidence Gaps

An "evidence gap" is a journey with one of these properties:

- Quality score below 70 — evidence is thin or ambiguous
- 0-byte evidence files present — invalid evidence counted in file totals
- VERDICT.md missing — status was inferred from file count, not asserted
- PASS verdict without citations — unsupported claim per `gate-validation-discipline`

Each gap is flagged in the per-journey table. Gaps are the punch list for the next
validation pass — fix the gap, re-run `/validate-dashboard`, watch the trend
indicator move.

### When to Regenerate

- After any `/validate` run (auto-invoked in the REPORT stage)
- After manually adding or updating evidence in `e2e-evidence/`
- Before a ship decision, to confirm the latest evidence grades out
- During audit review, to assess an existing evidence directory without modifying it

## Rules

1. **Never edit `dashboard.md` or `dashboard.html` by hand** — they are generated artifacts; edits are lost on next run.
2. **Never edit files under `.history/`** — snapshots are immutable; regenerate a snapshot by re-running validation, not by hand-editing JSON.
3. **Dashboard generation is non-blocking** — a generator failure must not fail the validation run; log a warning and proceed. The dashboard is a reporting layer, not a gate.
4. **Do not commit `e2e-evidence/dashboard.html`** if it contains screenshots of authenticated screens — follow the same retention policy as raw evidence.
5. **Grade is not a gate** — a Grade A dashboard on three shallow journeys is still incomplete coverage. Pair grade with coverage from `/validate-benchmark`.

## Security Policy

Dashboards may embed journey names, file paths, and verdict text from VERDICT.md
files. All user-provided strings are HTML-escaped by the generator before
substitution into `dashboard.html` — but evidence itself (screenshots, JSON bodies)
may still contain credentials or PII. Store `e2e-evidence/` in `.gitignore` and
treat the dashboard with the same handling rules as its sources.

## Related Skills

- **e2e-validate** — Produces the evidence this dashboard summarizes. Run before invoking this skill.
- **create-validation-plan** — Defines the journeys and PASS criteria whose verdicts populate the dashboard.
- **verification-before-completion** — Uses the dashboard as a completion gate: every claim cites an evidence row.
- **gate-validation-discipline** — Enforces the citation standard the dashboard's quality score measures.
- **baseline-quality-assessment** — Capture a baseline dashboard before changes; compare against post-change dashboard for regression detection.
- **forge-benchmark** — Plugin-level posture benchmark; the dashboard is the per-run evidence view.

## References

- `commands/validate-benchmark.md` — Canonical definition of the 5-dimension quality rubric
- `commands/validate-dashboard.md` — CLI surface for manual dashboard generation
- `scripts/generate-dashboard.sh` — Deterministic generator implementation
- `templates/dashboard.md.tmpl`, `templates/dashboard.html.tmpl` — Output templates
