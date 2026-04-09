---
name: validate
description: Run full end-to-end validation — detect platform, map journeys, capture evidence, write verdicts.
---

# /validate

Run the full ValidationForge validation pipeline. Detects your platform, maps user journeys, interacts with the REAL system, captures evidence, and writes PASS/FAIL verdicts.

## Usage

```
/validate                          # Full pipeline: detect + plan + approve + execute + report
/validate --platform ios           # Skip detection, force iOS validation
/validate --platform web           # Skip detection, force web validation
/validate --platform api           # Skip detection, force API validation
/validate --platform cli           # Skip detection, force CLI validation
/validate --scope src/auth/        # Limit validation to specific directory
/validate --parallel               # Use parallel sub-agents for independent journeys
/validate --verbose                # Include debug-level detail in report
/validate --fix                    # Alias for /validate-fix (fix failures + re-validate)
```

## Supported Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--platform PLATFORM` | auto-detect | Override platform detection. Values: `ios`, `web`, `api`, `cli`, `fullstack` |
| `--scope PATH` | entire project | Limit journey discovery to files under PATH |
| `--parallel` | off | Run independent journey validations in parallel sub-agents |
| `--verbose` | off | Include raw evidence content inline in the report |
| `--fix` | off | After validation, automatically fix FAILs and re-validate (3-strike limit) |

## Pipeline Stages

```
0. RESEARCH  → Standards, best practices, applicable criteria
1. PLAN      → Journeys, PASS criteria, evidence requirements
2. PREFLIGHT → Build compiles, services running, MCP servers available
3. EXECUTE   → Run journeys against real system, capture evidence
4. ANALYZE   → Root cause investigation for FAILs (sequential thinking)
5. VERDICT   → Evidence-backed PASS/FAIL per journey, unified report
6. SHIP      → Production readiness audit, deploy decision
```

### Phase 0: RESEARCH
Use the `research-validation` skill to gather standards and best practices. Identify applicable validation criteria (WCAG, HIG, security standards). Map standards to ValidationForge skills. Understand what to validate and how before planning begins.

### Phase 1: PLAN
Invoke the `platform-detector` agent to identify the platform. Then map all user-facing journeys by scanning routes, screens, commands, or endpoints. For each journey, define specific PASS criteria and required evidence types. Output a validation plan to `e2e-evidence/validation-plan.md`. In interactive mode, present the plan to the user for approval — the user may add, remove, or modify journeys. Skipped when `--ci` flag is used (see `/validate-ci`).

### Phase 2: PREFLIGHT
Use the `preflight` skill to check that the system is runnable. Verify build compiles (`build-quality-gates`). Check runtime prerequisites for the detected platform (server running, simulator booted, binary built). Verify required MCP servers and tools are available. If preflight fails, report what is missing and **stop** — do not proceed to execution.

### Phase 3: EXECUTE
For each approved journey:
1. Invoke the platform-specific validation skill (`ios-validation`, `web-validation`, `api-validation`, `cli-validation`, or `fullstack-validation`)
2. Perform real interactions with the running system
3. Capture evidence via the `evidence-capturer` agent at every state transition
4. Save all evidence to `e2e-evidence/` with descriptive filenames
5. Never skip a journey — run all, report all

### Phase 4: ANALYZE
For any journey that produced a FAIL result, use `sequential-analysis` skill to investigate root causes. Use `visual-inspection` for UI defect classification. Use `chrome-devtools` for deep browser debugging. Trace failures to specific source code before attempting fixes.

### Phase 5: VERDICT
Invoke the `verdict-writer` agent to:
1. Read every evidence file
2. Match evidence to PASS criteria
3. Write per-journey PASS/FAIL verdicts with cited evidence
4. Aggregate into a final report at `e2e-evidence/report.md`
5. Print summary to stdout

Never produce a partial verdict — wait for ALL validators before writing the report.

### Phase 6: SHIP
Use `production-readiness-audit` skill to make the deploy decision. Security and deployment FAILs are blocking — do not ship. Other FAILs can be CONDITIONAL with documented risk acceptance. Produce a deploy recommendation based on the full verdict.

## Default Behavior (no flags)

When invoked as bare `/validate`:
1. Auto-detect platform from project files
2. Discover all user journeys
3. Generate plan and ask for approval
4. Execute all journeys sequentially
5. Write report to `e2e-evidence/report.md`

## The Iron Rule

```
IF the real system doesn't work, FIX THE REAL SYSTEM.
NEVER create mocks, stubs, test doubles, or test files.
NEVER mark a journey PASS without specific evidence.
```

## Examples

```bash
# Validate an iOS app
/validate --platform ios

# Validate only the auth module of a web app
/validate --platform web --scope src/auth/

# Full validation with auto-fix for failures
/validate --fix

# Parallel validation for large projects
/validate --parallel --verbose
```

## Output

Final report saved to `e2e-evidence/report.md`. Evidence files saved to `e2e-evidence/` directory with descriptive names per journey and step.

Exit behavior:
- All journeys PASS: report ends with `Overall Verdict: PASS`
- Any journey FAIL: report ends with `Overall Verdict: FAIL` with root causes listed
