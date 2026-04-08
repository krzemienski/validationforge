# Execution Workflow

## The ValidationForge Pipeline

```
0. RESEARCH → Understand what to validate and how
1. PLAN    → Define journeys, PASS criteria, evidence requirements
2. PREFLIGHT → Verify system is runnable
3. EXECUTE → Run journeys against real system, capture evidence
4. ANALYZE → Investigate FAILs, trace root causes
5. VERDICT → Write evidence-backed PASS/FAIL verdicts
6. SHIP    → Production readiness audit
```

## Phase Details

### Phase 0: Research
- Use `research-validation` skill to gather standards and best practices
- Identify applicable validation criteria (WCAG, HIG, security standards)
- Map standards to ValidationForge skills

### Phase 1: Plan
- Use `create-validation-plan` skill
- Define specific, measurable PASS criteria for each journey
- Specify evidence types needed per criterion
- Order journeys by dependency

### Phase 2: Preflight
- Use `preflight` skill
- Verify build compiles (`build-quality-gates`)
- Check runtime prerequisites (server, simulator, database)
- Verify required tools are available

### Phase 3: Execute
- Use platform-specific skills (ios-validation, playwright-validation, etc.)
- Use `parallel-validation` for multi-platform projects
- Capture evidence at every state transition
- Never skip a journey — run all, report all

### Phase 4: Analyze
- Use `sequential-analysis` for FAIL root cause investigation
- Use `visual-inspection` for UI defect classification
- Use `chrome-devtools` for deep browser debugging

### Phase 5: Verdict
- `verdict-writer` agent reads all evidence
- Produces per-journey PASS/FAIL with cited evidence
- Aggregates into final report

### Phase 6: Ship
- Use `production-readiness-audit` for deploy decision
- Security and deployment FAILs are blocking
- Other FAILs can be CONDITIONAL with documented risk acceptance

## Parallel Execution

Independent journeys and platforms can run in parallel:
```
parallel-validation dispatches:
├── ios-validation (background)
├── playwright-validation (background)
├── api-validation (background)
└── Collect all → unified verdict
```

## Fix Loop

When validation FAILs:
1. Read the FAIL verdict and cited evidence
2. Trace to specific source code
3. Apply minimal fix to the real system
4. Re-validate the failed journey
5. Max 3 attempts per journey (`validate-fix` protocol)
