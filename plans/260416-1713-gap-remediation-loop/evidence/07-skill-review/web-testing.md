---
skill: web-testing
reviewed_at: 2026-04-16T20:15:00Z
reviewer: R4
---

## Frontmatter Check
- **name:** web-testing ✓
- **description:** "5-layer web validation: integration (APIs), E2E (journeys), accessibility (WCAG), performance (Core Web Vitals), security (OWASP). Decide which layers a feature needs. Real systems only—no mocks." (181 chars) ✓
- **yaml_parses:** Yes ✓

## Trigger Realism
4 triggers: "web testing strategy", "web validation strategy", "how to validate web app", "web quality strategy"
**Realism:** 5/5 — All align with planning/strategy phases

## Body-Description Alignment
**Verdict:** PASS — Validation Layers section shows 5 layers matching all description claims. Decision Matrix maps feature types to required layers. Philosophy explicitly states real systems only.

## MCP Tool Existence
curl, Playwright MCP (browser_navigate, browser_snapshot, etc.), Chrome DevTools MCP (performance_start_trace, lighthouse_audit), Lighthouse ✓

## Example Invocation Proof
**Prompt:** "web testing strategy for new dashboard" (6 words, viable)

## Verdict
**Status:** PASS

Strategic reference skill (not execution-level). Decision Matrix prevents over/under-validation. Layer details concrete for each of 5 layers. Evidence organization clear (separate directories per layer).

## Notes
- Excellent for teams new to ValidationForge
- Decision matrix most valuable section
- Prevents scope creep (not all features need all 5 layers)
- Pure guidance; no automation needed
