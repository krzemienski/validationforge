---
name: validate-plan
description: Analyze codebase and generate a validation plan with PASS criteria — no execution.
---

# /validate-plan

Generate a structured validation plan without executing any validation steps. The plan identifies all user journeys, defines PASS criteria, and specifies what evidence is needed.

## Usage

```
/validate-plan                        # Full plan for entire project
/validate-plan --platform web         # Plan for web platform only
/validate-plan --scope src/dashboard/ # Plan limited to dashboard features
```

## Supported Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--platform PLATFORM` | auto-detect | Force platform. Values: `ios`, `web`, `api`, `cli`, `fullstack` |
| `--scope PATH` | entire project | Limit journey discovery to files under PATH |

## Pre-Pipeline: Read Config

Before generating the plan, read the ValidationForge config written by `/vf-setup`.

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

## What It Does

### 1. Platform Detection
Invokes `platform-detector` agent to scan the project and determine the platform type with confidence scoring.

### 2. Journey Discovery
Scans the codebase for user-facing flows:
- **iOS:** View controllers, SwiftUI views, navigation routes, storyboard scenes
- **Web:** Page components, route definitions, form components, navigation links
- **API:** Route handlers, endpoint definitions, middleware chains
- **CLI:** Subcommands, argument parsers, help text definitions
- **Fullstack:** All of the above, organized by layer (DB, API, Frontend)

### 3. PASS Criteria Definition
For each discovered journey, generates specific, measurable PASS criteria. Example:
```
Journey: J1 — User Login
  PASS if:
    1. Login page renders with email and password fields
    2. Valid credentials produce a session token (200 response)
    3. Invalid credentials show an error message (401 response)
    4. After login, user is redirected to dashboard
    5. Dashboard displays the logged-in user's name
```

### 4. Evidence Requirements
For each PASS criterion, specifies what evidence type to capture:
- Screenshot (with description of what must be visible)
- JSON response body (with expected fields)
- Terminal output (with expected content)
- Log entries (with expected patterns)

### 5. Execution Order
Orders journeys by dependency. Example: "Login" must pass before "Dashboard" can be validated.

## Output

Saves the plan to `e2e-evidence/validation-plan.md` with this structure:

```markdown
# Validation Plan
Generated: YYYY-MM-DD HH:MM
Platform: web (confidence: high)
Scope: entire project

## Journey Inventory
| # | Journey | Priority | Dependencies | Steps | Evidence Types |
|---|---------|----------|--------------|-------|----------------|
| J1 | User Login | HIGH | none | 5 | screenshot, json |
| J2 | Dashboard | HIGH | J1 | 3 | screenshot |
| J3 | Settings | MEDIUM | J1 | 4 | screenshot, json |

## Journey Details

### J1: User Login
**Priority:** HIGH
**Dependencies:** none

**PASS Criteria:**
1. Login page renders with email/password fields → screenshot
2. Valid credentials return 200 with token → json response
3. Invalid credentials return 401 with error → json response
4. Redirect to /dashboard after login → screenshot
5. Dashboard shows user name → screenshot

**Execution order:** 1 → 2 → 3 → 4 → 5 (sequential)

### J2: Dashboard
...
```

## After Planning

The plan requires explicit approval before execution. Run `/validate` to execute an approved plan, or modify the plan file directly before executing.
