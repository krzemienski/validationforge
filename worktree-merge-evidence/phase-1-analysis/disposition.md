# Phase 1: Worktree Disposition Matrix

**Date:** 2026-04-17 07:15 ET
**Main at start of Phase 1:** `a73d9d9 chore: archive skill-grading reports + 2026-04-17 benchmark`
**Worktrees analyzed:** 10

## Disposition Summary

| # | Branch | Commits | Files / LOC | Category | Key Risk |
|---|--------|---------|-------------|----------|----------|
| 001 | e2e-pipeline-verification | 7 | 16 / 1,648 | **Ready (Phase 1 scope)** | "BLOCKED" state is by design — Phase 2+ needs live CC session |
| 002 | plugin-live-load-verification | 5 | 11 / 1,260 | **Needs completion** | Phase 4 live-session verification pending; HIGH conflict risk on plugin.json/hooks |
| 003 | github-repository-publication | 1 | 1 / 21 | **Abandon** | LICENSE already identical on main (51f66bf) |
| 004 | skill-deep-review-top-10 | 16 | 26 / 4,277 | **Needs completion** | 7/10 skills reviewed, NO fixes applied; 2 CRITICAL findings unaddressed |
| 005 | opencode-plugin-verification | 2 | 1 / 3 | **Abandon** | 2/13 subtasks done; unfixed bugs; fresh-start recommended |
| 006 | onboarding-flow-optimization | 0 | 0 / 0 | **Abandon** | Empty branch |
| 012 | evidence-summary-dashboard | 15 | 22 / 2,733 | **Ready** | MEDIUM README conflict risk (vs 013, 019) |
| 013 | ecosystem-integration-guides | 18 | 8 / 1,913 | **Ready** | MODERATE README conflict risk (vs 012, 019); docs-only |
| 015 | documentation-site | 14 | 43 / 14,383 | **Ready** | LOW — site/-isolated; build PASS (33 static pages) |
| 019 | consensus-engine | 18 | 40 / 3,217 | **Ready** | HIGH conflict risk on README / SKILLS.md / COMMANDS.md inventory |

## Buckets

### Ready to merge (5)
`001, 012, 013, 015, 019` — each has evidence of completion, syntactic checks pass, acceptance criteria met or explicitly scoped to Phase-1 of their spec.

### Needs completion (2)
- **002** — Phase 4 of 5 requires a live Claude Code session to run `/validate-ci`. This current session IS a live CC session; the previous auto-claude was sandbox-blocked. Completable here.
- **004** — 7/10 skill reviews done; NO SKILL.md fixes applied yet. 2 CRITICAL findings identified:
  - `preflight` skill: bash glob quoting bug breaks iOS detection
  - `e2e-validate` skill: Iron Rule #4 violation (preflight never invoked)
  Plus 3 remaining skills pending review. Estimated 8–12 hours additional.

### Abandon (3)
- **003** — redundant with main
- **005** — minimal work, unfixed bugs, would be faster to re-plan
- **006** — empty branch

## Conflict Cluster Map

| File | 001 | 002 | 012 | 013 | 015 | 019 |
|------|-----|-----|-----|-----|-----|-----|
| `README.md` | medium | - | ✓ | ✓ | - | ✓ |
| `SKILLS.md` | - | - | ✓ | - | - | ✓ |
| `COMMANDS.md` | - | - | ✓ | - | - | ✓ |
| `CLAUDE.md` | - | - | ✓ | - | - | ✓ |
| `skills/*/SKILL.md` | - | - | new skill | - | - | new skills |
| `commands/*.md` | - | - | new cmd | - | - | new cmd |
| `hooks/*.js` | - | possibly | - | - | - | - |
| `.claude-plugin/plugin.json` | - | ✓ | - | - | - | - |
| `scripts/*` | ✓ (new) | ✓ (new) | ✓ (new) | - | - | ✓ (new) |
| `site/**` | - | - | - | - | ✓ exclusive | - |
| `docs/integrations/*` | - | - | - | ✓ exclusive | - | - |

**Observation:** The inventory-bearing `README.md`, `SKILLS.md`, `COMMANDS.md` are the sole conflict hotspots. All other modifications are either in new paths or branch-exclusive directories.

## Recommended Merge Order (draft)

1. **001** — new-path scaffold, zero inventory edits
2. **015** — site/-isolated, zero conflict surface
3. **019** — largest inventory delta (adds multiple skills/commands/rules); go first of the conflict cluster
4. **012** — next inventory delta (adds evidence-dashboard skill + /validate-dashboard command); resolve against 019
5. **013** — smallest inventory delta (docs + README row); resolve against 019+012

Then (if user wants): complete + merge **002** and **004**. Abandon **003, 005, 006**.

## Outstanding decisions — RESOLVED 2026-04-17 13:30 ET

1. **002 disposition** — ✅ RESOLVED: completed + merged (`c50d101`).
2. **004 disposition** — ✅ RESOLVED: 3 follow-up commits landed on the 004 branch after the Phase-1 analysis (`14b330a`, `496aca9`, `86cff9a`) addressed ALL blockers. Cherry-picked 10 commits to main (7 review artifacts + 3 fix/review commits) instead of branch-merge. Both CRITICAL fixes applied. See `phase-4-merges/merge-04-skill-deep-review/README.md`.
3. **Merge order** — ✅ RESOLVED: executed as 001 → 015 → 002 → 019 → 012 → 013 → 004(cherry-pick). All 7 merged, 3 abandoned as planned.

## Individual Reports

- [worktree-001-e2e-pipeline-verification.md](worktree-001-e2e-pipeline-verification.md)
- [worktree-002-plugin-live-load-verification.md](worktree-002-plugin-live-load-verification.md)
- [worktree-003-github-repository-publication.md](worktree-003-github-repository-publication.md)
- [worktree-004-skill-deep-review.md](worktree-004-skill-deep-review.md)
- [worktree-005-opencode-plugin-verification.md](worktree-005-opencode-plugin-verification.md)
- [worktree-006-onboarding-flow-optimization.md](worktree-006-onboarding-flow-optimization.md)
- [worktree-012-evidence-summary-dashboard.md](worktree-012-evidence-summary-dashboard.md)
- [worktree-013-ecosystem-integration-guides.md](worktree-013-ecosystem-integration-guides.md)
- [worktree-015-documentation-site.md](worktree-015-documentation-site.md)
- [worktree-019-consensus-engine.md](worktree-019-consensus-engine.md)
