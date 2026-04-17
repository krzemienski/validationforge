# ValidationForge

No-mock validation platform for Claude Code. ValidationForge replaces unit tests, mocks, and stubs with evidence-based validation against real running systems. Every PASS verdict must cite specific evidence — screenshots, API responses, logs — captured from actual user-facing behavior.

**Version:** 1.0.0
**License:** MIT
**Author:** [Nick Krzemienski](https://github.com/krzemienski)
**Repository:** [github.com/krzemienski/validationforge](https://github.com/krzemienski/validationforge)

> For quick start and installation, see the [main README](../README.md).

### Related Documentation

| Document | Description |
|----------|-------------|
| [Architecture](ARCHITECTURE.md) | Plugin lifecycle, hook flow, pipeline, agent architecture |
| [Hook API Reference](HOOK-API-REFERENCE.md) | Per-hook I/O contracts, patterns, configuration |
| [ADRs](adr/) | Architecture Decision Records — the *why* behind design choices |
| [Iron Rules](domain/iron-rules.md) | The 8 non-negotiable rules with rationale |
| [Evidence Standards](domain/evidence-standards.md) | What makes evidence valid or invalid |
| [Hook Protocol](patterns/hook-protocol.md) | Complete stdin/stdout/exit code protocol |
| [Config Cascade](patterns/config-cascade.md) | How enforcement config flows to hooks |
| [Agent Dispatch](patterns/agent-dispatch.md) | Agent chain, file ownership, handoff protocol |
| [CC Plugin API](interfaces/claude-code-plugin-api.md) | How VF integrates with Claude Code |
| [OC Plugin API](interfaces/opencode-plugin-api.md) | How VF adapts for OpenCode |
| [Portability](PORTABILITY.md) | Dual-platform shared patterns architecture |
| [Benchmarks](BENCHMARKS.md) | Scoring rubric for hooks, skills, commands, agents |

## Quick Start

### Install via Marketplace

Search for `validationforge` in the Claude Code plugin marketplace, or:

```bash
claude plugin install validationforge
```

### Install via Local Path

Clone the repository and install from the local directory:

```bash
git clone https://github.com/krzemienski/validationforge.git ~/.claude/plugins/validationforge
```

### Install via Script

```bash
curl -fsSL https://raw.githubusercontent.com/krzemienski/validationforge/main/install.sh | bash
```

The installer clones the repo to `~/.claude/plugins/validationforge`, copies rules to `~/.claude/rules/` with a `vf-` prefix, creates an `e2e-evidence/` directory in the current project, and saves config to `~/.claude/.vf-config.json`.

### First Run

After installation, run the setup command in your project:

```
/vf-setup
```

This detects your project's platform, creates the evidence directory, and writes a local config.

## Core Commands

ValidationForge provides 15 slash commands split between the validation pipeline and forge orchestration.

### Validation Commands

| Command | Description |
|---------|-------------|
| `/vf-setup` | Setup and configure ValidationForge for a project or globally |
| `/validate` | Run full end-to-end validation -- detect platform, map journeys, capture evidence, write verdicts |
| `/validate-plan` | Analyze codebase and generate a validation plan with PASS criteria -- no execution |
| `/validate-audit` | Read-only validation audit -- captures evidence and classifies findings without modifying code |
| `/validate-fix` | Fix validation failures and re-validate until all journeys pass (3-strike limit) |
| `/validate-ci` | Non-interactive CI/CD mode -- auto-execute full validation pipeline with exit codes |
| `/validate-team` | Spawn coordinated validation agents across platforms with evidence handoff |
| `/validate-sweep` | Autonomous validation loop -- detect, validate, fix, re-validate until PASS or max attempts |
| `/validate-benchmark` | Benchmark validation coverage, speed, and evidence quality against baseline metrics |

### Forge Commands

| Command | Description |
|---------|-------------|
| `/forge-setup` | Initialize ValidationForge for this project |
| `/forge-plan` | Generate a validation plan with journey discovery and PASS criteria |
| `/forge-execute` | [planned V2.0] Run validation journeys against the real system with fix-and-retry loop |
| `/forge-team` | Multi-agent parallel validation across platforms |
| `/forge-benchmark` | Measure validation posture across 5 dimensions with trend tracking |
| `/forge-install-rules` | Install ValidationForge rules to `.claude/rules/` for cross-session enforcement |

## The 7-Phase Pipeline

ValidationForge runs a structured pipeline from research through ship decision:

| Phase | Name | What Happens |
|-------|------|-------------|
| 0 | **RESEARCH** | Discover applicable standards, best practices, and validation criteria for the project's platform |
| 1 | **PLAN** | Map user journeys, define PASS criteria, and specify evidence requirements for each journey |
| 2 | **PREFLIGHT** | Verify the build compiles, services are running, and required tools (MCP servers, browsers, simulators) are available |
| 3 | **EXECUTE** | Run each journey against the real system, capturing screenshots, API responses, and logs as evidence |
| 4 | **ANALYZE** | Investigate root causes of failures using sequential thinking and evidence correlation |
| 5 | **VERDICT** | Review evidence and issue PASS/FAIL per journey with specific citations; produce unified report |
| 6 | **SHIP** | Production readiness audit and deploy decision based on verdict outcomes |

Preflight failures halt the pipeline. No journey proceeds without a running system.

## Iron Rules

These rules are enforced by hooks at runtime. They are not guidelines.

1. **If the real system doesn't work, fix the real system.** Do not work around it.
2. **Never create mocks, stubs, test doubles, or test files.** The `block-test-files` hook blocks these at the file system level.
3. **Never mark a journey PASS without specific cited evidence.** "It looked fine" is not evidence.
4. **Never skip preflight.** If preflight fails, stop.
5. **Never exceed 3 fix attempts per journey.** After 3 failures, escalate.
6. **Never produce a partial verdict.** Wait for all validators to complete.
7. **Never reuse evidence from a previous attempt.** Each run captures fresh evidence.
8. **Compilation success is not functional validation.** The `validation-not-compilation` hook enforces this.

## Skills

ValidationForge includes 40 skills organized by category.

### Platform Validation (11)

| Skill | Purpose |
|-------|---------|
| `ios-validation` | End-to-end iOS app validation |
| `ios-validation-gate` | iOS-specific quality gates |
| `ios-validation-runner` | Execute iOS validation journeys |
| `ios-simulator-control` | Manage iOS simulators for validation |
| `playwright-validation` | Browser automation for web validation |
| `web-validation` | Web application validation |
| `web-testing` | Web interaction and evidence capture |
| `chrome-devtools` | Chrome DevTools integration for inspection |
| `api-validation` | REST/GraphQL API validation |
| `cli-validation` | Command-line application validation |
| `fullstack-validation` | Multi-layer application validation |

### Quality Gates (6)

| Skill | Purpose |
|-------|---------|
| `functional-validation` | Core validation protocol and discipline |
| `gate-validation-discipline` | Gate enforcement rules |
| `no-mocking-validation-gates` | Mock prevention gates |
| `build-quality-gates` | Build quality enforcement |
| `verification-before-completion` | Pre-completion verification checklist |
| `preflight` | Pre-validation system readiness checks |

### Design Validation (4)

| Skill | Purpose |
|-------|---------|
| `design-validation` | Design specification compliance |
| `design-token-audit` | Design token consistency audit |
| `stitch-integration` | Stitch design tool integration |
| `visual-inspection` | Visual regression and inspection |

### Analysis and Research (3)

| Skill | Purpose |
|-------|---------|
| `sequential-analysis` | Step-by-step analytical reasoning |
| `research-validation` | Standards and best practices research |
| `retrospective-validation` | Post-validation retrospective |

### Specialized (6)

| Skill | Purpose |
|-------|---------|
| `accessibility-audit` | WCAG accessibility compliance |
| `responsive-validation` | Multi-viewport responsive validation |
| `parallel-validation` | Parallel journey execution |
| `e2e-testing` | End-to-end journey execution |
| `e2e-validate` | End-to-end validation orchestration |
| `create-validation-plan` | Validation plan generation |

### Operational (5)

| Skill | Purpose |
|-------|---------|
| `baseline-quality-assessment` | Baseline quality measurement |
| `condition-based-waiting` | Smart wait conditions for async operations |
| `error-recovery` | Graceful error recovery during validation |
| `production-readiness-audit` | Ship/no-ship production audit |
| `full-functional-audit` | Comprehensive functional audit |

### Forge Orchestration (5)

| Skill | Purpose |
|-------|---------|
| `forge-setup` | Project initialization |
| `forge-plan` | Plan generation |
| `forge-execute` | Journey execution with fix loop |
| `forge-team` | Multi-agent team coordination |
| `forge-benchmark` | Posture benchmarking |

## Agents

Five agents handle distinct roles in the validation pipeline:

| Agent | Role | What It Does |
|-------|------|-------------|
| `platform-detector` | Detection | Analyzes the codebase to determine platform type (iOS, Web, API, CLI, Fullstack) with confidence scoring |
| `evidence-capturer` | Capture | Interacts with the real running system to capture screenshots, API responses, and logs as evidence files |
| `verdict-writer` | Judgment | Reviews evidence files skeptically and writes structured PASS/FAIL verdicts with specific citations |
| `validation-lead` | Orchestration | Decomposes validation scope into journey clusters, assigns to platform validators, aggregates results |
| `sweep-controller` | Fix Loop | Manages the autonomous fix-and-revalidate cycle, tracking attempts per journey and enforcing the 3-strike limit |

## Hooks

Seven hook scripts enforce validation discipline at runtime through Claude Code's hook system:

| Hook | Trigger | Purpose |
|------|---------|---------|
| `block-test-files.js` | PreToolUse (Write, Edit, MultiEdit) | Blocks creation of test, mock, stub, and fixture files |
| `evidence-gate-reminder.js` | PreToolUse (TaskUpdate) | Injects evidence checklist when marking tasks complete |
| `validation-not-compilation.js` | PostToolUse (Bash) | Reminds that build success output is not functional validation |
| `completion-claim-validator.js` | PostToolUse (Bash) | Catches completion claims that lack evidence citations |
| `validation-state-tracker.js` | PostToolUse (Bash) | Detects validation command execution and reminds about evidence capture |
| `mock-detection.js` | PostToolUse (Edit, Write, MultiEdit) | Detects mock/stub patterns in written code |
| `evidence-quality-check.js` | PostToolUse (Edit, Write, MultiEdit) | Warns when evidence files are empty (0-byte) |

Hook scripts receive tool call JSON on stdin and communicate back to Claude Code via exit codes and stderr/stdout. See [ARCHITECTURE.md](ARCHITECTURE.md) for the hook protocol.

## Configuration

Three enforcement levels in `config/`:

### Strict (`config/strict.json`)

Maximum enforcement. All hooks enabled, all gates required. Blocks test files, requires evidence for every completion, requires validation plans and preflight, requires screenshot review. Max 3 recovery attempts.

### Standard (`config/standard.json`)

Balanced enforcement. Blocks test files and mock patterns, requires evidence on completion, but does not require validation plans, preflight, or baseline before starting. Max 3 recovery attempts.

### Permissive (`config/permissive.json`)

Minimal enforcement for teams transitioning from unit tests. Hooks emit warnings instead of blocking. Test file creation is allowed. No evidence required on completion. Max 5 recovery attempts.

Setup config is stored at `~/.claude/.vf-config.json` after running `/vf-setup`.

## Evidence Structure

All evidence goes to `e2e-evidence/` with sequential naming:

```
e2e-evidence/
  {journey-slug}/
    step-01-{description}.png
    step-02-{description}.json
    step-03-{description}.txt
    evidence-inventory.txt
  report.md
```

Rules:
- Screenshots must describe what is visible, not just that a file exists
- API responses must include body AND headers, not just status codes
- Build output must quote the actual success/failure line
- Console logs must include timestamps
- Empty (0-byte) files are invalid evidence -- the `evidence-quality-check` hook catches these
- Each validation run captures fresh evidence; previous evidence is never reused

For team validation, each validator owns its evidence subdirectory exclusively:

```
e2e-evidence/
  web/       ← Web Validator only
  api/       ← API Validator only
  ios/       ← iOS Validator only
  design/    ← Design Validator only
  report.md  ← Verdict Writer only
```

## Integration Guides

Using ValidationForge with OMC, ECC, and Superpowers — see [integrations/README.md](integrations/README.md) for the hub.

## Contributing

ValidationForge is MIT licensed. Contributions welcome.

1. Fork the repository
2. Create a feature branch
3. Make changes -- ensure hooks pass, no test files introduced
4. Submit a pull request with evidence of the change working

Key directories:
- `skills/` -- Each skill is a directory with a `SKILL.md` file
- `commands/` -- Slash command definitions as markdown with YAML frontmatter
- `hooks/` -- Node.js hook scripts wired via `hooks/hooks.json`
- `agents/` -- Agent definitions as markdown
- `rules/` -- Rule files copied to `~/.claude/rules/` on install
- `config/` -- Enforcement level presets
