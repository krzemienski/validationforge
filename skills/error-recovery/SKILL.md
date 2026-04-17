---
name: error-recovery
description: "Use whenever a validation step fails and you're about to try again — this skill enforces a structured 3-strike protocol instead of unguided retrying. Strike 1: diagnose and apply the smallest targeted fix, re-run the same step. Strike 2: try an alternative approach (different tool, different config, docs search). Strike 3: rethink assumptions about the system, check environment and dependencies. After 3 strikes without success, escalate to the user with full error history and a root-cause hypothesis. Covers build failures, runtime crashes, network timeouts, auth errors, DB issues, missing deps. Reach for it on phrases like 'this keeps failing', 'try again', 'error recovery', 'validation failed', 'fix and retry', or whenever you catch yourself about to repeat an action that just failed."
triggers:
  - "error recovery protocol"
  - "fix validation failures"
  - "3 strike protocol"
  - "recover from failure"
  - "diagnose root cause"
  - "this keeps failing"
  - "try again"
  - "validation failed how do i fix"
context_priority: critical
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

1. **Don't repeat the same failing action unchanged.** If you didn't change anything, the result won't change either — you're just burning time. Every retry needs at least one concrete difference (different input, different tool, different hypothesis).
2. **Don't mock or stub around the error.** The error is telling you something about the real system. Mocking hides the signal; next person to hit this gets the same bug without the warning.
3. **Don't skip a failing step.** Either fix it, or escalate so the user knows it's unfixed. Silently advancing past a failure means the final verdict is a lie.
4. **Fix the real cause, not the surface symptom.** A 401 isn't fixed by "retry with new session" if the actual issue is expired refresh tokens.
5. **Re-validate after every fix by re-running the exact same step.** A fix you don't re-verify is a guess.
6. **Log every attempt to `e2e-evidence/error-log.md`.** Three attempts with no log means the next person starts from scratch. With a log they learn from what you tried.
7. **Read the FULL error output, not just the first line.** Root causes often live in the middle of stack traces — the top line is usually the symptom, the middle is often the cause.

## Security Policy

This skill modifies code only to fix validation failures. It never introduces new
functionality, never disables security checks, and never works around auth/permission errors
by lowering security — it fixes the auth configuration instead.

## Related Skills

- `preflight` — Prevent many errors by verifying prerequisites first
- `create-validation-plan` — The plan whose steps this skill helps recover
- `e2e-validate` — The execution loop that invokes this recovery protocol
- `gate-validation-discipline` — Ensures fixes are verified with evidence
