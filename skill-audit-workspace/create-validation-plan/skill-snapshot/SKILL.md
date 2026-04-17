---
name: create-validation-plan
description: "Create BEFORE evidence capture. Defines PASS criteria per journey (P0/P1/P2 priority). Maps routes/endpoints/screens, orders by dependency, checks prerequisites. Use when starting validation."
triggers:
  - "validation plan generation"
  - "journey discovery"
  - "pass criteria definition"
  - "validation strategy planning"
  - "upfront planning before execution"
context_priority: critical
---

# Create Validation Plan

## Scope

This skill handles: journey discovery, PASS criteria definition, plan document creation at `e2e-evidence/validation-plan.md`.
Does NOT handle: prerequisite verification (use `preflight`), evidence capture and execution (use `e2e-validate`), verdict evaluation (use `gate-validation-discipline`).

## Quick Start

```bash
mkdir -p e2e-evidence/
PLAN_FILE="e2e-evidence/validation-plan.md"
echo "# Validation Plan" > "$PLAN_FILE"
echo "**Created:** $(date '+%Y-%m-%d %H:%M')" >> "$PLAN_FILE"
echo "**Status:** DRAFT" >> "$PLAN_FILE"
```

After creating the file, populate it by scanning the codebase for user journeys.

## Plan Structure

Every plan follows this format:

| Section | Purpose |
|---------|---------|
| Metadata | Project, platform, date, scope, evidence dir |
| Prerequisites | All conditions that must be true before validation starts |
| Journey Inventory | Table: ID, journey name, priority (P0/P1/P2), dependencies, status |
| Journey Details | Per-journey: steps, PASS criteria, evidence required, capture commands |
| Execution Order | Dependency-respecting sequence (bottom-up for fullstack) |
| Summary | Priority counts and ship requirements |

**Priority definitions:** P0 = core (must pass), P1 = important (should pass), P2 = edge cases (best effort).

## Journey Discovery

Scan the codebase for routes, endpoints, screens, and commands by platform.
See `references/journey-discovery-patterns.md` for platform-specific discovery commands
(Web, API, iOS, CLI). Rule: each route = at least one journey; each form = a user interaction journey.

## PASS Criteria Rules

Every criterion must be all 8 of these. See `references/pass-criteria-examples.md` for
good/bad examples and the anti-patterns table.

| Rule | Bad | Good |
|------|-----|------|
| Specific | "Login works" | "POST /login returns 200 with `token` field" |
| Measurable | "Page loads fast" | "DOMContentLoaded < 2s" |
| Observable | "Data saved correctly" | "GET /users/1 returns updated name" |
| Complete | Happy path only | Happy + error paths |
| Ordered | Dashboard before login | Login PASS before dashboard starts |
| Evidence-mapped | No proof method | "Screenshot shows 3 metric cards" |
| Non-redundant | "Login works and dashboard loads" | Separate criteria |
| Falsifiable | "App doesn't crash" | "Navigate 5 screens, zero console errors" |

## Plan Quality Checklist

Before starting evidence capture, verify ALL:

- [ ] Every journey has unique ID (J1, J2...) and priority (P0/P1/P2)
- [ ] Every journey has explicit steps with expected outcomes
- [ ] Every journey has at least 2 PASS criteria
- [ ] Every criterion is specific, measurable, observable, and evidence-mapped
- [ ] Error paths covered (not just happy paths)
- [ ] Dependencies documented and execution order respects them
- [ ] Prerequisites list everything needed before validation starts

## Rules

1. Plan MUST be created before any evidence capture begins
2. Plan is saved as persistent artifact at `e2e-evidence/validation-plan.md`
3. PASS criteria must be falsifiable — possible to definitively fail
4. Never skip journey discovery — routes, endpoints, screens, and commands must all be mapped

## Security Policy

Plans must not contain secrets, credentials, or PII. Use placeholder references
(e.g., `[TEST_USER_EMAIL]`) for auth credentials in plan templates.

## Related Skills

- **preflight** — Verify prerequisites listed in this plan are met
- **e2e-validate** — Execute the plan and capture evidence for each journey
- **gate-validation-discipline** — Verify captured evidence satisfies PASS criteria
- **baseline-quality-assessment** — Capture "before" state when validating changes
- **error-recovery** — Handle failures encountered during plan execution

## References

- `references/journey-discovery-patterns.md` — Platform-specific commands to find all user journeys
- `references/pass-criteria-examples.md` — Good/bad criteria examples and anti-patterns table
