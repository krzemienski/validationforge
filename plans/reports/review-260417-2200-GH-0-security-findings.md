# Security + Dependencies Review — 260417-2200

## Summary
- Critical: 0, High: 3, Medium: 5, Low: 4
- Overall security posture: solid for a plugin distribution — explicit hardening in `install.sh`, no external runtime deps, hooks are read-only process scripts. Main risks are around shell/node code that runs during install/uninstall, a command-injection surface in `generate-report.js`, telemetry value escaping, and a handful of npm-publish hygiene gaps.

## Findings

### SEC-H1: `generate-report.js` passes attacker-influenced path to shell via `execSync` (HIGH) — Confidence: HIGH
- Location: `scripts/generate-report.js:624-636` (`openInBrowser`), called with `outputFile` argv at `:13`.
- Issue: `execSync(\`open "${file}" 2>/dev/null\`)` interpolates `outputFile` (from `process.argv[3]`) into a shell string with only double-quote wrapping. A filename containing `"` or `$(...)` / `\`` executes arbitrary commands (e.g. `node scripts/generate-report.js ev 'dash"; rm -rf ~; "'`). The earlier `validatePath()` guards only `evidenceDir` (argv[2]); `outputFile` (argv[3]) is never validated, nor is the computed default (`path.join(evidenceDir, 'dashboard.html')` — which, once `evidenceDir` is "safe", would be safe, but the override path is not).
- Fix: use `execFile('open', [file])` / `execFile('xdg-open', [file])`, or reuse `validatePath(outputFile)` before shelling.
```diff
- execSync(`open "${file}" 2>/dev/null`);
+ const { execFileSync } = require('child_process');
+ execFileSync('open', [file], { stdio: 'ignore' });
```

### SEC-H2: `telemetry.sh` assembles JSON via string concatenation — values unescaped (HIGH) — Confidence: HIGH
- Location: `scripts/telemetry.sh:53-78`
- Issue: `EVENT_NAME`, `ANON_ID`, and all `key=value` args are appended verbatim to the JSON body (`"${key}":"${val}"`). Any `"` or `\` in a value produces malformed JSON or an injection into the payload consumed by the telemetry endpoint. Worse, `key` is taken from `"${arg%%=*}"` without whitelisting — a key like `foo","injected":"x` slips a controlled field into the JSON. Argument-supplied keys/values flow from caller scripts; any caller that forwards user input here is an injection sink.
- Also: `DEFAULT_ENDPOINT` is read from the user's `~/.claude/.vf-config.json` without domain pinning. A tampered config can exfiltrate to any `https://` host (see SEC-M2).
- Fix: build the payload in Python/jq with proper JSON escaping, or at minimum validate keys with `[A-Za-z_][A-Za-z0-9_]*` and strip `"` / `\` / control chars from values. Apply the same `json_escape` helper already defined in `scripts/generate-dashboard.sh:123-130`.

### SEC-H3: Hook `|| true` in `hooks.json` silently swallows deny decisions on hook crash (HIGH) — Confidence: MEDIUM
- Location: `hooks/hooks.json:9, 18, 29, 33, 37, 46, 50`
- Issue: Every hook command is wrapped `node "${CLAUDE_PLUGIN_ROOT}/hooks/..." || true`. If `node` crashes before reading stdin, the pipeline returns 0 and the tool call proceeds. The only path that produces a `"deny"` is a clean JSON write to stdout before exit 0. A malformed/malicious `tool_input` that makes the hook throw during `require('./lib/patterns')` (e.g. plugin files partially synced) fails open — the "block-test-files" Iron Rule is bypassed.
- Additional exposure: many hook bodies catch all errors and `process.exit(0)` in the `catch` (e.g. `block-test-files.js:82-84`, `completion-claim-validator.js:89-92`). Combined with `|| true`, there is no failure path that blocks the tool call.
- Fix: drop `|| true`, or explicitly convert exceptions into `exit 2` for enforcement hooks so a broken hook fails closed rather than open. Document the trust model: the hooks are a safety net; install pipeline already fails the install when files are missing.

### SEC-M1: `sync-opencode.sh` creates symlinks with `ln -sf` without refusing pre-existing non-symlinks (MEDIUM) — Confidence: HIGH
- Location: `scripts/sync-opencode.sh:13-31`
- Issue: `for skill_dir in "$PROJECT_ROOT"/skills/*/ ; do ... if [ ! -L "$target" ]; then ln -sf "../../skills/$name" "$target"; fi; done`. The guard `[ ! -L ]` is true when `$target` is a regular file or directory — and `ln -sf` will then happily unlink the directory and replace it with a symlink. A pre-planted file or directory at `.opencode/skill/<name>` is silently overwritten. Compare the safe pattern in `install.sh:89-102` which explicitly refuses to replace non-symlinks.
- Fix:
```diff
- if [ ! -L "$target" ]; then
-   ln -sf "../../skills/$name" "$target"
- fi
+ if [ -e "$target" ] && [ ! -L "$target" ]; then
+   echo "REFUSE: $target exists and is not a symlink" >&2; continue
+ fi
+ ln -sfn "../../skills/$name" "$target"
```
Use `-n` to avoid following an existing symlink to a dir and creating a nested link.

### SEC-M2: Telemetry endpoint override lacks domain pinning (MEDIUM) — Confidence: HIGH
- Location: `scripts/telemetry.sh:35-47` (also `config/strict.json:28-31`)
- Issue: `ENDPOINT=$(jq -r '.telemetry.endpoint' ...)`; validated only as `https://*`. Anyone who can edit `~/.claude/.vf-config.json` (malware with user-level write) can redirect telemetry to `https://attacker.example/collect` — along with `anonymousId` and any key=value the caller attaches. `install.sh` does not set `telemetry.enabled=true` by default, which limits blast radius, but the override path is still a weak link.
- Fix: Pin to `*.validationforge.dev` (or a small allow-list) unless an explicit `VF_ALLOW_ALT_TELEMETRY=1` is set, mirroring the existing `VF_ALLOW_ALT_SOURCE` pattern in `install.sh:42-47`.

### SEC-M3: `evidence-clean.js` lock file treats dead-PID-but-recent-lock as live (MEDIUM) — Confidence: MEDIUM
- Location: `scripts/evidence-clean.js:127-149`
- Issue: The block says:
  - live PID → abort (good)
  - dead PID + age > 1h → warn, proceed (good)
  - dead PID + age ≤ 1h → abort (conservative)

  The conservative path is reasonable, but there is no PID-ownership check. On a shared multi-user host, PID number can be reused by an unrelated process from another user, causing `process.kill(pid, 0)` to succeed against a user who doesn't own the VF run — and cleanup hangs indefinitely. Lower severity because VF is intended for single-user developer machines, but worth a note.
- Fix: either (a) record the command line alongside PID and verify it matches, or (b) after 2× retention window age, force-override regardless of live-pid state.

### SEC-M4: `postinstall.js` replaces existing directory at `~/.claude/plugins/validationforge` via `fs.rmSync(..., { recursive: true, force: true })` (MEDIUM) — Confidence: HIGH
- Location: `scripts/postinstall.js:149-152`
- Issue: If the user already has a real directory at `~/.claude/plugins/validationforge` (e.g. a previous git-clone install from `install.sh`), `postinstall.js` silently `rm -rf`s it and replaces with a symlink. This is data loss if the dir contained any local customization or uncommitted modifications. `install.sh` is more careful (`ln -sfn` with ownership check), but the npm path is not.
- Fix: mirror `install.sh`'s guard — refuse to replace anything that isn't already an VF symlink/pointer; require `VF_ALLOW_OVERWRITE=1` to force. At minimum, log the path being destroyed rather than doing it silently.

### SEC-M5: `.npmignore` allow-lists by omission — package may ship unexpected content (MEDIUM) — Confidence: MEDIUM
- Location: `.npmignore` (full file) + `package.json:33-46` (`files` array)
- Issue: `package.json` has an explicit `files` array, which is the primary filter — good. `.npmignore` is redundant when `files` is present, but it lists only a handful of excludes. However, the `files` array includes `scripts/` wholesale; that directory contains `scripts/telemetry.sh`, `scripts/consensus-aggregate.sh`, `scripts/collect-team-metrics.sh` and ~30 other scripts that are not all needed at runtime, plus anything that lands in `scripts/benchmark/results/`. `benchmark/results/` is in `.gitignore` but NOT in `.npmignore`. Risk: if a developer ever runs benchmarks pre-publish, `benchmark/results/*.json` could leak into the tarball.
- Fix: add `benchmark/results/` and `scripts/benchmark/results/` to `.npmignore`, and consider narrowing `files: ["scripts/"]` to `scripts/postinstall.js`, `scripts/evidence-clean.js`, and whatever the published CLI actually invokes. Run `npm pack --dry-run` in CI and snapshot the file list.

### SEC-L1: Shell injection surface in `verify-plugin.sh` via `node -e` interpolation (LOW) — Confidence: MEDIUM
- Location: `scripts/verify-plugin.sh:36-48, 77-88, 94-105`
- Issue: `node -e "...JSON.parse(fs.readFileSync('$INSTALLED_JSON'...`. `$INSTALLED_JSON` is `$HOME/.claude/installed_plugins.json` — fine in normal use, but if `$HOME` contained a `'` the interpolation would break out of the single-quoted JS string. Very unlikely in practice, but the pattern is cargoed into `setup-plugin-cache.sh` and other scripts. Prefer passing via argv (`node -e '...' -- "$INSTALLED_JSON"` with `process.argv[2]`).

### SEC-L2: `scripts/evidence-cleanup.sh` uses `find -mtime` — mtime is attacker-forgeable but low-impact (LOW) — Confidence: LOW
- Location: `scripts/evidence-cleanup.sh:125-131`
- Issue: `find "$EVIDENCE_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +"$RETENTION_DAYS"`. Any process that can write evidence can `touch -d ...` to make a dir either look fresh (avoid cleanup) or old (force cleanup). Only the user can do this in normal operation; note for completeness. Impact is local DoS on evidence at worst.

### SEC-L3: `completion-claim-validator.js` reads evidence dir based on untrusted `data.cwd` (LOW) — Confidence: MEDIUM
- Location: `hooks/completion-claim-validator.js:22-35`
- Issue: The hook consults `data.cwd` (attacker-influenceable via the hook JSON payload) in the fallback chain for evidence directory resolution. `CLAUDE_PROJECT_ROOT` takes precedence, so normal CC runs are fine, but any path Claude Code writes into `data.cwd` is trusted — a malformed/adversarial hook payload can point the gate at a pre-seeded directory with fake "fresh" evidence to pass completion checks. Since the hook *prevents* a loose completion claim, the attacker gain is to weaken the gate, not escalate.
- Fix: if `CLAUDE_PROJECT_ROOT` is unset, fall through to `process.cwd()` only — skip `data.cwd` to drop one injection vector.

### SEC-L4: `mock-detection.js` truncates input at 200KB — bypass by payload padding (LOW) — Confidence: HIGH
- Location: `hooks/mock-detection.js:45-48`
- Issue: Files over 200KB are scanned only in their first 200KB. An adversary writing `jest.mock(` at offset 200KB+1 evades the scan. Comment explicitly calls this out as a ReDoS mitigation, which is a fair tradeoff, but document it — someone will try the padding trick.
- Fix: either scan the tail as well, or log/warn when truncation happens so the user is aware. Also note in `rules/no-mocks.md`.

## Strengths
- `install.sh` hardening is exemplary: HTTPS allowlist, `$HOME` confinement, `ln -sfn` atomic symlink replacement with ownership check, Python fcntl-based atomic JSON write for `installed_plugins.json`, and a manifest-based uninstall that won't destroy unrelated `vf-*.md` rules (the manifest fallback warning at `uninstall.sh:97` is well-placed).
- Zero runtime dependencies — only `typescript` as dev-dep, no `postinstall`-time network calls from deps. Lockfile present with integrity hashes pinned to specific SHA-512.
- Hooks are one-shot Node processes that read stdin, do local fs work, and exit — no network, no `eval`, no dynamic `require`. Env overrides (`DISABLE_OMC`, `VF_SKIP_HOOKS`) are checked at the top of each hook.
- Evidence cleanup and dashboard generation both reject absolute paths and `..` traversal (`evidence-cleanup.sh:19-28`, `evidence-collector.sh:10-13`, `generate-dashboard.sh:73-82`).
- Temp directories use `mktemp -d` with proper `trap 'rm -rf "$TMP_WORK"' EXIT` cleanup (`generate-dashboard.sh:142`).
- `resolve-profile.js` freezes `STANDARD_DEFAULTS` via `Object.freeze` — defends against mutation in-process.

## Unresolved questions
- Is `scripts/` intended to be user-runnable post-install, or is it dev-only? If dev-only, narrow `files` in `package.json` to just the scripts `postinstall.js` / `bin/vf.js` depend on. If user-runnable, every `.sh` in there is part of the plugin's security surface and needs full hardening (a third of them don't validate argv).
- Does `CLAUDE_PLUGIN_ROOT` get set by Claude Code in every hook invocation? `resolve-profile.js:31` has a `..` fallback. If CC ever invokes hooks with an unexpected cwd and no env var, `CONFIG_DIR` resolves relative to the hook file itself — which is fine. Confirm the contract.
- The `marketplace.json` / `plugin.json` claim distinct component counts ("52 skills, 19 commands" vs repo-expected "48 skills, 17 commands" from `verify-plugin-structure.js`). Drift between advertised and actual counts isn't a security bug, but it's a provenance concern if users verify the manifest.

---

STATUS: DONE
Summary: 3 HIGH (shell injection in `generate-report.js` open-in-browser, JSON injection in `telemetry.sh`, hooks fail-open via `|| true`), 5 MEDIUM, 4 LOW. No CRITICAL. Install/uninstall hardening is strong; the weak spots are in secondary scripts and telemetry plumbing.
