#!/usr/bin/env bash
# End-to-End Pipeline Verification Harness
#
# Runs all sandbox-side preflight checks that the orchestrator needs GREEN
# before invoking `/validate-ci --platform web` and `/validate-ci --platform api`
# from a live Claude Code session (subtasks 2.2 and 3.2).
#
# This script NEVER invokes `claude` directly — that is blocked by the
# sandbox PreToolUse callback, and the run-book already delegates those
# invocations to the live-session operator.
#
# Scope:
#   (a) set -euo pipefail
#   (b) run scripts/verify-setup.sh
#   (c) confirm web fixture reachable (default http://localhost:3847)
#   (d) confirm chosen API fixture reachable (default http://localhost:8000/health)
#   (e) print orchestrator-run instructions (copy-pasteable)
#
# Usage:
#   bash ./scripts/e2e-pipeline-check.sh
#   WEB_URL=http://localhost:3000 API_URL=http://localhost:8001/health \
#       bash ./scripts/e2e-pipeline-check.sh
#
# Exit codes:
#   0 — all preflight checks passed; orchestrator may proceed to phases 2/3
#   1 — one or more preflight checks failed; do NOT invoke /validate-ci yet

set -euo pipefail

# --- Paths (relative to worktree root; the script is invoked from the root) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERIFY_SETUP="${SCRIPT_DIR}/verify-setup.sh"
HEALTH_CHECK="${SCRIPT_DIR}/health-check.sh"
FIXTURE_DECISION="${PROJECT_DIR}/e2e-evidence/pipeline-verification/api-fixture-decision.md"
RUN_BOOK="${PROJECT_DIR}/e2e-evidence/pipeline-verification/run-book.md"

# --- Tunables (override via env) ---
WEB_URL="${WEB_URL:-http://localhost:3847}"
API_URL="${API_URL:-http://localhost:8000/health}"
WEB_FIXTURE_PATH="${WEB_FIXTURE_PATH:-/Users/nick/Desktop/blog-series/site}"
API_FIXTURE_PATH="${API_FIXTURE_PATH:-/Users/nick/Desktop/cg-ffmpeg}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-5}"
INTERVAL="${INTERVAL:-1}"

# --- URL scheme whitelist — prevent SSRF via file://, gopher://, dict://, etc. ---
for url_name in WEB_URL API_URL; do
  url_val="${!url_name}"
  case "$url_val" in
    http://*|https://*) ;;
    *) echo "[VF] ERROR: ${url_name} must be http:// or https://. Got: ${url_val}" >&2; exit 1 ;;
  esac
done

# --- Reporting helpers (match verify-setup.sh style) ---
PASS=0
FAIL=0
FAILED_CHECKS=()

ok()      { echo "  [OK] $1";       PASS=$((PASS + 1)); }
missing() { echo "  [MISSING] $1";  FAIL=$((FAIL + 1)); FAILED_CHECKS+=("$1"); }

section() { echo ""; echo "=== $1 ==="; }

echo "=== ValidationForge — End-to-End Pipeline Check ==="
echo "Worktree: ${PROJECT_DIR}"
echo ""

# --- 1. Setup verification (delegates to verify-setup.sh) ---
section "1. Plugin + setup verification"

if [ ! -f "$VERIFY_SETUP" ]; then
  missing "verify-setup.sh not found at ${VERIFY_SETUP}"
else
  # Run verify-setup.sh but do NOT let its exit code abort us — we want to
  # aggregate failures across all preflight sections and report once at the
  # bottom. set -e is temporarily disabled around this call for that reason.
  set +e
  bash "$VERIFY_SETUP" "$PROJECT_DIR"
  verify_rc=$?
  set -e
  if [ "$verify_rc" -eq 0 ]; then
    ok "verify-setup.sh passed"
  else
    missing "verify-setup.sh failed (exit ${verify_rc}). Run /vf-setup in a live Claude Code session."
  fi
fi

# --- 2. Fixture provenance (documents exist) ---
section "2. Fixture provenance"

if [ -s "$FIXTURE_DECISION" ]; then
  ok "API fixture decision present: e2e-evidence/pipeline-verification/api-fixture-decision.md"
else
  missing "API fixture decision missing or empty: ${FIXTURE_DECISION}"
fi

if [ -s "$RUN_BOOK" ]; then
  ok "Run-book present: e2e-evidence/pipeline-verification/run-book.md"
else
  missing "Run-book missing or empty: ${RUN_BOOK}"
fi

# --- 3. Evidence scaffolding (destination dirs exist) ---
section "3. Evidence scaffolding"

for sub in web api; do
  dir="${PROJECT_DIR}/e2e-evidence/pipeline-verification/${sub}"
  if [ -d "$dir" ]; then
    ok "Evidence directory present: e2e-evidence/pipeline-verification/${sub}/"
  else
    missing "Evidence directory missing: ${dir}"
  fi
done

# --- 4. Web fixture reachability ---
section "4. Web fixture reachability"
echo "  Probing: ${WEB_URL} (max ${MAX_ATTEMPTS} attempts @ ${INTERVAL}s)"

if [ ! -x "$HEALTH_CHECK" ]; then
  missing "health-check.sh not executable at ${HEALTH_CHECK}"
else
  set +e
  web_out=$("$HEALTH_CHECK" "$WEB_URL" "$MAX_ATTEMPTS" "$INTERVAL" 2>&1)
  web_rc=$?
  set -e
  # Indent the inner script's output so it is readable as part of this section
  echo "${web_out}" | sed 's/^/    /'
  if [ "$web_rc" -eq 0 ]; then
    ok "Web fixture reachable at ${WEB_URL}"
  else
    missing "Web fixture NOT reachable at ${WEB_URL} — start it per run-book §2.1 (PORT=3847 pnpm dev in ${WEB_FIXTURE_PATH})"
  fi
fi

# --- 5. API fixture reachability ---
section "5. API fixture reachability"
echo "  Probing: ${API_URL} (max ${MAX_ATTEMPTS} attempts @ ${INTERVAL}s)"

if [ ! -x "$HEALTH_CHECK" ]; then
  missing "health-check.sh not executable at ${HEALTH_CHECK}"
else
  set +e
  api_out=$("$HEALTH_CHECK" "$API_URL" "$MAX_ATTEMPTS" "$INTERVAL" 2>&1)
  api_rc=$?
  set -e
  echo "${api_out}" | sed 's/^/    /'
  if [ "$api_rc" -eq 0 ]; then
    ok "API fixture reachable at ${API_URL}"
  else
    missing "API fixture NOT reachable at ${API_URL} — start it per run-book §3.1 (python server.py in ${API_FIXTURE_PATH})"
  fi
fi

# --- Summary ---
TOTAL=$((PASS + FAIL))
section "Summary"
echo "  ${PASS}/${TOTAL} preflight checks passed"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "  Failed checks:"
  for f in "${FAILED_CHECKS[@]}"; do
    echo "    - ${f}"
  done
  echo ""
  echo "  Phase-1 gate is RED. Fix the items above before invoking /validate-ci."
  echo "  The orchestrator must NOT proceed to phase-2 or phase-3."
  exit 1
fi

# --- Orchestrator-run instructions (only on full pass) ---
section "Orchestrator-run instructions (live Claude Code session)"
cat <<'EOF'

  Phase-1 gate is GREEN. Proceed to phases 2 and 3 from a LIVE Claude Code
  session (this sandbox cannot invoke `claude` — see run-book §0).

  ----- Phase 2: Web platform run (subtask 2.2) -----

    cd /Users/nick/Desktop/blog-series/site
    VF_VERBOSE=1 claude --print "/validate-ci --platform web"
    echo "EXIT_CODE=$?"   # record immediately — required by subtask 4.2

    # Relocate evidence into the verification tree:
    SRC="/Users/nick/Desktop/blog-series/site/e2e-evidence"
    DST="<worktree>/e2e-evidence/pipeline-verification/web"
    cp -R "$SRC/." "$DST/"
    echo "observed_exit=<code>  expected_exit=<0|1>" >> "$DST/exit-code.txt"

  ----- Phase 3: API platform run (subtask 3.2) -----

    cd /Users/nick/Desktop/cg-ffmpeg
    VF_VERBOSE=1 claude --print "/validate-ci --platform api"
    echo "EXIT_CODE=$?"   # record immediately — required by subtask 4.2

    # Relocate evidence into the verification tree:
    SRC="/Users/nick/Desktop/cg-ffmpeg/e2e-evidence"
    DST="<worktree>/e2e-evidence/pipeline-verification/api"
    cp -R "$SRC/." "$DST/"
    echo "observed_exit=<code>  expected_exit=<0|1>" >> "$DST/exit-code.txt"

  ----- After both runs -----

    Return to the sandbox session for phase-4 subtasks (4.1 unified report,
    4.2 exit-code proof, 4.3 7-phase sequence grep). Those subtasks operate
    on the relocated evidence and do NOT require a live `claude` call.

  Full run-book: ./e2e-evidence/pipeline-verification/run-book.md
  Iron Rules reminder: CLAUDE.md §"The Iron Rules" (no mocks, cite evidence,
  never paper over a missing phase — fix the /validate template and re-run).

EOF

exit 0
