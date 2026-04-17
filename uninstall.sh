#!/usr/bin/env bash
# ValidationForge uninstaller for Claude Code
# Usage: bash uninstall.sh

set -euo pipefail

INSTALL_DIR="${VF_INSTALL_DIR:-${HOME}/.claude/plugins/validationforge}"
PLUGIN_CACHE_DIR="${HOME}/.claude/plugins/cache/validationforge"
RULES_DIR="${HOME}/.claude/rules"
CONFIG_FILE="${HOME}/.claude/.vf-config.json"
INSTALLED_PLUGINS_FILE="${HOME}/.claude/installed_plugins.json"
RULES_MANIFEST="${HOME}/.claude/.vf-rules-manifest.txt"

info() { echo "[VF] $1"; }
warn() { echo "[VF] WARNING: $1"; }
ok()   { echo "[VF] OK: $1"; }

info "Uninstalling ValidationForge..."
info ""

removed=0

# Remove installation directory
if [ -d "$INSTALL_DIR" ]; then
  info "Removing installation directory: ${INSTALL_DIR}..."
  rm -rf "$INSTALL_DIR"
  ok "Removed ${INSTALL_DIR}"
  removed=$((removed + 1))
else
  warn "Installation directory not found: ${INSTALL_DIR}"
fi

# Remove plugin cache directory
if [ -d "$PLUGIN_CACHE_DIR" ] || [ -L "$PLUGIN_CACHE_DIR" ]; then
  info "Removing plugin cache: ${PLUGIN_CACHE_DIR}..."
  rm -rf "$PLUGIN_CACHE_DIR"
  ok "Removed ${PLUGIN_CACHE_DIR}"
  removed=$((removed + 1))
else
  warn "Plugin cache directory not found: ${PLUGIN_CACHE_DIR}"
fi

# Remove entry from installed_plugins.json using python3
if [ -f "$INSTALLED_PLUGINS_FILE" ]; then
  info "Removing plugin entry from ${INSTALLED_PLUGINS_FILE}..."
  python3 - "$INSTALLED_PLUGINS_FILE" << 'PYEOF'
import sys, json, os

plugins_file = sys.argv[1]
plugin_key   = "validationforge@validationforge"

if os.path.isfile(plugins_file):
    with open(plugins_file, "r") as fh:
        try:
            registry = json.load(fh)
        except (json.JSONDecodeError, ValueError):
            registry = {}
else:
    registry = {}

if plugin_key in registry:
    del registry[plugin_key]
    with open(plugins_file, "w") as fh:
        json.dump(registry, fh, indent=2)
        fh.write("\n")
    print("[VF] OK: Plugin entry removed from " + plugins_file)
else:
    print("[VF] WARNING: Plugin key not found in " + plugins_file)
PYEOF
  removed=$((removed + 1))
else
  warn "Plugin registry file not found: ${INSTALLED_PLUGINS_FILE}"
fi

# Remove ONLY the rules we installed — consult the manifest written by
# install.sh. Falls back to the vf-*.md glob only if the manifest is
# missing, with a loud warning (review finding L2: the naive glob
# destroyed user-authored files sharing the vf- prefix).
vf_rules_found=0
if [ -f "$RULES_MANIFEST" ]; then
  info "Removing rules listed in manifest: ${RULES_MANIFEST}..."
  while IFS= read -r rule_target; do
    [ -z "$rule_target" ] && continue
    # Only remove if the file currently lives under RULES_DIR — defence
    # against an edited manifest pointing at unexpected paths.
    case "$rule_target" in
      "${RULES_DIR}/"*) ;;
      *) warn "Skipping manifest entry outside RULES_DIR: $rule_target"; continue ;;
    esac
    if [ -f "$rule_target" ]; then
      rm -f "$rule_target"
      vf_rules_found=$((vf_rules_found + 1))
    fi
  done < "$RULES_MANIFEST"
  rm -f "$RULES_MANIFEST"
else
  warn "Rules manifest not found at ${RULES_MANIFEST}; falling back to vf-*.md glob (may remove user-authored files with the vf- prefix)."
  shopt -s nullglob
  for rule_file in "${RULES_DIR}"/vf-*.md; do
    rm -f "$rule_file"
    vf_rules_found=$((vf_rules_found + 1))
  done
  shopt -u nullglob
fi

if [ "$vf_rules_found" -gt 0 ]; then
  ok "${vf_rules_found} rule(s) removed from ${RULES_DIR}"
  removed=$((removed + 1))
else
  warn "No vf-prefixed rules found to remove in ${RULES_DIR}"
fi

# Remove config file
if [ -f "$CONFIG_FILE" ]; then
  info "Removing config file: ${CONFIG_FILE}..."
  rm -f "$CONFIG_FILE"
  ok "Removed ${CONFIG_FILE}"
  removed=$((removed + 1))
else
  warn "Config file not found: ${CONFIG_FILE}"
fi

# Print success summary
info ""
info "=== ValidationForge Uninstalled ==="
info ""
info "  Removed ${removed} component(s):"
info "    Plugin dir:   ${INSTALL_DIR}"
info "    Plugin cache: ${PLUGIN_CACHE_DIR}"
info "    Rules:        ${RULES_DIR}/vf-*.md"
info "    Config:       ${CONFIG_FILE}"
info "    Registry:     ${INSTALLED_PLUGINS_FILE}"
info ""
info "  Restart Claude Code to complete the removal."
info ""
