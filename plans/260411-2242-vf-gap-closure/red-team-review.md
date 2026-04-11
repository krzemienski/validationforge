# Red-Team Review — VF Gap Closure Plan

**Reviewer:** Oracle (hostile adversarial mode)
**Date:** 2026-04-11
**Plan:** `plans/260411-2242-vf-gap-closure/plan.md`
**Session:** ses_2814385adffeZeoLi5zc55U26X
**Verdict:** 🔴 **RED — plan needs significant rework**

Total issues: **49** (7 Critical, 19 High, 20 Medium, 3 Low)

**Post-verification note:** H7 was REFUTED on live check (plan's inventory scan was correct). Adjusted total: **48 actionable** (7 Critical, 18 High, 20 Medium, 3 Low). C1 and C2 confirmed on live check — real blockers.

---

## Critical issues (7) — must fix before any execution

| # | Phase | Finding | Fix |
|---|-------|---------|-----|
| C1 | P1 Commit 3 | `.claude` still tracked as symlink in index (`git ls-files` mode `120000`). Plan's `git rm --cached .claude 2>/dev/null \|\| true` suppresses the only error. Adding `.claude/rules/` on top of a stale symlink entry produces an impossible tree. | Remove `\|\| true`. Hard gate: `git ls-files .claude \| grep -q '^\.claude$' && { echo FAIL; exit 1; }`. Commit symlink deletion explicitly. |
| C2 | P1 Commit 3 | `.gitignore` line 34 contains `.claude/`. `git check-ignore -v` confirms. Plan uses `-f` which works once, but future sessions will never see these files naturally → permanent invisibility trap. | Either remove `.claude/` from `.gitignore` with `!.claude/rules/` negation, or document the trap in commit msg. Add post-check: `git check-ignore .claude/rules/no-mocks.md && echo GOTCHA`. |
| C3 | P1 ordering | Commit 1 msg references `VERIFICATION.md` (in `plans/260411-1731-*`) which isn't staged until Commit 2. Commit 2 references `260411-1747-*` which isn't committed until Commit 6. Cross-references point to non-yet-committed content. | Reorder: stage plan dirs FIRST ("docs: add in-flight plan dirs"), then code commits reference them. Or fold plans into Commit 1. |
| C4 | P1 Commit 1 | `git add skills/*/SKILL.md` is indiscriminate. Rule #6 says "don't touch skills" but blanket-staging bypasses review of WIP/experimental edits. | Add diff-review artifact (`commit1-diff-review.md`). Flag any skill with `+` count > 200 lines. |
| C5 | Plan-wide | **No regression gate.** Zero phase runs `bash scripts/benchmark/score-project.sh .` or smoke-tests hooks after changes. A commit could drop benchmark from 96/A to 70/C and exit criteria still pass. | Add global post-phase check: (1) validate-skills.sh (2) score-project.sh (grade A or B) (3) hook smoke tests. Run after Phases 1, 2, 7. Fail-fast on regression. |
| C6 | P4 MANUAL-GATE | Phase 4 "cannot self-execute" with no enforcement → autonomous runner completes Phases 0-3, 7-9 with B3/B4 still open, yet success criteria claim "all 22 gaps closed." | Make Phase 5 and plan-level success gate hard-depend on `live-session-evidence.md` PASS markers. Split into `plan-auto.md` and `plan-manual.md`. |
| C7 | P6 | Transcript-analyzer.js design likely unrecoverable. Plan assumes `session_read ses_28db6f306*` fetches Apr 9 architect design. Buried risk — Phase 6 is listed as 3-4h HEAVY but no route-around. | Split P6: **6a recoverability check (5 min)** — verify session transcript readable → RESUMABLE/BLOCKED. **6b full resume only if RESUMABLE.** Move 6a to start. |

## High issues (19) — must fix before execution

| # | Phase | Finding | Fix |
|---|-------|---------|-----|
| H1 | P0 | Python `replace(...)` is idempotent-by-accident. If file was already flipped by another session, replace no-ops AND grep-check still passes → can't distinguish "we did it" from "we noticed nothing." | Pre-check: `grep -q '^status: in_progress' \|\| exit 1` before replace. Diff pre/post. |
| H2 | P1 Commit 2 | `.vf/config.json` + `validate-skills.sh` bundled but are different logical changes (bug fix vs config introduction). Dominating diff makes pipefail fix unreviewable. | Split into 2 commits or justify bundling. |
| H3 | P1 Commit 5 | `e2e-evidence/` + `scripts/benchmark/fixtures/**/.vf/benchmarks/` are different categories. Fixtures have never been committed before → freezing point-in-time benchmarks into git. Merge-campaign policy explicitly defers this. | Split. Check with `git check-ignore -v` before staging fixtures. Maybe add to `.gitignore` instead of committing. |
| H4 | P1 Commit 6 | Commits `.vf/skill-optimization/apply_trim.py` without runtime verification. | Pre-stage: `python3 -m py_compile .vf/skill-optimization/apply_trim.py`. Better: dry-run it. |
| H5 | P1 Step 7 | Exit criterion `wc -l >= 5` is too weak for 6 commits. Doesn't verify sane messages, plan references, or that it lands atop `cfa438d`. | `wc -l == 6` exactly. `grep -c 'Plan:' >= 5`. Add `git fsck --strict`. |
| H6 | P2 | Python `str.replace()` for README is fragile. No pre-verify that `OLD_TAG` still matches. Silent no-op = drift persists. | Pre-verify each target string exists before replace. Post-verify count. Require `grep -c '45 skills' = 0`. |
| H7 | P2 | ~~**Plan inventory assumption is WRONG.** Plan says "SKILLS.md has 44 entries, missing 4." Actual SKILLS.md has 46 numbered entries.~~ **REFUTED on verification.** `grep -oE '^\| [0-9]+ \| \`[a-z-]+\`' SKILLS.md \| wc -l` returns **44**. Fs/md diff confirms exactly 4 missing: `coordinated-validation`, `e2e-testing`, `e2e-validate`, `team-validation-dashboard`. Plan is correct. Oracle was mistaken by counting the "46 skills across 7 categories" header line which doesn't match the actual table row count. | No action needed — keep plan's "add 4 rows" instruction as-is. |
| H8 | P3 H7 | `git push origin --delete ... \|\| true` masks auth/network failures. `git ls-remote \|\| echo CLEAN` fires on network error = false pass. | Don't use `\|\| true`. Positive assertion: `tee /tmp/remotes && ! grep -q auto-claude`. Verify remote reachable first. |
| H9 | P3 stash | `stash@{0}` marked PENDING in CAMPAIGN_STATE — campaign's own flag. Plan drops with "to be filled" placeholders = rubber stamp. | Hard gate: require dispositions.md fully filled (`grep -q 'to be filled' && exit 1`). Require explicit override in CAMPAIGN_STATE. |
| H10 | P4 install | `bash install.sh` has side effects on user's real `~/.claude`. Plan offers "Option A or B" with no decision and no restoration. | Pre-flight detect existing VF. Snapshot: `tar czf /tmp/vf-pre-install-*.tgz ~/.claude/`. Pick Option B (symlink) unambiguously. |
| H11 | P4 env | `SCRATCH=/tmp/vf-live-test-*` is volatile. /tmp wipes on reboot → evidence paths break. | Use `~/Desktop/vf-live-test-*` or similar. Capture evidence inline, not as path refs. |
| H12 | P5 target | `demo/python-api/` is a controlled fixture. Doesn't satisfy B2 "first real run against real project." | Two targets: (1) demo smoke test, (2) one external open-source repo. |
| H13 | P5 M2 | Detection test against 1 platform proves nothing about M2 (multi-platform). | Test ≥3 platforms: API, Web, CLI. |
| H14 | P7 | Step 2 `mv` + Step 4 `git rm` conflict. After mv, `git rm` no-ops; commit drops boulder.json instead of recording rename. | Replace with `git mv`. Drop separate `git rm`. |
| H15 | P7 DEFERRED | 11 DEFERRED rows in CAMPAIGN_STATE — each could be hours. 1.5h budget explodes if "DO NOW" chosen. | Pre-triage 11 items. Cap DO NOW at 45 min. Spin rest to new plan. |
| H16 | P9 M1 | "Deep review" has no quality bar. "Read 100 lines and flag contradictions" = skim. | Define: ≥1 proposed edit OR signed "no changes needed" note + frontmatter verify + cross-ref check. File per skill. |
| H17 | P9 scope | 3h for M1 top-10 + M3 + M4 + M5 + M6 is fiction. Top-10 at 15 min each = 2.5h alone. | Split: 9a (M1, 3h) + 9b (M3-M6 + commit, 1h). |
| H18 | Order | **Self-binding rule violation:** Rule #7 says "B before H before M." Execution order runs P2 (H1), P3 (H6, H7) before P4/P5 (B2, B3, B4, B5). | Either fix rule or fix order. |
| H19 | P1 Commit 3 (stack) | `.gitignore` trap (C2) + symlink confusion (C1) + no verification of `git add -f` landing means Commit 3 can fail silently in 3 different ways. | Atomic verification after add: `git diff --cached --numstat .claude/` must show 2 files added, 1 symlink removed. |

## Medium issues (20)

Summary (full table in review narrative):
- M1-M5: Plan-wide concerns (time estimates, rollback, session continuity, concurrent-session protection, commit split)
- M6-M10: Phase-specific (hook audit enforcement, README lint, detection tests, stash count drift, parser brittleness)
- M11-M15: Verification quality (pass/fail automation, demo GIF proof, find ambiguity, M9 dates, triage criteria)
- M16-M20: Scope creep (P6 step 4 out-of-scope, M3/M4 relabeling, no-regression block, TECHNICAL-DEBT orphan refs, success shell golf)

## Low issues (3)

- L1: 15h estimate ambiguity (wall vs session runtime)
- L2: P0 Python heredoc overkill (sed one-liner suffices)
- L3: P1 Commit 4 j5-reverify.txt ordering nit

---

## Rework priorities

**Before ANY execution, fix all Critical + High (26 items).** The 20 Medium should be fixed in the same rewrite pass because most are trivial strengthening.

**Structural changes required:**
1. Add regression gates after Phases 1, 2, 7
2. Split plan into auto vs manual (C6)
3. Re-scan inventory against live SKILLS.md (H7)
4. Add unified rollback matrix + session-continuity log + concurrent-session lock
5. Move Phase 6 recoverability check to start (C7)
6. Fix all `|| true` suppressions in destructive operations (H8, stash drops, git push delete)
7. Split bundled commits (P1 Commit 2, 5, 6)
8. Reorder commits so plan-dir references are valid (C3)

**Estimate:** Plan rewrite itself = ~2-3h focused work. Then re-red-team, then execute.

---

## Key quote from Oracle

> "The plan has good bones — phase structure, dependency graph, and rollback tags show care — but the per-step details are too optimistic, too brittle, and too reliant on silent-failure patterns to ship as-is. **Do not execute until at least every Critical and High issue has an explicit fix committed to plan.md.**"

Source: Oracle session `ses_2814385adffeZeoLi5zc55U26X` (to continue: pass that session_id to task agent)
