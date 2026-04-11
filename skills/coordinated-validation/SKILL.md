---
name: coordinated-validation
description: "Multi-platform validation respecting cross-platform dependencies: DB→API→Web/iOS. Parallelizes independent layers, blocks downstream on failure, coordinates evidence. Use for fullstack, mobile+API, CI/CD."
triggers:
  - "coordinated validation"
  - "dependency-aware validation"
  - "fullstack coordinated validation"
  - "cross-platform validation"
  - "validate with dependencies"
context_priority: standard
---

# Coordinated Validation

Multi-platform validation that respects cross-platform dependencies. Independent platforms run in parallel for speed; dependent platforms wait for their dependencies to pass before launching. A failed dependency blocks all downstream validations.

## When to Use

- Fullstack projects where frontend depends on a working API
- Mobile + API projects where iOS app relies on real backend responses
- Any multi-platform project where one platform's correctness depends on another
- CI/CD pipelines where evidence must reflect true integration, not isolated layers

## Dependency Graph

```
DB (Layer 0)
 ├── API (Layer 1)  ← depends on DB
 │    ├── Web (Layer 2)  ← depends on API
 │    └── iOS (Layer 2)  ← depends on API
 └── (direct DB consumers, if any)
```

### Standard Dependency Rules

| Platform | Depends On | Why |
|----------|-----------|-----|
| API | DB | API reads/writes real data; DB must be correct first |
| Web | API | Frontend fetches from API; API must work before web evidence is meaningful |
| iOS | API | Native app talks to API; API must work before iOS evidence is meaningful |
| CLI | (none by default) | Typically independent; may depend on API if it calls endpoints |
| Design | (none) | Visual audit is independent of runtime behavior |

### Parallel-Safe Combinations

| Combination | Safe? | Reason |
|-------------|-------|--------|
| Web + iOS (same layer) | ✅ Yes | Both depend on API, not each other |
| DB + Design | ✅ Yes | No runtime dependency |
| CLI + Design | ✅ Yes | No shared state |
| API + Web | ❌ No | Web depends on API passing first |
| DB + API | ❌ No | API depends on DB passing first |

## Execution Protocol: Waves

Execution proceeds in **waves**. Each wave contains all platforms at the same dependency depth. A wave only starts when all platforms in the previous wave have passed.

```
Wave 0 (no dependencies):  DB, Design, CLI (if independent)
Wave 1 (depends on Wave 0): API
Wave 2 (depends on Wave 1): Web, iOS
```

### Wave Execution Rules

1. **Launch all platforms in a wave in parallel** using `Agent` tool with `run_in_background: true`
2. **Wait for ALL agents in the wave to complete** before evaluating
3. **If any platform in wave N fails → abort all dependent waves** (N+1, N+2, ...)
4. **Only proceed to the next wave if all current-wave platforms PASS or CONDITIONAL**

### Failure Blocking Matrix

| Wave 0 Result | Wave 1 Starts? | Wave 2 Starts? |
|--------------|----------------|----------------|
| All PASS | ✅ Yes | (depends on Wave 1) |
| Any CONDITIONAL | ✅ Yes (with warning) | (depends on Wave 1) |
| Any FAIL | ❌ BLOCKED | ❌ BLOCKED |

| Wave 1 Result | Wave 2 Starts? |
|--------------|----------------|
| All PASS | ✅ Yes |
| Any CONDITIONAL | ✅ Yes (with warning) |
| Any FAIL | ❌ BLOCKED — mark Web and iOS as BLOCKED |

## Orchestration Protocol

### Phase 1: Dependency Graph Analysis

```
1. Detect which platforms are present in the project
2. Build dependency graph based on standard rules above
3. Group platforms into execution waves
4. Identify which agents to spawn per wave
```

### Phase 2: Member Assignment

Assign team members to specific platform validations before execution:

```markdown
## Platform Assignments

| Wave | Platform | Agent Role | Evidence Directory | Assigned Member |
|------|----------|-----------|-------------------|-----------------|
| 0 | DB | db-validator | e2e-evidence/db/ | Agent A |
| 0 | Design | design-validator | e2e-evidence/design/ | Agent B |
| 1 | API | api-validator | e2e-evidence/api/ | Agent C |
| 2 | Web | web-validator | e2e-evidence/web/ | Agent D |
| 2 | iOS | ios-validator | e2e-evidence/ios/ | Agent E |
```

Assignment rules:
- One agent per platform (never share an evidence directory)
- Agents from earlier waves MUST complete before assigning next-wave agents
- The orchestrator (Lead) never validates directly — it coordinates and synthesizes

### Phase 3: Wave Execution

#### Wave 0 — Independent Platforms

```
Launch in parallel (run_in_background: true):
  Agent A: DB validation  → e2e-evidence/db/
  Agent B: Design validation → e2e-evidence/design/
```

Wait for ALL Wave 0 agents to complete.

Evaluate Wave 0:
- All PASS or CONDITIONAL → proceed to Wave 1
- Any FAIL → mark all downstream as BLOCKED, skip to Phase 5 (report)

#### Wave 1 — API (depends on DB)

```
Launch in parallel (run_in_background: true):
  Agent C: API validation → e2e-evidence/api/
```

Wait for ALL Wave 1 agents to complete.

Evaluate Wave 1:
- All PASS or CONDITIONAL → proceed to Wave 2
- Any FAIL → mark Web and iOS as BLOCKED, skip to Phase 5 (report)

#### Wave 2 — Frontend Platforms (depend on API)

```
Launch in parallel (run_in_background: true):
  Agent D: Web validation → e2e-evidence/web/
  Agent E: iOS validation → e2e-evidence/ios/
```

Wait for ALL Wave 2 agents to complete.

### Phase 4: Evidence Coordination

After all waves complete, the Lead collects cross-platform evidence:

```
1. Read each platform's evidence-inventory.txt
2. Verify evidence files exist and are non-empty
3. Cross-reference: API responses in api/ should match data shown in web/ and ios/
4. Note any cross-platform discrepancies as CONDITIONAL issues
```

Cross-platform evidence check:
- API returned N users → Web should display N users
- API create endpoint succeeded → DB should have the new record
- iOS received API response → API evidence should show the same request

### Phase 5: Unified Report

Spawn a verdict-writer agent with all evidence directories as input. It produces:
- `e2e-evidence/coordinated-report.md` — unified report with per-wave breakdown

## Evidence Directory Structure

```
e2e-evidence/
  db/                    ← Wave 0, Agent A ONLY
    step-01-schema.txt
    step-02-seed-count.txt
    evidence-inventory.txt
    report.md
  design/                ← Wave 0, Agent B ONLY
    reference/
    implementation/
    evidence-inventory.txt
    report.md
  api/                   ← Wave 1, Agent C ONLY
    step-01-health.json
    step-02-create.json
    evidence-inventory.txt
    report.md
  web/                   ← Wave 2, Agent D ONLY
    step-01-homepage.png
    step-02-dashboard.png
    evidence-inventory.txt
    report.md
  ios/                   ← Wave 2, Agent E ONLY
    step-01-launch.png
    step-02-login.png
    evidence-inventory.txt
    report.md
  coordinated-report.md  ← Lead / Verdict Writer ONLY
```

**NEVER** let two agents write to the same directory. Evidence corruption invalidates the entire report.

## Agent Prompt Template

Each validator agent receives a prompt structured as follows:

```markdown
You are a ValidationForge validation agent in a coordinated multi-platform validation.

**Platform:** {platform}
**Wave:** {wave number}
**Dependency context:** {what passed upstream, e.g., "DB validation PASSED — API should have correct data"}
**Journeys:** {journey list for this platform}
**Evidence Directory:** e2e-evidence/{platform}/ (you have EXCLUSIVE ownership)

## Rules
1. NO mocks, stubs, or hardcoded responses — validate the REAL system
2. Capture evidence for every step (screenshots, API responses, logs)
3. Name evidence: step-{NN}-{description}.{ext}
4. Write evidence-inventory.txt listing every file you create
5. Write report.md with per-journey verdicts and specific evidence citations
6. DO NOT write to any other platform's evidence directory

## Upstream Context
{summary of upstream platform results, e.g., "API /users returned 3 users — your web validation should confirm 3 users appear in the UI"}

## Journeys to Validate
{detailed journey descriptions with acceptance criteria}

## Verdict Rules
- PASS: All criteria met with evidence
- CONDITIONAL: Minor issues, non-blocking, document clearly
- FAIL: Any criteria unmet, evidence missing, or system error
```

## Verdict Aggregation

### Per-Wave Verdicts

| Wave Verdict | Condition |
|-------------|-----------|
| PASS | All platforms in wave PASS |
| CONDITIONAL | Any platform CONDITIONAL, none FAIL |
| FAIL | Any platform FAIL |
| BLOCKED | Upstream wave FAILED |

### Overall Verdict

| Scenario | Overall Verdict |
|----------|----------------|
| All waves PASS | PASS |
| Any wave CONDITIONAL, no FAIL or BLOCKED | CONDITIONAL |
| Any wave FAIL or BLOCKED | FAIL |
| Any agent crashed or incomplete | INCOMPLETE |

**Overall verdict = worst wave verdict.** A BLOCKED wave is treated as FAIL.

## Report Template

```markdown
# Coordinated Validation Report

**Date:** YYYY-MM-DD
**Platforms detected:** {list}
**Waves executed:** {N}
**Overall verdict:** PASS | CONDITIONAL | FAIL | INCOMPLETE

## Dependency Graph

DB → API → Web
         → iOS

## Wave Results

### Wave 0 — Independent

| Platform | Verdict | Evidence |
|----------|---------|---------|
| DB | PASS | e2e-evidence/db/report.md |
| Design | PASS | e2e-evidence/design/report.md |

### Wave 1 — API Layer

| Platform | Verdict | Evidence | Blocked By |
|----------|---------|---------|-----------|
| API | PASS | e2e-evidence/api/report.md | — |

### Wave 2 — Frontend Layer

| Platform | Verdict | Evidence | Blocked By |
|----------|---------|---------|-----------|
| Web | PASS | e2e-evidence/web/report.md | — |
| iOS | CONDITIONAL | e2e-evidence/ios/report.md | — |

## Cross-Platform Evidence Consistency

| Check | Result | Notes |
|-------|--------|-------|
| API user count matches Web display | ✅ | API: 3, Web: 3 |
| API create → DB record exists | ✅ | Record id=42 confirmed |
| iOS API responses match API evidence | ✅ | Same endpoint, same payload |

## Platform Summaries

### API (Wave 1) — PASS
{summary from api/report.md}

### Web (Wave 2) — PASS
{summary from web/report.md}

### iOS (Wave 2) — CONDITIONAL
{summary from ios/report.md}

## Issues Requiring Attention
{list of CONDITIONAL or FAIL items with evidence citations}

## Final Verdict Rationale
{explanation of overall verdict}
```

## Common Failures

| Symptom | Cause | Resolution |
|---------|-------|-----------|
| Web shows empty data after API PASS | Frontend fetching wrong endpoint | Check fetch URL in web validator |
| iOS blocked despite API passing | Incorrect wave evaluation | Re-check API report verdict field |
| Cross-platform count mismatch | API pagination vs full count | Document as CONDITIONAL, investigate |
| Wave 2 agents launched before Wave 1 complete | Orchestrator error | Always await all agents before next wave |
| Two agents writing same directory | Assignment error | Reassign immediately, discard corrupt evidence |

## Performance Guidelines

| Configuration | Waves | Wall Clock Estimate |
|--------------|-------|---------------------|
| API only | 1 | Fast (1 wave) |
| DB + API | 2 | Moderate (2 sequential waves) |
| DB + API + Web | 3 | 3 waves; Web waits for API |
| DB + API + Web + iOS | 3 | Same as above (Web+iOS parallel in Wave 2) |
| DB + Design + API + Web + iOS | 3 | Design runs in Wave 0 with DB |

Running Web and iOS in the same wave (Wave 2) means the total time is:
`time(DB) + time(API) + max(time(Web), time(iOS))`
not the sum of all — parallel execution saves significant wall clock time.
