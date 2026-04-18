# Quality + Simplification Review — 260417-2200

Reviewer: code-reviewer (quality + simplification lane)
Scope: runtime code (hooks, scripts, bin, install/uninstall), declarative artifacts (rules, commands, agents, skills — sampled), documentation drift.

## Summary
- Critical: 0
- High: 5
- Medium: 8
- Low: 5

## Inventory cross-check (filesystem vs docs vs verification)

| Artifact        | FS count | README claim | vf.js claim       | verify-plugin-structure.js claim | plugin.json declares |
|-----------------|----------|--------------|-------------------|----------------------------------|----------------------|
| skills/         | 52       | 52           | —                 | 48 (FAIL)                        | none                 |
| commands/*.md   | 19       | 19           | 9 in help text    | 17 (FAIL)                        | none                 |
| agents/*.md     | 7        | 7            | —                 | 5 (FAIL)                         | none                 |
| rules/*.md      | 9        | 9            | **8 required**    | 8 (FAIL)                         | none                 |
| hooks/*.js      | 7        | 7 registered | —                 | 9 + config-loader/verify-e2e (FAIL) | 5 wired in hooks.json |

Observed failures running `node scripts/verify-plugin-structure.js`: **0/6 checks pass.**
Observed success running `node scripts/verify-hooks.js`: **7/7 hooks pass** (hooks themselves work).

## Findings

### QUAL-H1: `verify-plugin-structure.js` is stale — 0/6 checks pass against current tree (HIGH) — Confidence: HIGH
- Location: `scripts/verify-plugin-structure.js:71-90`
- Issue: hard-coded `EXPECTED = { SKILLS: 48, COMMANDS: 17, AGENTS: 5, RULES: 8 }` and `EXPECTED_HOOK_FILES` includes `config-loader.js` (now under `hooks/lib/`) and `verify-e2e.js` (now in `scripts/`). Running the script returns FAIL on every check. Also expects `plugin.json` to contain keys `commands/skills/agents/rules/hooks` — **plugin.json has none of those keys** (see QUAL-H2).
- Fix: either (a) delete this script entirely — it duplicates what a trivial `ls | wc -l` would tell you and is currently wrong; or (b) update EXPECTED constants, remove the plugin.json key check (or align to reality), and drop the moved-file references. DELETE is preferred (YAGNI — `verify-hooks.js` already validates behavior).

### QUAL-H2: plugin.json does not declare any artifact directories, breaking documented contract (HIGH) — Confidence: HIGH
- Location: `.claude-plugin/plugin.json:1-23`
- Issue: file is pure metadata (`name`, `version`, `description`, `author`, `homepage`, `repository`, `license`, `keywords`). `verify-plugin-structure.js:77` expects keys `commands, skills, agents, rules, hooks`. `scripts/verify-cache.js:18` expects `commands` and `skills`. Docs across the repo (e.g. `docs/onboarding-walkthrough.md:120`) refer to plugin.json as the source of truth.
- Fix: either (a) declare the directories explicitly in plugin.json (one-line addition: `"commands": "./commands", "skills": "./skills", …`) — matches what Claude Code's loader expects per your own `verify-*.js` scripts, or (b) delete the verifiers that assume this shape. Option (a) is the cheaper fix and removes the drift permanently.

### QUAL-H3: vf.js `REQUIRED_RULES` is missing `consensus-engine` — /vf status underreports rule installation (HIGH) — Confidence: HIGH
- Location: `bin/vf.js:57-66`
- Issue: hard-coded 8-entry list vs 9 rule files on disk (`rules/consensus-engine.md` exists, added in "phase-0 freeze shared schemas"). `vf status` will show `Rules: 8/8 installed` after `install-rules`, silently hiding that consensus-engine.md was copied. Users upgrading from an earlier cut will never know they have an additional rule.
- Fix: `REQUIRED_RULES` should be derived from `fs.readdirSync(RULES_SOURCE).filter(f => f.endsWith('.md')).map(f => path.basename(f, '.md'))`. Never hand-maintain a mirror of a directory listing. One line of code removes the drift class permanently.

### QUAL-H4: Double source of truth for hook config — `config-loader` shim still imported by 4 hooks (HIGH) — Confidence: HIGH
- Location: `hooks/lib/config-loader.js` (compat shim), `hooks/lib/resolve-profile.js` (canonical). Consumers split 4/3:
  - config-loader → `evidence-gate-reminder.js`, `completion-claim-validator.js`, `validation-not-compilation.js`, `validation-state-tracker.js`
  - resolve-profile → `block-test-files.js`, `mock-detection.js`, `evidence-quality-check.js`
- Issue: the comment at the top of `config-loader.js` says "DEPRECATED — retained only as a thin compat shim" but no follow-up has migrated the callers. Two APIs for the same thing: `loadConfig().getHookConfig(name)` vs `resolveProfile() + hookState(profile, name)`. The split also mirrors a semantic split — the 4 legacy hooks only support `enabled|warn|disabled`, the 3 newer hooks also honor per-rule flags (`ruleEnabled(profile, 'block_test_files')`). Hook behavior is therefore inconsistent across the set for the same "permissive" profile.
- Fix: migrate the 4 legacy hooks to `resolveProfile/hookState/ruleEnabled` and delete `config-loader.js`. Deletion is safe — nothing outside `hooks/` imports it (grep confirmed). Removes ~20 lines and one public API surface.

### QUAL-H5: Hooks + rules define the same patterns/thresholds in two languages (HIGH) — Confidence: MEDIUM
- Location: `hooks/lib/patterns.js` (TEST_PATTERNS, MOCK_PATTERNS, BUILD_PATTERNS, COMPLETION_PATTERNS, VALIDATION_COMMAND_PATTERNS) vs `rules/validation-discipline.md` which lists forbidden patterns in prose, and `rules/no-mocks.md` at project root (in CLAUDE.md). README.md §200 claims "Blocks 15 test/mock patterns" — actual count in `TEST_PATTERNS` is 15, in `MOCK_PATTERNS` is 30. Counts are already drifting.
- Fix: pick ONE source. Option (a) keep `patterns.js` authoritative, auto-generate the rule snippet from it in a postinstall/doc-gen step; option (b) if that's too much machinery, stop quoting specific counts in README and rules and just say "see `hooks/lib/patterns.js`". Option (b) is cheaper and still correct a year from now.

### QUAL-M1: `config-loader.js` and `verify-e2e.js` moved but verifiers + docs still hunt for old paths (MEDIUM) — Confidence: HIGH
- Location: `scripts/verify-plugin-structure.js:80-90` lists `config-loader.js` and `verify-e2e.js` under `hooks/`. Actual paths: `hooks/lib/config-loader.js` and `scripts/verify-e2e.js`.
- Fix: fold this into QUAL-H1 (delete the script). If retained, update EXPECTED_HOOK_FILES to current paths.

### QUAL-M2: `e2e-testing`, `e2e-validate`, `web-testing`, `web-validation`, `playwright-validation` look duplicative (MEDIUM) — Confidence: MEDIUM
- Location: `skills/e2e-testing/`, `skills/e2e-validate/`, `skills/web-testing/`, `skills/web-validation/`, `skills/playwright-validation/`
- Issue: five skills with overlapping-by-name intent. The README/SKILLS.md don't make the distinction clear. YAGNI: likely at least 2 are redundant or are stale drafts from different planning rounds. Users picking a skill will guess.
- Fix: audit the five SKILL.md frontmatters side-by-side. Either (a) merge the overlaps, or (b) rename to make the split obvious (`web-e2e-playwright`, `web-e2e-chrome-devtools`, etc.). Do NOT keep all five unless each has a clearly distinct trigger context documented in SKILLS.md.

### QUAL-M3: TECHNICAL-DEBT.md itself acknowledges documented-but-unimplemented features (MEDIUM) — Confidence: HIGH
- Location: `TECHNICAL-DEBT.md:§3.1` CONSENSUS Engine "NOT IMPLEMENTED", §3.2 FORGE Engine "NOT IMPLEMENTED", §3.3 benchmark scoring "UNVERIFIED", §3.4 evidence retention "NOT IMPLEMENTED"
- Issue: README/CLAUDE.md advertise `/validate-consensus`, `/forge-execute`, `/validate-benchmark`, `/validate-sweep` as shipping features with full inventory counts. TECHNICAL-DEBT.md admits they are not actually implemented. The product claims 7 agents and 19 commands; many of those command .md files execute prose, not code. Gap between "file exists" and "feature works".
- Fix: README and CLAUDE.md should downgrade unimplemented commands to "Planned" or move to a separate "Roadmap" section. Alternative: delete the command .md files for features that don't work and re-add when they ship. Present state misleads users who read the README.

### QUAL-M4: install.sh hard-codes `VF_VERSION=1.0.0` as git ref — will break on any tag bump (MEDIUM) — Confidence: HIGH
- Location: `install.sh:21-22`, `scripts/verify-cache.js:6` (`'1.0.0'` in cache path)
- Issue: `VF_REF="${VF_REF:-v${VF_VERSION}}"` and a literal `'1.0.0'` in `verify-cache.js`. No `v1.0.0` tag exists yet on `origin` (still on `main`/`insights/phase-0-schema-freeze`). When a tag finally lands, every other place that mirrors the version (package.json, plugin.json, install.sh default) has to be hand-updated. Easy to miss.
- Fix: (a) install.sh should default to `main` for un-tagged installs or read version from package.json; (b) `verify-cache.js` should read cache path from package.json version; (c) consider a `scripts/bump-version.js` single-point-of-truth updater. Minimum: remove the literal `'1.0.0'` from `verify-cache.js`.

### QUAL-M5: Verify/integration scripts proliferate — 11 verify-* scripts, unclear which is canonical (MEDIUM) — Confidence: HIGH
- Location: `scripts/verify-cache.js`, `verify-e2e.js`, `verify-hook-exists.js`, `verify-hooks.js`, `verify-opencode-plugin.sh`, `verify-plugin-structure.js`, `verify-plugin.sh`, `verify-publish-readiness.js`, `verify-registration.js`, `verify-setup.sh`, `validate-pkg.js`
- Issue: no single entrypoint. Some overlap heavily (`validate-pkg.js` and `verify-publish-readiness.js` both check `package.json.files`). `verify-hook-exists.js` is 8 lines checking a single file under `~/.claude/hooks/` that isn't even this repo's install path. `verify-plugin-structure.js` currently fails across the board (QUAL-H1).
- Fix: consolidate to ≤3 scripts: (a) `verify-package.js` for publish-time checks, (b) `verify-hooks.js` for hook behavior (keep — it works), (c) `verify-install.sh` for post-install health check. Delete the rest. Reference: `verify-hook-exists.js`, `verify-registration.js`, `verify-cache.js` (all ≤28 lines) can be absorbed into a single post-install checker. Saves ~7 scripts, keeps behavior.

### QUAL-M6: install.sh and postinstall.js install the same rules with different naming conventions (MEDIUM) — Confidence: HIGH
- Location: `scripts/postinstall.js:75-86` copies `{name}.md → ~/.claude/rules/vf-{name}.md`. `bin/vf.js:179` does the same for `--global` but uses bare `{name}.md` for local.
- Issue: install.sh (L27) and postinstall.js both write to `~/.claude/rules/` — but the rule-filename prefix behavior is inconsistent across install paths. Local project installs have no prefix, global has `vf-` prefix, and `vf.js status` looks for BOTH. Lives and works, but any future rule-file authored outside this convention will silently not be counted.
- Fix: pick one prefix convention globally. Recommend always `vf-` prefixed (both local and global) so there's no branching in `vf status`. Deletes one branch in both `install-rules` and `status`.

### QUAL-M7: scripts/generate-report.js is 640 LOC — flagged by `philosophy.md` 800-line ceiling and 200-400 target (MEDIUM) — Confidence: MEDIUM
- Location: `scripts/generate-report.js` (640 lines)
- Issue: single file owns HTML template, evidence discovery, path validation, base64 inlining, and journey directory walking. Exceeds the "200-400 target, 800 max" from `philosophy.md`. Risk: any dashboard customization requires touching the whole file.
- Fix: extract (a) `scripts/lib/report-template.js` (HTML), (b) `scripts/lib/evidence-walker.js` (discovery), (c) keep `generate-report.js` as an orchestrator under 200 LOC. Simple mechanical split, no behavior change.

### QUAL-M8: Git-ignored build/work dirs NOT in .gitignore — leak into repo (MEDIUM) — Confidence: HIGH
- Location: `.gitignore` does not list: `skill-audit-workspace/`, `worktree-merge-evidence/`, `progress.txt`, `build-progress.txt`, `logs/`, `.omc/`, `.opencode/`, `.remember/`, `.ruff_cache/`, `plans/reports/` (debatable — may be intentional)
- Issue: `ls -la` of the repo root shows multiple directories and large `progress.txt` (7.5 KB) and `build-progress.txt` (22 KB) that look like session-local artifacts. They're part of the committed package surface (since they're not ignored) and will ship to npm unless they're specifically excluded. `package.json.files` whitelists, so npm-publish is safe — but `git status` noise and review surface stays polluted.
- Fix: extend `.gitignore` with: `skill-audit-workspace/`, `worktree-merge-evidence/`, `progress.txt`, `build-progress.txt`, `logs/`, `.ruff_cache/`. Verify whether `.omc/`, `.opencode/`, `.remember/` are intentional before committing.

### QUAL-L1: vf.js help text lists only 9 of 19 commands (LOW) — Confidence: HIGH
- Location: `bin/vf.js:221-230`
- Issue: help enumerates `/validate`, `/validate-plan`, `/validate-audit`, `/validate-fix`, `/validate-ci`, `/validate-team`, `/validate-sweep`, `/validate-benchmark`, `/vf-setup`. Missing: `/validate-consensus`, `/validate-dashboard`, `/validate-team-dashboard`, `/vf-telemetry`, and all 6 `/forge-*` commands.
- Fix: either (a) enumerate them all, or (b) remove the list and point users to README. (b) is lower maintenance (one source of truth again). Same drift class as QUAL-H3.

### QUAL-L2: Hooks inline duplicate env-override boilerplate (LOW) — Confidence: HIGH
- Location: `block-test-files.js:29-31`, `mock-detection.js:26-28`, `evidence-quality-check.js:26-28` all repeat:
  ```js
  if (process.env.DISABLE_OMC === '1') process.exit(0);
  const skipHooks = (process.env.VF_SKIP_HOOKS || '').split(',').map(s => s.trim());
  if (skipHooks.includes(HOOK_NAME)) process.exit(0);
  ```
- Fix: extract `hooks/lib/env-overrides.js` exporting `shouldSkip(hookName)`. Each hook drops 3 lines for 1. Also: the 4 legacy hooks don't honor `DISABLE_OMC` or `VF_SKIP_HOOKS` at all — centralizing this would fix that silent gap (arguably MEDIUM, but listing as LOW since workaround exists via `VF_PROFILE=permissive`).

### QUAL-L3: `VALIDATION_COMMAND_PATTERNS` overmatches `next.*build` and `npm run build` (LOW) — Confidence: MEDIUM
- Location: `hooks/lib/patterns.js:87` — `/npm run (dev|start|build)/i` is in VALIDATION_COMMAND_PATTERNS *and* `next.*build` / `npm.*build` are indirectly caught by BUILD_PATTERNS. A `npm run build` line could fire both `validation-not-compilation` (exit 2 — "build success") AND `validation-state-tracker` (exit 2 — "capture evidence"). Users see two stderr messages for one command.
- Fix: remove `npm run (dev|start|build)` from VALIDATION_COMMAND_PATTERNS. Build-related reminders already ride BUILD_PATTERNS. Dev-server startup can be detected via `localhost` if needed.

### QUAL-L4: `BUILD_PATTERNS` contains both case-sensitive and case-insensitive forms of the same phrase (LOW) — Confidence: HIGH
- Location: `hooks/lib/patterns.js:65-76` — `/build succeeded/i` and `/BUILD SUCCEEDED/` (literal, no `i`).
- Fix: drop the literal `/BUILD SUCCEEDED/` — the `/i` flag already covers it.

### QUAL-L5: CLAUDE.md and README advertise a "consensus-engine (3)" group of skills — physically only one exists with a stub SKILL.md (LOW) — Confidence: HIGH
- Location: CLAUDE.md §Skills: "Consensus Engine (3): consensus-engine, consensus-synthesis, consensus-disagreement-analysis". Filesystem: `skills/consensus-engine/SKILL.md` exists (only 1, not 3); `skills/consensus-synthesis/` and `skills/consensus-disagreement-analysis/` also exist (confirmed — re-check revealed they do). However, `skills/consensus-engine/` contains only `SKILL.md` with no references subdirectory while siblings like `functional-validation` have full reference trees. Likely a stub.
- Fix: either flesh out the skill content or mark the consensus engine group as "preview" in docs. Cross-ref QUAL-M3 (TECHNICAL-DEBT.md §3.1 "CONSENSUS Engine NOT IMPLEMENTED" self-admits this).

## Strengths
- `hooks/lib/resolve-profile.js` is well-structured: clear precedence, memoization, frozen defaults, isolated from fs on fast path. 174 LOC with 99% of the complexity contained. Good target to migrate the remaining hooks onto.
- `verify-hooks.js` is the canonical example of how a verification script should look — behavioral, no hard-coded counts, 7/7 passes with meaningful assertions. Replicate its pattern for other verify-* scripts.
- Hook implementations correctly follow the Claude Code hook output protocol (exit 0 on no-op, exit 2 + stderr for PostToolUse advisory, JSON with `permissionDecision: "deny"` for PreToolUse hard block). Matches `~/.claude/rules/hooks-and-integrations.md` Rule 4.
- `install.sh` is defensive: version-pinned clone, atomic symlink replacement with `ln -sfn`, flock around `installed_plugins.json`, https-allowlisted VF_SOURCE. Security hardening notes in-file are clear.
- The "phase-0 schema freeze" commit message and new rule files (`consensus-engine.md`, split forge/team rules) show the product is migrating toward one-schema-per-concept — the right direction. Finishing QUAL-H4 (config-loader removal) lands the schema-freeze goal cleanly.

## Unresolved questions
1. Is `plugin.json` supposed to declare directories (per `verify-plugin-structure.js` + `verify-cache.js`) or not (per the committed file)? The two tell-opposite stories; the truth determines whether QUAL-H2 fix is "add keys" or "delete verifiers".
2. Are `skills/e2e-testing/`, `skills/e2e-validate/`, `skills/web-testing/`, `skills/web-validation/`, and `skills/playwright-validation/` intentionally distinct, or are 2-3 of them orphan drafts? Need a side-by-side of their SKILL.md frontmatter to decide the merge/rename plan for QUAL-M2.
3. `commands/forge-*` and `/validate-consensus`: are these shipping features or planned ones? TECHNICAL-DEBT.md says "NOT IMPLEMENTED"; README lists them in the command roster. Decision needed before QUAL-M3 can be acted on (downgrade to "planned" vs delete command files vs implement).
4. Are `worktree-merge-evidence/` and `skill-audit-workspace/` intentional commits (artifacts of a past review) or leftover session state? If the former, they should live under `docs/` or `plans/`; if the latter, add to .gitignore.

## Status + Summary
**STATUS:** DONE. 18 findings (5 HIGH, 8 MEDIUM, 5 LOW). No CRITICAL — the product works, but carries documentation-vs-code drift that will compound. Highest-leverage fix: delete `scripts/verify-plugin-structure.js` and `hooks/lib/config-loader.js` (QUAL-H1 + QUAL-H4), derive `REQUIRED_RULES` from filesystem (QUAL-H3), and decide the plugin.json directory-keys contract (QUAL-H2). Those four changes remove ~400 LOC of drift-prone hand-maintained mirrors.
