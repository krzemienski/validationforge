---
name: e2e-validate
description: >
  Full end-to-end validation orchestrator. Detects platform, maps user journeys,
  defines PASS criteria, captures evidence, writes PASS/FAIL verdicts. Zero mocks.
  Supports iOS, React Native, Flutter, web, API, CLI, Django/Flask, and fullstack projects.
context_priority: critical
---

# ValidationForge: End-to-End Validation Orchestrator

## Scope

This skill handles: platform detection, journey mapping, PASS criteria definition, evidence capture and review, PASS/FAIL verdict writing, fix loops, and CI/CD report generation.
Does NOT handle: individual gate evidence examination (use `gate-validation-discipline`), mock pattern detection (use `no-mocking-validation-gates`), isolated plan generation (use `create-validation-plan`).

## Iron Rule

IF the real system doesn't work, FIX THE REAL SYSTEM.
NEVER create mocks, stubs, test doubles, or test files.
ALWAYS validate through the same interfaces real users experience.
ALWAYS capture evidence. ALWAYS review evidence. ALWAYS write verdicts.
Evidence you don't READ is evidence you don't HAVE.

See `no-mocking-validation-gates` for mock pattern detection and blocking rules.

## Platform Detection

Scan project root. First match wins.

| Priority | Signals | Platform | Primary Tool |
|----------|---------|----------|-------------|
| 1 | `.xcodeproj`, `.xcworkspace`, `Package.swift` | **ios** | xcrun simctl, Xcode MCP |
| 2 | `package.json` with `react-native` dep, `metro.config.js`, `app.json` | **react-native** | Expo CLI, Metro bundler, device/simulator |
| 3 | `pubspec.yaml`, `lib/main.dart`, `.dart` files | **flutter** | flutter run, flutter test, device/simulator |
| 4 | `Cargo.toml [[bin]]`, `go.mod + main.go`, `package.json "bin"` | **cli** | Terminal, exit codes |
| 5 | Backend routes WITHOUT frontend templates | **api** | curl, httpie |
| 6 | Frontend framework WITHOUT backend routes | **web** | Playwright, Chrome DevTools |
| 7 | `requirements.txt` + (`manage.py` OR `wsgi.py` OR `flask` import) | **django** | python manage.py, pytest, curl |
| 8 | Frontend AND backend in same project | **fullstack** | All tools, bottom-up |
| 9 | None of the above | **generic** | Adaptive |

Auto-detection script available in `scripts/detect-platform.sh`.

## Command Routing

| Flag | Effect | Workflow |
|------|--------|----------|
| (none) | Full pipeline: analyze → plan → approve → execute → report | `workflows/full-run.md` |
| `--analyze` | Scan codebase, detect platform, map journeys | `workflows/analyze.md` |
| `--plan` | Generate validation plan with PASS criteria | `workflows/plan.md` |
| `--execute` | Run the full validation pipeline | `workflows/execute.md` |
| `--fix` | Auto-fix failures + re-validate (3-strike) | `workflows/fix-and-revalidate.md` |
| `--audit` | Read-only validation, no code changes | `workflows/audit.md` |
| `--report` | Generate/export validation report | `workflows/report.md` |
| `--ci` | Non-interactive, no approval gates | `workflows/ci-mode.md` |

**Modifiers:** `--platform <type>` (override detection), `--scope <path>` (limit scope),
`--parallel` (sub-agents), `--verbose` (inline evidence).

## Validation Order

Always validate bottom-up: Data Layer → Backend API → Frontend Logic → UI/CLI.
Higher layers depend on lower layers. Start at the data layer to find causes, not symptoms.

## Platform References

| Platform | Reference | Key Commands |
|----------|-----------|-------------|
| ios | `references/ios-validation.md` | xcodebuild, simctl, idb, deep links |
| react-native | `references/react-native-validation.md` | Expo CLI, Metro bundler, device/simulator |
| flutter | `references/flutter-validation.md` | flutter run, flutter test, widget inspector |
| web | `references/web-validation.md` | Playwright, Chrome DevTools, responsive |
| api | `references/api-validation.md` | curl, auth flows, error cases |
| cli | `references/cli-validation.md` | Build, execute, exit codes |
| django | `references/django-validation.md` | python manage.py, pytest, curl |
| fullstack | `references/fullstack-validation.md` | Bottom-up: DB → API → Frontend |
| generic | `references/generic-validation.md` | Adaptive entry point discovery |

## Workflow Files

| Workflow | Phase | Purpose |
|----------|-------|---------|
| `workflows/research.md` | Research (Phase 0) | Standards gathering, validation criteria |
| `workflows/analyze.md` | Discovery | Platform detection, journey mapping |
| `workflows/plan.md` | Planning | PASS criteria, approval gate |
| `workflows/execute.md` | Execution | Evidence capture, review, verdicts |
| `workflows/fix-and-revalidate.md` | Repair | 3-strike protocol, re-validation |
| `workflows/audit.md` | Assessment | Read-only severity classification |
| `workflows/report.md` | Reporting | Report generation, export |
| `workflows/full-run.md` | Full Pipeline | End-to-end with approval gate |
| `workflows/ci-mode.md` | CI/CD | Non-interactive, exit codes |
| `workflows/ship.md` | Ship (Phase 6) | Production readiness audit, deploy decision |

## Success Criteria

Validation is complete ONLY when ALL are true:

1. Platform detected and all user journeys identified
2. PASS criteria defined for every journey BEFORE execution
3. Real system built AND running (not just "no errors")
4. Every journey exercised through real interfaces
5. Evidence captured AND read (content described, not just "exists")
6. Evidence matched to criteria with PASS/FAIL verdicts written
7. Failures diagnosed with root cause analysis
8. Report saved to `e2e-evidence/report.md`
9. Zero unreviewed evidence files

## Rules

1. Never skip platform detection — wrong platform = wrong validation approach
2. Never execute without a plan — PASS criteria must exist before evidence capture
3. Never claim PASS without cited evidence — see `gate-validation-discipline`
4. Always validate bottom-up for fullstack projects

## Security Policy

Evidence directories may contain screenshots of authenticated screens or API responses
with tokens. Store in `e2e-evidence/` (gitignored). Never commit evidence containing
credentials or PII to public repositories.

## Context Budget

All 41 ValidationForge skills total ~6,726 lines. Loading every skill simultaneously crowds
out the user's codebase in the context window. Skills are tiered by `context_priority` to
stay within a 2,000-line initial budget.

| Tier | context_priority | Load Policy | Line Budget |
|------|-----------------|-------------|-------------|
| Critical | `critical` | Always loaded — every validation run requires these | ~754 lines |
| Standard | `standard` | Load when matching platform detected or workflow phase entered | On demand |
| Reference | `reference` | Load only when explicitly invoked or required by a dependency | On demand |

**Do not eagerly load standard or reference skills.** Reference each skill by name in
instructions; load it only when the workflow actually reaches the phase that needs it.

## Related Skills

| Skill | Role in Pipeline | Priority | Load When |
|-------|-----------------|----------|-----------|
| `functional-validation` | Core protocol, referenced in all workflows | critical | Always |
| `gate-validation-discipline` | Evidence verification during verdict writing | critical | Always |
| `no-mocking-validation-gates` | Mock detection during analysis | critical | Always |
| `create-validation-plan` | Plan generation for `--plan` workflow | critical | Always |
| `verification-before-completion` | Pre-completion checklist | critical | Always |
| `preflight` | Environment checks before execution | critical | Always |
| `error-recovery` | Error handling during fix loop | critical | Always |
| `full-functional-audit` | Audit protocol for `--audit` workflow | standard | `--audit` flag |
| `baseline-quality-assessment` | Quality baseline during analysis | standard | Analysis phase |
| `condition-based-waiting` | Smart waits during evidence capture | standard | Execution phase |
