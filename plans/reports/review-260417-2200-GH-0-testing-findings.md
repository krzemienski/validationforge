# Testing + Compatibility Review — 260417-2200

## Summary
- Critical: 4, High: 5, Medium: 4, Low: 2
- Self-validation coverage: multiple gates drift from the manifest they police; several cross-file invariants will fail the first time a user runs them.
- Public contract stability: plugin.json advertises 52/19/7/7/9 inventory but omits the directory declarations Claude Code needs to discover ANY of it; hooks.json defangs its own block exits.

## Findings

### COMPAT-C1: `|| true` defangs every hook — exit(2) block never reaches Claude Code (CRITICAL) — Confidence: HIGH
- Location: `hooks/hooks.json:9,18,29,33,37,46,50`
- Issue: Every hook command is suffixed with `|| true`. When a PostToolUse hook does `process.exit(2)` to trigger Claude Code's stderr-feedback block protocol (`validation-not-compilation.js:43`, `completion-claim-validator.js:86`, `validation-state-tracker.js:42`, `mock-detection.js:66`, `evidence-quality-check.js:57`), the shell swallows the non-zero status and returns 0. Claude Code sees success and proceeds as if nothing happened. The hooks run, print their stderr warning, but do not block. The verify-hooks.js self-check spawns the `node` process directly and sees exit=2, so the gate passes in CI while the plugin is silently disarmed at runtime.
- Fix: Remove `|| true`. Let the exit code propagate. Catch accidental hook errors inside each hook (they already do — `catch (e) { … process.exit(0); }`). Example:
  ```json
  "command": "node \"${CLAUDE_PLUGIN_ROOT}/hooks/validation-not-compilation.js\""
  ```
- Impact: advertised enforcement ("enabled → hard block") is a lie; permissive/standard/strict behave identically from Claude Code's perspective. Benchmark score inflates because tests spawn hook directly.

### COMPAT-C2: plugin.json missing `commands`, `skills`, `agents`, `rules`, `hooks` declarations (CRITICAL) — Confidence: HIGH
- Location: `.claude-plugin/plugin.json` (entire file — 22 lines, no component keys) vs `scripts/verify-plugin-structure.js:77` which requires `['commands', 'skills', 'agents', 'rules', 'hooks']` and `scripts/verify-cache.js:18` which requires `['commands', 'skills']`.
- Issue: Claude Code reads these directory declarations from plugin.json to discover which subdirectories ship commands/skills/agents/hooks. Without them, Claude Code cannot load the 19 commands, 52 skills, 7 agents, or auto-register the hooks even though the files exist on disk. Plugin loads but appears empty.
- Fix: Add the directory declarations:
  ```json
  {
    "name": "validationforge",
    "version": "1.0.0",
    "commands": "./commands",
    "skills": "./skills",
    "agents": "./agents",
    "hooks": "./hooks/hooks.json"
  }
  ```
- Impact: every user install is broken; verify-plugin-structure.js and verify-cache.js both FAIL on a clean clone.

### COMPAT-C3: verify-plugin-structure.js encodes stale inventory counts (CRITICAL) — Confidence: HIGH
- Location: `scripts/verify-plugin-structure.js:71-90`
- Issue: Hardcoded `EXPECTED = { SKILLS: 48, COMMANDS: 17, AGENTS: 5, RULES: 8, HOOKS_JS: 9 }` and `EXPECTED_HOOK_FILES` includes `verify-e2e.js`. Filesystem reality: 52 skills, 19 commands, 7 agents, 9 rules, 7 hook `.js` files. `verify-e2e.js` lives at `scripts/verify-e2e.js`, not `hooks/verify-e2e.js`. Running the verifier yields 0/6 PASS on a clean checkout.
- Fix: Update expected counts to match actual inventory AND align with plugin.json description (52/19/7/7/9). Replace the hardcoded `EXPECTED_HOOK_FILES` with a dynamic read of `hooks/hooks.json` so drift is impossible, or remove `verify-e2e.js` from the list. Same drift exists in `scripts/verify-plugin.sh:89` (expects 15 commands).
- Impact: the one self-validation gate that exists is red from the moment of the schema freeze (commit 75a3fc6).

### COMPAT-C4: verify-plugin-structure.js contradicts its own docstring and manifest (CRITICAL) — Confidence: HIGH
- Location: `scripts/verify-plugin-structure.js:7-10` (docstring says "45 skill directories", "15 command .md files", "5 agent .md files", "8 rule .md files", "9 hook .js files") vs line 71 (`SKILLS: 48`) vs actual (`52/19/7/9/7`). README/plugin.json describes "52 skills, 19 commands, 7 hooks, 7 agents, 9 rules". Four different inventories in four places.
- Issue: there is no single source of truth for the component count. Each release silently drifts further; the public description in plugin.json is the only one currently correct.
- Fix: Make the verifier derive counts from `.claude-plugin/plugin.json` (once COMPAT-C2 is fixed) or from filesystem scan, not from hardcoded expected-totals. Delete the numeric docstring claims; replace with "matches filesystem inventory".

### TEST-H1: validate-pkg.js allows package to publish without engines field being Node-compatible (HIGH) — Confidence: MEDIUM
- Location: `scripts/validate-pkg.js:5`
- Issue: Required list includes `engines` but doesn't assert `engines.node` matches what the shipped code actually uses. Shipped code is clean (no top-level await, no global fetch, spot-checked in parallel) so Node 16 is currently fine — but there's no guard preventing a future PR from adding `fetch()` or top-level `await` that breaks Node 16 consumers silently.
- Fix: Add `if (!p.engines.node) throw new Error('engines.node required')` and optionally a node-version lint step that scans for `fetch(`, `Array.prototype.at`, `structuredClone`, top-level `await`.

### TEST-H2: verify-registration.js + verify-cache.js require a live install to pass (HIGH) — Confidence: HIGH
- Location: `scripts/verify-registration.js:7` (reads `~/.claude/installed_plugins.json`), `scripts/verify-cache.js:7` (reads `~/.claude/plugins/cache/validationforge/validationforge/1.0.0/.claude-plugin/plugin.json`)
- Issue: Both scripts fail with FAIL on any system that hasn't run `install.sh`. They belong in post-install verification, not CI pre-publish. If CI runs them before install they always red; if CI runs them never they're dead code. No indication which bucket they're in.
- Fix: Rename to `scripts/postinstall-verify-*.js` or gate behind an `--after-install` flag. Document in CONTRIBUTING.md which verifier runs at which lifecycle stage.

### TEST-H3: verify-hook-exists.js checks wrong install path (HIGH) — Confidence: HIGH
- Location: `scripts/verify-hook-exists.js:3`
- Issue: `const path = process.env.HOME + '/.claude/hooks/block-test-files.js'`. Neither install.sh nor postinstall.js writes hooks to `~/.claude/hooks/`. install.sh writes to `~/.claude/plugins/validationforge/hooks/`, postinstall.js does not write hooks at all (only rules). This script will FAIL on every legitimate install because the path it checks is not where VF lives.
- Fix: Point to the correct install location, or read `~/.claude/installed_plugins.json` to resolve the install path dynamically (same pattern `verify-registration.js` uses).

### COMPAT-H4: standard/strict profile files diverge from STANDARD_DEFAULTS on `reject_empty_evidence` (HIGH) — Confidence: HIGH
- Location: `config/{standard,strict,permissive}.json` (no `reject_empty_evidence` key anywhere) vs `hooks/lib/resolve-profile.js:54` (STANDARD_DEFAULTS includes `reject_empty_evidence: true`) vs `hooks/evidence-quality-check.js:51` (calls `ruleEnabled(profile, 'reject_empty_evidence')`).
- Issue: config schema is incomplete — `reject_empty_evidence` is consulted by the empty-evidence blocking branch but not present in any profile JSON. `ruleEnabled` returns `rules[ruleName] !== false`, so a missing rule resolves to `true`, and empty evidence files are hard-blocked under `strict`/`standard`. The behavior is correct *by accident*; any user who disables via config by adding `"reject_empty_evidence": false` will work, but nobody knows that key exists because it's not in the shipped schema. Users who copy `strict.json` expecting the documented rules will have undocumented behavior.
- Fix: Add `reject_empty_evidence: true/true/false` to the three profile JSONs. Same audit needed for every rule name `resolve-profile.js` ships with vs what appears in `config/*.json`.

### COMPAT-H5: bin/vf.js help output doesn't match actual command surface (HIGH) — Confidence: HIGH
- Location: `bin/vf.js:214-230` lists 8 slash commands.
- Issue: README/plugin.json documents 19 commands. `vf help` omits: `validate-dashboard`, `validate-consensus`, `validate-team-dashboard`, `vf-telemetry`, and all 7 `forge-*` commands. Users running `vf help` get a false impression of available tooling.
- Fix: Generate the command list from `commands/*.md` at runtime, or at minimum list every shipped slash command.

### TEST-M1: evidence-gate-reminder emits `hookSpecificOutput.hookEventName: "PreToolUse"` but fires on TodoWrite/TaskUpdate (MEDIUM) — Confidence: MEDIUM
- Location: `hooks/evidence-gate-reminder.js:59`
- Issue: Claude Code's canonical PreToolUse context injection returns `additionalContext` nested under a `hookSpecificOutput` with `hookEventName: "PreToolUse"`. hooks.json correctly registers this under the `PreToolUse` array with matcher `TodoWrite|TaskUpdate`. `TaskUpdate` is not a stock Claude Code tool — it's a custom task manager (documented in the hook). Users without that custom tool get zero behavior from this hook for `TaskUpdate` events. Worth a README note; not a blocker.
- Fix: Either rename matcher to `TodoWrite` only (stock CC), or document in the hook's README/comments that TaskUpdate requires a custom task-manager tool.

### COMPAT-M2: permissive.json defangs ai_analysis silently (MEDIUM) — Confidence: MEDIUM
- Location: `config/permissive.json:33`
- Issue: `ai_analysis.enabled = false` in permissive, `true` in strict/standard. Any skill or command that reads this config (grep for `ai_analysis` consumers) behaves differently on a permissive install with no warning. If `/validate` runs `ai_analysis`-dependent steps, the permissive user silently loses phase 3.5 of the pipeline.
- Fix: Document which features are disabled per profile in README, or move AI-analysis enable/disable out of the enforcement profile (it's an orthogonal concern).

### COMPAT-M3: Opencode fork uses a different patterns.ts and will drift (MEDIUM) — Confidence: MEDIUM
- Location: `.opencode/plugins/validationforge/` (contains own `patterns.ts`), `hooks/lib/patterns.js` (transpiled JS in Claude-side), `scripts/sync-opencode.sh` (symlinks skill/ and command/ only).
- Issue: sync-opencode.sh symlinks `skills/` and `commands/` into `.opencode/skill/` and `.opencode/command/`, but does NOT sync hook logic. The opencode fork maintains its own `patterns.ts` and `index.ts`. Any change to `hooks/lib/patterns.js` (MOCK_PATTERNS, TEST_PATTERNS, BUILD_PATTERNS) won't reach opencode. Review: `scripts/verify-opencode-plugin.sh` exists but only checks file presence, not content parity.
- Fix: Add a checksum/content comparison in verify-opencode-plugin.sh, or refactor to compile a single `patterns.ts` to both `.js` and `.d.ts` for both targets. Alternatively, document this as known drift and mark opencode as best-effort.

### COMPAT-M4: COMMANDS.md doesn't document `vf` CLI subcommands (MEDIUM) — Confidence: MEDIUM
- Location: `COMMANDS.md` (4 heading hits, zero references to `vf status`, `vf install-rules`, `vf --version`, `vf help`)
- Issue: The `vf` binary shipped via `package.json` `bin` field has 4 subcommands — none documented in COMMANDS.md. Users who `npm install -g validationforge` get a CLI they can't discover without reading `bin/vf.js` or running `vf help`. The spec says "CLI stability — bin/vf.js subcommands — are they documented in COMMANDS.md?" Answer: no.
- Fix: Add a `## CLI (`vf`)` section to COMMANDS.md duplicating the help text in bin/vf.js (or reference it).

### TEST-L1: DISABLE_OMC kill-switch is cross-tool leakage (LOW) — Confidence: HIGH
- Location: `hooks/block-test-files.js:29`, `hooks/mock-detection.js:26`, `hooks/evidence-quality-check.js:26`
- Issue: `DISABLE_OMC=1` is an oh-my-claudecode kill-switch. VF hooks honor it, but that means a user running OMC on the same box disables VF enforcement as a side-effect. VF also has its own `VF_SKIP_HOOKS` which is cleaner. Three hooks implement this; the other four (evidence-gate-reminder, validation-not-compilation, completion-claim-validator, validation-state-tracker) do not — inconsistent.
- Fix: Either remove the `DISABLE_OMC` check from VF hooks (leak between unrelated projects), or apply it uniformly to all 7. Prefer the former since `VF_SKIP_HOOKS` already covers the legitimate use case.

### TEST-L2: verify-plugin-structure.js lies about "patterns.js helper" (LOW) — Confidence: HIGH
- Location: `scripts/verify-plugin-structure.js:229-231`
- Issue: Filter excludes `patterns.js` from hook count, but actual `patterns.js` now lives at `hooks/lib/patterns.js`, not `hooks/patterns.js`. The exclusion filter no longer matches anything. Cosmetic — the count happens to be correct — but the inherited scaffolding is stale.
- Fix: Remove the dead filter; it's load-bearing for nothing.

## Strengths
- Hook-protocol separation is correct where it matters: `block-test-files.js` uses `permissionDecision: "deny"` JSON for blocking (PreToolUse best-practice), and PostToolUse hooks use `exit(2)` + stderr (canonical) — the only reason enforcement is dead is COMPAT-C1's shell `|| true`, not hook internals.
- `resolve-profile.js` is a clean rewrite of the legacy config-loader; memoization, frozen defaults, env precedence all sensible. The deprecation shim at `config-loader.js` is exactly the right compatibility move.
- install.sh is security-hardened: github source allowlist, atomic `ln -sfn` with ownership check, temp-file+os.replace JSON write under `flock`. Uninstall honors a manifest so it doesn't nuke user-authored `vf-*.md` rules.
- Evidence path is consistent — every hook, script, and config uses `e2e-evidence/` as the root. No `.vf/evidence/` drift.
- Node 16 engine contract is actually honored: spot-checked hooks/, bin/, scripts/ — no `fetch()`, no top-level await, no Node 18+ APIs.

## Unresolved questions
- Is COMPAT-C2 (missing commands/skills/agents declarations in plugin.json) intentional? Claude Code's plugin loader spec is evolving; if the platform now infers from directory layout the finding drops to informational, but the verifier scripts still expect explicit declarations, so the internal contract is still broken.
- Does the benchmark harness (`benchmark/transcript-analyzer.js`) actually run against a session captured with `|| true` defanged? If it parses a real Claude Code transcript, confirming COMPAT-C1 is trivially provable from recent benchmark runs.
- Is `DISABLE_OMC` a deliberate bridge to OMC ecosystem or an accidental copy? The VF CLAUDE.md doesn't mention it; three of seven hooks honor it. Worth a design decision.
- Why does `hooks/hooks.json` use `matcher: "TodoWrite|TaskUpdate"` if TaskUpdate is a custom tool? Should VF ship the task-manager tool or drop the matcher half?

STATUS: DONE_WITH_CONCERNS
Summary: COMPAT-C1 (hooks.json `|| true`) and COMPAT-C2 (missing plugin.json declarations) are silent-plugin-failure class issues; verify-plugin-structure.js (C3/C4) red on main. Cosmetic drift otherwise modest. 15 findings total.
