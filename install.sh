#!/usr/bin/env bash
# ValidationForge installer for Claude Code
# Usage: curl -fsSL https://raw.githubusercontent.com/krzemienski/validationforge/main/install.sh | bash
#
# Security notes (2026-04 hardening):
#   • Clone is pinned to $VF_VERSION tag by default (set VF_REF to a branch
#     or commit to override).
#   • VF_SOURCE is validated against an https://github.com/ allowlist unless
#     VF_ALLOW_ALT_SOURCE=1 is explicitly set.
#   • Plugin cache symlink is replaced atomically (ln -sfn) with
#     ownership/path-type verification before any removal.
#   • installed_plugins.json is written via temp-file + os.replace + flock
#     so concurrent writers cannot truncate it.

set -euo pipefail

# ────────────────────────────────────────────────────────────
# Defaults — override via env vars
# ────────────────────────────────────────────────────────────
REPO="${VF_SOURCE:-https://github.com/krzemienski/validationforge}"
VF_VERSION="${VF_VERSION:-1.0.0}"            # published tag — the default install target
VF_REF="${VF_REF:-v${VF_VERSION}}"           # git ref to clone; override for dev
INSTALL_DIR="${VF_INSTALL_DIR:-${HOME}/.claude/plugins/validationforge}"
RULES_DIR="${HOME}/.claude/rules"
CONFIG_FILE="${HOME}/.claude/.vf-config.json"

info() { echo "[VF] $1"; }
warn() { echo "[VF] WARNING: $1"; }
ok()   { echo "[VF] OK: $1"; }
die()  { echo "[VF] ERROR: $1" >&2; exit 1; }

# ────────────────────────────────────────────────────────────
# Prereqs
# ────────────────────────────────────────────────────────────
command -v git >/dev/null 2>&1 || die "git is required but not installed."
command -v python3 >/dev/null 2>&1 || die "python3 is required but not installed."

# ────────────────────────────────────────────────────────────
# Source allowlist — refuse non-HTTPS / non-github sources unless
# the user explicitly opts in via VF_ALLOW_ALT_SOURCE=1.
# ────────────────────────────────────────────────────────────
if [ "${VF_ALLOW_ALT_SOURCE:-0}" != "1" ]; then
  case "$REPO" in
    https://github.com/*) ;;
    *) die "VF_SOURCE must be an https://github.com/ URL. Got: $REPO. Set VF_ALLOW_ALT_SOURCE=1 to override." ;;
  esac
fi

# ────────────────────────────────────────────────────────────
# Validate clone target — under $HOME only (dropped /tmp from the
# allowlist; world-writable temp dirs race-prone, a mktemp -d 0700
# is acceptable via VF_ALLOW_TMP_INSTALL=1).
# ────────────────────────────────────────────────────────────
case "$INSTALL_DIR" in
  "$HOME"/*) ;;
  /tmp/*|/private/tmp/*|/var/folders/*|/private/var/folders/*)
    if [ "${VF_ALLOW_TMP_INSTALL:-0}" != "1" ]; then
      die "INSTALL_DIR under a shared temp directory is not allowed by default. Got: $INSTALL_DIR. Set VF_ALLOW_TMP_INSTALL=1 to override (temp dir should be owned 0700)."
    fi
    ;;
  *) die "INSTALL_DIR must be under \$HOME (or an explicitly allowed temp dir). Got: $INSTALL_DIR" ;;
esac

# ────────────────────────────────────────────────────────────
# Install or update
# ────────────────────────────────────────────────────────────
if [ -d "$INSTALL_DIR/.git" ]; then
  info "Updating existing installation to ref $VF_REF..."
  cd "$INSTALL_DIR"
  git fetch --tags --depth 1 origin "$VF_REF" 2>/dev/null || git fetch origin
  git checkout "$VF_REF" 2>/dev/null || git pull --ff-only
else
  info "Installing ValidationForge $VF_REF from $REPO..."
  mkdir -p "$(dirname "$INSTALL_DIR")"
  # Shallow clone pinned to VF_REF; falls back to default branch if ref is missing.
  if ! git clone --depth 1 --branch "$VF_REF" "$REPO" "$INSTALL_DIR" 2>/dev/null; then
    warn "Clone of tag/branch '$VF_REF' failed; falling back to default branch."
    git clone --depth 1 "$REPO" "$INSTALL_DIR"
  fi
fi

# ────────────────────────────────────────────────────────────
# Plugin cache symlink — atomic, with safety check on existing path.
# ────────────────────────────────────────────────────────────
PLUGIN_CACHE_DIR="${HOME}/.claude/plugins/cache/validationforge/validationforge/${VF_VERSION}"
info "Registering plugin cache at ${PLUGIN_CACHE_DIR}..."
mkdir -p "$(dirname "$PLUGIN_CACHE_DIR")"

if [ -e "$PLUGIN_CACHE_DIR" ] || [ -L "$PLUGIN_CACHE_DIR" ]; then
  # Refuse to replace anything that isn't already a symlink under our own cache root.
  if [ ! -L "$PLUGIN_CACHE_DIR" ]; then
    die "Plugin cache path exists but is not a symlink: $PLUGIN_CACHE_DIR. Remove it manually and re-run."
  fi
  # Confirm owner matches current user (defence against pre-planted symlinks).
  owner=$(python3 -c "import os,sys,pwd; print(pwd.getpwuid(os.lstat(sys.argv[1]).st_uid).pw_name)" "$PLUGIN_CACHE_DIR" 2>/dev/null || echo "")
  if [ -n "$owner" ] && [ "$owner" != "${USER:-$owner}" ]; then
    die "Existing symlink at $PLUGIN_CACHE_DIR is owned by '$owner', not '$USER'. Refusing to replace."
  fi
fi

# `ln -sfn` atomically replaces the symlink (no TOCTOU window between rm and ln).
ln -sfn "$INSTALL_DIR" "$PLUGIN_CACHE_DIR"
ok "Plugin cache symlink created: ${PLUGIN_CACHE_DIR} -> ${INSTALL_DIR}"

# ────────────────────────────────────────────────────────────
# Install global rules with vf- prefix, tracked in a manifest
# so uninstall can remove only the files we installed.
# ────────────────────────────────────────────────────────────
info "Installing rules to ${RULES_DIR}..."
mkdir -p "$RULES_DIR"
RULES_MANIFEST="${HOME}/.claude/.vf-rules-manifest.txt"
: > "$RULES_MANIFEST"

rule_count=0
for rule_file in "$INSTALL_DIR"/rules/*.md; do
  [ -f "$rule_file" ] || continue
  rule_name=$(basename "$rule_file" .md)
  target="${RULES_DIR}/vf-${rule_name}.md"
  cp "$rule_file" "$target"
  echo "$target" >> "$RULES_MANIFEST"
  rule_count=$((rule_count + 1))
done

ok "${rule_count} rules installed (manifest: ${RULES_MANIFEST})"

# ────────────────────────────────────────────────────────────
# Create evidence directory in current project (if in a git repo)
# ────────────────────────────────────────────────────────────
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

# ────────────────────────────────────────────────────────────
# Save config
# ────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$CONFIG_FILE")"
cat > "$CONFIG_FILE" << EOF
{
  "setupCompleted": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "setupVersion": "${VF_VERSION}",
  "installDir": "$INSTALL_DIR",
  "installedRef": "$VF_REF",
  "source": "$REPO",
  "scope": "global"
}
EOF
ok "Config saved to $CONFIG_FILE"

# ────────────────────────────────────────────────────────────
# Register plugin — atomic JSON write with a lockfile so concurrent
# install/uninstall scripts or Claude Code's loader can't race.
# ────────────────────────────────────────────────────────────
INSTALLED_PLUGINS_FILE="${HOME}/.claude/installed_plugins.json"
info "Registering plugin in ${INSTALLED_PLUGINS_FILE}..."
mkdir -p "$(dirname "$INSTALLED_PLUGINS_FILE")"
python3 - "$INSTALLED_PLUGINS_FILE" "$INSTALL_DIR" << 'PYEOF'
import sys, json, os, fcntl, tempfile

plugins_file = sys.argv[1]
install_dir  = sys.argv[2]
plugin_key   = "validationforge@validationforge"
lock_path    = plugins_file + ".lock"

# Serialize with any concurrent writer.
with open(lock_path, "w") as lock_fh:
    fcntl.flock(lock_fh.fileno(), fcntl.LOCK_EX)

    # Read-modify (defensive against a corrupt existing file)
    if os.path.isfile(plugins_file):
        try:
            with open(plugins_file, "r") as fh:
                registry = json.load(fh)
        except (json.JSONDecodeError, ValueError):
            registry = {}
    else:
        registry = {}

    registry[plugin_key] = {"path": install_dir, "scope": "user"}

    # Atomic write via temp-file + os.replace.
    plugins_dir = os.path.dirname(plugins_file) or "."
    fd, tmp_path = tempfile.mkstemp(prefix=".vf-plugins-", dir=plugins_dir)
    try:
        with os.fdopen(fd, "w") as tmp_fh:
            json.dump(registry, tmp_fh, indent=2)
            tmp_fh.write("\n")
            tmp_fh.flush()
            os.fsync(tmp_fh.fileno())
        os.replace(tmp_path, plugins_file)
    except Exception:
        try: os.remove(tmp_path)
        except OSError: pass
        raise

    # Lock released on context exit.
PYEOF
ok "Plugin registered in ${INSTALLED_PLUGINS_FILE}"

# ────────────────────────────────────────────────────────────
# Summary + restart prompt
# ────────────────────────────────────────────────────────────
info ""
info "=== ValidationForge Installed ==="
info ""
info "  Version:  ${VF_VERSION}  (ref: ${VF_REF})"
info "  Plugin:   $INSTALL_DIR"
info "  Rules:    $RULES_DIR/vf-*.md  (${rule_count} files, manifested)"
info "  Config:   $CONFIG_FILE"
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
