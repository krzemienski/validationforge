# ValidationForge

**No-mock functional validation for Claude Code.** Ship verified code, not "it compiled" code.

> **179 files | 9,424 lines | 40 skills | 15 commands | 7 hooks | 5 agents | 8 rules**

## The Iron Rule

```
IF the real system doesn't work, FIX THE REAL SYSTEM.
NEVER create mocks, stubs, test doubles, or test files.
ALWAYS validate through the same interfaces real users experience.
ALWAYS capture evidence. ALWAYS review evidence. ALWAYS write verdicts.
```

ValidationForge enforces this through hooks that block test file creation, skills that guide real-system validation, and agents that capture and review evidence through actual user interfaces.

## Verification Status

What has been verified, and what hasn't. A validation tool must be honest about its own validation.

| Area | Status | Evidence |
|------|--------|----------|
| File inventory (40 skills, 15 commands, 7 hooks, 5 agents, 8 rules) | Verified | Disk scan, all files exist with content |
| Hook syntax (all 7 hooks) | Verified | Each hook parsed and executed with real JSON stdin |
| Hook functional behavior (all 7 hooks) | Verified | Piped real tool_result objects, verified correct stdout |
| Cross-references (commands -> skills, agents, rules) | Verified | All 15 commands audited, zero broken references |
| Plugin manifest format (plugin.json, hooks.json) | Verified | Matches Claude Code plugin spec |
| `${CLAUDE_PLUGIN_ROOT}` resolution | Not verified | Requires live plugin load in Claude Code session |
| Plugin loaded in Claude Code session | Not verified | Registered in installed_plugins.json, awaiting session restart |
| `/validate` run against a real project | Not verified | Requires live plugin + running target project |
| `/vf-setup` run end-to-end | Not verified | Requires live plugin session |
| Benchmark scores | Not verified | No project has been benchmarked |
| Skill content quality (all 40) | Partially verified | 5 of 40 skills deep-audited; remaining spot-checked |

**Bottom line:** The plugin structure is sound and internally consistent. Hooks work correctly when tested standalone. But the full pipeline has never been exercised against a real project in a live Claude Code session. That test is next.

## Why Not Unit Tests?

Unit tests verify code in isolation with mocks. Mocks drift from reality. ValidationForge verifies **systems in production** — through the same interfaces your users experience.

| Scenario | Unit Tests | ValidationForge |
|----------|:----------:|:---------------:|
| API field renamed (`users` -> `data`) | PASS (mock returns old field) | **FAIL** (curl shows new field, frontend crashes) |
| JWT expiry reduced to 15 min | PASS (mock time, never wait) | **FAIL** (real token expires, refresh fails) |
| iOS deep link after nav refactor | PASS (mock URL handler) | **FAIL** (simctl openurl -> wrong screen) |
| DB migration with duplicate emails | PASS (clean in-memory DB) | **FAIL** (real migration fails on duplicates) |
| CSS grid overflow on small screens | PASS (no visual rendering) | **FAIL** (Playwright screenshot shows overflow) |

These are design scenarios — situations where mock-based testing is structurally blind. ValidationForge's approach targets exactly these gaps by validating against live systems.

## Quick Start

### Install

```bash
# Option 1: Symlink into Claude Code plugin cache
mkdir -p ~/.claude/plugins/cache/validationforge/validationforge
ln -sf /path/to/validationforge ~/.claude/plugins/cache/validationforge/validationforge/1.0.0

# Option 2: Clone from GitHub (when published)
# git clone https://github.com/krzemienski/validationforge ~/.claude/plugins/cache/validationforge/validationforge/1.0.0

# Then register in ~/.claude/plugins/installed_plugins.json:
# "validationforge@validationforge": [{"scope": "user", "installPath": "~/.claude/plugins/cache/validationforge/validationforge/1.0.0", "version": "1.0.0"}]

# Restart Claude Code to load the plugin.
```

### Initialize for Your Project

```bash
/vf-setup                    # Interactive setup wizard
/vf-setup --strict           # Skip prompts, use strict enforcement
/vf-setup --permissive       # Skip prompts, use permissive enforcement
```

Setup detects your platform, selects enforcement level, scaffolds `e2e-evidence/`, installs rules to `.claude/rules/vf-*`, and verifies MCP server availability.

### Validate

```bash
/validate                    # Full pipeline: detect -> plan -> execute -> verdict
/validate-plan               # Plan only (no execution)
/validate-audit              # Read-only audit with severity classification
/validate-fix                # Fix FAIL verdicts and re-validate (3-strike limit)
/validate-ci                 # Non-interactive CI/CD mode with exit codes
/validate-team               # Multi-agent parallel platform validation
/validate-sweep              # Autonomous fix-and-revalidate loop until PASS
/validate-benchmark          # Measure validation posture (coverage, evidence, speed)
```

## The 7-Phase Pipeline

```
0. RESEARCH   -> Standards, best practices, applicable criteria
1. PLAN       -> Journeys, PASS criteria, evidence requirements
2. PREFLIGHT  -> Build compiles, services running, MCP servers available
3. EXECUTE    -> Run journeys against real system, capture evidence
4. ANALYZE    -> Root cause investigation for FAILs (sequential thinking)
5. VERDICT    -> Evidence-backed PASS/FAIL per journey, unified report
6. SHIP       -> Production readiness audit, deploy decision
```

### Command Pipeline Matrix

| Command | Research | Plan | Preflight | Execute | Analyze | Verdict | Ship |
|---------|:--------:|:----:|:---------:|:-------:|:-------:|:-------:|:----:|
| `/validate` | yes | yes | yes | yes | yes | yes | no |
| `/validate-plan` | yes | yes | yes | -- | -- | -- | -- |
| `/validate-audit` | yes | -- | yes | read-only | yes | yes | -- |
| `/validate-fix` | -- | -- | -- | yes | yes | yes | -- |
| `/validate-ci` | yes | yes | yes | yes | yes | yes | -- |
| `/validate-team` | yes | yes | yes | parallel | yes | unified | -- |
| `/validate-sweep` | -- | -- | -- | loop | loop | loop | -- |
| `/validate-benchmark` | -- | -- | -- | -- | score | report | -- |

## Platform Auto-Detection

ValidationForge scans your codebase and loads the right validation strategy:

| Platform | Detection Signals | Validation Approach |
|----------|-------------------|---------------------|
| **iOS** | `.xcodeproj`, `.xcworkspace`, `Package.swift` | `xcodebuild` -> simulator -> `idb` screenshots -> deep links |
| **CLI** | `Cargo.toml [[bin]]`, `go.mod + main.go`, `package.json "bin"` | Build binary -> execute with args -> capture stdout/stderr |
| **API** | Route handlers, OpenAPI spec, Express/FastAPI/Gin | Start server -> health check -> `curl` endpoints -> verify JSON |
| **Web** | React/Vue/Svelte/Next, `vite.config.*` | Dev server -> Playwright/Chrome DevTools -> screenshots |
| **Fullstack** | Web + API signals combined | Bottom-up: Database -> API -> Frontend UI |
| **Design** | `DESIGN.md`, Stitch project, Figma tokens | Visual diff, token audit, design system compliance |

Override with `--platform <type>` if auto-detection picks wrong.

## Team Validation

For multi-platform projects, spawn coordinated validators with `/validate-team`:

```
Lead (you)
├── Web Validator    -> e2e-evidence/web/
├── API Validator    -> e2e-evidence/api/
├── iOS Validator    -> e2e-evidence/ios/
├── Design Validator -> e2e-evidence/design/
└── Verdict Writer   -> e2e-evidence/report.md
```

Each validator owns its evidence directory exclusively. The lead synthesizes per-validator verdicts into a unified report. Validators run in parallel across platforms for maximum throughput.

## Architecture

### Skill Dependency Graph

Skills are layered. Higher skills depend on lower ones:

```
                    ┌─────────────────┐
         Layer 4:   │   e2e-validate   │  (Orchestrator)
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              v              v              v
    ┌──────────────┐  ┌────────────┐  ┌──────────────┐
L3: │create-        │  │full-       │  │baseline-     │  (Planners)
    │validation-plan│  │functional- │  │quality-      │
    └──────┬───────┘  │audit       │  │assessment    │
           │          └─────┬──────┘  └──────┬───────┘
              ┌─────────────┼────────────┐
              v             v            v
    ┌──────────────┐  ┌──────────┐  ┌──────────────┐
L2: │functional-   │  │preflight │  │condition-    │  (Protocols)
    │validation    │  │          │  │based-waiting │
    └──────┬───────┘  └──────────┘  └──────┬───────┘
           v                               v
    ┌──────────────────┐  ┌──────────────────────┐
L1: │no-mocking-       │  │gate-validation-      │  (Guardrails)
    │validation-gates  │  │discipline            │
    └──────────────────┘  └──────────────────────┘
           │                        │
           v                        v
    ┌──────────────────────────────────────────┐
L0: │verification-before-completion            │  (Foundation)
    │error-recovery                            │
    └──────────────────────────────────────────┘
```

### File Structure

```
validationforge/
├── .claude-plugin/
│   └── plugin.json                  Plugin manifest (skills, hooks)
├── package.json                     npm package config
├── CLAUDE.md                        Master reference document
├── README.md                        This file
├── ARCHITECTURE.md                  Pipeline details, benchmarks
├── SPECIFICATION.md                 Full technical specification
│
├── skills/                          40 skills
│   ├── e2e-validate/                  Orchestrator — 8 workflows, 6 platform refs
│   ├── functional-validation/         Iron Rule protocol + 4 reference files
│   ├── create-validation-plan/        Journey discovery + PASS criteria
│   ├── gate-validation-discipline/    Evidence-based completion gates
│   ├── no-mocking-validation-gates/   Mock detection + blocking
│   ├── verification-before-completion/ Prevents premature completion
│   ├── error-recovery/                3-strike fix protocol
│   ├── condition-based-waiting/       Smart async waiting
│   ├── preflight/                     Prerequisites check
│   ├── baseline-quality-assessment/   Pre-change state capture
│   ├── full-functional-audit/         Read-only audit protocol
│   ├── ios-validation/                iOS simulator validation
│   ├── ios-validation-gate/           iOS build gates
│   ├── ios-validation-runner/         iOS test execution
│   ├── ios-simulator-control/         Simulator lifecycle
│   ├── web-validation/                Browser automation
│   ├── web-testing/                   Web testing patterns
│   ├── playwright-validation/         Playwright MCP integration
│   ├── chrome-devtools/               Chrome DevTools MCP
│   ├── api-validation/                HTTP endpoint validation
│   ├── cli-validation/                Binary execution validation
│   ├── fullstack-validation/          Bottom-up integration
│   ├── design-validation/             Design system compliance
│   ├── design-token-audit/            Token verification
│   ├── stitch-integration/            Stitch MCP design validation
│   ├── visual-inspection/             Visual regression detection
│   ├── accessibility-audit/           Accessibility compliance
│   ├── responsive-validation/         Responsive layout testing
│   ├── parallel-validation/           Parallel journey execution
│   ├── e2e-testing/                   End-to-end test patterns
│   ├── sequential-analysis/           Sequential thinking analysis
│   ├── research-validation/           Research phase protocol
│   ├── retrospective-validation/      Post-validation retrospective
│   ├── build-quality-gates/           Build quality enforcement
│   ├── production-readiness-audit/    Ship decision protocol
│   ├── forge-setup/                   Setup orchestration
│   ├── forge-plan/                    Plan orchestration
│   ├── forge-execute/                 Execute orchestration
│   ├── forge-team/                    Team orchestration
│   └── forge-benchmark/               Benchmark orchestration
│
├── commands/                        15 slash commands
│   ├── validate.md                    Full pipeline
│   ├── validate-plan.md               Plan only
│   ├── validate-audit.md              Read-only audit
│   ├── validate-fix.md                Fix + re-validate
│   ├── validate-ci.md                 CI/CD mode
│   ├── validate-team.md               Multi-agent parallel
│   ├── validate-sweep.md              Autonomous fix loop
│   ├── validate-benchmark.md          Posture scoring
│   ├── vf-setup.md                    Setup wizard (10-step)
│   ├── forge-setup.md                 Forge setup entry point
│   ├── forge-plan.md                  Forge plan entry point
│   ├── forge-execute.md               Forge execute entry point
│   ├── forge-team.md                  Forge team entry point
│   ├── forge-benchmark.md             Forge benchmark entry point
│   └── forge-install-rules.md         Rule installation utility
│
├── hooks/                           7 enforcement hooks
│   ├── hooks.json                     Hook registration manifest
│   ├── block-test-files.js            Blocks *.test.*, *.spec.*, __tests__/
│   ├── evidence-gate-reminder.js      Evidence checklist on task completion
│   ├── validation-not-compilation.js  Build success != validation
│   ├── completion-claim-validator.js  Catches claims without evidence
│   ├── mock-detection.js              Detects jest.mock, sinon.stub, etc.
│   ├── evidence-quality-check.js      Warns on empty evidence files
│   └── validation-state-tracker.js    Tracks validation activity
│
├── agents/                          5 specialist agents
│   ├── platform-detector.md           Codebase scanning + routing
│   ├── evidence-capturer.md           Evidence collection + review
│   ├── verdict-writer.md              PASS/FAIL verdicts with citations
│   ├── validation-lead.md             Multi-agent team coordination
│   └── sweep-controller.md            Autonomous fix-and-revalidate loops
│
├── rules/                           8 enforcement rules
│   ├── validation-discipline.md       No-mock mandate, evidence standards
│   ├── execution-workflow.md          7-phase pipeline details
│   ├── evidence-management.md         Directory structure, naming, quality
│   ├── platform-detection.md          Detection priority, platform routing
│   ├── team-validation.md             Multi-agent roles, coordination
│   ├── benchmarking.md                Metric collection, analysis
│   ├── forge-execution.md             Phase gates, fix loop discipline
│   └── forge-team-orchestration.md    Validator assignment, verdict synthesis
│
├── config/                          3 enforcement profiles
│   ├── strict.json                    Maximum enforcement
│   ├── standard.json                  Balanced enforcement
│   └── permissive.json               Minimal enforcement
│
├── templates/                       4 report templates
│   ├── validation-plan.md             Plan format
│   ├── audit-report.md                Audit findings format
│   ├── e2e-report.md                  Full report format
│   └── verdict.md                     Per-journey verdict format
│
├── scripts/                         3 utility scripts
│   ├── detect-platform.sh             Platform auto-detection
│   ├── health-check.sh                Service health polling
│   └── evidence-collector.sh          Evidence directory setup
│
└── demo/
    └── DEMO-SCENARIO.md              Walkthrough scenario
```

## Configuration

Three enforcement levels control how aggressively ValidationForge enforces discipline:

| Profile | Test Files | Mock Detection | Evidence | Best For |
|---------|:---------:|:--------------:|:--------:|----------|
| **strict** | Blocked | Blocked | Mandatory | Production, compliance |
| **standard** | Blocked | Blocked | Recommended | Most projects |
| **permissive** | Warned | Warned | Optional | Transitioning teams |

Select during `/vf-setup` or override with `--strict`/`--permissive` flags.

## Evidence Standards

Evidence is captured to `e2e-evidence/` and **must be reviewed, not just captured**:

| Evidence Type | Good | Bad |
|---------------|------|-----|
| Screenshots | "Shows 3 sessions with green status badges" | "Screenshot exists" |
| API responses | `{"total": 41, "items": [...]}` | `200 OK` |
| CLI output | `Processed 150 files in 2.3s` | `Done` |
| Build logs | `Build Succeeded (47 targets)` | "Build passed" |

**Capturing evidence without reviewing it is WORSE than not capturing it.**

## Benchmarking

`/validate-benchmark` scores your project across four dimensions:

| Dimension | Weight | What It Measures |
|-----------|--------|-----------------|
| Coverage | 35% | Validated journeys / Total discoverable features |
| Evidence Quality | 30% | Evidence citations, observation quality, verdict rigor |
| Enforcement | 25% | Hooks installed, no mocks, no test files, rules active |
| Speed | 10% | Validation time relative to project size |

Grades: A (90+), B (80-89), C (70-79), D (60-69), F (<60).

## Skills Reference

### Core Pipeline (11 skills)

| Skill | Layer | Purpose |
|-------|:-----:|---------|
| `e2e-validate` | L4 | Routes everything -- 8 workflows, 6 platform refs |
| `create-validation-plan` | L3 | Journey discovery, PASS criteria |
| `full-functional-audit` | L3 | Read-only audit with severity classification |
| `baseline-quality-assessment` | L3 | Pre-change state capture |
| `functional-validation` | L2 | Iron Rule enforcement, 4-step protocol |
| `preflight` | L2 | Prerequisites check before validation |
| `condition-based-waiting` | L2 | Smart async waiting (8 strategies) |
| `no-mocking-validation-gates` | L1 | Block test files, detect mock patterns |
| `gate-validation-discipline` | L1 | Evidence-based completion gates |
| `verification-before-completion` | L0 | Prevents premature completion claims |
| `error-recovery` | L0 | 3-strike fix protocol with escalation |

### Platform Validation (11 skills)

| Skill | Platform |
|-------|----------|
| `ios-validation` | iOS/macOS simulator |
| `ios-validation-gate` | iOS build quality gates |
| `ios-validation-runner` | iOS validation execution |
| `ios-simulator-control` | Simulator lifecycle management |
| `web-validation` | Browser automation |
| `web-testing` | Web testing patterns |
| `playwright-validation` | Playwright MCP integration |
| `chrome-devtools` | Chrome DevTools MCP |
| `api-validation` | HTTP endpoint validation |
| `cli-validation` | Binary execution |
| `fullstack-validation` | Bottom-up integration |

### Design & Visual (4 skills)

| Skill | Purpose |
|-------|---------|
| `design-validation` | Design system compliance |
| `design-token-audit` | Token verification |
| `stitch-integration` | Stitch MCP design validation |
| `visual-inspection` | Visual regression detection |

### Specialized (9 skills)

| Skill | Purpose |
|-------|---------|
| `accessibility-audit` | Accessibility compliance |
| `responsive-validation` | Responsive layout testing |
| `parallel-validation` | Parallel journey execution |
| `e2e-testing` | End-to-end test patterns |
| `sequential-analysis` | Sequential thinking analysis |
| `research-validation` | Research phase protocol |
| `retrospective-validation` | Post-validation retrospective |
| `build-quality-gates` | Build quality enforcement |
| `production-readiness-audit` | Ship decision protocol |

### Forge Orchestration (5 skills)

| Skill | Purpose |
|-------|---------|
| `forge-setup` | Project initialization orchestration |
| `forge-plan` | Validation plan orchestration |
| `forge-execute` | Execution pipeline orchestration |
| `forge-team` | Multi-agent team orchestration |
| `forge-benchmark` | Benchmark scoring orchestration |

## Hooks Reference

| Hook | Event | Matcher | Effect |
|------|-------|---------|--------|
| `block-test-files.js` | PreToolUse | Write\|Edit\|MultiEdit | **Blocks** `*.test.*`, `*.spec.*`, `__tests__/`, `__mocks__/` |
| `evidence-gate-reminder.js` | PreToolUse | TaskUpdate | Injects evidence checklist on task completion |
| `validation-not-compilation.js` | PostToolUse | Bash | Reminds that build success is not validation |
| `completion-claim-validator.js` | PostToolUse | Bash | Catches claims without functional evidence |
| `mock-detection.js` | PostToolUse | Edit\|Write\|MultiEdit | Warns on `jest.mock`, `sinon.stub`, `unittest.mock`, etc. |
| `evidence-quality-check.js` | PostToolUse | Edit\|Write\|MultiEdit | Warns on empty evidence files |
| `validation-state-tracker.js` | PostToolUse | Bash | Tracks validation activity, reminds to capture evidence |

## Agents Reference

| Agent | Purpose |
|-------|---------|
| `platform-detector` | Scans codebase to classify platform type with confidence scoring |
| `evidence-capturer` | Captures screenshots, logs, API responses to `e2e-evidence/` |
| `verdict-writer` | Synthesizes evidence into PASS/FAIL verdicts with citations |
| `validation-lead` | Orchestrates multi-agent validation teams across platforms |
| `sweep-controller` | Controls autonomous fix-and-revalidate loops (3-strike limit) |

## License

MIT
