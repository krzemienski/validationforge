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

### Wave Execution Rules (Summary)

1. **Launch all platforms in a wave in parallel.** Spawn one background agent per platform (Task tool with `run_in_background: true`, or equivalent). Each agent runs the platform-specific validation skill against its own scope.
2. **Wait for ALL agents in the wave to complete** before evaluating. Don't start the next wave early.
3. **If any platform in wave N fails → abort all dependent waves** (N+1, N+2, ...). Mark skipped platforms as BLOCKED (not FAIL).
4. **Only proceed to the next wave if all current-wave platforms PASS or CONDITIONAL.**

**What counts as an "agent"?** Either (a) a background subagent spawned via the Task tool, or (b) a human team member assigned to a platform. Both follow the same wave semantics.

For the Wave 0/1/2 step-by-step protocol with launch commands, evaluation gates, and evidence directory wiring, see `references/wave-execution-detail.md` — read this before running the first wave.

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

### Phase 3: Wave Execution (Summary)

Execute Wave 0 → evaluate → Wave 1 → evaluate → Wave 2 → evaluate. Each wave launches its agents in parallel with `run_in_background: true`, waits for all to complete, then gates on the results.

For the full step-by-step protocol (launch commands per wave, evaluation gates, Phase 4 evidence coordination, Phase 5 unified report), see `references/wave-execution-detail.md` — read this before running the first wave.

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

## Report Output

The Verdict Writer produces `e2e-evidence/coordinated-report.md` matching the structure in `references/coordinated-report-format.md` — load it when synthesizing the final report so per-wave tables, cross-platform consistency checks, and verdict rationale all follow the expected format.

## Troubleshooting and Performance

For the Common Failures table (empty-data-after-API-PASS, blocked-despite-upstream-PASS, cross-platform count mismatches, shared-directory corruption) and the wall-clock timing formulas for each wave configuration, see `references/troubleshooting.md` — load it when you hit a wave failure, cross-platform inconsistency, or need to estimate total validation time.
