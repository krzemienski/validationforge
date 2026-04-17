---
name: coordinated-validation
description: "Use for multi-platform projects (fullstack, mobile+API, web+iOS, any combination where one layer depends on another) when you want validation to respect those dependencies instead of running everything in parallel and getting false positives. This skill organizes validation into dependency-aware waves: DB first, then API, then Web/iOS in parallel. Upstream failures auto-block downstream waves (no point validating Web against a broken API). Also assigns exclusive evidence directories per agent to prevent collisions. Reach for it on phrases like 'validate everything in the right order', 'coordinate fullstack validation', 'run all platforms in parallel where safe', or before invoking multiple platform validators simultaneously."
triggers:
  - "coordinated validation"
  - "dependency-aware validation"
  - "fullstack coordinated validation"
  - "cross-platform validation"
  - "validate with dependencies"
  - "multi-platform validation"
  - "validate in order"
  - "parallel platform validation"
context_priority: standard
---

# Coordinated Validation

Multi-platform validation that respects cross-platform dependencies. Independent platforms run in parallel for speed; dependent platforms wait for their dependencies to pass before launching. A failed dependency blocks all downstream validations.

**Why dependency-aware?** Running Web validation against a broken API produces false failures — every Web journey fails, but the real bug is one layer down. Running them in strict order catches the cause first and skips the wasted work on symptoms.

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

1. **Launch all platforms in a wave in parallel.** Spawn one background agent per platform (Task tool with `run_in_background: true`, or equivalent in your environment). Each agent runs the platform-specific validation skill (e.g., `web-validation`, `api-validation`, `ios-validation`) against its own scope.
2. **Wait for ALL agents in the wave to complete** before evaluating. Don't start the next wave early even if one platform finishes fast — dependency correctness requires the whole wave's verdict.
3. **If any platform in wave N fails → abort all dependent waves** (N+1, N+2, ...). Mark skipped platforms as BLOCKED (not FAIL — the distinction matters for root-cause reports).
4. **Only proceed to the next wave if all current-wave platforms PASS or CONDITIONAL.**

**What counts as an "agent"?** In this context, an agent is either: (a) a background subagent spawned via the Task tool, or (b) a human team member assigned to a platform who runs validation and writes evidence to the assigned directory. Both follow the same wave semantics.

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

| Symptom | Root cause | How to diagnose | Resolution |
|---------|-----------|-----------------|-----------|
| Web shows empty data after API PASS | Frontend fetching wrong endpoint or using cached/mock fetch | Curl the API endpoint manually, compare JSON; check Network tab in browser devtools | Fix fetch URL in web validator; remove mock fallback |
| iOS blocked despite API passing | Wave evaluator read wrong field in API report | Open the API wave report JSON, verify `verdict: "PASS"` is set | Fix the evaluator's field lookup; re-read the report; re-launch blocked wave |
| Cross-platform count mismatch (API returns 10, Web shows 8) | API pagination cutoff, or Web filtering client-side | Curl API with page/limit params; inspect Web's fetch params | Document as CONDITIONAL with the specific counts cited; decide whether to ship |
| Wave 2 agents launched before Wave 1 completed | Orchestrator didn't await all Wave 1 background tasks | Check orchestration log — did it wait on EACH task or just the last one spawned? | Always `await` all agent tasks (not just the last) before evaluating wave verdict |
| Two agents writing to the same evidence directory | Assignment error — same dir assigned twice in member assignment table | Compare Assignment Table against actual agent prompts | Reassign immediately; discard corrupted evidence; re-run those agents with fresh dirs |

## Performance Guidelines

The point of wave execution is to parallelize where dependencies allow, so total time follows this pattern:

```
Total time = sum of wave durations
Wave duration = max of platform durations within that wave (parallel)
```

| Configuration | Waves | Wall clock formula |
|--------------|-------|-------|
| API only | 1 | `time(API)` |
| DB + API | 2 | `time(DB) + time(API)` |
| DB + API + Web | 3 | `time(DB) + time(API) + time(Web)` |
| DB + API + Web + iOS | 3 | `time(DB) + time(API) + max(time(Web), time(iOS))` |
| DB + Design + API + Web + iOS | 3 | `max(time(DB), time(Design)) + time(API) + max(time(Web), time(iOS))` |

**Worked example:** DB=10s, API=15s, Web=20s, iOS=25s → total = 10 + 15 + max(20,25) = 50s. The sequential alternative (DB→API→Web→iOS) would be 10+15+20+25 = 70s. Parallel execution saves 20s.
