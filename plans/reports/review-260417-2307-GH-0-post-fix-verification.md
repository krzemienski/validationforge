# Post-Fix Verification — 2026-04-17 23:07 ET

Evidence trail for review remediation. Companion to
`review-260417-2200-GH-0-full-codebase-synthesis.md` (original verdict:
REQUEST CHANGES, 1 Critical + 12 High). All Critical and High findings resolved.

## Findings resolved

| ID | Title | Fix | Functional evidence |
|---|---|---|---|
| **C1** | `\|\| true` defangs all 7 hooks | Removed suffix from every `hooks.json` command | `verify-hooks.js` test #8 (shell-path) PASS; simulated regression → FAIL as expected |
| **H1** | Shell injection in `generate-report.js` open-in-browser | `execSync` → `execFileSync('open', [file])` | grep: no `execSync(\`open` remains |
| **H2** | JSON injection in `telemetry.sh` key=value | Key `[A-Za-z_][A-Za-z0-9_-]*` validation + python3 `json.dumps` on value | Payload test with `"` and `\` in value → properly escaped; `bad-key!=` silently dropped |
| **H3** | ReDoS/size-cap gap on 3 Bash hooks | `MAX_SCAN_BYTES = 200KB`, slice from **tail** of stdout | 500KB stdout + trailing "Build succeeded" → exit 2 in 53ms |
| **H4** | Unbounded `readdirSync+statSync` | `.slice(0, 200)` hard cap | completion-claim-validator still works correctly |
| **H5** | `stat.size > 0` no-op on dirs (APFS) | Descend one level for dir entries; verify at least one fresh non-empty file | Empty journey dir → BLOCKS (was falsely PASSING); dir with file → PASSES |
| **H6** | `verify-plugin-structure.js` 0/6 checks | DELETED (245 LOC); single reference in docs updated | File absent; onboarding points to `verify-hooks.js` |
| **H7** | `plugin.json` missing directory keys | Added `commands/skills/agents/hooks` canonical CC keys (skipped VF-internal `rules`) | JSON valid; all 4 keys present |
| **H8** | `vf.js` REQUIRED_RULES stale 8-entry mirror | Derived from `fs.readdirSync(RULES_SOURCE)` at require time | `vf status` → `Rules: 8/9 installed`, `[MISSING] consensus-engine` — caught real drift on first run |
| **H9** | Two live config APIs (4 + 3 split) | Migrated 4 legacy hooks to `resolve-profile.js`; deleted `config-loader.js` shim (19 LOC) | `grep config-loader hooks/*.js` → zero matches; all 8 hook tests still PASS |
| **H10** | No stdin size cap in any hook | `MAX_INPUT_BYTES = 2MB` with fail-safe exit 0 across all 7 hooks | 3MB stdin → exit 0 in 55ms |
| **H11** | `reject_empty_evidence` missing from profile JSONs | Added to all 3 profiles: strict=true, standard=true, permissive=false | JSON parse confirms presence + correct values |
| **H12** | `verify-hook-exists.js` checked path that plugin never writes | Rewrite: canonical `~/.claude/plugins/validationforge/hooks/` + manifest fallback | PASS against real install |

## Regression guardrail added

`scripts/verify-hooks.js` test #8 ("shell-path regression"):
- Reads `hooks/hooks.json`, picks `validation-not-compilation` entry
- Substitutes `${CLAUDE_PLUGIN_ROOT}` → local plugin root
- Executes via `/bin/sh -c` exactly as Claude Code would
- Asserts exit code = 2 (via the shell layer, not direct `node` spawn)

Before adding this test, tests 1-7 spawned `node` directly and could not see
shell-level defanging — this was precisely the "gate blindspot" that let `||
true` survive in production. Regression check proven effective by temporarily
re-introducing `|| true` and observing test-#8 FAIL with
`exit 0 via /bin/sh (expected 2); shell is swallowing block signals — check
hooks.json for '|| true' or similar wrappers`.

## Verdict after fixes

- **Critical: 0** (was 1)
- **High: 0** (was 12)
- Medium: ~20 (unchanged — remaining work)
- Low: ~12 (unchanged — remaining work)

Per review rubric (`(0 crit, 0 high)` → APPROVE), the branch would now APPROVE.

## Files changed

```
Deleted (2):
  scripts/verify-plugin-structure.js   245 LOC of stale hardcoded expectations
  hooks/lib/config-loader.js            19 LOC compat shim

Modified — runtime code (10):
  hooks/hooks.json, block-test-files, evidence-gate-reminder,
  validation-not-compilation, completion-claim-validator,
  validation-state-tracker, mock-detection, evidence-quality-check,
  bin/vf.js, scripts/generate-report.js

Modified — infra (8):
  scripts/telemetry.sh, verify-hook-exists.js, verify-hooks.js,
  config/{strict,standard,permissive}.json,
  .claude-plugin/plugin.json, docs/onboarding-walkthrough.md

Net: +259 / -368 LOC (net -109 — drift-prone code removed)
```

## Unresolved

- `plugin.json` canonical directory-keys contract for CC plugin loader — we
  added the keys (H7 fix works either way; keys align with internal verifiers
  and CC convention). Definitive spec confirmation from Anthropic docs would
  retire the uncertainty.
- Benchmark harness may have been scoring hooks whose enforcement was defanged
  — pre/post benchmark diff would confirm score inflation.
- `DISABLE_OMC` still honored by only 3 of 7 hooks (review L13). Uniform
  application deferred to Medium/Low batch (L9 env-overrides helper).
