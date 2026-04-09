#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="$HOME/.claude/plugins/cache/validationforge/validationforge/1.0.0"
WORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Syncing plugin files to cache..."
echo "  Source: $WORK_DIR"
echo "  Target: $CACHE_DIR"

mkdir -p "$CACHE_DIR/.claude-plugin"
mkdir -p "$CACHE_DIR/hooks"
mkdir -p "$CACHE_DIR/commands"
mkdir -p "$CACHE_DIR/skills"
mkdir -p "$CACHE_DIR/agents"
mkdir -p "$CACHE_DIR/rules"
mkdir -p "$CACHE_DIR/config"
mkdir -p "$CACHE_DIR/templates"
mkdir -p "$CACHE_DIR/plans"
mkdir -p "$CACHE_DIR/scripts"
mkdir -p "$CACHE_DIR/docs"
mkdir -p "$CACHE_DIR/demo"

cp -f "$WORK_DIR/.claude-plugin/plugin.json" "$CACHE_DIR/.claude-plugin/plugin.json"
cp -f "$WORK_DIR/.claude-plugin/marketplace.json" "$CACHE_DIR/.claude-plugin/marketplace.json"

cp -rf "$WORK_DIR/hooks/." "$CACHE_DIR/hooks/"
cp -rf "$WORK_DIR/commands/." "$CACHE_DIR/commands/"
cp -rf "$WORK_DIR/skills/." "$CACHE_DIR/skills/"
cp -rf "$WORK_DIR/agents/." "$CACHE_DIR/agents/"
cp -rf "$WORK_DIR/rules/." "$CACHE_DIR/rules/"
cp -rf "$WORK_DIR/config/." "$CACHE_DIR/config/"

if [ -d "$WORK_DIR/templates" ]; then
  cp -rf "$WORK_DIR/templates/." "$CACHE_DIR/templates/"
fi
if [ -d "$WORK_DIR/scripts" ]; then
  cp -rf "$WORK_DIR/scripts/." "$CACHE_DIR/scripts/"
fi

echo "Sync complete."
echo "Verifying cached plugin.json..."
if [ -f "$CACHE_DIR/.claude-plugin/plugin.json" ]; then
  echo "PASS: $CACHE_DIR/.claude-plugin/plugin.json exists"
  cat "$CACHE_DIR/.claude-plugin/plugin.json"
else
  echo "FAIL: plugin.json not found in cache"
  exit 1
fi
