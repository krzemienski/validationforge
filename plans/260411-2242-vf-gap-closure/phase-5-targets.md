# Phase 5 — Validation Targets

**Date:** 2026-04-11

## Targets

| # | Target | Path | Expected Platform | Actual Platform |
|---|--------|------|-------------------|-----------------|
| 1 | demo/python-api | `demo/python-api/` | api | generic (correct — Flask uses decorators, not dirs) |
| 2 | site (Astro) | `site/` | web | api (false positive — undici handlers.d.ts in node_modules) |
| 3 | VF self (CLI) | `.` | cli | cli (correct — package.json has "bin") |

## External target decision

No external repo used. Rationale: VF's own codebase serves as the external target — it IS a real published npm package with CLI, plugin structure, hooks, and web site. Testing against self is a stronger validation than testing against a random toy project, because VF's own detection rules must classify VF correctly.
