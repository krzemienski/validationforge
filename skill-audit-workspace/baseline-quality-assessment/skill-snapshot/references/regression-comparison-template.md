# Regression Comparison Template

Save to `e2e-evidence/regression-check.md` after implementing changes.

## Comparison Template

```markdown
# Regression Check

**Project:** [Name]
**Date:** [YYYY-MM-DD]
**Change:** [Brief description of what was changed]

## Comparison

| ID | Feature | Baseline | Current | Verdict |
|----|---------|----------|---------|---------|
| B1 | Homepage | Working (200, renders) | Working (200, renders) | NO REGRESSION |
| B2 | Login flow | Working (200, token) | Working (200, token) | NO REGRESSION |
| B3 | GET /api/users | Broken (500) | Working (200) | IMPROVED |
| B4 | Dashboard | Working (3 cards) | Broken (blank page) | REGRESSION |

## Regressions Found

### REGRESSION: B4 — Dashboard
**Baseline:** Rendered 3 metric cards with data
**Current:** Blank page, console shows `TypeError: data.map is not a function`
**Evidence:** `e2e-evidence/b4-dashboard-regression.png`
**Severity:** CRITICAL
**Action:** Must fix before proceeding

## Improvements

### IMPROVED: B3 — API /users
**Baseline:** Returned 500 Internal Server Error
**Current:** Returns 200 with array of 5 users
**Evidence:** `e2e-evidence/b3-api-users-fixed.json`

## Summary
- Regressions: [N] ([severity breakdown])
- Improvements: [N]
- Unchanged: [N]
- **Status:** PASS (no regressions) | BLOCKED (fix regressions first)
```

## Verdict Definitions

| Verdict | Meaning | Action |
|---------|---------|--------|
| NO REGRESSION | Same behavior as baseline | None |
| IMPROVED | Was broken/slow, now works/faster | Document improvement |
| REGRESSION | Was working, now broken/degraded | Must fix (CRITICAL/HIGH) or evaluate (MEDIUM) |
| NEW | Feature didn't exist in baseline | Validate independently |
| UNKNOWN | Cannot compare (evidence missing) | Re-capture and compare |

## Comparison Rules

1. Compare identical evidence types — screenshot to screenshot, response to response
2. Use the same capture commands as baseline — consistency ensures valid comparison
3. Record BOTH quantitative (response time, status code) and qualitative (renders correctly, shows data)
4. Any CRITICAL regression blocks completion — no exceptions
5. HIGH regressions should block unless explicitly accepted by user
6. Pre-existing bugs (broken in baseline) are NOT regressions — don't block on them
