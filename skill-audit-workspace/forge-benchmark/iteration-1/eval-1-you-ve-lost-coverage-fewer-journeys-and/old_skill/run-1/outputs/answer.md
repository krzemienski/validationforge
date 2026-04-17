# Benchmark Regression Diagnostic: 92 -> 76 (Grade A -> C)

Aggregate dropped 16 points. Weighted math per SKILL.md:
`(coverage*35 + evidence_quality*30 + enforcement*25 + speed*10) / 100`

- Coverage delta: (95 -> 70) * 35% = **-8.75**
- Evidence Quality delta: (100 -> 60) * 30% = **-12.0**
- Enforcement + Speed: stable (~0)

That matches the ~16-point drop. Both dimensions that fell are the two heaviest-weighted, so recovery must target them directly.

## Dimension 1: Coverage 95 -> 70 (weight 35%)

Per SKILL.md, Coverage is computed from journey subdirectory count tiers in `e2e-evidence/` plus a +10 bonus when `plans/` has markdown files:
- 0 dirs = 0, <=2 = 50, <=4 = 70, >4 = 85 (+10 plan bonus, cap 100)

A score of exactly **70** means the tier collapsed to **"<=4 journey subdirectories"** AND the +10 plans bonus is gone. Previously at 95 you were at the >4 tier (85) with the plans bonus (+10).

Plausible causes:
1. **Journey subdirectories were deleted or purged** — a cleanup run (e.g. `/validate --clean`) or manual `rm -rf e2e-evidence/*` wiped prior journeys. The current run only captured 3-4 journeys this week instead of 5+.
2. **Plans directory lost its markdown files** — `plans/` was emptied, renamed, or the markdown was moved into a subdirectory that the scorer's glob doesn't traverse. That alone removes the +10 bonus.
3. **Partial validation run** — a fullstack app normally produces per-platform journey dirs (web, api, db, etc.). If the run was scoped to a subset (e.g. only API), journey count collapses.
4. **Evidence directory relocation** — if the team started writing to a non-default path, `find e2e-evidence -mindepth 1 -maxdepth 1 -type d` sees zero matches for some platforms.

## Dimension 2: Evidence Quality 100 -> 60 (weight 30%)

Formula: `(non_empty_files / total_files) * 70 + 30 if a *VERDICT* or report.md exists`.

A score of **60** strongly implies: **no verdict file present** (lost the +30 bonus) and a non-empty ratio around ~0.86 (0.86 * 70 ~= 60). Alternative: verdict present but ~43% of files are empty (0.43 * 70 + 30 ~= 60). Either interpretation means two of the three quality levers slipped.

Plausible causes:
1. **Verdict writer never ran / verdict file missing** — this alone removes 30 points. No `report.md` or `*VERDICT*` file was emitted this run.
2. **Empty evidence files** — screenshots that failed to capture (0-byte PNGs), log captures redirected incorrectly, or API response dumps that errored out before writing. Files <=10 bytes do not count toward the non-empty ratio.
3. **Evidence filename pattern drift** — if the verdict artifact was named something like `summary.md` instead of `report.md` or `*VERDICT*`, the bonus is silently skipped.

## Enforcement / Speed

Stable per the question, so skip investigation there.

## Concrete Investigative Steps

1. `find e2e-evidence -mindepth 1 -maxdepth 1 -type d | wc -l` — confirm current journey count vs last week.
2. `ls plans/*.md 2>/dev/null | wc -l` — verify the +10 plans bonus source still exists.
3. `find e2e-evidence -type f -size 0` and `-size -11c` — list empty/under-10-byte files.
4. `find e2e-evidence -iname '*verdict*' -o -name 'report.md'` — confirm verdict artifact exists and is non-empty.
5. Compare `.vf/benchmarks/benchmark-<last-week>.json` vs this week's JSON — the `journey_count` and `plans_found` fields pinpoint the exact regression.
6. Review `.vf/last-run.json` and recent git log for `e2e-evidence/` and `plans/` deletions.

## Remediation to Return to 92+

1. Re-run the full multi-platform validation sweep so all platform journeys repopulate `e2e-evidence/<platform>/`. Target >4 journey subdirs to restore the 85-base Coverage tier.
2. Ensure `plans/` retains at least one `.md` file (the validation plan itself) to regain the +10 Coverage bonus.
3. Require the verdict-writer phase to run and emit `e2e-evidence/report.md` every run — this single file returns +30 to Evidence Quality.
4. Audit evidence capture steps for 0-byte output; fix failing screenshotters/loggers so the non-empty ratio returns to ~1.0.
5. Add a post-run guard that fails loudly if journey count drops or if `report.md` is absent, so regressions are caught before the next benchmark.

With all four restored, projected score: coverage 95, evidence 100, enforcement stable, speed stable -> back to 92+ (Grade A).

## Caveats from SKILL.md

The snapshot does not explain *why* journey dirs or evidence files went missing — it only defines the scoring formulas. Root cause (deletion, failed capture, config drift) must be confirmed from the filesystem and git history, not inferred from the score alone.
