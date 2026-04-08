---
description: "Run validation journeys against the real system with autonomous fix loop"
allowed-tools: "Read, Write, Edit, Bash, Glob, Grep, Agent"
---

# /forge-execute

Execute validation plan against the real system.

## Pipeline

```
PREFLIGHT → EXECUTE → ANALYZE → FIX → RE-EXECUTE (max 3 attempts)
```

## Modes

| Mode | Flag | Behavior |
|------|------|----------|
| Full | (default) | All journeys, full evidence, fix loop |
| Quick | `--quick` | Critical journeys only |
| CI | `--ci` | Non-interactive, exit codes |
| Targeted | `--journey <name>` | Specific journey only |

## Usage

```
/forge-execute                  # Full validation run
/forge-execute --quick          # Smoke test
/forge-execute --ci             # CI/CD mode
/forge-execute --journey login  # Single journey
```

Output: `e2e-evidence/report.md`

Invoke the `forge-execute` skill to execute.
