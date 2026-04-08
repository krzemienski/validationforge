# Workflow: Fix and Revalidate

**Objective:** Fix validation failures using a structured 3-strike escalation protocol, then re-validate through the same pipeline to confirm the fix.

## Prerequisites

- Execution results with at least one FAIL verdict
- Access to source code for modifications
- System still running or restartable

## The Iron Rule of Fixing

Fix the REAL SYSTEM. Never:
- Add a mock to make validation pass
- Modify evidence capture to hide the failure
- Weaken PASS criteria to match broken behavior
- Add a test harness that works around the bug

## Process

### Step 1: Triage Failures

Read all FAIL verdicts from the execution phase. Classify each:

| Category | Description | Example |
|----------|------------|---------|
| Build | System fails to compile/start | Missing dependency, syntax error |
| Data | Wrong data displayed or returned | Empty list when items exist, wrong count |
| Navigation | Can't reach the expected state | Broken link, missing route, crash on tap |
| Logic | Incorrect behavior | Wrong calculation, missing validation |
| Visual | UI doesn't match expectations | Missing element, wrong layout, broken style |
| Integration | Layers don't communicate | API returns data but UI shows empty |

### Step 2: Prioritize Fix Order

Fix in dependency order (bottom-up):
1. Build failures (nothing else works if it won't build)
2. Data layer failures (API/DB issues)
3. Logic failures (business logic)
4. Navigation failures (routing/linking)
5. Integration failures (cross-layer)
6. Visual failures (cosmetic)

### Step 3: Apply 3-Strike Protocol

For EACH failure, you get 3 strikes before escalating:

#### Strike 1: Targeted Fix
- Read the error/evidence carefully
- Identify the most likely root cause
- Apply a minimal, focused fix
- Re-validate ONLY the failed journey

```
Example:
  Failure: "Dashboard shows 0 sessions instead of 41"
  Diagnosis: API query missing WHERE clause for active sessions
  Fix: Add `WHERE status = 'active'` to query
  Re-validate: Run J3 (Dashboard) only
```

#### Strike 2: Alternative Approach
If Strike 1 fix didn't work:
- The root cause was wrong — re-diagnose
- Try a fundamentally different approach
- Look at adjacent code for clues
- Re-validate the failed journey

```
Example:
  Strike 1 failed: WHERE clause was already correct
  Re-diagnosis: Frontend is caching stale data
  Fix: Add cache-busting header to API response
  Re-validate: Run J3 (Dashboard) only
```

#### Strike 3: Broader Investigation
If Strike 2 fix didn't work:
- Step back and examine the entire flow end-to-end
- Add diagnostic logging to trace data through each layer
- Check for environmental issues (wrong database, wrong port, stale process)
- Consider whether the PASS criteria themselves are wrong
- Re-validate the failed journey

```
Example:
  Strike 2 failed: Cache headers correct but data still stale
  Investigation: Dev server is pointing at test database with 0 records
  Fix: Update .env to point at correct database
  Re-validate: Run J3 (Dashboard) only
```

#### After 3 Strikes: Escalate

If 3 attempts fail to fix the issue:
- Mark the journey as **UNRESOLVED**
- Document all 3 attempts with what was tried and why it failed
- Include diagnostic data gathered
- Report to user for manual investigation

```markdown
### J3: Dashboard — UNRESOLVED (3 strikes exhausted)

**Strike 1:** Added WHERE clause to query → Still showing 0
**Strike 2:** Added cache-busting headers → Still showing 0
**Strike 3:** Checked database connection → DB has correct data,
             frontend receives it but state management drops it

**Recommendation:** Investigate React state management in
                    `src/components/Dashboard.tsx` — data arrives
                    via network tab but never renders
```

### Step 4: Re-Validation Rules

When re-validating after a fix:

1. **Re-validate the fixed journey** — confirm the FAIL is now PASS
2. **Re-validate adjacent journeys** — fixes can break related features
3. **Do NOT re-validate all journeys** unless the fix touches shared code (auth, routing, database schema)
4. **Use the same PASS criteria** — never weaken criteria to match a fix
5. **Capture fresh evidence** — overwrite old evidence files with new ones

### Step 5: Track Fix History

Maintain a fix log for the report:

```markdown
## Fix Log

| Journey | Strike | Action | Result |
|---------|--------|--------|--------|
| J3: Dashboard | 1 | Added WHERE clause | FAIL (still 0) |
| J3: Dashboard | 2 | Cache-busting headers | FAIL (still 0) |
| J3: Dashboard | 3 | Fixed DB connection | PASS |
| J5: Export | 1 | Fixed CSV encoding | PASS |
```

### Step 6: Never Repeat the Same Fix

Rules for strike attempts:
- Each strike MUST try something different
- If Strike 1 was "change query X", Strike 2 cannot be "change query X slightly differently"
- Each attempt must be based on NEW evidence or a NEW diagnosis
- Log what was tried so you can prove each strike was distinct

## Output

- Updated verdict blocks (FAIL → PASS or FAIL → UNRESOLVED)
- Fix log with all attempts documented
- Fresh evidence files for re-validated journeys
- List of unresolved issues (if any)

## Next Step

After fix loop completes, feed updated verdicts into `workflows/report.md`.
