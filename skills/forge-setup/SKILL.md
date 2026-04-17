---
name: forge-setup
description: "Run first on any new project to initialize ValidationForge. Detects which platforms are present (iOS, web, API, CLI, design), picks an enforcement level (strict/standard/permissive), scaffolds .validationforge/ and e2e-evidence/ directories, copies 8 enforcement rules into .claude/rules/ with vf- prefix, and validates that MCP servers for detected platforms are reachable. Reach for it whenever someone says 'set up validation', 'initialize validationforge', 'vf setup', before the first /validate or /forge-execute call on a project, or when a project is missing .validationforge/config.json."
triggers:
  - "setup validation"
  - "initialize validationforge"
  - "vf setup"
  - "forge setup"
  - "first-time validation setup"
  - "configure enforcement level"
context_priority: reference
---

# forge-setup

Initialize ValidationForge for a project. Detects platforms, scaffolds directories, installs enforcement hooks, and configures validation posture.

**Automated setup**: `bash skills/forge-setup/scripts/forge-init.sh --project-dir=/path/to/project --enforcement-level=standard` runs the install idempotently and logs what it did (config status, rules copied, gitignore update). Re-run safely to repair. Phases below document the full manual flow.

## When to use

Run this once per project before any other ValidationForge command. If `.validationforge/config.json` already exists, this skill becomes a repair / upgrade tool — use it to change enforcement level, reinstall missing rules, or re-scaffold evidence directories.

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

Copy ValidationForge rules to `.claude/rules/vf-*`. The `vf-` prefix avoids conflicts with rules from other plugins.

| Rule | What it enforces |
|------|------------------|
| `vf-validation-discipline.md` | Iron Rule — no mocks, real-system validation only |
| `vf-execution-workflow.md` | The 7-phase pipeline order (research → plan → preflight → execute → analyze → verdict → ship) |
| `vf-evidence-management.md` | Evidence must be saved, read, and cited; nothing claims PASS without proof |
| `vf-platform-detection.md` | Detect platform before validating; wrong platform = wrong approach |
| `vf-team-validation.md` | Multi-agent coordination, exclusive evidence directories, wave handoff |
| `vf-forge-execution.md` | Forge loop semantics (3-strike fix, attempt-N directories, rebuild rule) |
| `vf-forge-team-orchestration.md` | Wave dispatch and aggregation across forge teams |
| `vf-benchmarking.md` | Benchmark scoring and posture tracking |

### Phase 5: Verification

Confirm setup by checking each item. If any fails, the fix is listed inline — don't proceed past Phase 5 until all pass.

| Check | Command | If it fails |
|-------|---------|-------------|
| `.validationforge/config.json` exists and is valid JSON | `cat .validationforge/config.json \| python3 -m json.tool` | Review the syntax error reported; fix (common: missing comma, unquoted key); re-run Phase 3 |
| `.validationforge/forge-state.json` exists and is valid JSON | `cat .validationforge/forge-state.json \| python3 -m json.tool` | Run `bash scripts/forge-init.sh` to recreate |
| `e2e-evidence/` directory exists | `test -d e2e-evidence` | `mkdir -p e2e-evidence && touch e2e-evidence/.gitkeep` |
| All 8 rules installed | `ls .claude/rules/vf-*.md \| wc -l` should return 8 | Re-run Phase 4 copy commands; check source rules exist in plugin dir |
| Hooks loaded | `hooks.json` referenced in plugin manifest | Re-check plugin install; may need to restart the agent session |
| MCP servers available for detected platforms | Platform-specific: Playwright for web, Xcode for iOS | Install/configure the missing MCP server; or drop the platform from `config.json.platforms` if not needed |

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
