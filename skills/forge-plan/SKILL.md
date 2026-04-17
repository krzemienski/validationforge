---
name: forge-plan
description: "Use before /validate or /forge-execute on any new project. Scans the codebase for user-facing features (routes, endpoints, screens, CLI commands), groups them into user journeys, writes specific PASS criteria per step with required evidence type, and saves to e2e-evidence/validation-plan.md where forge-execute will pick it up. Three modes: quick (small projects, critical journeys only), standard (full discovery + coverage + gap-filling), consensus (three perspectives — user advocate, security, QA — merged for critical/multi-team projects). Reach for it on phrases like 'what should I validate', 'create a validation plan', 'plan before running validate', or when there's no validation-plan.md yet."
triggers:
  - "plan validation"
  - "create validation plan"
  - "what should I validate"
  - "forge plan"
  - "generate validation plan"
  - "journey discovery"
  - "plan before validate"
context_priority: reference
---

# forge-plan

Generate a validation plan with journey discovery, PASS criteria, and evidence requirements. Supports quick, standard, and consensus planning modes.

## When to use

Run this before `/validate` or `/forge-execute`. Those commands read `e2e-evidence/validation-plan.md` during their first phase; without a plan, they have no PASS criteria to check evidence against. This skill is closely related to `create-validation-plan` — the practical difference is that `forge-plan` bundles three planning modes (quick/standard/consensus) optimized for different project sizes and risk levels, while `create-validation-plan` is the underlying protocol.

## Modes

### Quick Mode (default for small projects)

1. Detect platform
2. Discover user-facing features (routes, screens, endpoints)
3. Generate journeys with PASS criteria
4. Output plan to `e2e-evidence/validation-plan.md`

### Standard Mode

1. **Discovery** — Scan codebase for all user-facing interactions
   - Web: routes, forms, navigation, interactive components
   - API: endpoints, request/response schemas, auth flows
   - iOS: view controllers, navigation stacks, gesture handlers
   - CLI: commands, flags, input/output formats
2. **Journey Generation** — Group features into user journeys
   - Each journey = a complete user workflow (e.g., "Sign up and verify email")
   - Each journey has 3-7 steps with specific PASS criteria
   - Each step specifies required evidence type (screenshot, API response, log output)
3. **Coverage Analysis** — Map journeys to features
   - Identify uncovered features
   - Flag high-risk areas (auth, payment, data mutation)
4. **Gap Filling** — Generate additional journeys for uncovered areas

### Consensus Mode

Use consensus mode for critical or multi-team projects where different stakeholders care about different aspects. Three independent perspectives analyze the project in parallel, then merge into one plan:

| Perspective | Focus |
|-------------|-------|
| User Advocate | User-facing flows, UX edge cases, accessibility |
| Security Analyst | Auth flows, data validation, injection vectors |
| Quality Engineer | Error handling, edge cases, performance boundaries |

**Merge protocol:**

1. Each perspective generates its journeys independently (parallel agents).
2. Group journeys by feature area (Authentication, Signup, Dashboard, etc.).
3. **For each group, merge overlapping journeys into a single journey that covers all three aspects** — don't pick one and drop the others. The value of consensus mode is precisely in keeping all three concerns.
4. Verify coverage: after merging, confirm each original perspective's concerns appear somewhere in the final plan.

**Merge helper**: `bash scripts/forge-plan-merge.sh --plan-a=planner-1.md --plan-b=planner-2.md --output=merged-plan.md` applies the merge algorithm below deterministically. It unions journeys by case-insensitive name, unions PASS criteria per journey, and writes a `## Merge Summary` at the top of the output. Conflicts (same subject, different expectations — e.g. one plan says "returns 200" and the other "returns 201") go to stderr with the `CONFLICT:` prefix for human review; plan A's version is kept in the output annotated with an HTML comment. Run the helper pairwise for three-perspective merges: merge planners 1+2 first, then merge the result with planner 3.

**Worked example** — password reset journey:

- User Advocate wants: "User can request reset, receives clear error messages, sees confirmation"
- Security Analyst wants: "Rate-limited to N requests per hour, token expires after 15 min, token is single-use"
- Quality Engineer wants: "Expired token shows useful error; invalid token shows useful error; concurrent reset requests handled"

Merged journey covers all three: 6 steps, PASS criteria include UX confirmation messages, rate-limit observed in logs/responses, token expiry enforced, error messages specific.

## Plan Output Format

```markdown
# Validation Plan

## Project: {name}
## Platforms: {detected platforms}
## Generated: {timestamp}
## Mode: {quick|standard|consensus}

## Coverage Matrix

| Feature Area | Journeys | Risk Level |
|-------------|----------|------------|
| Authentication | 3 | HIGH |
| Dashboard | 2 | MEDIUM |
| Settings | 1 | LOW |

## Journeys

### J1: {Journey Name}
**Risk:** HIGH | MEDIUM | LOW
**Steps:**
1. {Action} → **PASS:** {specific criterion} → **Evidence:** {type}
2. {Action} → **PASS:** {specific criterion} → **Evidence:** {type}

### J2: ...
```

## Evidence Requirements

Every PASS criterion must specify exactly what evidence proves it. Use this 3-part checklist to verify each criterion is concrete enough for forge-execute to evaluate:

1. **Expected value or state** — what the real system should produce (e.g., "response includes `token` field with 20+ chars")
2. **Evidence type** — how the proof is captured (screenshot, API response JSON, console log, CLI stdout, build output)
3. **What to look for in the evidence** — the specific content to verify (e.g., "response JSON has `token` key whose string value is 20+ chars", not just "200 OK")

**Risk classification** drives priority:

| Risk | Includes | Validation priority |
|------|----------|---------------------|
| **HIGH** | Auth, payment, data mutation, any security boundary | Must validate before ship; no exceptions |
| **MEDIUM** | User-facing workflows, API contracts, core functionality | Should validate; defer only with explicit justification |
| **LOW** | Secondary features, cosmetic UI, infrequently-used flows | Sample-validate; accept gaps for tight deadlines |

HIGH journeys get full evidence; LOW journeys can use lighter evidence (one screenshot instead of five) as long as the PASS criterion is still falsifiable.

**Reject as vague:**
- "Login works" → Replace with "POST /login with valid creds returns 200 + JWT in `token` field"
- "Page loads" → Replace with "GET / returns 200, screenshot shows <h1> with text 'Welcome'"
- "API is fast" → Replace with "Response time < 500ms per p95 (capture 10 samples)"
