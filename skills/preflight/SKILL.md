---
name: preflight
description: "Run BEFORE any validation session to catch missing dependencies, dead servers, unseeded databases, and stale builds — the failures that otherwise eat 10-30 minutes of mid-validation debugging. Auto-attempts one fix per failed check (start the DB, install dependencies, run migrations) and re-checks. Produces a CLEAR / BLOCKED / WARN verdict and a structured report at e2e-evidence/preflight-report.md. Reach for it whenever someone says 'check before validating', 'why is the dev server down', 'pre-validation check', 'environment health', before /validate or /forge-execute, or when a previous validation FAILed for environmental reasons (server crashed, DB empty, missing env var)."
triggers:
  - "preflight check"
  - "pre-validation check"
  - "environment health"
  - "check dependencies"
  - "before validation"
  - "is everything running"
  - "validate environment"
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

1. **Run preflight before any validation session.** A failed preflight costs seconds; a mid-validation failure for the same reason costs 10-30 minutes of misread errors.
2. **Try auto-fix once, then stop.** Auto-fix is for the well-known "service not started" class of problem (start the DB, run migrations, install deps). Two attempts means something isn't actually self-healing — escalate to BLOCKED and let a human diagnose.
3. **Don't auto-fix by installing major tools** (Xcode, Docker, language runtimes). Those are intentional decisions the user should make, not silent side effects.
4. **Re-check after every auto-fix.** Auto-fix without re-check risks reporting CLEAR when the fix didn't actually work.
5. **Save the report to `e2e-evidence/preflight-report.md`.** Later validation commands read it to know the starting state; skipping this breaks the chain.
6. **Check bottom-up for fullstack**: Database → API → Frontend. If the DB is down, starting the API first wastes time because every API check will fail on DB connection.

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
