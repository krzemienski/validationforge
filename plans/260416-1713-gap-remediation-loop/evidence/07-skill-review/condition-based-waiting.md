---
skill: condition-based-waiting
reviewer: R1
date: 2026-04-16
verdict: PASS
---

# condition-based-waiting review

## Frontmatter check
- name: `condition-based-waiting`
- description: `"Wait for conditions, not time: HTTP health polls, port availability, file existence, process readiness, browser content, iOS simulator, DB ready, log patterns. Every wait must timeout."` (191 chars)
- description_well_formed: yes
- yaml_parses: yes

## Trigger realism
Would invoke on: `"wait for server"`, `"service readiness"`, `"health check polling"`, `"async operation"`.
Realism score: 5/5. Developer workflow phrases. Clear and actionable terminology.

## Body-description alignment
PASS. Body delivers all 8 strategies:
1. HTTP Health Poll (server with health endpoint) ✓
2. Port Availability (TCP service without health) ✓
3. File Existence (build artifacts) ✓
4. Process Ready (background services) ✓
5. Browser Content (SPA rendering) ✓
6. iOS Simulator Boot (iOS validation) ✓
7. Database Ready (Docker databases) ✓
8. Log Pattern (services with readiness logs) ✓

All have explicit timeout specifications. References to `references/waiting-strategies.md` and `references/timeout-patterns.md` for complete implementation.

## MCP tool existence
Skill references external documentation files but does not require external MCP servers. Waiting logic is pure shell (curl, nc, ls, pgrep, psql, etc.) — all standard tools.

## Example invocation proof
User: `"Wait for API server to be ready before testing"`
Would use Strategy 1 (HTTP Health Poll) per documented protocol with 30s timeout.

## Verdict
**PASS**

Strong skill with explicit timeout rules (critical defect if missed). Anti-patterns table prevents sleep-based waiting. 8 strategies provide comprehensive coverage. References to implementation guides indicate detailed documentation available.
