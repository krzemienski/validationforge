#!/bin/bash
# Sync shared content (skills, commands) to .opencode/ directories via symlinks.
# Run after adding new skills or commands.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

mkdir -p "$PROJECT_ROOT/.opencode/skill" "$PROJECT_ROOT/.opencode/command"

# M7: refuse to overwrite pre-existing regular files/directories at the
# target path. `ln -sf` would silently unlink the target; that's data
# loss if a developer checked in real files at .opencode/skill/<name>.
# Use `ln -sfn` so existing symlinks-to-directories are replaced
# atomically (matches install.sh:89-102's hardened pattern).

# Sync skills
synced_skills=0
for skill_dir in "$PROJECT_ROOT"/skills/*/; do
  name=$(basename "$skill_dir")
  target="$PROJECT_ROOT/.opencode/skill/$name"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "REFUSE: $target exists and is not a symlink" >&2
    continue
  fi
  ln -sfn "../../skills/$name" "$target"
  synced_skills=$((synced_skills + 1))
done

# Sync commands
synced_commands=0
for cmd in "$PROJECT_ROOT"/commands/*.md; do
  name=$(basename "$cmd")
  target="$PROJECT_ROOT/.opencode/command/$name"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "REFUSE: $target exists and is not a symlink" >&2
    continue
  fi
  ln -sfn "../../commands/$name" "$target"
  synced_commands=$((synced_commands + 1))
done

echo "Synced $synced_skills skills and $synced_commands commands to .opencode/"
