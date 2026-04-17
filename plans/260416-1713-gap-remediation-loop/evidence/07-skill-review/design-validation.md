---
skill: design-validation
reviewer: R1
date: 2026-04-16
verdict: PASS
---

# design-validation review

## Frontmatter check
- name: `design-validation`
- description: `"Compare implementation screenshots against design refs (Stitch, DESIGN.md, Figma). Scores colors, typography, spacing, layout, interactions across 5 categories. Use after UI implementation."` (200 chars)
- description_well_formed: yes
- yaml_parses: yes

## Trigger realism
Would invoke on: `"design validation"`, `"design fidelity"`, `"compare design to implementation"`, `"does it match the design"`.
Realism score: 5/5. Natural designer/developer phrases. Realistic invocation flow.

## Body-description alignment
PASS. Body delivers all promised validations:
- Phase 1 (Reference): Stitch MCP, DESIGN.md, external sources ✓
- Phase 2 (Capture): Screenshots at matching viewport, computed styles, a11y tree ✓
- Phase 3 (Compare): 5-category scoring (Colors, Typography, Spacing, Layout, Interactions) ✓
- Fidelity scoring rubric (0-100 scale with interpretations) ✓
- Comparison checklist for each category ✓

Verdict rules are explicit. Overall score calculation is formulaic. Evidence structure is clear.

## MCP tool existence
- `stitch-integration` — referenced for design references via Stitch MCP
  - Confirmed available? Referenced but not in MCP provider list; documented as "preferred" method
- `Playwright MCP` or `Chrome DevTools MCP` — for capturing implementation screenshots
  - Confirmed available? Yes (verified in other skills)

## Example invocation proof
User: `"Validate that the dashboard matches the design mockup"`
Would execute 3-phase process: gather reference from Stitch/DESIGN.md, capture screenshots, score fidelity.

## Verdict
**PASS**

Design-focused skill with clear 3-phase process. 5-category scoring is granular and weighted. Viewport matching rule prevents false negatives. Integration with stitch-integration and design-token-audit is noted.
