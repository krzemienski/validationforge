---
name: validate-ci
description: Non-interactive CI/CD mode — auto-execute full validation pipeline with exit codes.
---

# /validate-ci

Run the full validation pipeline without interactive prompts. Designed for CI/CD pipelines where no human is available to approve the validation plan. Exits with code 0 (all pass) or 1 (any fail).

## Usage

```
/validate-ci                                  # Full CI validation
/validate-ci --platform web                   # Force web platform
/validate-ci --scope src/api/                 # Limit scope
/validate-ci --platform api --scope src/api/  # Combined
```

## Supported Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--platform PLATFORM` | auto-detect | Force platform detection |
| `--scope PATH` | entire project | Limit journey discovery to PATH |

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
  echo "[vf] WARNING: No config found at $CONFIG_FILE — run /vf-setup first to configure ValidationForge."
  echo "[vf] Continuing with defaults (enforcement: standard, evidence_dir: e2e-evidence/)"
fi

# Apply platform from config only if --platform flag was not provided
if [ -z "${FLAG_PLATFORM:-}" ] && [ -n "$CONFIG_PLATFORM" ] && [ "$CONFIG_PLATFORM" != "null" ]; then
  PLATFORM="$CONFIG_PLATFORM"
else
  PLATFORM="${FLAG_PLATFORM:-}"
fi
```

> **Note:** In CI mode, a missing `~/.claude/.vf-config.json` is a **warning, not a failure** — defaults apply and the pipeline continues. Run `/vf-setup` locally and commit the resulting config to avoid this warning in future runs.

## Telemetry

After reading config, resolve the telemetry script path and emit a `command.invoked` event to record that `/validate-ci` was started. All telemetry calls use `2>/dev/null || true` so they never block or fail the pipeline.

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
"${TELEMETRY_SH}" command.invoked command=validate-ci 2>/dev/null || true
```

At the end of the pipeline, emit `validation.verdict` with the final outcome:

```bash
# Set VERDICT to "pass" or "fail" based on the report outcome
# VERDICT="pass"   # if all journeys passed
# VERDICT="fail"   # if any journey failed
"${TELEMETRY_SH}" validation.verdict verdict="${VERDICT}" 2>/dev/null || true
```

> **Note:** Telemetry failures are always silent in CI mode — the `2>/dev/null || true` guard ensures no telemetry error can affect exit codes or break the pipeline. Telemetry is only transmitted when the user opted in during `/vf-setup`. See [PRIVACY.md](../PRIVACY.md) for full details on what is and is not collected.

## Differences from `/validate`

| Behavior | `/validate` | `/validate-ci` |
|----------|-------------|-----------------|
| Plan approval | Asks user | Skipped — auto-approved |
| Interactive prompts | Yes | None |
| Fix on failure | Optional (`--fix`) | Never — report and exit |
| Exit code | Not applicable | 0 = PASS, 1 = FAIL |
| Evidence location | `e2e-evidence/` | `e2e-evidence/` (same) |

## Pipeline Stages

### 1. PREFLIGHT (auto)
Verify prerequisites. If preflight fails, exit 1 with diagnostic message.

### 2. DETECT (auto)
Platform detection. No user override prompt — use `--platform` flag instead.

### 3. PLAN (auto-approved)
Generate validation plan. Skip approval gate. Plan saved to `e2e-evidence/validation-plan.md`.

### 4. EXECUTE (auto)
Run all journey validations sequentially. Capture all evidence. Do not stop on first failure — run all journeys to produce a complete report.

### 5. REPORT (auto)
Write final report to `e2e-evidence/report.md`. Print summary to stdout.

### 6. EXIT
```
if all journeys PASS:
  exit 0
else:
  exit 1
```

## Evidence Artifacts

All evidence is saved to `e2e-evidence/`. Configure your CI to upload this directory as build artifacts:

```
e2e-evidence/
  validation-plan.md       # What was planned
  report.md                # Final PASS/FAIL verdicts
  *.png                    # Screenshots
  *.json                   # API responses
  *.txt                    # CLI output, logs
```

## GitHub Actions Starter

For a production-ready GitHub Actions setup, use the provided starter template. It handles dependency installation, service startup, server readiness, validation execution, and evidence upload in a single file.

**Template:** [`templates/github-actions-validate.yml`](templates/github-actions-validate.yml)  
**Integration guide:** [`docs/github-actions-integration.md`](docs/github-actions-integration.md)

### What the Template Does

| Step | Action | Purpose |
|------|--------|---------|
| `checkout` | `actions/checkout@v4` | Check out repository at the triggering commit |
| `setup-node` | `actions/setup-node@v4` | Install Node.js and enable pnpm caching |
| `install` | `pnpm install --frozen-lockfile` | Install exact dependencies from lockfile |
| `dev-server` | `pnpm dev &` | Start the dev server in the background |
| `wait-for-server` | `curl` health-check loop | Block until the server is accepting connections |
| `validate` | `claude --print "/validate-ci"` | Run the full ValidationForge pipeline, exit 1 on fail |
| `upload-evidence` | `actions/upload-artifact@v4` | Archive `e2e-evidence/` as a build artifact (always) |

Copy the template to `.github/workflows/github-actions-validate.yml` in your project, then customise the `PLATFORM` and `SERVER_URL` environment variables for your stack. See [`docs/github-actions-integration.md`](docs/github-actions-integration.md) for full configuration options.

## GitHub Actions Example

> **Recommended:** Use the [starter template](templates/github-actions-validate.yml) instead of writing from scratch. The snippet below is a minimal reference only.

```yaml
name: Validation
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest   # Use macos-latest for iOS
    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: pnpm install

      - name: Start dev server
        run: pnpm dev &

      - name: Wait for server
        run: |
          for i in $(seq 1 30); do
            curl -s http://localhost:3000 > /dev/null && break
            sleep 1
          done

      - name: Run ValidationForge
        run: claude --print "/validate-ci --platform web"

      - name: Upload evidence
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: validation-evidence
          path: e2e-evidence/
          retention-days: 30
```

## GitLab CI Example

```yaml
validate:
  stage: test
  image: node:20
  script:
    - pnpm install
    - pnpm dev &
    - sleep 10
    - claude --print "/validate-ci --platform web"
  artifacts:
    when: always
    paths:
      - e2e-evidence/
    expire_in: 30 days
```

## Exit Code Reference

| Code | Meaning |
|------|---------|
| 0 | All journeys PASS — validation succeeded |
| 1 | One or more journeys FAIL — see report for details |

CI pipelines should treat exit code 1 as a build failure. The `e2e-evidence/report.md` file contains the full diagnosis with root causes for each FAIL verdict.
