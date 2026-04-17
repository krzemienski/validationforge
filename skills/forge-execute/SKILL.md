---
name: forge-execute
description: "Use after a validation plan exists to actually run the journeys and, when they fail, autonomously try to fix them. Runs each journey against the real system, captures evidence into a fresh attempt directory, analyzes failures, applies a fix, rebuilds, and re-runs — up to 3 strikes before giving up on that journey. Preserves the full attempt history (e2e-evidence/forge-attempt-N/) so you can see exactly what changed between tries. Reach for it on phrases like 'run validation', 'execute the plan', 'validate now', 'fix the failures and retry', or after forge-plan produced a plan."
triggers:
  - "run validation"
  - "execute validation"
  - "validate now"
  - "run the plan"
  - "execute journeys"
  - "fix and retry"
  - "autonomous validation loop"
context_priority: reference
---

# forge-execute

Autonomous validation execution loop. Runs journeys, captures fresh evidence per attempt, fixes failures, rebuilds, and re-validates until all pass or the 3-strike limit is reached.

## When to use

Reach for this skill after `forge-plan` (or `create-validation-plan`) has produced `e2e-evidence/validation-plan.md`. If no plan exists, run planning first — executing without a plan means you have no PASS criteria to check evidence against, and the fix loop has no target to converge on.

## Modes

| Mode | When to use | What changes |
|------|-------------|--------------|
| `full` | Default — running validation before a release or during active development | All journeys, full evidence capture, fix loop enabled |
| `quick` | Pre-commit smoke test, "does the build basically work" | Only P0-priority journeys, minimal evidence (one screenshot, one response body per journey), fix loop enabled |
| `ci` | Running inside CI/CD | All journeys, full evidence, **fix loop disabled** — fail fast with exit codes so a human can intervene. Auto-fixes in CI are risky because they can mutate the branch under test |
| `targeted` | Debugging one flow, or after a partial fix | Only named journeys run, fix loop enabled |

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

For each FAIL verdict, work this order — skipping steps produces fixes that don't converge:

1. **Read the actual evidence** from `forge-attempt-N/{journey}/`. Don't guess from the verdict line; open screenshots, logs, response bodies. Quote what you see.
2. **Compare to PASS criteria** from the plan. Which criterion failed, and what was the actual vs expected value?
3. **Classify the cause:**
   - **code bug** — logic, typo, missing handler; needs a source-code fix
   - **config issue** — env var, feature flag, DB URL; fix in config not code
   - **environment** — dev server died, DB unreachable, MCP disconnected; fix the environment, don't "fix" by rebuilding
   - **flaky** — non-deterministic; if the exact same steps pass on re-run without a code change, suspect timing/race
4. **Decide fixable or BLOCKED:**
   - Fixable: you can see the cause and the fix is within scope. Proceed to Phase 4.
   - BLOCKED: cause is external (third-party API down, missing credentials, unclear requirement). Mark the journey BLOCKED, record why, move on; no strikes consumed.

**Example:** Evidence shows 200 OK from POST /signup but frontend never navigates to /welcome. Classify: code bug (frontend navigation logic). Fixable: yes (navigate to signup component). Proceed to Phase 4.

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

**The rebuild rule (non-negotiable):**

- Always rebuild after a fix, before re-executing. A stale build re-runs the old code and makes the strike count lie.
- If rebuild fails (compile error introduced by the fix), that's the new failure — strike increments, fix is the compile error.
- Skipping rebuild invalidates the attempt. Treat it as a null strike and redo with rebuild.

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
