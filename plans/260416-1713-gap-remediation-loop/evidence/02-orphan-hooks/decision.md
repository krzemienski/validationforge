# Phase 02 — Orphan Hook Decision

## PASS Criteria Status

1. [x] All 3 orphans have explicit disposition (REGISTER | RELOCATE | DELETE)
2. [x] No REGISTER decisions — N/A (no smoke-test files required)
3. [x] RELOCATEd hooks have `git mv` diff + post-move grep showing zero old-path callers
4. [x] No DELETE decisions — N/A
5. [x] `node -e "JSON.parse(require('fs').readFileSync('hooks/hooks.json'))"` exits 0
6. [x] Dispositions sum to 3 and match actual git changes (3 RELOCATE = 3)

---

## Decision Table

| Hook | Gap ID | Classification | Rationale | Evidence File |
|------|--------|---------------|-----------|---------------|
| `hooks/config-loader.js` | H-ORPH-1 | RELOCATE → `hooks/lib/config-loader.js` | Pure utility library: exports `{ loadConfig }`, no stdin parsing, no event-hook logic. Required by 7 registered hooks. All callers updated. | `config-loader-caller-grep.txt` |
| `hooks/patterns.js` | H-ORPH-2 | RELOCATE → `hooks/lib/patterns.js` | Pure utility library: exports 6 pattern arrays + 5 helper fns. Documented as auto-generated CommonJS bridge in TECHNICAL-DEBT.md. Required by 5 registered hooks. All callers updated. | `patterns-caller-grep.txt` |
| `hooks/verify-e2e.js` | H-ORPH-3 | RELOCATE → `scripts/verify-e2e.js` | Behavioral verification runner (not an event hook): uses `spawnSync` to invoke hooks with fixture payloads, no hook protocol. Listed as expected file in `scripts/verify-plugin-structure.js:89`. | `verify-e2e-caller-grep.txt` |

---

## Disposition Justifications

### H-ORPH-1: config-loader.js — RELOCATE to hooks/lib/

`config-loader.js` is a synchronous utility that reads `~/.claude/.vf-config.json`,
loads the matching enforcement profile from `config/{level}.json`, and returns a
`{ enforcement, rules, getHookConfig }` object. It contains no hook protocol code
(no stdin reads, no JSON output, no exit-code signaling). It is `require()`d by every
registered hook that needs config-driven enforcement:

- `block-test-files.js` (PreToolUse)
- `mock-detection.js` (PostToolUse)
- `validation-not-compilation.js` (PostToolUse)
- `completion-claim-validator.js` (PostToolUse)
- `validation-state-tracker.js` (PostToolUse)
- `evidence-quality-check.js` (PostToolUse)
- `evidence-gate-reminder.js` (PreToolUse)

Placing it in `hooks/lib/` makes its library role explicit. All 7 callers patched
from `require('./config-loader')` to `require('./lib/config-loader')`. Post-move
grep confirms zero old-path references in `hooks/*.js`.

### H-ORPH-2: patterns.js — RELOCATE to hooks/lib/

`patterns.js` is a compiled/auto-generated CommonJS bridge (per `TECHNICAL-DEBT.md`
and `findings.md`) exporting 6 RegExp arrays and 5 helper functions used across
hooks. Documented explicitly as library code in `docs/opencode-plugin-parity.md`.
No hook lifecycle code. Required by 5 registered hooks. All 5 callers patched from
`require('./patterns')` to `require('./lib/patterns')`. Post-move
`node -e "require('./hooks/lib/patterns')"` exits 0 with expected exports.

### H-ORPH-3: verify-e2e.js — RELOCATE to scripts/

`verify-e2e.js` is a standalone behavioral verification runner. It uses `spawnSync`
to invoke other hook scripts with synthetic stdin payloads, reads fixture files from
`hooks/test-inputs/`, tracks pass/fail counts, and exits 1 on failure. It has no
stdin-reading hook protocol, never outputs permissionDecision JSON, and never uses
hook exit codes (exit 2 = block). The only operational reference is
`scripts/verify-plugin-structure.js:89`, which lists it as an expected file —
confirming `scripts/` is the correct home. Post-move grep confirms zero
`hooks/verify-e2e` references remain.

---

## Git Changes Summary

```
hooks/block-test-files.js           | 4 +-  (require paths updated)
hooks/completion-claim-validator.js | 4 +-  (require paths updated)
hooks/evidence-gate-reminder.js     | 2 +-  (require path updated)
hooks/evidence-quality-check.js     | 2 +-  (require path updated)
hooks/{ => lib}/config-loader.js    | 0     (renamed)
hooks/{ => lib}/patterns.js         | 0     (renamed)
hooks/mock-detection.js             | 4 +-  (require paths updated)
hooks/validation-not-compilation.js | 4 +-  (require paths updated)
hooks/validation-state-tracker.js   | 4 +-  (require paths updated)
{hooks => scripts}/verify-e2e.js    | 0     (renamed)
10 files changed, 12 insertions(+), 12 deletions(-)
```

## Post-Move Verification

- `node -e "require('./hooks/lib/config-loader')"` → exit 0, no errors
- `node -e "require('./hooks/lib/patterns')"` → exit 0, exports: TEST_PATTERNS, ALLOWLIST, MOCK_PATTERNS, BUILD_PATTERNS, COMPLETION_PATTERNS, VALIDATION_COMMAND_PATTERNS + 5 helpers
- All 7 registered hooks load without require errors
- `node -e "JSON.parse(require('fs').readFileSync('hooks/hooks.json'))"` → exit 0
- `rg "require\('./config-loader'\)\|require\('./patterns'\)" hooks/*.js` → no matches (exit 1)
- `rg "hooks/verify-e2e" hooks/ commands/ scripts/ .claude/` → no matches (exit 1)
