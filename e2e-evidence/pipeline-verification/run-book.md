# End-to-End Pipeline Verification — Run-Book

**Spec:** `./.auto-claude/specs/001-end-to-end-pipeline-verification/spec.md`
**Plan:** `./.auto-claude/specs/001-end-to-end-pipeline-verification/implementation_plan.json`
**Worktree:** `/Users/nick/Desktop/validationforge/.auto-claude/worktrees/tasks/001-end-to-end-pipeline-verification`
**Fixture decision:** `./e2e-evidence/pipeline-verification/api-fixture-decision.md`
**Author:** auto-claude orchestrator (subtask 1.3)
**Date:** 2026-04-17

---

## 0. Purpose

This run-book documents the **exact** invocations required by subtasks **2.2** and **3.2** of the implementation plan. The coder sandbox **cannot** execute the `claude` CLI (PreToolUse callback blocks it), so these two subtasks are flagged `verification_type: "manual"` and must be run from a live Claude Code session by the orchestrator or the user. This document is the operating checklist for that live session.

**Iron Rule reminder (CLAUDE.md):**
1. If the real system doesn't work, FIX THE REAL SYSTEM.
2. NEVER create mocks, stubs, test doubles, or test files.
3. NEVER mark a journey PASS without specific cited evidence.
4. NEVER skip preflight — if it fails, STOP.
8. Compilation success ≠ functional validation.

---

## 1. Operator Prerequisites

Run these once before starting either platform run.

### 1.1 Sandbox-side checks (already automated via subtask 1.4)

These will be re-run by `./scripts/e2e-pipeline-check.sh` when that subtask lands. For now, verify manually:

```bash
cd /Users/nick/Desktop/validationforge/.auto-claude/worktrees/tasks/001-end-to-end-pipeline-verification

# Plugin install state (subtask 1.1)
bash ./scripts/verify-setup.sh

# Fixture decision present and non-empty (subtask 1.2)
test -s ./e2e-evidence/pipeline-verification/api-fixture-decision.md && echo "[ok] fixture decision present"

# Evidence scaffolding present (this subtask, 1.3)
test -d ./e2e-evidence/pipeline-verification/web && \
test -d ./e2e-evidence/pipeline-verification/api && \
test -s ./e2e-evidence/pipeline-verification/run-book.md && \
echo "[ok] scaffolding present"
```

### 1.2 Live-session-side checks

In the live Claude Code session (from any CWD):

```bash
# Claude CLI available
which claude
claude --version

# Plugin config readable — NOT a hard fail if missing; the pipeline uses defaults
cat ~/.claude/.vf-config.json 2>/dev/null || echo "[warn] no vf-config; defaults will apply"
```

### 1.3 Fixture reachability

Both fixtures must answer on their documented ports **before** the `/validate-ci` call.

```bash
# Web fixture: Next.js blog-series/site on :3847
curl -sI http://localhost:3847 | head -1
# Expect: HTTP/1.1 200 OK

# API fixture: FastAPI cg-ffmpeg on :8000
curl -sI http://localhost:8000/health | head -1
# Expect: HTTP/1.1 200 OK
```

If either is not reachable, start it (sections 2.1 / 3.1 below) **before** invoking `/validate-ci`.

---

## 2. Web Platform Run (subtask 2.2)

Covers `implementation_plan.json` → `phase-2-web-run` → subtask `2.2`.

### 2.1 Start the web fixture (subtask 2.1)

```bash
# Port precedent: ./e2e-evidence/web-validation/VERDICT.md used :3847 and passed 6/6.
cd /Users/nick/Desktop/blog-series/site

# Install deps if first run
pnpm install

# Boot dev server on the pinned port (background)
PORT=3847 pnpm dev &
WEB_PID=$!

# Wait up to 60 s for readiness
for i in $(seq 1 60); do
  curl -sf http://localhost:3847 > /dev/null && break
  sleep 1
done
curl -sI http://localhost:3847 | head -1
# Expected: HTTP/1.1 200 OK
```

Record `HTTP/1.1 200 OK` as proof of subtask 2.1 before proceeding.

### 2.2 Invoke `/validate-ci --platform web`

**Exact command — run from the live Claude Code session, not the sandbox:**

```bash
cd /Users/nick/Desktop/blog-series/site
```

Then in the Claude Code REPL (or `claude --print` outside the REPL):

```
/validate-ci --platform web
```

**If scripting with the CLI directly:**

```bash
# CWD matters — ValidationForge writes e2e-evidence/ relative to CWD
cd /Users/nick/Desktop/blog-series/site

# No secret env required; optional verbose config summary:
VF_VERBOSE=1 claude --print "/validate-ci --platform web"
echo "EXIT_CODE=$?"   # Capture immediately — required by subtask 4.2
```

**Environment expectations:**

| Variable | Source | Required? | Purpose |
|----------|--------|-----------|---------|
| `HOME` | shell | yes (implicit) | ValidationForge reads `$HOME/.claude/.vf-config.json` |
| `PATH` | shell | yes (implicit) | Must include `claude`, `pnpm`, `curl`, `jq` |
| `VF_VERBOSE` | operator | optional | Echoes the resolved config summary |
| `FLAG_PLATFORM` | command-line | overridden via `--platform web` | Ensures web skills run even if auto-detect would miss |

**Exit-code expectation (record both even if they match):**

| Scenario | Expected code |
|----------|---------------|
| All journeys PASS | `0` |
| Any journey FAIL | `1` |

### 2.3 Post-run: copy evidence into verification tree

The `/validate-ci` command writes into `<CWD>/e2e-evidence/`. That is **not** the pipeline-verification location. The operator must relocate it **without overwriting** prior runs:

```bash
# From the live session host (same CWD or absolute path):
SRC="/Users/nick/Desktop/blog-series/site/e2e-evidence"
DST="/Users/nick/Desktop/validationforge/.auto-claude/worktrees/tasks/001-end-to-end-pipeline-verification/e2e-evidence/pipeline-verification/web"

# Sanity: destination must already exist with only .gitkeep
ls "$DST"

# Copy contents (not the top dir itself)
cp -R "$SRC/." "$DST/"

# Append exit code observation — required for subtask 4.2
echo "observed_exit=<code>  expected_exit=<0|1>" >> "$DST/exit-code.txt"
```

### 2.4 Expected artifacts under `./e2e-evidence/pipeline-verification/web/`

At minimum (enforced by subtask 2.3 verification_command):

- `report.md` — unified verdict with per-journey PASS/FAIL table
- `validation-plan.md` — the auto-approved plan from stage 3 of the pipeline
- `**/*.png` — ≥3 screenshots (home, navigation, interaction state)
- `**/*.json` — chrome-devtools / playwright network captures
- `exit-code.txt` — the `$?` value captured immediately after the claude invocation

`find ./e2e-evidence/pipeline-verification/web -type f \( -name '*.png' -o -name '*.md' -o -name '*.json' -o -name '*.txt' \) | wc -l` must be ≥4, and `find ./e2e-evidence/pipeline-verification/web -type f -size 0` must be empty.

### 2.5 Web run cleanup

```bash
# Stop the dev server started in 2.1
kill $WEB_PID 2>/dev/null || true
```

---

## 3. API Platform Run (subtask 3.2)

Covers `phase-3-api-run` → subtask `3.2`. Fixture chosen in subtask 1.2 → see `./api-fixture-decision.md`.

### 3.1 Start the API fixture (subtask 3.1)

```bash
cd /Users/nick/Desktop/cg-ffmpeg

# Optional but recommended: isolated venv
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Launch (either invocation is real; server.py is the default)
python server.py &
API_PID=$!

# Wait up to 30 s for readiness
for i in $(seq 1 30); do
  curl -sf http://localhost:8000/health > /dev/null && break
  sleep 1
done

# Capture readiness proof — subtask 3.1 acceptance
curl -s http://localhost:8000/health \
  -w '\nHTTP_STATUS=%{http_code}\n' \
  | tee /Users/nick/Desktop/validationforge/.auto-claude/worktrees/tasks/001-end-to-end-pipeline-verification/e2e-evidence/pipeline-verification/api/step-00-readiness.json
```

### 3.2 Invoke `/validate-ci --platform api`

**Exact command:**

```bash
cd /Users/nick/Desktop/cg-ffmpeg
```

In the Claude Code REPL:

```
/validate-ci --platform api
```

Or via `claude --print`:

```bash
cd /Users/nick/Desktop/cg-ffmpeg
VF_VERBOSE=1 claude --print "/validate-ci --platform api"
echo "EXIT_CODE=$?"
```

**Environment expectations** — identical to section 2.2. No API keys, no database credentials. `cg-ffmpeg` is a self-contained simulator (see api-fixture-decision.md §5, "Rejected Candidates" table, for why other projects that required secrets were declined).

**Exit-code expectation** — same as section 2.2. Per the plan: "Command exits with code 0 (if all PASS) or 1 (if any FAIL — still a valid outcome for verification purposes; we care that the CODE is correct)."

### 3.3 Post-run: copy evidence into verification tree

```bash
SRC="/Users/nick/Desktop/cg-ffmpeg/e2e-evidence"
DST="/Users/nick/Desktop/validationforge/.auto-claude/worktrees/tasks/001-end-to-end-pipeline-verification/e2e-evidence/pipeline-verification/api"

ls "$DST"      # Should show .gitkeep + step-00-readiness.json

cp -R "$SRC/." "$DST/"

echo "observed_exit=<code>  expected_exit=<0|1>" >> "$DST/exit-code.txt"
```

### 3.4 Expected artifacts under `./e2e-evidence/pipeline-verification/api/`

At minimum (enforced by subtask 3.3 verification_command):

- `report.md` — per-journey PASS/FAIL table, cites evidence JSON files
- `validation-plan.md`
- `step-00-readiness.json` — `GET /health` capture from 3.1
- `step-NN-*.json` — ≥1 curl response body for a real CRUD operation (per api-fixture-decision.md §4, the 9-step journey plan: health → jobs-empty → origins → create → status → jobs-after → stop → 404 → 400)
- `evidence-inventory.txt` — per the api-validation SKILL
- `exit-code.txt`

`find ./e2e-evidence/pipeline-verification/api -type f \( -name '*.json' -o -name '*.md' -o -name '*.txt' \) | wc -l` must be ≥3, and every `*.json` must be parseable by `jq`.

### 3.5 API run cleanup

```bash
# Stop the FastAPI server
kill $API_PID 2>/dev/null || true
deactivate 2>/dev/null || true
```

---

## 4. After Both Runs

Return to the sandbox session to execute phase-4 subtasks (`4.1` unified report, `4.2` exit-code proof, `4.3` 7-phase sequence grep). Those subtasks operate on the copied-in evidence under `./e2e-evidence/pipeline-verification/{web,api}/` and do **not** require `claude` invocation.

```bash
# Quick gate check — matches phase-4 verifier
for p in web api; do
  for ph in RESEARCH PLAN PREFLIGHT EXECUTE ANALYZE VERDICT SHIP; do
    grep -qi "$ph" ./e2e-evidence/pipeline-verification/$p/report.md \
      || echo "[gate] missing $ph in $p"
  done
done
```

---

## 5. Failure Handling

Per CLAUDE.md Iron Rule #5 (3-strike max) and the plan's `fix_loop_policy`:

| Symptom | Action |
|---------|--------|
| `curl` to :3847 or :8000 fails before invoking `/validate-ci` | Restart fixture. Do NOT proceed until health check returns 2xx. |
| `/validate-ci` exits 1 | Inspect `report.md`. If FAILs are caused by real app defects, open a bugfix subtask. Do NOT re-run without addressing the root cause. |
| `/validate-ci` exits 0 but evidence missing the 7 phase names | Bug in `/validate` command template. File a subtask; do not paper over with a manual grep claim. |
| A journey fails 3× | Halt. Escalate to the user with evidence. Never fabricate a PASS. |
| Any subtask is tempted to create a test API / shim | STOP. Iron Rule #2. Re-read `./api-fixture-decision.md` §1 ("No-Mock Compliance Statement"). |

---

## 6. Change Log

| Version | Date | Note |
|---------|------|------|
| 1.0 | 2026-04-17 | Initial run-book created for subtask 1.3. Covers web (blog-series/site :3847) and api (cg-ffmpeg :8000) invocations. |
