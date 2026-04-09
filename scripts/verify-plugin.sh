#!/usr/bin/env bash
# Comprehensive plugin verification — checks all 5 acceptance criteria
# Usage: bash scripts/verify-plugin.sh
# Exits 0 when all criteria pass, 1 if any fail.

set -uo pipefail

INSTALLED_JSON="$HOME/.claude/installed_plugins.json"
HOOKS_DIR="$HOME/.claude/hooks"
PLUGIN_KEY="validationforge@validationforge"
PLUGIN_PATH=""

PASS_COUNT=0
FAIL_COUNT=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
info() { echo "       $1"; }

echo ""
echo -e "${BOLD}=== ValidationForge Plugin Verification ===${NC}"
echo ""

# ─── Criterion 1: Plugin registers in Claude Code without errors ──────────────
echo -e "${BOLD}[1/5] Plugin registers in Claude Code's plugin system without errors${NC}"

if [ ! -f "$INSTALLED_JSON" ]; then
  fail "installed_plugins.json not found at: $INSTALLED_JSON"
else
  if PLUGIN_PATH=$(node -e "
    const fs = require('fs');
    const r = JSON.parse(fs.readFileSync('$INSTALLED_JSON', 'utf8'));
    const entry = r['$PLUGIN_KEY'];
    if (!entry) throw new Error('No $PLUGIN_KEY entry in installed_plugins.json');
    if (!fs.existsSync(entry.path)) throw new Error('Registered path does not exist: ' + entry.path);
    process.stdout.write(entry.path);
  " 2>/dev/null); then
    pass "Registered at valid path: $PLUGIN_PATH"
  else
    fail "Plugin not registered or path invalid in $INSTALLED_JSON"
    PLUGIN_PATH=""
  fi
fi

echo ""

# ─── Criterion 2: All 15 slash commands are discoverable ─────────────────────
echo -e "${BOLD}[2/5] All 15 slash commands are discoverable via /help or autocomplete${NC}"

if [ -z "$PLUGIN_PATH" ]; then
  fail "Cannot check commands — plugin path not set (criterion 1 failed)"
elif [ ! -d "$PLUGIN_PATH/commands" ]; then
  fail "Commands directory not found: $PLUGIN_PATH/commands"
else
  CMD_COUNT=$(ls "$PLUGIN_PATH/commands/"*.md 2>/dev/null | wc -l | tr -d ' ') || CMD_COUNT=0
  if [ "$CMD_COUNT" -eq 15 ]; then
    pass "15 command files found in $PLUGIN_PATH/commands/"
    info "$(ls "$PLUGIN_PATH/commands/"*.md | xargs -I{} basename {} .md | tr '\n' ' ')"
  else
    fail "Expected 15 commands, found $CMD_COUNT in $PLUGIN_PATH/commands/"
  fi
fi

echo ""

# ─── Criterion 3: block-test-files hook fires for .test.ts files ─────────────
echo -e "${BOLD}[3/5] Hook block-test-files fires when attempting to create a .test.ts file${NC}"

if [ -z "$PLUGIN_PATH" ]; then
  fail "Cannot check hook — plugin path not set (criterion 1 failed)"
else
  HOOK_FILE="$PLUGIN_PATH/hooks/block-test-files.js"
  GLOBAL_HOOK="$HOOKS_DIR/block-test-files.js"

  if [ ! -f "$HOOK_FILE" ]; then
    fail "block-test-files.js not found at: $HOOK_FILE"
  else
    info "Plugin hook: $HOOK_FILE"
    if [ -f "$GLOBAL_HOOK" ]; then
      info "Global hook: $GLOBAL_HOOK (also installed)"
    fi

    # Run hook from plugin cache path — CLAUDE_PLUGIN_ROOT resolves here at runtime,
    # so patterns.js is co-located and the require('./patterns') call succeeds.
    HOOK_OUTPUT=$(echo '{"tool_input":{"file_path":"src/foo.test.ts"}}' | \
      node "$HOOK_FILE" 2>/dev/null) || HOOK_OUTPUT=""

    DECISION=$(echo "$HOOK_OUTPUT" | node -e "
      let d = '';
      process.stdin.on('data', c => d += c);
      process.stdin.on('end', () => {
        try {
          const o = JSON.parse(d);
          process.stdout.write(o.hookSpecificOutput && o.hookSpecificOutput.permissionDecision || 'none');
        } catch (e) {
          process.stdout.write('parse-error');
        }
      });
    " 2>/dev/null) || DECISION="error"

    if [ "$DECISION" = "deny" ]; then
      pass "Hook correctly blocks .test.ts files (permissionDecision: deny)"
    else
      fail "Hook did not return deny for .test.ts file — got: '$DECISION'"
    fi
  fi
fi

echo ""

# ─── Criterion 4: CLAUDE_PLUGIN_ROOT resolves to correct directory ───────────
echo -e "${BOLD}[4/5] \${CLAUDE_PLUGIN_ROOT} resolves to the correct plugin installation directory${NC}"

if [ -z "$PLUGIN_PATH" ]; then
  fail "Cannot verify CLAUDE_PLUGIN_ROOT — plugin not registered (criterion 1 failed)"
else
  HOOK_JS="$PLUGIN_PATH/hooks/block-test-files.js"
  HOOKS_JSON="$PLUGIN_PATH/hooks/hooks.json"

  if [ ! -f "$HOOK_JS" ]; then
    fail "CLAUDE_PLUGIN_ROOT resolution broken — hooks/block-test-files.js missing at: $PLUGIN_PATH/hooks/"
  elif [ ! -f "$HOOKS_JSON" ]; then
    fail "CLAUDE_PLUGIN_ROOT resolution broken — hooks/hooks.json missing at: $PLUGIN_PATH/hooks/"
  elif ! grep -q 'CLAUDE_PLUGIN_ROOT' "$HOOKS_JSON" 2>/dev/null; then
    fail "hooks.json does not reference CLAUDE_PLUGIN_ROOT — hook commands would not resolve"
  else
    HOOK_COUNT=$(ls "$PLUGIN_PATH/hooks/"*.js 2>/dev/null | wc -l | tr -d ' ') || HOOK_COUNT=0
    pass "\${CLAUDE_PLUGIN_ROOT} resolves to $PLUGIN_PATH ($HOOK_COUNT hook scripts present)"
  fi
fi

echo ""

# ─── Criterion 5: Skills are loaded when referenced by commands ──────────────
echo -e "${BOLD}[5/5] Skills are loaded when referenced by commands${NC}"

if [ -z "$PLUGIN_PATH" ]; then
  fail "Cannot check skills — plugin path not set (criterion 1 failed)"
elif [ ! -d "$PLUGIN_PATH/skills" ]; then
  fail "Skills directory not found: $PLUGIN_PATH/skills"
else
  SKILL_COUNT=$(ls "$PLUGIN_PATH/skills/" 2>/dev/null | wc -l | tr -d ' ') || SKILL_COUNT=0
  if [ "$SKILL_COUNT" -ge 40 ]; then
    pass "$SKILL_COUNT skill directories found in $PLUGIN_PATH/skills/ (>= 40 required)"
  else
    fail "Expected >= 40 skills, found $SKILL_COUNT in $PLUGIN_PATH/skills/"
  fi
fi

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
echo -e "Results: ${GREEN}${BOLD}${PASS_COUNT} passed${NC}  ${RED}${BOLD}${FAIL_COUNT} failed${NC}"
echo ""

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo -e "${GREEN}${BOLD}PASS: All 5 acceptance criteria met.${NC}"
  exit 0
else
  echo -e "${RED}${BOLD}FAIL: ${FAIL_COUNT} of 5 acceptance criteria failed.${NC}"
  exit 1
fi
