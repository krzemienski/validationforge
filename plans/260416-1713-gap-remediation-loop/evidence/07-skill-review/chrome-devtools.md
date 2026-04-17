---
skill: chrome-devtools
reviewer: R1
date: 2026-04-16
verdict: PASS
---

# chrome-devtools review

## Frontmatter check
- name: `chrome-devtools`
- description: `"Deep browser inspection via Chrome DevTools MCP: performance profiling (Core Web Vitals), Lighthouse audits, network inspection, console monitoring, memory snapshots. Use for debugging, perf, a11y."` (201 chars)
- description_well_formed: yes
- yaml_parses: yes

## Trigger realism
Would invoke on: `"chrome devtools"`, `"devtools inspection"`, `"network inspector"`, `"performance profiling"`.
Realism score: 5/5. Exact developer terminology. Triggers match skill scope.

## Body-description alignment
PASS. Body delivers all promised capabilities:
- Performance profiling (Core Web Vitals via traces) ✓
- Lighthouse audits (accessibility, SEO, best practices) ✓
- Network inspection (headers, payloads, timing) ✓
- Console monitoring (errors, warnings, logs) ✓
- Memory snapshots (heap profiling) ✓

Six evidence capture patterns provided. Element discovery workflow documented.

## MCP tool existence
- `Chrome DevTools MCP` — explicitly referenced as external server
  - Confirmed available? Yes, MCP server is documented with full tool list (list_pages, navigate_page, lighthouse_audit, etc.)

## Example invocation proof
User: `"Profile Core Web Vitals for this page"`
Would execute Pattern 1 (Page Load Performance): start trace, reload, analyze insights.

## Verdict
**PASS**

Reference skill with comprehensive tool coverage. Workflow is explicit. DevTools vs Playwright comparison table aids tool selection. All 6 capture patterns are actionable.
