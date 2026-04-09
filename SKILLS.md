# ValidationForge Skills Index

45 skills across 7 categories. All skills use Claude Code SKILL.md frontmatter for discovery.

## Platform Validation (15)

| # | Skill | Description |
|---|-------|-------------|
| 1 | `ios-validation` | iOS/macOS platform validation through Xcode build, simulator launch, and real device interaction via simctl and idb. Captures screenshots, video, and accessibility tree as evidence. |
| 2 | `ios-validation-gate` | Three-gate iOS validation -- Simulator, Backend, Analysis -- all must PASS |
| 3 | `ios-validation-runner` | Five-phase iOS validation with video recording, log streaming, and evidence collection |
| 4 | `ios-simulator-control` | iOS Simulator lifecycle management -- boot, install, launch, screenshot, logs, reset |
| 5 | `playwright-validation` | Browser-based validation using Playwright MCP -- real browser interaction, evidence capture |
| 6 | `web-validation` | Web platform validation through browser automation (Playwright MCP or Chrome DevTools MCP). Captures screenshots, console logs, network responses, and DOM snapshots as evidence. |
| 7 | `web-testing` | Comprehensive web validation strategy -- integration, E2E, accessibility, performance, security |
| 8 | `chrome-devtools` | Chrome DevTools MCP integration for deep browser inspection and evidence capture |
| 9 | `api-validation` | API platform validation through direct HTTP requests (curl). Captures full response bodies, headers, and status codes. Tests CRUD operations, authentication flows, error responses, pagination, and rate limiting. |
| 10 | `cli-validation` | CLI platform validation through direct binary execution. Captures stdout, stderr, exit codes, and pipe behavior as evidence. Validates happy paths, error handling, and output format correctness. |
| 11 | `fullstack-validation` | Fullstack validation using strict bottom-up approach: Database -> API -> Frontend. Validates each layer independently, then tests integration across the entire stack. |
| 12 | `react-native-validation` | React Native platform validation through Metro bundler, iOS Simulator, and Android Emulator. Captures screenshots, JS console logs, and bridge errors as evidence. Validates navigation, state management, and native module integration. |
| 13 | `flutter-validation` | Flutter platform validation through flutter build and device/emulator execution. Captures screenshots, widget tree snapshots, and Dart console output as evidence. Validates widget rendering, navigation, and platform channel calls. |
| 14 | `django-validation` | Django/Flask platform validation through runserver and direct HTTP requests (curl). Captures response bodies, headers, and Django debug output as evidence. Validates views, forms, ORM queries, and REST endpoints. |
| 15 | `rust-cli-validation` | Rust CLI platform validation through cargo build and direct binary execution. Captures stdout, stderr, exit codes, and panic traces as evidence. Validates argument parsing, error handling, and output correctness. |

## Quality Gates (6)

| # | Skill | Description |
|---|-------|-------------|
| 16 | `functional-validation` | Enforces end-user perspective validation through real system execution. Never write mocks or test files. Validate via simulator, browser, CLI, or cURL. Covers iOS, Web, API, CLI, and Full-Stack with evidence-based PASS/FAIL. |
| 17 | `gate-validation-discipline` | Enforces evidence-based validation before marking any gate, task, or checkpoint complete. Requires personal examination of evidence, specific proof citations, and evidence-to-criteria matching. |
| 18 | `no-mocking-validation-gates` | Enforces the Iron Rule: never create mocks, stubs, test doubles, or test files. Detects mock-creation intent and redirects to real system validation. Works with pre-tool-use hooks to block test file creation. |
| 19 | `build-quality-gates` | Multi-stage build quality enforcement -- compile, lint, type-check, bundle analysis |
| 20 | `verification-before-completion` | Prevents premature completion claims by requiring personally examined evidence, specific citations, and criteria matching before marking any task complete. |
| 21 | `preflight` | Pre-execution checklist before starting any validation. Ensures prerequisites are met: servers running, databases seeded, tools available. Auto-fixes common failures. Saves preflight report to e2e-evidence/. |

## Design Validation (4)

| # | Skill | Description |
|---|-------|-------------|
| 22 | `design-validation` | Validate implementation fidelity against design specifications and Stitch-generated references |
| 23 | `design-token-audit` | Verify CSS and Tailwind tokens match the project's design system specification |
| 24 | `stitch-integration` | Stitch MCP workflow for design generation, iteration, and design-to-code validation |
| 25 | `visual-inspection` | Evidence-based visual inspection of running UIs -- captures what IS, not what SHOULD BE |

## Analysis & Research (3)

| # | Skill | Description |
|---|-------|-------------|
| 26 | `sequential-analysis` | Systematic root cause analysis for validation failures using step-by-step reasoning |
| 27 | `research-validation` | Research standards, best practices, and tools before designing validation strategies |
| 28 | `retrospective-validation` | Validate methodologies and approaches using historical evidence and past results |

## Specialized (6)

| # | Skill | Description |
|---|-------|-------------|
| 29 | `accessibility-audit` | Deep WCAG 2.1 AA accessibility audit with Lighthouse, keyboard navigation, and screen reader validation |
| 30 | `responsive-validation` | Systematic viewport matrix testing with device-specific validation checks |
| 31 | `parallel-validation` | Orchestrate multiple validation agents in parallel across independent journeys or platforms |
| 32 | `e2e-testing` | End-to-end validation patterns -- journey design, evidence management, flaky flow handling |
| 33 | `e2e-validate` | Full end-to-end validation orchestrator. Detects platform, maps user journeys, defines PASS criteria, captures evidence, writes PASS/FAIL verdicts. Zero mocks. Supports iOS, web, API, CLI, and fullstack projects. |
| 34 | `create-validation-plan` | Generates a structured validation plan with PASS criteria for every user journey before any evidence is captured. Plans define what success looks like upfront. |

## Operational (5)

| # | Skill | Description |
|---|-------|-------------|
| 35 | `baseline-quality-assessment` | Establishes a quality baseline before making changes. Captures current state evidence so post-change validation can prove improvement without regression. |
| 36 | `condition-based-waiting` | Smart waiting strategies for async operations during validation. Waits for specific conditions rather than arbitrary sleep durations. Every wait has a timeout, a condition, and a failure path. |
| 37 | `error-recovery` | Structured 3-strike error recovery during validation. When validation fails, diagnoses root cause, applies fix, and re-validates. |
| 38 | `production-readiness-audit` | Systematic audit of application readiness for production deployment |
| 39 | `full-functional-audit` | Read-only validation audit that captures evidence and writes findings without making any code changes. Produces a severity-classified audit report. |

## Forge Orchestration (6)

| # | Skill | Description |
|---|-------|-------------|
| 40 | `forge-setup` | Initialize ValidationForge for a project. Detects platforms, scaffolds directories, installs enforcement hooks, and configures validation posture. |
| 41 | `forge-plan` | Generate a validation plan with journey discovery, PASS criteria, and evidence requirements. Supports quick, standard, and consensus planning modes. |
| 42 | `forge-execute` | Autonomous validation execution loop. Runs validation journeys against the real system, captures evidence, and fixes failures with re-validation. |
| 43 | `forge-team` | Multi-agent parallel validation. Spawns platform-specific validators that work in parallel with strict evidence directory ownership. |
| 44 | `forge-benchmark` | Measure validation posture across five dimensions. Track trends over time and compare against baseline targets. |
| 45 | `validate-audit-benchmarks` | Run automated benchmark suite to score hook correctness, skill/command structural integrity, and aggregate quality metrics. |
