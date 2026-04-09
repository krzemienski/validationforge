---
name: preflight
description: >
  Pre-execution checklist before starting any validation. Ensures prerequisites
  are met: servers running, databases seeded, tools available. Auto-fixes common
  failures. Saves preflight report to e2e-evidence/.
context_priority: critical
---

# Preflight Checklist

## Scope

This skill handles: verifying prerequisites, auto-fixing common failures, producing preflight reports.
Does NOT handle: validation execution (use `e2e-validate`), validation planning (use `create-validation-plan`).

## Purpose

Catching missing dependencies, dead servers, and unseeded databases upfront saves
10-30 minutes of debugging misleading failures mid-validation. A failed preflight
is cheaper than a failed validation.

## How It Works

1. **Detect platform** — scan project for indicator files (xcodeproj, package.json, Cargo.toml, etc.)
2. **Run platform checklist** — execute each check command, record PASS/FAIL/WARN
3. **Auto-fix failures** — attempt one auto-fix per failed check, re-check after
4. **Produce report** — save structured report to `e2e-evidence/preflight-report.md`
5. **Verdict** — CLEAR (proceed), BLOCKED (manual fix needed), or WARN (proceed with caution)

For the full platform-specific checklists (Web, API, iOS, CLI, Fullstack),
see `references/platform-checklists.md`.

For the auto-fix action table and platform detection script,
see `references/auto-fix-actions.md`.

## Preflight Report Format

```markdown
PREFLIGHT CHECK: [PROJECT_NAME]
Platform: [DETECTED]
Time: [YYYY-MM-DD HH:MM]
Status: CLEAR | BLOCKED

---
## Results
[PASS] Node.js v20.11.0
[PASS] Dependencies installed
[FAIL] Database: connection refused
       Auto-fix: ran `brew services start postgresql@16` — NOW RUNNING
[PASS] Database: connection OK (re-checked)
[WARN] .env.local missing STRIPE_KEY — non-critical

---
## Summary
- Checks run: 10 | Passed: 9 | Auto-fixed: 1 | Warnings: 1 | Blocked: 0
## Status: CLEAR
```

## Severity Levels

| Severity | Meaning | Action |
|----------|---------|--------|
| CRITICAL | Validation cannot proceed | Must fix (auto-fix or manual) |
| HIGH | Validation will be degraded | Should fix before proceeding |
| MEDIUM | Some checks may be limited | Proceed with awareness |
| LOW | Nice to have | Proceed normally |

## Rules

1. **ALWAYS run preflight** before any validation session
2. **ALWAYS attempt auto-fix once** before reporting BLOCKED
3. **NEVER auto-fix** by installing major tools (Xcode, Docker) — report BLOCKED
4. **ALWAYS re-check** after auto-fix to confirm resolution
5. **ALWAYS save** the preflight report to `e2e-evidence/preflight-report.md`
6. **Check bottom-up** for fullstack: Database -> API -> Frontend.

## Security Policy

This skill runs diagnostic commands and may start services (database, dev server).
It never modifies application code, never changes security configurations, and
never installs major software without user consent.

## Related Skills

- `create-validation-plan` — Run preflight before creating the plan
- `baseline-quality-assessment` — Run preflight before baseline capture
- `e2e-validate` — Preflight is the first step of validation execution
- `error-recovery` — Many preflight catches prevent confusing mid-validation failures
- `condition-based-waiting` — Used by preflight to wait for services after auto-fix
