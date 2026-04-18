# Phase 6 — Functional Validation (End-to-End, NO MOCKS)

## 1. Context Links

- Parent plan: `/Users/nick/Desktop/validationforge/plans/260417-1715-insights-ambitious-workflows/plan.md`
- Upstream Phases 1-5: lib, enforcer, tuner, swarm, headless runners
- Refs:
  - `~/.claude/rules/validation-discipline.md` — real-system validation, no mocks, evidence citations
  - `~/.claude/rules/vf-evidence-management.md` — file naming + inventory requirements
  - Project `CLAUDE.md` — no mocks/stubs/test-files (functional validation mandate)
  - `/Users/nick/Desktop/validationforge/.claude/rules/evidence-before-completion.md`

## 2. Overview

- **Priority:** P0 (no phase is "done" until this phase's evidence exists)
- **Status:** pending (Phases 1-5 required)
- **Description:** Run all three workflows end-to-end against real systems, capture observable evidence (stdout/stderr/exit codes, JSON campaign files, SQLite rows, PR URLs, git refs, log tails), file evidence reports under the plan's `reports/` dir. This phase does NOT write tests, mocks, or simulated fixtures — all validation hits real code paths.

## 3. Key Insights

- Project rule: "Compilation success ≠ functional validation." Every claim must cite a specific evidence artifact.
- yt-shorts-detector is the live test bed. We must NOT corrupt real GT files — all GT Tuner experimentation happens in a dedicated worktree on a throwaway branch `gt-tuner-probe/phase-6`.
- Root-Cause Enforcer validation needs a seeded bug that the user consents to. We use a fake bug in a scratch file — `src/yt_shorts_detector/_probe.py` created just for this phase and deleted after.
- Swarm validation runs against a tiny seeded module in `/tmp/vf-swarm-probe-<timestamp>/` (a real git repo with a known bug) so we don't pollute yt-shorts-detector's bug tracker.
- Every evidence file must be >0 bytes (per `vf-evidence-management.md`).

## 4. Requirements

### Functional
- F1: Evidence dir: `/Users/nick/Desktop/validationforge/plans/260417-1715-insights-ambitious-workflows/reports/e2e-evidence/`
  - Subdirs: `enforcer/`, `tuner/`, `swarm/`, `lib-harness/`
- F2: Each subdir has an `evidence-inventory.txt` listing all files + byte counts.
- F3: Each subdir has a verdict file `verdict.md` citing specific evidence per criterion.
- F4: Three synthesis reports:
  - `functional-validation-enforcer-260417.md`
  - `functional-validation-tuner-260417.md`
  - `functional-validation-swarm-260417.md`
- F5: All runs captured with `script`/`tee`/redirect — exact stdout/stderr preserved.

### Non-functional / Safety
- NF1: No modifications to real GT JSON files. Tuner runs on `gt-tuner-probe/phase-6` branch only; final `git status` must show no staged/unstaged changes to `videos/*.groundtruth.json` on main.
- NF2: All probe files (`src/yt_shorts_detector/_probe.py`, `/tmp/vf-swarm-probe-*`) cleaned up post-phase with a documented cleanup script.
- NF3: Swarm run is budget-capped (`CLAUDE_RUN_TOKEN_CAP=500000`, `--timeout 1200`) — this is a validation run, not a full campaign.
- NF4: Tuner run is budget-capped to ONE iteration (`max_iterations=1` in config override).

## 5. Architecture

### Evidence directory layout
```
plans/260417-1715-insights-ambitious-workflows/reports/
├── e2e-evidence/
│   ├── lib-harness/
│   │   ├── step-01-harness-run.txt
│   │   ├── step-02-checkpoints-log-tail.txt
│   │   ├── step-03-schema-list.txt
│   │   ├── evidence-inventory.txt
│   │   └── verdict.md
│   ├── enforcer/
│   │   ├── step-01-attempt-edit-without-evidence.txt   (stderr + exit code)
│   │   ├── step-02-evidence-md-seeded.md
│   │   ├── step-03-retry-edit-success.txt
│   │   ├── step-04-five-file-diff-blocked.txt
│   │   ├── step-05-bypass-env-var-allowed.txt
│   │   ├── step-06-bypass-log-entry.txt
│   │   ├── step-07-hook-latency-nonsrc.txt
│   │   ├── evidence-inventory.txt
│   │   └── verdict.md
│   ├── tuner/
│   │   ├── step-01-config-dump.json
│   │   ├── step-02-one-iter-run.jsonl            (headless JSONL log)
│   │   ├── step-03-subagent-proposal-json.json
│   │   ├── step-04-worktree-regression-stdout.txt
│   │   ├── step-05-merge-predicate-decision.txt
│   │   ├── step-06-campaign-json-final.json
│   │   ├── step-07-sqlite-iter-summary.txt
│   │   ├── step-08-failed-approaches-md.md
│   │   ├── step-09-abort-drain.txt
│   │   ├── evidence-inventory.txt
│   │   └── verdict.md
│   └── swarm/
│       ├── step-01-seeded-repo-tree.txt
│       ├── step-02-scout-transcript.jsonl
│       ├── step-03-reproduction-sh.txt
│       ├── step-04-reproduction-first-exit.txt    (shows non-zero, bug present)
│       ├── step-05-fixer-transcript.jsonl
│       ├── step-06-reproduction-after-fix.txt     (shows exit 0)
│       ├── step-07-reviewer-transcript.jsonl
│       ├── step-08-pr-url-and-diff.txt
│       ├── step-09-checkpoint-resume-diff.txt
│       ├── evidence-inventory.txt
│       └── verdict.md
├── functional-validation-enforcer-260417.md
├── functional-validation-tuner-260417.md
└── functional-validation-swarm-260417.md
```

### Verdict template (per subdir)
```
# Verdict: <workflow>
Criterion 1: <text>
  - Evidence file: step-NN-<name>.<ext>
  - Cited line / exit code / field:
  - Match: YES | NO
  - PASS | FAIL
(repeat per criterion)
Final: PASS | FAIL
```

## 6. Related Code Files

**CREATE (evidence artifacts; not source):**
- all files listed under §5 layout
- `/Users/nick/Desktop/validationforge/plans/260417-1715-insights-ambitious-workflows/scripts/phase6-cleanup.sh` (tears down probe files)
- `/Users/nick/Desktop/validationforge/plans/260417-1715-insights-ambitious-workflows/scripts/phase6-runbook.md` (exact command sequences)

**MODIFY:** none (phase is validation-only; any prod changes are reverted).

**DELETE:** post-phase cleanup removes:
- `yt-transition-shorts-detector/src/yt_shorts_detector/_probe.py`
- `yt-transition-shorts-detector/.debug/rc-enforcer-test/`
- `/tmp/vf-swarm-probe-<timestamp>/`
- Branch `gt-tuner-probe/phase-6` (after evidence captured)

## 7. Implementation Steps

### 7.A Phase 1 lib harness validation
1. Run `node ~/.claude/scripts/common/checkpoint-lib.test-harness.js --confirm 2>&1 | tee .../lib-harness/step-01-harness-run.txt`. Expect four `HARNESS PASS:` lines.
2. `tail -20 ~/.claude/state/checkpoints.log > .../lib-harness/step-02-checkpoints-log-tail.txt`
3. `ls ~/.claude/state/schemas/ > .../lib-harness/step-03-schema-list.txt` — must list exactly 3 schemas.
4. Build `evidence-inventory.txt` with `find .../lib-harness -type f -exec wc -c {} \;`.
5. Write `verdict.md` citing each criterion.

### 7.B Root-Cause Enforcer validation
1. In yt-shorts-detector, checkout probe branch: `git checkout -b issue-rc-enforcer-test/probe`.
2. Create scratch `src/yt_shorts_detector/_probe.py` containing a clear seeded bug (e.g. off-by-one in a function) committed to the branch so there's a real src file to edit.
3. Attempt `Edit` on `_probe.py` WITHOUT creating `.debug/rc-enforcer-test/evidence.md`. Capture:
   - stderr: `... evidence.md missing ...`
   - exit code: 2
   - Save to `step-01-attempt-edit-without-evidence.txt`.
4. Write `.debug/rc-enforcer-test/evidence.md` following the checklist. Save a copy to `step-02-evidence-md-seeded.md`.
5. Retry `Edit` — expect exit 0. Capture full interaction to `step-03-retry-edit-success.txt`.
6. Induce a 5-file diff (touch 5 arbitrary src files). Attempt `Edit`. Capture exit 2 + reason to `step-04-five-file-diff-blocked.txt`.
7. Set `CLAUDE_SKIP_ROOT_CAUSE_GATE=1`, repeat attempt. Capture exit 0 + stderr bypass notice to `step-05-bypass-env-var-allowed.txt`.
8. `tail -1 ~/.claude/state/bypass.log > step-06-bypass-log-entry.txt`.
9. Time a non-src `Edit` (e.g. on a markdown file): `time node ~/.claude/hooks/root-cause-enforce-pre.js <stdin>` — capture to `step-07-hook-latency-nonsrc.txt`. Assert <300ms.
10. Build inventory + verdict.

### 7.C GT Tuner validation
1. Create worktree: `git worktree add ../yt-transition-shorts-detector_worktrees/tuner-phase6 gt-tuner-probe/phase-6`.
2. Override config with `max_iterations=1`, `max_parallel_subagents=2` and save to `step-01-config-dump.json`.
3. Run `./scripts/headless/gt-tuner.sh --config .gt-tuner/config.phase6.json` with budget cap; redirect JSONL to `step-02-one-iter-run.jsonl`.
4. Extract one subagent's JSON proposal from JSONL → `step-03-subagent-proposal-json.json`.
5. Extract regression stdout for the winning proposal's worktree → `step-04-worktree-regression-stdout.txt`.
6. Extract coordinator's predicate decision line → `step-05-merge-predicate-decision.txt` (must show `accept: true|false` with delta + regression check).
7. Copy final campaign JSON → `step-06-campaign-json-final.json`; validate with `node -e "require('~/.claude/scripts/common/checkpoint-lib').readCheckpoint(...)" ` and capture success.
8. `sqlite3 .gt-tuner/scoreboard.sqlite 'SELECT * FROM iter_summary;' > step-07-sqlite-iter-summary.txt` — must show ≥1 row.
9. `cat .gt-tuner/failed-approaches.md > step-08-failed-approaches-md.md`.
10. Kill-switch sub-test: start another iter, `touch .gt-tuner/ABORT` within 10s, capture wrapper stderr + exit → `step-09-abort-drain.txt`. Must show clean exit within 60s.
11. Build inventory + verdict.

### 7.D Bug-Audit Swarm validation
1. Create seeded repo: `/tmp/vf-swarm-probe-$(date +%s)/` with a small Python module containing a known bug (e.g. a CLI that crashes on empty input). Capture `tree` output → `step-01-seeded-repo-tree.txt`.
2. Run `~/.claude/scripts/headless/bug-audit-swarm.sh` in that repo, budget-capped. Route coordinator output to JSONL.
3. Extract scout's transcript turns → `step-02-scout-transcript.jsonl`.
4. Copy the reproduction script the scout created → `step-03-reproduction-sh.txt`.
5. Run the reproduction against the unfixed code; expect non-zero exit → `step-04-reproduction-first-exit.txt` (MUST capture exit code line).
6. Extract fixer's transcript → `step-05-fixer-transcript.jsonl`.
7. Run the reproduction against the fixed branch; expect exit 0 → `step-06-reproduction-after-fix.txt`.
8. Extract reviewer's transcript → `step-07-reviewer-transcript.jsonl`.
9. If PR created via `gh`, capture `gh pr view --json url,files` → `step-08-pr-url-and-diff.txt`. If no `gh` remote, capture `git log --format=fuller` + diff of the reviewed branch.
10. Resume test: kill coordinator between scout and fixer, restart with `--resume`, capture `diff` of pre/post-resume checkpoint → `step-09-checkpoint-resume-diff.txt`.
11. Build inventory + verdict.

### 7.E Synthesis
- Write three `functional-validation-*-260417.md` reports under `reports/`, each citing at least one evidence file per Success Criterion.
- Run `phase6-cleanup.sh` to tear down probe artifacts. Capture its stdout to `reports/phase6-cleanup-log.txt`.

### Safety gates
- Before ANY Tuner run, verify `git -C yt-transition-shorts-detector status` is clean on main and current branch is the worktree branch, not main. ABORT if not.
- Before ANY Swarm run, verify `pwd` is under `/tmp/vf-swarm-probe-*` — NEVER run swarm against yt-shorts-detector.
- Enforcer probe MUST delete `_probe.py` in cleanup; phase fails if cleanup leaves residue.

## 8. Todo List

- [ ] 7.A lib harness run + inventory + verdict
- [ ] 7.B enforcer scenarios 1-7 + inventory + verdict
- [ ] 7.C tuner one-iter + kill-switch + resume + inventory + verdict
- [ ] 7.D swarm scout→fixer→reviewer + resume + inventory + verdict
- [ ] 7.E synthesis reports (3 files)
- [ ] Cleanup script execution + log
- [ ] Verify no residue: `_probe.py`, `.debug/rc-enforcer-test`, `/tmp/vf-swarm-probe-*`, probe branches

## 9. Success Criteria

- All 4 `verdict.md` files exist and each ends with `Final: PASS`. Any FAIL → phase fails, escalate.
- Every evidence file >0 bytes (inventory verifies byte counts).
- Enforcer stderr lines cited verbatim in verdict.
- Tuner SQLite has ≥1 iter row; campaign JSON validates against schema.
- Swarm reproduction exits non-zero before fix and 0 after fix, both captured with `$?` lines.
- Cleanup log shows every probe artifact removed; `git status` on main is clean.
- Three synthesis reports saved under `reports/` and referenced from `plan.md` (add a "Validation" section link).

## 10. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Tuner corrupts real GT files | Low | Critical | Worktree-only; pre-flight `git status` assertion; main branch read-only. |
| Swarm probe leaks into yt-shorts-detector | Low | High | Hard pwd check: swarm runner refuses to start outside `/tmp/vf-swarm-probe-*`. |
| Enforcer probe file left in `src/` | Medium | Medium | Cleanup script; post-phase `find src -name _probe.py` must return empty. |
| Headless runner token cap hits before workflow completes minimum demo | Medium | Medium | Validation-only caps tuned above minimum turn budgets; retry once with doubled cap on first exhaustion. |
| `gh` CLI unavailable (no remote) | Medium | Low | Alternative evidence via `git log` + `git diff` captured; verdict accepts either. |
| Seeded bug too subtle for scout to find | Medium | Medium | Bug is deliberately obvious (e.g. `argv[1]` without length check); scout prompt hints seeded scope via `hypothesized_area`. |
| Resume test false-positive (no real state change) | Low | Medium | Diff command covers timestamps + attempt counters; verifier asserts counter incremented. |
| Evidence dir path collision with prior runs | Low | Low | Path includes plan folder timestamp; within-plan subdirs cleaned at start. |
| Phase exceeds wall-clock budget for the operator | Medium | Medium | Steps are independent; partial completion with explicit per-workflow verdicts is acceptable; unfinished workflows fail phase. |

## 11. Security Considerations

- All probe artifacts live under paths explicitly listed in the cleanup script. No wildcard `rm` against parent dirs.
- Swarm validation uses a throwaway `/tmp/` repo — even a worst-case rogue agent can only corrupt that repo.
- Tuner runs in a dedicated worktree on a probe branch — coordinator's merge-to-PR step is intercepted (no actual PR created during Phase 6; we capture the would-be PR content as evidence).
- All stderr/stdout captures are plain text — no execution of captured content.
- `gh` / `git push` NOT invoked during validation — evidence is local-only. Any PR creation is simulated via `git format-patch` output, captured as evidence, then discarded.
- Budget caps ensure a broken workflow cannot burn significant tokens during this phase.

## 12. Next Steps

- If all four verdicts PASS: merge plan status → `shipped`; update `plan.md` with a Validation section linking the three synthesis reports.
- If any FAIL: identify the defective phase, open remediation tasks; do NOT advance plan status. Re-run only the failing subdirectory's scenarios after fix.
- Long-term: wire these scenarios into a `/validate-sweep`-style nightly rerun against a pinned yt-shorts-detector SHA. Out of scope for this plan; tracked as a follow-up.
