---
name: Insights Skills Layer — /evidence-gate (only) + extend fix-detection
status: revised-post-redteam
revision: 2026-04-17-pivot
mode: deep
blocks: [260417-1715-insights-ambitious-workflows]
blockedBy: [260417-1715-insights-foundation]
created: 2026-04-17
owner: nick
authorities:
  - ~/.claude/skills/skill-creator/SKILL.md
  - ~/.claude/plugins/cache/superpowers-marketplace/superpowers-developing-for-claude-code/0.3.1/skills/working-with-claude-code/SKILL.md
---

# Plan B — Insights Skills Layer

## Why this plan exists

Three repeatable workflows from the insights report need to become invocable skills so they stop needing re-explanation every session:

1. **`/gt-perfect`** — the GT-comparison debug loop for yt-shorts-detector. Encodes: diff against ground_truth/*.json → identify root cause via frame inspection (NOT threshold tweaks) → ONE fix at a time → commit → repeat until 8/8.
2. **`/root-cause-first`** — gates Edit/Write behind an evidence.md checklist (visual evidence, written hypothesis, minimal repro, cross-check against failed-approaches.md).
3. **`/audit`** — encodes the visual-first audit workflow: Playwright screenshots / frame dumps FIRST, then code-path investigation, then fixes. Prevents the SessionForge dashboard pattern where audits stalled on auth/workspace issues before visual inspection.

## Targets

| Skill | Location | Type |
|-------|----------|------|
| `/gt-perfect` | `~/.claude/skills/gt-perfect/SKILL.md` | Workflow skill with bundled GT-diff script |
| `/root-cause-first` | `~/.claude/skills/root-cause-first/SKILL.md` | Gate skill referenced by Plan C's PreToolUse hook |
| `/audit` | `~/.claude/skills/audit/SKILL.md` | Workflow skill with visual-capture helpers |

## Dependencies on Plan A

- All three skills reference rules shipped in Plan A: `instrument-before-theorize.md` (strengthened), `audit-workflow.md` (new), `detector-project-conventions.md` (new in yt-shorts-detector).
- `/root-cause-first` depends on the checkpoint schema in `~/.claude/state/`.
- `/gt-perfect` depends on the detector project conventions rule being in place.

## Authoring protocol (non-negotiable)

Every skill follows the `skill-creator` skill's loop:

1. Intent capture → 2. SKILL.md draft → 3. Test-case design (2-3 realistic prompts) → 4. Spawn with-skill + baseline runs in parallel → 5. Grade + aggregate benchmarks → 6. Review via `eval-viewer/generate_review.py` → 7. Iterate until stable → 8. Description optimization via `run_loop.py` → 9. Package.

Each skill gets its own `evals/evals.json` and workspace sibling dir under `plans/260417-1715-insights-skills-layer/evals/{skill-name}/`.

## Phases

| # | Phase | Skill | Deliverable |
|---|-------|-------|-------------|
| 1 | Author `/gt-perfect` SKILL.md + bundled script | gt-perfect | SKILL.md + `scripts/gt-diff.py` |
| 2 | Author `/root-cause-first` SKILL.md + evidence template | root-cause-first | SKILL.md + `assets/evidence.md.template` + `assets/failed-approaches.md.template` |
| 3 | Author `/audit` SKILL.md + visual-capture helper | audit | SKILL.md + `scripts/capture-visuals.sh` |
| 4 | Design 2-3 eval cases per skill | all three | `evals/{skill}/evals.json` for each |
| 5 | Run with-skill + baseline runs in parallel; grade; aggregate benchmarks | all three | `evals/{skill}/iteration-1/benchmark.{json,md}` |
| 6 | Iterate based on `eval-viewer` feedback → iteration-2+ until happy | all three | final SKILL.md per skill |
| 7 | Description optimization via `run_loop.py` (5 iterations, 20 trigger queries) | all three | updated `description:` in frontmatter |
| 8 | Functional validation — invoke each skill via `/<name>` against a real scenario; capture transcript evidence | all three | `plans/reports/skill-validation-{name}-260417.md` per skill |

## Success criteria

- [ ] Each skill has a SKILL.md under 500 lines with proper frontmatter (`name`, `description`, optional `compatibility`).
- [ ] Each skill has ≥3 eval cases with assertions.
- [ ] Each skill's with-skill benchmark beats baseline on pass-rate (documented in `benchmark.md`).
- [ ] Each skill's description-optimization loop completed; final `description:` score ≥ 80% on held-out test queries.
- [ ] Each skill invoked manually via `/gt-perfect`, `/root-cause-first`, `/audit` produces the expected workflow output against a real scenario (evidence in `plans/reports/`).
- [ ] Each skill packaged as `.skill` via `package_skill.py` (if `present_files` is available).

## Out of scope

- Multi-agent coordinators or swarms (Plan C).
- Any hook enforcement of the skills — Plan C's PreToolUse hook depends on `/root-cause-first` being stable, so wiring happens in C.

## Unresolved questions

- Should `/gt-perfect` ship as global `~/.claude/skills/` or project-local `yt-shorts-detector/.claude/skills/`? (Recommend: project-local since it encodes detector-specific invariants.)
- How many eval cases per skill — the skill-creator guide suggests 2-3 during dev, then expand; do we expand in this plan or defer to a follow-up tuning plan?
- Description optimization via `run_loop.py` uses `claude -p` — that costs real tokens. Budget for 5 iterations × 20 queries × 3 samples = 300 runs per skill × 3 skills = 900 Claude invocations. OK?
