---
name: e2e-testing
description: "Use when designing end-to-end validation strategy — deciding how to structure journeys, how to name evidence, how to diagnose flaky flows. This is a strategy/patterns skill (the HOW-TO-THINK layer), separate from execution skills like e2e-validate / playwright-validation / ios-validation which actually RUN the validation. Covers: one goal per journey, precondition→action→assertion structure, step-NN evidence naming, inventory files, flaky-flow diagnosis (3-run delta technique, root-cause fix patterns). Reach for it on phrases like 'how do I structure e2e tests', 'journey design patterns', 'why is this test flaky', 'e2e strategy', or when planning the shape of E2E work before executing it."
triggers:
  - "e2e testing patterns"
  - "end to end patterns"
  - "journey design"
  - "flaky flow"
  - "e2e strategy"
  - "how to structure e2e"
  - "why is this flaky"
  - "journey naming"
context_priority: standard
---

# E2E Testing Patterns

Patterns and strategies for designing end-to-end validation journeys, managing evidence artifacts, and handling flaky flows. This is a strategy skill — it tells you HOW to think about E2E validation, not how to execute it (use `e2e-validate`, `playwright-validation`, or `ios-validation` for execution).

## When to Use

- When designing validation journeys for `create-validation-plan`
- When a validation flow is intermittently failing (flaky)
- When organizing evidence across multiple journeys
- When deciding what to validate end-to-end vs. at other layers

## Journey Design Principles

### 1. One Journey = One User Goal

A journey maps to a single user goal, not a single page or component.

**Good journeys:**
- "User signs up and reaches dashboard"
- "User creates a post and sees it in the feed"
- "User changes password and can log in with new password"

**Bad journeys:**
- "Test the login page" (too narrow — what's the user goal?)
- "Test everything" (too broad — no clear PASS/FAIL criteria)
- "Test the API" (not a user goal — that's integration validation)

### 2. Journey Structure

Every journey follows this pattern:

```
PRECONDITION → ACTION(s) → ASSERTION(s)
     |              |             |
"Given this    "When the     "Then this
 state..."      user does..."  should be true"
```

Example:
```markdown
## Journey: New User Signup

**Precondition:** No existing account for test@example.com
**Actions:**
1. Navigate to /signup
2. Fill email, password, name
3. Click "Create Account"
4. Check email for verification (or auto-verify in dev)
5. Navigate to /dashboard

**PASS Criteria:**
1. Dashboard renders with welcome message containing user's name
2. Navigation shows authenticated state (profile avatar, not login button)
3. No console errors during flow
4. All API calls return 2xx
```

### 3. Journey Independence

Each journey MUST be independent — it cannot depend on another journey having run first.

**Good:** Each journey sets up its own preconditions
**Bad:** Journey B assumes Journey A created a user account

### 4. Journey Prioritization

Validate in this order:

| Priority | Type | Example |
|----------|------|---------|
| P0 | Revenue/auth critical | Login, checkout, payment |
| P1 | Core user value | Primary feature, data CRUD |
| P2 | Secondary features | Settings, preferences, search |
| P3 | Edge cases | Error recovery, empty states |

## Evidence Management

### Directory Structure

```
e2e-evidence/
  {journey-slug}/                    # One directory per journey
    step-01-{description}.png        # Sequential evidence files
    step-02-{description}.png
    step-03-{description}.json       # API responses
    step-04-{description}.txt        # Console/log output
    evidence-inventory.txt           # Auto-generated file list
  report.md                          # Final verdict report
```

### Naming Convention

```
step-{NN}-{action}-{result}.{ext}
```

Examples:
- `step-01-navigate-to-login.png`
- `step-02-fill-credentials.png`
- `step-03-submit-form.png`
- `step-04-dashboard-loaded.png`
- `step-05-console-errors.txt`
- `step-06-network-requests.txt`

### Evidence Inventory

After capturing all evidence for a journey:

```bash
find "e2e-evidence/$JOURNEY" -type f | sort | while read f; do
  echo "$(wc -c < "$f" | tr -d ' ') $f"
done | tee "e2e-evidence/$JOURNEY/evidence-inventory.txt"
```

The `verdict-writer` agent uses this inventory to find all evidence files.

## Flaky Flow Handling

A flow is "flaky" when it sometimes PASSes and sometimes FAILs without code changes.

### Common Causes

| Cause | Symptoms | Fix |
|-------|----------|-----|
| Race condition | Passes on fast machines, fails on slow | Add explicit waits for specific conditions |
| Stale data | Passes first time, fails on re-run | Reset state before each journey |
| Network timing | Intermittent timeout | Increase timeout, add retry with evidence |
| Animation interference | Click hits wrong element | Wait for animation to complete |
| Shared state | Journey A pollutes Journey B | Ensure journey independence |

### Diagnosis Protocol

1. **Run 3 times** — if it fails at least once, it's flaky
2. **Capture evidence on every run** — compare passing vs failing evidence
3. **Identify the delta** — what's different between PASS and FAIL runs?
4. **Fix the root cause** — don't just retry

### Quarantine Pattern

If a flow is flaky and blocking other work:

1. Document the flakiness in `e2e-evidence/{journey}/FLAKY.md`:
```markdown
# Flaky Flow: {journey name}

**Failure rate:** ~1 in 3 runs
**First observed:** YYYY-MM-DD
**Symptom:** Step 4 screenshot shows loading spinner instead of dashboard
**Suspected cause:** API response takes >3s under load
**Workaround:** Added 5s wait before screenshot
**Root cause fix needed:** Optimize /api/dashboard endpoint
```

2. Mark the journey as CONDITIONAL in the verdict report
3. Track as a separate remediation item

## Artifact Management

### What to Keep

| Artifact | When to Capture | Retention |
|----------|----------------|-----------|
| Screenshots | Every state transition | Keep all |
| DOM snapshots | Initial load + after interactions | Keep all |
| Console logs | Always | Keep all |
| Network logs | When debugging API integration | Keep for FAIL journeys |
| Video recordings | Complex multi-step flows | Keep for FAIL journeys |
| Performance traces | When validating performance | Keep most recent |

### Storage Optimization

```bash
# Compress evidence directory after validation
tar -czf "e2e-evidence-$(date +%Y%m%d).tar.gz" e2e-evidence/

# Clean up for next run (keep archive)
rm -rf e2e-evidence/*/
```

## Integration with ValidationForge

- Journey definitions feed into `create-validation-plan` skill
- Journey execution uses platform-specific skills (`playwright-validation`, `ios-validation`, etc.)
- Evidence structure is consumed by the `verdict-writer` agent
- Flaky flow documentation prevents false FAILs in verdict reports
- This skill provides the strategic framework; execution skills provide the tactics
