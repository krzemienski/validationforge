---
name: forge-team
description: "Multi-agent parallel validation across platforms"
allowed-tools: "Read, Write, Bash, Glob, Grep, Agent"
---

# /forge-team

Spawn platform-specific validators for parallel validation.

## Architecture

```
Lead (you)
├── Web Validator    → e2e-evidence/web/
├── API Validator    → e2e-evidence/api/
├── iOS Validator    → e2e-evidence/ios/
├── Design Validator → e2e-evidence/design/
└── Verdict Writer   → e2e-evidence/report.md
```

Each validator exclusively owns its evidence directory.

## Usage

```
/forge-team                     # Auto-detect platforms, spawn validators
/forge-team --web --api         # Specific platforms only
```

Invoke the `forge-team` skill to execute.
