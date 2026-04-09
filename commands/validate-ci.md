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

## GitHub Actions Example

```yaml
name: Validation
on: [push, pull_request]

jobs:
  validate:
    runs-on: macos-latest   # Use macos for iOS, ubuntu for web/api/cli
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
