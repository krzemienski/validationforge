---
name: forge-plan
description: Generate a validation plan with journey discovery, PASS criteria, and evidence requirements. Supports quick, standard, and consensus planning modes.
---

# forge-plan

Generate a validation plan with journey discovery, PASS criteria, and evidence requirements. Supports quick, standard, and consensus planning modes.

## Trigger

- "plan validation", "create validation plan", "what should I validate"
- Before running `/validate` on a new project

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

Three independent perspectives analyze the project, then merge:

| Perspective | Focus |
|-------------|-------|
| User Advocate | User-facing flows, UX edge cases, accessibility |
| Security Analyst | Auth flows, data validation, injection vectors |
| Quality Engineer | Error handling, edge cases, performance boundaries |

**Protocol:**
1. Each perspective generates journeys independently (parallel agents)
2. Merge: union of all journeys, deduplicate by feature area
3. Conflict resolution: most comprehensive journey wins
4. Coverage check: ensure merged plan covers all perspectives

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

Every PASS criterion must specify exactly what evidence proves it:
- **Screenshot**: What must be visible in the screenshot
- **API response**: Expected status code, body structure, specific fields
- **Console output**: Expected log lines or absence of errors
- **Build output**: Specific success indicators

Never accept "it works" as a PASS criterion.
