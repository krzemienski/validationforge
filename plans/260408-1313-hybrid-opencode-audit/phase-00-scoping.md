# Phase 0: Inventory and Scoping

**Date:** 2026-04-08
**Scope:** Hybrid audit — Claude Code plugin audit + OpenCode compatibility layer
**Status:** COMPLETE

## Platform Classification

**This is a Claude Code plugin.** Not an OpenCode plugin.

| Evidence | Finding |
|----------|---------|
| `.claude-plugin/plugin.json` | Claude Code manifest: `name: validationforge`, `version: 1.0.0` |
| `.claude-plugin/marketplace.json` | Claude Code marketplace format with `source: "./"` |
| `package.json` keywords | `claude-code`, `claude-code-plugin` |
| `hooks/hooks.json` | Claude Code hook system: `PreToolUse`, `PostToolUse`, `${CLAUDE_PLUGIN_ROOT}` |
| `CLAUDE.md` | Claude Code instructions file |
| `opencode.json` | **Does not exist** |
| `.opencode/` directory | **Does not exist** |
| TypeScript plugins | **None** |
| Git repository | **Not initialized** |

## Primitive Inventory

### Skills (40 files, 35 valid + 5 broken)

**Valid Skills (35)** — Have `SKILL.md` with `name` and `description` frontmatter:

| # | Directory | Name | Category |
|---|-----------|------|----------|
| 1 | `accessibility-audit` | accessibility-audit | Quality |
| 2 | `api-validation` | api-validation | Platform |
| 3 | `baseline-quality-assessment` | baseline-quality-assessment | Quality |
| 4 | `build-quality-gates` | build-quality-gates | Quality |
| 5 | `chrome-devtools` | chrome-devtools | Platform |
| 6 | `cli-validation` | cli-validation | Platform |
| 7 | `condition-based-waiting` | condition-based-waiting | Operational |
| 8 | `create-validation-plan` | create-validation-plan | Planning |
| 9 | `design-token-audit` | design-token-audit | Design |
| 10 | `design-validation` | design-validation | Design |
| 11 | `e2e-testing` | e2e-testing | Quality |
| 12 | `error-recovery` | error-recovery | Operational |
| 13 | `full-functional-audit` | full-functional-audit | Quality |
| 14 | `fullstack-validation` | fullstack-validation | Platform |
| 15 | `functional-validation` | functional-validation | Core |
| 16 | `gate-validation-discipline` | gate-validation-discipline | Core |
| 17 | `ios-simulator-control` | ios-simulator-control | Platform |
| 18 | `ios-validation-gate` | ios-validation-gate | Platform |
| 19 | `ios-validation-runner` | ios-validation-runner | Platform |
| 20 | `ios-validation` | ios-validation | Platform |
| 21 | `no-mocking-validation-gates` | no-mocking-validation-gates | Core |
| 22 | `parallel-validation` | parallel-validation | Orchestration |
| 23 | `playwright-validation` | playwright-validation | Platform |
| 24 | `preflight` | preflight | Operational |
| 25 | `production-readiness-audit` | production-readiness-audit | Quality |
| 26 | `research-validation` | research-validation | Planning |
| 27 | `responsive-validation` | responsive-validation | Quality |
| 28 | `retrospective-validation` | retrospective-validation | Quality |
| 29 | `sequential-analysis` | sequential-analysis | Analysis |
| 30 | `stitch-integration` | stitch-integration | Design |
| 31 | `verification-before-completion` | verification-before-completion | Core |
| 32 | `visual-inspection` | visual-inspection | Quality |
| 33 | `web-testing` | web-testing | Platform |
| 34 | `web-validation` | web-validation | Platform |

**Format Violation — Directory/Name Mismatch (1):**

| Directory | Frontmatter `name` | Issue |
|-----------|-------------------|-------|
| `e2e-validate` | `validate` | Name must match directory. Should be `e2e-validate`. |

**Broken Skills — Missing Frontmatter (5):**

| Directory | Issue |
|-----------|-------|
| `forge-benchmark` | No `name:` or `description:` in frontmatter |
| `forge-execute` | No `name:` or `description:` in frontmatter |
| `forge-plan` | No `name:` or `description:` in frontmatter |
| `forge-setup` | No `name:` or `description:` in frontmatter |
| `forge-team` | No `name:` or `description:` in frontmatter |

### Commands (15 files)

| # | File | Name | Description |
|---|------|------|-------------|
| 1 | `validate.md` | validate | Full pipeline: detect + plan + approve + execute + report |
| 2 | `validate-plan.md` | validate-plan | Analyze codebase, generate validation plan |
| 3 | `validate-audit.md` | validate-audit | Read-only audit with severity classification |
| 4 | `validate-fix.md` | validate-fix | Fix failures and re-validate (3-strike) |
| 5 | `validate-ci.md` | validate-ci | Non-interactive CI/CD mode with exit codes |
| 6 | `validate-team.md` | validate-team | Multi-agent parallel platform validation |
| 7 | `validate-sweep.md` | validate-sweep | Autonomous fix-and-revalidate loop |
| 8 | `validate-benchmark.md` | validate-benchmark | Benchmark validation posture |
| 9 | `vf-setup.md` | vf-setup | Setup and configure ValidationForge |
| 10 | `forge-setup.md` | forge-setup | Initialize ValidationForge for this project |
| 11 | `forge-plan.md` | forge-plan | Generate validation plan with journey discovery |
| 12 | `forge-execute.md` | forge-execute | Run validation journeys with fix loop |
| 13 | `forge-team.md` | forge-team | Multi-agent parallel validation |
| 14 | `forge-benchmark.md` | forge-benchmark | Measure validation posture |
| 15 | `forge-install-rules.md` | forge-install-rules | Install rules to .claude/rules/ |

### Hooks (7 JS files + 1 config)

| # | File | Trigger | Matcher | Purpose |
|---|------|---------|---------|---------|
| 1 | `block-test-files.js` | PreToolUse | Write\|Edit\|MultiEdit | Block test/mock/stub file creation |
| 2 | `evidence-gate-reminder.js` | PreToolUse | TaskUpdate | Inject evidence checklist on completion |
| 3 | `validation-not-compilation.js` | PostToolUse | Bash | Remind build ≠ validation |
| 4 | `completion-claim-validator.js` | PostToolUse | Bash | Catch claims without evidence |
| 5 | `validation-state-tracker.js` | PostToolUse | Bash | Track validation activity |
| 6 | `mock-detection.js` | PostToolUse | Edit\|Write\|MultiEdit | Detect mock patterns in code |
| 7 | `evidence-quality-check.js` | PostToolUse | Edit\|Write\|MultiEdit | Warn on empty evidence files |
| — | `hooks.json` | — | — | Hook registration manifest |

### Agents (5 files)

| # | File | Role | Capabilities |
|---|------|------|-------------|
| 1 | `platform-detector.md` | Platform analysis | platform-detection, codebase-analysis, confidence-scoring |
| 2 | `evidence-capturer.md` | Evidence collection | evidence-capture, screenshot-collection, api-response-logging |
| 3 | `verdict-writer.md` | Verdict synthesis | evidence-review, verdict-writing, root-cause-analysis |
| 4 | `validation-lead.md` | Team orchestration | team-orchestration, journey-decomposition, evidence-aggregation |
| 5 | `sweep-controller.md` | Fix loop control | fix-loop-control, root-cause-analysis, revalidation |

### Rules (8 files, 393 total lines)

| # | File | Lines | Topic |
|---|------|-------|-------|
| 1 | `validation-discipline.md` | 42 | No-mock mandate, evidence standards |
| 2 | `evidence-management.md` | 46 | Directory structure, naming, quality |
| 3 | `execution-workflow.md` | 73 | 7-phase pipeline details |
| 4 | `platform-detection.md` | 28 | Detection priority, routing |
| 5 | `team-validation.md` | 54 | Multi-agent roles, coordination |
| 6 | `forge-execution.md` | 44 | Phase gates, fix loop discipline |
| 7 | `forge-team-orchestration.md` | 42 | Validator assignment, evidence ownership |
| 8 | `benchmarking.md` | 64 | Metric collection, integrity |

### Infrastructure (out of audit scope for format compliance, in scope for docs)

| File/Dir | Purpose |
|----------|---------|
| `.claude-plugin/plugin.json` | Plugin manifest |
| `.claude-plugin/marketplace.json` | Marketplace config |
| `package.json` | npm metadata |
| `install.sh` | Installer script |
| `CLAUDE.md` | Plugin instructions |
| `config/strict.json` | Strict enforcement config |
| `config/standard.json` | Standard enforcement config |
| `config/permissive.json` | Permissive enforcement config |
| `templates/` | 4 markdown templates (verdict, plan, report, audit) |
| `scripts/` | 3 shell scripts (evidence-collector, detect-platform, health-check) |
| `e2e-evidence/` | Evidence output directory |
| `demo/` | Demo scenario |

### Existing Documentation (in scope for overhaul)

| File | Lines | Content |
|------|-------|---------|
| `README.md` | ~600 | Existing plugin readme |
| `ARCHITECTURE.md` | ~400 | Existing architecture doc |
| `SPECIFICATION.md` | ~1500 | Detailed spec |
| `PRD.md` | ~1100 | Product requirements |
| `TECHNICAL-DEBT.md` | ~300 | Known debt |
| `COMPETITIVE-ANALYSIS.md` | ~200 | Competitive landscape |

## Scope Summary

### IN SCOPE — Claude Code Audit

| Primitive | Count | Action |
|-----------|-------|--------|
| Skills | 40 (35 valid + 5 broken) | Audit format, frontmatter, instructions, tool refs |
| Commands | 15 | Audit frontmatter, arguments, routing |
| Hooks | 7 + hooks.json | Audit input handling, error recovery, output protocol |
| Agents | 5 | Audit capabilities, instruction quality |
| Rules | 8 | Audit accuracy, scope, coverage |
| Documentation | 6 files | Overhaul README, ARCHITECTURE; create SKILLS.md, COMMANDS.md |
| Infrastructure | install.sh, configs, templates | Audit install path, config schema |

### IN SCOPE — OpenCode Layer Creation

| Deliverable | Description |
|-------------|-------------|
| `.opencode/skill/` | Mirror all 40 skills in OpenCode skill format |
| `.opencode/command/` | Mirror all 15 commands in OpenCode command format |
| `opencode.json` | Plugin registration config |
| OpenCode README section | Installation and usage for OpenCode users |

### OUT OF SCOPE

| Item | Reason |
|------|--------|
| `.omc/` state files | Runtime state, not extension primitives |
| `e2e-evidence/` contents | Output artifacts, not plugin code |
| `plans/` contents | Planning artifacts |
| `demo/` | Demo content |
| MCP server creation | No MCP servers in current codebase |
| TypeScript plugin (`@opencode-ai/plugin`) | No existing TS plugins; OpenCode layer uses skill/command format only |

## Critical Defects Found (Phase 0)

| # | Severity | Primitive | Issue |
|---|----------|-----------|-------|
| 1 | **HIGH** | Skill | 5 forge-* skills have NO frontmatter (completely broken) |
| 2 | **HIGH** | Skill | `e2e-validate` has `name: validate` (directory mismatch) |
| 3 | **HIGH** | Infrastructure | No git repository initialized |
| 4 | **MEDIUM** | Hook | `block-test-files.js` uses deprecated `decision: "block"` output format |
| 5 | **MEDIUM** | Hook | `mock-detection.js` uses `hookSpecificOutput` for PostToolUse — should use stderr + exit 2 per Claude Code protocol |
| 6 | **LOW** | Skill | `e2e-validate/SKILL.md` is the most complex skill (128 lines) — may benefit from splitting |

## Gate Check

- [x] Every file classified by primitive type
- [x] Every primitive inventoried with counts and categories
- [x] In-scope vs out-of-scope documented with rationale
- [x] Critical defects surfaced before analysis phase
- [x] OpenCode layer scope defined

**Phase 0 gate: PASSED.** Proceeding to Phase 1.
