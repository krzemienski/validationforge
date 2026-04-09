#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CACHE_BASE="$HOME/.claude/plugins/cache/validationforge/validationforge/1.0.0"
INSTALLED_JSON="$HOME/.claude/installed_plugins.json"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo "[INFO] $1"; }

echo "=== ValidationForge Plugin Cache Setup ==="
echo "Source: $PLUGIN_ROOT"
echo "Target: $CACHE_BASE"
echo ""

mkdir -p "$CACHE_BASE/.claude-plugin"
mkdir -p "$CACHE_BASE/hooks"
mkdir -p "$CACHE_BASE/commands"
mkdir -p "$CACHE_BASE/skills"
mkdir -p "$CACHE_BASE/agents"
mkdir -p "$CACHE_BASE/rules"
mkdir -p "$CACHE_BASE/config"
mkdir -p "$CACHE_BASE/scripts"
mkdir -p "$CACHE_BASE/templates"
mkdir -p "$CACHE_BASE/plans"
mkdir -p "$CACHE_BASE/docs"
ok "Cache directory structure created"

cp -f "$PLUGIN_ROOT/.claude-plugin/plugin.json" "$CACHE_BASE/.claude-plugin/plugin.json"
cp -f "$PLUGIN_ROOT/.claude-plugin/marketplace.json" "$CACHE_BASE/.claude-plugin/marketplace.json" 2>/dev/null || true
ok "Synced .claude-plugin/"

cp -rf "$PLUGIN_ROOT/hooks/." "$CACHE_BASE/hooks/"
ok "Synced hooks/"

cp -rf "$PLUGIN_ROOT/commands/." "$CACHE_BASE/commands/"
ok "Synced commands/"

cp -rf "$PLUGIN_ROOT/skills/." "$CACHE_BASE/skills/"
ok "Synced skills/"

cp -rf "$PLUGIN_ROOT/agents/." "$CACHE_BASE/agents/"
ok "Synced agents/"

cp -rf "$PLUGIN_ROOT/rules/." "$CACHE_BASE/rules/"
ok "Synced rules/"

cp -rf "$PLUGIN_ROOT/config/." "$CACHE_BASE/config/" 2>/dev/null || true
cp -rf "$PLUGIN_ROOT/scripts/." "$CACHE_BASE/scripts/" 2>/dev/null || true
cp -rf "$PLUGIN_ROOT/templates/." "$CACHE_BASE/templates/" 2>/dev/null || true
ok "Synced supporting directories"

echo ""
info "Verifying cached plugin.json..."
if node -e "const p = require('$CACHE_BASE/.claude-plugin/plugin.json'); ['commands','skills'].forEach(k => { if (!p[k]) throw new Error('Missing: ' + k); }); console.log('PASS: cached plugin.json has directory declarations');" 2>/dev/null; then
  ok "Cache verification PASSED"
else
  fail "Cache verification FAILED"
  exit 1
fi

echo ""
info "Registering plugin in installed_plugins.json..."
if [ ! -f "$INSTALLED_JSON" ]; then
  echo '{}' > "$INSTALLED_JSON"
  warn "Created new installed_plugins.json"
fi

node -e "
const fs = require('fs');
const path = '$INSTALLED_JSON';
const reg = JSON.parse(fs.readFileSync(path, 'utf8'));
reg['validationforge@validationforge'] = {
  path: '$CACHE_BASE',
  scope: 'user',
  installedAt: new Date().toISOString()
};
fs.writeFileSync(path, JSON.stringify(reg, null, 2));
console.log('Registered validationforge@validationforge at $CACHE_BASE');
"

ok "Plugin registered in installed_plugins.json"

echo ""
info "Verifying registration..."
if node -e "
const fs = require('fs');
const r = JSON.parse(fs.readFileSync('$INSTALLED_JSON', 'utf8'));
const entry = r['validationforge@validationforge'];
if (!entry) throw new Error('Not registered');
if (!fs.existsSync(entry.path)) throw new Error('Path does not exist: ' + entry.path);
console.log('PASS: plugin registered at existing path:', entry.path);
" 2>/dev/null; then
  ok "Registration verification PASSED"
else
  fail "Registration verification FAILED"
  exit 1
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Plugin cache: $CACHE_BASE"
echo "Registration: $INSTALLED_JSON"
echo ""
echo "Restart Claude Code to pick up the plugin."
