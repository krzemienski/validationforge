---
skill: web-validation
reviewed_at: 2026-04-16T20:15:00Z
reviewer: R4
---

## Frontmatter Check
- **name:** web-validation ✓
- **description:** "Web validation via browser automation: health checks, screenshots at 375/768/1920px, form testing, console/network validation. Detects CORS, hydration, CSS issues." (139 chars) ✓
- **yaml_parses:** Yes ✓

## Trigger Realism
6 triggers: "web validation", "browser automation", "playwright validation", "web testing", "validate web app", "screenshot test"
**Realism:** 5/5 — All common in web QA

## Body-Description Alignment
**Verdict:** PASS — All description claims verified in 8-step protocol: health checks (Step 2), screenshots at 375/768/1920px (Step 7), form testing (Step 6), console validation (Step 4), network validation (Step 5). Common Failures table includes CORS, hydration, CSS.

## MCP Tool Existence
Playwright MCP (browser_navigate, browser_take_screenshot, browser_click, browser_fill, browser_console_messages, browser_network_requests), Chrome DevTools MCP, Bash ✓

## Example Invocation Proof
**Prompt:** "web validation of the dashboard app" (6 words, viable)

## Verdict
**Status:** PASS

Execution-level skill (not guidance). 8-step protocol covering full web validation: server start (with package manager detection), health check, navigation/screenshots, console/network, form validation, responsive testing, route coverage. Evidence outputs concrete at each step.

## Common Failures Table
8 entries (port conflict, CORS, 404 on refresh, hydration, blank page, styles missing, etc.) with fixes. Very practical troubleshooting guide.

## Notes
- Excellent for regression testing
- Server auto-detection practical
- Health check first prevents cascades
- Step 4 (console errors) strict but correct
- Responsive testing at only 3 widths (could expand to 8 per responsive-validation)
