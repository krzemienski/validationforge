#!/bin/bash
# Sync shared content (skills, commands) to .opencode/ directories via symlinks.
# Run after adding new skills or commands.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

mkdir -p "$PROJECT_ROOT/.opencode/skill" "$PROJECT_ROOT/.opencode/command"

# Sync skills
synced_skills=0
for skill_dir in "$PROJECT_ROOT"/skills/*/; do
  name=$(basename "$skill_dir")
  target="$PROJECT_ROOT/.opencode/skill/$name"
  if [ ! -L "$target" ]; then
    ln -sf "../../skills/$name" "$target"
  fi
  synced_skills=$((synced_skills + 1))
done

# Sync commands
synced_commands=0
for cmd in "$PROJECT_ROOT"/commands/*.md; do
  name=$(basename "$cmd")
  target="$PROJECT_ROOT/.opencode/command/$name"
  if [ ! -L "$target" ]; then
    ln -sf "../../commands/$name" "$target"
  fi
  synced_commands=$((synced_commands + 1))
done

echo "Synced $synced_skills skills and $synced_commands commands to .opencode/"
