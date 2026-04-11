---
name: validate-team
description: Spawn coordinated validation agents across platforms with evidence handoff
triggers:
  - "validate team"
  - "team validation"
  - "parallel validate"
  - "multi-platform validate"
---

# Validate Team

Spawn N coordinated validation agents working on a shared validation task list. Each agent validates a specific platform or journey set, producing evidence that flows to a unified verdict.

## Usage

```
/validate-team                              # Auto-detect platforms, auto-size team
/validate-team N "scope description"        # N agents on specific scope
/validate-team --platforms ios,web,api      # Explicit platform split
```

### Parameters

- **N** — Number of validation agents (1-6). Auto-sized if omitted.
- **scope** — What to validate. Defaults to full application.
- **--platforms** — Comma-separated platform list for explicit assignment.

## Architecture

```
User: "/validate-team 3 validate the full application"
              |
              v
      [VALIDATION LEAD]
              |
              +-- platform-detector agent
              |       -> detects: ios, web, api
              |       -> resolves cross-platform dependencies
              |
              +-- create-validation-plan skill
              |       -> generates journey list per platform
              |       -> annotates dependency graph
              |
              +-- TeamCreate("vf-validation")
              |
              +-- WAVE 1 (independent — run in parallel)
              |       +-- Task(name="api-validator") x 1
              |               -> MUST PASS before Wave 2 launches
              |
              +-- WAVE 2 (depends on api-validator PASS)
              |       +-- Task(name="web-validator") x 1   <-- blocked until API passes
              |       +-- Task(name="ios-validator") x 1   <-- blocked until API passes
              |               (web and ios run in parallel within wave)
              |
              +-- Monitor loop
              |       <- evidence files accumulate
              |       -> TaskList polling
              |       -> promote wave-2 tasks when wave-1 PASS confirmed
              |       -> mark wave-2 tasks BLOCKED if wave-1 FAIL
              |
              +-- verdict-writer agent
              |       -> reads all e2e-evidence/
              |       -> unified coordinated report
              |
              +-- Shutdown
                      -> SendMessage(shutdown_request) to each
                      -> TeamDelete("vf-validation")
```

## Agent Roles

| Role | Agent Type | Responsibility | Evidence Directory |
|------|-----------|----------------|-------------------|
| Lead | orchestrator | Decomposes, assigns, monitors, produces verdict | e2e-evidence/ |
| iOS Validator | general-purpose | Builds, runs simulator, captures iOS evidence | e2e-evidence/ios/ |
| Web Validator | general-purpose | Launches dev server, Playwright captures | e2e-evidence/web/ |
| API Validator | general-purpose | Exercises endpoints, saves responses | e2e-evidence/api/ |
| Design Validator | general-purpose | Stitch references, fidelity scoring | e2e-evidence/design/ |
| CLI Validator | general-purpose | Runs commands, captures stdout/stderr | e2e-evidence/cli/ |

## Team Sizing

| Application | Agents | Wave Assignment |
|-------------|--------|-----------------|
| Single platform | 1-2 | Wave 1: 1 validator; lead |
| Web + API | 2-3 | Wave 1: api; Wave 2: web (parallel); lead |
| iOS + Web + API | 3-4 | Wave 1: api; Wave 2: web + ios (parallel); lead |
| Fullstack + Design | 4-5 | Wave 1: api + design (parallel); Wave 2: web + ios (parallel); lead |
| Everything | 5-6 | Wave 1: api + design + cli (parallel); Wave 2: web + ios (parallel); lead |

## Dependency-Aware Execution

Coordinated validation executes in waves based on cross-platform dependencies detected in the codebase. Independent platforms run in parallel within each wave; dependent platforms wait for upstream PASS.

### Execution Waves

```
Wave 1 — Foundation (always first, run in parallel within wave)
  API validator         → validates backend endpoints, auth, data contracts
  CLI validator         → validates build tools, scripts (if independent)
  Design validator      → visual audit, independent of runtime behavior

Wave 2 — Consumers (launch only after Wave 1 PASS)
  Web validator    ──── depends on: api-validator PASS
  iOS validator    ──── depends on: api-validator PASS
  (web and ios execute in parallel within Wave 2)
```

### Platform Dependency Table

| Platform | Depends On | Can Run In Parallel With |
|----------|-----------|--------------------------|
| API | (none — wave 1 root) | CLI, Design (if independent) |
| CLI | (none — wave 1 root) | API, Design |
| Web | API (wave 1) | iOS (same wave) |
| iOS | API (wave 1) | Web (same wave) |
| Design | (none — independent) | API, CLI (wave 1) |

> **Dependency detection**: The lead reads `package.json`, import paths, and environment configs to infer which platforms consume the API. Explicit override via `--dependency-map` flag.

## Platform Failure Blocking

When a Wave 1 platform fails, all downstream platforms are marked **BLOCKED** immediately — no cycles are wasted validating a frontend against a broken backend.

### Blocking Rules

```
IF api-validator → FAIL
  THEN web-validator  → BLOCKED (not run)
       ios-validator  → BLOCKED (not run)

IF api-validator → PASS, web-validator → FAIL
  THEN ios-validator continues (not blocked — independent within wave)
       (design-validator is independent — continues regardless of api or web result)
```

### BLOCKED Status in Reports

A BLOCKED platform receives a structured non-verdict entry in the unified report:

```
Platform: web
Status:   BLOCKED
Reason:   api-validator returned FAIL — web validation skipped
Blocked By: api-validator (wave-1)
Evidence: none captured (upstream prerequisite failed)
Action:   Fix API failures first, then re-run /validate-team
```

BLOCKED platforms do **not** count as PASS or FAIL in the aggregation — they are recorded as INCOMPLETE with a blocking cause. The overall verdict is `FAIL` if any upstream platform failed, regardless of BLOCKED downstream status.

## Agent Prompt Template

Each validator agent receives:

```markdown
You are a ValidationForge {platform} validation agent.

## Your Assignment
- Platform: {platform}
- Journeys: {journey list with acceptance criteria}
- Evidence directory: e2e-evidence/{platform}/

## Rules (NON-NEGOTIABLE)
1. NO mocks, stubs, or test files — validate the REAL system
2. Build and run the actual application
3. Capture evidence for EVERY step (screenshots, logs, responses)
4. Name files: step-{NN}-{action}-{result}.{ext}
5. Write report.md in your evidence directory
6. Every PASS must cite a specific evidence file
7. Every FAIL must include root cause and remediation (fix real system, not tests)

## Journeys
{detailed journey descriptions}

## When Done
1. Write evidence-inventory.txt listing all captured files
2. Write report.md with per-journey verdicts
3. Mark your task as completed via TaskUpdate
4. Send completion message to lead
```

## Validation Pipeline Per Agent

Each agent follows the standard 7-phase pipeline independently:

```
Research → Plan → Preflight → Execute → Analyze → Verdict
```

1. **Research**: Read codebase, understand the platform layer
2. **Plan**: Map journeys to concrete steps
3. **Preflight**: Verify build succeeds, dependencies available
4. **Execute**: Run the real system, interact through actual UI/API
5. **Analyze**: Review captured evidence against criteria
6. **Verdict**: Write per-journey PASS/FAIL with evidence citations

## Evidence Handoff

```
ios-validator  → e2e-evidence/ios/report.md
web-validator  → e2e-evidence/web/report.md
api-validator  → e2e-evidence/api/report.md
                        |
                        v
              verdict-writer agent
                        |
                        v
              e2e-evidence/report.md (unified)
```

## Verdict Aggregation

The lead runs the `verdict-writer` agent after all validators complete:

```
Overall = worst(all platform verdicts)

If ANY platform = FAIL → Overall = FAIL
If ANY platform = CONDITIONAL, none FAIL → Overall = CONDITIONAL
If ALL platforms = PASS → Overall = PASS
If ANY agent incomplete → Overall = INCOMPLETE
```

## File Ownership (CRITICAL)

| Owner | Writes To | Never Touches |
|-------|-----------|---------------|
| ios-validator | e2e-evidence/ios/* | e2e-evidence/web/*, api/*, design/* |
| web-validator | e2e-evidence/web/* | e2e-evidence/ios/*, api/*, design/* |
| api-validator | e2e-evidence/api/* | e2e-evidence/ios/*, web/*, design/* |
| design-validator | e2e-evidence/design/* | e2e-evidence/ios/*, web/*, api/* |
| lead | e2e-evidence/report.md | Platform subdirectories |

## Fix Loop

If overall verdict is FAIL:

1. Lead identifies which platform(s) failed
2. For each failed platform, create fix tasks
3. Assign fix tasks to the same validator that found the issue
4. Re-validate after fix (max 3 attempts per journey)
5. Re-aggregate verdict
6. If still FAIL after 3 attempts, report with evidence of all attempts

## Integration

- Uses `coordinated-validation` skill for dependency-aware wave execution and platform blocking
- Uses `create-validation-plan` to decompose into journeys
- Each agent uses platform-specific skills (ios-validation, web-validation, etc.)
- Evidence consumed by `verdict-writer` agent
- Pairs with `/validate` for single-agent mode
- Pairs with `/validate-ci` for CI/CD pipeline mode
