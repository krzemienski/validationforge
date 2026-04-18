# Phase C5 — Headless Runners — Evidence Report

**Date:** 2026-04-18  
**Branch:** insights/phase-0-schema-freeze

---

## 1. Deliverables Created

| File | Path | Status |
|------|------|--------|
| `common.sh` | `~/.claude/scripts/headless/common.sh` | Updated (merged budget utils + preserved C3 env-scrubbing) |
| `bug-audit-swarm.sh` | `~/.claude/scripts/headless/bug-audit-swarm.sh` | Created |
| `gt-tuner.sh` | `yt-transition-shorts-detector/scripts/headless/gt-tuner.sh` | Created |
| `README.md` | `~/.claude/scripts/headless/README.md` | Created |

**`.gitignore` modification:** Not needed. `logs/` already present at line 126 of
`yt-transition-shorts-detector/.gitignore`.

**C3 artifact preserved:** `~/.claude/scripts/headless/gt-tuner.sh` (Phase C3
env-scrubbing runner) was **not overwritten**. Phase C5's gt-tuner.sh lives in the
yt-transition-shorts-detector repo at a separate path.

---

## 2. `--allowedTools` Grammar — Authoritative Finding

From `headless.md` and `claude --help`:
```
--allowedTools "Bash(git *) Edit"
--allowedTools "Bash(npm install),mcp__filesystem"
```

**Correct syntax:** `Bash(prefix *)` — space-separated prefix within parens.  
**Spec §5 used:** `Bash(git:*)` — **colon form is invalid**; corrected to `Bash(git *)`.

**`timeout` availability:** Neither `timeout` nor `gtimeout` present on this macOS.
Shell-native fallback implemented in `run_with_timeout()` (background process + async killer).
Install via `brew install coreutils` to use `gtimeout`.

---

## 3. bash -n Syntax Check

All three shell files pass with zero output (exit 0):

```
common.sh: OK
bug-audit-swarm.sh: OK
gt-tuner.sh: OK
```

---

## 4. Executable Bits (chmod +x verification)

```
~/.claude/scripts/headless/
  -rwxr-xr-x  bug-audit-swarm.sh   (4116 bytes)
  -rwxr-xr-x  common.sh            (4312 bytes)
  -rwxr-xr-x  gt-tuner.sh          (1710 bytes — C3 artifact, preserved)
  -rw-r--r--  README.md            (5287 bytes)

yt-transition-shorts-detector/scripts/headless/
  -rwxr-xr-x  gt-tuner.sh          (4509 bytes — Phase C5)
```

---

## 5. Dry-Run: gt-tuner.sh

Command:
```bash
cd /Users/nick/Desktop/yt-transition-shorts-detector
bash scripts/headless/gt-tuner.sh --dry-run
```

Output:
```
[gt-tuner] DRY-RUN — planned invocation:
  claude -p 'Run /gt-tuner with config .gt-tuner/config.json' \
    --allowedTools 'Read,Grep,Glob,Bash(git *),Bash(node *),Bash(python3 *),Edit,Task' \
    --disallowedTools 'WebFetch,WebSearch' \
    --output-format stream-json \
    >> logs/gt-tuner-2026-04-18T00:43:26Z.jsonl
[gt-tuner] token_cap=2000000
[gt-tuner] timeout_sec=7200
[gt-tuner] sentinel=.gt-tuner/ABORT
```

---

## 6. Dry-Run: bug-audit-swarm.sh

Command:
```bash
bash ~/.claude/scripts/headless/bug-audit-swarm.sh --dry-run
```

Output:
```
[bug-audit-swarm] DRY-RUN — planned invocation:
  claude -p 'Run /bug-audit-swarm' \
    --allowedTools 'Read,Grep,Glob,Bash(git *),Bash(node *),Bash(bash reproductions/*),Edit,Task' \
    --disallowedTools 'WebFetch,WebSearch' \
    --output-format stream-json \
    >> logs/bug-audit-swarm-2026-04-18T00:43:56Z.jsonl
[bug-audit-swarm] token_cap=2000000
[bug-audit-swarm] timeout_sec=7200
[bug-audit-swarm] sentinel=.audit/ABORT
```

---

## 7. Soft-Stop Scenario

### 7a. watch_budget Isolation Test (no real claude invocation)

Demonstrates the OUTER budget loop directly:

```bash
# Pre-seeded log: input_tokens=80, output_tokens=40 → total=120 > cap=100
# watch_budget runs in background, polls every 5s
# SIGUSR1 sent to parent on trigger

--- Test 1: empty log (no tokens) ---
PASS: no false-positive sentinel on empty log

--- Test 2: 120 tokens > cap=100 ---
[INFO] soft_stop: token_cap_exceeded:120/100 → /tmp/tmp.9qqzKCr7SE/ABORT
PASS: sentinel written → {"soft_stop":"token_cap_exceeded:120/100","at":"2026-04-18T00:52:38Z"}
PASS: SIGUSR1 received (BUDGET_KILL=1)
```

**Exit path verified:** `if [[ $BUDGET_KILL -eq 1 ]] || [[ -f "$SENTINEL" ]]; then exit 3`

### 7b. Real Wrapper Run — CLAUDE_RUN_TOKEN_CAP=100

Command:
```bash
cd /Users/nick/Desktop/yt-transition-shorts-detector
CLAUDE_RUN_TOKEN_CAP=100 bash scripts/headless/gt-tuner.sh
```

The `/gt-tuner` skill does not exist yet (Phase C3 coordinator not shipped). Claude
ran, responded with skill-not-found messaging, and wrote stream-json to:
`logs/gt-tuner-2026-04-18T00:46:17Z.jsonl`

**Token fields captured in log:**
```
"input_tokens":12   (×1)
"input_tokens":6    (×5)
"output_tokens":0   (×2)
"output_tokens":286 (×1)
"output_tokens":538 (×1)
"output_tokens":8   (×2)
Total aggregated: 882 tokens > cap 100
```

**Wrapper stderr:**
```
[INFO] soft_stop: token_cap_exceeded:882/100_post_run → .gt-tuner/ABORT
[gt-tuner] budget exceeded — sentinel at .gt-tuner/ABORT
```

**Exit code:**
```
WRAPPER_EXIT_CODE=3
```

**Note:** The post-run budget check (inline, after `claude -p` exits) caught the
overrun. The background `watch_budget` polled before the log was fully written and
saw 0 tokens on its first cycle — as expected. The post-run check is the reliable
catch for fast-exiting runs.

**Sentinel content** (from real run):
```json
{"soft_stop":"token_cap_exceeded:882/100_post_run","at":"2026-04-18T00:46:17Z"}
```

---

## 8. Bug Fixed During Implementation

**Bug:** `pipefail` + `|| echo 0` double-output when grep finds no matches.

With `set -o pipefail`, a pipeline like:
```bash
grep ... | grep | awk ... || echo 0
```
When `grep` returns non-zero (empty log): `awk` still prints `0` (END block), pipeline
exit = grep's non-zero (pipefail), `|| echo 0` fires → variable gets `0\n0` → `((...))` 
fails with `syntax error in expression`.

**Fix applied to all three files:**
```bash
used=$(... | awk ... || true)
used="${used:-0}"
```

`|| true` suppresses the non-zero exit without adding output. `"${var:-0}"` handles
empty-string edge case.

---

## 9. Unresolved Questions

None blocking. The following are noted for Phase C6:

- `--allowedTools` path-scoped `Edit(path/*)` syntax is not documented in
  `headless.md`. Using unscoped `Edit` is conservative; tighten on first real run
  if needed.
- `watch_budget` sends `SIGUSR1` to the parent. If the parent is inside a blocking
  `wait`, the signal interrupts `wait` early — the `claude -p` process keeps running.
  For Phase C6 real campaigns, verify that the USR1 handler + post-run check produce
  the correct exit before the sentinel is consumed by the coordinator.
- Log rotation is tested via unit logic; a >50 MB dummy log scenario was not run.
  Add to Phase C6 smoke tests.
