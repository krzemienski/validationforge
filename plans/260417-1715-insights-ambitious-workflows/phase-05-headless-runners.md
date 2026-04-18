# Phase 5 — Headless Runners

## 1. Context Links

- Parent plan: `/Users/nick/Desktop/validationforge/plans/260417-1715-insights-ambitious-workflows/plan.md`
- Upstream Phase 3: GT Tuner coordinator
- Upstream Phase 4: Bug-Audit Swarm coordinator
- Refs:
  - `~/.claude/plugins/cache/superpowers-marketplace/superpowers-developing-for-claude-code/0.3.1/skills/working-with-claude-code/references/headless.md` — `claude -p`, `--allowedTools`, `--output-format`
  - `~/.claude/rules/orchestration-protocol.md`
  - `~/.claude/rules/security.md` (tool whitelist discipline)

## 2. Overview

- **Priority:** P2
- **Status:** pending (Phases 3 + 4 required)
- **Description:** Shell wrappers that drive the GT Tuner and Bug-Audit Swarm coordinators in non-interactive mode via `claude -p`, with strict `--allowedTools` whitelists, bounded iteration counts, token-budget caps, structured JSONL logging, and soft-stop-on-budget behavior. A shared `common.sh` holds the flags, timeouts, log rotation, and error handling.

## 3. Key Insights

- Per `headless.md`, `--allowedTools` takes a comma-separated list and rejects unlisted tools — this is our primary defense against runaway subagents making arbitrary bash calls.
- `--output-format json` yields structured per-turn records we can parse for token counts and status. JSONL per run is the format of record.
- Coordinators from Phases 3/4 already honor `ABORT` sentinels and checkpoint on every turn — the headless wrapper adds an OUTER budget layer (wall-clock timeout, token cap) that complements the inner loop bounds.
- Soft-stop semantics: when budget is hit, the wrapper writes an ABORT sentinel (not SIGKILL) so the coordinator drains + checkpoints before exit.
- Log rotation is important — a long campaign's JSONL can reach hundreds of MB; rotate at 50MB per file.

## 4. Requirements

### Functional
- F1: `gt-tuner.sh` wraps the GT Tuner coordinator; invokes `claude -p` with GT-specific whitelist.
- F2: `bug-audit-swarm.sh` wraps the Swarm coordinator; invokes `claude -p` with Swarm-specific whitelist.
- F3: `common.sh` provides: `parse_flags`, `enforce_budget`, `rotate_log`, `soft_stop`, `timestamp_iso`.
- F4: Per-run log at `<repo>/logs/<runner>-<iso-timestamp>.jsonl`.
- F5: Token budget passed via `--max-tokens <N>` flag or `CLAUDE_RUN_TOKEN_CAP` env var. When exceeded, write ABORT sentinel and exit 3 (budget-exceeded).
- F6: Wall-clock timeout via `--timeout <sec>` (default 2 hours).
- F7: Exit codes: 0=success, 1=coordinator error, 2=setup error, 3=budget exceeded, 4=wall-clock timeout, 5=user abort.
- F8: `--dry-run` flag prints planned command without invoking Claude.

### Non-functional / Safety
- NF1: `--allowedTools` lists are FIXED in each wrapper — never user-overridable from the shell.
- NF2: `--disallowedTools` MUST include `WebFetch` and `WebSearch` to prevent network egress from a rogue subagent.
- NF3: Scripts fail fast on missing prerequisites (`claude` binary, `node`, `jq`).
- NF4: `set -euo pipefail` and `IFS=$'\n\t'` at top of every shell file.
- NF5: No `eval`, no word-splitting of variables.

## 5. Architecture

### Allowed tool whitelists

**GT Tuner (`gt-tuner.sh`):**
- `Read,Grep,Glob,Bash(git:*),Bash(node:*),Bash(python3:*),Edit(scripts/gt-tuner/*),Edit(.gt-tuner/*),Edit(~/.claude/state/campaigns/gt/*),Task`
- Rationale: runs regression via `python3`, manages worktrees via `git`, dispatches subagents via `Task`, writes state files. No unscoped `Bash`.
- `--disallowedTools WebFetch,WebSearch`

**Bug-Audit Swarm (`bug-audit-swarm.sh`):**
- `Read,Grep,Glob,Bash(git:*),Bash(node:*),Bash(bash:reproductions/*),Edit(reproductions/*),Edit(.audit/*),Edit(~/.claude/state/campaigns/audit/*),Task`
- Rationale: runs reproduction scripts via bounded `bash`, manages branches via `git`, dispatches roles via `Task`.
- `--disallowedTools WebFetch,WebSearch`

> Per `headless.md`, tool argument patterns supported by `--allowedTools` vary; authors MUST re-verify the exact syntax (e.g. `Bash(git *)` vs `Bash:git`) at implementation time. Placeholder syntax above is illustrative — resolve via the reference before shipping.

### common.sh shape (sketch)
```bash
# ~/.claude/scripts/headless/common.sh
set -euo pipefail
IFS=$'\n\t'

MAX_LOG_BYTES="${MAX_LOG_BYTES:-$((50*1024*1024))}"
DEFAULT_TIMEOUT_SEC="${DEFAULT_TIMEOUT_SEC:-7200}"

require_bin() {
  for b in "$@"; do command -v "$b" >/dev/null || { echo "missing $b" >&2; exit 2; }; done
}

timestamp_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

rotate_log() {
  local f="$1"; [[ ! -f "$f" ]] && return 0
  local sz; sz=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f")
  (( sz < MAX_LOG_BYTES )) && return 0
  mv "$f" "${f%.jsonl}-$(timestamp_iso).jsonl"
}

soft_stop() {
  local sentinel="$1"; local reason="$2"
  echo "{\"soft_stop\":\"$reason\",\"at\":\"$(timestamp_iso)\"}" > "$sentinel"
}

parse_budget() {
  # echoes normalized token_cap + timeout via env vars
  export TOKEN_CAP="${CLAUDE_RUN_TOKEN_CAP:-${TOKEN_CAP_ARG:-2000000}}"
  export TIMEOUT_SEC="${TIMEOUT_ARG:-$DEFAULT_TIMEOUT_SEC}"
}

watch_budget() {
  # Polls log file for cumulative token usage; writes ABORT sentinel when exceeded.
  local log="$1"; local sentinel="$2"; local cap="$3"
  while sleep 10; do
    [[ ! -f "$log" ]] && continue
    local used; used=$(jq -s 'map(.usage.total_tokens // 0) | add' "$log" 2>/dev/null || echo 0)
    if (( used >= cap )); then
      soft_stop "$sentinel" "token_cap_exceeded:$used/$cap"
      exit 3
    fi
  done
}
```

### gt-tuner.sh shape (sketch)
```bash
#!/usr/bin/env bash
source "$(dirname "$0")/../common.sh"
require_bin claude node jq git python3

CAMPAIGN_CONFIG=".gt-tuner/config.json"
SENTINEL=".gt-tuner/ABORT"
LOG_DIR="logs"; mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/gt-tuner-$(timestamp_iso).jsonl"
rotate_log "$LOG"

parse_budget
watch_budget "$LOG" "$SENTINEL" "$TOKEN_CAP" &
WATCH_PID=$!
trap 'kill $WATCH_PID 2>/dev/null || true; [[ -f "$SENTINEL" ]] || true' EXIT

timeout --signal=TERM --kill-after=30s "$TIMEOUT_SEC" \
  claude -p "Run /gt-tuner with config $CAMPAIGN_CONFIG" \
    --allowedTools 'Read,Grep,Glob,Bash(git:*),Bash(node:*),Bash(python3:*),Edit,Task' \
    --disallowedTools 'WebFetch,WebSearch' \
    --output-format json \
    >> "$LOG"

rc=$?
case $rc in
  0)   echo "OK"; exit 0 ;;
  124) soft_stop "$SENTINEL" "wall_clock"; exit 4 ;;
  *)   exit 1 ;;
esac
```

### bug-audit-swarm.sh — same shape with swarm whitelist.

### JSONL record shape expected per turn
```
{"ts":"...","role":"coordinator|scout|fixer|reviewer","status":"DONE|BLOCKED|...","usage":{"total_tokens":N}}
```
Wrappers parse via `jq`; do not assume Claude emits exactly this — document that the parser is tolerant of missing `usage` fields.

## 6. Related Code Files

**CREATE:**
- `/Users/nick/.claude/scripts/headless/common.sh`
- `/Users/nick/.claude/scripts/headless/bug-audit-swarm.sh`
- `/Users/nick/Desktop/yt-transition-shorts-detector/scripts/headless/gt-tuner.sh`
- `/Users/nick/.claude/scripts/headless/README.md` (usage, budget flags, exit codes table)

**MODIFY:**
- `/Users/nick/Desktop/yt-transition-shorts-detector/.gitignore` — ignore `logs/`
- `/Users/nick/.claude/scripts/headless/.gitignore` (if under version-managed tree) — ignore `logs/`

**DELETE:** none.

## 7. Implementation Steps

1. Re-read `headless.md` authoritative reference. Confirm exact `--allowedTools` argument grammar. Document any deviation.
2. Write `common.sh`; smoke-run `require_bin` + `rotate_log` against a tmp file to verify behavior.
3. Write `gt-tuner.sh`; run `--dry-run` to print planned command, eyeball whitelist.
4. Write `bug-audit-swarm.sh` mirroring.
5. Write `README.md` with: flags table, exit-code table, budget override env vars, kill-switch procedure, log-rotation policy.
6. For Phase 6: capture one real run's JSONL tail + one soft-stop scenario (artificially low token cap).

### Safety gates
- Step 1 is non-negotiable — the `--allowedTools` syntax is authoritative-only; never guess. If `headless.md` is ambiguous, cross-reference against a real `claude --help` output before shipping.
- Step 3/4 whitelists MUST NOT include bare `Bash` — only scoped `Bash(...)` patterns.
- `--disallowedTools WebFetch,WebSearch` is mandatory in both wrappers.

## 8. Todo List

- [ ] Re-read `headless.md`; confirm argument grammar
- [ ] Write `common.sh` with budget + log-rotation + soft-stop
- [ ] Write `gt-tuner.sh` with GT whitelist
- [ ] Write `bug-audit-swarm.sh` with Swarm whitelist
- [ ] Write `README.md` with flags/exit-codes/kill-switch
- [ ] Smoke `--dry-run` for each wrapper
- [ ] Phase 6 soft-stop scenario prep (artificially low token cap)

## 9. Success Criteria

- `./gt-tuner.sh --dry-run` prints the exact `claude -p` invocation including `--allowedTools` and `--disallowedTools` — captured as evidence.
- Soft-stop scenario: set `CLAUDE_RUN_TOKEN_CAP=100` (tiny) → wrapper writes ABORT sentinel within ~20s, coordinator exits cleanly, wrapper exits 3. Evidence = sentinel content + log tail.
- Wall-clock timeout scenario: set `--timeout 30` → wrapper SIGTERMs after 30s + 30s grace, exits 4. Evidence = exit code + timestamp.
- Log rotation: create a >50MB dummy log, run wrapper, observe rotated filename. Evidence = `ls -la logs/`.
- No rogue bash: attempt `Bash(curl ...)` from inside the session — rejected by `--allowedTools`. Evidence = Claude's refusal in JSONL output.

## 10. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| `--allowedTools` syntax differs from `headless.md` examples | Medium | High | Step 1 gate — verify against live `claude --help` before shipping. |
| Token accounting unreliable from JSONL `usage` field | Medium | High | Document tolerance; augment with wall-clock timeout as fallback bound. |
| `timeout` command differs on macOS vs Linux (`gtimeout` on mac without coreutils) | High | Medium | `require_bin timeout`; document `brew install coreutils` or use `--timeout` inside Claude if available. |
| Soft-stop race — coordinator doesn't notice sentinel | Low | Medium | Coordinator polls sentinel every turn (per Phases 3/4); additionally wrapper escalates to SIGTERM after grace. |
| Log file disk fill | Medium | Medium | 50MB rotation; `.gitignore` entry prevents commit; document manual prune. |
| Background `watch_budget` orphaned | Low | Low | `trap '... kill $WATCH_PID' EXIT` in wrappers. |
| Whitelist drifts from coordinator actual needs | Medium | Medium (run fails loudly) | Per-turn JSONL captures refused-tool events; triage and update whitelist on first real run. |

## 11. Security Considerations

- **Primary defense**: `--allowedTools` whitelist is the authority. Every scope is explicit. No bare `Bash`. No `WebFetch`/`WebSearch`.
- **Secondary defense**: coordinators themselves run inside the Root-Cause Enforcer hook (Phase 2) — even if a subagent tries to Edit `src/`, the enforcer gates it.
- **No user input interpolation into shell**: all CLI args normalized via shell built-ins; no `eval`, no `$(user_input)`.
- **No secrets in logs**: JSONL logs may capture tool inputs — document that users must `.gitignore logs/` and must not paste credentials into prompts driving these runners.
- **Budget as safety**: token cap + wall-clock are BOTH hard limits — a runaway agent cannot burn unbounded tokens even if coordinator logic bugs out.
- `require_bin` fails fast on missing binaries rather than falling back to `sh` improvisation.

## 12. Next Steps

Phase 6 exercises all three workflows end-to-end with real evidence captured via these wrappers.
