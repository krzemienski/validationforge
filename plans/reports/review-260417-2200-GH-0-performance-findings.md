# Performance + Concurrency Review — 260417-2200

## Summary
- Critical: 2, High: 4, Medium: 5, Low: 3
- Overall perf posture: Hot-path hooks are mostly cheap (resolve-profile memoized + STANDARD_DEFAULTS fast path). Biggest risks: `completion-claim-validator` does unbounded sync `readdirSync`+`statSync` in project root on every Bash call; several regex patterns in `patterns.js` are ReDoS-fragile against adversarial tool output (Bash stdout / Write content).

## Hot-path latency budget
- Per-tool-call fixed cost ≈ Node cold-start (~40–80ms) × N hooks matching the tool. A single Bash tool call fires 3 hooks (validation-not-compilation, completion-claim-validator, validation-state-tracker) = 3 Node processes serially — ~120–240ms of pure startup before any work. This is an architectural cost, not a code smell, but it means every additional sync I/O in a hook compounds.
- `block-test-files` / `mock-detection` / `evidence-quality-check`: near-zero after profile cache hit (regex-only work).
- `completion-claim-validator`: only triggers I/O on completion-claim match, but when it does, full `readdirSync` + per-entry `statSync` of `e2e-evidence/` — unbounded. On a project with thousands of evidence files, this dominates.
- `evidence-gate-reminder`: TodoWrite payloads can contain large `todos` arrays; `.some()` short-circuits, fine.

## Findings

### PERF-C1: Catastrophic-backtracking-prone regexes on tool output (CRITICAL) — Confidence: HIGH
- Location: `hooks/lib/patterns.js:58-62` and callers `mock-detection.js:51`, `completion-claim-validator.js:55`, `validation-not-compilation.js:30`
- Issue: Several MOCK_PATTERNS use bounded-quantifier alternatives with `[^\n]{0,N}` runs that still permit pathological matching cost on adversarial inputs. More concerning: `COMPLETION_PATTERNS` and `BUILD_PATTERNS` run `.test(output)` against **`data.tool_result.stdout`** — this is the full stdout of the just-executed Bash command, which is user-controlled for all practical purposes (any script can echo arbitrary text). Specific concerns:
  - `/all.*pass/i` and `/tests.*pass/i` (patterns.js:78–79) — `.*` greedy, case-insensitive, tested against full stdout. On a 1MB Bash stdout containing `"all" + "a"*500000 + "pazz"`, this is still linear (single `.*`), **but** the scan cost × 4 COMPLETION_PATTERNS against possibly large stdout is unbounded. `completion-claim-validator.js` does not cap input size the way `mock-detection.js` does (MAX_SCAN_BYTES=200KB).
  - `/expect\([^)]{0,500}\)\.(to|not)/` (patterns.js:62) — nested bounded quantifier + alternation after it. Safe in practice (single negated char class) but tested against arbitrary Write content up to 200KB; the `.some()` short-circuits, but the scan cost per pattern before the match is non-trivial.
  - `/describe\(['"][^'"]{0,200}['"],\s*\(\)\s*=>/ ` and `/it\(['"][^'"]{0,200}['"],\s*\(\)\s*=>/` — two nearly identical patterns applied sequentially; would miss the cheaper case if the earlier matches.
- Fix:
  1. Cap input in `completion-claim-validator.js` the same way `mock-detection.js` does (MAX_SCAN_BYTES).
  2. Cap input in `validation-not-compilation.js` and `validation-state-tracker.js`.
  3. Anchor `COMPLETION_PATTERNS` more tightly: replace `/all.*pass/i` with `/\ball[^\n]{0,80}pass(ed|ing)?\b/i`. Same for `/tests.*pass/i`.
  4. Add a hard timeout to hook execution in `hooks.json` via a wrapper (not supported natively in Claude Code hook schema — fall back to input size caps).
- Code (before → after for validation-not-compilation.js:26-30):
```js
// before
const data = JSON.parse(input);
const result = data.tool_result || {};
const output = typeof result === 'string' ? result : (result.stdout || '');
const isBuildSuccess = BUILD_PATTERNS.some(p => p.test(output));

// after
const MAX_SCAN_BYTES = 200 * 1024;
const data = JSON.parse(input);
const result = data.tool_result || {};
const rawOutput = typeof result === 'string' ? result : (result.stdout || '');
const output = rawOutput.length > MAX_SCAN_BYTES ? rawOutput.slice(-MAX_SCAN_BYTES) : rawOutput;
const isBuildSuccess = BUILD_PATTERNS.some(p => p.test(output));
```
Note: slice from the end (`-MAX`), not start — success markers are almost always at the tail of build output.

### PERF-C2: Unbounded synchronous readdir+statSync on hot path (CRITICAL) — Confidence: HIGH
- Location: `hooks/completion-claim-validator.js:64-72`
- Issue: On every Bash call whose stdout matches a COMPLETION_PATTERN, the hook does `fs.readdirSync(evidenceDir)` followed by `fs.statSync` on every entry. No cap, no short-circuit after first match. A project that has accumulated thousands of evidence directories (which is realistic — `e2e-evidence/` is the intended long-term home) pays O(N) syscalls per hit. `.some()` does short-circuit once a fresh+non-empty entry is found, which helps, but worst case (all entries stale) is full scan.
- Concurrency: parallel Bash calls (common with agents/Task tool) will race on this scan, multiplying I/O pressure and blocking the event loop per-process (sync).
- Fix: Cap the scan (`slice(0, 200)` max entries) and prefer `opendir`/`Dirent.statSync` via `readdirSync(..., { withFileTypes: true })` — avoids an extra syscall per entry on APFS. Even better: once `hasFreshEvidence = true`, break early (the `.some()` does this; the remaining win is keeping a hard upper bound on entries scanned).
- Code:
```js
// after
if (fs.existsSync(evidenceDir)) {
  const entries = fs.readdirSync(evidenceDir, { withFileTypes: true }).slice(0, 200);
  const cutoff = Date.now() - 24 * 60 * 60 * 1000;
  hasFreshEvidence = entries.some(ent => {
    try {
      const stat = fs.statSync(path.join(evidenceDir, ent.name));
      return stat.mtimeMs > cutoff && stat.size > 0;
    } catch { return false; }
  });
}
```
Better still: sort by mtime desc and check only top N — but that requires a first pass anyway, so the cap is the pragmatic win.

### PERF-H1: `statSync` instead of `stat` on directories, missing fast path for size (HIGH) — Confidence: HIGH
- Location: `hooks/completion-claim-validator.js:69`
- Issue: `fs.statSync` on an entry that's itself a directory returns directory inode size, not the size of evidence content inside. `stat.size > 0` is true for nearly every non-empty directory on macOS/APFS (dir size is always nonzero). The "non-empty evidence" gate is effectively a no-op for nested evidence structures (e.g. `e2e-evidence/journey-A/step-01.png`). Evidence quality gate is bypassed silently.
- Fix: When entry is a directory, descend one level and check for any regular file with size>0 and recent mtime. Or: redefine "fresh evidence" as "any descendant file matching the shape step-NN-*." A cheap fix is to check `ent.isFile() && stat.size > 0` first, and only recurse for directories up to 1 level deep.

### PERF-H2: Per-hook re-import of patterns.js + resolve-profile.js (HIGH) — Confidence: MEDIUM
- Location: All hooks (`hooks/*.js`)
- Issue: Each hook is a separate Node process. Node.js cold-start + `require('./lib/patterns')` + `require('./lib/resolve-profile')` runs on *every* tool invocation. Regexes in `patterns.js` are compiled once per process, which is fine — but the process itself is spun up fresh each time. For a Bash tool call that triggers 3 hooks, that's 3 Node boots.
- There's no in-tree fix beyond what the spec allows (Claude Code hooks are spawned as subprocesses). But **do not** add any heavy top-level `require` to the hook files. Currently clean — keep it that way. Any future hook that imports a transpilation/AST lib would add ~100–300ms cold-start.
- Fix: Add a lint rule or CI check that fails if any `hooks/*.js` requires anything outside `fs`, `path`, `os`, and `./lib/*`. Add to `scripts/verify-hooks.js`.

### PERF-H3: No input size cap on `evidence-gate-reminder.js` (HIGH) — Confidence: HIGH
- Location: `hooks/evidence-gate-reminder.js:37-42`
- Issue: `Array.isArray(toolInput.todos) ? toolInput.todos : []` then `.some(t => t && t.status === 'completed')`. Large todos arrays (adversarial or buggy) would force full O(N) scan (well, short-circuit on first `completed`). Mostly benign, but no cap. More importantly, `JSON.parse(input)` on line 34 can consume arbitrary-sized stdin. A huge TodoWrite payload blocks the main thread during parse. For TodoWrite, payloads are realistically <1MB so this is low risk — but still worth capping.
- Fix: Add MAX_INPUT_BYTES guard when assembling `input` in the stdin handler:
```js
let input = '';
const MAX_INPUT_BYTES = 2 * 1024 * 1024; // 2MB
process.stdin.on('data', chunk => {
  if (input.length + chunk.length > MAX_INPUT_BYTES) {
    process.exit(0); // bail silently on oversize input
  }
  input += chunk;
});
```
Apply to ALL hooks.

### PERF-H4: `generate-report.js` base64-encodes all PNGs into single HTML (HIGH) — Confidence: HIGH
- Location: `scripts/generate-report.js:84`, `scripts/generate-report.js:255`
- Issue: `fs.readFileSync(filePath).toString('base64')` for every screenshot, synchronously, concatenated into one HTML string. A dashboard for 20 journeys × 10 screenshots × 500KB PNG = 100MB base64 HTML. Node's string-concatenation + `fs.writeFileSync` of a 100MB+ buffer stalls the process and can OOM on smaller runners. Also, the JSON highlighter regex at line 255 has nested alternation with a capture group that's vulnerable to moderate input ReDoS on pathological escape strings — bounded in practice by escaping at the front.
- Fix:
  1. Stream-write the HTML with `fs.createWriteStream(outputFile)` and write each journey block as it's processed, not accumulated in memory.
  2. Downscale or skip images > 2MB, or split into one HTML per journey and link from the index.
  3. Use a safe JSON highlighter (e.g. Prism via CDN in offline mode, or a linear tokenizer) — only a concern if evidence JSON can be adversarial, which is unlikely in the evidence workflow.
- This is not on the hot path (script-invoked) but a benchmark-path with user-visible pain at scale.

### PERF-M1: `resolveProfile` cache module-level state but hooks are one-shot (MEDIUM) — Confidence: HIGH
- Location: `hooks/lib/resolve-profile.js:69`
- Issue: Comment claims "hooks run as one-shot processes, but the resolver can be called several times per hook — cache saves each subsequent lookup the double-fs cost." Inspection of callers: `block-test-files.js` calls `resolveProfile()` once, `hookState()` once, `ruleEnabled()` once — none of those actually re-call `resolveProfile`. The cache has **no observable effect in production**; only `_resetCacheForTests` exercises it. The code isn't wrong — it's just dead weight (and a small risk: if a future caller mutates `profile.data`, the frozen defaults protect; but user-read profile data is *not* frozen).
- Fix: Either drop the cache (simpler) or freeze `data` before caching:
```js
_cache = { name: envVal, data: Object.freeze(data), source: 'env:VF_PROFILE' };
```

### PERF-M2: `readProfileFile` swallows JSON parse errors silently (MEDIUM) — Confidence: HIGH
- Location: `hooks/lib/resolve-profile.js:71-78`
- Issue: If `config/strict.json` is present but has a JSON syntax error, `readProfileFile` returns `null` and the caller falls through to `STANDARD_DEFAULTS`. A user who mis-edited their strict profile will silently get standard enforcement — no warning, no log. On a config-management perspective this is a correctness issue (violates principle of least surprise) but it's MEDIUM because it only affects misconfigured installs.
- Fix: `process.stderr.write` a one-liner warning when a profile file exists but fails to parse:
```js
function readProfileFile(name) {
  const p = path.join(CONFIG_DIR, `${name}.json`);
  if (!fs.existsSync(p)) return null;
  try { return JSON.parse(fs.readFileSync(p, 'utf8')); }
  catch (e) {
    process.stderr.write(`[VF] WARN: ${p} unreadable (${e.message}); using standard defaults.\n`);
    return null;
  }
}
```

### PERF-M3: `completion-claim-validator` resolves evidence dir from `data.cwd` without validation (MEDIUM) — Confidence: MEDIUM
- Location: `hooks/completion-claim-validator.js:23-35`
- Issue: Candidates include `data.cwd` (from hook JSON payload). While `fs.existsSync` is called before joining, a crafted payload could point at a symlink to an unrelated directory (and the hook would then scan whatever lives there). Not a security hole (the hook only reads/stats, doesn't write), but it's a trust-boundary issue: the hook is supposed to enforce evidence in the project root and could be redirected. Review note already flags this (finding M4 in the code).
- Fix: Verify that `data.cwd`, if present, is the same as `process.env.CLAUDE_PROJECT_ROOT` when both are set; if they diverge, prefer the env var and log a warning.

### PERF-M4: Empty-evidence detection via `content.length === 0` misses whitespace-only writes (MEDIUM) — Confidence: HIGH
- Location: `hooks/evidence-quality-check.js:45`
- Issue: A Write that passes `content: "   \n\n\n"` satisfies `content.length > 0` and passes the gate, but the file is empty of real observations. Rule says "0-byte files are INVALID evidence" which is literally what's checked — but the spirit of the rule is "meaningful evidence." This is a correctness gap, not a perf issue per se, but it undermines the validation the hook is meant to enforce.
- Fix: `if (content.trim().length === 0) { ... }` for text files. PNG/binary evidence comes through `Write` as… actually, binary Write isn't a thing in Claude Code — Writes are text. So trimming is safe.

### PERF-M5: Race on `evidenceRoot/cleanup.log` in `evidence-clean.js` (MEDIUM) — Confidence: HIGH
- Location: `scripts/evidence-clean.js:88`
- Issue: `fs.appendFileSync` without file locking. If two `evidence-clean` runs execute concurrently (two agents, parallel CI jobs), the log can interleave and corrupt lines. The lock file protocol in the header protects validation runs from cleanup, but does **not** protect concurrent cleanup invocations from each other. Also, `fs.rmSync` on the same directory from two concurrent processes is a classic TOCTOU — one sees it exist, starts recursive delete, the other sees partial state and errors mid-delete.
- Fix: Take an exclusive lock on the cleanup.log or a dedicated `.vf/state/cleanup.lock` at script start; fail fast if taken. Use `fs.openSync(lockPath, 'wx')` pattern.

### PERF-L1: `transcript-analyzer.js` reads entire JSONL into memory (LOW) — Confidence: HIGH
- Location: `benchmark/transcript-analyzer.js:16`
- Issue: `fs.readFileSync(file, 'utf8').split('\n')` on potentially very large session transcripts (Claude Code sessions can reach hundreds of MB). Consider `readline` over a stream. Low severity — this is an occasional analysis tool, not a hook.
- Fix:
```js
const rl = readline.createInterface({ input: fs.createReadStream(file), crlfDelay: Infinity });
for await (const line of rl) { /* ... */ }
```

### PERF-L2: `vf.js status` re-parses `package.json` and iterates `REQUIRED_RULES` with O(N) fs.existsSync calls (LOW) — Confidence: HIGH
- Location: `bin/vf.js:118-132`
- Issue: 8 rules × 2 existsSync each = 16 syscalls on every `vf status`. Cheap, but could batch with a single `readdirSync` of each rules dir. Low priority.

### PERF-L3: `generate-report.js` syntax-highlighter regex on arbitrary JSON (LOW) — Confidence: MEDIUM
- Location: `scripts/generate-report.js:255`
- Issue: Pattern `/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|...)/g` — nested quantifier `(...)*` inside a captured group. Not catastrophic on normal JSON, but adversarial inputs (e.g. `"\"\"\"\"\"\"\"\"\"\"\"\"\"..."`) could cause slow matching. Evidence JSON is trusted in practice, so LOW.
- Fix: Replace with a tokenizer or use a vetted library if adversarial input becomes a concern.

## Strengths
- `mock-detection.js` explicitly caps input at 200KB (MAX_SCAN_BYTES) — this is exactly the right defensive move, and the rest of the hooks should match it.
- `resolve-profile.js` has a thoughtful fast-path: `VF_PROFILE=standard` with no user config returns frozen defaults with zero fs I/O. Good.
- Hook JSON (`hooks/hooks.json`) correctly wraps all node invocations with `|| true` so a hook crash cannot block the tool. Also uses `${CLAUDE_PLUGIN_ROOT}` resolution rather than hard-coded paths.
- `evidence-clean.js` lock protocol is well-designed: PID liveness check + 1-hour stale grace + conservative default when PID is dead but lock is recent. Appends audit log per action.
- Hooks fail-safe — every hook wraps its main logic in try/catch and exits 0 on error, so a hook bug cannot break the editor. (Trade-off: silent failures are possible, but the priority is right.)

## Unresolved questions
1. Are Claude Code hooks ever invoked with a stdin limit? If the runtime enforces e.g. 10MB max, the ReDoS/size-cap concerns are already bounded. Worth confirming with the CC hooks spec in `references/hooks.md`.
2. `completion-claim-validator` pattern `/all.*pass/i` matches "all users must pass authentication" or similar incidental strings. This is a false-positive risk, not perf — but causes user-visible `exit 2` blocks on unrelated commands. Should the completion-pattern set be tightened?
3. Is `e2e-evidence/` intended to accumulate indefinitely? If so, PERF-C2's unbounded scan becomes worse over time. If cleanup is run regularly, the practical impact stays small.
4. Concurrency model for parallel validators: validators each write to their own subdir per the orchestration rules, so directory-level races are avoided — but the aggregation step (verdict-writer reading all subdirs) runs after, which is sequentially safe. No finding here beyond confirming that's the actual execution pattern.

---

STATUS: DONE
Summary: Found 2 CRITICAL (ReDoS/unbounded scans on hot-path Bash hooks, unbounded readdir+stat in completion-claim-validator), 4 HIGH, 5 MEDIUM, 3 LOW. Quick wins: add MAX_SCAN_BYTES to `validation-not-compilation.js`/`completion-claim-validator.js`/`validation-state-tracker.js`/`evidence-gate-reminder.js`; cap readdir in completion-claim-validator; fix stat.size>0 check for directories.
