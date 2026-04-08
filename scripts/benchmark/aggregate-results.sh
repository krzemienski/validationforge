#!/usr/bin/env bash
# Aggregate benchmark results from hook tests, skill validation, and command validation.
# Outputs weighted score JSON to audit-artifacts/benchmark-baseline.json.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
ARTIFACTS="$PROJECT_ROOT/audit-artifacts"

mkdir -p "$ARTIFACTS"

echo "=== ValidationForge Benchmark Aggregator ==="

# Run hook tests
echo ""
echo "--- Running hook tests ---"
hook_output=$(bash "$SCRIPT_DIR/test-hooks.sh" 2>/dev/null | tail -1)
hook_total=$(echo "$hook_output" | grep -o '"total":[0-9]*' | cut -d: -f2)
hook_pass=$(echo "$hook_output" | grep -o '"pass":[0-9]*' | cut -d: -f2)
hook_fail=$(echo "$hook_output" | grep -o '"fail":[0-9]*' | cut -d: -f2)
hook_score=$(( hook_pass * 100 / (hook_total > 0 ? hook_total : 1) ))
echo "Hooks: $hook_pass/$hook_total pass (${hook_score}%)"

# Run skill validation
echo ""
echo "--- Running skill validation ---"
skill_output=$(bash "$SCRIPT_DIR/validate-skills.sh" 2>/dev/null | tail -1)
skill_total=$(echo "$skill_output" | grep -o '"total":[0-9]*' | cut -d: -f2)
skill_pass=$(echo "$skill_output" | grep -o '"pass":[0-9]*' | cut -d: -f2)
skill_fail=$(echo "$skill_output" | grep -o '"fail":[0-9]*' | cut -d: -f2)
skill_score=$(( skill_pass * 100 / (skill_total > 0 ? skill_total : 1) ))
echo "Skills: $skill_pass/$skill_total pass (${skill_score}%)"

# Run command validation
echo ""
echo "--- Running command validation ---"
cmd_output=$(bash "$SCRIPT_DIR/validate-cmds.sh" 2>/dev/null | tail -1)
cmd_total=$(echo "$cmd_output" | grep -o '"total":[0-9]*' | cut -d: -f2)
cmd_pass=$(echo "$cmd_output" | grep -o '"pass":[0-9]*' | cut -d: -f2)
cmd_fail=$(echo "$cmd_output" | grep -o '"fail":[0-9]*' | cut -d: -f2)
cmd_score=$(( cmd_pass * 100 / (cmd_total > 0 ? cmd_total : 1) ))
echo "Commands: $cmd_pass/$cmd_total pass (${cmd_score}%)"

# Weighted aggregate: correctness 40%, format 20%, error handling 20%, security 20%
# Hook tests cover correctness + error handling, skill/cmd cover format
weighted_score=$(( (hook_score * 60 + skill_score * 20 + cmd_score * 20) / 100 ))

echo ""
echo "=== AGGREGATE ==="
echo "Weighted score: ${weighted_score}%"

# Grade
grade="F"
[ "$weighted_score" -ge 60 ] && grade="D"
[ "$weighted_score" -ge 70 ] && grade="C"
[ "$weighted_score" -ge 80 ] && grade="B"
[ "$weighted_score" -ge 90 ] && grade="A"
echo "Grade: $grade"

# Write baseline JSON
cat > "$ARTIFACTS/benchmark-baseline.json" << ENDJSON
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "hooks": {
    "total": $hook_total,
    "pass": $hook_pass,
    "fail": $hook_fail,
    "score": $hook_score
  },
  "skills": {
    "total": $skill_total,
    "pass": $skill_pass,
    "fail": $skill_fail,
    "score": $skill_score
  },
  "commands": {
    "total": $cmd_total,
    "pass": $cmd_pass,
    "fail": $cmd_fail,
    "score": $cmd_score
  },
  "aggregate": {
    "weighted_score": $weighted_score,
    "grade": "$grade"
  }
}
ENDJSON

echo ""
echo "Baseline saved to $ARTIFACTS/benchmark-baseline.json"
