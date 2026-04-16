# 260307-unified-validationforge-product — Reality Diff

## Original intent (from vf.md)

The plan opened with an OpenCode-plugin systems-engineer persona and scoped a full-lifecycle audit of an "OpenCode plugin system." It enumerated four OC extension primitives (plugins, skills, commands, rules) and defined a 16-skill scaffold target (VF's first plan).

- **Goal:** Audit and harden a unified VF product across OC primitives, achieving benchmark-validated quality across every skill.
- **Success criteria (implicit):** 16 skills, valid plugin format, input sanitization, benchmark-validated quality.
- **Expected deliverables:** Plugin scaffold, skill library, commands, rules, benchmark system.

## Actual outcome (git + disk)

- Disk now contains 48 skills, 17 commands, 7 registered hooks, 5 agents, 8 rules.
- Plugin is a **Claude Code plugin** (`.claude-plugin/plugin.json`), with an **OpenCode adapter** (`.opencode/plugins/validationforge/index.ts`) added later.
- SPECIFICATION.md:941 still references "16 skills (5,653 lines)" — that was the scaffold target of this plan. The 48 on disk reflect 32 additional skills that arrived across subsequent plans + the spec waves.

## Silent drift

| Drift | Severity |
|-------|----------|
| Platform pivot: OC-first plan → CC-primary product. OC remains as adapter, not target. | HIGH (directional) |
| Skill count grew from 16 target → 48 on disk. No plan in the `plans/` tree documents this growth individually — it accumulated across the 26 `spec-*` auto-claude merges visible in `git log`. | MEDIUM |
| Original plan used `vf.md` naming convention (persona prompt), later plans adopted `plan.md` (spec). Naming drift is minor but complicates tooling that expects consistent filenames. | LOW |

## Verdict

**PARTIALLY DELIVERED → SUPERSEDED**
- The "unified VF product" exists on disk.
- The OC-first framing was retired in favor of a CC-primary approach; the OC adapter (2 .ts files in `.opencode/plugins/validationforge/`) is the vestige of original intent.
- All subsequent plans cite this one as the foundation; none formally close it.

## Citations

- `plans/260307-unified-validationforge-product/vf.md:1-45` (original OC framing)
- `SPECIFICATION.md:941` ("16 skills (5,653 lines)")
- `.claude-plugin/plugin.json` (CC manifest — evidence of CC primacy)
- `.opencode/plugins/validationforge/index.ts` (OC adapter — vestige)
- Git log shows no single commit attributed to this plan; the foundational work landed as a mixture of early uncommitted scaffolding + `spec-*` waves.

## Closure status

Open. Not referenced by `blocks:` / `blockedBy:` in any later plan's frontmatter; effectively orphaned foundational reference.
