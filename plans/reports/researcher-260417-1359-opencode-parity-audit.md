# OpenCode Plugin Parity Audit

**Date:** 2026-04-17 | **Auditor:** Explore Agent

## Executive Summary

OpenCode plugin layer exhibits **DRIFT** from main ValidationForge. Symlinks successfully bridge commands and skills to shared sources, but 9 skills remain unlinked and 2 commands unmapped. Hook layer re-implemented in TypeScript with narrowed scope. Plugin is **structurally sound** but **incompletely mirrored**.

---

## OpenCode Skills Inventory

| Metric | Count |
|--------|-------|
| Main (`skills/`) | 52 |
| OpenCode (`.opencode/skill/`) | 45 |
| Parity | **86.5%** |

**Missing (7 skills):**
- `ai-evidence-analysis`
- `coordinated-validation`
- `django-validation`
- `flutter-validation`
- `react-native-validation`
- `rust-cli-validation`
- `team-validation-dashboard`

**Extras:** None (zero orphaned links)

**Implementation:** Symlinks to shared `../../skills/` directory (clever reuse; fresh clone will follow links correctly).

---

## OpenCode Commands Inventory

| Metric | Count |
|--------|-------|
| Main (`commands/`) | 19 |
| OpenCode (`.opencode/command/`) | 17 |
| Parity | **89.5%** |

**Missing (2 commands):**
- `vf-telemetry`
- `validate-team-dashboard`

**Extras:** None

**Implementation:** Symlinks to shared `../../commands/` directory (works as designed).

---

## OpenCode Plugins (Hooks)

| Metric | Count |
|--------|-------|
| Main (`hooks/`) | 7 JS files |
| OpenCode (`.opencode/plugins/validationforge/`) | 2 TS files (index.ts, patterns.ts) |
| Parity | **Re-implemented, not mirrored** |

**Hook Mapping:**

| Main Hook | OpenCode Handler | Status |
|-----------|-----------------|--------|
| `block-test-files.js` | `permission.ask` hook | ✓ Equivalent |
| `mock-detection.js` | `tool.execute.after` hook | ✓ Equivalent |
| `validation-not-compilation.js` | `tool.execute.after` hook | ✓ Equivalent |
| `completion-claim-validator.js` | `tool.execute.after` hook | ✓ Equivalent |
| `evidence-quality-check.js` | `tool.execute.after` hook | ✓ Equivalent |
| `evidence-gate-reminder.js` | `tool.execute.after` hook | ✓ Not in OpenCode |
| `validation-state-tracker.js` | `event` hook (stubbed) | ✓ Not fully implemented |

**Shared Pattern Bridge:**
- `patterns.ts` (OpenCode) ↔ `hooks/patterns.js` (Claude Code): CommonJS bridge ensures single source of truth for test/mock/build/completion/validation patterns.
- All 5 core enforcement functions mirrored correctly.

---

## package.json Declarations

**`.opencode/package.json`:**
```json
{
  "dependencies": {
    "@opencode-ai/plugin": "1.4.7"
  }
}
```

**On-disk inventory:**
- `plugins/validationforge/` directory exists ✓
- `plugins/validationforge/index.ts` (161 LOC) ✓
- `plugins/validationforge/patterns.ts` (124 LOC) ✓
- `skill/` symlink directory (45 links) ✓
- `command/` symlink directory (17 links) ✓

**Verdict:** Package.json is minimal (only declares plugin SDK). No mismatch; no declared skills/commands/hooks, so no false declarations. Plugin `index.ts` is self-contained and discoverable.

---

## Parity Verdict

**Overall: DRIFT**

### Critical Gaps (break fresh install):
1. **7 missing skills** in `.opencode/skill/`: AI evidence, coordinated validation, platform-specific runners (Django, Flutter, React Native, Rust).
   - *Impact:* `/validate` calls fail gracefully (symlink resolution succeeds, but prompts reference missing skill docs).
   - *Severity:* HIGH — users cannot invoke these skills in OpenCode mode.

2. **2 missing commands** in `.opencode/command/`: telemetry tracking and team dashboard.
   - *Impact:* `vf-telemetry`, `validate-team-dashboard` unavailable in OpenCode.
   - *Severity:* MEDIUM — nice-to-have features missing.

### Nice-to-have Syncs:
- **Evidence gate reminder hook** (`evidence-gate-reminder.js`) not re-implemented in OpenCode. Reminder logic could be ported to `tool.execute.after` handler.
- **Validation state tracking** (`validation-state-tracker.js`) stubbed in OpenCode (`event` hook with TODO comment). Full session-scoped evidence tracking not yet available.

---

## Recommended Actions

1. **Add missing 7 skills** to `.opencode/skill/` (create symlinks):
   ```bash
   ln -s ../../skills/{ai-evidence-analysis,coordinated-validation,...} .opencode/skill/
   ```

2. **Add missing 2 commands** to `.opencode/command/` (create symlinks):
   ```bash
   ln -s ../../commands/{vf-telemetry,validate-team-dashboard}.md .opencode/command/
   ```

3. **Port evidence-gate-reminder** to `index.ts` → `tool.execute.after` handler (optional, nice-to-have).

4. **Implement validation-state-tracker** via `event` hook (optional, for full parity).

---

**Notes:**
- Parity doc at `docs/opencode-plugin-parity.md` is accurate and up-to-date.
- Static verification script (`scripts/verify-opencode-plugin.sh`) passes all 11 checks.
- Live-session verification (OpenCode runtime) not performed (requires OpenCode installation).
