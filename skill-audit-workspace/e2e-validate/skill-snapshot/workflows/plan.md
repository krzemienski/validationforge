# Workflow: Plan

**Objective:** Generate a validation plan with specific, measurable PASS criteria for every user journey identified during analysis.

## Prerequisites

- Completed analysis output (`e2e-evidence/analysis.md`)
- Detected platform type

## Process

### Step 1: Read Analysis Output

Load the journey inventory from the analyze phase. Verify:
- Platform is detected
- At least one journey is mapped
- Journeys have priority classifications

If analysis is missing, run `workflows/analyze.md` first.

### Step 2: Define PASS Criteria Per Journey

For EVERY journey, write criteria that are:

- **Specific** — exact values, exact UI elements, exact response fields
- **Observable** — can be verified through evidence (screenshot, response, output)
- **Binary** — unambiguously PASS or FAIL, no "partially works"

| Weak Criteria (REJECT) | Strong Criteria (ACCEPT) |
|------------------------|-------------------------|
| "Login works" | "POST /auth/login with valid credentials returns 200 with `access_token` field" |
| "Dashboard loads" | "Dashboard shows user name in header, displays 3 metric cards with numeric values" |
| "CLI processes files" | "`./tool process *.json` outputs `Processed N files` and exit code 0" |
| "Error handling works" | "Invalid input returns 400 with `{\"error\": \"field X is required\"}`" |

### Step 3: Assign Evidence Type Per Journey

| Platform | Default Evidence | When to Use Alternative |
|----------|-----------------|------------------------|
| iOS | Screenshot + logs | Video for multi-step flows |
| Web | Screenshot + console + network | Video for animations |
| API | Full response body + status code | Logs for async operations |
| CLI | stdout + stderr + exit code | File output for generators |
| Fullstack | Combination per layer | Cross-layer: DB query + API response + UI screenshot |

### Step 4: Estimate Execution Order

Order journeys for execution:
1. Infrastructure/health checks first (can the system start?)
2. Authentication flows (needed for subsequent journeys)
3. P0 critical journeys
4. P1 high journeys
5. P2/P3 if time permits

### Step 5: Generate Plan Document

Write the plan using this structure:

```markdown
## Validation Plan

**Platform:** {platform}
**Total Journeys:** {count}
**Estimated Duration:** {estimate}
**Generated:** {timestamp}

### Prerequisites
- [ ] System builds successfully
- [ ] Required services running (database, API, etc.)
- [ ] Test data available (real data, NOT fixtures)

### Journey Validation Sequence

#### J1: {Journey Name} [P0]
**Entry Point:** {how to start}
**Steps:**
1. {action}
2. {action}
3. {action}

**PASS Criteria:**
- [ ] {specific criterion 1}
- [ ] {specific criterion 2}

**Evidence:** {type} saved to `e2e-evidence/j1-{slug}.{ext}`

---
(repeat for each journey)
```

Save to `e2e-evidence/plan.md`.

### Step 6: Approval Gate

**Interactive mode (default):** Present the plan to the user for review.
- User approves → proceed to execution
- User modifies → update plan and re-present
- User rejects → stop pipeline

**CI mode (`--ci`):** Skip approval, proceed directly to execution.

## Output

- `e2e-evidence/plan.md` — Complete validation plan with PASS criteria
- Execution order for journeys
- Evidence type assignments

## Next Step

After approval, feed the plan into `workflows/execute.md` to run validation.
