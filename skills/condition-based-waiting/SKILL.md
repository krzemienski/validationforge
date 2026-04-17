---
name: condition-based-waiting
description: "Wait for conditions, not time: HTTP health polls, port availability, file existence, process readiness, browser content, iOS simulator, DB ready, log patterns. Every wait must timeout."
triggers:
  - "wait for server"
  - "async operation"
  - "service readiness"
  - "health check polling"
  - "timeout handling"
context_priority: standard
---

# Condition-Based Waiting

## Scope

This skill handles: waiting for async operations (server start, DB ready, build complete, simulator boot).
Does NOT handle: what to validate (use `functional-validation`), fixing failures (use `error-recovery`).

## The Principle

`sleep 5` is NEVER acceptable. Wait for WHAT, not for WHEN.

```bash
# WRONG: Hoping 10 seconds is enough
sleep 10
curl http://localhost:3000/health

# RIGHT: Waiting until the server is actually ready
until curl -sf http://localhost:3000/health; do sleep 1; done
curl http://localhost:3000/api/data
```

## 8 Strategies (Summary)

| # | Strategy | When to Use | Timeout |
|---|----------|------------|---------|
| 1 | HTTP Health Poll | Server with health endpoint | 30s |
| 2 | Port Availability | TCP service without health endpoint | 30s |
| 3 | File Existence | Build artifacts, generated output | 60s |
| 4 | Process Ready | Background services, daemons | 30s |
| 5 | Browser Content | SPA rendering, AJAX updates | 15s |
| 6 | iOS Simulator Boot | iOS validation workflows | 90s |
| 7 | Database Ready | Docker databases, migrations | 30s |
| 8 | Log Pattern | Services that log readiness messages | 60s |

For the complete implementation of all 8 strategies with copy-paste bash functions,
see `references/waiting-strategies.md`.

## Timeout Rules

Every wait MUST include a timeout. Infinite waits are a critical defect.

```bash
TIMEOUT=30; ELAPSED=0
until CONDITION || [ $ELAPSED -ge $TIMEOUT ]; do
  sleep 1; ELAPSED=$((ELAPSED + 1))
done
[ $ELAPSED -ge $TIMEOUT ] && echo "TIMEOUT" && exit 1
```

For recommended timeouts by resource type, anti-patterns table, and platform-specific
wait patterns, see `references/timeout-patterns.md`.

## Rules

1. **NEVER use bare `sleep N`** — always wait for a condition
2. **ALWAYS include a timeout** — infinite waits are critical defects
3. **ALWAYS capture diagnostic state on timeout** — `ps`, `lsof`, `tail` the log
4. **Prefer health checks over port checks** — port open does not mean ready
5. **Chain waits bottom-up** for fullstack: DB -> API -> Frontend
6. **Prefer text/element waits** over time-based in browser automation

## Security Policy

This skill executes diagnostic commands (curl, nc, pgrep, psql) to check readiness.
It never modifies application code, never changes configurations, and never
installs software.

## Related Skills

- `preflight` — Uses condition-based waiting to verify prerequisites
- `e2e-validate` — Orchestrates waits as part of the validation lifecycle
- `error-recovery` — Waits for services to recover after fix attempts
- `functional-validation` — Depends on ready services; this skill ensures readiness
