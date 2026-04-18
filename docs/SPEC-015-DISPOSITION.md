# Spec 015 Disposition — DROP

**Date**: 2026-04-16  
**Decision**: DROP (per U3 in plans/260416-1713-gap-remediation-loop/logs/decisions.md)  
**Campaign**: ValidationForge Spec Branch Consolidation (plan 260416-1713-gap-remediation-loop)

---

## Branch State at Decision Time

- **Branch name**: `auto-claude/015-persistent-validation-history-trend-tracking`
- **Merge commit**: `0c66723bbbbe0d9d1f91f100937be0f543b26f06`
- **Merge subject**: `merge: spec 015a — landing page documentation site (Astro + Starlight)`
- **Last commit before merge**: `b3adbbd` (auto-claude: subtask-2-2 - Add demo section to landing page showing 5 scenarios)
- **Commits in branch**: 5 total (4 implementation + 1 merge)
- **Lines added/deleted**: +8,294 additions / 0 deletions (net +8,294)
- **Files changed**: 15 files added (all under `site/` directory)

---

## Why Spec 015 Was Quarantined

Per CAMPAIGN_STATE.md (2026-04-09 quarantine decision):

- **Quarantine date**: 2026-04-09
- **Quarantine reason**: "256 files changed, +2375/-17723. Deletes protected files (config-loader.js, verify-e2e.js, uninstall.sh). Too destructive to merge."
- **Revisit policy**: Revisit by 2026-07-01; drop by 2026-10-01 if not revisited

**Critical finding** (from Phase 11 analysis): The quarantine description references 256 files with -17,723 deletions, but the actual merged content (commit 0c66723) shows 15 files with +8,294 additions and **zero deletions**. This indicates:

1. **Spec 015 was substantially rewritten** between quarantine decision and merge.
2. **The destructive deletions (protected files) were NOT merged** — only the documentation site component survived to main.
3. **The quarantine was justified but the merged result is safe** — no protected file deletions in the actual merge.

**Note (2026-04-17):** The "protected files" referenced in the quarantine decision (`config-loader.js`, `verify-e2e.js`) have since been intentionally removed in commit `1155af4` as part of the full-codebase review remediation:
- `config-loader.js` was consolidated into `resolve-profile.js` (3-line compat shim) — H9 fix
- `verify-plugin-structure.js` (245 LOC stale inventory) was deleted — H6 fix

These removals were justified remediation, not destructive cargo-cult deletions. The quarantine concern about "deletes protected files" is now obsolete.

---

## Why DROP Is Correct

Per **U3 decision** (campaign decisions.md, line 34-40):

> "Delete the quarantine branch; matrix closes with DROP rationale. Fastest path."

Justification:

1. **U3 mandates DROP** — No cherry-pick permitted; branch must be deleted and disposition documented.
2. **Minimal risk of rollback** — The merged content is isolated to `site/` (marketing/documentation site). No core ValidationForge files were deleted or corrupted.
3. **No unique value in cherry-pick** — The destructive work that justified quarantine was already stripped before merge. The documentation site is self-contained and non-critical to core functionality.
4. **Fastest closure path** — Branch already deleted from remote; merge already applied to main. Just close the gap and move on.
5. **Campaign policy compliance** — Phase 11 executor must execute DROP per U3. No exceptions.

---

## Action Taken

- **Branch delete**: Remote branch `auto-claude/015-landing-page-documentation-site` already deleted before Phase 11 execution. No force-delete required.
- **Local cleanup**: No local branch reference found (`git branch -a` returned no match). Confirmed absent.
- **Merge status**: Already merged into main at commit `0c66723`. No reversal taken.
- **Matrix update**: VALIDATION_MATRIX.md updated to change Spec 015 status from QUARANTINED to DROPPED.
- **State update**: CAMPAIGN_STATE.md updated to mark Spec 015 as DROPPED (date 2026-04-16).

---

## VALIDATION_MATRIX Update

**Before:**
```
| 015 | Persistent Validation History & Trends | QUARANTINED | Branch preserved at `auto-claude/015-*`. Worktree at `.auto-claude/worktrees/tasks/015-*`. **Not merged.** | 256 files changed, +2375/-17723. Deletes protected files (config-loader.js, verify-e2e.js, uninstall.sh). Too destructive to merge. Preserved for future cherry-pick. |
```

**After:**
```
| 015 | Landing Page Documentation Site | DROPPED | Branch `auto-claude/015-*` merged at `0c66723`. Remote branch deleted. | Merged content isolated to `site/` directory (Astro + Starlight docs). U3 decision (DROP) closed gap M6. Disposition: 2026-04-16. |
```

---

## CAMPAIGN_STATE Update

**Quarantine Registry — Before:**
```
| 015 | `auto-claude/015-persistent-validation-history-trend-tracking` | `.auto-claude/worktrees/tasks/015-*` | 17K net deletions destroy protected files | Cherry-pick history/trend features after manual review |
```

**Quarantine Registry — After (REMOVED):**
Spec 015 removed from quarantine registry; status upgraded to DROPPED.

**Wave 4 status (line 47):**
- Before: `Spec 015 QUARANTINED, 016 SKIPPED, 018/021/023/024 merged`
- After: `Spec 015 DROPPED, 016 SKIPPED, 018/021/023/024 merged`

---

## Historical Note

**Discrepancy between quarantine description and actual merge**:

The quarantine decision (2026-04-09) referenced a destructive version of Spec 015 (256 files, -17K lines, deleted protected files). However, the version that actually merged (commit 0c66723, 2026-04-11) was a sanitized documentation site (+8K lines, zero deletions, only `site/` directory touched).

This indicates either:
1. Spec 015 branch was substantially rewritten between quarantine decision and merge, OR
2. Two different Spec 015 branches existed; the destructive one was never merged

**Either way**: The DROP decision is sound. The merged content is safe; the destructive work never reached main.

---

## Future Re-introduction

Should persistent validation history/trends features be needed in the future:
1. Open a new plan under `plans/<YYMMDD-HHMM>-spec-015-history-tracking-rerun/`
2. Design against current codebase state (not 2026-04-09 stale code)
3. Implement without deletions to protected files
4. This document serves as historical record of the 2026-04 disposition

---

## Sign-off

- **Executor**: researcher (Phase 11, plan 260416-1713-gap-remediation-loop)
- **Decision authority**: U3 (campaign decisions.md)
- **Gap closed**: M6 (Spec 015 quarantine disposition)
- **Status**: CLOSED 2026-04-16
