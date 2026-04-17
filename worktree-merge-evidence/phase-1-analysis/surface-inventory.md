# Phase 2: Surface Inventory

**Scope:** User-facing surfaces (commands, skills, agents, hooks, rules, docs) that worktrees touch. This feeds the Phase 5 post-merge audit checklist.

## Current main surface counts (pre-merge)

| Category | Count (main) |
|----------|-------------|
| Commands | 17 |
| Skills | 48 |
| Agents | 5 |
| Hooks | 7 |
| Rules | 8 |
| Templates | see below |
| Scripts (scripts/) | see below |
| Docs site (site/) | scaffold present |

## Per-branch surface deltas

### 001 — e2e-pipeline-verification (Ready)
- **New scripts:** `scripts/e2e-pipeline-check.sh` (preflight harness, 215 LOC); `scripts/verify-setup.sh` enhanced.
- **New evidence:** `e2e-evidence/pipeline-verification/` (web/, api/, run-book.md, HANDOFF.md, api-fixture-decision.md).
- **Surfaces:** scaffolding only — no new user-facing commands or skills.

### 002 — plugin-live-load-verification (Needs completion → Ready per user)
- **New evidence:** `e2e-evidence/plugin-load-verification/` (verify-step-*.js, step-01…step-10 evidence JSON/txt).
- **Touched (light):** `.claude-plugin/plugin.json`, `hooks/*` (read-only verification).
- **Surfaces:** verification harness only — no new user-facing primitives.

### 004 — skill-deep-review-top-10 (Needs completion → Ready per user)
- **Diagnostic artifacts (26 files):** `skill-audit-workspace/`, `audit-artifacts/`, `findings.md`, `skill-review-results.md`.
- **Planned fixes (pending):**
  - `skills/preflight/SKILL.md` — iOS detection glob quoting bug.
  - `skills/e2e-validate/SKILL.md` — invoke preflight per Iron Rule #4.
- **Surfaces:** No new skills; **modifies** 2 existing SKILL.md files.

### 012 — evidence-summary-dashboard (Ready)
- **New skill:** `skills/evidence-dashboard/SKILL.md` (172 LOC).
- **New command:** `commands/validate-dashboard.md` (201 LOC).
- **New templates:** `templates/dashboard.html.tmpl` (458 LOC), `templates/dashboard.md.tmpl` (48 LOC).
- **New script:** `scripts/generate-dashboard.sh` (871 LOC).
- **Touched inventory files:** `README.md`, `CLAUDE.md`, `ARCHITECTURE.md` — new entries.
- **Surfaces:** +1 skill, +1 command.

### 013 — ecosystem-integration-guides (Ready)
- **New docs:** `docs/integrations/vf-with-omc.md` (465), `vf-with-superpowers.md` (620), plus additional integration guides.
- **Touched:** `README.md` ("Works With Other Plugins" section), `docs/README.md` (Inventory row).
- **Surfaces:** documentation only — no new executable primitives.

### 015 — documentation-site (Ready)
- **New subtree:** `site/` — Astro/Starlight docs site (14,383 LOC across 43 files).
  - `site/src/content/docs/` — 10 skill pages, 15 command pages, 3 integration guides, getting-started, config.
  - `site/package.json`, `site/tsconfig.json`, `site/astro.config.mjs`.
- **Touched outside site/:** none of significance (only implementation_plan.json + verdict.md).
- **Surfaces:** docs site (new independent deployable).

### 019 — consensus-engine (Ready)
- **New skills:** `skills/consensus-engine/SKILL.md`, `skills/consensus-synthesis/SKILL.md` (258 LOC), `skills/consensus-disagreement-analysis/SKILL.md`.
- **New agents:** 2 (names tbc; count from analysis report).
- **New command:** `commands/validate-consensus.md`.
- **New rule:** `rules/consensus-*.md`.
- **New template:** `templates/consensus-report.md` (182 LOC).
- **New script:** structural benchmark script.
- **Touched inventory files:** `README.md`, `SKILLS.md`, `COMMANDS.md`, `CLAUDE.md` — inventory row additions.
- **Surfaces:** +3 skills, +2 agents, +1 command, +1 rule.

## Post-merge projected totals

| Category | Pre (main) | +001 | +015 | +002 | +004 | +019 | +012 | +013 | Projected |
|----------|-----|------|------|------|------|------|------|------|----------|
| Commands | 17 | - | - | - | - | +1 | +1 | - | **19** |
| Skills | 48 | - | - | - | - | +3 | +1 | - | **52** |
| Agents | 5 | - | - | - | - | +2 | - | - | **7** |
| Hooks | 7 | - | - | - | - | - | - | - | 7 |
| Rules | 8 | - | - | - | - | +1 | - | - | **9** |

## Post-merge audit checklist (for Phase 5)

For each new primitive, Phase 5 must validate:

1. **Loads** — plugin.json / hooks.json references resolve.
2. **SKILL.md frontmatter valid** — YAML parses, required fields present.
3. **Command frontmatter valid** — YAML parses.
4. **Inventory accurate** — README.md / SKILLS.md / COMMANDS.md counts match disk.
5. **No broken references** — cross-references from CLAUDE.md / other skills resolve to real files.
6. **Scripts syntactically valid** — `bash -n` on every new .sh.
7. **Hooks syntactically valid** — `node --check` on every JS hook.

Full functional validation (running the skills, invoking the commands) is the Phase 5 audit body.

## Conflict resolution playbook

| File | Strategy |
|------|----------|
| `README.md` inventory rows | Merge in branch order (001→015→019→012→013); renumber rows as each branch lands |
| `SKILLS.md` table | Same as README — renumber as entries accumulate |
| `COMMANDS.md` table | Same as SKILLS |
| `CLAUDE.md` inventory | Additive — combine bullets from each branch |
| `scripts/` | All new files, no overlap expected |
| `site/` | 015-exclusive, no conflicts |
| `skills/preflight/SKILL.md` | 004 modifies; no other branch touches |
| `skills/e2e-validate/SKILL.md` | 004 modifies; no other branch touches |
