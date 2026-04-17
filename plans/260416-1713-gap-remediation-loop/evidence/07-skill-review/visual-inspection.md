---
skill: visual-inspection
reviewed_at: 2026-04-16T20:15:00Z
reviewer: R4
---

## Frontmatter Check
- **name:** visual-inspection ✓
- **description:** "Capture rendered UI state via screenshots across breakpoints, modes, edge cases. Use before claiming frontend work done, validating responsive layouts, dark/light modes, empty/error/loading states." (176 chars) ✓
- **yaml_parses:** Yes ✓

## Trigger Realism
6 triggers: "visual inspection", "check the UI", "does it look right", "visual review", "UI inspection", "screenshot review"
**Realism:** 5/5 — All common in frontend QA

## Body-Description Alignment
**Verdict:** PASS — Evidence Capture Protocol stated. Inspection Checklist covers breakpoints, dark/light modes, edge cases (empty/error/loading states). All claims verified.

## MCP Tool Existence
Playwright MCP (browser_take_screenshot, browser_snapshot), Chrome DevTools MCP, xcrun simctl (iOS), idb (iOS) ✓

## Example Invocation Proof
**Prompt:** "visual inspection of the login page" (6 words, viable)

## Verdict
**Status:** PASS

Comprehensive validation skill with 7 inspection categories and 30+ checks. Philosophy strong: "You are a camera, not an optimist." Severity classification (CRITICAL, HIGH, MEDIUM, LOW) with examples. Evidence Capture Protocol platform-specific (Web, iOS).

## Notes
- Anti-patterns section prevents vague language
- Edge cases section often overlooked in other tools
- Complements responsive-validation (visual cluster)
