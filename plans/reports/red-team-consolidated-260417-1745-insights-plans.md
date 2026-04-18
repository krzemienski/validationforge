# Consolidated Red-Team Review — Insights Plans A/B/C
Date: 2026-04-17 17:45
Sources:
- `plans/260417-1715-insights-foundation/reports/red-team-260417.md`
- `plans/260417-1715-insights-skills-layer/reports/red-team-260417.md`
- `plans/260417-1715-insights-ambitious-workflows/reports/red-team-260417.md`

## Verdicts

| Plan | Verdict | Criticals | Majors | Blockers |
|------|---------|-----------|--------|----------|
| A — Foundation | APPROVE_WITH_CHANGES | 4 | 6 | In-phase fixes |
| B — Skills Layer | **REJECT** | 4 | 5 | Needs Phase 0 pivot |
| C — Ambitious Workflows | **REJECT** | 5 | 6 | Joint revision with A |

## Cross-Plan Critical Contract (must resolve before execution)

### X1. Schema ownership — Plan A vs Plan C drift
Plan A Phase 4 defines `~/.claude/state/schemas/debug-checkpoint.schema.json` with one shape. Plan C Phase 1 defines the **same file** with incompatible required fields. Silent runtime incompatibility.
**Fix**: Plan A owns the schema (it ships first). Plan C reads from the same file via `checkpoint-lib.js`. Version field required. Plan C cancels its duplicate schema definition.

### X2. Skill inventory was not checked
Plan B proposes 3 new skills. Detector repo already has 17 skills including `audit` (exact name collision, `user-invocable: true`), `fix-detection` (description literally = Plan B's /gt-perfect workflow), `algorithm-mismatch-debugging`, `gt-batch`, `fix-loop`, `visual-debugging-process`.
**Fix**: Plan B must pivot from "create" to "extend/consolidate existing."

### X3. Budget decisions hidden in success criteria
Plan B Phase 7 locks 900-run budget but pretends it's gated. Plan C Phase 6 estimates 1-1.5M tokens but success criteria don't tier.
**Fix**: Two-tier success criteria everywhere — full budget target + reduced budget fallback, chosen up front not downstream.

## Per-Plan Critical Issues

### Plan A — APPROVE_WITH_CHANGES (all in-phase fixes)
| # | Issue | Fix |
|---|-------|-----|
| A-C1 | `py_compile` writes `__pycache__/*.pyc` into user tree on every Python edit | Swap to `python3 -c "import ast; ast.parse(open(p).read())"` OR set `PYTHONDONTWRITEBYTECODE=1` |
| A-C2 | `tsc --noEmit <file>` catastrophically noisy without tsconfig | Walk up for `tsconfig.json`, skip if absent. OR defer TS entirely to follow-up |
| A-C3 | Char-count ÷ 4 token heuristic miscalibrated for JSONL transcripts | Parse JSONL content lengths OR use calibrated line-count median |
| A-C4 | `-`-prefix path guard "recommended" Phase 3, "tested" Phase 5 — inconsistent | Make required across both |

### Plan B — REJECT (needs pivot)
| # | Issue | Pivot |
|---|-------|-------|
| B-C1 | `/audit` name collides with existing `yt-shorts-detector/.claude/skills/audit/` | Option A: cancel `/audit` skill; Option B: rename to `visual-first-audit` and defer to detector's audit in its CWD |
| B-C2 | `/gt-perfect` duplicates fix-detection + algorithm-mismatch-debugging + gt-batch + etc. | Option A: cancel `/gt-perfect`, extend `fix-detection` with the GT-perfection protocol; Option B: deprecate 2 detector skills with redirect, carry forward user-invocable |
| B-C3 | Plan A schemas assumed (not yet shipped) | Add Phase 0 schema freeze owned by Plan A; block B Phase 1-3 on freeze |
| B-C4 | Phase 7 budget dishonest (900 runs behind a gate that fires too late) | Two-tier: Full (900 runs, ≥80% held-out) OR Reduced (270 runs, ≥70% held-out) |
| B-M1 | `/root-cause-first` collides with `fix` ("ALWAYS activate") + `ck-debug` | Rename to `evidence-gate` or `root-cause-gate`. Baseline Phase 5 WITH incumbents discoverable. |
| B-M5 | Phase 8 "seed a bug" to validate `/root-cause-first` = mocking | Pick actually-open bug from one of 3 projects. No open bug → defer validation. |

### Plan C — REJECT (joint revision with A)
| # | Issue | Fix |
|---|-------|-----|
| C-C1 | Schema drift vs Plan A (= X1) | Plan A owns; Plan C reads |
| C-C2 | `--allowedTools` grammar unverified; `Bash(git:*)` pattern not documented | Verify against live `claude --help` before Phase 5. Fallback: bare `Bash` + `--disallowedTools` subtractive (weaker but documented) |
| C-C3 | Subagent credential leakage — no env scrubbing; subagent can `env \| grep TOKEN` | `env -i` + allowlist (PATH, HOME, PWD, USER, TERM, minimum) in `common.sh` |
| C-C4 | Enforcer hook has no shadow mode — Week-1 friction kills adoption | Add `ROOT_CAUSE_SHADOW=1` env: log-but-don't-block for first 7 days, then flip |
| C-C5 | Phase 6 self-DoS: runs all 3 workflows in one session; success criterion contradicts mitigation | Split Phase 6 across 3 sessions OR make only enforcer mandatory in Phase 6 |

### Plan C Major (C-M1..M6 summary)
- Unbounded `failed-approaches.md` growth (no rotation)
- Worktree disk hazard (8 parallel × multi-GB)
- 6-hex campaign-ID collision under tight timing (use worktree lock)
- Post-commit hook extracts different issue-id than enforcer for same branch (split-brain)
- JSONL `usage` field unreliable as token cap signal
- Enforcer non-load-bearing during automation (systematically gamed by Phase 3's pre-generated stubs)

## Unified Phase 0 Proposal

Block Plans A/B/C Phase 1 authoring on this Phase 0 bundle:

### Phase 0.A — Plan A schema freeze (owned by Plan A, shipped first)
- Freeze `~/.claude/state/schemas/debug-checkpoint.schema.json` shape (one shape, versioned `schemaVersion: "1.0"`)
- Freeze `~/.claude/rules/audit-workflow.md` final content
- Freeze `yt-transition-shorts-detector/.claude/rules/detector-project-conventions.md` final content
- Pre-commit test script: `test -f` all three files before B/C can start

### Phase 0.B — Plan B consolidation decision
- Cancel `/gt-perfect` → extend existing `fix-detection` skill in place
- Cancel `/audit` (new) → name collision unresolvable; detector's `audit` stays authoritative
- Keep `/root-cause-first` but rename to `evidence-gate` (avoid `fix`/`ck-debug` trigger war)
- Budget tier: pick Full (900 runs) or Reduced (270 runs) — affects success criteria

### Phase 0.C — Plan C safety additions
- Mandate `env -i` + allowlist in headless runners
- Mandate `ROOT_CAUSE_SHADOW=1` for enforcer Week 1
- Mandate worktree lock file (not 6-hex alone)
- Mandate `--allowedTools` grammar verification before Phase 5 authoring
- Split Phase 6 validation into 3 sessions (enforcer / tuner / swarm)

## Residual Decisions for User (validation interview)

Grouped by plan:

**Plan A**
- A1: TS syntax check — ship with tsconfig walk-up, or defer entirely?
- A2: Context-threshold heuristic — JSONL-aware or line-count median?

**Plan B**
- B1: Cancel `/gt-perfect` and modify `fix-detection` in place, OR build new skill + deprecate incumbents?
- B2: Cancel `/audit` (new) or rename to `visual-first-audit`?
- B3: Phase 7 budget — Full (900) or Reduced (270)?
- B4: `/root-cause-first` rename — `evidence-gate`, `root-cause-gate`, or keep current?

**Plan C**
- C1: Enforcer shadow-mode duration — 7 days, 14 days, or until explicit flip?
- C2: GT Tuner parallelism — 8 parallel or 4 parallel?
- C3: Swarm orchestration — Agent Teams (`/team`) or plain Task tool?
- C4: Phase 6 validation scope — all 3 workflows or enforcer-only first pass?

**Cross-cutting**
- X1: Plan A schema ownership — confirmed?
- X2: Any additional safety gates for the enforcer (blocklist paths that bypass)?
