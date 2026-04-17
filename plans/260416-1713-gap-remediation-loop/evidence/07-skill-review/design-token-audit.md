---
skill: design-token-audit
reviewer: R1
date: 2026-04-16
verdict: PASS
---

# design-token-audit review

## Frontmatter check
- name: `design-token-audit`
- description: `"Audit CSS/Tailwind/inline styles against design system spec (DESIGN.md, tailwind.config, CSS vars). Detects hardcoded values, off-palette colors, non-standard spacing, typography drift."` (193 chars)
- description_well_formed: yes
- yaml_parses: yes

## Trigger realism
Would invoke on: `"design token audit"`, `"token compliance"`, `"color audit"`, `"design system drift"`.
Realism score: 5/5. Design team phrasing. Triggers match design workflow terminology exactly.

## Body-description alignment
PASS. Body delivers all promised audit capabilities:
- Phase 1 (Extract): Tokens from DESIGN.md, Tailwind config, CSS variables ✓
- Phase 2 (Scan): Color, typography, spacing scans via grep ✓
- Phase 3 (Compare): Violation types with severity (HIGH/MEDIUM/LOW) ✓
- Phase 4 (Report): Compliance calculation and verdict ✓
- Detects hardcoded values, off-palette colors, non-standard spacing, typography drift ✓

Compliance scoring formula is explicit. Violation types table is comprehensive.

## MCP tool existence
None required. Audit uses grep, shell tools, and markdown. Integrates with `stitch-integration` for design tokens but does not require it.

## Example invocation proof
User: `"Audit Tailwind classes for design system compliance"`
Would execute 4-phase process (extract, scan, compare, report) per documented protocol.

## Verdict
**PASS**

Design-specific skill with clear audit phases. Violation types and severity levels are well-defined. Compliance formula is calculable. Evidence structure is clear (e2e-evidence/design-tokens/).
