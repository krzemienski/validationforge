# Phase 02 — Author `/root-cause-first` SKILL.md + evidence templates

## Context Links
- Plan: `plans/260417-1715-insights-skills-layer/plan.md`
- Authoritative skill authoring guide: `~/.claude/skills/skill-creator/SKILL.md` (sections: *Capture Intent*, *Write the SKILL.md*, *Progressive Disclosure*, *Writing Style*)
- Official skill format reference: `~/.claude/plugins/cache/superpowers-marketplace/superpowers-developing-for-claude-code/0.3.1/skills/working-with-claude-code/references/skills.md`
- Plan A deliverables this skill pairs with:
  - `~/.claude/rules/instrument-before-theorize.md` (strengthened with 10-minute ceiling and failed-approaches log)
  - `~/.claude/state/schemas/checkpoint.schema.json`
- Plan C dependency note: the PreToolUse hook in Plan C enforces `.debug/<issue>/evidence.md` existence before Edit/Write — this skill is what produces that file.

## Overview
- **Priority:** P1 — substrate skill; Plan C's hook is non-viable without it.
- **Status:** pending (blocked by Plan A's `instrument-before-theorize.md` rewrite)
- **Description:** Author a global skill at `~/.claude/skills/root-cause-first/` that gates every bugfix behind a completed evidence checklist. Before the model touches Edit/Write for a bug, it fills in `.debug/<issue-id>/evidence.md` (from bundled template) and appends to `.debug/<issue-id>/failed-approaches.md` on each failed iteration.

## Key Insights (from discovery)
- Past sessions consumed hours on theoretical code-path tracing before any print statement or visual dump. The skill must force evidence-before-hypothesis.
- A plain rule (as in `instrument-before-theorize.md`) is easy to skip because it lives in CLAUDE.md-tier context. A *skill* forces a file-producing ritual — model cannot claim "I have evidence" without pointing at a path.
- Evidence file must live in the working tree (`.debug/`), not under `~/.claude/` — so it survives branch switches and ends up in PR diffs where humans can review the reasoning chain.
- `failed-approaches.md` pattern only works if it auto-appends with a stable schema (JSON-lines or templated markdown). Model should not have to invent the format on every retry.
- skill-creator explicitly warns against heavy-handed MUSTs — frame the gate as "the evidence file is cheap insurance" rather than "YOU MUST."

## Requirements

### Functional
- SKILL.md frontmatter `name: root-cause-first`. Description triggers on any debugging/bugfix intent: "debug", "fix this bug", "why is X failing", "the test is broken", "error on line", etc.
- SKILL.md body encodes: (1) resolve issue id (git branch, ticket, or user-provided slug), (2) create `.debug/<issue-id>/` if missing, (3) fill `evidence.md` from template, (4) check `failed-approaches.md` before hypothesizing, (5) commit the evidence file *before* any src edit, (6) after any failed fix, append to `failed-approaches.md`.
- Bundled `assets/evidence.md.template` with five sections: exact failing input, expected vs actual (quoted/screenshot), minimal repro <20 lines, hypothesis naming ONE specific function/line, cross-check of failed-approaches.md.
- Bundled `assets/failed-approaches.md.template` with appendable record format: `{date, issue_id, hypothesis, fix_tried, why_failed}`.
- SKILL.md cross-references `~/.claude/rules/instrument-before-theorize.md` and the checkpoint schema from Plan A.

### Non-functional
- SKILL.md <500 lines.
- Templates are valid markdown that render cleanly in a GitHub PR preview.
- Prose is explanatory, not imperative-heavy — follow skill-creator's *Writing Style* ("explain the why, not MUSTs").

## Architecture

### Skill directory layout
```
~/.claude/skills/root-cause-first/
├── SKILL.md                          # Layer 2 — gate workflow
└── assets/
    ├── evidence.md.template          # Filled per-issue
    └── failed-approaches.md.template # Appended per failed attempt
```

### Progressive disclosure layers
1. **Metadata**: `name` + pushy description triggering on broad debugging vocabulary.
2. **SKILL.md body**: the five-step gate + rationale.
3. **Assets**: templates copied into `.debug/<issue-id>/` on first use.

### Frontmatter shape (example, not final copy)
```yaml
---
name: root-cause-first
description: Force evidence-before-edit on any bugfix. Use WHENEVER the user reports a bug, regression, failing test, unexpected output, error message, crash, stack trace, or says "why is this broken" / "fix this" / "debug" / "something's wrong" — even if they sound confident about the cause. The gate is a single cheap file (.debug/<issue>/evidence.md) that pays for itself the first time it stops a wrong-root-cause fix. Pair with instrument-before-theorize.md.
---
```

### Data flow
```
user reports bug
      │
      ▼
resolve issue-id (branch / ticket / slug)
      │
      ▼
cp evidence.md.template → .debug/<issue>/evidence.md
      │
      ▼
fill: failing input | expected vs actual | minimal repro | hypothesis | failed-approaches check
      │
      ▼
git add .debug/<issue>/evidence.md && commit   ← Plan C hook reads this
      │
      ▼
model may now Edit/Write src
      │
      ▼
on failure: append record to failed-approaches.md, loop to "hypothesis"
```

## Related Code Files

### CREATE
- `/Users/nick/.claude/skills/root-cause-first/SKILL.md`
- `/Users/nick/.claude/skills/root-cause-first/assets/evidence.md.template`
- `/Users/nick/.claude/skills/root-cause-first/assets/failed-approaches.md.template`

### MODIFY
- None in this phase. Plan A ships the rule strengthening; Plan C ships the hook enforcement.

### DELETE
- None.

## Implementation Steps

Follow skill-creator's *Capture Intent → Draft → Writing Style* sequence.

1. **(skill-creator §Capture Intent)** Extract the phrasings from the insights report that historically led to misrouted debugging (e.g. "I think the issue is…" with no evidence).
2. **(skill-creator §Write the SKILL.md — description)** Draft pushy description listing 8+ trigger phrases. Include the counterintuitive case: *even when the user sounds sure about the cause.*
3. Draft SKILL.md body:
   - "Why this gate exists" — one paragraph citing the 2+ hours wasted on theoretical code-path tracing.
   - "The five-step gate" — each step with a one-sentence why.
   - "What the evidence file must contain" — reference `assets/evidence.md.template`.
   - "When to append to failed-approaches.md" — on every failed attempt, before re-hypothesizing.
   - "Relationship to instrument-before-theorize.md" — evidence.md *precedes* instrumentation; instrumentation *feeds* evidence.md's "expected vs actual" section.
4. **(skill-creator §Writing Patterns — Examples)** Add a worked example: a real bug from the detector's OCR pipeline, showing the filled evidence.md and the resulting single-line fix. Source: the OCR debug protocol case in `~/.claude/rules/ocr-debug-protocol.md`.
5. Write `assets/evidence.md.template`. Five sections, each with placeholder prose explaining what goes there and why a vague answer defeats the purpose. Include example for each.
6. Write `assets/failed-approaches.md.template`. Header plus one worked record showing the format, then a `---` separator and instructions for appending.
7. **(skill-creator §Writing Style)** Read SKILL.md with fresh eyes; strip any caps-MUST that can be replaced with "because past sessions showed…".
8. Stage for Phase 4 eval design.

## Todo List
- [ ] Draft pushy frontmatter description (8+ trigger phrases, include the "even if confident" clause)
- [ ] Draft SKILL.md body with five-step gate + rationale
- [ ] Author `assets/evidence.md.template` with inline explanations per section
- [ ] Author `assets/failed-approaches.md.template` with worked record
- [ ] Add OCR-pipeline worked example referencing real past bug
- [ ] Fresh-eyes pass: remove caps-MUSTs, explain why
- [ ] Verify templates render in markdown preview

## Success Criteria
- SKILL.md frontmatter parses as valid YAML.
- A model reading SKILL.md + the user prompt "the login flow is broken, fix it" produces `.debug/<issue>/evidence.md` before any src edit (validated in Phase 5 with-skill runs).
- Baseline (no-skill) runs on the same prompt show direct src edits without evidence.md — the delta between with-skill and baseline is what the Phase 5 benchmark surfaces.
- Templates render cleanly in GitHub PR preview (manual smoke in a test branch).

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Skill triggers on trivial one-line syntax fixes and adds friction | Medium | Medium | Description explicitly carves out "one-line typo" / "obvious syntax" cases; Phase 7 description optimization tunes this |
| Model fills evidence.md with boilerplate and moves on (Goodhart) | Medium | High | Template's prompts are specific (*name ONE function + line*); Phase 8 manual validation catches boilerplate |
| `.debug/` dir accumulates and clutters repos | Low | Low | `.debug/` goes in `.gitignore` by default — but per-bug files can be committed when the bug is real and interesting |
| Plan C hook ships before this skill is stable | High | High | Plan.md declares this phase as `blocks:` Plan C's hook wiring; Plan C cannot merge without this phase complete |
| Overtriggers on non-bug refactors | Medium | Medium | Description says "bugfix", not "any edit"; validate in Phase 7 with refactor-style near-miss queries |

## Security Considerations
- Templates are plain markdown — no executable content, no references to external resources.
- `.debug/<issue>/` files can contain sensitive repro data (API payloads, user IDs). SKILL.md instructs the model to redact secrets before committing.
- Global skill (under `~/.claude/skills/`) means every project inherits it — document in SKILL.md that the skill is safe to disable per-project via `skill-activation-forced-eval.js` kill-switch patterns if needed.

## Next Steps
- Phase 3 (`/audit`) can run in parallel — separate skill dir, no file ownership overlap.
- Phase 4 (eval design) depends on this phase complete.
- Plan C PreToolUse hook wiring depends on this skill being in Phase 7-optimized state.
