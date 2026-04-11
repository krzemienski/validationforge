# ValidationForge

No-mock validation platform for Claude Code. Ship verified code, not "it compiled" code.

## Philosophy

1. **No Mocks Ever** — Never create test files, mocks, stubs, or test doubles
2. **Evidence-Based Verdicts** — Every PASS/FAIL cites specific evidence (screenshots, logs, responses)
3. **Real System Validation** — Build, run, and interact with the actual application
4. **Gate Discipline** — Never claim completion without personally examining evidence
5. **Autonomous Fix Loop** — Don't just find defects, fix them and re-validate
6. **Benchmark Everything** — Measure validation effectiveness with real metrics

## Quick Start

```
/vf-setup                    # Initialize ValidationForge for this project
/validate                    # Full pipeline: detect → plan → execute → verdict
/validate-plan               # Plan only (no execution)
/validate-audit              # Read-only audit with severity classification
/validate-fix                # Fix FAIL verdicts and re-validate (3-strike limit)
/validate-ci                 # Non-interactive CI/CD mode with exit codes
/validate-team               # Multi-agent parallel platform validation
/validate-team-dashboard     # Aggregate team validation posture dashboard
/validate-sweep              # Autonomous fix-and-revalidate loop until PASS
/validate-benchmark          # Measure validation posture (coverage, evidence, enforcement, speed)
```

## The 7-Phase Pipeline

```
0. RESEARCH   → Standards, best practices, applicable criteria
1. PLAN       → Journeys, PASS criteria, evidence requirements
2. PREFLIGHT  → Build compiles, services running, MCP servers available
3. EXECUTE    → Run journeys against real system, capture evidence
3.5 AI ANALYZE → Vision + LLM analysis of captured evidence, confidence scores per item
4. ANALYZE    → Root cause investigation for FAILs (sequential thinking)
5. VERDICT    → Evidence-backed PASS/FAIL per journey, unified report
6. SHIP       → Production readiness audit, deploy decision
```

## Platform Detection

| Platform | Indicators | Skills |
|----------|-----------|--------|
| iOS | .xcodeproj, .swift | ios-validation, ios-validation-gate, ios-validation-runner, ios-simulator-control |
| Web | package.json + framework config | playwright-validation, web-validation, web-testing, chrome-devtools |
| API | route handlers, OpenAPI spec | api-validation |
| CLI | argument parsers, bin entries | cli-validation |
| Fullstack | multiple layers detected | fullstack-validation |
| Design | DESIGN.md, Stitch project | design-validation, stitch-integration, design-token-audit |
| React Native | package.json + react-native dep | react-native-validation |
| Flutter | pubspec.yaml, .dart files | flutter-validation |
| Django/Flask | requirements.txt, wsgi.py, manage.py | django-validation |
| Rust CLI | Cargo.toml, src/main.rs | rust-cli-validation |

## Evidence Rules

All evidence goes to `e2e-evidence/` with sequential naming:
```
e2e-evidence/
  {journey-slug}/
    step-01-{description}.png
    step-02-{description}.json
    evidence-inventory.txt
  report.md
```

### Evidence Quality Standards

- **Screenshots**: Describe what you SEE, not that it exists
- **API responses**: Quote actual body AND headers, not just status code
- **Build output**: Quote the actual success/failure line
- **Console logs**: Include timestamps
- **Empty files**: 0-byte files are INVALID evidence

## The Iron Rules

```
1. IF the real system doesn't work, FIX THE REAL SYSTEM.
2. NEVER create mocks, stubs, test doubles, or test files.
3. NEVER mark a journey PASS without specific cited evidence.
4. NEVER skip preflight — if it fails, STOP.
5. NEVER exceed 3 fix attempts per journey.
6. NEVER produce a partial verdict — wait for ALL validators.
7. NEVER reuse evidence from a previous attempt.
8. Compilation success ≠ functional validation.
```

## Team Validation

For multi-platform projects, spawn coordinated validators:

```
Lead (you)
├── Web Validator    → e2e-evidence/web/
├── API Validator    → e2e-evidence/api/
├── iOS Validator    → e2e-evidence/ios/
├── Design Validator → e2e-evidence/design/
└── Verdict Writer   → e2e-evidence/report.md
```

Each validator owns its evidence directory exclusively. Never write to another validator's directory.

## Configuration

Three enforcement levels in `config/`:
- `strict.json` — Maximum enforcement, all hooks enabled
- `standard.json` — Balanced enforcement for daily development
- `permissive.json` — Minimal enforcement for exploration

Setup config stored in `~/.claude/.vf-config.json` after running `/vf-setup`.

## Benchmarking

`/validate-benchmark` scores your project across four dimensions:

| Dimension | Weight | What It Measures |
|-----------|--------|-----------------|
| Coverage | 35% | Validated journeys / Total discoverable features |
| Evidence Quality | 30% | Evidence citations, observation quality, verdict rigor |
| Enforcement | 25% | Hooks installed, no mocks, no test files, rules active |
| Speed | 10% | Validation time relative to project size |

Grades: A (90+), B (80-89), C (70-79), D (60-69), F (<60).
History tracked in `.vf/benchmarks/`.

## Inventory

### Commands (16)

**Validation Commands**
vf-setup, validate, validate-plan, validate-audit, validate-fix, validate-ci, validate-team, validate-team-dashboard, validate-sweep, validate-benchmark

**Forge Commands**
forge-setup, forge-plan, forge-execute, forge-team, forge-benchmark, forge-install-rules

### Skills (46)

**Platform Validation (15)**
ios-validation, ios-validation-gate, ios-validation-runner, ios-simulator-control, playwright-validation, web-validation, web-testing, chrome-devtools, api-validation, cli-validation, fullstack-validation, react-native-validation, flutter-validation, django-validation, rust-cli-validation

**Quality Gates (6)**
functional-validation, gate-validation-discipline, no-mocking-validation-gates, build-quality-gates, verification-before-completion, preflight

**Design Validation (4)**
design-validation, design-token-audit, stitch-integration, visual-inspection

**Analysis & Research (4)**
sequential-analysis, research-validation, retrospective-validation, ai-evidence-analysis

**Specialized (6)**
accessibility-audit, responsive-validation, parallel-validation, e2e-testing, e2e-validate, create-validation-plan

**Operational (5)**
baseline-quality-assessment, condition-based-waiting, error-recovery, production-readiness-audit, full-functional-audit

**Forge Orchestration (7)**
forge-setup, forge-plan, forge-execute, forge-team, forge-benchmark, validate-audit-benchmarks, team-validation-dashboard, coordinated-validation

### Agents (5)

| Agent | Purpose |
|-------|---------|
| platform-detector | Identify project platforms and frameworks |
| evidence-capturer | Capture and organize validation evidence |
| verdict-writer | Synthesize evidence into PASS/FAIL verdicts |
| validation-lead | Orchestrate multi-agent validation teams |
| sweep-controller | Control autonomous fix-and-revalidate loops |

### Hooks (7)

| Hook | Trigger | Purpose |
|------|---------|---------|
| block-test-files | Write/Edit (pre) | Block creation of test/mock/stub files |
| evidence-gate-reminder | TaskUpdate (pre) | Inject evidence checklist on completion |
| validation-not-compilation | Bash (post) | Remind: build success is not validation |
| completion-claim-validator | Bash (post) | Catch claims without evidence |
| validation-state-tracker | Bash (post) | Track validation activity, remind to capture evidence |
| mock-detection | Edit/Write (post) | Detect mock patterns in code |
| evidence-quality-check | Edit/Write (post) | Warn on empty evidence files |

### Rules (8)

| Rule | Purpose |
|------|---------|
| validation-discipline | No-mock mandate, evidence standards, gate protocol |
| execution-workflow | 7-phase pipeline details |
| evidence-management | Directory structure, naming, quality, retention |
| platform-detection | Detection priority, platform-specific validation |
| team-validation | Multi-agent roles, file ownership, coordination |
| benchmarking | Metric collection, integrity, comparative analysis |
| forge-execution | Phase gates, fix loop discipline, state persistence |
| forge-team-orchestration | Validator assignment, evidence ownership, verdict synthesis |
