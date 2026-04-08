# Workflow: Full Run

**Objective:** Execute the complete validation pipeline end-to-end: analyze, plan, approve, execute, and report. This is the default workflow when no flags are specified.

## Pipeline Flow

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ ANALYZE  │───▶│   PLAN   │───▶│ APPROVE  │───▶│ EXECUTE  │───▶│  REPORT  │
│          │    │          │    │          │    │          │    │          │
│ Detect   │    │ Define   │    │ User     │    │ Build    │    │ Aggregate│
│ platform │    │ PASS     │    │ reviews  │    │ Run      │    │ verdicts │
│ Map      │    │ criteria │    │ plan     │    │ Capture  │    │ Generate │
│ journeys │    │ per      │    │          │    │ Review   │    │ report   │
│          │    │ journey  │    │          │    │ Verdict  │    │          │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
                                     │                │
                                     │           ┌────┴─────┐
                                  REJECT?        │ FAILURES │
                                     │           │ FOUND?   │
                                     ▼           └────┬─────┘
                                   STOP               │ (if --fix)
                                                      ▼
                                                ┌──────────┐
                                                │   FIX    │
                                                │          │
                                                │ 3-strike │◀──┐
                                                │ protocol │   │
                                                │          │───┘
                                                └────┬─────┘
                                                     │
                                                     ▼
                                                ┌──────────┐
                                                │  REPORT  │
                                                │ (updated)│
                                                └──────────┘
```

## Process

### Phase 1: Analyze

Execute `workflows/analyze.md`:
1. Run platform detection
2. Scan entry points
3. Map user journeys
4. Classify by priority
5. Output: `e2e-evidence/analysis.md`

### Phase 2: Plan

Execute `workflows/plan.md`:
1. Read analysis output
2. Define PASS criteria per journey
3. Assign evidence types
4. Set execution order
5. Output: `e2e-evidence/plan.md`

### Phase 3: Approve (Interactive Gate)

Present the plan to the user:

```
Validation plan generated for {platform} project:
- {N} journeys identified ({P0_count} critical, {P1_count} high)
- Estimated duration: {estimate}

Review the plan at: e2e-evidence/plan.md

Proceed with validation? [Y/n/edit]
```

| Response | Action |
|----------|--------|
| Y (or Enter) | Proceed to execution |
| n | Stop pipeline, keep plan for later |
| edit | User modifies plan, re-present for approval |

**Skip this gate** with `--ci` flag.

### Phase 4: Execute

Execute `workflows/execute.md`:
1. Build the real system
2. Start the real system
3. For each journey: navigate, act, capture, READ, match, verdict
4. Output: evidence files + verdict blocks

### Phase 5: Fix Loop (only if --fix)

If any journeys FAILED and `--fix` flag is active:

Execute `workflows/fix-and-revalidate.md`:
1. Triage failures
2. Apply 3-strike protocol per failure
3. Re-validate fixed journeys
4. Output: updated verdicts + fix log

### Phase 6: Report

Execute `workflows/report.md`:
1. Aggregate all verdicts
2. Compute summary statistics
3. Generate report
4. Output: `e2e-evidence/report.md`

## Parallel Execution (--parallel flag)

When `--parallel` is set, Phase 4 spawns sub-agents for independent journeys:

- Group journeys by dependency (journeys sharing state run sequentially)
- Independent journey groups run in parallel sub-agents
- Each sub-agent: navigate, capture, review, verdict
- Main agent: collects verdicts, writes report

**Dependency detection:** Journeys that modify shared state (database writes, file system changes) must run sequentially. Read-only journeys can run in parallel.

## Scope Limiting (--scope flag)

When `--scope <path>` is set:
- Only analyze files within the specified path
- Only include journeys whose entry points are within scope
- Useful for validating a single feature after a change

## Timeouts

| Phase | Default Timeout | Configurable |
|-------|----------------|-------------|
| Analyze | 60s | No |
| Plan | 30s | No |
| Approve | None (waits for user) | N/A |
| Execute (per journey) | 120s | `--timeout` flag |
| Fix (per strike) | 180s | No |
| Report | 30s | No |

## Output

- `e2e-evidence/analysis.md` — Journey inventory
- `e2e-evidence/plan.md` — Validation plan
- `e2e-evidence/j{N}-{slug}.{ext}` — Evidence files
- `e2e-evidence/report.md` — Final report
