---
phase: P02
name: Orphan hook decision + registration
date: 2026-04-16
status: pending
gap_ids: [H-ORPH-1, H-ORPH-2, H-ORPH-3]
executor: fullstack-developer
validator: code-reviewer
depends_on: [P00]
---

# Phase 02 — Orphan Hook Decision + Registration

## Why

3 hook files exist on disk but are not registered in `hooks/hooks.json`:
- `hooks/config-loader.js` (42 lines)
- `hooks/patterns.js` (28 lines)
- `hooks/verify-e2e.js` (64 lines)

They will never execute. They are either dead code, helper utilities that should
be in `hooks/lib/`, or functional hooks that were never wired in. Decide per file
and execute the decision.

## Pass criteria

1. Each orphan has an explicit disposition recorded in
   `evidence/02-orphan-hooks/decision.md`:
   - `REGISTER` (added to hooks.json with matcher+event) OR
   - `RELOCATE` (moved under `hooks/lib/` and confirmed not-invoked-as-hook) OR
   - `DELETE` (rm'd with `git rm`)
2. For each REGISTER: the `hooks/hooks.json` diff shows the exact matcher/event
   inserted; at least one smoke invocation is captured proving the hook fires
   (stderr redirected via `2>&1 | tee evidence/02-orphan-hooks/<hook>-fires.txt`).
3. For each RELOCATE: `git mv` diff attached; grep confirms no caller uses the
   old path (`grep -r "hooks/<name>.js" .claude .omc scripts commands hooks ||
   echo "no callers"`).
4. For each DELETE: justification quotes the file's contents showing it's
   dead/untested/not-integrated; `git rm` run; diff attached.
5. `hooks.json` is valid JSON (`node -e "JSON.parse(require('fs').readFileSync('hooks/hooks.json'))"` exits 0).
6. Decision counts add to 3 and match the actual git changes.

## Inputs

- `hooks/config-loader.js`
- `hooks/patterns.js`
- `hooks/verify-e2e.js`
- `hooks/hooks.json`
- `plans/reports/researcher-260416-1707-inventory-audit.md` (Q3)

## Steps

1. Dispatch executor.
2. Executor reads each orphan, classifies:
   - Is it invoked from anywhere else? (grep)
   - Does it export helper fns (likely RELOCATE)?
   - Does it have its own PreToolUse/PostToolUse logic (likely REGISTER)?
   - Is it obviously superseded (likely DELETE)?
3. Executor drafts `decision.md` with one row per orphan and rationale.
4. For REGISTER: edit `hooks/hooks.json`. Smoke test with a synthetic trigger.
5. For RELOCATE: `git mv hooks/X.js hooks/lib/X.js`. Confirm no callers broken.
6. For DELETE: `git rm hooks/X.js`. Confirm no callers.
7. Record every command output in `evidence/02-orphan-hooks/`.
8. Dispatch validator.

## Evidence outputs

| File | Source |
|------|--------|
| `evidence/02-orphan-hooks/decision.md` | Executor synthesis |
| `evidence/02-orphan-hooks/hooks-json-before.txt` | pre-edit copy |
| `evidence/02-orphan-hooks/hooks-json-after.txt` | post-edit copy |
| `evidence/02-orphan-hooks/git-diff.patch` | `git diff hooks/` |
| `evidence/02-orphan-hooks/<hook>-fires.txt` | smoke-test output (REGISTER only) |
| `evidence/02-orphan-hooks/caller-grep.txt` | grep output confirming no orphan refs |

## Failure modes

- Ambiguous classification → default RELOCATE (safest; reversible).
- JSON parse fail after edit → revert; re-run with explicit schema validation.
- Smoke test shows hook registered but silent → recheck matcher pattern.

## Duration estimate

45–90 min.
