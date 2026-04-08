---
name: error-recovery
description: >
  Structured 3-strike error recovery during validation. When validation fails,
  diagnoses root cause, applies fix, and re-validates. Use when any validation
  step fails, builds break, runtime crashes, or network/auth/database errors occur.
---

# Error Recovery Protocol

## Scope

This skill handles: diagnosing validation failures, structured fix attempts, escalation.
Does NOT handle: initial validation planning (use `create-validation-plan`), evidence capture (use `e2e-validate`).

## The 3-Strike Protocol

```
VALIDATION STEP FAILS
        │
        ▼
┌─────────────────────────────────────────┐
│ STRIKE 1: Diagnose and Targeted Fix     │
│  1. Read FULL error output              │
│  2. Identify root cause (file, line)    │
│  3. Apply smallest fix                  │
│  4. Re-validate the SAME step           │
│  PASS → Continue  |  FAIL → Strike 2   │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│ STRIKE 2: Alternative Approach          │
│  1. Different tool/path/config          │
│  2. Search error message in docs        │
│  3. Apply alternative fix               │
│  4. Re-validate the SAME step           │
│  PASS → Continue  |  FAIL → Strike 3   │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│ STRIKE 3: Broader Rethink              │
│  1. Question assumptions about system   │
│  2. Re-read related code paths          │
│  3. Check environment, deps, versions   │
│  4. Consider if plan needs updating     │
│  5. Apply broader fix, re-validate      │
│  PASS → Continue  |  FAIL → Escalate   │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│ ESCALATE: Report to user with:         │
│  - Full error output                    │
│  - All 3 attempts and results           │
│  - Root cause hypothesis                │
│  - Suggested next steps                 │
└─────────────────────────────────────────┘
```

## Error Classification

| Error Type | Symptoms | First Action |
|---|---|---|
| Build failure | Compilation/type errors | Fix source at file:line, rebuild |
| Runtime crash | Uncaught exception | Read stack trace, fix throwing path |
| Network timeout | ETIMEDOUT, ECONNREFUSED | Verify server running |
| Auth failure | 401, 403 | Check credentials, token expiry |
| Database error | Connection refused | Verify DB running, check migrations |
| File not found | ENOENT, 404 | Check file path, verify build output |
| Port in use | EADDRINUSE | Find and kill process on port |
| Dependency missing | Module not found | Install missing dependency |
| Config error | Missing env vars | Check config files, verify env |

For platform-specific recovery commands, see `references/recovery-commands.md`.
For error log and escalation templates, see `references/error-log-template.md`.

## Rules

1. **NEVER repeat the exact same failing action** without changing something first
2. **NEVER add a mock or stub** to work around the error
3. **NEVER skip a failing validation step** — fix it or escalate
4. **ALWAYS fix the real cause**, not the surface symptom
5. **ALWAYS re-validate after every fix** — run the exact same step
6. **ALWAYS log what you tried** in `e2e-evidence/error-log.md`
7. **ALWAYS read the FULL error output** — root cause is often in the middle

## Security Policy

This skill modifies code only to fix validation failures. It never introduces new
functionality, never disables security checks, and never works around auth/permission errors
by lowering security — it fixes the auth configuration instead.

## Related Skills

- `preflight` — Prevent many errors by verifying prerequisites first
- `create-validation-plan` — The plan whose steps this skill helps recover
- `e2e-validate` — The execution loop that invokes this recovery protocol
- `gate-validation-discipline` — Ensures fixes are verified with evidence
