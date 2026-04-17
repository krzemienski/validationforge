---
skill: verification-before-completion
reviewed_at: 2026-04-16T20:15:00Z
reviewer: R4
---

## Frontmatter Check
- **name:** verification-before-completion ✓
- **description:** "Block premature completion: require personally examined evidence, specific citations, criteria matching, regression checks, final state capture. Use before marking tasks done, closing gates." (153 chars) ✓
- **yaml_parses:** Yes ✓

## Trigger Realism
6 triggers: "verification before completion", "complete task", "close gate", "mark done", "evidence checklist", "can i ship this"
**Realism:** 5/5 — All align with completion workflows

## Body-Description Alignment
**Verdict:** PASS — Checklist enforces: personally examined evidence, specific citations, criteria matching, regression checks, final state capture. All claims verified.

## MCP Tool Existence
No tools required — read-only verification skill ✓

## Example Invocation Proof
**Prompt:** "can i mark this task complete" (6 words, viable)

## Verdict
**Status:** PASS (with minor concern)

**CONCERN:** Skill references `references/evidence-citation-examples.md` (not present in repo). File should exist but is missing. Recommended action: create file or reference from existing docs.

## Verification Checklist
7 comprehensive checks covering: personally examined evidence, view actual screenshot, examine actual output, cite specific evidence, skeptical reviewer test, regression checks, final state capture.

## Notes
- Critical gate-keeping skill
- Very strong on preventing premature completion
- Verification checklist honest and skeptical
- Integrates with e2e-evidence framework
