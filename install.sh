#!/usr/bin/env bash
# ValidationForge installer for Claude Code
# Usage: curl -fsSL https://raw.githubusercontent.com/krzemienski/validationforge/main/install.sh | bash

set -euo pipefail

REPO="https://github.com/krzemienski/validationforge"
INSTALL_DIR="${HOME}/.claude/plugins/validationforge"
RULES_DIR="${HOME}/.claude/rules"
CONFIG_FILE="${HOME}/.claude/.vf-config.json"

info() { echo "[VF] $1"; }
warn() { echo "[VF] WARNING: $1"; }
ok()   { echo "[VF] OK: $1"; }

# Check prerequisites
command -v git >/dev/null 2>&1 || { warn "git is required but not installed."; exit 1; }

# Install or update
if [ -d "$INSTALL_DIR" ]; then
  info "Updating existing installation..."
  cd "$INSTALL_DIR" && git pull --ff-only
else
  info "Installing ValidationForge..."
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone "$REPO" "$INSTALL_DIR"
fi

# Install global rules with vf- prefix
info "Installing rules to ${RULES_DIR}..."
mkdir -p "$RULES_DIR"

for rule_file in "$INSTALL_DIR"/rules/*.md; do
  rule_name=$(basename "$rule_file" .md)
  target="${RULES_DIR}/vf-${rule_name}.md"
  cp "$rule_file" "$target"
done

ok "$(ls "$INSTALL_DIR"/rules/*.md | wc -l | tr -d ' ') rules installed"

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
  "setupCompleted": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "setupVersion": "1.0.0",
  "installDir": "$INSTALL_DIR",
  "scope": "global"
}
EOF

ok "Config saved to $CONFIG_FILE"

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
