---
name: vf-setup
description: Setup and configure ValidationForge for a project or globally
triggers:
  - "setup validationforge"
  - "vf setup"
  - "configure validation"
  - "install validationforge"
---

# ValidationForge Setup

The only command you need to learn. After running this, validation enforcement is automatic.

**When this skill is invoked, immediately execute the workflow below.**

## Pre-Setup Check

```bash
CONFIG_FILE="$HOME/.claude/.vf-config.json"

if [ -f "$CONFIG_FILE" ]; then
  SETUP_COMPLETED=$(jq -r '.setupCompleted // empty' "$CONFIG_FILE" 2>/dev/null)
  SETUP_VERSION=$(jq -r '.setupVersion // empty' "$CONFIG_FILE" 2>/dev/null)

  if [ -n "$SETUP_COMPLETED" ] && [ "$SETUP_COMPLETED" != "null" ]; then
    echo "ValidationForge setup was completed on: $SETUP_COMPLETED"
    [ -n "$SETUP_VERSION" ] && echo "Version: $SETUP_VERSION"
    ALREADY_CONFIGURED="true"
  fi
fi
```

### If Already Configured

Use AskUserQuestion:

**Question:** "ValidationForge is already configured. What would you like to do?"

**Options:**
1. **Update rules only** — Refresh validation rules without full setup
2. **Run full setup** — Complete setup wizard
3. **Cancel** — Exit

## Flags

| Flag | Behavior |
|------|----------|
| `--local` | Install project-level CLAUDE.md + rules (default) |
| `--global` | Install to `~/.claude/` for all projects |
| `--strict` | Use strict enforcement config |
| `--standard` | Use standard enforcement config (default) |
| `--permissive` | Use permissive enforcement config |
| `--force` | Re-run even if already configured |
| `--platform ios\|web\|api\|cli` | Pre-configure platform detection |

## Setup Workflow

### Step 0: Resume Detection

```bash
STATE_FILE=".vf/state/setup-state.json"

# Ensure the state directory exists before attempting to read state
mkdir -p .vf/state

if [ -f "$STATE_FILE" ]; then
  LAST_STEP=$(jq -r ".lastCompletedStep // 0" "$STATE_FILE" 2>/dev/null)
  TIMESTAMP=$(jq -r ".timestamp // empty" "$STATE_FILE" 2>/dev/null)
  echo "Found previous setup session (Step $LAST_STEP at $TIMESTAMP)"
fi
```

If state exists, prompt to resume or start fresh.

### Step 1: Detect Scope

Use AskUserQuestion:

**Question:** "Where should ValidationForge be configured?"

**Options:**
1. **This project only** (Recommended) — Rules in `.claude/CLAUDE.md`, evidence in `e2e-evidence/`
2. **All projects (global)** — Rules in `~/.claude/CLAUDE.md`
3. **Both** — Global defaults + project overrides

### Step 2: Platform Detection

Run the `platform-detector` agent to auto-detect the project type.

```
Launch agent: platform-detector
→ Returns: { platform, confidence, indicators_found }
```

Present results:

**Question:** "Detected platform: {platform} ({confidence} confidence). Is this correct?"

**Options:**
1. **Yes, use {platform}** — Proceed with detected platform
2. **No, it's {alternatives}** — Override with correct platform
3. **Multi-platform** — Configure for fullstack validation

### Step 3: Enforcement Level

Use AskUserQuestion:

**Question:** "What enforcement level do you want?"

**Options:**
1. **Strict** — All hooks active, blocks test files + mocks + false claims. Recommended for production projects.
   Config: `config/strict.json`
   Hooks: `block-test-files` (block), `evidence-gate-reminder` (enabled), `validation-not-compilation` (enabled), `completion-claim-validator` (enabled), `mock-detection` (enabled)
   Rules: requires validation plan, preflight, baseline, screenshot review; fails on missing evidence
2. **Standard** (Recommended) — Core hooks active, warnings for best practices.
   Config: `config/standard.json`
   Hooks: `block-test-files` (block), `evidence-gate-reminder` (enabled), `validation-not-compilation` (enabled), `completion-claim-validator` (enabled), `mock-detection` (enabled)
   Rules: blocks test files and mocks; evidence reminders active; no strict preflight or baseline requirement
3. **Permissive** — Advisory hooks only, warns but does not block. For teams transitioning from unit tests.
   Config: `config/permissive.json`
   Hooks: `block-test-files` (warn), `evidence-gate-reminder` (enabled), `validation-not-compilation` (enabled), `completion-claim-validator` (warn), `mock-detection` (warn)
   Rules: no blocking rules active; all gates are advisory only

Store the selected level for use in subsequent steps:

```bash
# ENFORCEMENT_LEVEL is set to: "strict" | "standard" | "permissive"
ENFORCEMENT_LEVEL="standard"   # replace with actual user selection
```

### Step 4: Install Rules

Based on scope (local or global), copy rules from the ValidationForge plugin directory.

First, resolve the plugin installation directory:

```bash
# Resolve plugin install directory from config written by install.sh
CONFIG_FILE="$HOME/.claude/.vf-config.json"
INSTALL_DIR=""

if [ -f "$CONFIG_FILE" ]; then
  INSTALL_DIR=$(jq -r '.installDir // empty' "$CONFIG_FILE" 2>/dev/null)
fi

# Fall back to CLAUDE_PLUGIN_ROOT (set by Claude Code when loading plugins),
# then to the default install path used by install.sh
INSTALL_DIR="${INSTALL_DIR:-${CLAUDE_PLUGIN_ROOT:-${HOME}/.claude/plugins/validationforge}}"
RULES_SOURCE="${INSTALL_DIR}/rules"

if [ ! -d "$RULES_SOURCE" ]; then
  echo "ERROR: Rules source directory not found: $RULES_SOURCE"
  echo "       Re-run the installer: curl -fsSL https://raw.githubusercontent.com/krzemienski/validationforge/main/install.sh | bash"
  exit 1
fi
```

#### Local Install (`.claude/` in project root)

```bash
# Local install — copy from plugin rules/ to .claude/rules/ (no prefix)
mkdir -p .claude/rules

for rule_file in "${RULES_SOURCE}"/*.md; do
  rule_name=$(basename "$rule_file" .md)
  cp "$rule_file" ".claude/rules/${rule_name}.md"
  echo "  [OK] .claude/rules/${rule_name}.md"
done

echo "  Rules installed from: ${RULES_SOURCE}"
echo "  Rules installed to:   $(pwd)/.claude/rules/"
```

Expected result:
```
.claude/
  rules/
    validation-discipline.md    ← No-mock mandate
    evidence-management.md      ← Evidence directory + naming
    platform-detection.md       ← Platform routing rules
    execution-workflow.md       ← 7-phase pipeline
    team-validation.md          ← Multi-agent validation teams
    forge-execution.md          ← Fix loop discipline
    forge-team-orchestration.md ← Validator assignment + verdict synthesis
    benchmarking.md             ← Metric collection + benchmarks
```

Also install CLAUDE.md:
```bash
# Copy CLAUDE.md template from plugin (skip if project already has one)
cp "${INSTALL_DIR}/CLAUDE.md" .claude/CLAUDE.md 2>/dev/null || true
```

#### Global Install (`~/.claude/`)

```bash
# Global install — copy from plugin rules/ to ~/.claude/rules/ with vf- prefix
# The vf- prefix avoids conflicts with rules from other Claude Code plugins
mkdir -p "$HOME/.claude/rules"

for rule_file in "${RULES_SOURCE}"/*.md; do
  rule_name=$(basename "$rule_file" .md)
  cp "$rule_file" "$HOME/.claude/rules/vf-${rule_name}.md"
  echo "  [OK] ~/.claude/rules/vf-${rule_name}.md"
done

echo "  Rules installed from: ${RULES_SOURCE}"
echo "  Rules installed to:   ${HOME}/.claude/rules/vf-*.md"
```

#### CLAUDE.md Content

The installed CLAUDE.md includes:

```markdown
# ValidationForge

No-mock validation platform. Ship verified code, not "it compiled" code.

## Philosophy

1. **No Mocks Ever** — Never create test files, mocks, stubs, or test doubles
2. **Evidence-Based Verdicts** — Every PASS/FAIL cites specific evidence
3. **Real System Validation** — Build, run, and interact with the actual application
4. **Gate Discipline** — Never claim completion without examining evidence

## Quick Start

/validate                    # Full pipeline
/validate-plan               # Plan only
/validate-audit              # Read-only audit
/validate-fix                # Fix failures and re-validate
/validate-ci                 # CI/CD mode

## The Iron Rule

IF the real system doesn't work, FIX THE REAL SYSTEM.
NEVER create mocks, stubs, test doubles, or test files.
NEVER mark a journey PASS without specific evidence.
```

### Step 4b: Apply Enforcement Config

Copy the selected enforcement config from the plugin's `config/` directory to `.vf/active-config.json`.
This file is the authoritative source of active hooks and rules for all subsequent `validate` commands.

```bash
# Ensure the .vf directory exists
mkdir -p .vf

# Map the user's enforcement selection to its config file
case "${ENFORCEMENT_LEVEL}" in
  strict)     CONFIG_SRC="${INSTALL_DIR}/config/strict.json" ;;
  permissive) CONFIG_SRC="${INSTALL_DIR}/config/permissive.json" ;;
  *)          CONFIG_SRC="${INSTALL_DIR}/config/standard.json" ;;
esac

if [ -f "${CONFIG_SRC}" ]; then
  cp "${CONFIG_SRC}" .vf/active-config.json
  echo "  [OK] Enforcement config applied: .vf/active-config.json (${ENFORCEMENT_LEVEL})"
else
  echo "  [WARN] Config source not found: ${CONFIG_SRC}"
  echo "         Verify plugin installation directory: ${INSTALL_DIR}"
  echo "         Re-run the installer: curl -fsSL https://raw.githubusercontent.com/krzemienski/validationforge/main/install.sh | bash"
fi
```

Expected result:
```
.vf/
  active-config.json    ← Active enforcement config (strict | standard | permissive)
```

The `active-config.json` structure matches the source config (e.g., for `standard`):

```json
{
  "name": "standard",
  "strictness": "standard",
  "hooks": {
    "block-test-files": "enabled",
    "evidence-gate-reminder": "enabled",
    "validation-not-compilation": "enabled",
    "completion-claim-validator": "enabled",
    "mock-detection": "enabled"
  },
  "rules": {
    "block_test_files": true,
    "block_mock_patterns": true,
    "require_evidence_on_completion": true,
    "fail_on_missing_evidence": false
  }
}
```

Validate the config was written:

```bash
if [ -f ".vf/active-config.json" ]; then
  ACTIVE_NAME=$(jq -r '.name // empty' .vf/active-config.json 2>/dev/null)
  echo "  [OK] Active config: ${ACTIVE_NAME}"
else
  echo "  [FAIL] .vf/active-config.json was not created"
fi
```

### Step 5: Create Evidence Directory

```bash
mkdir -p e2e-evidence
echo "*.png" >> e2e-evidence/.gitignore
echo "*.json" >> e2e-evidence/.gitignore
echo "!evidence-inventory.txt" >> e2e-evidence/.gitignore
echo "!report.md" >> e2e-evidence/.gitignore
echo "# Evidence directory — screenshots and logs from validation runs" > e2e-evidence/README.md
```

### Step 6: Configure .gitignore

Append to project `.gitignore` (if not already present):

```
# ValidationForge
e2e-evidence/**/*.png
e2e-evidence/**/*.json
!e2e-evidence/report.md
!e2e-evidence/evidence-inventory.txt
.vf/
```

### Step 7: MCP Prerequisite Check

Check for required MCP servers based on platform:

| Platform | Required MCP | Check |
|----------|-------------|-------|
| Web | Playwright MCP or Chrome DevTools | `mcp__playwright__*` or `mcp__chrome-devtools__*` available |
| iOS | Xcode tools | `xcrun simctl list` succeeds |
| Design | Stitch MCP | `mcp__stitch__*` available |
| API | None | curl available |
| CLI | None | Shell available |

Report missing prerequisites with installation instructions. Do NOT fail setup — just warn.

### Step 8: Verification

Run a quick health check:

```bash
# Verify installation
echo "=== ValidationForge Setup Verification ==="

# Check rules installed
for rule in validation-discipline evidence-management platform-detection execution-workflow team-validation; do
  if [ -f ".claude/rules/${rule}.md" ] || [ -f "$HOME/.claude/rules/vf-${rule}.md" ]; then
    echo "  [OK] Rule: $rule"
  else
    echo "  [MISSING] Rule: $rule"
  fi
done

# Check CLAUDE.md has VF section
if grep -q "ValidationForge" .claude/CLAUDE.md 2>/dev/null || grep -q "ValidationForge" "$HOME/.claude/CLAUDE.md" 2>/dev/null; then
  echo "  [OK] CLAUDE.md configured"
else
  echo "  [MISSING] CLAUDE.md not configured"
fi

# Check evidence directory
if [ -d "e2e-evidence" ]; then
  echo "  [OK] Evidence directory"
else
  echo "  [MISSING] Evidence directory"
fi

echo "=== Setup Complete ==="
```

### Step 9: Save Config

```bash
mkdir -p "$HOME/.claude"

# Determine where rules were installed based on scope
if [ "${CONFIG_TYPE}" = "global" ] || [ "${CONFIG_TYPE}" = "both" ]; then
  RULES_DIR="${HOME}/.claude/rules"
else
  RULES_DIR="$(pwd)/.claude/rules"
fi

cat > "$HOME/.claude/.vf-config.json" << EOF
{
  "setupCompleted": "$(date -Iseconds)",
  "setupVersion": "1.0.0",
  "scope": "${CONFIG_TYPE}",
  "enforcement": "${ENFORCEMENT_LEVEL}",
  "platform": "${DETECTED_PLATFORM}",
  "projectPath": "$(pwd)",
  "rulesDir": "${RULES_DIR}",
  "pluginDir": "${INSTALL_DIR}",
  "hooksInstalled": true
}
EOF
```

### Step 10: Welcome Message

Print:

```
ValidationForge is ready.

Platform: {platform}
Enforcement: {level}
Evidence: e2e-evidence/

Commands:
  /validate          Full validation pipeline
  /validate-plan     Plan validation journeys
  /validate-audit    Read-only audit
  /validate-fix      Fix and re-validate
  /validate-ci       CI/CD mode

Start with: /validate-plan
```

## Uninstall

```bash
# Remove VF rules
rm -f .claude/rules/validation-discipline.md
rm -f .claude/rules/evidence-management.md
rm -f .claude/rules/platform-detection.md
rm -f .claude/rules/execution-workflow.md
rm -f .claude/rules/team-validation.md

# Remove global rules
rm -f ~/.claude/rules/vf-*.md

# Remove config
rm -f ~/.claude/.vf-config.json

# Remove state
rm -rf .vf/

# Keep e2e-evidence/ (user may want to preserve evidence)
echo "ValidationForge uninstalled. e2e-evidence/ preserved."
```
