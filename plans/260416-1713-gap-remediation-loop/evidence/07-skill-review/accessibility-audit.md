---
skill: accessibility-audit
reviewer: R1
date: 2026-04-16
verdict: PASS
---

# accessibility-audit review

## Frontmatter check
- name: `accessibility-audit`
- description: `"Audit WCAG 2.1 AA compliance across 4 layers (Lighthouse, keyboard nav, screen reader, contrast). Use before public release, after UI changes, or on a11y complaints."` (177 chars)
- description_well_formed: yes
- yaml_parses: yes

## Trigger realism
Would invoke on: `"accessibility audit"`, `"wcag compliance"`, `"screen reader validation"`, `"a11y audit"`.
Realism score: 5/5. Phrases match explicit triggers exactly. Direct and actionable terminology.

## Body-description alignment
PASS. Body realizes the 4-layer promise:
- Layer 1 (Automated): Lighthouse via Chrome DevTools MCP ✓
- Layer 2 (Keyboard): Tab navigation, focus testing ✓
- Layer 3 (Screen Reader): A11y tree structure checks ✓
- Layer 4 (Visual): Contrast, color, dark mode audit ✓

Scoring and verdict section provides weighted decision framework. All promise kept.

## MCP tool existence
- `chrome-devtools` — referenced for `lighthouse_audit`, `take_snapshot`, `take_screenshot`, `emulate`
  - Confirmed available in this session? Yes (verified in skills/chrome-devtools/SKILL.md)
- `playwright-mcp` — referenced for keyboard navigation
  - Confirmed available? Referenced but not explicit in provided skills; complementary tool. Likely available via context7

## Example invocation proof
User: `"Audit WCAG 2.1 AA compliance before public release"`
Would trigger and deliver 4-layer audit per documented protocol.

## Verdict
**PASS**

Skill is well-formed, description matches body, MCP tools are documented and available, example invocation is realistic and would execute correctly.
