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

## Pre-Pipeline: Read Config

Before entering the pipeline, read the ValidationForge config written by `/vf-setup`.

```bash
CONFIG_FILE="$HOME/.claude/.vf-config.json"

# Defaults used when config is missing (enforcement: standard, evidence_dir: e2e-evidence/)
ENFORCEMENT="standard"
EVIDENCE_DIR="e2e-evidence"
CONFIG_PLATFORM=""

if [ -f "$CONFIG_FILE" ]; then
  ENFORCEMENT=$(jq -r '.enforcement // "standard"' "$CONFIG_FILE" 2>/dev/null)
  EVIDENCE_DIR=$(jq -r '.evidence_dir // "e2e-evidence"' "$CONFIG_FILE" 2>/dev/null)
  CONFIG_PLATFORM=$(jq -r '.platform // empty' "$CONFIG_FILE" 2>/dev/null)
else
  echo "[vf] No config found at $CONFIG_FILE — using defaults (enforcement: standard, evidence_dir: e2e-evidence/)"
fi

# Apply platform from config only if --platform flag was not provided
if [ -z "${FLAG_PLATFORM:-}" ] && [ -n "$CONFIG_PLATFORM" ] && [ "$CONFIG_PLATFORM" != "null" ]; then
  PLATFORM="$CONFIG_PLATFORM"
else
  PLATFORM="${FLAG_PLATFORM:-}"
fi

# Print active config summary when VF_VERBOSE is set
if [ -n "${VF_VERBOSE:-}" ]; then
  echo "[vf] Config: enforcement=${ENFORCEMENT} | evidence_dir=${EVIDENCE_DIR} | platform=${PLATFORM:-auto-detect}"
fi
```

> **Note:** If `~/.claude/.vf-config.json` is missing, defaults apply automatically:
> `enforcement: standard`, `evidence_dir: e2e-evidence/`. Run `/vf-setup` to create a config.

## Enforcement Level Behavior

The `enforcement` value from config gates how strictly the pipeline runs. Use this table to understand what each level requires at each stage:

| Behavior | `strict` | `standard` | `permissive` |
|----------|----------|------------|--------------|
| Require preflight before execution | ✅ Required — stop if preflight fails | ⚠️ Recommended — warn if skipped | Optional — continue even if skipped |
| Require plan approval before execute | ✅ Required — block until approved | ✅ Required — block until approved | Optional — proceed without approval |
| Fail on missing evidence | ✅ Fail journey if evidence absent | ⚠️ Warn but continue | Continue silently |
| Require baseline capture | ✅ Required before execute | Not required | Not required |
| Block test files / mocks | ✅ Hard block — write rejected | ✅ Hard block — write rejected | ⚠️ Warn only |
| Max fix attempts per journey | 3 | 3 | 5 |
| Require screenshot review | ✅ Required | Not required | Not required |

**How enforcement gates the pipeline:**

- **`strict`** — Maximum enforcement. Preflight must pass or the pipeline stops. Plan approval is mandatory. Every journey must have captured evidence or it is marked FAIL. Baseline must be captured before execute. Test files and mocks are hard-blocked.

- **`standard`** — Balanced enforcement (default). Plan approval is required before execute. Missing evidence produces a warning but does not auto-fail the journey. Preflight is recommended but does not stop the pipeline. Test files and mocks are hard-blocked.

- **`permissive`** — Minimal enforcement for teams transitioning from unit tests. Plan approval is optional — the pipeline continues if skipped. Missing evidence is noted but does not affect the verdict. Test file and mock creation produces a warning instead of a block.

> **Enforcement in code:** Check `ENFORCEMENT` variable after reading config. Branch on `strict` / `standard` / `permissive` at each gate point (preflight, approve, evidence check) to apply the correct behavior.

## Pipeline Stages

### 1. PREFLIGHT
Check that the system is runnable. Verify prerequisites for the detected platform (server running, simulator booted, binary built). If preflight fails, report what is missing and stop.

### 2. PLAN
Invoke the `platform-detector` agent to identify the platform. Then map all user-facing journeys by scanning routes, screens, commands, or endpoints. For each journey, define specific PASS criteria and required evidence types. Output a validation plan to `e2e-evidence/validation-plan.md`.

### 3. APPROVE (interactive only)
Present the validation plan to the user. Wait for approval before executing. The user may add, remove, or modify journeys. Skipped when `--ci` flag is used (see `/validate-ci`).

### 4. EXECUTE
For each approved journey:
1. Invoke the platform-specific validation skill (`ios-validation`, `web-validation`, `api-validation`, `cli-validation`, or `fullstack-validation`)
2. Perform real interactions with the running system
3. Capture evidence via the `evidence-capturer` agent
4. Save all evidence to `e2e-evidence/` with descriptive filenames

### 5. REPORT
Invoke the `verdict-writer` agent to:
1. Read every evidence file
2. Match evidence to PASS criteria
3. Write per-journey PASS/FAIL verdicts with cited evidence
4. Aggregate into a final report at `e2e-evidence/report.md`
5. Print summary to stdout

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
