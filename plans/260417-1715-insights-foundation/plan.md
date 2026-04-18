---
name: Insights Foundation — CLAUDE.md, Rules, Hooks
status: approved-with-changes
revision: 2026-04-17-post-redteam
mode: deep
blocks: [260417-1715-insights-skills-layer, 260417-1715-insights-ambitious-workflows]
blockedBy: []
created: 2026-04-17
owner: nick
source: plans/reports/insights-report-260417.md (shareable insights dump)
authorities:
  - ~/.claude/skills/skill-creator/SKILL.md
  - ~/.claude/plugins/cache/superpowers-marketplace/superpowers-developing-for-claude-code/0.3.1/skills/working-with-claude-code/SKILL.md
---

# Plan A — Insights Foundation: Rules, CLAUDE.md, Hooks

## Why this plan exists

The `/insights` report over 466 sessions surfaced three recurring failures:
1. **Symptom-patch spiral** — Claude reaches for threshold tweaks, fallback chains, and guards before understanding the bug (multiple reverts in the yt-shorts-detector OCR campaign).
2. **Context exhaustion mid-task** — 16× `Prompt is too long` errors during ralph-mode and observer sessions.
3. **Process-discipline drift in autonomous loops** — "ONE FIX AT A TIME" violated without a hard enforcement mechanism.

Plans B (Skills) and C (Ambitious Workflows) build on top of these foundations. This plan ships the substrate: written conventions + hook enforcement + checkpoint scaffolding that the skills and swarms will depend on.

## Targets (where edits land)

| Surface | Scope |
|---------|-------|
| `~/.claude/CLAUDE.md` | Add **Debugging Protocol**, **Audit Workflow**, and cross-link to new rules |
| `~/.claude/rules/` | Strengthen `instrument-before-theorize.md` → promote to root-cause-first protocol; add `audit-workflow.md`; leave existing rules untouched |
| `~/.claude/hooks/` | Add `syntax-check-after-edit.js` (PostToolUse) and `context-threshold-warn.js` (UserPromptSubmit) |
| `~/.claude/state/` | New dir; add schema for `debug-checkpoint.json` + `audit-checkpoint.json` |
| `yt-transition-shorts-detector/.claude/rules/` | Add `detector-project-conventions.md` (project-local, not global) |
| `yt-transition-shorts-detector/.claude/` | Wire `session-state/` to new checkpoint schema |

## Guiding principles

- **Extend, don't duplicate.** `instrument-before-theorize.md` + `ocr-debug-protocol.md` already exist; strengthen them rather than creating parallel rules.
- **Hooks over prose.** Every rule must have a corresponding enforcement mechanism — either a hook that blocks/warns, or a skill that gates edits.
- **Project-local where project-specific.** Detector conventions go in the detector repo's `.claude/rules/`, not in global user rules.
- **No validation via unit tests.** Validation = running the hook against a real edit, watching the output, confirming the gate fires. See `vf-validation-discipline` rule.

## Phases

| # | Phase | Files touched | Blocks next? |
|---|-------|---------------|--------------|
| 1 | Cross-repo CLAUDE.md additions | `~/.claude/CLAUDE.md`, `yt-transition-shorts-detector/CLAUDE.md` | Yes — 2,3 depend |
| 2 | Strengthen existing rules + add audit-workflow.md | `~/.claude/rules/instrument-before-theorize.md`, `~/.claude/rules/audit-workflow.md` (new), `yt-transition-shorts-detector/.claude/rules/detector-project-conventions.md` (new) | Yes — 3,4 depend |
| 3 | PostToolUse syntax-check hook | `~/.claude/hooks/syntax-check-after-edit.js` (new), `~/.claude/settings.json` | Parallel with 4 |
| 4 | Context-threshold warn hook + checkpoint scaffolding | `~/.claude/hooks/context-threshold-warn.js` (new), `~/.claude/state/` (new), `yt-transition-shorts-detector/.claude/session-state/` (extend) | Parallel with 3 |
| 5 | Functional validation | Run hooks against seeded edits; capture evidence in `plans/reports/` | Final gate |

## Success criteria

- [ ] `~/.claude/CLAUDE.md` contains Debugging Protocol section; diff reviewed.
- [ ] `instrument-before-theorize.md` promoted to "Root-Cause-First Protocol" with written hypothesis requirement.
- [ ] PostToolUse syntax-check hook runs `python -m py_compile` on edited `.py` files; blocks further tool use with stderr+exit 2 on syntax error. Verified by deliberately introducing a SyntaxError and observing the hook fire.
- [ ] Context-threshold warn hook emits checkpoint reminder at 60% context usage. Verified by forcing context pressure and observing the warning.
- [ ] `~/.claude/state/debug-checkpoint.json.schema.json` defines the structure Plans B+C will consume.
- [ ] `yt-transition-shorts-detector/.claude/rules/detector-project-conventions.md` encodes GT-is-the-metric + thread-unsafe adaptive-rescan lesson + fuzz.token_set_ratio over fuzz.ratio.
- [ ] Evidence files saved per hook in `plans/reports/`.

## Out of scope for Plan A

- Writing any of the 3 skills (that's Plan B)
- Multi-agent coordinators or headless batch loops (Plan C)
- Changes to `vf-*` rules (VF's validation semantics are already correct)

## Unresolved questions

- Should the PostToolUse syntax-check cover TypeScript/JS too, or just Python where the insights pain was observed?
- Does the context-threshold hook emit at 60%, 70%, or both (two-stage warning)?
- Detector repo uses `.claude/session-state/` — is that the right location for `debug-checkpoint.json`, or should it live in `.debug/`?
