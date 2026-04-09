#!/usr/bin/env bash
# Enable block-test-files hook in ~/.claude/hooks/
# Copies the current hooks/block-test-files.js to ~/.claude/hooks/block-test-files.js

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$HOME/.claude/hooks"
SOURCE_HOOK="$PLUGIN_ROOT/hooks/block-test-files.js"
TARGET_HOOK="$HOOKS_DIR/block-test-files.js"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }
info() { echo "[INFO] $1"; }

echo "=== Enable block-test-files Hook ==="
info "Source: $SOURCE_HOOK"
info "Target: $TARGET_HOOK"

if [ ! -f "$SOURCE_HOOK" ]; then
  fail "Source hook file not found: $SOURCE_HOOK"
fi

if [ ! -d "$HOOKS_DIR" ]; then
  info "Creating hooks directory: $HOOKS_DIR"
  mkdir -p "$HOOKS_DIR"
fi

cp "$SOURCE_HOOK" "$TARGET_HOOK"
chmod +x "$TARGET_HOOK"

if [ -f "$TARGET_HOOK" ]; then
  ok "block-test-files.js installed at $TARGET_HOOK"
else
  fail "Installation failed — file not found after copy"
fi

echo ""
echo "=== Verification ==="
node -e "const fs = require('fs'); const path = process.env.HOME + '/.claude/hooks/block-test-files.js'; if (!fs.existsSync(path)) throw new Error('Hook file missing: ' + path); console.log('PASS: block-test-files.js exists at:', path)"
