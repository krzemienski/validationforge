# Benchmark Breakdown: 68/100 (Grade D) — What to Fix First

## Score Interpretation

Your aggregate of 68 lands in the **D band (60-69)** per the skill's grade table, meaning "Below standard." Let's decompose each dimension using the rubric in SKILL.md.

| Dimension | Weight | Score | Weighted Contribution | Target |
|-----------|--------|-------|----------------------|--------|
| Coverage | 35% | 50 | 17.5 | >80 |
| Evidence Quality | 30% | 80 | 24.0 | >90 |
| Enforcement | 25% | 60 | 15.0 | >80 |
| Speed | 10% | 95 | 9.5 | — |
| **Total** | | | **68** | |

### What each score means (per SKILL.md)
- **Coverage 50** — Matches the "≤2 journey subdirs" tier in `e2e-evidence/`. You have 1-2 journeys captured. No `plans/` markdown bonus (otherwise you'd be 60).
- **Evidence Quality 80** — Non-empty rate is solid, but you're missing the +30 verdict bonus (no `*VERDICT*` or `report.md` file), OR some files are empty. Formula: `(non_empty/total)*70 + verdict_bonus(30)`.
- **Enforcement 60** — Three of the six enforcement checks pass. You're missing roughly: `.claude/rules/*.md` (+20), the `.vf/config.json` bonus (+10), and possibly one of the hooks/test-files/mocks checks (+20/+20/+20).
- **Speed 95** — Near-perfect. Under 120s run time. Leave alone.

## Priority Ranking (by points recoverable × weight)

### 1. FIX FIRST — Coverage (35% weight, +50 headroom)
**Biggest lever on your grade.** Going from 50 → 85 gains **+12.25 aggregate points** alone.
- Add journey subdirectories under `e2e-evidence/` — the tiers are: ≤2=50, ≤4=70, >4=85.
- **Target: more than 4 journey subdirs.** Name them by user journey (e.g., `e2e-evidence/login-flow/`, `e2e-evidence/checkout/`, `e2e-evidence/search/`).
- Add markdown files under `plans/` for a flat **+10 bonus** (capped at 100).

### 2. FIX SECOND — Enforcement (25% weight, +40 headroom)
Going from 60 → 100 gains **+10 aggregate points**. Each check is worth either +10 or +20 — very cheap wins:
- `.claude/rules/*.md` exists → **+20**
- `.vf/config.json` exists → **+10**
- Verify `hooks/hooks.json` or `.claude/hooks/` exists → **+20**
- Confirm no `*.test.*` / `*.spec.*` in `src/` or `lib/` → **+20**
- Confirm no `jest.mock`/`sinon`/`.mock`/`.stub` patterns in `src/` → **+20**
- `e2e-evidence/` directory exists → **+10** (you already have this since you have journeys)

### 3. FIX THIRD — Evidence Quality (30% weight, +20 headroom)
Going from 80 → 100 gains **+6 aggregate points**.
- Create a top-level `e2e-evidence/report.md` (or any `*VERDICT*` file). The skill says this alone grants a +30 verdict bonus — which likely pushes you to 100.
- Delete or repopulate any 0-byte evidence files so `non_empty/total` approaches 1.0.

### 4. SKIP — Speed (10% weight, +5 headroom)
Already 95. Not worth optimizing.

## Projected New Grade

If you execute fixes 1-3:
- Coverage: 50 → **85** (>4 journeys + plans/*.md bonus)
- Evidence Quality: 80 → **100** (add `report.md`)
- Enforcement: 60 → **100** (add rules + config)
- Speed: **95** (unchanged)

**Projected aggregate:** `(85×35 + 100×30 + 100×25 + 95×10) / 100` = **93.0 → Grade A.**

Even a minimal pass (fixes 1 + 2 only, Coverage 70, Enforcement 80) lands you at ~79 → **Grade C**, a two-letter jump.
