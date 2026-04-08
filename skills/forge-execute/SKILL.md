---
name: forge-execute
description: Autonomous validation execution loop. Runs validation journeys against the real system, captures evidence, and fixes failures with re-validation.
---

# forge-execute

Autonomous validation execution loop. Runs validation journeys against the real system, captures evidence, and fixes failures with re-validation.

## Trigger

- "run validation", "execute validation", "validate now"
- After a validation plan exists

## Modes

| Mode | Use Case | Behavior |
|------|----------|----------|
| full | Complete validation | All journeys, full evidence capture |
| quick | Smoke test | Critical journeys only, minimal evidence |
| ci | CI/CD pipeline | Non-interactive, exit codes, no fix loop |
| targeted | Specific area | Named journeys only |

## The Forge Loop

```
PLAN → PREFLIGHT → EXECUTE → ANALYZE → FIX → RE-EXECUTE
                                          ↑        ↓
                                          └────────┘ (max 3 attempts)
```

### Phase 0: Load Plan

Read validation plan from `e2e-evidence/validation-plan.md`. If none exists, run forge-plan first.

### Phase 1: Preflight

Before any validation:
- [ ] Project builds without errors
- [ ] Required services are running (dev server, database, etc.)
- [ ] MCP servers are available (Playwright, Xcode tools, etc.)
- [ ] Evidence directory is clean (no stale evidence from previous runs)

**If preflight fails: STOP. Fix the build/environment first.**

### Phase 2: Execute Journeys

For each journey in the plan:
1. Execute each step against the real system
2. Capture evidence per step requirements
3. Compare evidence against PASS criteria
4. Record verdict: PASS or FAIL with cited evidence

Evidence goes to `e2e-evidence/{journey-slug}/`:
```
e2e-evidence/
  {journey-slug}/
    step-01-{description}.png
    step-02-{description}.json
    evidence-inventory.txt
```

### Phase 3: Analyze Failures

For each FAIL verdict:
1. Use sequential thinking to trace root cause
2. Classify: code bug, config issue, environment problem, or flaky behavior
3. Determine if auto-fixable

### Phase 4: Fix Loop (max 3 attempts per journey)

```
attempt = 0
while journey.verdict == FAIL and attempt < 3:
    fix(root_cause)
    rebuild()
    re_execute(journey)
    attempt++
if journey.verdict == FAIL:
    mark_as_unfixable(journey)
```

### Phase 5: Verdict

Generate unified report at `e2e-evidence/report.md`:
```markdown
# Validation Report

## Summary
- Total Journeys: N
- PASS: X
- FAIL: Y
- Fix Attempts: Z

## Journey Results
| Journey | Verdict | Evidence | Fix Attempts |
|---------|---------|----------|-------------|
| J1: Login Flow | PASS | 4 screenshots, 2 API responses | 0 |
| J2: Settings | FAIL | 3 screenshots | 3 (max reached) |

## Detailed Results
### J1: Login Flow — PASS
**Evidence:**
- step-01: Screenshot shows login form with email/password fields
- step-02: API response 200 with valid JWT token in body
...
```

## State Management

Execution state persists to `.validationforge/forge-state.json`:

```json
{
  "run_id": "uuid",
  "started_at": "ISO-8601",
  "phase": "execute",
  "journeys": {
    "login-flow": { "verdict": "PASS", "attempts": 0 },
    "settings-page": { "verdict": "IN_PROGRESS", "attempts": 1 }
  },
  "evidence_count": 12
}
```

If interrupted, resume from the last incomplete journey.

## CI Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All journeys PASS |
| 1 | One or more journeys FAIL |
| 2 | Preflight failure |
| 3 | Plan not found |
| 4 | Internal error |
