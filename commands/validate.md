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
/validate --report                 # After validation, open a visual HTML dashboard in the browser
/validate --clean                  # Remove old evidence before validating
/validate --ai-analysis            # Enable AI analysis of captured evidence (overrides config)
/validate --no-ai-analysis         # Disable AI analysis for this run (overrides config)
```

## Supported Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--platform PLATFORM` | auto-detect | Override platform detection. Values: `ios`, `web`, `api`, `cli`, `fullstack` |
| `--scope PATH` | entire project | Limit journey discovery to files under PATH |
| `--parallel` | off | Run independent journey validations in parallel sub-agents |
| `--verbose` | off | Include raw evidence content inline in the report |
| `--fix` | off | After validation, automatically fix FAILs and re-validate (3-strike limit) |
| `--report` | off | After validation, generate and open a visual HTML dashboard in the default browser |
| `--clean` | off | Remove evidence older than configured retention period before running validation |
| `--ai-analysis` | config | Enable AI analysis of captured evidence. Overrides `ai_analysis.enabled` in config for this run. Set `VF_AI_ANALYSIS=disabled` to disable globally. |
| `--no-ai-analysis` | config | Disable AI analysis for this run. Overrides `ai_analysis.enabled` in config. Useful for offline or cost-sensitive environments. |

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

# AI analysis toggle — env var takes highest precedence, then --ai-analysis/--no-ai-analysis flags, then config
AI_ANALYSIS_ENABLED="true"  # default: enabled
if [ "${VF_AI_ANALYSIS:-}" = "disabled" ]; then
  AI_ANALYSIS_ENABLED="false"
elif [ -n "${FLAG_NO_AI_ANALYSIS:-}" ]; then
  AI_ANALYSIS_ENABLED="false"
elif [ -n "${FLAG_AI_ANALYSIS:-}" ]; then
  AI_ANALYSIS_ENABLED="true"
elif [ -f "$CONFIG_FILE" ]; then
  AI_ANALYSIS_ENABLED=$(jq -r '.ai_analysis.enabled // true | if . then "true" else "false" end' "$CONFIG_FILE" 2>/dev/null)
fi

# Print active config summary when VF_VERBOSE is set
if [ -n "${VF_VERBOSE:-}" ]; then
  echo "[vf] Config: enforcement=${ENFORCEMENT} | evidence_dir=${EVIDENCE_DIR} | platform=${PLATFORM:-auto-detect} | ai_analysis=${AI_ANALYSIS_ENABLED}"
fi
```

> **Note:** If `~/.claude/.vf-config.json` is missing, defaults apply automatically:
> `enforcement: standard`, `evidence_dir: e2e-evidence/`. Run `/vf-setup` to create a config.

### AI Analysis Environment Variable

`VF_AI_ANALYSIS=disabled` — Set this environment variable to globally disable AI analysis of captured evidence for all runs in the current shell session. This takes highest precedence over all flags and config settings. Useful for offline environments, CI pipelines where AI calls are cost-prohibitive, or when the analysis model is unavailable.

```bash
# Disable AI analysis for the entire session
export VF_AI_ANALYSIS=disabled
/validate

# Disable AI analysis for a single run only
VF_AI_ANALYSIS=disabled /validate
```

Priority order (highest to lowest):
1. `VF_AI_ANALYSIS=disabled` env var
2. `--no-ai-analysis` flag (disable for this run)
3. `--ai-analysis` flag (enable for this run)
4. `ai_analysis.enabled` in `~/.claude/.vf-config.json`
5. Default: enabled

## Pre-Pipeline: Evidence Cleanup (--clean)

When the `--clean` flag is passed, run the evidence cleanup script **before** the validation pipeline starts. Cleanup respects the in-progress lock — if another validation is actively running, cleanup aborts safely.

```bash
if [ -n "${FLAG_CLEAN:-}" ]; then
  # Read retention period from config (default: 30 days)
  RETENTION_DAYS=$(jq -r '.evidence_retention_days // 30' "$CONFIG_FILE" 2>/dev/null || echo "30")

  echo "[vf] --clean flag detected — removing evidence older than ${RETENTION_DAYS} days from ${EVIDENCE_DIR}/"

  if [ -f "scripts/evidence-cleanup.sh" ]; then
    bash scripts/evidence-cleanup.sh "$EVIDENCE_DIR" "$RETENTION_DAYS"
  else
    echo "[vf] WARNING: scripts/evidence-cleanup.sh not found — skipping cleanup." >&2
  fi
fi
```

> **Note:** Cleanup runs before the pipeline enters PREFLIGHT. It will not remove evidence from a
> currently active validation session — the in-progress lock (`.vf/state/validation-in-progress.lock`)
> prevents accidental deletion. Use `EVIDENCE_CLEANUP_DRY_RUN=1` to preview what would be removed
> without actually deleting anything.

## Pre-Pipeline: Active Validation Lock

Before entering PREFLIGHT, create a lock file to signal that a validation session is actively running. This prevents concurrent validations from colliding and prevents evidence cleanup from deleting files mid-run.

```bash
LOCK_FILE=".vf/state/validation-in-progress.lock"

# Ensure the lock directory exists
mkdir -p ".vf/state"

# Check if another validation is already running
if [ -f "$LOCK_FILE" ]; then
  echo "[vf] ERROR: Another validation is already in progress." >&2
  echo "[vf] Lock file: $LOCK_FILE" >&2
  echo "[vf] If no validation is running, remove the lock file manually and retry." >&2
  exit 1
fi

# Create the lock file with metadata
echo "pid=$$" > "$LOCK_FILE"
echo "started=$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOCK_FILE"
echo "platform=${PLATFORM:-auto-detect}" >> "$LOCK_FILE"
echo "[vf] Lock acquired: $LOCK_FILE"

# Register cleanup handler to remove lock on exit (success or failure)
trap 'rm -f "$LOCK_FILE"; echo "[vf] Lock released: $LOCK_FILE"' EXIT
```

> **Lock behavior:** The lock is acquired before PREFLIGHT and released automatically when the pipeline
> exits — whether it completes successfully, encounters an error, or is interrupted. The `trap EXIT`
> handler guarantees cleanup even on unexpected termination. If a stale lock exists from a crashed
> session, remove it manually with `rm .vf/state/validation-in-progress.lock`.
## Telemetry

After reading config, resolve the telemetry script path and emit a `command.invoked` event to record that `/validate` was started. All telemetry calls use `2>/dev/null || true` so they never block or fail the pipeline.

```bash
# Resolve plugin install directory (same pattern as vf-setup.md Step 4)
CONFIG_FILE="$HOME/.claude/.vf-config.json"
INSTALL_DIR=""

if [ -f "$CONFIG_FILE" ]; then
  INSTALL_DIR=$(jq -r '.installDir // empty' "$CONFIG_FILE" 2>/dev/null)
fi

# Fall back to CLAUDE_PLUGIN_ROOT, then to the default install path used by install.sh
INSTALL_DIR="${INSTALL_DIR:-${CLAUDE_PLUGIN_ROOT:-${HOME}/.claude/plugins/validationforge}}"
TELEMETRY_SH="${INSTALL_DIR}/scripts/telemetry.sh"

# Emit command.invoked at pipeline start
"${TELEMETRY_SH}" command.invoked command=validate 2>/dev/null || true
```

After Phase 0 (platform detection) resolves the platform, emit `platform.detected`:

```bash
# After platform is detected — ${PLATFORM} holds the resolved platform value
"${TELEMETRY_SH}" platform.detected platform="${PLATFORM}" 2>/dev/null || true
```

After each major pipeline phase completes, emit `pipeline.phase.completed`:

```bash
# After PREFLIGHT phase completes
"${TELEMETRY_SH}" pipeline.phase.completed phase=preflight 2>/dev/null || true

# After PLAN phase completes
"${TELEMETRY_SH}" pipeline.phase.completed phase=plan 2>/dev/null || true

# After EXECUTE phase completes
"${TELEMETRY_SH}" pipeline.phase.completed phase=execute 2>/dev/null || true

# After REPORT phase completes
"${TELEMETRY_SH}" pipeline.phase.completed phase=report 2>/dev/null || true
```

At the end of the pipeline, emit `validation.verdict` with the final outcome:

```bash
# Set VERDICT to "pass" or "fail" based on the report outcome
# VERDICT="pass"   # if all journeys passed
# VERDICT="fail"   # if any journey failed
"${TELEMETRY_SH}" validation.verdict verdict="${VERDICT}" 2>/dev/null || true
```

> **Note:** Telemetry is only transmitted when the user opted in during `/vf-setup`. The `2>/dev/null || true` guard ensures telemetry failures never interrupt validation. See [PRIVACY.md](../PRIVACY.md) for full details on what is and is not collected.

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

```
0. RESEARCH  → Standards, best practices, applicable criteria
1. PLAN      → Journeys, PASS criteria, evidence requirements
2. PREFLIGHT → Build compiles, services running, MCP servers available
3. EXECUTE   → Run journeys against real system, capture evidence
4. ANALYZE   → Root cause investigation for FAILs (sequential thinking)
5. VERDICT   → Evidence-backed PASS/FAIL per journey, unified report
6. SHIP      → Production readiness audit, deploy decision
```

> **Lock lifecycle:** The `validation-in-progress.lock` file is created before stage 2 (PREFLIGHT)
> and automatically removed after stage 5 (VERDICT) completes — or immediately if any stage fails.
> All pipeline stages from PREFLIGHT onward run within the lock window.

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
4b. **AI Analysis (optional):** If `ai_analysis.enabled` is `true` (and `VF_AI_ANALYSIS` is not `disabled`), invoke the `ai-evidence-analysis` skill on each captured evidence file. The skill assigns a confidence score (0–100) and produces structured findings (e.g., page load completeness for screenshots, schema compliance for API responses, error indicators for CLI output). Analysis results are saved alongside evidence as `e2e-evidence/{journey}/ai-analysis-step-NN-{description}.json` and tagged `ai_analyzed: true` in the evidence inventory. Skip this step when `AI_ANALYSIS_ENABLED="false"`.
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

After VERDICT completes, the lock file (`.vf/state/validation-in-progress.lock`) is released via the `trap EXIT` handler registered during pipeline startup.

### Phase 6: SHIP
Use `production-readiness-audit` skill to make the deploy decision. Security and deployment FAILs are blocking — do not ship. Other FAILs can be CONDITIONAL with documented risk acceptance. Produce a deploy recommendation based on the full verdict.

## Default Behavior (no flags)

When invoked as bare `/validate`:
1. Auto-detect platform from project files
2. Discover all user journeys
3. Generate plan and ask for approval
4. Execute all journeys sequentially
5. Write report to `e2e-evidence/report.md`

## Report Mode

When `--report` is passed, ValidationForge generates a self-contained HTML dashboard after the REPORT stage completes and opens it in your default browser.

### What the dashboard shows

| Section | Details |
|---------|---------|
| **Summary bar** | Overall PASS/FAIL verdict, total journeys, pass rate |
| **Journey cards** | Per-journey PASS/FAIL badge, evidence count, expandable evidence panel |
| **Screenshots** | Inline at full resolution with click-to-zoom |
| **API responses** | Formatted JSON/XML with syntax highlighting |
| **Build logs** | Raw log output with color-coded severity levels |
| **Trend chart** | Validation history over the last 30 days (reads `.vf/benchmarks/`) |

### How it works

1. After the REPORT stage writes `e2e-evidence/report.md`, ValidationForge reads all evidence files in `e2e-evidence/`
2. A single self-contained `e2e-evidence/dashboard.html` file is generated — no server required
3. The file embeds all screenshots as base64, all JSON as inline code blocks, and all chart data as inline JavaScript
4. Your default browser opens `e2e-evidence/dashboard.html` automatically

### Offline support

The dashboard has **no external dependencies**. All CSS, JavaScript, and assets are inlined. It can be shared as a single `.html` file and viewed anywhere without network access.

### Example usage

```bash
# Run validation and open visual dashboard when done
/validate --report

# Platform-specific validation with dashboard
/validate --platform web --report

# Validate, auto-fix failures, then open dashboard
/validate --fix --report
```

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

# Remove old evidence before validating (uses configured retention period)
/validate --clean

# Parallel validation for large projects
/validate --parallel --verbose
```

## Output

Final report saved to `e2e-evidence/report.md`. Evidence files saved to `e2e-evidence/` directory with descriptive names per journey and step.

Exit behavior:
- All journeys PASS: report ends with `Overall Verdict: PASS`
- Any journey FAIL: report ends with `Overall Verdict: FAIL` with root causes listed
