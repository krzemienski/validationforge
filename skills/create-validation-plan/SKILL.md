---
name: create-validation-plan
description: "Use BEFORE capturing any evidence. Plans prevent the two most common validation failures: missed journeys (you didn't test the flow that actually breaks) and vague PASS criteria (you can't tell if a run passed). This skill walks you through discovering every user journey (routes, endpoints, screens, commands), writing falsifiable PASS criteria per journey, ordering journeys by dependency, and listing prerequisites. Output is a persistent plan at e2e-evidence/validation-plan.md that guides the rest of the validation pipeline. Reach for it whenever someone says 'let's start validating', 'what should we test', 'write a test plan', 'define acceptance criteria', or before invoking e2e-validate / forge-execute."
triggers:
  - "validation plan generation"
  - "journey discovery"
  - "pass criteria definition"
  - "validation strategy planning"
  - "upfront planning before execution"
  - "write a test plan"
  - "what should we test"
  - "define acceptance criteria"
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

Scan the codebase for every entry point users interact with. The exact commands depend on platform — here are starting points; see `references/journey-discovery-patterns.md` for the full playbook per framework.

- **Web (Next.js app router)**: `rg -l 'export default' app/**/page.*`
- **Web (React Router)**: `rg '<Route\s' src/`
- **API (Express/Fastify)**: `rg '\.(get|post|put|delete|patch)\(' --type js --type ts`
- **API (FastAPI)**: `rg '@(app|router)\.(get|post|put|delete|patch)'`
- **API (Django)**: `python manage.py show_urls` (requires `django-extensions`), or `rg 'path\(|url\(' */urls.py`
- **iOS (SwiftUI)**: `rg 'struct \w+:\s*View'` for screens; `rg 'NavigationLink'` for flows
- **CLI (Clap)**: `rg '#\[command\(' --type rust`
- **CLI (Click/argparse)**: `rg '@.*\.command|add_parser'`

**Rules of thumb:**
- Each route = at least one journey.
- Each form = a user interaction journey (test valid submit AND invalid submit — that's two journeys if the error path is substantial).
- Each auth boundary = a journey (authenticated access + unauthenticated-denied + wrong-role-denied).
- Each empty state and error state = a journey. These are the ones most often missed, and they're where real bugs hide.

Don't hand-maintain the list long-term — journey discovery should be rerun whenever routes/endpoints change, so plans stay honest.

## PASS Criteria Rules

Every criterion must be all 8 of these. See `references/pass-criteria-examples.md` for
good/bad examples and the anti-patterns table.

| Rule | Bad | Good |
|------|-----|------|
| Specific | "Login works" | "POST /login returns 200 with `token` field" |
| Measurable | "Page loads fast" | "DOMContentLoaded < 2s" |
| Observable | "Data saved correctly" | "GET /users/1 returns updated name" |
| Complete | Happy path only — "POST /login with valid creds returns 200" | Happy + error paths — "POST /login with valid creds returns 200 + token; POST /login with invalid creds returns 401 + error message body" |
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

1. **Plan before evidence.** If you start capturing evidence without a plan, you have no way to know when you're done, and the evidence you gather will match what you tested, not what matters.
2. **Plan is persistent.** Save to `e2e-evidence/validation-plan.md` so the next run, the next teammate, and future you can reuse it.
3. **Criteria must be falsifiable.** If there's no concrete way to say "this failed", it will never fail — which means the criterion isn't doing any work.
4. **Never skip journey discovery.** Routes, endpoints, screens, and commands must all be mapped. Coverage gaps in the plan become coverage gaps in validation; what you didn't plan for is what ships broken.

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
