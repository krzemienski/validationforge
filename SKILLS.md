# ValidationForge Skills Index

41 skills across 7 categories. All skills use Claude Code SKILL.md frontmatter for discovery. Skills are tiered by `context_priority` (critical / standard / reference) to stay within Claude Code's context window budget — see [Loading Strategy](#loading-strategy) below.

## Platform Validation (11)

| # | Skill | Priority | Description |
|---|-------|----------|-------------|
| 1 | `ios-validation` | standard | iOS/macOS platform validation through Xcode build, simulator launch, and real device interaction via simctl and idb. Captures screenshots, video, and accessibility tree as evidence. |
| 2 | `ios-validation-gate` | standard | Three-gate iOS validation -- Simulator, Backend, Analysis -- all must PASS |
| 3 | `ios-validation-runner` | standard | Five-phase iOS validation with video recording, log streaming, and evidence collection |
| 4 | `ios-simulator-control` | standard | iOS Simulator lifecycle management -- boot, install, launch, screenshot, logs, reset |
| 5 | `playwright-validation` | standard | Browser-based validation using Playwright MCP -- real browser interaction, evidence capture |
| 6 | `web-validation` | standard | Web platform validation through browser automation (Playwright MCP or Chrome DevTools MCP). Captures screenshots, console logs, network responses, and DOM snapshots as evidence. |
| 7 | `web-testing` | standard | Comprehensive web validation strategy -- integration, E2E, accessibility, performance, security |
| 8 | `chrome-devtools` | reference | Chrome DevTools MCP integration for deep browser inspection and evidence capture |
| 9 | `api-validation` | standard | API platform validation through direct HTTP requests (curl). Captures full response bodies, headers, and status codes. Tests CRUD operations, authentication flows, error responses, pagination, and rate limiting. |
| 10 | `cli-validation` | standard | CLI platform validation through direct binary execution. Captures stdout, stderr, exit codes, and pipe behavior as evidence. Validates happy paths, error handling, and output format correctness. |
| 11 | `fullstack-validation` | standard | Fullstack validation using strict bottom-up approach: Database -> API -> Frontend. Validates each layer independently, then tests integration across the entire stack. |

## Quality Gates (6)

| # | Skill | Priority | Description |
|---|-------|----------|-------------|
| 12 | `functional-validation` | critical | Enforces end-user perspective validation through real system execution. Never write mocks or test files. Validate via simulator, browser, CLI, or cURL. Covers iOS, Web, API, CLI, and Full-Stack with evidence-based PASS/FAIL. |
| 13 | `gate-validation-discipline` | critical | Enforces evidence-based validation before marking any gate, task, or checkpoint complete. Requires personal examination of evidence, specific proof citations, and evidence-to-criteria matching. |
| 14 | `no-mocking-validation-gates` | critical | Enforces the Iron Rule: never create mocks, stubs, test doubles, or test files. Detects mock-creation intent and redirects to real system validation. Works with pre-tool-use hooks to block test file creation. |
| 15 | `build-quality-gates` | standard | Multi-stage build quality enforcement -- compile, lint, type-check, bundle analysis |
| 16 | `verification-before-completion` | critical | Prevents premature completion claims by requiring personally examined evidence, specific citations, and criteria matching before marking any task complete. |
| 17 | `preflight` | critical | Pre-execution checklist before starting any validation. Ensures prerequisites are met: servers running, databases seeded, tools available. Auto-fixes common failures. Saves preflight report to e2e-evidence/. |

## Design Validation (4)

| # | Skill | Priority | Description |
|---|-------|----------|-------------|
| 18 | `design-validation` | standard | Validate implementation fidelity against design specifications and Stitch-generated references |
| 19 | `design-token-audit` | reference | Verify CSS and Tailwind tokens match the project's design system specification |
| 20 | `stitch-integration` | reference | Stitch MCP workflow for design generation, iteration, and design-to-code validation |
| 21 | `visual-inspection` | standard | Evidence-based visual inspection of running UIs -- captures what IS, not what SHOULD BE |

## Analysis & Research (3)

| # | Skill | Priority | Description |
|---|-------|----------|-------------|
| 22 | `sequential-analysis` | standard | Systematic root cause analysis for validation failures using step-by-step reasoning |
| 23 | `research-validation` | standard | Research standards, best practices, and tools before designing validation strategies |
| 24 | `retrospective-validation` | reference | Validate methodologies and approaches using historical evidence and past results |

## Specialized (6)

| # | Skill | Priority | Description |
|---|-------|----------|-------------|
| 25 | `accessibility-audit` | reference | Deep WCAG 2.1 AA accessibility audit with Lighthouse, keyboard navigation, and screen reader validation |
| 26 | `responsive-validation` | reference | Systematic viewport matrix testing with device-specific validation checks |
| 27 | `parallel-validation` | standard | Orchestrate multiple validation agents in parallel across independent journeys or platforms |
| 28 | `e2e-testing` | standard | End-to-end validation patterns -- journey design, evidence management, flaky flow handling |
| 29 | `e2e-validate` | critical | Full end-to-end validation orchestrator. Detects platform, maps user journeys, defines PASS criteria, captures evidence, writes PASS/FAIL verdicts. Zero mocks. Supports iOS, web, API, CLI, and fullstack projects. |
| 30 | `create-validation-plan` | standard | Generates a structured validation plan with PASS criteria for every user journey before any evidence is captured. Plans define what success looks like upfront. |

## Operational (5)

| # | Skill | Priority | Description |
|---|-------|----------|-------------|
| 31 | `baseline-quality-assessment` | standard | Establishes a quality baseline before making changes. Captures current state evidence so post-change validation can prove improvement without regression. |
| 32 | `condition-based-waiting` | standard | Smart waiting strategies for async operations during validation. Waits for specific conditions rather than arbitrary sleep durations. Every wait has a timeout, a condition, and a failure path. |
| 33 | `error-recovery` | standard | Structured 3-strike error recovery during validation. When validation fails, diagnoses root cause, applies fix, and re-validates. |
| 34 | `production-readiness-audit` | reference | Systematic audit of application readiness for production deployment |
| 35 | `full-functional-audit` | reference | Read-only validation audit that captures evidence and writes findings without making any code changes. Produces a severity-classified audit report. |

## Forge Orchestration (6)

| # | Skill | Priority | Description |
|---|-------|----------|-------------|
| 36 | `forge-setup` | critical | Initialize ValidationForge for a project. Detects platforms, scaffolds directories, installs enforcement hooks, and configures validation posture. |
| 37 | `forge-plan` | critical | Generate a validation plan with journey discovery, PASS criteria, and evidence requirements. Supports quick, standard, and consensus planning modes. |
| 38 | `forge-execute` | critical | Autonomous validation execution loop. Runs validation journeys against the real system, captures evidence, and fixes failures with re-validation. |
| 39 | `forge-team` | standard | Multi-agent parallel validation. Spawns platform-specific validators that work in parallel with strict evidence directory ownership. |
| 40 | `forge-benchmark` | reference | Measure validation posture across five dimensions. Track trends over time and compare against baseline targets. |
| 41 | `validate-audit-benchmarks` | reference | Run automated benchmark suite to score hook correctness, skill/command structural integrity, and aggregate quality metrics. |

---

## Loading Strategy

Skills are tiered into three priority levels to manage Claude Code's context window budget. Loading all 41 skills simultaneously would consume ~6,600 lines, crowding out user codebase context. The tiered approach keeps initial load under 2,000 lines while still making every skill available on demand.

### Critical — Always Loaded (~800 lines)

These 8 skills form the invariant core. They enforce the platform's foundational rules and are always present regardless of project type:

| # | Skill | Purpose |
|---|-------|---------|
| 12 | `functional-validation` | Core no-mock principle |
| 13 | `gate-validation-discipline` | Evidence-before-completion gate |
| 14 | `no-mocking-validation-gates` | Iron Rule enforcement |
| 16 | `verification-before-completion` | Premature-completion prevention |
| 17 | `preflight` | Pre-validation prerequisite check |
| 29 | `e2e-validate` | Main validation orchestrator |
| 36 | `forge-setup` | Project initialization |
| 37 | `forge-plan` | Validation planning |
| 38 | `forge-execute` | Execution loop |

**Load condition:** Loaded on every session start, regardless of project platform.

### Standard — Loaded on Platform Match (~1,100 lines)

These 22 skills are loaded when the platform detector identifies a matching project type. Platform detection runs during preflight and sets `DETECTED_PLATFORMS` in the session context.

| Trigger | Skills Loaded |
|---------|--------------|
| iOS detected | `ios-validation`, `ios-validation-gate`, `ios-validation-runner`, `ios-simulator-control` |
| Web detected | `playwright-validation`, `web-validation`, `web-testing` |
| API detected | `api-validation` |
| CLI detected | `cli-validation` |
| Fullstack detected | `fullstack-validation` |
| Build step present | `build-quality-gates` |
| Design spec present | `design-validation`, `visual-inspection` |
| Analysis phase | `sequential-analysis`, `research-validation` |
| Multi-agent run | `parallel-validation`, `forge-team` |
| Validation run | `e2e-testing`, `create-validation-plan` |
| Baseline requested | `baseline-quality-assessment`, `condition-based-waiting`, `error-recovery` |

**Load condition:** Loaded when the corresponding platform or phase is detected. Unload after the phase completes to reclaim context budget.

### Reference — Loaded on Explicit Invocation (~700 lines)

These 10 skills are highly specialized and only load when a command explicitly invokes them or a dependency chain requires them. They are never pre-loaded.

| # | Skill | Invoke Condition |
|---|-------|-----------------|
| 8 | `chrome-devtools` | `/chrome-devtools` command or deep browser inspection requested |
| 19 | `design-token-audit` | `/design-token-audit` command or token diff requested |
| 20 | `stitch-integration` | Stitch MCP present and design generation requested |
| 24 | `retrospective-validation` | `/retrospective` command or historical evidence review |
| 25 | `accessibility-audit` | `/accessibility-audit` command or WCAG review requested |
| 26 | `responsive-validation` | `/responsive-validation` or viewport matrix requested |
| 34 | `production-readiness-audit` | `/validate-ci` with production gate or deploy decision |
| 35 | `full-functional-audit` | `/validate-audit` command |
| 40 | `forge-benchmark` | `/validate-benchmark` command |
| 41 | `validate-audit-benchmarks` | `/validate-benchmark --audit` flag |

**Load condition:** Loaded only when explicitly invoked. Unloaded immediately after the invocation completes.
