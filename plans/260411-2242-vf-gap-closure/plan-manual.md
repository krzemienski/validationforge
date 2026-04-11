---
title: VF Gap Closure — Manual Protocol (Phases 4 + 5)
parent: plans/260411-2242-vf-gap-closure/plan.md
created: 2026-04-11
version: 2
---

# Manual-Gate Protocol — Phases 4 + 5

**These phases CANNOT be executed autonomously.** They require a fresh Claude Code session with the plugin installed. An autonomous runner that skips this file leaves B2, B3, B4, B5 OPEN.

Plan-level success in `plan.md` depends on evidence files produced here. The final `VERIFICATION.md` will FAIL if these are missing.

---

## Pre-requisites

- Phase 1 (commits) and Phase 3 (cleanup) have landed (autonomous)
- `git log --oneline` shows 6+ commits from this session
- Concurrent-session lock released: `! test -f .vf/.gap-closure.lock`
- User in a position to open a NEW Claude Code session (not this one)

---

## Phase 4 — Live hook enforcement test [B3, B4]

**Estimated time:** 1-2 hours
**Gates:** B3 (plugin load), B4 (hook enforcement)

### Step 0 — `~/.claude` snapshot (H10 red-team rollback)

```bash
# Snapshot user's ~/.claude BEFORE any install
BACKUP=/tmp/vf-pre-install-claude-$(date +%s).tgz
tar czf "$BACKUP" -C ~ .claude 2>&1 | tail -3
ls -lh "$BACKUP"
echo "BACKUP=$BACKUP"

# Also snapshot installed_plugins.json if present
cp ~/.claude/installed_plugins.json "$BACKUP.installed-plugins.json" 2>/dev/null || echo "no installed_plugins.json"
```

### Step 1 — Prepare scratch project (H11 red-team)

```bash
# Use ~/Desktop not /tmp (volatile)
SCRATCH=~/Desktop/vf-live-test-$(date +%s)
mkdir -p "$SCRATCH/src"
cd "$SCRATCH"
git init -q
cat > README.md <<'MD'
# VF Live Test Project
Minimal test fixture for validating ValidationForge plugin installation
and hook enforcement.
MD
cat > src/app.js <<'JS'
// Trivial source file - non-test, non-mock
console.log("hello world");
JS
git add .
git commit -qm "initial"
echo "SCRATCH=$SCRATCH"
```

### Step 2 — Install plugin (H10 Option B — symlink)

```bash
# Clean any existing VF install first
rm -f ~/.claude/plugins/validationforge 2>/dev/null
mkdir -p ~/.claude/plugins

# Symlink install (Option B — reversible)
ln -s /Users/nick/Desktop/validationforge ~/.claude/plugins/validationforge
ls -la ~/.claude/plugins/validationforge

# Register in installed_plugins.json (minimal — merge with existing)
python3 - <<'PY'
import json
from pathlib import Path
p = Path.home() / ".claude" / "installed_plugins.json"
data = {}
if p.exists():
    data = json.loads(p.read_text())
data.setdefault("plugins", {})
data["plugins"]["validationforge"] = {
    "source": "symlink",
    "path": "/Users/nick/Desktop/validationforge",
    "installed_at": "2026-04-11"
}
p.write_text(json.dumps(data, indent=2))
print("REGISTERED")
PY
```

### Step 3 — Open fresh Claude Code session

**Manual action:** Open a new Claude Code window. Navigate to `$SCRATCH`. You (the user) must perform the tests below interactively in the new session.

### Step 4 — Test protocol (run inside new CC session)

Execute these 4 tests, one by one, in the new session. Capture output into `plans/260411-2242-vf-gap-closure/live-session-evidence.md`.

#### Test 1: Plugin discovery

```
User (in new CC session): list the slash commands available in this session
Expected: Claude lists /validate, /vf-setup, /forge-*, /validate-*, etc.
Record: exact output including the command names
Mark: PASS if /validate and /vf-setup both appear, FAIL otherwise
```

#### Test 2: PreToolUse hook fires (block-test-files.js)

```
User: create a file named foo.test.ts with the content "test"
Expected: Claude is BLOCKED. The deny message from block-test-files.js appears:
  "BLOCKED: \"foo.test.ts\" matches a test/mock/stub file pattern.
   ValidationForge Iron Rule: Never create test files, mock files, or stub files.
   Instead: Build and run the real system. Validate through actual user interfaces."
Mark: PASS if Claude explicitly shows the BLOCKED message and does not create the file
     FAIL if the file is created OR no enforcement message appears
```

#### Test 3: PostToolUse hook fires (mock-detection.js)

```
User: edit src/app.js to add the line: const fs = jest.mock("fs");
Expected: A warning from mock-detection.js appears in session feedback:
  "[ValidationForge] mock-detection: Mock/test pattern detected in code being written.
   ValidationForge Iron Rule: Never create mocks, stubs, or test harnesses."
Mark: PASS if the warning appears, FAIL otherwise
     (Claude may still perform the edit — this is a warning, not a hard block)
```

#### Test 4: /vf-setup runs

```
User: /vf-setup --permissive
Expected: Command executes, creates ~/.claude/.vf-config.json, reports profile=permissive
Record: contents of ~/.claude/.vf-config.json
Mark: PASS if config file exists and contains "permissive", FAIL otherwise
```

### Step 5 — Write evidence file

```markdown
# Live CC Session Evidence (B3 + B4)

**Date:** 2026-04-XX
**Scratch project:** /Users/nick/Desktop/vf-live-test-<ts>
**Claude Code version:** <run `claude --version` in the new session>
**Backup tarball:** /tmp/vf-pre-install-claude-<ts>.tgz

## Test 1: Plugin discovery
- **Command:** list available slash commands
- **Result:** <PASS | FAIL>
- **Evidence (verbatim):**
  ```
  <paste output here>
  ```

## Test 2: PreToolUse block-test-files.js
- **Command:** create foo.test.ts with "test content"
- **Result:** <PASS | FAIL>
- **Evidence (verbatim):**
  ```
  <paste deny message and Claude's response here>
  ```

## Test 3: PostToolUse mock-detection.js
- **Command:** add jest.mock("fs") to src/app.js
- **Result:** <PASS | FAIL>
- **Evidence (verbatim):**
  ```
  <paste warning output here>
  ```

## Test 4: /vf-setup
- **Command:** /vf-setup --permissive
- **Result:** <PASS | FAIL>
- **Evidence (verbatim):**
  ```
  <paste Claude's output>
  ```
- **~/.claude/.vf-config.json contents:**
  ```json
  <paste the file contents>
  ```

## Summary
- Total PASS: <N>/4
- B3 (plugin load): <PASS if Test 1 PASS else FAIL>
- B4 (hook enforcement): <PASS if Test 2 PASS AND Test 3 PASS else FAIL>

## Cleanup status
- [ ] Plugin symlink removed: `rm ~/.claude/plugins/validationforge`
- [ ] Config restored or left in place: `~/.claude/.vf-config.json`
- [ ] Scratch dir kept for Phase 5 OR removed: `rm -rf $SCRATCH`
```

### Step 6 — Verify evidence file (checker script)

Create `plans/260411-2242-vf-gap-closure/verify-live-session-evidence.py`:

```python
#!/usr/bin/env python3
"""Checker for live-session-evidence.md — M11 red-team"""
import sys
from pathlib import Path

p = Path("plans/260411-2242-vf-gap-closure/live-session-evidence.md")
if not p.exists():
    print("FAIL: evidence file missing")
    sys.exit(1)

s = p.read_text()
checks = {
    "Test 1 PASS marker": "Result:** PASS" in s or "Result: PASS" in s,
    "Test 2 deny message": "permissionDecision" in s or "BLOCKED" in s,
    "Test 3 warning": "mock-detection" in s.lower() or "Iron Rule" in s,
    "Test 4 config file": ".vf-config.json" in s,
    "Min 4 PASS markers": s.count("PASS") >= 4,
}
failed = [k for k, v in checks.items() if not v]
if failed:
    print("FAIL:", failed)
    sys.exit(1)
print("LIVE_SESSION_EVIDENCE_OK")
```

Run it:

```bash
python3 plans/260411-2242-vf-gap-closure/verify-live-session-evidence.py
```

### Step 7 — Rollback (if needed)

```bash
# Restore ~/.claude from snapshot
BACKUP=/tmp/vf-pre-install-claude-<ts>.tgz
rm -rf ~/.claude
tar xzf "$BACKUP" -C ~
rm -rf "$SCRATCH"
```

**Exit for Phase 4:**
- `python3 plans/260411-2242-vf-gap-closure/verify-live-session-evidence.py` exits 0
- Evidence file has ≥ 4 PASS markers
- B3 marker present
- B4 marker present

---

## Phase 5 — First real /validate run [B2, B5, M2]

**Estimated time:** 2 hours

### Step 1 — Pick targets (H12, H13 red-team)

Phase 5 requires **≥ 3 platform targets** to validate M2 (multi-platform detection).

| # | Target | Path | Expected platform |
|---|--------|------|-------------------|
| 1 | demo/python-api | `/Users/nick/Desktop/validationforge/demo/python-api/` | api |
| 2 | site (if exists) OR minimal scaffold | `/Users/nick/Desktop/validationforge/site/` or scaffold | web |
| 3 | CLI (bin/vf.js itself) | `/Users/nick/Desktop/validationforge/bin/` or scaffold | cli |
| 4 | **External repo (H12)** | PRE-NAMED by user before Phase 5 | varies |

**STOP POINT:** Before running Phase 5, name the external target repo in `plans/260411-2242-vf-gap-closure/phase-5-targets.md`. Candidates:
- A small local TypeScript CLI (e.g. a previous side project)
- A public open-source repo cloned fresh to a scratch dir
- Explicit decision: "external target deferred to next plan because …"

### Step 2 — Run /validate against each target (inside live CC session)

For each target, in a Claude Code session:

```
User: cd <target>
User: /validate
```

Capture:
- Phase outputs (research → plan → preflight → execute → analyze → verdict)
- Platform detection result
- Which hooks fired during the run
- Final verdict (PASS/FAIL per journey)
- Evidence directory populated (`ls e2e-evidence/`)

### Step 3 — Write evidence files

For each target, create `plans/260411-2242-vf-gap-closure/first-real-run-<target>.md`:

```markdown
# First Real /validate Run — <target name>

**Target:** <path>
**Date:** 2026-04-XX
**CC session:** <id>
**Platform detected:** <result>

## Phase outputs
### Research
<paste or summarize>

### Plan
<paste>

### Preflight
<paste>

### Execute
<paste journey-by-journey output>

### Analyze
<paste>

### Verdict
- Journey 1: <PASS|FAIL> — <evidence>
- Journey 2: <PASS|FAIL> — <evidence>
...

## Hooks observed firing
- [ ] block-test-files: <fired? on what action?>
- [ ] mock-detection: <fired?>
- [ ] evidence-quality-check: <fired?>
- [ ] completion-claim-validator: <fired?>
- [ ] validation-state-tracker: <fired?>

## Evidence directory
```bash
ls -la e2e-evidence/
```
<paste>

## Outcome
- Did /validate produce a verdict? <YES|NO>
- Evidence dir populated? <YES|NO>
- Subjective quality: <useful | partially useful | unusable>
- Bugs encountered: <list>
```

Write one file per target. At minimum, `first-real-run-demo-python-api.md` must exist.

### Step 4 — Aggregate into first-real-run.md

```markdown
# First Real /validate Runs — Summary

**Date:** 2026-04-XX
**Total targets:** <N>
**Files:** first-real-run-<target>.md × N

## Results
| Target | Platform | Verdict | Notes |
|--------|----------|---------|-------|
| demo/python-api | <detected> | <PASS|FAIL> | ... |
| site (web) | <detected> | <PASS|FAIL> | ... |
| bin (cli) | <detected> | <PASS|FAIL> | ... |
| <external> | <detected> | <PASS|FAIL> | ... |

## B2 closure
- Primary target: <target name>
- Verdict: <PASS|FAIL>

## M2 closure (platform detection)
- API detected correctly: <YES|NO>
- Web detected correctly: <YES|NO>
- CLI detected correctly: <YES|NO>
- External detected correctly: <YES|NO>
```

### Step 5 — B5 demo GIF disposition (M12 red-team)

```bash
# Inspect metadata
ls -la demo/vf-demo.gif
file demo/vf-demo.gif
ffprobe demo/vf-demo.gif 2>&1 | grep -E 'Duration|fps'

# Human action: open + watch end-to-end
```

Create `plans/260411-2242-vf-gap-closure/demo-gif-disposition.md`:

```markdown
# Demo GIF Disposition (B5)

**File:** demo/vf-demo.gif
**Inspected:** 2026-04-XX

## Metadata
- Size: <bytes>
- Duration: <sec from ffprobe>
- Frame count: <from ffprobe>
- Dimensions: <WxH>

## Content review
**Frame descriptions (at least 3 frames):**
1. Frame 5 (t=0.5s): <what you see>
2. Frame 30 (t=3s): <what you see>
3. Frame 60 (t=6s): <what you see>

## Decision
- [ ] KEEP — shows real /validate run catching a real bug
- [ ] RE-RECORD — shows stub / placeholder content (separate plan)
- [ ] MISSING — file not present (different scope issue)

**Rationale:** <why>
```

### Step 6 — Exit gate

```bash
# Check all Phase 5 artifacts exist
test -f plans/260411-2242-vf-gap-closure/first-real-run.md || exit 1
test -f plans/260411-2242-vf-gap-closure/first-real-run-demo-python-api.md || exit 1
test -f plans/260411-2242-vf-gap-closure/demo-gif-disposition.md || exit 1
test -f plans/260411-2242-vf-gap-closure/phase-5-targets.md || exit 1

# Verify first-real-run.md has verdict
grep -q '## Results' plans/260411-2242-vf-gap-closure/first-real-run.md || exit 1

echo "PHASE_5_EXIT_OK"
```

---

## Returning to autonomous execution

After Phases 4 and 5 complete:
1. Close the manual-test Claude Code session
2. Uninstall the plugin: `rm ~/.claude/plugins/validationforge`
3. Reduce `~/.claude/installed_plugins.json` via backup or manual edit
4. Return to main CC session, resume Phase 2 (docs)
5. Update `plans/260411-2242-vf-gap-closure/progress.md` marking Phase 4 and 5 complete

Phase 2 uses evidence from Phase 4+5 to write the README "Verification Status" table (M7).

---

## Cleanup protocol (after Phase 5)

```bash
# Cleanup scratch + test install
rm -rf ~/Desktop/vf-live-test-*
rm -f ~/.claude/plugins/validationforge

# Restore or leave ~/.claude/.vf-config.json?
# Decision: KEEP the config if it was created by a real /vf-setup run,
# REMOVE if it was clobbered from snapshot.

# Evidence files under plans/.../ are kept — they're the whole point
```
