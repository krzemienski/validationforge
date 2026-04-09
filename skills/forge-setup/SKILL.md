---
name: forge-setup
description: Initialize ValidationForge for a project. Detects platforms, scaffolds directories, installs enforcement hooks, and configures validation posture.
context_priority: reference
---

# forge-setup

Initialize ValidationForge for a project. Detects platforms, scaffolds directories, installs enforcement hooks, and configures validation posture.

## Trigger

- "setup validation", "initialize validationforge", "vf setup"
- First time running any validate-* command in a project

## Process

### Phase 1: Platform Detection

Scan the project root for platform indicators:

| Platform | Indicators | Validation Tools |
|----------|-----------|-----------------|
| iOS | .xcodeproj, .swift, Package.swift | Xcode build, simctl, idb |
| Web | package.json + react/next/vue/svelte | Playwright, Chrome DevTools |
| API | Express/Fastify routes, OpenAPI spec | curl, httpie, API snapshots |
| CLI | bin entries, argument parsers | Direct invocation, exit codes |
| Design | DESIGN.md, Stitch project, Figma | Visual diff, token audit |

Multiple platforms can coexist (fullstack detection).

### Phase 2: Enforcement Configuration

Select enforcement level based on project maturity:

| Level | File | Behavior |
|-------|------|----------|
| strict | config/strict.json | All hooks, block test files, require evidence for every completion |
| standard | config/standard.json | Core hooks, evidence reminders, soft gates |
| permissive | config/permissive.json | Minimal hooks, no blocking, advisory only |

Default: `standard`

### Phase 3: Directory Scaffold

Create the validation infrastructure:

```
.validationforge/
  config.json          # Platform detection results + enforcement level
  forge-state.json     # Execution state (idle initially)
  benchmark-history.json  # Benchmark trend data
e2e-evidence/
  .gitkeep
```

Run `scripts/forge-init.sh` to initialize the forge state directory:

```bash
bash scripts/forge-init.sh
```

This creates `.validationforge/forge-state.json` with status `idle` if it does not already exist. Output confirms the file path and initial state.

### Phase 4: Rules Installation

Copy ValidationForge rules to `.claude/rules/vf-*`:
- `vf-validation-discipline.md`
- `vf-execution-workflow.md`
- `vf-evidence-management.md`
- `vf-platform-detection.md`
- `vf-team-validation.md`
- `vf-forge-execution.md`
- `vf-forge-team-orchestration.md`
- `vf-benchmarking.md`

Uses `vf-` prefix to avoid conflicts with other plugins.

### Phase 5: Verification

Confirm setup by checking:
- [ ] `.validationforge/config.json` exists and is valid
- [ ] `.validationforge/forge-state.json` exists and is valid JSON (run `cat .validationforge/forge-state.json | python3 -m json.tool` to verify)
- [ ] `e2e-evidence/` directory exists
- [ ] Rules installed to `.claude/rules/`
- [ ] Hooks loaded (check hooks.json is referenced in plugin manifest)
- [ ] MCP servers available for detected platforms (Playwright, Xcode, etc.)

### Config Schema

```json
{
  "version": "1.0.0",
  "platforms": ["web", "api"],
  "enforcement": "standard",
  "evidence_dir": "e2e-evidence",
  "max_fix_attempts": 3,
  "mcp_servers": {
    "playwright": true,
    "chrome-devtools": false,
    "xcode": false,
    "stitch": false
  },
  "created_at": "2026-03-07T20:00:00Z"
}
```

## Output

Print setup summary:
```
ValidationForge initialized
  Platforms: web, api
  Enforcement: standard
  Evidence: e2e-evidence/
  Rules: 8 installed to .claude/rules/
  MCP: playwright (available), chrome-devtools (not configured)
```
