#!/usr/bin/env bash
# Validate structural integrity of all ValidationForge skills.
# Checks SKILL.md frontmatter: name, description, dir match.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
SKILLS_DIR="$PROJECT_ROOT/skills"

pass=0
fail=0
total=0
warnings=0

echo "=== ValidationForge Skill Structural Validation ==="
echo ""

for skill_dir in "$SKILLS_DIR"/*/; do
  [ -d "$skill_dir" ] || continue
  dir_name=$(basename "$skill_dir")
  skill_file="$skill_dir/SKILL.md"
  total=$((total + 1))

  if [ ! -f "$skill_file" ]; then
    echo "FAIL: $dir_name — missing SKILL.md"
    fail=$((fail + 1))
    continue
  fi

  # Extract frontmatter name
  fm_name=$(grep -m1 '^name:' "$skill_file" 2>/dev/null | sed 's/^name:\s*//' | tr -d '"' | tr -d "'" | xargs)
  fm_desc=$(grep -m1 '^description:' "$skill_file" 2>/dev/null | sed 's/^description:\s*//' | tr -d '"' | tr -d "'")

  issues=""

  # Check name exists
  if [ -z "$fm_name" ]; then
    issues="${issues}missing name; "
  elif [ "$fm_name" != "$dir_name" ]; then
    issues="${issues}name mismatch (dir=$dir_name, name=$fm_name); "
  fi

  # Check description exists
  if [ -z "$fm_desc" ]; then
    issues="${issues}missing description; "
  fi

  # Check description length
  desc_len=${#fm_desc}
  if [ "$desc_len" -gt 1024 ]; then
    issues="${issues}description too long ($desc_len chars); "
  fi

  # Check file is non-empty (beyond frontmatter)
  line_count=$(wc -l < "$skill_file" | tr -d ' ')
  if [ "$line_count" -lt 5 ]; then
    issues="${issues}too short ($line_count lines); "
  fi

  if [ -z "$issues" ]; then
    echo "PASS: $dir_name ($line_count lines)"
    pass=$((pass + 1))
  else
    echo "FAIL: $dir_name — $issues"
    fail=$((fail + 1))
  fi
done

echo ""
echo "=== SUMMARY ==="
echo "Total: $total  Pass: $pass  Fail: $fail  Warnings: $warnings"
echo '{"total":'$total',"pass":'$pass',"fail":'$fail',"warnings":'$warnings'}'
