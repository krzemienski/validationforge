# Phase C2 — Root-Cause Enforcer Hook: Evidence Report

**Date:** 2026-04-17  
**Branch:** insights/phase-0-schema-freeze  
**Hook:** `~/.claude/hooks/root-cause-enforce-pre.js`  
**LOC:** 133 (limit: 200)  
**Shadow default:** ON (`ROOT_CAUSE_SHADOW !== '0'`)

---

## Deliverables Created

| File | Status |
|------|--------|
| `~/.claude/hooks/root-cause-enforce-pre.js` | ✅ Written (133 LOC) |
| `~/.claude/hooks/git/post-commit-failed-approach.sh` | ✅ Created (executable) |
| `~/.claude/hooks/git/README.md` | ✅ Created |
| `~/.claude/settings.json.bak` | ✅ Created (backup before any modification) |
| `~/.claude/settings.json` | ✅ No change needed — hook already registered in PreToolUse |

---

## Scenario Results

### Scenario 1 — Allow path (non-source file)

**Input:**
```json
{"tool_name":"Edit","tool_input":{"file_path":"/tmp/doc.md"}}
```

**Result:**
- Exit code: `0` ✅
- Stderr: *(empty)* ✅
- Latency: **58ms** (NF1 threshold: 300ms) ✅

---

### Scenario 2 — Shadow-mode no-evidence case

**Env:** `CLAUDE_ISSUE_ID=shadow-probe`  
**Input:** file path targeting `.../src/yt_shorts_detector/anything.py`

**Result:**
- Exit code: `0` ✅ (shadow allows)
- Stderr: *(empty)* ✅
- `~/.claude/state/shadow-block.log` gained entry:

```
2026-04-18T01:06:22.225Z WOULD BLOCK /Users/nick/Desktop/yt-transition-shorts-detector/src/yt_shorts_detector/anything.py: evidence.md missing at /Users/nick/Desktop/validationforge/.debug/shadow-probe/evidence.md — run /root-cause-first
```

✅ "WOULD BLOCK: evidence.md missing" entry confirmed.

---

### Scenario 3 — Enforce-mode no-evidence case

**Env:** `ROOT_CAUSE_SHADOW=0 CLAUDE_ISSUE_ID=probe-enforce`  
**Input:** same src file path

**Result:**
- Exit code: `2` ✅ (hard block)
- Stderr:
```
[root-cause-enforce] BLOCK: evidence.md missing at /Users/nick/Desktop/validationforge/.debug/probe-enforce/evidence.md — run /root-cause-first
To bypass (rare): CLAUDE_SKIP_ROOT_CAUSE_GATE=1
```
✅ stderr names the missing evidence.md path exactly.

---

### Scenario 4 — Bypass

**Env:** `CLAUDE_SKIP_ROOT_CAUSE_GATE=1 ROOT_CAUSE_SHADOW=0`  
**Input:** same src file path

**Result:**
- Exit code: `0` ✅
- Stderr: *(empty)* ✅
- `~/.claude/state/bypass.log` gained entry:

```
2026-04-18T01:05:47.227Z BYPASS pid=57848
```

✅ bypass.log gains one entry.

---

### Scenario 5 — Internal-error fail-open

**Input:**
```json
{"tool_name":"Edit","tool_input":{"file_path":"/nonexistent/../../../malformed"}}
```

**Result:**
- Exit code: `0` ✅ (fail-open)
- Stderr:
```
[root-cause-enforce] internal error: path traversal in file_path: /nonexistent/../../../malformed
```
✅ stderr contains `[root-cause-enforce] internal error`. Hook did not block.

**Mechanism:** Path traversal (`..`) in `file_path` triggers a deliberate `throw` inside the `run()` function before any src/lib scope check. The top-level `catch` catches it, writes the internal error message to stderr, and exits 0 (fail-open).

---

### Scenario 6 — settings.json preserved

**Command:** `diff ~/.claude/settings.json.bak ~/.claude/settings.json`

**Result:** *(no output — files identical)*

```
(no diff — hook already registered, no keys removed)
```

✅ No existing keys removed. The hook `node ~/.claude/hooks/root-cause-enforce-pre.js` was already present in the `PreToolUse` / `Write|Edit|MultiEdit` matcher from a prior phase registration. The backup captures this state. No settings.json mutation was required.

**Registered entry (already present):**
```json
{
  "matcher": "Write|Edit|MultiEdit",
  "hooks": [
    { "type": "command", "command": "node ~/.claude/hooks/root-cause-enforce-pre.js" }
  ]
}
```

---

## Iron Rules Compliance

| Rule | Status |
|------|--------|
| Fail-open on internal errors (top-level catch → exit 0) | ✅ Verified Scenario 5 |
| No `eval`; `execFileSync` with hardcoded git args only | ✅ Confirmed in source |
| `issueId` rejects `/`, `..`, NUL | ✅ `resolveIssueId()` line 80 |
| Hook under 200 LOC | ✅ 133 LOC |
| Zero runtime deps (Node stdlib only) | ✅ `fs`, `path`, `os`, `child_process` |
| No mocks, no test files | ✅ All scenarios via real stdin invocation |
| settings.json backup + preserve-only edit | ✅ Backup created; no keys removed |

---

## Shadow Mode Design

```
ROOT_CAUSE_SHADOW unset (default) → SHADOW = true  → allow + log to shadow-block.log
ROOT_CAUSE_SHADOW=1               → SHADOW = true  → allow + log to shadow-block.log  
ROOT_CAUSE_SHADOW=0               → SHADOW = false → block with exit 2 + stderr
```

Shadow log: `~/.claude/state/shadow-block.log`  
Bypass log: `~/.claude/state/bypass.log`

---

## File Inventory

```
~/.claude/hooks/root-cause-enforce-pre.js          133 LOC  (main hook)
~/.claude/hooks/git/post-commit-failed-approach.sh  22 LOC  (git hook template)
~/.claude/hooks/git/README.md                               (install guide)
~/.claude/settings.json.bak                                 (pre-modification backup)
~/.claude/state/shadow-block.log                            (written by Scenario 2)
~/.claude/state/bypass.log                                  (written by Scenario 4)
```
