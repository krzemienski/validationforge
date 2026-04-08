# ValidationForge Architecture

Dual-platform enforcement architecture for Claude Code (CC) and OpenCode (OC). Both platforms share the same pattern library and enforce the same validation discipline.

## Inventory

| Primitive | Count | CC Location | OC Location |
|-----------|------:|-------------|-------------|
| Skills | 41 | `skills/*/SKILL.md` | (shared via symlink) |
| Commands | 15 | `commands/*.md` | (shared via symlink) |
| Hooks | 8 | `hooks/*.js` + `hooks.json` | `.opencode/plugins/validationforge/index.ts` |
| Agents | 5 | `agents/*.md` | (shared) |
| Rules | 8 | `rules/*.md` | (shared) |
| Shell Scripts | 8 | `scripts/` + `scripts/benchmark/` | (shared) |
| Config Profiles | 3 | `config/*.json` | (shared) |

---

## Claude Code Plugin (CC)

### Hook Lifecycle

CC hooks are Node.js scripts registered in `hooks/hooks.json`. The CC harness pipes a JSON object to each hook's stdin and reads the response.

**PreToolUse hooks** (run before the tool executes):

```
CC Harness                            Hook Script
   |                                      |
   |-- stdin: JSON {tool_name, tool_input} -->|
   |                                      |-- parse stdin
   |                                      |-- evaluate patterns
   |                                      |
   |                          (if blocking)|-- stdout: JSON {decision, ...}
   |                          (if blocking)|-- exit 0
   |                                      |
   |                          (if passing) |-- exit 0 (silent, no output)
   |<-------------------------------------|
```

- `block-test-files.js` -- Matches `Write|Edit|MultiEdit`. Reads `tool_input.file_path`, checks against `TEST_PATTERNS` from patterns.js. If matched and not in `ALLOWLIST`, writes `{"permissionDecision":"deny","reason":"..."}` to stdout and exits 0.
- `evidence-gate-reminder.js` -- Matches `TaskUpdate`. Writes `{"additionalContext":"..."}` to stdout with an evidence checklist and exits 0.

**PostToolUse hooks** (run after the tool executes):

```
CC Harness                            Hook Script
   |                                      |
   |-- stdin: JSON {tool_name, tool_input,-->|
   |          tool_result}                |-- parse stdin
   |                                      |-- evaluate patterns
   |                                      |
   |                        (if feedback) |-- stderr: reminder text
   |                        (if feedback) |-- exit 2
   |                                      |
   |                        (if no-op)    |-- exit 0 (silent)
   |<-------------------------------------|
```

- `validation-not-compilation.js` -- Matches `Bash`. Checks `tool_result` against `BUILD_PATTERNS`. If build success detected, writes reminder to stderr, exits 2.
- `completion-claim-validator.js` -- Matches `Bash`. Checks `tool_result` against `COMPLETION_PATTERNS`. If completion claim detected without evidence directory, writes warning to stderr, exits 2.
- `validation-state-tracker.js` -- Matches `Bash`. Checks command against `VALIDATION_COMMAND_PATTERNS`. If validation tool detected, writes evidence reminder to stderr, exits 2.
- `mock-detection.js` -- Matches `Edit|Write|MultiEdit`. Checks written content against `MOCK_PATTERNS`. If mock patterns detected, writes warning to stderr, exits 2.
- `evidence-quality-check.js` -- Matches `Edit|Write|MultiEdit`. Checks if file path is in `e2e-evidence/` and content is empty. If so, writes warning to stderr, exits 2.

### Hook Registration (hooks.json)

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Write|Edit|MultiEdit", "hooks": [{"type":"command","command":"${CLAUDE_PLUGIN_ROOT}/hooks/block-test-files.js"}] },
      { "matcher": "TaskUpdate",           "hooks": [{"type":"command","command":"${CLAUDE_PLUGIN_ROOT}/hooks/evidence-gate-reminder.js"}] }
    ],
    "PostToolUse": [
      { "matcher": "Bash",                 "hooks": [
          {"type":"command","command":"${CLAUDE_PLUGIN_ROOT}/hooks/validation-not-compilation.js"},
          {"type":"command","command":"${CLAUDE_PLUGIN_ROOT}/hooks/completion-claim-validator.js"},
          {"type":"command","command":"${CLAUDE_PLUGIN_ROOT}/hooks/validation-state-tracker.js"}
      ]},
      { "matcher": "Edit|Write|MultiEdit", "hooks": [
          {"type":"command","command":"${CLAUDE_PLUGIN_ROOT}/hooks/mock-detection.js"},
          {"type":"command","command":"${CLAUDE_PLUGIN_ROOT}/hooks/evidence-quality-check.js"}
      ]}
    ]
  }
}
```

`${CLAUDE_PLUGIN_ROOT}` resolves to the plugin installation directory at runtime.

### Skill Lifecycle

Skills are directories under `skills/` containing a `SKILL.md` with YAML frontmatter:

```yaml
---
name: skill-name
description: What the skill does
triggers:
  - "keyword phrase"
  - "another trigger"
---
```

Claude Code discovers skills by scanning `SKILL.md` files in the plugin directory. When a user message or agent prompt matches a trigger phrase, the skill's content is loaded into context. Skills reference other skills by name (e.g., "invoke `preflight` skill first").

### Command Lifecycle

Commands are `.md` files in `commands/` with YAML frontmatter:

```yaml
---
name: command-name
description: What the command does
allowed-tools: "Read, Write, Bash, Glob"   # forge commands only
---
```

Validation commands (9) have no `allowed-tools` restriction. Forge commands (6) specify which Claude Code tools they may invoke, constraining the execution scope.

---

## OpenCode Plugin (OC)

### Plugin Entry Point

`.opencode/plugins/validationforge/index.ts` exports a `Plugin` function that registers three hooks and two tools.

### Hook Lifecycle

```
OpenCode Harness                      Plugin Hooks
   |                                      |
   |-- permission.ask(input, output) ---->|
   |   (before Write/Edit/MultiEdit)      |-- isBlockedTestFile(filePath)
   |                                      |-- if blocked: output.status = "deny"
   |<-------------------------------------|
   |                                      |
   |-- tool.execute.after(input, output)->|
   |   (after any tool)                   |-- if Bash: isBuildSuccess? isCompletionClaim?
   |                                      |-- if Write/Edit: detectMockPatterns? emptyEvidence?
   |                                      |-- attaches output.metadata warnings
   |<-------------------------------------|
   |                                      |
   |-- shell.env() ---------------------->|
   |                                      |-- returns VF_EVIDENCE_DIR, VF_VERSION, VF_ENFORCEMENT
   |<-------------------------------------|
```

- `permission.ask` -- Mirrors `block-test-files.js`. Calls `isBlockedTestFile()` from `patterns.ts`. Sets `output.status = "deny"` if matched.
- `tool.execute.after` -- Mirrors all 5 PostToolUse CC hooks. Checks bash output for build success and completion claims, checks write content for mock patterns, checks evidence files for empty content. Attaches `vf_reminder`, `vf_warning`, or `vf_note` to `output.metadata`.
- `shell.env` -- Injects `VF_EVIDENCE_DIR=e2e-evidence`, `VF_VERSION=1.0.0`, `VF_ENFORCEMENT=standard` into the shell environment.

### Custom Tools

- `vf_validate` -- Proxy to `/validate` command with optional `--platform` and `--scope` flags.
- `vf_check_evidence` -- Checks `e2e-evidence/` directory status and lists evidence files per journey.

---

## Pattern Sharing Architecture

A single source of truth for all regex patterns used across both platforms.

```
.opencode/plugins/validationforge/patterns.ts    <-- Source of truth
  |
  |-- Exports 6 pattern arrays:
  |     TEST_PATTERNS        (15 regexes: .test.*, .spec.*, __tests__/, etc.)
  |     ALLOWLIST             (4 regexes: e2e-evidence, .claude/, etc.)
  |     MOCK_PATTERNS         (20 regexes: jest.mock, sinon.stub, etc.)
  |     BUILD_PATTERNS        (10 regexes: build succeeded, compiled, etc.)
  |     COMPLETION_PATTERNS   (4 regexes: all pass, tests pass, etc.)
  |     VALIDATION_COMMAND_PATTERNS (8 regexes: playwright, simctl, etc.)
  |
  |-- Exports 5 helper functions:
  |     isBlockedTestFile(path)    -> string | null
  |     detectMockPatterns(text)   -> boolean
  |     isBuildSuccess(text)       -> boolean
  |     isCompletionClaim(text)    -> boolean
  |     isValidationCommand(cmd)   -> boolean
  |
  +-- OC plugin (index.ts)
  |     imports directly via TypeScript: import { isBlockedTestFile, ... } from "./patterns"
  |
  +-- CC hooks (hooks/patterns.js)
        CommonJS bridge using vm.runInNewContext():
        1. Reads patterns.ts from disk
        2. Strips TypeScript syntax (export, type annotations, function defs)
        3. Evaluates in vm sandbox to extract const arrays
        4. Falls back to inline copy if patterns.ts is unavailable
        CC hooks: require('./patterns') -> { TEST_PATTERNS, ALLOWLIST, ... }
```

Hooks that consume patterns.js:
- `block-test-files.js` -- TEST_PATTERNS, ALLOWLIST
- `completion-claim-validator.js` -- COMPLETION_PATTERNS
- `mock-detection.js` -- MOCK_PATTERNS
- `validation-not-compilation.js` -- BUILD_PATTERNS
- `validation-state-tracker.js` -- VALIDATION_COMMAND_PATTERNS

---

## Validation Pipeline

### Data Flow

```
User invokes /validate
  |
  v
RESEARCH: Scan codebase, identify platform, load applicable standards
  |
  v
PLAN: Map user journeys, define PASS criteria per journey
  |
  v
PREFLIGHT: Check prerequisites
  |  - Server running?      (health-check.sh or condition-based-waiting)
  |  - Build compiles?      (build-quality-gates skill)
  |  - Evidence dir exists? (evidence-collector.sh)
  |  - MCP servers up?      (platform-specific check)
  |
  v
EXECUTE: For each journey:
  |  - Interact with real system (simulator, browser, curl, binary)
  |  - Capture evidence to e2e-evidence/{journey-slug}/
  |  - Name files: step-{NN}-{description}.{ext}
  |
  v
ANALYZE: For FAIL journeys:
  |  - sequential-analysis skill for root cause investigation
  |  - error-recovery skill for 3-strike fix attempts
  |
  v
VERDICT: verdict-writer agent synthesizes all evidence
  |  - Per-journey PASS/FAIL with cited evidence
  |  - Unified report at e2e-evidence/report.md
  |
  v
SHIP (optional): production-readiness-audit skill
```

### Skill Dependency Graph

Skills are layered. Higher skills depend on lower ones:

```
                    +-------------------+
         Layer 4:   |   e2e-validate    |  (Orchestrator: routes everything)
                    +--------+----------+
                             |
              +--------------+--------------+
              v              v              v
    +----------------+  +------------+  +----------------+
L3: |create-         |  |full-       |  |baseline-       |  (Planners)
    |validation-plan |  |functional- |  |quality-        |
    +-------+--------+  |audit       |  |assessment      |
            |           +-----+------+  +-------+--------+
            |                 |                 |
              +---------------+-------------+
              v               v             v
    +----------------+  +----------+  +----------------+
L2: |functional-     |  |preflight |  |condition-      |  (Protocols)
    |validation      |  |          |  |based-waiting   |
    +-------+--------+  +----------+  +-------+--------+
            |                                 |
            v                                 v
    +--------------------+  +------------------------+
L1: |no-mocking-         |  |gate-validation-        |  (Guardrails)
    |validation-gates    |  |discipline              |
    +--------------------+  +------------------------+
            |                        |
            v                        v
    +----------------------------------------------+
L0: |verification-before-completion                |  (Foundation)
    |error-recovery                                |
    +----------------------------------------------+
```

### Platform Routing

The `e2e-validate` orchestrator skill (L4) routes to platform-specific skills based on detection:

```
e2e-validate
  |-- detect platform (detect-platform.sh or platform-detector agent)
  |
  +-- ios?       -> ios-validation, ios-validation-gate, ios-validation-runner, ios-simulator-control
  +-- web?       -> web-validation, web-testing, playwright-validation, chrome-devtools
  +-- api?       -> api-validation
  +-- cli?       -> cli-validation
  +-- fullstack? -> fullstack-validation (chains api-validation + web-validation)
  +-- design?    -> design-validation, design-token-audit, stitch-integration, visual-inspection
```

---

## Shell Scripts

### Core Scripts (4)

| Script | Purpose |
|--------|---------|
| `scripts/detect-platform.sh` | Scans codebase for platform indicators, outputs detected platform type |
| `scripts/health-check.sh` | Polls a service endpoint until healthy or timeout |
| `scripts/evidence-collector.sh` | Creates and validates `e2e-evidence/` directory structure |
| `scripts/sync-opencode.sh` | Symlinks skills and commands into `.opencode/` for OC compatibility |

### Benchmark Scripts (4)

| Script | Purpose |
|--------|---------|
| `scripts/benchmark/test-hooks.sh` | Tests all 7 CC hooks with real JSON stdin payloads |
| `scripts/benchmark/validate-skills.sh` | Validates structural integrity of all 41 skill SKILL.md files |
| `scripts/benchmark/validate-cmds.sh` | Validates structural integrity of all 15 command .md files |
| `scripts/benchmark/aggregate-results.sh` | Aggregates benchmark scores into a unified report |

---

## Agents

| Agent | File | Purpose |
|-------|------|---------|
| `platform-detector` | `agents/platform-detector.md` | Scans codebase to classify platform type with confidence scoring |
| `evidence-capturer` | `agents/evidence-capturer.md` | Captures screenshots, logs, API responses to `e2e-evidence/` |
| `verdict-writer` | `agents/verdict-writer.md` | Synthesizes evidence into PASS/FAIL verdicts with citations |
| `validation-lead` | `agents/validation-lead.md` | Orchestrates multi-agent validation teams across platforms |
| `sweep-controller` | `agents/sweep-controller.md` | Controls autonomous fix-and-revalidate loops (3-strike limit) |

---

## Configuration Schema

Stored at `~/.claude/.vf-config.json` after installation:

```json
{
  "strictness": "strict | standard | permissive",
  "evidence_dir": "e2e-evidence",
  "platform_override": "auto | ios | web | api | cli | fullstack",
  "ci_mode": false,
  "max_recovery_attempts": 3,
  "require_baseline": true,
  "parallel_journeys": false,
  "evidence_retention_days": 30
}
```

Three enforcement profiles in `config/`:

| Profile | File | Test Files | Mock Detection | Evidence |
|---------|------|:---------:|:--------------:|:--------:|
| strict | `config/strict.json` | Blocked | Blocked | Mandatory |
| standard | `config/standard.json` | Blocked | Blocked | Recommended |
| permissive | `config/permissive.json` | Warned | Warned | Optional |

---

## Rules

8 enforcement rules installed to `~/.claude/rules/vf-*.md` by `install.sh` or `/forge-install-rules`:

| Rule | File | Purpose |
|------|------|---------|
| validation-discipline | `rules/validation-discipline.md` | No-mock mandate, evidence standards, gate protocol |
| execution-workflow | `rules/execution-workflow.md` | 7-phase pipeline details |
| evidence-management | `rules/evidence-management.md` | Directory structure, naming, quality, retention |
| platform-detection | `rules/platform-detection.md` | Detection priority, platform-specific validation |
| team-validation | `rules/team-validation.md` | Multi-agent roles, file ownership, coordination |
| benchmarking | `rules/benchmarking.md` | Metric collection, integrity, comparative analysis |
| forge-execution | `rules/forge-execution.md` | Phase gates, fix loop discipline, state persistence |
| forge-team-orchestration | `rules/forge-team-orchestration.md` | Validator assignment, evidence ownership, verdict synthesis |
