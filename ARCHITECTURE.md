# ValidationForge Architecture

> **NOTE:** This document covers the core validation pipeline architecture (9 validate commands).
> For complete inventory (40 skills, 15 commands, 7 hooks, 5 agents, 8 rules),
> FORGE engine architecture, and CONSENSUS engine details, see [PRD.md](./PRD.md) v2.0.0.

## Command Orchestration System

All 15 commands (9 validate + 6 forge) are entry points into the validation and execution pipelines. The validate commands share a single validation pipeline, each activating a different subset of stages:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    ValidationForge Pipeline                         │
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │ PREFLIGHT│→ │  PLAN    │→ │ EXECUTE  │→ │  REPORT  │           │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘           │
│       ↑              ↑             ↑             ↑                 │
│   preflight     create-         e2e-validate  verdict-             │
│   skill         validation-     + platform    writer               │
│                 plan skill      routing       agent                │
│                                                                     │
│  ┌──────────┐  ┌──────────┐                                        │
│  │   FIX    │→ │RE-EXECUTE│  (fix loop, max 3 strikes)            │
│  └──────────┘  └──────────┘                                        │
│       ↑                                                             │
│   error-recovery                                                    │
│   skill                                                             │
└─────────────────────────────────────────────────────────────────────┘
```

### Command → Pipeline Stage Mapping

| Command | Preflight | Plan | Execute | Report | Fix Loop |
|---------|:---------:|:----:|:-------:|:------:|:--------:|
| `/validate` | ✅ | ✅ | ✅ | ✅ | ❌ |
| `/validate-plan` | ✅ | ✅ | ❌ | ❌ | ❌ |
| `/validate-fix` | ❌ | ❌ | ✅ | ✅ | ✅ |
| `/validate-audit` | ✅ | ❌ | ✅ (read-only) | ✅ | ❌ |
| `/validate-ci` | ✅ | ✅ | ✅ | ✅ | ❌ |
| `/validate-team` | ✅ | ✅ | ✅ (parallel) | ✅ | ❌ |
| `/validate-sweep` | ❌ | ❌ | ✅ | ✅ | ✅ (loop) |
| `/validate-benchmark` | ❌ | ❌ | ✅ (measure) | ✅ (score) | ❌ |
| `/vf-setup` | — | — | — | — | — |

### Command Flow Details

#### `/validate` — Full Pipeline (Default)
```
1. PREFLIGHT: Check prerequisites (servers, DBs, tools, evidence dir)
   ├─ BLOCKED? → List unmet prerequisites, exit
   └─ CLEAR? → Continue

2. PLATFORM DETECT: Scan codebase → ios/web/api/cli/fullstack/generic
   ├─ Load platform-specific validation reference
   └─ Override available via --platform flag

3. PLAN: Map user journeys → define PASS criteria → generate plan
   ├─ User approval gate (unless --ci)
   └─ Save plan to e2e-evidence/validation-plan.md

4. EXECUTE: For each journey:
   ├─ Run real system (not mocks)
   ├─ Capture evidence (screenshots, responses, output)
   ├─ READ every piece of evidence (not just existence check)
   └─ Write PASS/FAIL verdict with citations

5. REPORT: Aggregate verdicts → save to e2e-evidence/report.md
   ├─ Overall: ALL PASS / PARTIAL / ALL FAIL
   ├─ Per-journey: verdict + evidence refs + root cause (if fail)
   └─ Recommendations for failures
```

#### `/validate-plan` — Plan Only
```
1. PREFLIGHT → 2. PLATFORM DETECT → 3. PLAN → STOP
Output: e2e-evidence/validation-plan.md with all journeys + PASS criteria
Use case: Review what will be tested before committing to execution
```

#### `/validate-fix` — Fix + Re-validate
```
1. READ last report (e2e-evidence/report.md)
2. IDENTIFY failed journeys and root causes
3. For each failure (3-strike protocol):
   ├─ Strike 1: Targeted fix based on root cause
   ├─ Re-validate just that journey
   ├─ PASS? → Move to next failure
   ├─ Strike 2: Alternative approach
   ├─ Re-validate
   ├─ Strike 3: Broader rethink
   └─ Still failing? → Escalate with what was tried
4. REPORT: Updated report with fix history
```

#### `/validate-audit` — Read-Only Audit
```
1. PREFLIGHT (no-change mode)
2. PLATFORM DETECT
3. EXECUTE in read-only mode:
   ├─ Capture evidence but make NO code changes
   ├─ Classify findings: CRITICAL / HIGH / MEDIUM / LOW / INFO
   └─ No fix loop, no plan modification
4. REPORT: Audit report with severity breakdown
Use case: Compliance documentation, pre-release assessment
```

#### `/validate-ci` — CI/CD Mode
```
Same as /validate but:
- No approval gates (auto-approve plan)
- No interactive prompts
- Exit code: 0 = all PASS, 1 = any FAIL
- Evidence artifacts saved for CI upload
- Stdout: structured summary for pipeline logs
```

---

## Skill Dependency Graph

Skills are layered. Higher skills depend on lower ones:

```
                    ┌─────────────────┐
         Layer 4:   │   e2e-validate   │  (Orchestrator: routes everything)
                    └────────┬────────┘
                             │ uses
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
    ┌──────────────┐  ┌────────────┐  ┌──────────────┐
L3: │create-        │  │full-       │  │baseline-     │  (Planners)
    │validation-plan│  │functional- │  │quality-      │
    └──────┬───────┘  │audit       │  │assessment    │
           │          └─────┬──────┘  └──────┬───────┘
           │                │                │
              ┌─────────────┼────────────┐
              ▼             ▼            ▼
    ┌──────────────┐  ┌──────────┐  ┌──────────────┐
L2: │functional-   │  │preflight │  │condition-    │  (Protocols)
    │validation    │  │          │  │based-waiting │
    └──────┬───────┘  └──────────┘  └──────┬───────┘
           │                               │
           ▼                               ▼
    ┌──────────────────┐  ┌──────────────────────┐
L1: │no-mocking-       │  │gate-validation-      │  (Guardrails)
    │validation-gates  │  │discipline            │
    └──────────────────┘  └──────────────────────┘
           │                        │
           ▼                        ▼
    ┌──────────────────────────────────────────┐
L0: │verification-before-completion            │  (Foundation)
    │error-recovery                            │
    └──────────────────────────────────────────┘
```

### Dependency Rules

1. **Every skill** references `no-mocking-validation-gates` and `gate-validation-discipline`
2. **Orchestrator** (`e2e-validate`) never runs alone — it routes to platform validators
3. **Platform routing** skills load ONLY for their detected platform (saves context)
4. **Error recovery** is available to ALL skills that might encounter failures
5. **Condition-based-waiting** is used by any skill that starts services

---

## Benchmarking Framework

### What We Benchmark

ValidationForge vs three alternatives:
1. **Unit Testing** (jest, pytest, XCTest) — Traditional approach
2. **ClaudeKit** (v2.11.3) — Competitor CC extension
3. **Manual QA** — Human tester approach

### Benchmark Dimensions

| Dimension | How Measured | Unit |
|-----------|-------------|------|
| **Bug Detection Rate** | # real bugs caught / # total real bugs | Percentage |
| **False Confidence Rate** | # bugs missed that tests "passed" | Count |
| **Time to First Evidence** | Clock time from "start validation" to first captured proof | Minutes |
| **Total Validation Time** | Clock time for complete validation pipeline | Minutes |
| **Integration Bug Coverage** | # cross-layer bugs caught (API↔Frontend, DB↔API) | Count |
| **Evidence Quality** | Specificity score (1-5) of captured evidence | Score |
| **Maintenance Burden** | Lines of validation code per 1000 lines of app code | Ratio |
| **Mock Drift Detection** | # scenarios where mocks diverged from real behavior | Count |
| **Regression Detection** | # regressions caught on re-validation | Count |
| **CI Integration Cost** | Setup time + per-run cost | Minutes + $ |

### Benchmark Scenarios

#### Scenario 1: The Field Rename (API Breaking Change)
```
Setup: REST API returns { users: [...] }, frontend reads response.users
Change: Rename field to { data: [...] }
Expected: Frontend breaks with TypeError

| Approach | Catches Bug? | How? | Time |
|----------|:----------:|------|------|
| Unit Tests (jest) | ❌ | Tests mock the API response, mock still returns old field | — |
| ClaudeKit review | ⚠️ | Might flag if reviewer reads both files | 2-3 min |
| ValidationForge | ✅ | curl API → see "data" field → Playwright → see TypeError | 30 sec |
| Manual QA | ✅ | Open browser, see crash | 2 min |
```

#### Scenario 2: The Auth Token Expiry (Session Management)
```
Setup: JWT expires after 1 hour, refresh token rotates
Change: Reduce expiry to 15 minutes
Expected: Users logged out mid-session if refresh fails

| Approach | Catches Bug? | How? | Time |
|----------|:----------:|------|------|
| Unit Tests | ❌ | Tests mock time, never wait 15 real minutes | — |
| ClaudeKit review | ❌ | Code review can't simulate time-based behavior | — |
| ValidationForge | ✅ | Condition-based wait → verify token refresh → capture response | 2 min |
| Manual QA | ⚠️ | Would need to wait or manipulate clock | 15+ min |
```

#### Scenario 3: The iOS Deep Link (Navigation)
```
Setup: App handles myapp://profile/123 deep link
Change: Refactor navigation stack
Expected: Deep link lands on wrong screen or crashes

| Approach | Catches Bug? | How? | Time |
|----------|:----------:|------|------|
| Unit Tests (XCTest) | ❌ | Tests mock URL handler, never launch real app | — |
| ClaudeKit review | ❌ | No iOS simulator integration | — |
| ValidationForge | ✅ | simctl openurl → idb screenshot → verify screen content | 45 sec |
| Manual QA | ✅ | Tap link on device, see result | 1 min |
```

#### Scenario 4: The Database Migration (Data Integrity)
```
Setup: User table has email column, migration adds unique constraint
Change: Run migration on DB with duplicate emails
Expected: Migration fails, app can't start

| Approach | Catches Bug? | How? | Time |
|----------|:----------:|------|------|
| Unit Tests | ❌ | Tests use clean in-memory DB, no duplicates | — |
| ClaudeKit review | ⚠️ | Might flag missing pre-migration check | 2 min |
| ValidationForge | ✅ | Bottom-up: run migration → health check → verify app starts | 1 min |
| Manual QA | ✅ | Run migration, see error | 3 min |
```

#### Scenario 5: The CSS Regression (Visual)
```
Setup: Dashboard grid layout works on 1920x1080
Change: Add sidebar component
Expected: Grid overflows on smaller screens

| Approach | Catches Bug? | How? | Time |
|----------|:----------:|------|------|
| Unit Tests | ❌ | No visual rendering in test harness | — |
| ClaudeKit review | ❌ | Code review can't render CSS | — |
| ValidationForge | ✅ | Playwright resize → screenshot → describe what you SEE | 30 sec |
| Manual QA | ✅ | Resize browser, see overflow | 1 min |
```

### Aggregate Scorecard

```
| Metric                    | Unit Tests | ClaudeKit | ValidationForge | Manual QA |
|---------------------------|:----------:|:---------:|:---------------:|:---------:|
| Bugs caught (of 5)        | 0/5        | 1/5       | 5/5             | 4/5       |
| Avg time to detect        | —          | 2.5 min   | 53 sec          | 4.4 min   |
| False confidence events   | 5          | 3         | 0               | 0         |
| Integration bugs caught   | 0/3        | 0/3       | 3/3             | 2/3       |
| Maintenance lines/1K app  | 200-400    | 0         | 0               | 0         |
| Mock drift risk           | HIGH       | N/A       | ZERO            | ZERO      |
| CI automatable            | ✅         | ❌        | ✅ (--ci)       | ❌        |
| Evidence artifact         | ❌ (logs)  | ❌        | ✅ (screenshots)| ❌        |
```

### Running the Benchmark

```bash
# 1. Clone benchmark scenarios repo
git clone https://github.com/krzemienski/validationforge-benchmarks

# 2. Each scenario has:
#    - app/          → The application code
#    - change.patch  → The breaking change to apply
#    - tests/        → Unit tests that PASS despite the bug
#    - expected/     → What ValidationForge should catch

# 3. Run ValidationForge benchmark
cd scenario-01-field-rename
git apply change.patch
validationforge validate --ci --verbose

# 4. Run unit test benchmark
cd scenario-01-field-rename
git apply change.patch
npm test  # Watch it pass despite bug

# 5. Compare: ValidationForge catches it, unit tests don't
```

---

## Configuration Schema

```json
{
  "strictness": {
    "type": "enum",
    "values": ["strict", "standard", "permissive"],
    "default": "standard",
    "description": "Controls enforcement level of validation hooks"
  },
  "evidence_dir": {
    "type": "string",
    "default": "e2e-evidence",
    "description": "Directory for evidence artifacts"
  },
  "platform_override": {
    "type": "enum",
    "values": ["auto", "ios", "web", "api", "cli", "fullstack"],
    "default": "auto",
    "description": "Override platform auto-detection"
  },
  "ci_mode": {
    "type": "boolean",
    "default": false,
    "description": "Non-interactive mode for CI/CD pipelines"
  },
  "max_recovery_attempts": {
    "type": "integer",
    "default": 3,
    "min": 1,
    "max": 10,
    "description": "Maximum fix attempts per failure before escalating"
  },
  "require_baseline": {
    "type": "boolean",
    "default": true,
    "description": "Require baseline capture before validation"
  },
  "parallel_journeys": {
    "type": "boolean",
    "default": false,
    "description": "Run independent journey validations in parallel"
  },
  "evidence_retention_days": {
    "type": "integer",
    "default": 30,
    "description": "Auto-prune evidence older than N days"
  }
}
```

---

## Current State (March 2026)

- 179 files, 9,424 total lines
- 40 skills across 5 layers (L0 Foundation → L4 Orchestrator)
- 15 commands (9 validate + 6 forge)
- 7 hooks (3 blocking, 4 advisory)
- 5 agents, 8 rules, 3 config profiles
- Core orchestrator (e2e-validate): 2,563 lines with 8 workflow files + 6 platform references
- See [PRD.md](./PRD.md) Section 13 for full roadmap (M0 → V3.0)
