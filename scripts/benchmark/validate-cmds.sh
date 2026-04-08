#!/usr/bin/env bash
# Validate structural integrity of all ValidationForge commands.
# Checks frontmatter: name/description present.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
CMDS_DIR="$PROJECT_ROOT/commands"

pass=0
fail=0
total=0

echo "=== ValidationForge Command Structural Validation ==="
echo ""

for cmd_file in "$CMDS_DIR"/*.md; do
  [ -f "$cmd_file" ] || continue
  cmd_name=$(basename "$cmd_file" .md)
  total=$((total + 1))

  issues=""

  # Check frontmatter exists (--- delimiters)
  if ! head -1 "$cmd_file" | grep -q '^---'; then
    issues="${issues}missing frontmatter; "
  fi

  # Check description
  fm_desc=$(grep -m1 '^description:' "$cmd_file" 2>/dev/null | sed 's/^description:\s*//')
  if [ -z "$fm_desc" ]; then
    issues="${issues}missing description; "
  fi

  # Check file length
  line_count=$(wc -l < "$cmd_file" | tr -d ' ')
  if [ "$line_count" -lt 3 ]; then
    issues="${issues}too short ($line_count lines); "
  fi

  if [ -z "$issues" ]; then
    echo "PASS: $cmd_name ($line_count lines)"
    pass=$((pass + 1))
  else
    echo "FAIL: $cmd_name — $issues"
    fail=$((fail + 1))
  fi
done

echo ""
echo "=== SUMMARY ==="
echo "Total: $total  Pass: $pass  Fail: $fail"
echo '{"total":'$total',"pass":'$pass',"fail":'$fail'}'
