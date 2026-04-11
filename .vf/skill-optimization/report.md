# Skill Optimization Report

**Scope:** 48 VF skills in `skills/`
**Applied:** 48
**Skipped:** 0

---

## accessibility-audit

**Before:**
```
Deep WCAG 2.1 AA accessibility audit with Lighthouse, keyboard navigation, and screen reader validation
```

**After:**
```
Audit WCAG 2.1 AA compliance across 4 layers: Lighthouse automated scan, keyboard navigation, screen reader tree structure, and color contrast. Use before public release, after UI changes, or when a11y complaints arise. Tools: Lighthouse, Chrome DevTools.
```

---

## ai-evidence-analysis

**Before:**
```
AI-powered analysis of validation evidence using vision models for screenshots and LLM analysis for API responses and CLI output. Produces confidence scores (0-100) and structured findings per evidence item to augment human review.
```

**After:**
```
AI-augmented evidence review: vision models analyze screenshots for completeness, LLMs check API responses and CLI output against expected patterns. Produces 0-100 confidence scores and finding lists. Use after capture, before verdict. Optional (disabled in offline/air-gapped).
```

---

## api-validation

**Before:**
```
API platform validation through direct HTTP requests (curl). Captures full response bodies, headers, and status codes as evidence. Tests CRUD operations, authentication flows, error responses, pagination, and rate limiting.
```

**After:**
```
Validate APIs via curl: health checks, CRUD cycles (create/read/update/delete), auth (token, 401/403 errors), error responses, pagination. Capture full JSON bodies and status codes. Use when API changes, before API-dependent features deploy, or on integration issues.
```

**Triggers added:** api testing, curl validation, api contract, endpoint verification, HTTP status codes

---

## baseline-quality-assessment

**Before:**
```
Establishes a quality baseline before making changes. Captures current state evidence so post-change validation can prove improvement without regression.
```

**After:**
```
Capture immutable 'before' evidence (journeys, features, endpoints, screens) before code changes. Proves changes improved targets without regressing existing functionality. Use for refactor, migration, dependency update, bug fix. Baseline detects pre-existing bugs vs. regressions.
```

**Triggers added:** baseline capture, before-after comparison, regression detection, no-regressions proof, change impact

---

## build-quality-gates

**Before:**
```
Multi-stage build quality enforcement — compile, lint, type-check, bundle analysis
```

**After:**
```
4-stage build pipeline: compile (errors only), lint (style rules), type-check (typed langs), bundle (size/deps). Each gate PASS required before next. Build gates are necessary NOT sufficient—functional validation still required. Use pre-deploy, pre-PR, when builds fail.
```

---

## chrome-devtools

**Before:**
```
Chrome DevTools MCP integration for deep browser inspection and evidence capture
```

**After:**
```
Deep browser inspection via Chrome DevTools MCP: performance profiling (Core Web Vitals), Lighthouse audits (a11y/SEO/best practices), network inspection (headers/payloads/timing), console monitoring, memory snapshots. Use for debugging, perf analysis, a11y audits. Complements Playwright.
```

---

## cli-validation

**Before:**
```
CLI platform validation through direct binary execution. Captures stdout, stderr, exit codes, and pipe behavior as evidence. Validates happy paths, error handling, and output format correctness.
```

**After:**
```
Validate CLI binaries: build, help/version output, happy path execution, error cases (bad flags, missing args, file not found), exit codes, stdin/pipe, output format (JSON/CSV parsing). Capture full stdout/stderr. Use on all binary changes, before release, on CLI behavior regression.
```

**Triggers added:** binary validation, CLI testing, exit code verification, command-line tool, stderr/stdout capture

---

## condition-based-waiting

**Before:**
```
Smart waiting strategies for async operations during validation. Waits for specific conditions rather than arbitrary sleep durations. Every wait has a timeout, a condition, and a failure path.
```

**After:**
```
Wait for conditions, not time: HTTP health polls, port availability, file existence, process readiness, browser content, iOS simulator boot, DB ready, log patterns. Every wait must timeout (30–90s). Captures diagnostic state on failure. Never use bare sleep.
```

**Triggers added:** wait for server, async operation, service readiness, health check polling, timeout handling

---

## coordinated-validation

**Before:**
```
Multi-platform validation with dependency-aware execution. Validates platforms in dependency order (DB→API→Web, DB→API→iOS), runs independent platforms in parallel, blocks dependent platforms when dependencies fail, and coordinates evidence into a unified cross-platform report.
```

**After:**
```
Multi-platform validation respecting cross-platform dependencies: DB→API→Web/iOS. Parallelizes independent layers, blocks downstream when dependencies fail, coordinates evidence waves, prevents race conditions. Use for fullstack projects, mobile+API integration, CI/CD multi-layer verification.
```

---

## create-validation-plan

**Before:**
```
Generates a structured validation plan with PASS criteria for every user journey before any evidence is captured. Plans define what success looks like upfront.
```

**After:**
```
Create BEFORE evidence capture. Defines PASS criteria per journey (P0/P1/P2 priority). Maps routes/endpoints/screens, orders by dependency, checks prerequisites. Use when starting validation, refining journeys, or validating changes. Falsifiable criteria only — no vague goals.
```

**Triggers added:** validation plan generation, journey discovery, pass criteria definition, validation strategy planning, upfront planning before execution

---

## design-token-audit

**Before:**
```
Verify CSS and Tailwind tokens match the project's design system specification
```

**After:**
```
Audit CSS/Tailwind/inline styles against design system spec (DESIGN.md, tailwind.config, CSS vars). Detects hardcoded values, off-palette colors, non-standard spacing, typography drift. Use after style changes, before release, during DS migration, on new codebases.
```

---

## design-validation

**Before:**
```
Validate implementation fidelity against design specifications and Stitch-generated references
```

**After:**
```
Compare implementation screenshots against design refs (Stitch MCP, DESIGN.md, Figma). Scores colors, typography, spacing, layout, interactions (5-category fidelity). Use after UI implementation, before release, during design reviews, post-refactor for visual regressions.
```

---

## django-validation

**Before:**
```
Django and Flask web application validation through server startup, database migration verification, curl endpoint testing, and Django admin checks. Captures HTTP responses, migration status, and server logs as evidence.
```

**After:**
```
Django/Flask validation: dependencies → system check → migrations → server startup → health/CRUD endpoints (GET/POST/PUT/DELETE) → auth flows → admin check. Uses curl, capture HTTP responses/migrations/logs. Also Flask+Gunicorn.
```

**Triggers added:** django framework testing, flask validation, django server check, migration validation, django endpoint testing

---

## e2e-testing

**Before:**
```
End-to-end validation patterns — journey design, evidence management, flaky flow handling
```

**After:**
```
E2E strategy patterns: design journeys (one goal per journey, precondition→action→assertion). Manage evidence (step-NN naming, inventory). Diagnose flaky flows (3 runs, capture delta, fix root cause). Use for journey planning, handling intermittent failures, organizing cross-journey artifacts.
```

---

## e2e-validate

**Before:**
```
Full end-to-end validation orchestrator. Detects platform, maps user journeys, defines PASS criteria, captures evidence, writes PASS/FAIL verdicts. Zero mocks. Supports iOS, React Native, Flutter, web, API, CLI, Django/Flask, and fullstack projects.
```

**After:**
```
Orchestrator: detect platform → map journeys → PASS criteria → capture evidence → write verdicts (zero mocks). Platform detection (iOS/RN/Flutter/web/API/CLI/Django/fullstack), bottom-up fullstack order, fix loop (3-strike). Use for any project validation start-to-finish.
```

**Triggers added:** end to end validation, full validation pipeline, orchestrate validation, platform detection, validation orchestration

---

## error-recovery

**Before:**
```
Structured 3-strike error recovery during validation. When validation fails, diagnoses root cause, applies fix, and re-validates. Use when any validation step fails, builds break, runtime crashes, or network/auth/database errors occur.
```

**After:**
```
3-strike recovery: strike 1 (targeted fix, same step), strike 2 (alt tool/path), strike 3 (rethink assumptions, broader fix). Never mock; fix real cause. Use on build fails, runtime crashes, network/auth/DB errors, flaky flows. Log all 3 attempts.
```

**Triggers added:** error recovery protocol, fix validation failures, 3 strike protocol, recover from failure, diagnose root cause

---

## flutter-validation

**Before:**
```
Flutter platform validation through dependency installation, build, device launch, and screenshot capture via flutter screenshot. Captures logs, widget trees, and crash output as validation evidence across Android and iOS targets.
```

**After:**
```
Validate Flutter apps on real Android/iOS devices: install deps, build, launch, capture screenshots, check logs for crashes. Use for any flutter project before release; covers both emulators and physical devices.
```

---

## forge-benchmark

**Before:**
```
Measure validation posture across five dimensions. Track trends over time and compare against baseline targets.
```

**After:**
```
Score validation posture: Coverage (30%), Detection (25%), Evidence Quality (25%), Speed (10%), Cost (10%). Use after validation runs to measure trends, benchmark against baselines, and identify gaps in journeys or evidence.
```

---

## forge-execute

**Before:**
```
Autonomous validation execution loop. Runs journeys against the real system, captures per-attempt evidence in isolated directories, fixes failures with rebuild-then-revalidate, and persists state to forge-state.json after every phase transition and strike.
```

**After:**
```
Run validation journeys with autonomous fix loop: execute, capture evidence, analyze failures, rebuild, re-execute (max 3 strikes). Use after plan exists; maintains attempt history and strike tracking in isolated directories.
```

---

## forge-plan

**Before:**
```
Generate a validation plan with journey discovery, PASS criteria, and evidence requirements. Supports quick, standard, and consensus planning modes.
```

**After:**
```
Create validation plan by discovering journeys, defining PASS criteria per step, and specifying evidence types. Use quick mode for small projects, standard for medium, consensus for critical/multi-team review.
```

---

## forge-setup

**Before:**
```
Initialize ValidationForge for a project. Detects platforms, scaffolds directories, installs enforcement hooks, and configures validation posture.
```

**After:**
```
Set up ValidationForge: detect platforms, scaffold directories (.validationforge/, e2e-evidence/), install rules, configure enforcement (strict/standard/permissive). Run first to initialize any new project.
```

---

## forge-team

**Before:**
```
Multi-agent parallel validation. Spawns platform-specific validators that work in parallel with strict evidence directory ownership.
```

**After:**
```
Parallel multi-platform validation with wave-based dependencies: DB/Design → API → Web/iOS. Each validator owns isolated evidence directory. Use for fullstack projects; blocks downstream platforms on upstream failure.
```

---

## full-functional-audit

**Before:**
```
Read-only validation audit that captures evidence and writes findings without making any code changes. Produces a severity-classified audit report.
```

**After:**
```
Audit project health without code changes: exercise all features, capture evidence, classify findings by severity (CRITICAL/HIGH/MEDIUM/LOW/INFO). Use for pre-release gates, compliance reviews, or baseline assessments.
```

---

## fullstack-validation

**Before:**
```
Fullstack validation using strict bottom-up approach: Database -> API -> Frontend. Validates each layer independently, then tests integration across the entire stack. References api-validation and web-validation skills for layer-specific procedures.
```

**After:**
```
Validate fullstack bottom-up: DB schema/data → API CRUD → Frontend rendering → integration (create→read→update→delete across all layers). Use for any multi-layer project; proves data flows correctly end-to-end.
```

---

## functional-validation

**Before:**
```
Enforces end-user perspective validation through real system execution. Never write mocks or test files. Validate via simulator, browser, CLI, or cURL. Covers iOS, Web, API, CLI, and Full-Stack with evidence-based PASS/FAIL.
```

**After:**
```
Build & validate real systems end-to-end (iOS, Web, API, CLI, fullstack)—never mocks or test files. Capture evidence from browser, simulator, CLI, or cURL. Platform detection, 4-step protocol, verdict format with evidence citations. Use even when slowness tempts shortcuts.
```

---

## gate-validation-discipline

**Before:**
```
Enforces evidence-based validation before marking any gate, task, or checkpoint complete. Requires personal examination of evidence, specific proof citations, and evidence-to-criteria matching. Prevents premature completion claims.
```

**After:**
```
EVIDENCE BEFORE COMPLETION—never mark gates/tasks done without reading actual evidence, citing specific proof, matching evidence to criteria. Personal examination required; delegate reports but verify findings yourself. Use before any checkpoint.
```

**Triggers added:** evidence examination, before completion, verify gate, checkpoint validation, proof citation

---

## ios-simulator-control

**Before:**
```
iOS Simulator lifecycle management — boot, install, launch, screenshot, logs, reset
```

**After:**
```
iOS Simulator operations: boot, install, launch, screenshot, video, logs, deep links, permissions, location, crash detection. Reference for evidence capture commands. Use with all iOS validation skills. Also covers status bar override, app container access.
```

---

## ios-validation

**Before:**
```
iOS/macOS platform validation through Xcode build, simulator launch, and real device interaction via simctl and idb. Captures screenshots, video, and accessibility tree as validation evidence.
```

**After:**
```
iOS/macOS validation: Xcode build → simulator install/launch → screenshot/video/logs/deep links/idb accessibility tree. 9-step protocol from build through crash detection. Evidence quality standards. Use for all iOS feature validation. Also covers simulator prerequisites.
```

**Triggers added:** ios feature validation, xcode build simulator, ios ui testing, deep link validation, ios accessibility testing

---

## ios-validation-gate

**Before:**
```
Three-gate iOS validation — Simulator, Backend, Analysis — all must PASS
```

**After:**
```
Three-gate iOS enforcement: Simulator (build/install/launch/screenshot/a11y), Backend (health/endpoints/responses), Analysis (logs/behavior correlation). ALL gates must PASS. Use after each iOS feature. Also covers skip conditions for offline apps.
```

---

## ios-validation-runner

**Before:**
```
Five-phase iOS validation with video recording, log streaming, and evidence collection
```

**After:**
```
Five-phase iOS protocol: SETUP (boot sim) → RECORD (video+logs) → ACT (user interaction) → COLLECT (artifacts) → VERIFY (verdict). Complex multi-step flows & debug scenarios. Video proves temporal evidence screenshots miss. Kill -INT not -9.
```

---

## no-mocking-validation-gates

**Before:**
```
Enforces the Iron Rule: never create mocks, stubs, test doubles, or test files. Detects mock-creation intent and redirects to real system validation. Works with pre-tool-use hooks to block test file creation at the enforcement layer.
```

**After:**
```
THE IRON RULE: no mocks/stubs/test files—hook blocks *.test.ts, __tests__/, jest.mock(), etc. When mocking tempts: diagnose why real system unavailable, fix it, validate real system instead. Redirect 12+ thought patterns to real validation.
```

**Triggers added:** block test file, mock detection, prevent mocking, test double elimination, real system validation redirect

---

## parallel-validation

**Before:**
```
Orchestrate multiple validation agents in parallel across independent journeys or platforms
```

**After:**
```
Multi-agent parallel validation—iOS+Web+API simultaneously on independent journeys. Strict file ownership rules prevent conflicts. Verdict aggregation: any FAIL=FAIL. Use for large apps, CI/CD, multi-platform. Sequential-only: auth→pages, create→read→update.
```

---

## playwright-validation

**Before:**
```
Browser-based validation using Playwright MCP — real browser interaction, evidence capture
```

**After:**
```
Validate web features through real browser interaction with Playwright MCP. Use for feature verification, screenshot evidence, form testing, responsive layouts, and console error detection. Captures DOM snapshots and network logs.
```

---

## preflight

**Before:**
```
Pre-execution checklist before starting any validation. Ensures prerequisites are met: servers running, databases seeded, tools available. Auto-fixes common failures. Saves preflight report to e2e-evidence/.
```

**After:**
```
Run before validation to catch missing dependencies, dead servers, unseeded databases upfront. Detects platform, auto-fixes common failures (services, configs), produces CLEAR/BLOCKED/WARN verdict. Prevents 10-30min debugging mid-validation.
```

---

## production-readiness-audit

**Before:**
```
Systematic audit of application readiness for production deployment
```

**After:**
```
Audit app readiness across 8 phases: code quality, security, performance, reliability, observability, documentation, deployment. Use before first deploy, major releases, significant refactors. Produces READY/NOT READY/CONDITIONAL verdict with blocking issues.
```

---

## react-native-validation

**Before:**
```
React Native platform validation through Metro bundler startup, Expo/RN CLI build and launch, screenshot capture, log streaming, and deep link testing. Validates both iOS and Android targets via simulator/emulator or real device.
```

**After:**
```
Validate React Native apps via Metro/Expo with platform-specific build, launch, screenshots, logs, and deep link testing. Use for iOS/Android feature validation, launch verification, crash detection. Covers Expo Go, Expo CLI, and bare RN projects.
```

---

## research-validation

**Before:**
```
Research standards, best practices, and tools before designing validation strategies
```

**After:**
```
Research applicable standards, tools, and best practices before planning validation (Phase 0). Use entering new domains, when standards change, or deciding coverage. Maps standards to skills, produces research report feeding into validation planning.
```

---

## responsive-validation

**Before:**
```
Systematic viewport matrix testing with device-specific validation checks
```

**After:**
```
Validate layouts across 8 device viewports (375px–1920px). Use after responsive redesigns, mobile launches, CSS refactors, or user-reported breakpoint issues. Tests layout, touch targets, typography, content parity, orientation, overflow at each breakpoint.
```

---

## retrospective-validation

**Before:**
```
Validate methodologies and approaches using historical evidence and past results
```

**After:**
```
Assess whether validation methodology actually worked by analyzing past results, deployments, incidents. Use post-sprint, pre/post approach changes, or after production issues. Calculates false PASS/FAIL rates, revert frequency, confidence score, and recommends process changes.
```

---

## rust-cli-validation

**Before:**
```
Rust CLI platform validation through cargo toolchain and direct binary execution. Runs cargo check, clippy, release build, and binary execution with real inputs. Captures stdout, stderr, exit codes, and pipe behavior as evidence. Validates compilation correctness, lint cleanliness, happy paths, error handling, and output format correctness.
```

**After:**
```
Validate Rust CLI apps via cargo toolchain: check, clippy, release build, binary execution. Use for Rust tool feature validation, panic detection, exit code verification, happy/error paths. Captures help, version, output, error messages, and exit codes as evidence.
```

---

## sequential-analysis

**Before:**
```
Systematic root cause analysis for validation failures using step-by-step reasoning
```

**After:**
```
Root cause analysis for FAIL verdicts using structured hypothesis testing & sequential thinking. Use when validation fails unexpectedly, error messages are ambiguous, or multiple journeys share common causes. Evidence-backed investigation produces documented recommendations & prevention strategies.
```

---

## stitch-integration

**Before:**
```
Stitch MCP workflow for design generation, iteration, and design-to-code validation
```

**After:**
```
Generate reference designs via Stitch MCP, iterate variants, capture as evidence for design-validation. Use when starting UI features, exploring design options before code, or validating implementation fidelity. Bridges design-to-code via project persistence, design system tokens, and variant generation.
```

---

## team-validation-dashboard

**Before:**
```
Aggregate team validation posture into a shared dashboard. Shows coverage, posture scores, regression trends, and ownership assignments across all registered projects.
```

**After:**
```
Aggregate validation metrics across projects into shared dashboard: posture scores, coverage %, regressions, ownership. Use to identify critical projects (score <60), review team validation posture, track regressions over time, assign journey owners. Also for CI/CD metric reporting.
```

**Triggers added:** team dashboard, validation posture, show team metrics, which projects need attention, who owns this journey

---

## validate-audit-benchmarks

**Before:**
```
Run automated benchmark suite to score hook correctness, skill/command structural integrity, and aggregate quality metrics.
```

**After:**
```
Score ValidationForge primitives: hooks (60% weight), skill structure (20%), command structure (20%). Run before releases, after modifications, or during audits. Produces baseline metrics, grades A–F, compares against previous benchmarks. 10 high-impact skills prioritized for manual review.
```

**Triggers added:** audit benchmarks, run benchmark suite, score hook correctness, validate primitives, quality metrics

---

## verification-before-completion

**Before:**
```
Prevents premature completion claims by requiring personally examined evidence, specific citations, and criteria matching before marking any task complete. Use whenever completing tasks, closing gates, reporting to leads, or merging code.
```

**After:**
```
Block premature completion claims: require personally examined evidence, specific citations (file paths, line numbers, screenshots), criteria-to-evidence matching, regression checks, final state capture. Use before TaskUpdate completed, gate closure, lead reports, code merge. Never skip verification steps.
```

**Triggers added:** verification before completion, complete task, close gate, mark done, evidence checklist, can i ship this

---

## visual-inspection

**Before:**
```
Evidence-based visual inspection of running UIs — captures what IS, not what SHOULD BE
```

**After:**
```
Capture & describe actual rendered UI state via screenshots across breakpoints, modes, & edge cases. Use before claiming frontend work complete, validating responsive layouts, checking dark/light modes, testing empty/error/loading states. Severity-classified findings prevent invisible text, overlapping elements, layout overflow issues.
```

---

## web-testing

**Before:**
```
Comprehensive web validation strategy — integration, E2E, accessibility, performance, security
```

**After:**
```
5-layer web validation: integration (APIs), E2E (user journeys), accessibility (WCAG), performance (Core Web Vitals), security (OWASP). Use when planning comprehensive web feature validation, determining validation types needed, building validation plans. All validation against real running systems—no mocks.
```

---

## web-validation

**Before:**
```
Web platform validation through browser automation (Playwright MCP or Chrome DevTools MCP). Captures screenshots, console logs, network responses, and DOM snapshots as evidence.
```

**After:**
```
Web validation via browser automation: health checks, screenshots at breakpoints (375/768/1920px), form testing (valid/invalid), console/network/route validation. Captures DOM snapshots & error logs. Also detects CORS, hydration, CSS issues. PASS criteria include no console errors, <3s load time.
```

**Triggers added:** web validation, browser automation, playwright validation, web testing, validate web app, screenshot test

---
