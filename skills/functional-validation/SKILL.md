---
name: functional-validation
description: "Build & validate real systems (iOS, Web, API, CLI, fullstack)—never mocks or test files. Capture evidence from browser, simulator, CLI, cURL. Platform detection, 4-step protocol, verdict with evidence."
context_priority: critical
---

# Functional Validation Protocol

## Scope

This skill handles: the complete validation protocol from build to verdict.
Does NOT handle: mock blocking (use `no-mocking-validation-gates`), evidence examination at completion (use `gate-validation-discipline`), validation planning (use `create-validation-plan`).

## The Iron Rule

```
NEVER create mocks, stubs, test doubles, or test files.
NEVER import jest, vitest, pytest, XCTest, or any test framework.
ALWAYS validate through the same interfaces real users experience.
ALWAYS capture evidence that proves the feature works end-to-end.
```

## Before You Validate

1. **Is the real system running?** (not a dev server with mocks)
2. **Can I access it as a user would?** (browser, simulator, CLI — not a test harness)
3. **Are all dependencies real?** (real DB, real API keys, real network)
4. **Do I have PASS criteria written down?** (specific, observable, measurable)
5. **Am I capturing evidence to files?** (not just observing in terminal)

## Platform Detection

Detect the platform FIRST. Wrong platform = wrong validation approach.

| Priority | Platform | Indicators | Approach | Reference |
|----------|----------|-----------|----------|-----------|
| 1 | iOS/macOS | `*.xcodeproj`, `Package.swift` | Xcode build, simulator, idb/simctl | skill: `ios-validation` |
| 2 | Web | `package.json` + React/Vue/Next | Dev server, browser, Playwright MCP | skill: `web-validation` |
| 3 | CLI | `main.go`, `Cargo.toml`, `cli.py` | Build binary, execute, capture stdout | skill: `cli-validation` |
| 4 | API | `server.ts`, `app.py` + routes | Start server, curl endpoints | skill: `api-validation` |
| 5 | Full-Stack | Frontend + Backend present | Bottom-up: DB -> API -> Frontend | skill: `fullstack-validation` |

## The 4-Step Protocol

### Step 1: Build & Launch
Build the real system with all real dependencies. If the build fails, that IS your first finding.

### Step 2: Exercise Through UI
Interact as a real user would — browser, simulator, CLI binary, or curl. No REPL imports, no direct function calls.

### Step 3: Capture Evidence
Save to `e2e-evidence/` — screenshots, response bodies, CLI output, logs. Evidence must be READ and DESCRIBED, not just confirmed to exist.

### Step 4: Write Verdict
For each criterion, cite specific evidence with file paths and quoted content.

For platform-specific commands for all 4 steps, see `references/evidence-capture-commands.md`.
For common failure patterns and debugging, see `references/common-failure-patterns.md`.

## Multi-Platform Validation Order

For full-stack apps, validate bottom-up. Each layer must PASS before testing above it.

```
Database/Infra (validate FIRST) -> Business Logic -> API Endpoints -> Frontend UI (validate LAST)
```

Why: If the DB is broken, every API test fails with misleading errors.

## Verdict Format

```markdown
### Criterion: [What was required]
**PASS** / **FAIL**
Evidence: `e2e-evidence/[file]` — [What I actually saw, quoted specifically]
```

For evidence quality standards (good vs bad by platform) and the full verdict template,
see `references/quick-reference-card.md`.

## Security Policy

This skill executes real systems for validation. It never introduces new functionality,
never disables security checks, and never bypasses auth — it validates through the
same security boundaries real users encounter.

## Related Skills

- `gate-validation-discipline` — Evidence examination before completion claims
- `no-mocking-validation-gates` — Mock detection and test file blocking
- `e2e-validate` — Multi-step end-to-end validation flows
- `create-validation-plan` — Structured validation plan generation
- `preflight` — Prerequisites check before starting validation
- `ios-validation`, `web-validation`, `api-validation`, `cli-validation`, `fullstack-validation` — Platform-specific validation

## Resources

- `team-adoption-guide.md` — Onboarding guide for teams adopting the functional validation protocol; covers tooling setup, workflow integration, and cultural practices for evidence-based validation
