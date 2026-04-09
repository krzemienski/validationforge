#!/usr/bin/env bash
# ValidationForge installer for Claude Code
# Usage: curl -fsSL https://raw.githubusercontent.com/krzemienski/validationforge/main/install.sh | bash

set -euo pipefail

REPO="${VF_SOURCE:-https://github.com/krzemienski/validationforge}"
INSTALL_DIR="${VF_INSTALL_DIR:-${HOME}/.claude/plugins/validationforge}"
RULES_DIR="${HOME}/.claude/rules"
CONFIG_FILE="${HOME}/.claude/.vf-config.json"

info() { echo "[VF] $1"; }
warn() { echo "[VF] WARNING: $1"; }
ok()   { echo "[VF] OK: $1"; }

# Check prerequisites
command -v git >/dev/null 2>&1 || { warn "git is required but not installed."; exit 1; }

# Validate clone target is under HOME or /tmp (prevent writing to system dirs)
case "$INSTALL_DIR" in
  "$HOME"/*|/tmp/*|/private/tmp/*|/var/folders/*|/private/var/folders/*) ;;
  *) warn "INSTALL_DIR must be under \$HOME or temp directory. Got: $INSTALL_DIR"; exit 1 ;;
esac

# Install or update
if [ -d "$INSTALL_DIR/.git" ]; then
  info "Updating existing installation..."
  cd "$INSTALL_DIR" && git pull --ff-only
else
  info "Installing ValidationForge..."
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone --depth 1 "$REPO" "$INSTALL_DIR"
fi

# Create plugin cache symlink so Claude Code plugin loader can find it
PLUGIN_CACHE_DIR="${HOME}/.claude/plugins/cache/validationforge/validationforge/1.0.0"
info "Registering plugin cache at ${PLUGIN_CACHE_DIR}..."
mkdir -p "$(dirname "$PLUGIN_CACHE_DIR")"
if [ -L "$PLUGIN_CACHE_DIR" ]; then
  rm "$PLUGIN_CACHE_DIR"
fi
ln -s "$INSTALL_DIR" "$PLUGIN_CACHE_DIR"
ok "Plugin cache symlink created: ${PLUGIN_CACHE_DIR} -> ${INSTALL_DIR}"

# Install global rules with vf- prefix
info "Installing rules to ${RULES_DIR}..."
mkdir -p "$RULES_DIR"

for rule_file in "$INSTALL_DIR"/rules/*.md; do
  rule_name=$(basename "$rule_file" .md)
  target="${RULES_DIR}/vf-${rule_name}.md"
  cp "$rule_file" "$target"
done

ok "$(ls "$INSTALL_DIR"/rules/*.md | wc -l | tr -d ' ') rules installed"  # tr -d ' ' strips leading spaces from macOS wc; harmless on Linux

# Create evidence directory in current project (if in a git repo)
if git rev-parse --git-dir >/dev/null 2>&1; then
  mkdir -p e2e-evidence
  if [ ! -f e2e-evidence/.gitignore ]; then
    cat > e2e-evidence/.gitignore << 'GITIGNORE'
*.png
*.jpg
*.json
!evidence-inventory.txt
!report.md
GITIGNORE
  fi
  ok "Evidence directory created at e2e-evidence/"
fi

# Save config
mkdir -p "$(dirname "$CONFIG_FILE")"
cat > "$CONFIG_FILE" << EOF
{
  "setupCompleted": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",  # POSIX-compatible: -u=UTC, format is portable
  "setupVersion": "1.0.0",
  "installDir": "$INSTALL_DIR",
  "scope": "global"
}
EOF

ok "Config saved to $CONFIG_FILE"

# Register in installed_plugins.json so Claude Code plugin loader discovers the plugin
INSTALLED_PLUGINS_FILE="${HOME}/.claude/installed_plugins.json"
info "Registering plugin in ${INSTALLED_PLUGINS_FILE}..."
mkdir -p "$(dirname "$INSTALLED_PLUGINS_FILE")"
python3 - "$INSTALLED_PLUGINS_FILE" "$INSTALL_DIR" << 'PYEOF'
import sys, json, os

plugins_file = sys.argv[1]
install_dir  = sys.argv[2]
plugin_key   = "validationforge@validationforge"

if os.path.isfile(plugins_file):
    with open(plugins_file, "r") as fh:
        try:
            registry = json.load(fh)
        except (json.JSONDecodeError, ValueError):
            registry = {}
else:
    registry = {}

registry[plugin_key] = {"path": install_dir, "scope": "user"}

with open(plugins_file, "w") as fh:
    json.dump(registry, fh, indent=2)
    fh.write("\n")
PYEOF
ok "Plugin registered in ${INSTALLED_PLUGINS_FILE}"

# Verify installation
info ""
info "=== ValidationForge Installed ==="
info ""
info "  Plugin:  $INSTALL_DIR"
info "  Rules:   $RULES_DIR/vf-*.md"
info "  Config:  $CONFIG_FILE"
info ""
info "  Commands:"
info "    /validate          Full validation pipeline"
info "    /validate-plan     Plan validation journeys"
info "    /validate-audit    Read-only audit"
info "    /validate-fix      Fix and re-validate"
info "    /validate-ci       CI/CD mode"
info "    /vf-setup          Project-level setup wizard"
info ""
info "  Start with: /vf-setup in your project directory"
info ""

# Prominent restart prompt
BOLD='\033[1m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RESET='\033[0m'
printf "\n"
printf "${YELLOW}************************************************************${RESET}\n"
printf "${BOLD}${GREEN}  ACTION REQUIRED: Restart Claude Code to activate the plugin${RESET}\n"
printf "${YELLOW}************************************************************${RESET}\n"
printf "${BOLD}  Please restart Claude Code now for ValidationForge to take effect.${RESET}\n"
printf "\n"
