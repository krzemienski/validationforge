---
description: "Generate a validation plan with journey discovery and PASS criteria"
allowed-tools: "Read, Write, Bash, Glob, Grep, Agent"
---

# /forge-plan

Generate a validation plan for the current project.

## Modes

- **quick** — Fast journey generation for small projects
- **standard** — Full discovery, journey generation, coverage analysis
- **consensus** — Three perspectives (User Advocate, Security Analyst, Quality Engineer) independently analyze, then merge

## Usage

```
/forge-plan                     # Standard mode
/forge-plan --quick             # Quick mode
/forge-plan --consensus         # Consensus mode with 3 perspectives
```

Output: `e2e-evidence/validation-plan.md`

Invoke the `forge-plan` skill to execute.
