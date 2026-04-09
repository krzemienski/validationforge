---
name: e2e-validate
description: >
  Full end-to-end validation orchestrator. Detects platform, maps user journeys,
  defines PASS criteria, captures evidence, writes PASS/FAIL verdicts. Zero mocks.
  Supports iOS, web, API, CLI, and fullstack projects.
context_priority: critical
---

# ValidationForge: End-to-End Validation Orchestrator

## Scope

Primary entry point for the entire ValidationForge pipeline. Routes to specialized
workflows based on parsed intent. Applies to any project type — auto-detects platform
and selects appropriate validation strategy.

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
| 2 | `Cargo.toml [[bin]]`, `go.mod + main.go`, `package.json "bin"` | **cli** | Terminal, exit codes |
| 3 | Backend routes WITHOUT frontend templates | **api** | curl, httpie |
| 4 | Frontend framework WITHOUT backend routes | **web** | Playwright, Chrome DevTools |
| 5 | Frontend AND backend in same project | **fullstack** | All tools, bottom-up |
| 6 | None of the above | **generic** | Adaptive |

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
| web | `references/web-validation.md` | Playwright, Chrome DevTools, responsive |
| api | `references/api-validation.md` | curl, auth flows, error cases |
| cli | `references/cli-validation.md` | Build, execute, exit codes |
| fullstack | `references/fullstack-validation.md` | Bottom-up: DB → API → Frontend |
| generic | `references/generic-validation.md` | Adaptive entry point discovery |

## Workflow Files

| Workflow | Phase | Purpose |
|----------|-------|---------|
| `workflows/analyze.md` | Discovery | Platform detection, journey mapping |
| `workflows/plan.md` | Planning | PASS criteria, approval gate |
| `workflows/execute.md` | Execution | Evidence capture, review, verdicts |
| `workflows/fix-and-revalidate.md` | Repair | 3-strike protocol, re-validation |
| `workflows/audit.md` | Assessment | Read-only severity classification |
| `workflows/report.md` | Reporting | Report generation, export |
| `workflows/full-run.md` | Full Pipeline | End-to-end with approval gate |
| `workflows/ci-mode.md` | CI/CD | Non-interactive, exit codes |

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

## Related Skills

| Skill | Role in Pipeline |
|-------|-----------------|
| `functional-validation` | Core protocol, referenced in all workflows |
| `gate-validation-discipline` | Evidence verification during verdict writing |
| `no-mocking-validation-gates` | Mock detection during analysis |
| `create-validation-plan` | Plan generation for `--plan` workflow |
| `verification-before-completion` | Pre-completion checklist |
| `full-functional-audit` | Audit protocol for `--audit` workflow |
| `preflight` | Environment checks before execution |
| `baseline-quality-assessment` | Quality baseline during analysis |
| `condition-based-waiting` | Smart waits during evidence capture |
| `error-recovery` | Error handling during fix loop |
