---
name: forge-setup
description: "Initialize ValidationForge for this project"
allowed-tools: "Read, Write, Edit, Bash, Glob, Grep, Agent"
---

# /forge-setup

Initialize ValidationForge for the current project.

## What This Does

1. **Detect platforms** — Scan for iOS, Web, API, CLI, Design indicators
2. **Select enforcement** — Choose strict, standard, or permissive
3. **Scaffold directories** — Create `.validationforge/` and `e2e-evidence/`
4. **Install rules** — Copy VF rules to `.claude/rules/vf-*`
5. **Verify MCP servers** — Check Playwright, Xcode tools, Stitch availability
6. **Report** — Print setup summary

## Usage

```
/forge-setup                    # Interactive setup (asks enforcement level)
/forge-setup --strict           # Skip prompt, use strict enforcement
/forge-setup --permissive       # Skip prompt, use permissive enforcement
```

Invoke the `forge-setup` skill to execute.
