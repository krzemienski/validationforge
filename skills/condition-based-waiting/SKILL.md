---
name: condition-based-waiting
description: "Use whenever you need to wait for something asynchronous — a dev server to start, a DB to accept connections, a simulator to boot, a build artifact to appear, a browser to finish rendering. Replaces bare `sleep N` (which is hope, not engineering) with condition-polling patterns that time out cleanly when something is genuinely stuck. Covers 8 strategies: HTTP health polls, port checks, file existence, process ready, browser content, iOS simulator boot, DB ready, log patterns. Reach for it on phrases like 'wait for the server', 'poll until ready', 'why is sleep 5 flaky', 'why do my tests intermittently fail', or anytime timing makes a test unstable."
triggers:
  - "wait for server"
  - "async operation"
  - "service readiness"
  - "health check polling"
  - "timeout handling"
  - "poll until ready"
  - "sleep 5 is flaky"
  - "wait for it to start"
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

1. **Don't use bare `sleep N`.** Sleep-N-and-hope works until the day the dev server takes 6s to start instead of 4s — then tests flake and people blame the test, not the wait. Condition-polling makes the wait as long as it needs to be, and no longer.
2. **Every wait needs a timeout.** Infinite waits hang CI runs for hours. 30s is a good default; adjust per strategy.
3. **On timeout, capture diagnostic state.** If you timeout waiting for the DB, run `ps`, `lsof -i :5432`, and tail the DB log into the evidence directory. The next person debugging this needs the snapshot at the moment it failed, not "it didn't work".
4. **Health checks beat port checks.** A port open ≠ ready. Postgres listens on 5432 during startup before it accepts queries. Curl the `/health` endpoint or run `SELECT 1` — don't trust the socket.
5. **Chain waits bottom-up for fullstack**: DB → API → Frontend. Waiting for the frontend while the API is still starting produces confusing cascade failures.
6. **In browsers, wait for content, not time.** "Wait 2s for the page to render" is a guess; "wait for `<h1>` with text 'Dashboard' to appear" is a fact.

## Security Policy

This skill executes diagnostic commands (curl, nc, pgrep, psql) to check readiness.
It never modifies application code, never changes configurations, and never
installs software.

## Related Skills

- `preflight` — Uses condition-based waiting to verify prerequisites
- `e2e-validate` — Orchestrates waits as part of the validation lifecycle
- `error-recovery` — Waits for services to recover after fix attempts
- `functional-validation` — Depends on ready services; this skill ensures readiness
