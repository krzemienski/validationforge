---
skill: responsive-validation
reviewed_at: 2026-04-16T20:15:00Z
reviewer: R4
---

## Frontmatter Check
- **name:** responsive-validation ✓
- **description:** "Validate layouts across 8 device viewports (375px–1920px): layout, touch targets, typography, content parity, orientation, overflow. Use after responsive redesigns, CSS refactors, mobile launches." (174 chars) ✓
- **yaml_parses:** Yes ✓

## Trigger Realism
5 triggers: "responsive validation", "responsive testing", "viewport testing", "mobile responsive", "breakpoint validation"
**Realism:** 5/5 — All match common UX/QA workflows

## Body-Description Alignment
**Verdict:** PASS — Device Matrix lists exact 8 viewports. Phase 2 covers touch targets, typography, content parity, orientation, overflow. All claims verified.

## MCP Tool Existence
Playwright MCP (`browser_resize`), Chrome DevTools MCP (`emulate`) ✓

## Example Invocation Proof
**Prompt:** "responsive validation for dashboard app" (5 words, viable)

## Verdict
**Status:** PASS

4-phase protocol. Evidence structure concrete (e2e-evidence/responsive-validation/{mobile-375,tablet-768,...}/step-*.png). Verdict rules explicit (PASS/CONDITIONAL/FAIL thresholds).

## Notes
- Heavy on screenshot capture/comparison (1-2 hours)
- Pairs well with visual-inspection for detailed UX review
