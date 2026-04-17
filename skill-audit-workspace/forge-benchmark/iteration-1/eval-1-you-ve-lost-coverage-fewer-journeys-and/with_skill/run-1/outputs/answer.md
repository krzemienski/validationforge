# Benchmark Regression Diagnostic: 92 → 76 (A → C)

## Aggregate math

Weighted formula from the skill: `(cov*35 + evidence*30 + enforce*25 + speed*10)/100`.

- Last week: `95*.35 + 100*.30 + 70*.25 + 80*.10 = 33.25 + 30 + 17.5 + 8 = 88.75` → rounds near 92 once enforcement was likely 80–90.
- This week: `70*.35 + 60*.30 + 70*.25 + 80*.10 = 24.5 + 18 + 17.5 + 8 = 68` → the stated 76 implies enforcement closer to 100 or speed=100. The user-reported 76 is broadly consistent; the **-16 drop is entirely Coverage and Evidence Quality**.

## Dimension 1 — Coverage: 95 → 70 (−25)

Per SKILL.md, Coverage uses tier bins: `0 dirs=0, ≤2=50, ≤4=70, >4=85` plus `+10` for any `plans/*.md`. A score of **70** means `e2e-evidence/` now has **3 or 4 journey subdirs** (you were `>4` before). The +10 plans bonus is likely still present.

**Plausible causes:**
1. **Evidence purged** — someone ran `/validate --clean`, `rm -rf e2e-evidence/*`, or CI cleanup removed journey subdirs between runs. Coverage is computed from subdirs on disk, not history.
2. **New features shipped without new journeys** — coverage is journey-count-relative; even keeping the same journeys while the app grew will not drop score, but **renaming/consolidating journey dirs** (e.g. merging `login/`, `signup/`, `reset/` into a single `auth/`) collapses the subdir count into the `≤4=70` tier.
3. **Journey subdirs became files** — if someone wrote `e2e-evidence/login.md` instead of `e2e-evidence/login/step-*.png`, the `find -type d` count drops.

**Investigate:**
```bash
find e2e-evidence -mindepth 1 -maxdepth 1 -type d | sort
git log --since="1 week ago" -- e2e-evidence/ plans/
cat .vf/benchmarks/benchmark-*.json | jq '.dimensions.coverage'
```
Compare the two most recent JSON snapshots in `.vf/benchmarks/` — the skill explicitly recommends this.

## Dimension 2 — Evidence Quality: 100 → 60 (−40)

Formula: `(non_empty/total)*70 + (verdict_exists ? 30 : 0)`. Hitting exactly **60** is diagnostic: either (a) verdict file deleted AND non-empty rate still ~85% (`0.857*70 = 60`), or (b) verdict still present but non-empty rate plunged to ~43% (`0.43*70 + 30 = 60`). Scenario (a) is more common.

**Plausible causes:**
1. **Verdict file missing** — `e2e-evidence/report.md` or any `*VERDICT*` file was not written this run (losing a clean 30 points). Check if verdict-writer agent crashed or was skipped.
2. **Empty/zero-byte evidence files** — a validator captured stubs (e.g. `touch step-01.png`), failed screenshots wrote 0 bytes, or piped-to-file commands errored silently. The scorer rejects files `≤10 bytes`.

**Investigate:**
```bash
find e2e-evidence -type f \( -name "*VERDICT*" -o -name "report.md" \)
find e2e-evidence -type f -size -11c ! -name ".gitkeep"
find e2e-evidence -type f -name "*.png" -size 0
```

## Remediation to return to 92+

1. **Restore verdicts** — re-run `verdict-writer` against existing evidence to regenerate `e2e-evidence/report.md` (+30 Evidence instantly).
2. **Re-capture empty files** — replay the failed journey steps, overwriting zero-byte artifacts.
3. **Reinstate journey subdirs** — add journey directories for any features validated-but-uncaptured so count returns to `>4` (+15 Coverage).
4. **Add a cleanup guard** — honor `.vf/state/validation-in-progress.lock` before `/validate --clean` to prevent mid-run purges.
5. Re-run `bash scripts/score-project.sh .` and diff the JSON against last week's snapshot.

## Unresolved questions
- Which validator owns the purged journeys? (need `git log` on `e2e-evidence/`)
- Was last week's `enforcement=70` a typo? The math is tight only if enforcement was actually higher.
