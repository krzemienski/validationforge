# Merge 4 — 004 skill-deep-review-top-10 (cherry-picked)

**Status:** ✅ PASS (10 commits via cherry-pick, not branch merge)
**Branch:** auto-claude/004-skill-deep-review-top-10
**Strategy:** Cherry-pick. Branch forked from pre-cleanup main (2,435 file deletions),
naive merge would destroy current codebase. Cherry-picked 10 additive commits instead.

## Commits landed on main (oldest → newest)

| Hash | Message | Files | Notes |
|------|---------|-------|-------|
| `6b6662a` | review(skills): functional-validation (phase-1-subtask-1) | 1 | findings.md |
| `0e5ed78` | review(skills): gate-validation-discipline (phase-1-subtask-2) | 1 | findings.md |
| `a3097c3` | review(skills): no-mocking-validation-gates (phase-1-subtask-3) | 3 | findings + test patterns |
| `365ed7a` | review(skills): preflight (phase-1-subtask-4) | 11 | findings + 10 evidence artifacts |
| `56b4a59` | review(skills): e2e-validate (phase-1-subtask-5) | 1 | findings.md |
| `3f80319` | review(skills): ios-validation (phase-2-subtask-1) | 4 | findings + transcripts |
| `9ba33a2` | review(skills): web-validation (phase-2-subtask-2) | 6 | findings + 4 transcripts |
| `024eb23` | review(skills): api+cli+fullstack-validation | 9 | 3 findings + 6 transcripts |
| `9f5e248` | **fix(preflight): nullglob+array for iOS detection** | 2 | CRITICAL fix |
| `475c51b` | **fix(e2e-validate): preflight as explicit pipeline gate** | 4 | CRITICAL fix |

## CRITICAL fixes validated

### preflight (commit 9f5e248)
- Bad pattern: `[ -d "*.xcodeproj" ]` — tests literal directory name
- Fix: `shopt -s nullglob; xcode_projs=(*.xcodeproj *.xcworkspace); shopt -u nullglob`
- Evidence file: `e2e-evidence/skill-review/preflight/fix-a-verification.txt`
  - 5 fixture tests: xcodeproj/xcworkspace/SPM → ios ✅, empty → unknown ✅, buggy → unknown ✅

### e2e-validate (commit 475c51b)
- Bad pattern: preflight listed only as Related Skill, never invoked in workflows
- Fix: SKILL.md Preflight Gate section + `--preflight` flag + `--skip-preflight` override
- Fix: workflows/full-run.md Phase 2 enhanced with CLEAR/WARN/BLOCKED semantics + Iron Rule #4 citation
- Fix: workflows/ci-mode.md Step 1 "Preflight Gate (MANDATORY)" with exit-code semantics

## All 10 findings files present

`find e2e-evidence/skill-review -name findings.md | wc -l` → 10

## Cherry-pick conflict resolution

Commit `14b330a` (e2e-validate fix) conflicted in 2 files:
- `skills/e2e-validate/SKILL.md` — Command Routing table: main had richer "When to use" column;
  resolved by keeping main's format + adding 004's `--preflight` row + `--skip-preflight` modifier.
- `skills/e2e-validate/workflows/full-run.md` — pipeline diagram: main had 7-phase layout
  (Research→Plan→Preflight→Execute→Analyze→Verdict→Ship); 004 had older 6-phase. Kept main's
  7-phase diagram, then enhanced Phase 2 (Preflight) inline with 004's CLEAR/WARN/BLOCKED gate
  behavior + Iron Rule #4 citation + `--skip-preflight` note.

No functionality lost; main's structure preserved; Iron-Rule-4 intent fully delivered.

## Validation

```
bash -n <(grep -A5 'shopt -s nullglob' skills/preflight/references/auto-fix-actions.md) → PASS
grep -c "preflight" skills/e2e-validate/SKILL.md → 11 mentions
grep -c "Iron Rule #4\|MANDATORY" skills/e2e-validate/workflows/full-run.md → 2 mentions
find e2e-evidence/skill-review -name findings.md | wc -l → 10
```
