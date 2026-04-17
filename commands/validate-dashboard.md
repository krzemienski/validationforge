---
name: validate-dashboard
description: Generate or regenerate the evidence summary dashboard from e2e-evidence/
triggers:
  - "validate dashboard"
  - "evidence dashboard"
  - "generate dashboard"
  - "regenerate dashboard"
---

# Validate Dashboard

Generate or regenerate the ValidationForge evidence summary dashboard from `e2e-evidence/`. Produces a shareable `dashboard.md` and self-contained `dashboard.html` with per-journey PASS/FAIL verdicts, evidence citations, quality scores, and — when prior runs exist — a historical trend comparison.

This command is a user-facing wrapper around `scripts/generate-dashboard.sh`. It is invoked automatically at the end of `/validate`; use this command to regenerate after editing evidence by hand, to review past runs, or to open the HTML in a browser.

## Usage

```
/validate-dashboard                        # Generate markdown + HTML from e2e-evidence/
/validate-dashboard --format md            # Markdown only (no HTML)
/validate-dashboard --format html          # HTML only (no markdown)
/validate-dashboard --open                 # Generate, then open dashboard.html in default browser
/validate-dashboard --compare              # Generate, then print historical delta to stdout
/validate-dashboard --history              # Print summary of past runs from .history/ and exit
```

## Supported Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--format md\|html\|both` | `both` | Which output(s) to render. `md` = `dashboard.md` only, `html` = `dashboard.html` only, `both` = render both. |
| `--open` | off | After generation, open `dashboard.html` in the default browser. macOS: `open`. Linux: `xdg-open`. No-op if the file was not rendered (e.g. `--format md`). |
| `--compare` | off | After generation, print the historical delta table (pass-rate delta, quality-score delta, trend indicator) to stdout. Requires at least one prior snapshot in `e2e-evidence/.history/`. |
| `--history` | off | Print a summary of past runs from `e2e-evidence/.history/` (timestamp, verdict, pass/fail counts, grade) to stdout and **exit without regenerating**. Mutually exclusive with `--open` and `--compare`. |
| `--evidence-dir DIR` | `e2e-evidence` | Override the evidence directory. Must be relative; `..` traversal is rejected. Passed through to `scripts/generate-dashboard.sh`. |
| `--project-name NAME` | basename of cwd | Project name for the dashboard header. Passed through to the generator. |
| `--no-history` | off | Skip writing a new snapshot to `e2e-evidence/.history/`. Passed through to the generator. |

## What Gets Generated

```
e2e-evidence/
  dashboard.md                       # Markdown summary (for terminals, GitHub, PRs)
  dashboard.html                     # Self-contained HTML (inline CSS, no network)
  .history/
    run-YYYY-MM-DDTHH-MM-SSZ.json    # One snapshot per run (unless --no-history)
    .gitignore                       # Keeps snapshots local by default
```

- **`dashboard.md`** — rendered from `templates/dashboard.md.tmpl`. Includes summary stats, per-journey verdict table, full evidence index with relative links, and the historical delta (if prior runs exist).
- **`dashboard.html`** — rendered from `templates/dashboard.html.tmpl`. Fully self-contained: inline CSS, no external assets, no JS libraries. Opens correctly as a `file://` URL with no network access.
- **`.history/run-*.json`** — one JSON snapshot per run with timestamp, verdict counts, aggregate quality score, grade, and per-journey entries. Used by `--compare` and by the next run to compute deltas.

## Quality Score Rubric

The dashboard reports a per-journey and aggregate quality score (0-100) using the same rubric as `/validate-benchmark`:

```
Quality = weighted_average(
  evidence_exists            × 30%,
  evidence_cites_specific    × 25%,
  screenshots_describe_obs   × 20%,
  verdicts_cite_evidence     × 15%,
  no_false_claims            × 10%
)
```

| Score | Grade | Meaning |
|-------|-------|---------|
| 90-100 | A | Court-grade evidence |
| 80-89 | B | Solid evidence trail |
| 70-79 | C | Noticeable evidence gaps |
| 60-69 | D | Significant gaps |
| <60 | F | Evidence theater |

See `commands/validate-benchmark.md` for the canonical rubric definitions.

## Historical Comparison

When `e2e-evidence/.history/` contains two or more snapshots, the generator compares the current run against the most recent prior snapshot and renders a delta section into both `dashboard.md` and `dashboard.html`.

```markdown
## Historical Comparison

| Dimension | Prior | Current | Delta |
|-----------|-------|---------|-------|
| Pass Rate | 83% | 100% | +17 |
| Quality Score | 78 | 85 | +7 |
| New journeys | — | checkout-flow |
| Regressed journeys | — | (none) |
| Recovered journeys | login-flow | — |

Trend: IMPROVING
```

**Trend classification** (from `quality_score_delta`):

| Delta | Trend |
|-------|-------|
| `>= +3` | IMPROVING |
| `-2 … +2` | STABLE |
| `<= -3` | REGRESSING |

If no prior snapshot exists, the section renders: `No prior runs yet — this is baseline.`

## History Browse Mode

```
/validate-dashboard --history
```

Prints a chronological summary of past runs without regenerating:

```
=== Validation Run History (e2e-evidence/.history/) ===
2026-04-16T21:00:00Z   PASS   6/6   Grade: A   Quality: 91
2026-04-15T17:32:10Z   FAIL   5/6   Grade: B   Quality: 82
2026-04-14T09:15:44Z   PASS   6/6   Grade: B   Quality: 85
3 runs total.
```

Exits 0 on success, 1 if `.history/` is missing or empty.

## Exit Codes

Mirrors the underlying `scripts/generate-dashboard.sh`:

| Code | Meaning |
|------|---------|
| `0` | Success — dashboard rendered (and opened / compared / listed as requested). |
| `1` | Usage error, bad argument, missing `e2e-evidence/` directory, path traversal rejected, or `--history` invoked with empty `.history/`. |
| `2` | Template missing (`templates/dashboard.md.tmpl` or `templates/dashboard.html.tmpl` not found). |

Non-zero exit from this command is safe to treat as build-failing in CI pipelines — the generator is deterministic and will only fail on structural input problems.

## Process

1. **Preflight** — confirm `e2e-evidence/` exists. If missing, exit 1 with a helpful message (`Run /validate first to produce evidence, then re-run this command.`).
2. **Short-circuit for `--history`** — if `--history` is set, read `e2e-evidence/.history/run-*.json`, print the summary, and exit. No regeneration, no history write.
3. **Generate** — invoke `scripts/generate-dashboard.sh` with the resolved `--evidence-dir`, `--project-name`, `--format`, and `--no-history` flags. The generator discovers journeys under the evidence dir, parses each journey's `VERDICT.md`, computes per-journey and aggregate quality scores, and writes `dashboard.md` and/or `dashboard.html`.
4. **Archive** — unless `--no-history` is set, the generator writes a snapshot to `e2e-evidence/.history/run-YYYY-MM-DDTHH-MM-SSZ.json`.
5. **Post-actions** —
   - If `--open`, invoke `open e2e-evidence/dashboard.html` (macOS) or `xdg-open e2e-evidence/dashboard.html` (Linux). Skip if `--format md` was used.
   - If `--compare`, print the historical delta block to stdout after generation.
6. **Report** — print the final stats line emitted by the generator (single-line JSON: `{"dashboard_md":"...","dashboard_html":"...","quality_score":NN,"grade":"X","pass":N,"fail":N,"total":N}`).

## The Dashboard Rule

```
A dashboard is a SUMMARY of evidence, not a SUBSTITUTE for it.
The grade is an indicator — the evidence files are the source of truth.
Never ship a feature based on a grade alone. Read the evidence.
```

The dashboard never modifies evidence. It parses existing `VERDICT.md` files, counts existing evidence files, and renders a summary. If the dashboard disagrees with your read of the evidence, the evidence wins.

## Examples

```bash
# Regenerate after editing a VERDICT.md by hand
/validate-dashboard

# Markdown only, suitable for pasting into a PR description
/validate-dashboard --format md

# Generate and immediately open in browser (macOS / Linux)
/validate-dashboard --open

# Generate and print historical delta for tracking quality over time
/validate-dashboard --compare

# Browse past runs without regenerating — useful for release reviews
/validate-dashboard --history

# Regenerate against a different evidence directory (e.g. a PR snapshot)
/validate-dashboard --evidence-dir e2e-evidence-pr-123

# Re-render without writing a new history snapshot (preview / dry regen)
/validate-dashboard --no-history
```

## Output

The rendered files land in the evidence directory:

```
e2e-evidence/dashboard.md       # Markdown summary
e2e-evidence/dashboard.html     # Self-contained HTML
e2e-evidence/.history/*.json    # Per-run snapshots (unless --no-history)
```

Stdout receives one JSON status line. With `--compare`, the delta table is printed to stdout immediately before the status line. With `--history`, only the history summary is printed and the dashboard files are not touched.

## Related

- `/validate` — produces the evidence that this dashboard summarizes; invokes this generator automatically in the REPORT stage.
- `/validate-benchmark` — canonical source for the quality-score rubric and grade tiers used by the dashboard.
- `/validate-audit` — read-only audit that can be regenerated into a dashboard view with `/validate-dashboard`.
- `skills/evidence-dashboard/SKILL.md` — guidance on interpreting dashboard output and quality gaps.
- `scripts/generate-dashboard.sh` — the underlying generator (deterministic, mock-free, no network).
