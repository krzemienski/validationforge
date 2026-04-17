# Phase 3: Merge Orchestration Plan

**Main baseline:** `a73d9d9` (chore: archive skill-grading reports + 2026-04-17 benchmark)
**Total merges:** 7 (after completion of 002, 004; abandonment of 003, 005, 006)
**Expected final state:** Skills 48→52, Commands 17→19, Agents 5→7, Rules 8→9.

## Strategy

Two parallel workstreams, one serial merge line:

1. **Background: completion agents** for 002 (Phase 4-5 live verification) and 004 (CRITICAL fixes + 3 remaining reviews).
2. **Foreground: sequential merges** of already-ready branches while background work runs. Merges that depend on completions wait for their branch.

## Merge Order

| # | Branch | Depends on | Conflict risk | Validation criteria source |
|---|--------|-----------|---------------|---------------------------|
| 1 | 001 (e2e-pipeline-verification) | none | none (new paths + 1 enhanced script) | spec.md Phase 1 acceptance (scaffold + harness) |
| 2 | 015 (documentation-site) | none | none (site/-isolated) | `cd site && npm run build` produces ≥33 pages |
| 3 | 002 (plugin-live-load-verification) | 002 completion agent | low (plugin.json/hooks read-only, new evidence paths) | all 6 spec criteria PASS with live-session evidence |
| 4 | 004 (skill-deep-review-top-10) | 004 completion agent | medium (modifies 2 existing SKILL.md files) | 10/10 skills reviewed + 2 CRITICAL fixes applied + re-validated |
| 5 | 019 (consensus-engine) | none | high (first conflict-cluster merge — largest inventory delta) | spec criteria + /validate-consensus dogfood PASS |
| 6 | 012 (evidence-summary-dashboard) | 019 merged (inventory rebase) | high (README/SKILLS/COMMANDS conflict vs 019) | dashboard generates real HTML/MD from e2e-evidence/ |
| 7 | 013 (ecosystem-integration-guides) | 019 + 012 merged (inventory rebase) | medium (README integration section + docs/README inventory row) | all integration guides present + cross-links resolve |

## Per-merge PASS criteria

### Merge 1 — 001
- [ ] `git merge auto-claude/001-end-to-end-pipeline-verification` succeeds (no conflicts).
- [ ] `bash -n scripts/e2e-pipeline-check.sh` exits 0.
- [ ] `bash -n scripts/verify-setup.sh` exits 0.
- [ ] `ls e2e-evidence/pipeline-verification/run-book.md` → file exists.
- [ ] Main's `ls scripts/` count increased by 1 (new e2e-pipeline-check.sh).

### Merge 2 — 015
- [ ] Merge succeeds.
- [ ] `cd site && npm ci` completes without error.
- [ ] `cd site && npm run build` produces static pages.
- [ ] Sample page file exists: `site/src/content/docs/index.mdx`.

### Merge 3 — 002 (post-completion)
- [ ] 002 completion agent reports all 6 acceptance criteria PASS.
- [ ] Evidence inventory present at `e2e-evidence/plugin-load-verification/VERDICT.md`.
- [ ] Merge succeeds.
- [ ] `ls hooks/` count unchanged from pre-merge (002 is read-only verification).
- [ ] Inventory counts in README/SKILLS/COMMANDS unchanged (002 adds no primitives).

### Merge 4 — 004 (post-completion)
- [ ] 004 completion agent reports: 10/10 skills reviewed, 2 CRITICAL findings fixed, re-validation PASS.
- [ ] Merge succeeds.
- [ ] Modified SKILL.md files parse as valid YAML + markdown.
- [ ] `grep -q "preflight" skills/e2e-validate/SKILL.md` → hit (Iron Rule #4 fix).
- [ ] `bash -n` succeeds on any shell additions.

### Merge 5 — 019
- [ ] Merge succeeds (conflicts expected on README/SKILLS/COMMANDS — resolve additively).
- [ ] 3 new skills present: `skills/consensus-engine/SKILL.md`, `skills/consensus-synthesis/SKILL.md`, `skills/consensus-disagreement-analysis/SKILL.md`.
- [ ] 1 new command: `commands/validate-consensus.md`.
- [ ] 1 new rule file present.
- [ ] SKILL.md YAML parses for all new skills.
- [ ] `bash -n` on new benchmark script succeeds.
- [ ] Inventory counts in README.md accurate: Skills: 51, Commands: 18, Rules: 9.

### Merge 6 — 012
- [ ] Merge succeeds after conflict resolution.
- [ ] `skills/evidence-dashboard/SKILL.md` present.
- [ ] `commands/validate-dashboard.md` present.
- [ ] `bash -n scripts/generate-dashboard.sh` exits 0.
- [ ] Templates present: `templates/dashboard.html.tmpl`, `templates/dashboard.md.tmpl`.
- [ ] Inventory counts: Skills: 52, Commands: 19.

### Merge 7 — 013
- [ ] Merge succeeds.
- [ ] `ls docs/integrations/` shows the new guides.
- [ ] README.md "Works With Other Plugins" section present.
- [ ] `docs/README.md` Integration Guides inventory row present.

## Abandonment protocol (003, 005, 006)

1. Do NOT merge.
2. Capture final-state evidence: `git log --oneline main..auto-claude/<branch>` → preserve in `worktree-merge-evidence/abandoned/<branch>-final-log.txt`.
3. Document reason in `disposition.md` (already done).
4. Phase 6 cleanup: `git worktree remove` + `git branch -D`.

## Failure protocol

Per skill rules:
- Merge conflict unresolvable → `git merge --abort`, document in merge-log.md, route to Immediate Remediation.
- Build fails post-merge → `git reset --hard HEAD~1` (revert merge commit), investigate, fix, retry.
- After 3 consecutive failures on same branch → mark UNFIXABLE and move on.

## Ongoing evidence

Each merge writes to `worktree-merge-evidence/phase-4-merges/merge-NN-<branch>/`:
- `pre-merge-status.txt` — `git status` + `git log main..<branch> --stat`
- `merge-output.txt` — full `git merge` stdout/stderr
- `post-merge-build.txt` — whatever build step applies
- `post-merge-validation.md` — per-criterion PASS/FAIL with cited evidence
- `conflict-resolution.md` (if conflicts) — what was chosen and why

## Advancement rules

- Next merge begins ONLY after previous merge's PASS gate satisfies `gate-validation-discipline`.
- 002 and 004 have completion agents running in parallel; if a completion agent reports FAIL or BLOCKED, that merge is deferred and subsequent merges proceed around it.
- No merge proceeds on a dirty main.
