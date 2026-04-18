# MEGA-PROMPT — Implement Insights Plans A/B/C (Post-Red-Team Revision)

**Version:** 1.0
**Date:** 2026-04-17 17:45
**Authoritative source.** This document supersedes the individual plan.md + phase files for execution. The phase files remain as the audit trail.
**Input plans:**
- `plans/260417-1715-insights-foundation/plan.md` (Plan A — APPROVE_WITH_CHANGES)
- `plans/260417-1715-insights-skills-layer/plan.md` (Plan B — REJECT → pivoted)
- `plans/260417-1715-insights-ambitious-workflows/plan.md` (Plan C — REJECT → safety-added)
**Red-team consolidated:** `plans/reports/red-team-consolidated-260417-1745-insights-plans.md`

---

<mock_detection_protocol>
Before executing ANY task below, check intent:
- Creating `.test.*`, `_test.*`, `*Tests.*`, `test_*`, `*.spec.*` files → STOP
- Importing mock libraries (jest.mock, sinon, nock, unittest.mock, pytest-mock) → STOP
- Creating in-memory databases (SQLite :memory:, H2, fakeredis) → STOP
- Adding TEST_MODE, NODE_ENV=test, or CI-only code paths to bypass real behavior → STOP
- Rendering components in isolation (Testing Library, Storybook, React Test Renderer) → STOP
- Seeding synthetic bugs to validate `/evidence-gate` — use an ACTUALLY OPEN bug → STOP
Fix the REAL system instead. Invoke real hooks, install real skills, run real campaigns. No exceptions.
</mock_detection_protocol>

---

## §0 EXECUTION CONTRACT

### Invariants (violating any → abort)
1. **No unit tests, no mocks, no test doubles.** Functional validation only. Real hooks fire on real edits. Real skills invoked via `/name` against real scenarios. No `*.test.*` or `*.spec.*` in `src/`/`lib/`.
2. **Evidence before completion.** Every phase-done claim cites a file path + quoted evidence line. `plans/{plan-dir}/reports/` is the evidence root.
3. **One fix at a time.** Edits touching >3 unrelated files or >2 distinct function signatures require explicit justification in the commit body.
4. **Extend, don't duplicate.** Before creating any new skill/rule/hook, `Grep` existing surfaces. If >60% overlap with an incumbent, modify in place.
5. **Bounded runs.** Every headless invocation carries a max-iterations, max-wall-clock, and max-tokens cap. Exceeding any → soft-stop + checkpoint.
6. **Schema versioning.** Any JSON schema change requires `schemaVersion` bump + migration note.

### Failure semantics
- **Hard stop** on Phase 0 failure. All subsequent phases blocked.
- **Soft stop + checkpoint** on Phase N failure within a plan. Plan halts; siblings continue.
- **Rollback** via git branch isolation. Every phase runs on its own branch `insights/plan-{a|b|c}/phase-{n}-{slug}`.

### Budget ceilings
| Plan | Tokens | Wall-clock | Subagents |
|------|--------|-----------|-----------|
| Plan A | 500K | 2h | 0 (no spawn) |
| Plan B | 2.5M (full: 900 description-opt runs) | 4h | 54 in Phase B4 iteration-1 |
| Plan C | 3.5M (full: all 3 workflows validated) | 6h | 8 parallel in Phase C3 |
| Phase 0 | 200K | 30min | 0 |
| **Total** | **6.7M** | **~12h, split** | — |

### Kill switches
- `INSIGHTS_MEGA_ABORT=1` → headless runner stops after current phase, writes checkpoint.
- `ROOT_CAUSE_SHADOW=1` → Plan C Phase C2 enforcer logs but doesn't block (default first 7 days).
- `SKIP_TS_CHECK=1` → Plan A syntax-check hook skips TypeScript (default ON).
- `INSIGHTS_DRY_RUN=1` → write to `/tmp/insights-dry-run/` instead of live paths.

---

## §1 PRE-EXECUTION CHECKLIST

Before Phase 0, verify:
```bash
# Repo state
cd /Users/nick/Desktop/validationforge && git status --short
# Detector state
cd /Users/nick/Desktop/yt-transition-shorts-detector && git status --short

# Tool availability
command -v python3 && python3 -c "import ast; print('ast OK')"
command -v node && node --version
command -v jq && jq --version
command -v claude && claude --version

# Existing surfaces (DO NOT overwrite)
ls ~/.claude/rules/instrument-before-theorize.md
ls ~/.claude/rules/ocr-debug-protocol.md
ls /Users/nick/Desktop/yt-transition-shorts-detector/.claude/skills/fix-detection/SKILL.md
ls /Users/nick/Desktop/yt-transition-shorts-detector/.claude/skills/audit/SKILL.md
```

If any command fails → stop. Report missing dependency.

Confirm decisions (from validation interview 2026-04-17):
- [x] Plan B pivot: only `/evidence-gate` new skill; cancel `/gt-perfect` + `/audit` (new); modify `fix-detection` in place
- [x] Plan A C1 fix: `ast.parse` not `py_compile`; defer TS entirely
- [x] Plan C safety: shadow-mode enforcer 7 days; `env -i` + allowlist in headless runners
- [x] Budget: full everywhere (Plan B 900 runs; Plan C all 3 workflows, split across 3 sessions)

---

## §2 PHASE 0 — SCHEMA FREEZE + PIVOT BUNDLE

**Blocks all subsequent phases across all plans.**

### 0.1 Freeze shared schema (Plan A owns; Plan C consumes)
**Create** `~/.claude/state/schemas/debug-checkpoint.schema.json`:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://claude.local/schemas/debug-checkpoint/1.0.json",
  "title": "DebugCheckpoint",
  "type": "object",
  "required": ["schemaVersion", "campaignId", "targetRepo", "hypotheses", "fixesAttempted", "currentState", "lastUpdated"],
  "properties": {
    "schemaVersion": { "const": "1.0" },
    "campaignId": { "type": "string", "pattern": "^[a-f0-9]{12}$" },
    "targetRepo": { "type": "string" },
    "targetFile": { "type": "string" },
    "hypotheses": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "statement", "evidencePath", "result"],
        "properties": {
          "id": { "type": "string" },
          "statement": { "type": "string" },
          "evidencePath": { "type": "string" },
          "result": { "enum": ["pending", "confirmed", "rejected"] }
        }
      }
    },
    "fixesAttempted": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "diffSha", "outcome"],
        "properties": {
          "id": { "type": "string" },
          "diffSha": { "type": "string" },
          "outcome": { "enum": ["pending", "passed", "failed", "reverted"] }
        }
      }
    },
    "currentState": { "type": "string" },
    "lastUpdated": { "type": "string", "format": "date-time" }
  }
}
```

**Create** `~/.claude/state/schemas/audit-campaign.schema.json`:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://claude.local/schemas/audit-campaign/1.0.json",
  "title": "AuditCampaign",
  "type": "object",
  "required": ["schemaVersion", "campaignId", "targetRepo", "bugs", "currentPhase", "lastUpdated"],
  "properties": {
    "schemaVersion": { "const": "1.0" },
    "campaignId": { "type": "string", "pattern": "^[0-9]{13}-[a-f0-9]{6}$" },
    "targetRepo": { "type": "string" },
    "bugs": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "reproPath", "status"],
        "properties": {
          "id": { "type": "string" },
          "reproPath": { "type": "string", "description": "Real reproduction artifact (CLI invocation script or HTTP request file), NOT a test file" },
          "fixerAttempts": { "type": "integer", "maximum": 5 },
          "reviewerVerdict": { "enum": ["pending", "approved", "rejected"] },
          "status": { "enum": ["scouted", "in-fix", "reviewed", "merged", "failed"] }
        }
      }
    },
    "currentPhase": { "enum": ["scout", "fix", "review", "complete"] },
    "lastUpdated": { "type": "string", "format": "date-time" }
  }
}
```

**Create** `~/.claude/state/schemas/gt-campaign.schema.json`:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://claude.local/schemas/gt-campaign/1.0.json",
  "title": "GtCampaign",
  "type": "object",
  "required": ["schemaVersion", "campaignId", "targetRepo", "iterations", "baselineScore", "currentScore", "lastUpdated"],
  "properties": {
    "schemaVersion": { "const": "1.0" },
    "campaignId": { "type": "string", "pattern": "^[0-9]{13}-[a-f0-9]{6}$" },
    "targetRepo": { "type": "string" },
    "baselineScore": { "type": "string", "description": "e.g. '7/8' at campaign start" },
    "currentScore": { "type": "string" },
    "maxIterations": { "type": "integer", "default": 20 },
    "iterations": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["n", "proposedFixes", "mergedFix"],
        "properties": {
          "n": { "type": "integer" },
          "proposedFixes": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["videoId", "rootCause", "fixDiff", "expectedDelta", "risk", "regressionResult"],
              "properties": {
                "videoId": { "type": "string" },
                "rootCause": { "type": "string" },
                "fixDiff": { "type": "string", "description": "Path to diff file" },
                "expectedDelta": { "type": "string" },
                "risk": { "enum": ["low", "medium", "high"] },
                "regressionResult": { "enum": ["pending", "net-improve", "net-regress", "flat"] }
              }
            }
          },
          "mergedFix": { "type": ["string", "null"], "description": "videoId of merged fix, or null if iteration yielded no merge" }
        }
      }
    },
    "lastUpdated": { "type": "string", "format": "date-time" }
  }
}
```

<validation_gate id="VG-0.1" blocking="true">
  <execute>jq -e . ~/.claude/state/schemas/debug-checkpoint.schema.json &amp;&amp; jq -e . ~/.claude/state/schemas/audit-campaign.schema.json &amp;&amp; jq -e . ~/.claude/state/schemas/gt-campaign.schema.json</execute>
  <pass_criteria>All three jq calls return exit 0 (valid JSON). `$id` URIs distinct. `schemaVersion` const "1.0" in each.</pass_criteria>
  <evidence>plans/reports/phase-0-schema-freeze-evidence.txt — captured with `ls -la ~/.claude/state/schemas/ &amp;&amp; for f in ~/.claude/state/schemas/*.json; do echo "=== $f ==="; jq -e . "$f" &amp;&amp; echo "valid"; done | tee plans/reports/phase-0-schema-freeze-evidence.txt`</evidence>
  <mock_guard>Schemas are the contract. No test files. Real consumers (checkpoint-lib.js) will validate against these at runtime in Phase C1.</mock_guard>
</validation_gate>

### 0.2 Freeze new rule files (Plan A ships; B + C consume)
**Create** `~/.claude/rules/audit-workflow.md` — visual-first audit generalization (not new, just formalized). Content from Plan A Phase 2 spec. Must cross-reference `ocr-debug-protocol.md`.

**Create** `/Users/nick/Desktop/yt-transition-shorts-detector/.claude/rules/detector-project-conventions.md` — GT-is-the-metric + thread-unsafe adaptive-rescan + fuzz.token_set_ratio + ralph-loop lessons. Project-local.

<validation_gate id="VG-0.2" blocking="true">
Prerequisites: Phase 0.1 VG-0.1 PASS
Execute: test -s ~/.claude/rules/audit-workflow.md && test -s /Users/nick/Desktop/yt-transition-shorts-detector/.claude/rules/detector-project-conventions.md
Capture: `ls -la ~/.claude/rules/audit-workflow.md /Users/nick/Desktop/yt-transition-shorts-detector/.claude/rules/detector-project-conventions.md | tee plans/reports/phase-0-2-evidence.txt; grep -l "instrument-before-theorize" ~/.claude/rules/audit-workflow.md /Users/nick/Desktop/yt-transition-shorts-detector/.claude/rules/detector-project-conventions.md | tee -a plans/reports/phase-0-2-evidence.txt`
Pass criteria: Both files exist with size > 500 bytes. Both grep results show the cross-reference to `instrument-before-theorize.md`.
Review: `cat plans/reports/phase-0-2-evidence.txt` — confirm 2 file paths in first output and 2 matches in second.
Verdict: PASS → proceed to 0.3 | FAIL → re-author the missing/thin file → re-run
Mock guard: Rules must contain real cross-references to live rule files, not placeholder text.
</validation_gate>

### 0.3 Plan B consolidation decision (CANCELLED scope)
**Do NOT create** `~/.claude/skills/gt-perfect/` — cancelled. Modify `yt-transition-shorts-detector/.claude/skills/fix-detection/SKILL.md` in place (Phase B2).
**Do NOT create** `~/.claude/skills/audit/` — cancelled. The detector's existing `audit` skill stays authoritative.
**DO create** `~/.claude/skills/evidence-gate/` — this is the only net-new skill (was `/root-cause-first`, renamed to avoid `fix`/`ck-debug` trigger collision).

<validation_gate id="VG-0.3" blocking="true">
Prerequisites: VG-0.2 PASS
Execute: `test ! -d ~/.claude/skills/gt-perfect && test ! -d ~/.claude/skills/audit && test ! -d ~/.claude/skills/evidence-gate; echo "exit=$?"`
Capture: `echo "phase=0.3 skill_dirs_absent_check exit=$?" | tee -a plans/reports/phase-0-schema-freeze-evidence.txt`
Pass criteria: exit=0 (all three skill directories absent — they land only in Plan B, not prematurely).
Review: `cat plans/reports/phase-0-schema-freeze-evidence.txt | grep phase=0.3` — confirm `exit=0`.
Verdict: PASS → proceed to 0.4 | FAIL → a premature dir exists → rm -rf offender → re-run
Mock guard: Do NOT stub out directories to make the check pass. The check is about confirming clean state.
</validation_gate>

### 0.4 Commit Phase 0 with tag
```bash
cd /Users/nick/Desktop/validationforge
git checkout -b insights/phase-0-schema-freeze
git add plans/reports/phase-0-schema-freeze-evidence.txt
git commit -m "phase-0: freeze shared schemas and new rule files"
git tag insights-phase-0-complete
```

**Phase 0 PASS criteria:**
- [ ] 3 schema files in `~/.claude/state/schemas/` validate as JSON Schema draft-07
- [ ] `audit-workflow.md` + `detector-project-conventions.md` present
- [ ] No premature skill dirs created
- [ ] Git tag `insights-phase-0-complete` exists
- [ ] Evidence file saved

---

## §3 PLAN A — FOUNDATION (5 phases, sequential)

### A1 — Cross-repo CLAUDE.md additions
**Target files:**
- `~/.claude/CLAUDE.md` — insert `## Debugging Protocol` + `## Audit Workflow` after governing-loop preamble
- `yt-transition-shorts-detector/CLAUDE.md` — append `## Detector Project Conventions` section

**Content (verbatim):**
```markdown
## Debugging Protocol
- ONE FIX AT A TIME. Apply one change, verify, decide next.
- Find ROOT CAUSE before patching. Visual evidence / log trace / frame inspection before threshold tweaks.
- Document WHY the fix failed on every revert. See `~/.claude/rules/instrument-before-theorize.md`.

## Audit Workflow
- Visual / frame / rendered-output inspection FIRST. No code-path investigation before visual evidence.
- Seed test data locally. Do not debug cross-workspace auth.
- Run DB schema / migration check up-front. Catch all missing tables in one pass.
```

**Evidence:** `diff` output pre/post edit, quoted in `plans/260417-1715-insights-foundation/reports/a1-evidence.md`.

<validation_gate id="VG-A1" blocking="true">
Prerequisites: Phase 0 complete (tag `insights-phase-0-complete` exists)
Execute: `grep -c "^## Debugging Protocol" ~/.claude/CLAUDE.md && grep -c "^## Audit Workflow" ~/.claude/CLAUDE.md && grep -c "^## Detector Project Conventions" /Users/nick/Desktop/yt-transition-shorts-detector/CLAUDE.md`
Capture: `diff <(git -C ~/.claude show insights-phase-0-complete:CLAUDE.md 2>/dev/null || echo "") ~/.claude/CLAUDE.md | tee plans/260417-1715-insights-foundation/reports/a1-evidence.md; wc -c ~/.claude/CLAUDE.md | tee -a plans/260417-1715-insights-foundation/reports/a1-evidence.md`
Pass criteria: grep returns 1 for each section (exactly one match). Growth ≤800 bytes vs pre-edit.
Review: `cat plans/260417-1715-insights-foundation/reports/a1-evidence.md` — confirm 3 new section headings and bounded growth.
Verdict: PASS → A2 | FAIL → trim or reinsert → re-run
Mock guard: Edit the REAL ~/.claude/CLAUDE.md. No copies, no previews.
</validation_gate>

### A2 — Strengthen rules + add audit-workflow.md
**Modify** `~/.claude/rules/instrument-before-theorize.md` — APPEND (don't prepend — preserve the A7 anecdote as opener):
```markdown
## Root-Cause-First Protocol (added 2026-04-17)
Before ANY code change on a bug:
1. State observed symptom (exact input + expected vs actual output)
2. State hypothesis (ONE function/line named as suspected root cause)
3. Design ONE experiment (log, print, frame dump) that confirms/denies the hypothesis
4. Run the experiment; record evidence path
5. Only then propose a fix

If fix fails: document WHY in `.debug/<issue-id>/failed-approaches.md` before next attempt.
Two failed attempts on the same hypothesis → stop and rethink, don't retry.
```

**`audit-workflow.md`** already created in Phase 0. Skip.

**`detector-project-conventions.md`** already created in Phase 0. Skip.

**Evidence:** `cat ~/.claude/rules/instrument-before-theorize.md | head -40` shows original anecdote preserved; `tail -20` shows new section.

<validation_gate id="VG-A2" blocking="true">
Prerequisites: VG-A1 PASS
Execute: `grep -n "Empirical > Theoretical" ~/.claude/rules/instrument-before-theorize.md && grep -n "Root-Cause-First Protocol" ~/.claude/rules/instrument-before-theorize.md`
Capture: `head -40 ~/.claude/rules/instrument-before-theorize.md > plans/260417-1715-insights-foundation/reports/a2-head.txt; tail -25 ~/.claude/rules/instrument-before-theorize.md > plans/260417-1715-insights-foundation/reports/a2-tail.txt`
Pass criteria: original "Empirical > Theoretical. Instrument > Reason." line appears before line 40 (preserved as closer of original content). "Root-Cause-First Protocol" heading appears in the last 25 lines (appended, not prepended).
Review: `cat plans/260417-1715-insights-foundation/reports/a2-head.txt plans/260417-1715-insights-foundation/reports/a2-tail.txt` — eyeball the structure.
Verdict: PASS → A3 | FAIL → re-apply APPEND (not prepend) → re-run
Mock guard: The A7 anecdote is load-bearing domain knowledge. If your edit removed it, you edited wrong.
</validation_gate>

### A3 — PostToolUse syntax-check hook (Python only; TS deferred)
**Create** `~/.claude/hooks/syntax-check-after-edit.js`:
```javascript
#!/usr/bin/env node
// PostToolUse hook: validate syntax of Python and JS files after Edit/Write/MultiEdit.
// TypeScript deferred (see mega-prompt §2 decisions).
// Exit 2 + stderr = feedback to Claude. Exit 0 silent = allow.
// Stdin shape verified against hooks.md:236-265 and ~/.claude/hooks/evidence-gate-reminder.js idiom.

const { execFileSync } = require('child_process');
const path = require('path');
const fs = require('fs');

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  let data;
  try { data = JSON.parse(input); } catch { process.exit(0); }
  // hooks.md: tool_input shape depends on tool. For Edit/Write: file_path. For MultiEdit: edits[].file_path.
  const tin = data.tool_input || {};
  const filePaths = (tin.file_path ? [tin.file_path]
    : (tin.edits || []).map(e => e.file_path)).filter(Boolean);

  const errors = [];
  for (const rawPath of filePaths) {
    if (!rawPath || rawPath.startsWith('-')) continue; // mandatory path-injection guard
    const p = path.resolve(rawPath);
    if (!fs.existsSync(p)) continue;
    const ext = path.extname(p).toLowerCase();
    try {
      if (ext === '.py') {
        // A-C1 fix: ast.parse, no __pycache__ pollution
        execFileSync('python3', ['-c', 'import ast,sys; ast.parse(open(sys.argv[1]).read())', p],
          { stdio: 'pipe', env: { ...process.env, PYTHONDONTWRITEBYTECODE: '1' } });
      } else if (['.js', '.cjs', '.mjs'].includes(ext)) {
        execFileSync('node', ['--check', p], { stdio: 'pipe' });
      }
      // .ts/.tsx deliberately SKIPPED — see decision §7
    } catch (e) {
      errors.push(`${p}: ${e.stderr?.toString() || e.message}`);
    }
  }

  if (errors.length) {
    process.stderr.write(`Syntax error(s) in edited files:\n${errors.join('\n')}\n`);
    process.exit(2);
  }
  process.exit(0);
});
```

**Register** in `~/.claude/settings.json` PostToolUse `Edit|Write|MultiEdit` matcher (append; do not replace existing hooks).

**Evidence:**
1. Introduce a deliberate SyntaxError in `/tmp/bad.py`
2. Fire hook via: `echo '{"tool_input":{"file_path":"/tmp/bad.py"}}' | node ~/.claude/hooks/syntax-check-after-edit.js; echo "exit=$?"`
3. Expect exit=2 + stderr content
4. Save stdout+stderr to `plans/260417-1715-insights-foundation/reports/a3-evidence.txt`

<validation_gate id="VG-A3" blocking="true">
Prerequisites: VG-A2 PASS; hook installed at `~/.claude/hooks/syntax-check-after-edit.js` and registered in settings.json PostToolUse Edit|Write|MultiEdit matcher.
Execute:
  1. `echo 'def x(:' > /tmp/bad.py; find /Users/nick/Desktop/yt-transition-shorts-detector -name "__pycache__" > /tmp/pyc-before.txt`
  2. `echo '{"tool_input":{"file_path":"/tmp/bad.py"},"tool_name":"Write"}' | node ~/.claude/hooks/syntax-check-after-edit.js 2> /tmp/a3-bad-stderr.txt; echo "exit=$?" > /tmp/a3-bad-exit.txt`
  3. `echo 'def x(): pass' > /tmp/good.py && echo '{"tool_input":{"file_path":"/tmp/good.py"},"tool_name":"Write"}' | node ~/.claude/hooks/syntax-check-after-edit.js 2> /tmp/a3-good-stderr.txt; echo "exit=$?" > /tmp/a3-good-exit.txt`
  4. `find /Users/nick/Desktop/yt-transition-shorts-detector -name "__pycache__" > /tmp/pyc-after.txt`
Capture: `cat /tmp/a3-bad-exit.txt /tmp/a3-bad-stderr.txt /tmp/a3-good-exit.txt /tmp/a3-good-stderr.txt | tee plans/260417-1715-insights-foundation/reports/a3-evidence.txt; diff /tmp/pyc-before.txt /tmp/pyc-after.txt | tee -a plans/260417-1715-insights-foundation/reports/a3-evidence.txt`
Pass criteria: `a3-bad-exit.txt` contains `exit=2`; `a3-bad-stderr.txt` contains "Syntax error"; `a3-good-exit.txt` contains `exit=0`; `a3-good-stderr.txt` is empty; pyc before/after diff is empty (A-C1: no new __pycache__).
Review: `cat plans/260417-1715-insights-foundation/reports/a3-evidence.txt` — confirm all 5 checks.
Verdict: PASS → A4 | FAIL → fix hook → re-run from step 1
Mock guard: Use the real hook binary. Do not stub subprocess.execFileSync.
</validation_gate>

### A4 — Context-threshold warn hook (JSONL-aware) + schema registration
**Create** `~/.claude/hooks/context-threshold-warn.js` — UserPromptSubmit hook. A-C3 fix: parse JSONL transcript content-lengths, not char-count ÷ 4. Transcript path arrives via **stdin JSON `transcript_path`** (verified against hooks.md:236), NOT `CLAUDE_TRANSCRIPT_PATH` env var.

Skeleton:
```javascript
#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  let data;
  try { data = JSON.parse(input); } catch { process.exit(0); }
  // hooks.md:236 — transcript_path is a stdin field, not env var
  const transcriptPath = data.transcript_path;
  if (!transcriptPath || !fs.existsSync(transcriptPath)) process.exit(0);

  let totalChars = 0;
  const lines = fs.readFileSync(transcriptPath, 'utf8').split('\n').filter(Boolean);
  for (const line of lines) {
    try {
      const rec = JSON.parse(line);
      if (rec.message?.content) totalChars += JSON.stringify(rec.message.content).length;
      if (rec.toolUseResult?.content) totalChars += JSON.stringify(rec.toolUseResult.content).length;
    } catch { /* skip malformed */ }
  }
  const tokensApprox = Math.floor(totalChars / 4);
  const ctxWindow = parseInt(process.env.CLAUDE_CODE_AUTO_COMPACT_WINDOW || '200000', 10);
  const pct = tokensApprox / ctxWindow;

  const statePath = path.join(process.env.HOME, '.claude/state/last-ctx-warn.json');
  let last = 0; try { last = JSON.parse(fs.readFileSync(statePath, 'utf8')).ts; } catch {}
  if (Date.now() - last < 30 * 60 * 1000) process.exit(0);

  if (pct >= 0.6) {
    fs.mkdirSync(path.dirname(statePath), { recursive: true });
    fs.writeFileSync(statePath, JSON.stringify({ ts: Date.now() }));
    // Advisory via hookSpecificOutput.additionalContext (matches project convention from completion-claim-validator.js)
    process.stdout.write(JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "UserPromptSubmit",
        additionalContext: `[ctx-warn] ${(pct*100).toFixed(0)}% context used (~${tokensApprox} of ${ctxWindow} tokens). Consider /compact or write checkpoint to ~/.claude/state/debug-checkpoint.json.`
      }
    }));
  }
  process.exit(0);
});
```

<validation_gate id="VG-A4" blocking="true">
  <execute>
    1. Build synthetic JSONL with 500K chars of content at /tmp/big.jsonl
    2. Build small JSONL with 10K chars at /tmp/small.jsonl
    3. For each: `echo "{\"transcript_path\":\"$PATH\",\"hook_event_name\":\"UserPromptSubmit\"}" | node ~/.claude/hooks/context-threshold-warn.js`
  </execute>
  <pass_criteria>Large transcript → stdout contains `additionalContext` with "[ctx-warn]" string. Small transcript → empty stdout, exit 0. Second invocation within 30min on large → silent (debounce works).</pass_criteria>
  <evidence>plans/260417-1715-insights-foundation/reports/a4-evidence.txt — captures stdout + exit codes of all 3 invocations with `tee`.</evidence>
  <mock_guard>Synthetic JSONL is a real file on disk the hook reads — not a mock of hook internals. If tempted to unit-test the function, STOP and just run the hook.</mock_guard>
</validation_gate>

### A5 — Functional validation
Run each hook against REAL edits in REAL projects (not synthetic fixtures):
1. `cd yt-transition-shorts-detector && touch src/bad_test.py` — introduce a Python SyntaxError; invoke via actual Claude Code Edit; confirm hook fires.
2. Simulate 80% context via long conversation; confirm ctx-warn fires once; confirm debounce holds on next prompt.
3. Verify no `__pycache__` appeared anywhere in the target repo.

**Evidence root:** `plans/260417-1715-insights-foundation/reports/a5-functional-validation/`.

**Plan A PASS criteria:**
- [ ] All 5 phase evidence files exist
- [ ] Git tag `insights-plan-a-complete`
- [ ] No regressions to existing hooks (confirm via `ls ~/.claude/hooks/*.js | wc -l` = baseline + 2)

---

## §4 PLAN B — SKILLS LAYER (REVISED) (6 phases)

### B1 — Author `/evidence-gate` skill (was /root-cause-first; renamed)
**Create** `~/.claude/skills/evidence-gate/SKILL.md`:
```yaml
---
name: evidence-gate
description: "Use BEFORE any bugfix edit in src/ or lib/. Creates .debug/<issue-id>/evidence.md with input/output, visual evidence path, minimal repro, ONE root-cause hypothesis, and failed-approaches cross-check. Required by Plan C's PreToolUse enforcer. Triggers: fixing a bug, debugging root cause, before editing to fix, investigate a failing test that isn't a real test (real reproduction), 'why is X failing'. Complements (not replaces) ck-debug and fix."
user-invocable: true
---

# Evidence Gate
[body: progressive disclosure to assets/evidence.md.template and assets/failed-approaches.md.template]
```

**Create** `assets/evidence.md.template` with 5 required sections (input/output, visual evidence, minimal repro, single-line hypothesis, failed-approaches cross-ref).

**Create** `assets/failed-approaches.md.template`.

**Evidence:** skill dir exists; `head -5 SKILL.md` shows frontmatter; `/evidence-gate` listed in `available_skills` after Claude Code reload.

<validation_gate id="VG-B1" blocking="true">
Prerequisites: Plan A complete; VG-0.3 PASS (skill dirs were clean)
Execute: `ls ~/.claude/skills/evidence-gate/SKILL.md ~/.claude/skills/evidence-gate/assets/evidence.md.template ~/.claude/skills/evidence-gate/assets/failed-approaches.md.template`
Capture: `head -10 ~/.claude/skills/evidence-gate/SKILL.md | tee plans/260417-1715-insights-skills-layer/reports/b1-frontmatter.txt; grep -i "complement\|fix\|ck-debug" ~/.claude/skills/evidence-gate/SKILL.md | tee plans/260417-1715-insights-skills-layer/reports/b1-positioning.txt`
Pass criteria: All 3 files exist. Frontmatter has `name: evidence-gate` + `user-invocable: true`. Description explicitly contains "Complements" or mentions "ck-debug" / "fix" by name to disambiguate triggers.
Review: `cat plans/260417-1715-insights-skills-layer/reports/b1-frontmatter.txt plans/260417-1715-insights-skills-layer/reports/b1-positioning.txt` — confirm positioning language present.
Verdict: PASS → B2 | FAIL → rewrite description to disambiguate → re-run
Mock guard: Skill must be real (reloadable by Claude Code), not a stub SKILL.md.
</validation_gate>

### B2 — Extend `fix-detection` in place (was /gt-perfect)
**Modify** `yt-transition-shorts-detector/.claude/skills/fix-detection/SKILL.md` — APPEND section:
```markdown
## GT-Perfection Loop (added 2026-04-17)
When working toward 8/8 ground-truth match:
1. Run detection against ALL videos in `ground_truth/`
2. Diff JSON output vs `*.groundtruth.json` per video (use `scripts/gt-diff.py`)
3. For each mismatch:
   a. Invoke `/evidence-gate` → fill `.debug/<video-id>/evidence.md`
   b. Frame-inspect the failing segment (per `ocr-debug-protocol.md` if OCR-adjacent)
   c. ONE fix
   d. Commit message: `fix-NNN: <root cause> -> <result>`
4. Regression: re-run detection across ALL videos; reject fix if any previously-matching video regresses
5. Repeat until 8/8 OR 20 iterations
```

**Create** `yt-transition-shorts-detector/scripts/gt-diff.py` — structured delta between detection JSON and ground_truth/*.json.

**Evidence:** `fix-detection/SKILL.md` has the new section; `gt-diff.py` runs against one real video and prints a delta table.

<validation_gate id="VG-B2" blocking="true">
Prerequisites: VG-B1 PASS
Execute:
  1. `grep -c "^## GT-Perfection Loop" /Users/nick/Desktop/yt-transition-shorts-detector/.claude/skills/fix-detection/SKILL.md`
  2. `test ! -d ~/.claude/skills/gt-perfect && test ! -d /Users/nick/Desktop/yt-transition-shorts-detector/.claude/skills/gt-perfect; echo "cancellation_preserved=$?"`
  3. `cd /Users/nick/Desktop/yt-transition-shorts-detector && python3 scripts/gt-diff.py <(python3 -m yt_shorts_detector detect stall-test-clips/clips-sequential/seq_A_0-30s.mp4 /tmp/seq_a --detect-stalls --debug-json 2>&1 | tail -5) videos/seq_A.groundtruth.json 2>&1 | head -30`
Capture: output of all 3 commands to `plans/260417-1715-insights-skills-layer/reports/b2-evidence.txt`
Pass criteria: grep returns 1 (section added once). cancellation_preserved=0. gt-diff.py prints a delta table with rows (not an exception).
Review: `cat plans/260417-1715-insights-skills-layer/reports/b2-evidence.txt` — confirm all 3.
Verdict: PASS → B3 | FAIL → revert premature gt-perfect / fix diff script → re-run
Mock guard: gt-diff.py must read REAL detection output against REAL ground truth. No fixtures.
</validation_gate>

### B3 — Design eval cases (2-3 per skill; only `/evidence-gate` + modified `fix-detection`)
Create `plans/260417-1715-insights-skills-layer/evals/evidence-gate/evals.json` and `.../fix-detection-gt-loop/evals.json`. Per-eval prompts are realistic + include filepaths/typos/casual speech. Use field name `expectations` per skill-creator schemas.md.

Per-eval `eval_metadata.json` files use field name `assertions` (M2 fix — confirm via `jq`).

<validation_gate id="VG-B3" blocking="true">
Prerequisites: VG-B2 PASS
Execute: `jq -e '.evals[0].expectations | length > 0' plans/260417-1715-insights-skills-layer/evals/evidence-gate/evals.json; jq -e '.evals[0].expectations | length > 0' plans/260417-1715-insights-skills-layer/evals/fix-detection-gt-loop/evals.json; for f in plans/260417-1715-insights-skills-layer/evals/*/iteration-1/eval-*/eval_metadata.json; do jq -e '.assertions | length > 0' "$f"; done`
Capture: `{ echo "=== evidence-gate evals ==="; jq . plans/260417-1715-insights-skills-layer/evals/evidence-gate/evals.json; echo "=== fix-detection-gt-loop evals ==="; jq . plans/260417-1715-insights-skills-layer/evals/fix-detection-gt-loop/evals.json; } | tee plans/260417-1715-insights-skills-layer/reports/b3-evals-dump.txt`
Pass criteria: Both `evals.json` files parse; `.evals[].expectations` is a non-empty array. All `eval_metadata.json` files parse with `.assertions` non-empty.
Review: `cat plans/260417-1715-insights-skills-layer/reports/b3-evals-dump.txt | head -80` — confirm at least 2-3 eval objects per file with realistic prompts (filepaths, typos, casual phrasing).
Verdict: PASS → B4 | FAIL → fix schema drift (expectations vs assertions) → re-run
Mock guard: Prompts must be realistic. No "Format this data" tautologies — use real user language.
</validation_gate>

### B4 — Run + grade benchmarks (iteration-1; M3 fix: 2 runs/config not 3)
Spawn with-skill + baseline subagents in same-turn **per skill** (not per eval, not 54 at once — M3 fix balancing cache locality vs concurrency).
For each skill: 3 evals × 2 configs × 2 runs = 12 subagents per skill. Run each skill's batch in one turn (12 parallel), then next skill's batch. Two skills ship under the pivot (/evidence-gate + fix-detection-gt-loop) so total = **24 subagents across 2 turns**.
Capture `timing.json` from task notifications. Grade via subagent reading `skill-creator/agents/grader.md`. Aggregate via `python -m scripts.aggregate_benchmark`.

M1 fix: baseline spawns with `~/.claude/skills/` available (incumbents like `fix`, `ck-debug` reachable) so delta measures REAL-WORLD lift.

**Evidence:** `evals/{skill}/iteration-1/benchmark.{json,md}` with three-way delta (with-new-skill / incumbent-only / no-skill).

<validation_gate id="VG-B4" blocking="true">
Prerequisites: VG-B3 PASS; 24 subagent runs complete across 2 turns (12 per skill)
Execute: `jq -e '.configurations[] | select(.name == "with_skill") | .pass_rate' plans/260417-1715-insights-skills-layer/evals/evidence-gate/iteration-1/benchmark.json; jq -e '.configurations[] | select(.name == "incumbent_only") | .pass_rate' plans/260417-1715-insights-skills-layer/evals/evidence-gate/iteration-1/benchmark.json`
Capture: `cat plans/260417-1715-insights-skills-layer/evals/*/iteration-1/benchmark.md | tee plans/260417-1715-insights-skills-layer/reports/b4-benchmarks.md`
Pass criteria: For at least 1 skill, `with_skill` pass-rate > `incumbent_only` pass-rate on at least 1 eval. Three-way delta (with_skill vs incumbent_only vs no_skill) is reported.
Review: `cat plans/260417-1715-insights-skills-layer/reports/b4-benchmarks.md` — confirm three columns, delta column populated, ≥1 win documented.
Verdict: PASS → B5 | FAIL → improve SKILL.md description → re-run B4 into iteration-N+1
Mock guard: Subagent runs must invoke the real skill via its path. No stubbed subagent outputs.
</validation_gate>

### B5 — Iterate on eval-viewer feedback
Launch `eval-viewer/generate_review.py` interactive (macOS has display). Read `feedback.json` after user reviews. Iteration cap: 3 (M4 fix). Improve SKILL.md based on feedback. Re-run iteration-2.

Include `--static` fallback command in phase doc for ssh/tmux (m6 fix).

<validation_gate id="VG-B5" blocking="true">
Prerequisites: VG-B4 PASS (or current iteration); `generate_review.py` launched and user clicked "Submit All Reviews"
Execute: `test -f plans/260417-1715-insights-skills-layer/evals/evidence-gate/iteration-1/feedback.json && jq -e '.status == "complete"' plans/260417-1715-insights-skills-layer/evals/evidence-gate/iteration-1/feedback.json; ITER=$(ls plans/260417-1715-insights-skills-layer/evals/evidence-gate/ | grep iteration- | sort -V | tail -1 | sed 's/iteration-//')`
Capture: `jq -s 'map({iter: .iteration, pass: .pass_rate})' plans/260417-1715-insights-skills-layer/evals/evidence-gate/iteration-*/benchmark.json 2>/dev/null | tee plans/260417-1715-insights-skills-layer/reports/b5-iteration-progression.json`
Pass criteria: EITHER (a) pass-rate of iteration-N > iteration-(N-1), OR (b) `feedback.json` contains empty/"happy" review entries, OR (c) iteration-3 reached (hard cap per M4 fix).
Review: `cat plans/260417-1715-insights-skills-layer/reports/b5-iteration-progression.json` — trajectory should be monotonic improvement or plateau.
Verdict: PASS → B6 | FAIL (regression + cap not hit) → improve SKILL.md → re-run B4
Mock guard: User feedback.json must be real user input, not auto-generated.
</validation_gate>

### B6 — Description optimization (FULL BUDGET: 600 runs — recomputed post-pivot)
For each of 2 skills: 20 trigger eval queries (10 should-trigger / 10 near-miss). Use `skill-creator/assets/eval_review.html` for review; re-check after user edits.

Run `python -m scripts.run_loop --eval-set <path> --skill-path <skill> --model claude-opus-4-7[1m] --max-iterations 5 --verbose` (m3 fix: explicit model ID).

Near-miss prompts avoid tautologies (m4, m5 fixes). E.g., replace "write a unit test for the OCR module" with "explain the OCR preprocessing pipeline to me".

**Budget:** 5 iter × 20 queries × 3 samples × 2 skills = **600 runs** (Plan B pre-pivot assumed 3 skills → 900; /gt-perfect cancellation reduced count to 2 skills → 600. Full-budget tier chosen; success target unchanged).

Success criteria (Full tier): held-out test score ≥80%.

<validation_gate id="VG-B6" blocking="true">
Prerequisites: VG-B5 PASS; run_loop.py background job completed; 600 `claude -p` invocations logged
Execute: `for skill in evidence-gate fix-detection-gt-loop; do jq -e '.best_description and (.test_score >= 0.80)' plans/260417-1715-insights-skills-layer/evals/$skill/description-optimization-report.json; done`
Capture: `for skill in evidence-gate fix-detection-gt-loop; do echo "=== $skill ==="; jq '{best_description, test_score, iterations: (.iterations | length)}' plans/260417-1715-insights-skills-layer/evals/$skill/description-optimization-report.json; done | tee plans/260417-1715-insights-skills-layer/reports/b6-optimization-summary.txt`
Pass criteria: Both skills report `test_score ≥ 0.80` on held-out test queries. Both `SKILL.md` frontmatter `description:` now matches `best_description`.
Review: `diff <(git show HEAD:.claude/skills/evidence-gate/SKILL.md 2>/dev/null) ~/.claude/skills/evidence-gate/SKILL.md` — confirm description actually changed.
Verdict: PASS → B7 | FAIL (score < 0.80 on either skill) → expand near-miss set or run a 4th iteration (still within 5-cap) → re-run
Mock guard: Test queries must be held-out (40% split), not trained on. run_loop.py enforces this automatically.
</validation_gate>

### B7 — Functional validation (real scenario, no mocks — M5 fix)
For `/evidence-gate`: pick an ACTUALLY OPEN bug from one of the three projects (VF, detector, SessionForge). If none open → defer.
For `fix-detection` GT-loop: use current detector state (7/8 match) against a SPECIFIC video that's known-failing. Run the workflow end-to-end until either GT match improves or a fix is proposed and rejected by the regression predicate.

**Evidence:** transcript + evidence.md + commit SHA saved to `plans/260417-1715-insights-skills-layer/reports/b7-{skill}/`.

**Plan B PASS:**
- [ ] `/evidence-gate` in `available_skills`; works end-to-end on a real bug
- [ ] `fix-detection/SKILL.md` has GT-Perfection section; `gt-diff.py` runs
- [ ] No new `/gt-perfect` or `/audit` directories (cancellation preserved)
- [ ] Full-budget benchmark complete; ≥80% held-out test score

---

## §5 PLAN C — AMBITIOUS WORKFLOWS (with safety additions) (6 phases)

### C1 — Shared state + checkpoint library (consume Plan A's schema)
**Create** `~/.claude/scripts/common/checkpoint-lib.js`:
- `readCheckpoint(path, schema)` — reads + validates against `~/.claude/state/schemas/*.schema.json`
- `writeCheckpoint(path, data, schema)` — writes + validates; refuses on schemaVersion mismatch
- `appendFailedApproach(issueId, entry)` — append-only, ROTATES at 500 entries (C-M1 fix)

**Create** `~/.claude/scripts/common/checkpoint-lib.harness.js` — NOT a test file; a runnable demo that reads/writes real state dirs and prints results. Used in Phase C6.

<validation_gate id="VG-C1" blocking="true">
Prerequisites: Plan A complete; `~/.claude/state/schemas/*.schema.json` all present and valid
Execute: `node ~/.claude/scripts/common/checkpoint-lib.harness.js; echo "exit=$?"`
Capture: `node ~/.claude/scripts/common/checkpoint-lib.harness.js 2>&1 | tee plans/260417-1715-insights-ambitious-workflows/reports/c1-harness-output.txt; echo "exit=$?" >> plans/260417-1715-insights-ambitious-workflows/reports/c1-harness-output.txt`
Pass criteria: exit=0. Harness output shows: (1) read+validate roundtrip on all 3 schemas, (2) 501st append to failed-approaches.md triggers rotation to `.archive/<timestamp>.md`, (3) schemaVersion mismatch refusal tested.
Review: `cat plans/260417-1715-insights-ambitious-workflows/reports/c1-harness-output.txt` — confirm all 3 branches exercised.
Verdict: PASS → C2 | FAIL → fix lib or harness → re-run
Mock guard: Harness reads/writes REAL files in a tmpdir, not mocked fs.
</validation_gate>

### C2 — Root-Cause Enforcer hook (SHADOW MODE 7 DAYS — C-C4 fix)
**Create** `~/.claude/hooks/root-cause-enforce-pre.js`:
```javascript
#!/usr/bin/env node
// PreToolUse hook. Stdin shape per hooks.md:236-265; stdin idiom per project convention.
const fs = require('fs'), path = require('path');
const { execFileSync } = require('child_process');

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  if (process.env.CLAUDE_SKIP_ROOT_CAUSE_GATE === '1') process.exit(0);

  let data;
  try { data = JSON.parse(input); } catch { process.exit(0); }
  const toolName = data.tool_name;
  if (!['Edit', 'Write', 'MultiEdit'].includes(toolName)) process.exit(0);

  const tin = data.tool_input || {};
  const filePath = tin.file_path || tin.edits?.[0]?.file_path;
  if (!filePath || !/\/(src|lib)\//.test(filePath)) process.exit(0); // scope: src/ lib/ only

  const cwd = data.cwd || process.cwd();
  const SHADOW = process.env.ROOT_CAUSE_SHADOW === '1' || isWithinFirst7Days();

  const issueId = getIssueId(cwd);
  if (!issueId) return fail(SHADOW, toolName, filePath, cwd,
    'No issue-id. Set CLAUDE_ISSUE_ID or name branch issue/<id>.');

  const evidencePath = path.join(cwd, '.debug', issueId, 'evidence.md');
  if (!fs.existsSync(evidencePath)) return fail(SHADOW, toolName, filePath, cwd,
    `Missing ${evidencePath}. Invoke /evidence-gate first.`);

  // Tightened regexes — accept common heading variants, avoid false-positive from word-soup.
  const content = fs.readFileSync(evidencePath, 'utf8');
  const checks = [
    { label: 'input/output', re: /^##+\s*(input|observed|symptom)[\s\S]{0,100}(output|expected|actual)/im },
    { label: 'visual-evidence', re: /^##+\s*(visual|screenshot|frame|log)\s*evidence/im },
    { label: 'minimal-repro', re: /^##+\s*(minimal\s*)?repro(duction)?/im },
    { label: 'hypothesis (ONE line named)', re: /^##+\s*hypothesis[\s\S]{5,300}?(src\/|lib\/|function\s|line\s*\d+)/im },
    { label: 'failed-approaches cross-ref', re: /failed[-_]approaches\.md/i }
  ];
  const missing = checks.filter(c => !c.re.test(content)).map(c => c.label);
  if (missing.length) return fail(SHADOW, toolName, filePath, cwd,
    `evidence.md incomplete: ${missing.join(', ')}`);

  // One-fix-at-a-time heuristic
  const maxFiles = parseInt(process.env.ONE_FIX_MAX_FILES || '3', 10);
  const diffFiles = countDiffFiles(cwd);
  if (diffFiles > maxFiles) return fail(SHADOW, toolName, filePath, cwd,
    `one-fix-at-a-time: diff touches ${diffFiles} files (>${maxFiles}). Commit current work or split.`);

  // Concurrent-campaign lock (C-M3 fix)
  const lockPath = path.join(cwd, '.debug', '.enforcer-lock');
  if (fs.existsSync(lockPath)) {
    const lockedBy = fs.readFileSync(lockPath, 'utf8').trim();
    if (lockedBy && lockedBy !== issueId) {
      return fail(SHADOW, toolName, filePath, cwd,
        `campaign lock held by ${lockedBy}; current issue ${issueId}. Release or wait.`);
    }
  } else {
    fs.mkdirSync(path.dirname(lockPath), { recursive: true });
    fs.writeFileSync(lockPath, issueId);
  }

  process.exit(0);
});

function fail(shadow, toolName, filePath, cwd, reason) {
  const logPath = path.join(cwd, '.debug', 'enforcer.log');
  fs.mkdirSync(path.dirname(logPath), { recursive: true });
  fs.appendFileSync(logPath,
    `${new Date().toISOString()} ${shadow ? 'SHADOW-BLOCK' : 'BLOCK'} ${toolName} ${filePath}: ${reason}\n`);
  if (shadow) {
    // Advisory only in shadow mode — exit 0, non-blocking
    process.stdout.write(JSON.stringify({
      hookSpecificOutput: { hookEventName: "PreToolUse",
        additionalContext: `[enforcer:shadow] would block — ${reason}` }
    }));
    process.exit(0);
  }
  process.stderr.write(`Root-cause enforcer: ${reason}\n`);
  process.exit(2);
}

function isWithinFirst7Days() {
  const installPath = path.join(process.env.HOME, '.claude/state/enforcer-installed-at');
  try { return Date.now() - parseInt(fs.readFileSync(installPath, 'utf8'), 10) < 7*24*60*60*1000; }
  catch { fs.writeFileSync(installPath, String(Date.now())); return true; }
}

function getIssueId(cwd) {
  if (process.env.CLAUDE_ISSUE_ID) return process.env.CLAUDE_ISSUE_ID;
  try {
    const branch = execFileSync('git', ['rev-parse', '--abbrev-ref', 'HEAD'],
      { cwd, stdio: 'pipe' }).toString().trim();
    // Accept issue/<id>, feature/<id>, feat-<id>, bug/<id>, fix-<id>
    const m = branch.match(/(?:issue|feature|feat|bug|fix)[\/_-]([a-zA-Z0-9._-]+)/);
    return m?.[1] || null;
  } catch { return null; }
}

function countDiffFiles(cwd) {
  try {
    const out = execFileSync('git', ['diff', '--name-only', 'HEAD'],
      { cwd, stdio: 'pipe' }).toString().trim();
    return out ? out.split('\n').length : 0;
  } catch { return 0; }
}
```

**Register** in `~/.claude/settings.json` PreToolUse. Document disable: `CLAUDE_SKIP_ROOT_CAUSE_GATE=1`.

**Worktree lock file** (C-M3 fix): hook also checks `.debug/.enforcer-lock` to prevent concurrent campaign conflicts.

<validation_gate id="VG-C2" blocking="true">
Prerequisites: VG-C1 PASS; hook installed at `~/.claude/hooks/root-cause-enforce-pre.js`; registered in settings.json PreToolUse Edit|Write|MultiEdit
Execute:
  1. Shadow-mode: `cd /Users/nick/Desktop/yt-transition-shorts-detector && git checkout -b issue/test-enforcer-1; ROOT_CAUSE_SHADOW=1 echo '{"tool_name":"Edit","cwd":"'"$PWD"'","tool_input":{"file_path":"'"$PWD"'/src/yt_shorts_detector/foo.py"}}' | node ~/.claude/hooks/root-cause-enforce-pre.js 2> /tmp/c2-shadow-stderr.txt; echo "exit=$?" > /tmp/c2-shadow-exit.txt`
  2. Enforce-mode (without evidence.md): `ROOT_CAUSE_SHADOW=0 rm -rf $PWD/.debug/test-enforcer-1; echo '{"tool_name":"Edit","cwd":"'"$PWD"'","tool_input":{"file_path":"'"$PWD"'/src/yt_shorts_detector/foo.py"}}' | node ~/.claude/hooks/root-cause-enforce-pre.js 2> /tmp/c2-block-stderr.txt; echo "exit=$?" > /tmp/c2-block-exit.txt`
  3. Enforce-mode (with evidence.md): `mkdir -p $PWD/.debug/test-enforcer-1 && cat > $PWD/.debug/test-enforcer-1/evidence.md <<'EOF'\n## Input / Output\nObserved: X. Expected: Y.\n## Visual Evidence\nframe-001.png\n## Minimal Repro\n./binary --flag\n## Hypothesis\nsrc/foo.py:42 — off-by-one\n## Cross-check\nfailed-approaches.md\nEOF\nROOT_CAUSE_SHADOW=0 echo '{"tool_name":"Edit","cwd":"'"$PWD"'","tool_input":{"file_path":"'"$PWD"'/src/yt_shorts_detector/foo.py"}}' | node ~/.claude/hooks/root-cause-enforce-pre.js 2> /tmp/c2-pass-stderr.txt; echo "exit=$?" > /tmp/c2-pass-exit.txt`
  4. Disable-env: `CLAUDE_SKIP_ROOT_CAUSE_GATE=1 echo '{"tool_name":"Edit","cwd":"'"$PWD"'","tool_input":{"file_path":"/src/anything.py"}}' | node ~/.claude/hooks/root-cause-enforce-pre.js; echo "exit=$?" > /tmp/c2-disable-exit.txt`
Capture: `cat /tmp/c2-shadow-exit.txt /tmp/c2-shadow-stderr.txt /tmp/c2-block-exit.txt /tmp/c2-block-stderr.txt /tmp/c2-pass-exit.txt /tmp/c2-pass-stderr.txt /tmp/c2-disable-exit.txt | tee plans/260417-1715-insights-ambitious-workflows/reports/c2-evidence.txt`
Pass criteria: shadow exit=0, stderr empty (advisory via stdout); block exit=2, stderr contains "Root-cause enforcer:"; pass exit=0 (evidence complete); disable exit=0 (env bypass works).
Review: `cat plans/260417-1715-insights-ambitious-workflows/reports/c2-evidence.txt` — confirm all 4 scenarios behave correctly.
Verdict: PASS → C3 | FAIL → fix regex / shadow logic / env check → re-run from step 1; delete /tmp/c2-* between runs
Mock guard: Real hook binary, real git branch, real file paths. No jest/sinon.
</validation_gate>

### C3 — GT Autonomous Tuner
**Create** `yt-transition-shorts-detector/.claude/commands/gt-tuner.md` — slash command entry point.

**Create** `yt-transition-shorts-detector/scripts/gt-tuner/coordinator.js`:
- Reads `ground_truth/*.json` → spawns per-video worker subagents via Task tool (max 8 parallel — C full budget)
- Each worker returns JSON: `{root_cause, fix_diff, expected_delta, risk}`
- Arbiter runs full regression per proposed fix in isolated git worktrees
- Merge predicate: net GT-score improvement, zero regressions on previously-matching videos
- Bounded: max 20 iterations, max 30min per iteration, max tokens 500K per campaign

**Create** `video-worker.prompt.md` — enforces ONE fix, root-cause hypothesis required, structured JSON return.

**Create** `arbiter.js` — runs regression, applies merge predicate.

**Create** `scoreboard.sqlite.schema.sql` — campaigns, videos, fixes, regressions tables.

**Campaign-id collision fix (C-M3):** use `{timestamp}-{randomHex6}` format + filesystem lock.

<validation_gate id="VG-C3" blocking="true">
Prerequisites: VG-C2 PASS; detector at current 7/8 GT-match baseline; 64GB RAM available
Execute: `cd /Users/nick/Desktop/yt-transition-shorts-detector && bash scripts/gt-tuner/coordinator.sh --max-iterations 3 --max-subagents 8 --budget-tokens 500000 2>&1 | tee logs/gt-tuner-$(date +%s).jsonl; echo "exit=$?" > /tmp/c3-exit.txt`
Capture: `ls -la .gt-tuner/campaigns/ | tee plans/260417-1715-insights-ambitious-workflows/reports/c3-campaigns-list.txt; cat .gt-tuner/campaigns/$(ls -t .gt-tuner/campaigns/ | head -1) | tee plans/260417-1715-insights-ambitious-workflows/reports/c3-latest-campaign.json`
Pass criteria: exit=0 or soft-stop (budget hit, not crash). Campaign JSON validates against `gt-campaign.schema.json` (schemaVersion=1.0). At least 1 iteration recorded. For at least 1 proposed fix: `regressionResult` is "net-improve" (accepted+merged) OR "net-regress" (correctly rejected by merge predicate).
Review: `jq -e '.iterations[0].proposedFixes | length > 0 and (map(.regressionResult) | any(. == "net-improve" or . == "net-regress"))' plans/260417-1715-insights-ambitious-workflows/reports/c3-latest-campaign.json`
Verdict: PASS → C4 | FAIL (no fixes proposed OR all regressionResult=pending) → raise iteration cap OR fix arbiter → re-run
Mock guard: Regressions run the REAL detector against REAL videos in REAL worktrees. No stubbed scoreboard.
</validation_gate>

### C4 — Bug-Audit Swarm
**Create** `~/.claude/skills/bug-audit-swarm/SKILL.md` per skill-creator protocol (pushy description, progressive disclosure).

**Create per-role prompt templates:**
- `scouts/scout-prompt.md` — writes failing reproduction (real CLI/HTTP invocation, NOT test files)
- `fixers/fixer-prompt.md` — max 5 iterations per bug
- `reviewers/reviewer-prompt.md` — diff <50 lines unless justified, no reverted-then-reapplied

**Create** `scripts/swarm-coordinator.js` — orchestrates Scout → Fixer → Reviewer via Task tool.

**State:** `.audit/checkpoint.json` after every role turn (uses Plan A schema — C-C1 fix).

<validation_gate id="VG-C4" blocking="true">
Prerequisites: VG-C3 PASS; target = VF utility module with an ACTUALLY OPEN bug (check issue tracker / TODO markers; no synthetic seeding)
Execute: `cd /Users/nick/Desktop/validationforge && claude -p "Invoke /bug-audit-swarm against src/cli/validate-audit.ts. Use the currently-open bug referenced in TODO markers." --allowedTools "Bash,Read,Write,Edit,Grep,Glob" 2>&1 | tee logs/bug-audit-swarm-$(date +%s).jsonl`
Capture: `cat .audit/checkpoint.json | tee plans/260417-1715-insights-ambitious-workflows/reports/c4-checkpoint.json; cat .audit/final-report.md | tee plans/260417-1715-insights-ambitious-workflows/reports/c4-final-report.md`
Pass criteria: `c4-checkpoint.json` validates against `audit-campaign.schema.json`. `c4-final-report.md` contains markdown table with columns `bugs_found | fixed | failed | files_touched`. Scout produced at least 1 failing real reproduction (CLI invocation script, NOT *.test.* file). Fixer ran ≤5 iterations per bug. Reviewer verdict present.
Review: `grep -E "^\| *bugs_found *\|" plans/260417-1715-insights-ambitious-workflows/reports/c4-final-report.md; find .audit -name "*.test.*" -o -name "*.spec.*" | wc -l` (latter must be 0).
Verdict: PASS → C5 | FAIL (no real bug chosen OR test files created) → restart with real bug; rm any test files → re-run
Mock guard: Real bug from real issue/TODO. Scout reproductions are real CLI/HTTP invocations. Zero test files.
</validation_gate>

### C5 — Headless runners (env -i + allowlist — C-C3 fix)
**Create** `~/.claude/scripts/headless/common.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
# C-C3 fix: env scrubbing
ALLOWED_ENV=(PATH HOME PWD USER TERM LANG LC_ALL CLAUDE_ISSUE_ID ROOT_CAUSE_SHADOW)
exec env -i $(for v in "${ALLOWED_ENV[@]}"; do [[ -n "${!v-}" ]] && echo "$v=${!v}"; done) "$@"
```

**Create** `~/.claude/scripts/headless/gt-tuner.sh` — wraps `claude -p` with `--allowedTools` whitelist.

**C-C2 fix (grammar verified against `headless.md:31-32`):** `--allowedTools` uses **literal-prefix match** inside parentheses. `Bash(npm install)` matches any bash command starting with the literal `npm install`. Glob (`Bash(git:*)`), colon-separator (`Bash:git`), and path-scoped (`Edit(scripts/*)`) forms are NOT documented and should be treated as non-functional.

Concrete wrapper:
```bash
#!/usr/bin/env bash
# gt-tuner.sh — headless GT autonomous tuner
set -euo pipefail
source "$(dirname "$0")/common.sh"  # env -i + allowlist

CAMPAIGN_ID="$(date +%s%3N)-$(openssl rand -hex 3)"
export CLAUDE_ISSUE_ID="gt-tuner-${CAMPAIGN_ID}"

# Literal-prefix allowlist — verified against headless.md
claude -p "$(cat <<'EOF'
Execute Plan C Phase C3 (GT Autonomous Tuner) from plans/reports/mega-prompt-260417-1745-insights-implementation.md.
Bounded: max 20 iterations, max 30min wall-clock per iteration, max 500K tokens per campaign.
Write campaign JSON to .gt-tuner/campaigns/${CAMPAIGN_ID}.json after each iteration.
Stop on INSIGHTS_MEGA_ABORT=1 or token cap.
EOF
)" \
  --allowedTools "Bash(git),Bash(python3),Bash(node),Bash(jq),Read,Write,Edit,Grep,Glob" \
  --output-format json \
  2>&1 | tee "logs/gt-tuner-${CAMPAIGN_ID}.jsonl"
```

Fallback if literal-prefix proves insufficient (e.g., need `Bash(git log)` but NOT `Bash(git push)`):
```bash
# Subtractive: allow all Bash, disallow dangerous subcommands
--allowedTools "Bash,Read,Write,Edit,Grep,Glob" \
--disallowedTools "Bash(git push),Bash(rm),Bash(sudo),Bash(curl)"
```

**Token cap:** `CLAUDE_RUN_TOKEN_CAP=2000000` soft-stops run, checkpoints, exits.

<validation_gate id="VG-C5" blocking="true">
Prerequisites: VG-C4 PASS; `~/.claude/scripts/headless/common.sh` installed
Execute:
  1. Credential scrubbing: `ANTHROPIC_API_KEY=FAKESECRET GITHUB_TOKEN=FAKESECRET bash ~/.claude/scripts/headless/common.sh env 2>&1 | tee /tmp/c5-env.txt`
  2. Allowlist enforcement probe: `claude -p "List files with ls" --allowedTools "Bash(git)" 2>&1 | tee /tmp/c5-allowlist.txt` (expect refusal to run `ls` since only `git` is allowed)
  3. Token cap: `CLAUDE_RUN_TOKEN_CAP=100 bash ~/.claude/scripts/headless/gt-tuner.sh --dry-run 2>&1 | tee /tmp/c5-tokencap.txt` (expect soft-stop with checkpoint)
Capture: `cat /tmp/c5-env.txt /tmp/c5-allowlist.txt /tmp/c5-tokencap.txt | tee plans/260417-1715-insights-ambitious-workflows/reports/c5-evidence.txt`
Pass criteria: c5-env.txt does NOT contain the word "FAKESECRET" (env -i scrubbed). c5-allowlist.txt shows Claude refusing to run `ls` or asking permission (allowlist respected). c5-tokencap.txt shows "soft-stop" / "checkpoint" message before completion.
Review: `grep -c FAKESECRET plans/260417-1715-insights-ambitious-workflows/reports/c5-evidence.txt` must be 0.
Verdict: PASS → C6 | FAIL (credential leaked OR allowlist grammar mismatched) → fix common.sh OR re-verify `claude --help` for grammar → re-run
Mock guard: Real claude binary, real env, real spawned process. Don't stub exec.
</validation_gate>

### C6 — Functional validation (SPLIT ACROSS 3 SESSIONS — C-C5 fix)

**Session 1 (enforcer only):** Seed a bug in yt-shorts-detector (real open TODO, not synthetic). Attempt Edit in src/ without evidence.md → confirm shadow-mode logs. Set shadow=0 → confirm exit 2 + stderr. Write evidence.md → retry → allowed. Evidence: `reports/c6-enforcer.md`.

**Session 2 (GT tuner):** Run `/gt-tuner` against current 7/8 detector state. Target: demonstrate at least ONE proposed fix was correctly accepted or rejected by merge predicate. Evidence: campaign JSON + before/after scoreboard.

**Session 3 (swarm):** Run `/bug-audit-swarm` against VF utility module (real). Scout writes reproduction → fixer → reviewer. Evidence: per-role transcripts.

Each session's token budget ≤1.5M. Do NOT run in single session (C-C5 self-DoS).

<validation_gate id="VG-C6" blocking="true">
Prerequisites: VG-C5 PASS; 3 separate sessions run (NOT a single session — C-C5 self-DoS mitigation)
Execute (evidence pre-captured from each session):
  1. Session 1 evidence: `ls -la plans/260417-1715-insights-ambitious-workflows/reports/c6-enforcer.md`
  2. Session 2 evidence: `ls -la plans/260417-1715-insights-ambitious-workflows/reports/c6-tuner-campaign.json plans/260417-1715-insights-ambitious-workflows/reports/c6-tuner-before-after.md`
  3. Session 3 evidence: `ls -la plans/260417-1715-insights-ambitious-workflows/reports/c6-swarm-transcripts/`
  4. Resume test: after session 3 completes, start NEW session, point at `.audit/checkpoint.json`, confirm swarm resumes from last role turn.
Capture: `{ echo "=== enforcer ==="; cat plans/260417-1715-insights-ambitious-workflows/reports/c6-enforcer.md; echo "=== tuner ==="; cat plans/260417-1715-insights-ambitious-workflows/reports/c6-tuner-before-after.md; echo "=== swarm ==="; ls plans/260417-1715-insights-ambitious-workflows/reports/c6-swarm-transcripts/; } | tee plans/260417-1715-insights-ambitious-workflows/reports/c6-final-summary.md`
Pass criteria: All 3 session evidence files/dirs exist and are non-empty. Enforcer evidence includes both shadow-mode log line AND blocking-mode stderr. Tuner merge predicate correctly applied in at least 1 iteration (net-improve OR net-regress, not pending). Swarm resume succeeded from fresh session (checkpoint read + work continued).
Review: `cat plans/260417-1715-insights-ambitious-workflows/reports/c6-final-summary.md` — confirm all 4 criteria.
Verdict: PASS → All plans complete; git tag `insights-all-plans-complete`; run `/ck:journal` | FAIL → identify missing session, re-run that session only, do NOT re-run all 3
Mock guard: Three DISTINCT sessions with DISTINCT timestamps. No single-session cheats.
</validation_gate>

---

## §6 EXECUTION PROTOCOL

### Headless invocation (autonomous run)
```bash
# Phase 0 + Plan A (sequential, ~2.5h total)
claude -p "$(cat plans/reports/mega-prompt-260417-1745-insights-implementation.md)

EXECUTE Phase 0 then Plan A all phases A1-A5.
Stop after A5 and report PASS/FAIL with evidence file paths." \
  --allowedTools "Edit,Write,Read,Grep,Glob,Bash" \
  --output-format json \
  2>&1 | tee logs/mega-prompt-phase-0-plan-a-$(date +%Y%m%d-%H%M%S).jsonl
```

Repeat for Plan B (separate session; ~4h) and Plan C (3 separate sessions; ~2h each).

### Interactive invocation (user-in-loop)
1. `cd /Users/nick/Desktop/validationforge`
2. Start Claude Code session
3. Paste: "Execute `plans/reports/mega-prompt-260417-1745-insights-implementation.md` starting at Phase 0. Stop at each phase gate for my approval."
4. Approve gates inline.

### Evidence capture (per phase)
- Every phase saves to `plans/{plan-dir}/reports/{phase-slug}-evidence.{md,txt,json}`
- Evidence content: file path, cited line, command output, exit code, timestamp
- No phase is PASS until evidence file exists and cites specific content (not existence)

### Gate enforcement
- Each phase has explicit PASS criteria listed in this document
- Skip to next phase ONLY after gate passes
- On gate FAIL: stop the plan, leave checkpoint, report to user

### Kill switches + rollback
- `INSIGHTS_MEGA_ABORT=1` → soft-stop after current phase
- `git tag insights-phase-<N>-complete` after each phase PASS
- Rollback: `git reset --hard insights-phase-<N-1>-complete`; discard branch

### Post-execution
Run `/ck:journal` after all 3 plans complete. Commit mega-prompt + all evidence files.

---

## §7 DECISION LOG (locked 2026-04-17)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Plan B scope | Cancel /gt-perfect + /audit; ship only /evidence-gate + modify fix-detection | Existing detector skills cover 80% of what Plan B proposed |
| Syntax-check language scope | Python only (ast.parse); defer TS | TS requires tsconfig walk-up; defer to follow-up |
| __pycache__ prevention | PYTHONDONTWRITEBYTECODE=1 + ast.parse | A-C1 fix |
| Context-threshold heuristic | JSONL content-aware | A-C3 fix |
| Enforcer rollout | Shadow-mode 7 days, then flip | C-C4 fix |
| Subagent env | `env -i` + explicit allowlist | C-C3 fix |
| Budget | Full (900 runs Plan B; all 3 workflows Plan C) | User accepted |
| Plan C Phase 6 | Split across 3 sessions | C-C5 self-DoS mitigation |
| Schema ownership | Plan A owns; Plan C consumes | X1 resolution |
| /root-cause-first rename | /evidence-gate | Avoid `fix`/`ck-debug` trigger war |

---

## §8 UNRESOLVED (surfaces for future attention)

1. `--allowedTools` grammar (`Bash(git:*)` vs `Bash:git`) — verify at C5 execution time against live `claude --help`
2. `failed-approaches.md` rotation at 500 entries — confirm rotation file format
3. Enforcer one-fix-at-a-time threshold (3 files default) — tune per project if rename-across-many-files triggers false blocks
4. TypeScript syntax-check — follow-up plan needed when TS surface grows
5. Multi-operator concurrent `/gt-tuner` — locking semantics beyond filesystem lock?

---

<gate_manifest>
Total gates: 22
  Phase 0: VG-0.1, VG-0.2, VG-0.3, VG-0.4 (tag-only, implicit in 0.4)
  Plan A: VG-A1, VG-A2, VG-A3, VG-A4, VG-A5 (phase rollup)
  Plan B: VG-B1, VG-B2, VG-B3, VG-B4, VG-B5, VG-B6, VG-B7 (phase rollup)
  Plan C: VG-C1, VG-C2, VG-C3, VG-C4, VG-C5, VG-C6 (phase rollup, 3 sub-sessions)
Sequence: VG-0.1 → VG-0.2 → VG-0.3 → [Phase 0 tag] → VG-A1 → ... → VG-A5 → [Plan A tag] → VG-B1 → ... → VG-B7 → [Plan B tag] → VG-C1 → ... → VG-C6 → [all-complete tag]
Policy: ALL gates BLOCKING. No advancement on FAIL. On gate FAIL: fix real system → re-run failed gate (not prior gates). No partial completion of a gate.
Evidence root: plans/{plan-dir}/reports/ (per plan) and plans/reports/ (cross-cutting)
Regression protocol: If a later gate FAILS and root cause is in an earlier phase's artifact, re-run from the earliest affected gate. Do NOT skip gates to reach the failing one faster.
Shadow-mode policy: Plan C VG-C2 supports shadow mode for first 7 days per `enforcer-installed-at` state file. After 7 days or explicit `ROOT_CAUSE_SHADOW=0`, gate enforces blocking mode.
Mock-detection policy: Applies to EVERY gate. Any `.test.*`, `.spec.*`, mock library import, in-memory DB, or TEST_MODE flag → abort task, fix real system.
</gate_manifest>

---

**END OF MEGA-PROMPT.** Authoritative for execution. Source plans in `plans/260417-1715-insights-*/` remain for audit trail.
