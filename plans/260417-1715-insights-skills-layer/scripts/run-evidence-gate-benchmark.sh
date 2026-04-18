#!/usr/bin/env bash
# run-evidence-gate-benchmark.sh — benchmark scaffold for /evidence-gate skill.
#
# Orchestrates the skill-creator eval loop (with-skill + baseline) for all
# evals in evals/evidence-gate/evals.json.  Actual claude invocations are
# heavy (token-budget-gated); use --dry-run to inspect the planned invocations
# without spending tokens.
#
# Usage:
#   ./run-evidence-gate-benchmark.sh [OPTIONS]
#
# Options:
#   --dry-run             Print planned invocations; do not call claude.
#   --max-iterations N    Number of benchmark iterations to run (default: 1).
#   --runs-per-eval N     claude -p runs per eval per configuration (default: 3).
#
# Environment:
#   CLAUDE_RUN_TOKEN_CAP  Global token budget across all spawned claude -p calls.
#                         Monitored via common.sh watch_budget.  Default: 2000000.
#
# Outputs (per iteration):
#   evals/evidence-gate/iteration-N/
#     eval-<ID>-with-skill/outputs/     — with-skill run transcript + metrics
#     eval-<ID>-baseline/outputs/       — baseline (no-skill) run transcript
#     benchmark.json                    — aggregated results (schema: schemas.md)
#     benchmark.md                      — human-readable summary

set -euo pipefail
IFS=$'\n\t'

# ─── Paths ───────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_PATH="$HOME/.claude/skills/evidence-gate"
EVALS_JSON="$PLAN_DIR/evals/evidence-gate/evals.json"
WORKSPACE="$PLAN_DIR/evals/evidence-gate"
COMMON_SH="$HOME/.claude/scripts/headless/common.sh"
LOG_DIR="$PLAN_DIR/evals/evidence-gate/logs"
ABORT_SENTINEL="$LOG_DIR/ABORT"

# ─── Defaults ────────────────────────────────────────────────────────────────
DRY_RUN=false
MAX_ITERATIONS=1
RUNS_PER_EVAL=3

# ─── Arg parsing ─────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)          DRY_RUN=true;           shift ;;
    --max-iterations)   MAX_ITERATIONS="$2";    shift 2 ;;
    --runs-per-eval)    RUNS_PER_EVAL="$2";     shift 2 ;;
    *) echo "[ERROR] unknown argument: $1" >&2; exit 1 ;;
  esac
done

# ─── Bootstrap ───────────────────────────────────────────────────────────────
# shellcheck source=/Users/nick/.claude/scripts/headless/common.sh
source "$COMMON_SH"

require_bin claude jq

parse_budget   # exports TOKEN_CAP from CLAUDE_RUN_TOKEN_CAP or default

mkdir -p "$LOG_DIR"
BUDGET_LOG="$LOG_DIR/token-usage.jsonl"
rotate_log "$BUDGET_LOG"

# ─── Tool allowlist for spawned claude -p ────────────────────────────────────
ALLOWED_TOOLS='Read,Grep,Glob,Bash(git *),Bash(node *),Bash(python3 *),Edit,Task'
DISALLOWED_TOOLS='WebFetch,WebSearch'

# ─── Load eval list ──────────────────────────────────────────────────────────
if [[ ! -f "$EVALS_JSON" ]]; then
  echo "[ERROR] evals.json not found: $EVALS_JSON" >&2
  exit 1
fi

# Extract eval IDs and prompts into parallel arrays (bash 3.2 compat: no mapfile)
EVAL_IDS=()
while IFS= read -r line; do EVAL_IDS+=("$line"); done < <(jq -r '.evals[].id' "$EVALS_JSON")
EVAL_PROMPTS=()
while IFS= read -r line; do EVAL_PROMPTS+=("$line"); done < <(jq -r '.evals[].prompt' "$EVALS_JSON")
EVAL_COUNT=${#EVAL_IDS[@]}

echo "[INFO] loaded $EVAL_COUNT evals from $EVALS_JSON" >&2
echo "[INFO] TOKEN_CAP=$TOKEN_CAP  MAX_ITERATIONS=$MAX_ITERATIONS  RUNS_PER_EVAL=$RUNS_PER_EVAL  DRY_RUN=$DRY_RUN" >&2

# ─── Budget watcher (live runs only) ─────────────────────────────────────────
if [[ "$DRY_RUN" == false ]]; then
  watch_budget "$BUDGET_LOG" "$ABORT_SENTINEL" "$TOKEN_CAP" "$$" &
  BUDGET_WATCHER_PID=$!
  trap 'kill "$BUDGET_WATCHER_PID" 2>/dev/null || true' EXIT
fi

# ─── Helpers ─────────────────────────────────────────────────────────────────
# soft_stop_check — abort if sentinel was written by watch_budget or externally.
soft_stop_check() {
  if [[ -f "$ABORT_SENTINEL" ]]; then
    echo "[ABORT] sentinel found at $ABORT_SENTINEL — stopping." >&2
    exit 4
  fi
}

# build_claude_cmd — emit the full claude -p command for one run.
# Args: <prompt> <skill_flag_or_empty> <output_dir>
build_claude_cmd() {
  local prompt="$1"
  local skill_flag="$2"     # "--skill $SKILL_PATH" or ""
  local output_dir="$3"

  # shellcheck disable=SC2086
  printf 'claude -p %s \\\n' "$(printf '%q' "$prompt")"
  printf '  --allowedTools %s \\\n' "$(printf '%q' "$ALLOWED_TOOLS")"
  printf '  --disallowedTools %s \\\n' "$(printf '%q' "$DISALLOWED_TOOLS")"
  printf '  --output-format json \\\n'
  printf '  --verbose \\\n'
  if [[ -n "$skill_flag" ]]; then
    printf '  %s \\\n' "$skill_flag"
  fi
  printf '  > %s/transcript.json 2> %s/stderr.txt\n' \
    "$(printf '%q' "$output_dir")" "$(printf '%q' "$output_dir")"
}

# ─── Main loop ───────────────────────────────────────────────────────────────
for (( iter = 1; iter <= MAX_ITERATIONS; iter++ )); do
  echo "[INFO] === iteration $iter / $MAX_ITERATIONS ===" >&2
  soft_stop_check

  ITER_DIR="$WORKSPACE/iteration-${iter}"
  mkdir -p "$ITER_DIR"

  # Collect background PIDs for this iteration (parallel launch)
  declare -a PIDS=()
  declare -a PID_LABELS=()

  for (( ei = 0; ei < EVAL_COUNT; ei++ )); do
    eid="${EVAL_IDS[$ei]}"
    prompt="${EVAL_PROMPTS[$ei]}"

    for (( run = 1; run <= RUNS_PER_EVAL; run++ )); do
      soft_stop_check

      WITH_SKILL_DIR="$ITER_DIR/eval-${eid}-with-skill/run-${run}/outputs"
      BASELINE_DIR="$ITER_DIR/eval-${eid}-baseline/run-${run}/outputs"

      if [[ "$DRY_RUN" == true ]]; then
        echo ""
        echo "# ── eval ${eid}  run ${run}  [WITH SKILL] ──"
        build_claude_cmd "$prompt" "--skill $(printf '%q' "$SKILL_PATH")" "$WITH_SKILL_DIR"
        echo ""
        echo "# ── eval ${eid}  run ${run}  [BASELINE — no skill] ──"
        build_claude_cmd "$prompt" "" "$BASELINE_DIR"
      else
        mkdir -p "$WITH_SKILL_DIR" "$BASELINE_DIR"

        # Launch with-skill run in background
        (
          build_claude_cmd "$prompt" "--skill $SKILL_PATH" "$WITH_SKILL_DIR" | bash
          echo '{"run":"with-skill","eval_id":'"$eid"',"iteration":'"$iter"',"run_number":'"$run"',"ts":"'"$(timestamp_iso)"'"}' >> "$BUDGET_LOG"
        ) &
        PIDS+=($!)
        PID_LABELS+=("eval-${eid}-with-skill-run-${run}")

        # Launch baseline run in background
        (
          build_claude_cmd "$prompt" "" "$BASELINE_DIR" | bash
          echo '{"run":"baseline","eval_id":'"$eid"',"iteration":'"$iter"',"run_number":'"$run"',"ts":"'"$(timestamp_iso)"'"}' >> "$BUDGET_LOG"
        ) &
        PIDS+=($!)
        PID_LABELS+=("eval-${eid}-baseline-run-${run}")
      fi
    done
  done

  # Wait for all parallel runs in this iteration (live mode only)
  if [[ "$DRY_RUN" == false && ${#PIDS[@]} -gt 0 ]]; then
    echo "[INFO] waiting for ${#PIDS[@]} background processes..." >&2
    for (( pi = 0; pi < ${#PIDS[@]}; pi++ )); do
      wait "${PIDS[$pi]}" || echo "[WARN] ${PID_LABELS[$pi]} exited non-zero" >&2
    done
    echo "[INFO] iteration $iter complete" >&2

    # Stub: aggregate into benchmark.json (requires skill-creator aggregate_benchmark.py)
    echo "[INFO] aggregate step — run manually:" >&2
    echo "  python -m scripts.aggregate_benchmark $ITER_DIR --skill-name evidence-gate" >&2
  fi
done

if [[ "$DRY_RUN" == true ]]; then
  echo ""
  echo "# ── DRY RUN COMPLETE ──"
  echo "# Total planned invocations: $(( EVAL_COUNT * RUNS_PER_EVAL * 2 * MAX_ITERATIONS )) claude -p calls"
  echo "# Token cap: $TOKEN_CAP"
  echo "# Workspace: $WORKSPACE"
fi
