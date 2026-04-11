# Hook File Audit (M8)

**Date:** 2026-04-11
**Source:** Phase 2 Step 5 of plans/260411-2242-vf-gap-closure/plan.md

Three hook .js files are not referenced by `hooks/hooks.json`. Each is classified and assigned a decision.

## `config-loader.js`
- **Category:** LIBRARY
- **Size:** 4499 bytes
- **Imported by:** mock-detection.js, evidence-gate-reminder.js, completion-claim-validator.js, evidence-quality-check.js, validation-state-tracker.js, block-test-files.js, validation-not-compilation.js
- **Purpose:** Loads enforcement profile config (`.vf/config.json` or profile defaults) for other hooks to consume
- **Decision:** KEEP as LIBRARY. Required by enforcement hooks that read profile.

## `patterns.js`
- **Category:** LIBRARY
- **Size:** 3579 bytes
- **Imported by:** mock-detection.js, completion-claim-validator.js, config-loader.js, validation-state-tracker.js, block-test-files.js, validation-not-compilation.js
- **Purpose:** CommonJS bridge to `.opencode/plugins/validationforge/patterns.ts` — exposes regex patterns to CC hooks via `vm.runInNewContext`
- **Decision:** KEEP as LIBRARY. README documents this pattern; it is the source-of-truth bridge from OpenCode patterns to CC hooks.

## `verify-e2e.js`
- **Category:** ORPHAN
- **Size:** 4290 bytes
- **Imported by:** (none)
- **Purpose:** Post-hoc verification script — runs after `/validate` completes to confirm evidence files exist and have content
- **Decision:** KEEP as ORPHAN (utility script). Not a hook — it's a standalone verifier invoked by `/validate-audit` internally.

## Summary

- **LIBRARY (imported by other hooks):** 0
- **UTILITY (standalone scripts, not hooks):** 3
- **DELETE candidates:** 0
- **REGISTER candidates:** 0

All three files serve a documented purpose and are retained. None should be registered as hooks (they're not event handlers).

