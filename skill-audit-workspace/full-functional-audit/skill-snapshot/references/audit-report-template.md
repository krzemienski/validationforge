# Audit Report Template

Copy this template to `e2e-evidence/audit-report.md` and fill in each section.

```markdown
# Functional Audit Report

**Project:** [Name]
**Platform:** [ios | web | api | cli | fullstack]
**Date:** [YYYY-MM-DD HH:MM]
**Auditor:** ValidationForge
**Scope:** [Full audit | Targeted audit of X features]

## Executive Summary

[1 paragraph: total features audited, pass/fail counts, critical issues count,
overall assessment. Be direct — "The application is in [good/fair/poor/broken]
state with N critical issues requiring immediate attention."]

## Findings Summary

| Severity | Count |
|----------|-------|
| CRITICAL | N |
| HIGH | N |
| MEDIUM | N |
| LOW | N |
| INFO | N |
| **Total** | **N** |

| Status | Count |
|--------|-------|
| PASS | N |
| FAIL | N |
| UNKNOWN | N |
| **Total** | **N** |

## Findings by Feature

### Feature 1: [Name]
- **Status:** PASS | FAIL | UNKNOWN
- **Severity:** [If FAIL: CRITICAL / HIGH / MEDIUM / LOW]
- **Evidence:** `e2e-evidence/audit/feature-01-[name].[ext]`
- **Expected:** [What should happen]
- **Observed:** [What actually happened — be specific]
- **Recommendation:** [If FAIL: what to fix. If PASS: none]

### Feature 2: [Name]
...

## Priority Recommendations

Ordered by impact (CRITICAL first, then HIGH, then by breadth of user impact):

1. **[CRITICAL]** [Description] — Affects [scope]. Fix by [specific action].
2. **[HIGH]** [Description] — Affects [scope]. Fix by [specific action].
3. **[MEDIUM]** [Description] — Affects [scope]. Fix by [specific action].

## Evidence Index

| # | File | Description |
|---|------|-------------|
| 1 | `e2e-evidence/audit/feature-01-[name].png` | [What it shows] |
| 2 | `e2e-evidence/audit/feature-02-[name].json` | [What it contains] |
```

## Feature Inventory Template

Use this to map features before exercising them:

```markdown
## Feature Inventory

| # | Feature | Type | Expected Behavior | Status |
|---|---------|------|-------------------|--------|
| 1 | Homepage | Page | Hero section, navigation, feature cards | PENDING |
| 2 | User Registration | Form + API | Email/password form, creates account | PENDING |
| 3 | Login | API + Redirect | Authenticates, redirects to dashboard | PENDING |
| 4 | GET /api/users | Endpoint | Returns paginated user list | PENDING |
```

## Evidence Naming Convention

```
e2e-evidence/audit/
  feature-01-homepage.png
  feature-02-registration-form.png
  feature-02-registration-submit.json
  feature-03-login-success.png
  feature-03-login-error.png
  feature-06-api-users-response.json
```

Rules:
- Prefix with feature number for sorting
- Use descriptive suffixes (-form, -submit, -success, -error)
- Screenshots: `.png`. API responses: `.json`. CLI output: `.txt`. Logs: `.log`
