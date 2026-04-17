#!/usr/bin/env bash
# forge-plan-merge.sh — consensus-mode plan merger.
#
# Usage: bash forge-plan-merge.sh --plan-a=PATH --plan-b=PATH --output=PATH
#
# Merges two markdown validation plans produced by forge-plan perspectives
# (e.g. planner-1.md and planner-2.md) into a single consensus plan by
# deduplicating journeys by name and unioning PASS criteria per journey.
# Conflicts between plans are emitted to stderr for human review and the
# output retains plan A's version annotated with an HTML comment.
#
# Conflict line format (stderr):
#   CONFLICT: <journey> / <criterion> — plan A says "X", plan B says "Y"
#
# Exit codes: 0 on success (including when conflicts exist), 2 on bad args.

set -euo pipefail

PLAN_A=""
PLAN_B=""
OUTPUT=""

for arg in "$@"; do
  case "$arg" in
    --plan-a=*) PLAN_A="${arg#--plan-a=}" ;;
    --plan-b=*) PLAN_B="${arg#--plan-b=}" ;;
    --output=*) OUTPUT="${arg#--output=}" ;;
    -h|--help)
      sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *)
      echo "forge-plan-merge: unknown arg: $arg" >&2
      exit 2 ;;
  esac
done

if [[ -z "$PLAN_A" || -z "$PLAN_B" || -z "$OUTPUT" ]]; then
  echo "forge-plan-merge: --plan-a, --plan-b, and --output are all required" >&2
  exit 2
fi

for p in "$PLAN_A" "$PLAN_B"; do
  if [[ ! -f "$p" ]]; then
    echo "forge-plan-merge: not a file: $p" >&2
    exit 2
  fi
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMPL="$SCRIPT_DIR/_merge_impl.py"

if [[ ! -f "$IMPL" ]]; then
  echo "forge-plan-merge: missing impl: $IMPL" >&2
  exit 2
fi

exec python3 "$IMPL" --plan-a="$PLAN_A" --plan-b="$PLAN_B" --output="$OUTPUT"
