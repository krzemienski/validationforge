# Workflow: Full Run

**Objective:** Execute the complete validation pipeline end-to-end across all 7 phases: Research → Plan → Preflight → Execute → Analyze → Verdict → Ship. This is the default workflow when no flags are specified.

## Pipeline Flow

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Phase 0  │───▶│ Phase 1  │───▶│ Phase 2  │───▶│ Phase 3  │
│ RESEARCH │    │   PLAN   │    │PREFLIGHT │    │ EXECUTE  │
│          │    │          │    │          │    │          │
│ Gather   │    │ Define   │    │ Build    │    │ Run      │
│ standards│    │ journeys │    │ compiles │    │ journeys │
│ Map      │    │ PASS     │    │ Services │    │ Capture  │
│ criteria │    │ criteria │    │ running  │    │ evidence │
└──────────┘    └──────────┘    └──────┬───┘    └────┬─────┘
                                       │              │
                                  FAIL?│         FAIL?│
                                       ▼              ▼
                                     STOP           (fix loop
                                                    if --fix)
                                                       │
┌──────────┐    ┌──────────┐    ┌──────────┐          │
│ Phase 6  │◀───│ Phase 5  │◀───│ Phase 4  │◀─────────┘
│   SHIP   │    │ VERDICT  │    │ ANALYZE  │
│          │    │          │    │          │
│ Prod     │    │ Evidence-│    │ Root     │
│ readiness│    │ backed   │    │ cause    │
│ audit    │    │ PASS/FAIL│    │ invest.  │
│ Deploy   │    │ per      │    │ FAILs    │
│ decision │    │ journey  │    │ only     │
└──────────┘    └──────────┘    └──────────┘
     │
     ▼
SHIP | CONDITIONAL SHIP | HOLD
```

### Fix Loop Detail (--fix flag)

```
                                ┌──────────┐
                                │   FIX    │
                                │          │
                                │ 3-strike │◀──┐
                                │ protocol │   │
                                │          │───┘
                                └────┬─────┘
                                     │
                                     ▼
                               Re-run Phase 3
                               (EXECUTE) for
                               failed journeys
```

## Process

### Phase 0: Research

Execute `workflows/research.md`:
1. Scope the validation domain (web, iOS, API, CLI, fullstack)
2. Gather applicable standards (WCAG, OWASP, HIG, Core Web Vitals)
3. Inventory available validation tools
4. Map standards to ValidationForge skills
5. Output: `e2e-evidence/research/report.md`

Skills used: `research-validation`

### Phase 1: Plan

Execute `workflows/plan.md`:
1. Read research report
2. Define specific, measurable PASS criteria per journey
3. Assign evidence types per criterion
4. Order journeys by dependency and priority
5. Output: `e2e-evidence/plan.md`

Skills used: `create-validation-plan`

**Interactive Gate (non-CI):** Present plan to user before proceeding.

```
Validation plan generated for {platform} project:
- {N} journeys identified ({P0_count} critical, {P1_count} high)
- Standards: {standards list}
- Estimated duration: {estimate}

Review the plan at: e2e-evidence/plan.md

Proceed with validation? [Y/n/edit]
```

| Response | Action |
|----------|--------|
| Y (or Enter) | Proceed to Phase 2 |
| n | Stop pipeline, keep plan for later |
| edit | User modifies plan, re-present for approval |

**Skip this gate** with `--ci` flag.

### Phase 2: Preflight

Execute `workflows/preflight.md`:
1. Verify build compiles without errors
2. Check runtime prerequisites (server, simulator, database)
3. Verify required tools are available (playwright, xcrun, curl, etc.)
4. Confirm MCP servers are reachable if needed
5. Output: `e2e-evidence/preflight.md`

Skills used: `preflight`, `build-quality-gates`

**Phase Gate:** If preflight FAILS, STOP the pipeline. Do not proceed to Execute.

```
Preflight status:
  Build: PASS | FAIL
  Services: PASS | FAIL
  Tools: PASS | FAIL

→ If any FAIL: pipeline halted. Fix prerequisites before retrying.
```

### Phase 3: Execute

Execute `workflows/execute.md`:
1. For each journey in the plan: navigate, act, capture evidence, READ output
2. Match observations against PASS criteria
3. Record verdict block per journey (PASS / FAIL / UNRESOLVED)
4. Never skip a journey — run all, report all
5. Output: `e2e-evidence/{journey-slug}/` directories with evidence

Skills used: `ios-validation`, `playwright-validation`, `api-validation`, `cli-validation` (platform-dependent)

Use `parallel-validation` for independent journeys when `--parallel` flag is set.

### Phase 4: Analyze

Execute `workflows/analyze.md` (post-execution analysis):
1. For each FAIL verdict, investigate root cause
2. Trace failures to specific source code or configuration
3. Classify defect severity
4. Record findings for verdict enrichment
5. Output: `e2e-evidence/analysis.md`

Skills used: `sequential-analysis`, `visual-inspection`, `chrome-devtools`

**Only runs for journeys with FAIL or UNRESOLVED verdicts.** PASS journeys are skipped.

### Fix Loop (only if --fix)

If any journeys FAILED after Phase 4 and `--fix` flag is active:

Execute `workflows/fix-and-revalidate.md`:
1. Triage failures by severity and fix feasibility
2. Apply 3-strike protocol per failure:
   - Attempt 1: Apply minimal fix to the real system
   - Re-execute the failed journey
   - Attempt 2: Broader fix if attempt 1 fails
   - Re-execute the failed journey
   - Attempt 3: Final attempt, document if still failing
3. Re-validate fixed journeys (return to Phase 3 for those journeys only)
4. Output: updated verdicts + `e2e-evidence/fix-log.md`

**Max 3 attempts per journey.** After 3 strikes, mark UNRESOLVED and continue.

### Phase 5: Verdict

Execute `workflows/verdict.md`:
1. `verdict-writer` agent reads all evidence from `e2e-evidence/`
2. Produces per-journey PASS/FAIL with cited evidence (no evidence = no PASS)
3. Computes summary statistics
4. Generates unified report
5. Output: `e2e-evidence/report.md`

Skills used: `verdict-writer` agent

### Phase 6: Ship

Execute `workflows/ship.md`:
1. Read Phase 5 report
2. Run `production-readiness-audit` (8 sub-phases)
3. Evaluate blocking criteria (security FAILs, deployment FAILs are blocking)
4. Compute ship verdict
5. Output: `e2e-evidence/ship-report.md`

Skills used: `production-readiness-audit`

| Feature Validation | Prod Audit | Ship Verdict |
|-------------------|------------|--------------|
| PASS | READY | **SHIP** |
| PASS | CONDITIONAL | **CONDITIONAL SHIP** |
| PASS | NOT READY | **HOLD** |
| PARTIAL | READY | **CONDITIONAL SHIP** |
| FAIL | (any) | **HOLD** |

## Parallel Execution (--parallel flag)

When `--parallel` is set, Phase 3 spawns sub-agents for independent journeys:

- Group journeys by dependency (journeys sharing state run sequentially)
- Independent journey groups run in parallel sub-agents
- Each sub-agent: navigate, capture, review, verdict
- Main agent: collects verdicts, passes to Phase 4

```
parallel-validation dispatches:
├── ios-validation (background)      → e2e-evidence/ios/
├── playwright-validation (background) → e2e-evidence/web/
├── api-validation (background)      → e2e-evidence/api/
└── Collect all → Phase 4 (Analyze)
```

**Dependency detection:** Journeys that modify shared state (database writes, file system changes) must run sequentially. Read-only journeys can run in parallel.

## Scope Limiting (--scope flag)

When `--scope <path>` is set:
- Only analyze files within the specified path
- Only include journeys whose entry points are within scope
- Useful for validating a single feature after a change

## Timeouts

| Phase | Default Timeout | Configurable |
|-------|----------------|-------------|
| Phase 0: Research | 120s | No |
| Phase 1: Plan | 60s | No |
| Phase 2: Preflight | 60s | No |
| Phase 3: Execute (per journey) | 120s | `--timeout` flag |
| Phase 4: Analyze | 60s | No |
| Phase 5: Verdict | 30s | No |
| Phase 6: Ship | 120s | No |
| Fix (per strike) | 180s | No |

## Output

- `e2e-evidence/research/` — Phase 0 research artifacts
- `e2e-evidence/plan.md` — Phase 1 validation plan
- `e2e-evidence/preflight.md` — Phase 2 preflight results
- `e2e-evidence/{journey-slug}/` — Phase 3 evidence per journey
- `e2e-evidence/analysis.md` — Phase 4 root cause analysis
- `e2e-evidence/report.md` — Phase 5 verdict report
- `e2e-evidence/ship-report.md` — Phase 6 ship decision
