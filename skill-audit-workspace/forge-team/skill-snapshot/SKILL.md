---
name: forge-team
description: "Multi-agent parallel validation with wave-based dependencies: DB/Design → API → Web/iOS. Each validator owns isolated evidence directory. Blocks downstream on upstream failure. Use for fullstack."
context_priority: reference
---

# forge-team

Multi-agent parallel validation. Spawns platform-specific validators that work in parallel with strict evidence directory ownership. Uses dependency-aware wave execution so that upstream platforms (API, DB) are validated before dependent platforms (Web, iOS) launch.

## Trigger

- "team validation", "parallel validation", "validate all platforms"
- Projects with 2+ detected platforms

## Architecture

```
Lead (you)
├── [Wave 0] DB Validator    → e2e-evidence/db/
├── [Wave 0] Design Validator → e2e-evidence/design/
├── [Wave 1] API Validator   → e2e-evidence/api/   ← depends on DB
├── [Wave 2] Web Validator   → e2e-evidence/web/   ← depends on API
├── [Wave 2] iOS Validator   → e2e-evidence/ios/   ← depends on API
├── [Wave 0] CLI Validator   → e2e-evidence/cli/
└── Verdict Writer           → e2e-evidence/report.md
```

## Dependency Graph

Platform dependencies drive wave-based execution. A platform must PASS before any platform that depends on it can launch.

```
DB (Layer 0 — independent)
 └── API (Layer 1 — depends on DB)
      ├── Web (Layer 2 — depends on API)
      └── iOS (Layer 2 — depends on API)

Design (Layer 0 — independent)
CLI    (Layer 0 — independent by default)
```

### Standard Dependencies

| Platform | Depends On | Why |
|----------|-----------|-----|
| DB       | (none)    | Foundation layer; always first |
| API      | DB        | API reads/writes real data; DB must be correct first |
| Web      | API       | Frontend fetches from API; API must work before web evidence is meaningful |
| iOS      | API       | Native app talks to API; API must work before iOS evidence is meaningful |
| CLI      | (none by default) | Typically independent; may depend on API if it calls endpoints |
| Design   | (none)    | Visual audit is independent of runtime behavior |

### Execution Waves

| Wave | Platforms | Condition to Start |
|------|-----------|--------------------|
| Wave 0 | DB, Design, CLI (if independent) | Always — no dependencies |
| Wave 1 | API | Wave 0 all PASS or CONDITIONAL |
| Wave 2 | Web, iOS | Wave 1 all PASS or CONDITIONAL |

Only waves containing detected platforms are executed.

## Team Roles

| Role | Agent Type | Owns | Responsibilities |
|------|-----------|------|-----------------|
| Lead | You | Orchestration | Build wave plan, spawn validators per wave, propagate failures |
| DB Validator | general-purpose | `e2e-evidence/db/` | Database schema and data validation |
| Web Validator | general-purpose | `e2e-evidence/web/` | Playwright-based web journey validation |
| API Validator | general-purpose | `e2e-evidence/api/` | HTTP endpoint validation with real requests |
| iOS Validator | general-purpose | `e2e-evidence/ios/` | Simulator-based iOS validation |
| CLI Validator | general-purpose | `e2e-evidence/cli/` | Direct CLI invocation and output capture |
| Design Validator | general-purpose | `e2e-evidence/design/` | Visual inspection, token audit, accessibility |
| Verdict Writer | general-purpose | `e2e-evidence/report.md` | Synthesize all evidence into unified report |

## Workflow

### Step 1: Platform Detection

Read `.validationforge/config.json` for detected platforms. Only spawn validators for detected platforms.

### Step 2: Journey Assignment

Partition validation plan journeys by platform. Each validator receives only its platform's journeys.

Build the wave plan using the `coordinated-validation` skill's dependency graph:

```
wave_plan = {
  wave_0: [p for p in detected_platforms if no dependencies],
  wave_1: [p for p in detected_platforms if all deps in wave_0],
  wave_2: [p for p in detected_platforms if all deps in wave_1],
  # ...
}
```

### Step 3: Spawn Validators (Wave-Based)

> **Replaces the previous single-round parallel spawn.** Use the `coordinated-validation` skill for dependency-aware execution.

Execute waves **sequentially**. Within each wave, spawn all assigned validators **in parallel** using `Agent` tool with `run_in_background: true`.

#### Wave Execution Loop

```
for wave in wave_plan:
  # Spawn all platforms in this wave in parallel
  for platform in wave.platforms:
    Agent(
      run_in_background: true,
      prompt: <validator prompt — see template below>
    )

  # Wait for ALL agents in the wave to complete
  wait_for_all(wave.agents)

  # Evaluate wave result
  failed = [p for p in wave.platforms if verdict[p] == "FAIL"]

  if failed:
    blocked = get_all_dependents(failed, dependency_graph)
    for p in blocked:
      record_blocked(p, blocked_by=failed)   # see Blocked Validator Handling
    remove_from_remaining_waves(blocked, wave_plan)
    # Continue to next wave (which may now be empty)
```

#### Validator Prompt MUST include:
- Platform name and wave number
- The validation plan (its journeys only)
- Evidence directory path (exclusive ownership)
- PASS criteria for each journey
- Evidence capture requirements
- Upstream context (what passed in prior waves, with key data points)
- The iron rules (no mocks, real evidence, cite specific proof)

### Blocked Validator Handling

When a platform in wave N receives a FAIL verdict, all platforms that depend on it (transitively) are **BLOCKED** — they are never spawned.

For each blocked platform:
1. **Skip the spawn** — do not create an agent
2. **Write a BLOCKED report** to `e2e-evidence/{platform}/report.md`:

```markdown
# {Platform} Validation — BLOCKED

This platform was not validated because an upstream dependency failed.

**Blocked by:** {failed_platform(s)}
**Upstream failure:** {brief description from upstream report}
**Status:** BLOCKED
**Action required:** Fix the {failed_platform} failures above, then re-run validation.
```

3. **Record BLOCKED status** in the wave state — treat as FAIL for overall verdict

Blocking rules:
- FAIL in a dependency → BLOCKED for all dependents (transitive)
- CONDITIONAL in a dependency → dependents proceed (with warning in their prompt)
- BLOCKED is distinct from FAIL in the report (root cause attribution differs)

### Step 4: Monitor Progress (with Dependency State Tracking)

While validators run, track the dependency state alongside completion status.

**Dependency state per platform:**

| State | Meaning |
|-------|---------|
| WAITING | Not yet spawned; waiting for wave N-1 to complete |
| RUNNING | Agent spawned and executing |
| PASS | Completed with PASS verdict |
| CONDITIONAL | Completed with CONDITIONAL verdict |
| FAIL | Completed with FAIL verdict |
| BLOCKED | Skipped because a dependency FAILed |

Monitor actions:
- Check validator progress via TaskOutput
- After each wave completes, update dependency state for all platforms in the next wave
- If a wave has no remaining platforms (all blocked), skip it and proceed to verdict
- Do not interfere with a running validator unless it is stuck > 5 min

Track state in `.vf/state/wave-plan.json`:

```json
{
  "wave_0": { "db": "PASS", "design": "PASS" },
  "wave_1": { "api": "FAIL" },
  "wave_2": { "web": "BLOCKED", "ios": "BLOCKED" }
}
```

### Step 5: Collect Results

When all waves complete (or all remaining platforms are BLOCKED):

1. Read each non-BLOCKED platform's `evidence-inventory.txt`
2. Verify evidence files exist and are non-empty (0-byte = INVALID)
3. For BLOCKED platforms, confirm the BLOCKED report was written

### Step 6: Verdict Synthesis

Spawn verdict-writer agent with all evidence directories as input. It produces the unified `e2e-evidence/report.md`.

Verdict aggregation:
- `FAIL` overrides `CONDITIONAL` overrides `PASS`
- `BLOCKED` counts as `FAIL` for overall verdict (root cause is the upstream failure)
- `INCOMPLETE` if any non-BLOCKED agent did not finish

### Step 7: Report

Present summary to user with per-platform, per-wave breakdown. See report template below.

## Report Template

```markdown
# Team Validation Report

**Date:** YYYY-MM-DD
**Platforms detected:** {list}
**Waves executed:** {N}
**Overall verdict:** PASS | CONDITIONAL | FAIL | INCOMPLETE

## Dependency Chain

DB → API → Web
          → iOS
Design (independent)
CLI    (independent)

## Wave Results

### Wave 0 — Independent Platforms

| Platform | Verdict | Evidence |
|----------|---------|---------|
| DB       | PASS    | e2e-evidence/db/report.md |
| Design   | PASS    | e2e-evidence/design/report.md |

### Wave 1 — API Layer

| Platform | Verdict | Evidence | Blocked By |
|----------|---------|---------|-----------|
| API      | FAIL    | e2e-evidence/api/report.md | — |

### Wave 2 — Frontend Layer

| Platform | Verdict | Evidence | Blocked By |
|----------|---------|---------|-----------|
| Web      | BLOCKED | e2e-evidence/web/report.md | API (Wave 1 FAIL) |
| iOS      | BLOCKED | e2e-evidence/ios/report.md | API (Wave 1 FAIL) |

## BLOCKED Platforms

| Platform | Blocked By | Reason |
|----------|-----------|--------|
| Web      | API       | API validator returned FAIL |
| iOS      | API       | API validator returned FAIL |

Blocked platforms were not executed. Fix the root-cause failure(s) above,
then re-run validation to obtain verdicts for these platforms.

## Platform Summaries

### DB (Wave 0) — PASS
{summary from db/report.md}

### API (Wave 1) — FAIL
{summary from api/report.md with specific failure evidence}

### Web (Wave 2) — BLOCKED
Not executed. Blocked by: API

### iOS (Wave 2) — BLOCKED
Not executed. Blocked by: API

## Issues Requiring Attention

{list of FAIL and BLOCKED items with evidence citations}

## Final Verdict Rationale

{explanation of overall verdict, root cause chain}
```

## Evidence Ownership Rules

- Each validator EXCLUSIVELY owns its evidence directory
- No validator may write to another validator's directory
- The lead writes BLOCKED reports to blocked platforms' directories
- The lead does NOT write validation evidence — only BLOCKED status reports and the final report
- If a validator needs cross-platform evidence (e.g., API call from web test), it captures its OWN evidence of the API response

## Conflict Resolution

| Conflict | Resolution |
|----------|-----------|
| Two validators need same endpoint | Each captures independently |
| Validator stuck > 5 min | Lead investigates, may reassign |
| Contradictory verdicts | Lead re-validates the specific journey |
| Missing evidence | Journey marked FAIL, not INCONCLUSIVE |
| Dependency cycle detected | Halt orchestration, report error, require manual dependency review |
| Wave N-1 CONDITIONAL (not FAIL) | Wave N proceeds with warning note in each validator prompt |

## Team Size Guidelines

| Platforms | Validators | Waves | Max Parallel per Wave |
|-----------|-----------|-------|-----------------------|
| 1 | 1 + verdict writer | 1 | 1 |
| 2 (independent) | 2 + verdict writer | 1 | 2 |
| 2 (API + Web) | 2 + verdict writer | 2 | 1 |
| 3-4 (fullstack) | 3-4 + verdict writer | 2-3 | 2 |
| 5 | 5 + verdict writer | 3 | 2 |

Never spawn more than 5 validators. For 5+ platforms, batch into rounds within waves.
