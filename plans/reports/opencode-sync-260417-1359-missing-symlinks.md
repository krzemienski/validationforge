# OpenCode Parity Sync — Missing Symlinks

**Date:** 2026-04-17 13:59
**Scope:** `.opencode/skill/` and `.opencode/command/`
**Source audit:** `plans/reports/researcher-260417-1359-opencode-parity-audit.md`

## Pattern confirmed

Existing `.opencode/skill/` entries are **directory symlinks** pointing to
`../../skills/<name>` (not individual `SKILL.md` file-level symlinks). The
`functional-validation` directory is an outlier (real directory, not symlink),
so it was NOT used as the pattern template.

Existing `.opencode/command/` entries are **file symlinks** pointing to
`../../commands/<name>.md`.

All 9 new symlinks mirror the prevailing pattern exactly.

## Symlinks created (9)

### Skills (7) — `.opencode/skill/<name> -> ../../skills/<name>`

1. `ai-evidence-analysis`
2. `coordinated-validation`
3. `django-validation`
4. `flutter-validation`
5. `react-native-validation`
6. `rust-cli-validation`
7. `team-validation-dashboard`

### Commands (2) — `.opencode/command/<name>.md -> ../../commands/<name>.md`

8. `vf-telemetry.md`
9. `validate-team-dashboard.md`

## Verification

Each new symlink was resolved and its `SKILL.md` (or `.md`) target confirmed
accessible via `ls -la`.

### Final parity counts

| Layer                  | Count | Target | Status |
|------------------------|-------|--------|--------|
| `.opencode/skill/` symlinks   | 52    | 52     | PASS   |
| `.opencode/command/` symlinks | 19    | 19     | PASS   |

Both counts match the expected post-fix totals specified in the task.

## Notes on verification method

The task protocol suggested `find .opencode/skill -name SKILL.md -type l | wc -l`
as the verification command, but that pattern would return 0 — because the
existing convention uses **directory symlinks**, not file-level `SKILL.md`
symlinks. The correct verification is
`ls -la .opencode/skill/ | grep -c '^l'`, which returns 52.

## Commit status (IMPORTANT — deviation from task spec)

The task requested a dedicated commit:
`feat(opencode): add missing skill + command symlinks (parity with main)`

However, **all 9 symlinks were already captured by the preceding commit
`c3e9fc4 fix(site): sweep includeStatic across MDX pages`** — that commit
(authored before my dedicated commit step ran) swept the new symlinks into
its tree alongside unrelated site MDX edits. `git commit` then reported
"nothing to commit" because the changes were already persisted under the
wrong message.

Attempting to correct this would require either:
- `git commit --amend` (forbidden by CLAUDE.md "never amend" rule), or
- `git reset --soft HEAD~1` + recommit (destructive, requires explicit user
  consent per CLAUDE.md git safety protocol).

Neither destructive path was taken. The functional outcome (9 working
symlinks, 52/19 parity) is already on HEAD. A follow-up housekeeping commit
could be issued by the caller if a clean history is required.

## Out of scope

- `.opencode/plugins/` (hooks) — deferred per task constraints.
- Any content copying — only symlinks created.

## Unresolved questions

- Should the caller rewrite history (`git reset --soft HEAD~1` + two fresh
  commits) to split c3e9fc4 into a dedicated "site MDX" + dedicated
  "opencode symlinks" pair? Left for user decision.
