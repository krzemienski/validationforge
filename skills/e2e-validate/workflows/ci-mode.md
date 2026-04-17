# Workflow: CI Mode

**Objective:** Run the full validation pipeline in non-interactive mode for CI/CD integration. No approval gates, no interactive prompts, deterministic exit codes.

## Prerequisites

- System source code accessible
- Build tools installed
- Required services available (database, external APIs)

## Differences from Interactive Mode

| Aspect | Interactive (default) | CI Mode (`--ci`) |
|--------|----------------------|------------------|
| Approval gate | Pauses for user review | Skipped — proceeds automatically |
| User prompts | May ask clarifying questions | Never prompts — uses defaults |
| Evidence display | Shows evidence inline | Saves to files only |
| Fix loop | Asks before fixing | If `--fix` set, fixes automatically |
| Output format | Rich markdown | Structured for pipeline parsing |
| Exit code | Not used | 0 = all PASS, 1 = any FAIL |

## Process

### Step 1: Preflight Gate (MANDATORY — Iron Rule #4)

Before any pipeline phase, invoke the `preflight` skill. See
`../../../skills/preflight/SKILL.md`.

```bash
# Preflight is the first step; its verdict controls whether the pipeline
# proceeds. See skills/preflight for the full checklist.
# Preflight writes its report to e2e-evidence/preflight-report.md.
```

**Exit behavior in CI mode:**
- Preflight verdict `CLEAR` → proceed to Step 2.
- Preflight verdict `WARN` → proceed to Step 2, log warning on stdout in
  structured form: `[VALIDATE] phase=preflight status=WARN`.
- Preflight verdict `BLOCKED` → **exit 2** (pipeline error). Write the
  preflight report to the evidence artifact directory so CI can surface
  it. Do NOT run Analyze, Plan, Execute, or Fix against a BLOCKED
  preflight — this violates Iron Rule #4.

The `--skip-preflight` override is accepted only when explicitly passed
(emergency use; logs a warning). Never skip preflight silently.

### Step 2: Environment Validation

Additional environment sanity checks beyond what preflight covers (e.g.,
CI-specific concerns like disk space for the artifact upload):

```bash
# Check build tools exist
command -v node npm pnpm yarn cargo go python3 swift xcodebuild 2>/dev/null

# Check required services (preflight covers the platform-relevant ones)
curl -sf http://localhost:5432 > /dev/null 2>&1  # PostgreSQL
curl -sf http://localhost:6379 > /dev/null 2>&1  # Redis

# Check disk space for evidence
df -h . | awk 'NR==2 {print $4}'
```

Log available tools and services. Proceed with what's available — don't fail because an unneeded tool is missing.

### Step 3: Run Full Pipeline

Execute the same phases as `workflows/full-run.md` but without pauses:

1. **Preflight** — done in Step 1 above
2. **Analyze** — `workflows/analyze.md` (no changes)
3. **Plan** — `workflows/plan.md` (skip approval gate)
4. **Execute** — `workflows/execute.md` (no changes)
5. **Fix** — `workflows/fix-and-revalidate.md` (only if `--fix` flag set)
6. **Report** — `workflows/report.md` (no changes)

### Step 4: Structured Output

Print structured progress to stdout for pipeline log parsing:

```
[VALIDATE] phase=analyze status=start
[VALIDATE] phase=analyze platform=web journeys=12
[VALIDATE] phase=analyze status=complete
[VALIDATE] phase=plan status=start
[VALIDATE] phase=plan criteria=34
[VALIDATE] phase=plan status=complete
[VALIDATE] phase=execute status=start
[VALIDATE] phase=execute journey=J1 name="Login Flow" status=start
[VALIDATE] phase=execute journey=J1 status=PASS evidence=e2e-evidence/j1-login.png
[VALIDATE] phase=execute journey=J2 name="Dashboard" status=start
[VALIDATE] phase=execute journey=J2 status=FAIL reason="Expected 41 items, got 0"
...
[VALIDATE] phase=execute status=complete passed=10 failed=2 total=12
[VALIDATE] phase=report status=start
[VALIDATE] phase=report path=e2e-evidence/report.md
[VALIDATE] phase=report status=complete
[VALIDATE] result=FAIL passed=10 failed=2 total=12
```

### Step 5: Evidence Artifact Path

Save all evidence to a configurable directory for CI artifact upload:

```
Default:  ./e2e-evidence/
Override: --evidence-dir /path/to/artifacts/

Contents after run:
  e2e-evidence/
  ├── analysis.md          # Journey inventory
  ├── plan.md              # Validation plan
  ├── report.md            # Final report
  ├── j1-login.png         # Journey evidence
  ├── j2-dashboard.json    #
  ├── j3-export.txt        #
  └── ...
```

CI systems can upload this directory as build artifacts:

```yaml
# GitHub Actions
- uses: actions/upload-artifact@v4
  with:
    name: e2e-evidence
    path: e2e-evidence/

# GitLab CI
artifacts:
  paths:
    - e2e-evidence/
  when: always
```

### Step 6: Exit Codes

| Code | Meaning | When |
|------|---------|------|
| 0 | All journeys PASS | Every PASS criterion met |
| 1 | One or more journeys FAIL | Any PASS criterion not met |
| 2 | Pipeline error | Build failed, system won't start, evidence capture broken |

### Step 7: Timeout Handling

CI environments have hard time limits. Handle gracefully:

- If a journey exceeds its timeout, mark it as FAIL with reason "timeout"
- If total pipeline exceeds CI timeout, write partial report before exiting
- Always write the report file, even on timeout — partial results are better than no results

```bash
# Recommended CI timeout settings
# GitHub Actions: timeout-minutes: 30
# GitLab CI: timeout: 30 minutes
# Jenkins: timeout(time: 30, unit: 'MINUTES')
```

## Integration Examples

### GitHub Actions

```yaml
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup
        run: npm install
      - name: Validate
        run: claude --skill validate --ci
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: e2e-evidence
          path: e2e-evidence/
```

### Pre-merge Gate

```yaml
# Require validation to pass before merge
validate:
  script:
    - claude --skill validate --ci --fix
  allow_failure: false
```

## Output

- `e2e-evidence/report.md` — Final report
- `e2e-evidence/` — All evidence artifacts
- Structured stdout log for pipeline parsing
- Exit code: 0 (pass), 1 (fail), 2 (error)
