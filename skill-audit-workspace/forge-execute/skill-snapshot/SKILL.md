---
name: forge-execute
description: "Execute validation journeys with autonomous fix loop: run, capture evidence, analyze, rebuild, re-execute (max 3 strikes). Use after plan exists; maintains attempt history in isolated directories."
context_priority: reference
---

# forge-execute

Autonomous validation execution loop. Runs journeys, captures fresh evidence per attempt, fixes failures, rebuilds, and re-validates until all pass or the 3-strike limit is reached.

## Trigger

- "run validation", "execute validation", "validate now"
- After a validation plan exists (run forge-plan first if needed)

## Modes

| Mode | Use Case | Behavior |
|------|----------|----------|
| full | Complete validation | All journeys, full evidence capture |
| quick | Smoke test | Critical journeys only, minimal evidence |
| ci | CI/CD pipeline | Non-interactive, exit codes, no fix loop |
| targeted | Specific area | Named journeys only |

## The Forge Loop

```
PLAN → PREFLIGHT → EXECUTE → ANALYZE → FIX → REBUILD → RE-EXECUTE
                                          ↑                   ↓
                                          └───────────────────┘ (max 3 strikes)
```

### Phase 0: Load Plan

Read `e2e-evidence/validation-plan.md`. If absent, run forge-plan first.
Update forge-state.json: `status → running`, record `run_id`.

### Phase 1: Preflight

- [ ] Project builds without errors
- [ ] Required services are running (dev server, database, etc.)
- [ ] MCP servers are available (Playwright, Xcode tools, etc.)
- [ ] Evidence directory initialized for attempt 1

**If preflight fails: STOP. Fix the build/environment first.**
Update forge-state.json: `phase → preflight_failed` on failure.

### Phase 2: Execute Journeys

For each journey, at attempt N:
1. Create evidence directory: `e2e-evidence/forge-attempt-{N}/{journey-slug}/`
2. Execute each step against the real system
3. Capture evidence (screenshots, API responses) into that directory
4. Compare against PASS criteria → record verdict

Update forge-state.json after each journey verdict. See `references/forge-state-schema.md` for schema.

```
e2e-evidence/
  forge-attempt-1/
    {journey-slug}/
      step-01-{description}.png
      step-02-{description}.json
      evidence-inventory.txt
  forge-attempt-2/
    {journey-slug}/
      ...
```

### Phase 3: Analyze Failures

For each FAIL verdict:
1. Use sequential thinking to trace root cause
2. Classify: code bug, config issue, environment, or flaky
3. Determine if auto-fixable (if not, mark BLOCKED)

### Phase 4: Fix Loop (max 3 strikes per journey)

```
strike = 0
while journey.verdict == FAIL and strike < 3:
    fix(root_cause)             # modify real application code
    rebuild()                   # MUST compile before re-validating
    N++                         # increment attempt counter
    re_execute(journey, N)      # fresh evidence in forge-attempt-{N}/
    strike++
    update_forge_state(strike)  # persist strike count and attempt result
if journey.verdict == FAIL:
    mark_as_persistent_fail(journey)
    update_forge_state(status="aborted")
```

**Rebuild rule:** Never re-validate after a fix without rebuilding first. A clean build is a prerequisite for re-execution.

### Phase 5: Verdict

Generate unified report at `e2e-evidence/report.md`:

```markdown
# Forge Validation Report

## Summary
- Total Journeys: N
- PASS: X  FAIL: Y  Fix Attempts: Z

## Journey Results
| Journey | Verdict | Strikes | Evidence Path |
|---------|---------|---------|---------------|
| login-flow | PASS | 1 | forge-attempt-2/login-flow/ |
| settings | FAIL | 3 | forge-attempt-3/settings/ |

## Detailed Results
### login-flow — PASS
- step-01: Screenshot shows login form with email/password fields
- step-02: API response 200 with valid JWT in body
```

Update forge-state.json: `status → completed` (or `aborted` if any persistent failures).

## State Management

State persists to `.validationforge/forge-state.json`. Update after:
- Every phase transition (0 → 1 → 2 → 3 → 4 → 5)
- Every strike increment
- Every attempt conclusion

See `references/forge-state-schema.md` for complete schema, field definitions, and lifecycle transitions.

## CI Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All journeys PASS |
| 1 | One or more journeys FAIL |
| 2 | Preflight failure |
| 3 | Plan not found |
| 4 | Internal error |
