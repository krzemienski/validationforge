---
skill: playwright-validation
reviewer: R3
date: 2026-04-16
verdict: PASS
---

# playwright-validation review

## Frontmatter check
- name: `playwright-validation`
- description: `Validate web features via real browser interaction: screenshots, DOM snapshots, form testing, responsive layouts, console/network error detection. Use for feature verification and evidence capture.`
- description_chars: 162
- yaml_parses: yes

## Trigger realism
- Trigger phrases: `playwright validation`, `browser validation`, `web browser test`, `playwright verify`
- Realism score (5/5): Triggers match real web validation workflows

## Body-description alignment
- Verdict: PASS
- Evidence: Description matches body exactly. Validation Protocol has 7 steps (Setup, Navigate and Capture, Exercise Features, Responsive Testing, Form Validation, Console Error Check, Network Request Verification). Responsive Testing covers 4 breakpoints (375px, 768px, 1440px). Common Patterns section covers Authentication Flow, CRUD Operations, Navigation. Anti-Patterns table documents 5 incorrect approaches with corrections.

## MCP tool existence
- Tools referenced: Playwright MCP tools (browser_navigate, browser_snapshot, browser_take_screenshot, browser_click, browser_fill_form, browser_console_messages, browser_network_requests, browser_resize)
- Confirmed: yes (Playwright MCP is standard Claude Code integration)

## Example invocation
"Validate the web dashboard feature with responsive layout testing"

## Verdict
PASS
- 7-step protocol is complete and testable
- Prerequisites section covers dev server startup (npm run dev, pnpm dev, yarn dev, etc.)
- Responsive Testing table covers 4 standard breakpoints with device classes
- Form Validation section tests both happy path and validation errors
- Console Error Check enforces that "any console error is a finding"
- Network Request Verification checks for failed requests and unexpected API calls
- Common Patterns section provides templates for Authentication, CRUD, Navigation
- Anti-Patterns table maps incorrect approaches to correct ones
- Evidence Output structure is clear with inventory generation command
