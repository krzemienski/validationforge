---
name: e2e-validate
description: "Start HERE when validating any project. Auto-detects your platform (iOS, React Native, Flutter, web, API, CLI, Django, fullstack) and runs the full pipeline: map user journeys, write PASS criteria, build the real system, capture evidence through real interfaces, diagnose failures, emit a verdict. Use whenever the user says 'validate', 'end-to-end test', 'does this actually work', or is unsure which validation skill to reach for."
triggers:
  - "end to end validation"
  - "full validation pipeline"
  - "orchestrate validation"
  - "platform detection"
  - "validation orchestration"
  - "validate my project"
  - "does this actually work"
context_priority: critical
---

# ValidationForge: End-to-End Validation Orchestrator

## When to use this skill

Reach for `e2e-validate` when you need to run validation end-to-end and aren't sure where to start. It figures out the platform, chains the right platform-specific skill at each phase, and ties everything together with a single verdict.

Use a platform-specific skill instead (e.g., `flutter-validation`, `api-validation`, `ios-validation`) when you already know your platform and just need the validation protocol for it. `e2e-validate` will call those same skills under the hood during execution — they're the detailed playbooks, this skill is the conductor.

## Scope

Handles: platform detection, journey mapping, PASS criteria definition, evidence capture and review, PASS/FAIL verdict writing, fix loops, and CI/CD report generation.

Does NOT handle: individual gate evidence examination (`gate-validation-discipline`), mock pattern detection (`no-mocking-validation-gates`), isolated plan generation (`create-validation-plan`).

## Iron Rule

IF the real system doesn't work, FIX THE REAL SYSTEM.
NEVER create mocks, stubs, test doubles, or test files.
ALWAYS validate through the same interfaces real users experience.
ALWAYS capture evidence. ALWAYS review evidence. ALWAYS write verdicts.
Evidence you don't READ is evidence you don't HAVE.

See `no-mocking-validation-gates` for mock pattern detection and blocking rules.

## Platform Detection

Scan project root. First match wins — priorities are ordered so mobile > CLI > server > browser, because the more specialized the runtime, the narrower the validation approach.

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

### When signals conflict

- **Next.js with API routes**: both frontend and backend signals match. Treat as **fullstack** — the web UI and API tests both run, but from one codebase.
- **Django + React SPA**: Django's `manage.py` matches priority 7, React matches priority 6. Django wins. Use **django** and validate the React frontend as part of the Django flow.
- **iOS app with a Node.js companion server in the same repo**: iOS wins by priority. Spin up a separate validation run for the server with `--platform api --scope ./server`.
- **Next.js SPA, no backend**: no API routes → **web**, not fullstack.
- **Monorepo with both a mobile app and a web app**: run two separate validations, one per subpath, with `--scope` set accordingly.

If the auto-detected platform is wrong, override with `--platform <type>` and re-run.

**Automated detection**: `bash scripts/detect-platform.sh --project-dir=. --json` prints the resolved platform + signals in JSON. Use this when you want deterministic platform-gating in CI.

Auto-detection script: `scripts/detect-platform.sh` (in the plugin root).

## Command Routing

Start with no flag (full pipeline). Use the others when you need a specific phase in isolation.

| Flag | When to use | Effect | Workflow |
|------|-------------|--------|----------|
| (none) | Default — you want the whole thing | Full pipeline: analyze → plan → approve → execute → report | `workflows/full-run.md` |
| `--analyze` | Just want to know what platform/journeys exist | Discovery only, no planning or execution | `workflows/analyze.md` |
| `--plan` | You want to write/review PASS criteria before running anything | Plan only, no execution | `workflows/plan.md` |
| `--execute` | Plan already exists, run it | Execute the plan | `workflows/execute.md` |
| `--fix` | Previous run FAILED, want auto-recovery | 3-strike failure recovery + re-validate | `workflows/fix-and-revalidate.md` |
| `--audit` | Pre-release review, don't change code | Read-only severity classification | `workflows/audit.md` |
| `--report` | Need a saved report for stakeholders | Generate/export report from last run | `workflows/report.md` |
| `--ci` | Running in CI/CD, no humans around | Non-interactive, no approval gates, exit codes | `workflows/ci-mode.md` |

**Modifiers:** `--platform <type>` (override detection), `--scope <path>` (limit scope), `--parallel` (sub-agents), `--verbose` (inline evidence).

## Validation Order

Always validate bottom-up: Data Layer → Backend API → Frontend Logic → UI/CLI.

**Why bottom-up?** Higher layers depend on lower ones. A broken database makes every API call fail; broken API endpoints make every UI flow fail. If you test the UI first, every failure looks like a UI bug even when the real cause is three layers down. Starting at the bottom isolates root cause cheaply — each layer is independently verifiable, and once a layer is green you trust it for the next one up.

**What bottom-up looks like per platform:**
- **fullstack**: DB migrations → API endpoints (curl) → UI flows (Playwright)
- **mobile**: deep-link routing → data fetching / storage → UI screens → user journeys
- **API**: DB connectivity → health endpoint → auth → CRUD
- **CLI**: argument parsing → core operation → output format → exit codes

Bottom-up doesn't always apply: a pure CLI with no persistence is basically one layer. Use judgment — the point is to find causes before symptoms, not to follow the order dogmatically.

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

Validation is complete only when all applicable criteria are true. The first seven apply to every platform. The last two depend on what kind of evidence the platform produces.

| # | Criterion | Applies to |
|---|-----------|-----------|
| 1 | Platform detected and all user journeys identified | all |
| 2 | PASS criteria defined for every journey BEFORE execution | all |
| 3 | Real system built AND running (not just "no errors") | all |
| 4 | Every journey exercised through real interfaces | all |
| 5 | Evidence captured AND read (content described, not just "exists") | all |
| 6 | Evidence matched to criteria with PASS/FAIL verdicts written | all |
| 7 | Failures diagnosed with root cause analysis | all (if any FAIL) |
| 8 | Report saved to `e2e-evidence/report.md` | all |
| 9 | Zero unreviewed evidence files in `e2e-evidence/` | platforms that produce files (web, ios, mobile, fullstack); skip for pure CLI where stdout/exit code is the evidence |

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

Core skills used on every run (already loaded as `critical` priority):

- `functional-validation` — the core protocol each workflow calls into
- `create-validation-plan` — invoked during `--plan`
- `gate-validation-discipline` — evidence verification during verdict writing
- `no-mocking-validation-gates` — catches mock patterns during analysis
- `preflight` — environment checks before execution
- `error-recovery` — 3-strike recovery during `--fix`
- `verification-before-completion` — pre-completion checklist

Loaded on demand when the workflow reaches their phase:

- `full-functional-audit` — when `--audit` is set
- `baseline-quality-assessment` — during analysis
- `condition-based-waiting` — during execution, for flaky waits

Platform-specific skills are loaded at execute time based on detection. See the **Platform References** table above.
