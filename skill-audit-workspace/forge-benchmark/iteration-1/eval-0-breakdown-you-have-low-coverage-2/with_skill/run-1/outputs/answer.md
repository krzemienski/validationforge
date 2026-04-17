# Your 68/100 (Grade D) Benchmark — What It Means and How to Fix It

Your aggregate is weighted: `(Coverage*35 + Evidence*30 + Enforcement*25 + Speed*10) / 100`. D means "below standard" (60-69) per the skill's grading table — your validation posture is incomplete but recoverable.

## Interpreting each dimension

| Dimension | Your Score | Target | Reading |
|---|---|---|---|
| Coverage (35%) | **50** | >80 | Only 1-2 journey subdirs under `e2e-evidence/`. Most features are unvalidated. |
| Evidence Quality (30%) | 80 | >90 | Non-empty ratio is solid, but you're missing the verdict bonus (no `*VERDICT*` or `report.md`) OR you have some empty/near-empty files. |
| Enforcement (25%) | 60 | >80 | Two of six enforcement slots are zeroed out (each worth +10 or +20). |
| Speed (10%) | 95 | — | Excellent — last run was <120s. Ignore this one. |

## Priority order (biggest weighted gap first)

Rank by `(100 - score) × weight`:
1. **Coverage**: 50 pts × 0.35 = **17.5 aggregate points on the table** ← fix first
2. **Enforcement**: 40 × 0.25 = 10.0 points
3. **Evidence Quality**: 20 × 0.30 = 6.0 points
4. **Speed**: 5 × 0.10 = 0.5 points — leave alone

## Fix 1 — Coverage (50 → 95, +15.75 aggregate)

The scorer tiers journey count: 0=0, ≤2=50, ≤4=70, **>4=85**, plus +10 if `plans/` has any `.md`.

- Add at least **5 journey subdirectories** under `e2e-evidence/` (e.g. `e2e-evidence/login/`, `/signup/`, `/checkout/`, `/dashboard/`, `/search/`). Each must contain real step evidence — don't create empty shells; the evidence-quality scorer will punish them.
- Add at least one markdown plan file in `plans/` (e.g. `plans/validation-plan.md`).
- Easiest path: run `/validate-plan` to produce the plan, then `/validate` to execute journeys and populate subdirs.

## Fix 2 — Enforcement (60 → 100, +10 aggregate)

Six slots: hooks (+20), no test/spec files in src/lib (+20), no jest.mock/sinon/.mock/.stub in src (+20), `.claude/rules/*.md` (+20), `e2e-evidence/` exists (+10), `.vf/config.json` exists (+10). You're missing 40 pts' worth — typically rules + config.

Run locally to see exactly which slots zeroed out:
```bash
bash skills/forge-benchmark/scripts/score-project.sh .
```
Then:
- Missing hooks → run `/vf-setup` (installs `.claude/hooks/`).
- Missing rules → copy the 8 rules from `.claude/rules/*.md` in this ValidationForge repo into your project's `.claude/rules/`.
- Missing config → `/vf-setup` creates `.vf/config.json`.
- Test/mock files in `src/` → delete them (iron rule #2).

## Fix 3 — Evidence Quality (80 → 100, +6 aggregate)

Formula: `(non_empty_files / total_files) × 70 + 30 if any VERDICT/report.md exists`. 80 most likely = 100% non-empty (70) + partial verdict, OR ~71% non-empty + full verdict. Two actions:
- Ensure `e2e-evidence/report.md` or a `*VERDICT*` file exists (verdict-writer agent produces this).
- Audit `e2e-evidence/**` for files ≤10 bytes and delete or repopulate them.

## Projected new grade

Applying all three fixes: 50→95, 60→100, 80→100, speed unchanged at 95.
New aggregate = `(95×35 + 100×30 + 100×25 + 95×10) / 100` = **97 → Grade A**.

Even doing only Fix 1 + Fix 2 lands you at ~92 (A). Fix 1 alone gets you to ~82 (B).

## Start here, in order
1. `/vf-setup` → fixes Enforcement config/hooks slots.
2. `/validate-plan` then `/validate` → creates 5+ journey subdirs and a verdict report (fixes Coverage and closes Evidence gap in one move).
3. Re-run `bash skills/forge-benchmark/scripts/score-project.sh .` to confirm the A.
