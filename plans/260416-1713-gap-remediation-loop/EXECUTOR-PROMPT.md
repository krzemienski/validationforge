---
name: Autonomous Loop Executor Prompt
date: 2026-04-16
purpose: Gated execution prompt for the main orchestrator to drive the gap-remediation loop
source: /transform-validation-prompt applied to 260416-1713-gap-remediation-loop/
platform: Generic (meta-plan over Node/npm + shell + git)
---

# Autonomous Loop Executor Prompt

Feed this to the main orchestrator (or an executor sub-agent) to drive the
ValidationForge gap-remediation campaign from P00 through P13 with BLOCKING
validation gates at every boundary. Each phase file already contains a detailed
`<validation_gate id="VG-NN">`. This prompt threads them into a single gated
sequence an executor can follow.

<mock_detection_protocol>
Before executing any task, check intent:
- Creating `*.test.*`, `*_test.*`, `*Tests.*`, `test_*`, `*.spec.*` files → STOP
- Importing mock libraries (`jest.mock`, `sinon`, `nock`, `unittest.mock`, `td`) → STOP
- Creating in-memory databases (SQLite `:memory:`, H2, `better-sqlite3 :memory:`) → STOP
- Adding `TEST_MODE`, `NODE_ENV=test`, or `MOCK_EXTERNAL` flags → STOP
- Rendering components in isolation (`@testing-library`, Storybook) → STOP
- Disabling `hooks/block-test-files.js` or any hook as a workaround → STOP
Fix the REAL system instead. No exceptions.
</mock_detection_protocol>

<iron_rules>
1. IF the real system doesn't work, FIX the real system.
2. NEVER create mocks, stubs, test doubles, or test files.
3. NEVER mark a phase CLOSED without a validator verdict citing specific evidence.
4. NEVER advance past a failing gate. Loop, fix, re-run — up to 3 attempts.
5. NEVER self-validate. Always dispatch a separate validator sub-agent (Agent
   tool, read-only type).
6. Main orchestrator dispatches; it does NOT implement or write verdicts.
</iron_rules>

<context>
Plan root: `/Users/nick/Desktop/validationforge/plans/260416-1713-gap-remediation-loop/`
Work context: `/Users/nick/Desktop/validationforge`
Loop protocol: `LOOP-CONTROLLER.md`
Gap register: `GAP-REGISTER.md` (22 OPEN rows)
Validator template: `validators/validator-template.md`
State file: `logs/state.json` (schema in LOOP-CONTROLLER.md)
Decisions: `logs/decisions.md` (U1, U2, U3)
</context>

---

<task id="1" phase="P00" depends_on="">
Run preflight: capture baseline, resolve U1–U3, initialize state.
Phase file: `phase-00-preflight.md`
Executor: `researcher` | Validator: `code-reviewer`
</task>

<validation_gate id="VG-P00" blocking="true">
Prerequisites: `git status --short` clean OR plan dir only | `ls .vf/benchmarks/` ≥1 file OR flag risk | AskUserQuestion answered U1 (test|defer), U2 (all|top-20), U3 (drop|cherry-pick).
Execute: dispatch executor via Agent(subagent_type=researcher) with phase-00 pass_criteria verbatim + work context paths.
Capture: `evidence/00-preflight/{baseline.md,inventory-diff.txt,active-plan-state.md,git-status.txt,git-head.txt,demo-matrix.md}` | `logs/decisions.md` | `logs/state.json`.
Pass criteria: all 6 criteria in phase-00 §Pass criteria PASS | `validators/P00-verdict.md` exists, verdict field = PASS | `jq .current_phase logs/state.json` = "P01".
Review: `cat validators/P00-verdict.md` | `jq -e '.current_phase == "P01"' logs/state.json`.
Verdict: PASS → advance P01 | FAIL → re-dispatch (attempt++); attempt > 3 → write `logs/escalation-P00.md`, halt, notify user.
Mock guard: P00 is read-only (scan + user Q&A); any mock creation = IMMEDIATE STOP.
</validation_gate>

<task id="2" phase="P01" depends_on="P00">
Execute active plan 260411-2305 Phases C→H end-to-end; close P01, P06.
Phase file: `phase-01-active-plan-completion.md` (contains full VG-01 with verbatim run.sh markers)
Executor: `fullstack-developer` | Validator: `code-reviewer`
</task>

<validation_gate id="VG-P01" blocking="true">
Prerequisites: P00 verdict = PASS | `.vf/.gap-validation.lock` absent | `demo-matrix.md` resolves platform minimum (≥2).
Execute: dispatch executor; executor runs `cd plans/260411-2305-gap-validation && bash run.sh 2>&1 | tee ../../260416-1713-gap-remediation-loop/evidence/01-active-plan/run.log`.
Capture: `evidence/01-active-plan/{run.log,phase-markers.txt,run-exit-code.txt,summary.md}` | `.vf/benchmarks/benchmark-260416-*.json`.
Pass criteria: 14 verbatim phase markers present (PREFLIGHT/C/D/E/F/G/H × START+END) | per-phase evidence non-empty | summary.md per-phase verdict = PASS | Phase 6b ≥2 platforms OR BLOCKED_WITH_USER with follow-up stub | `run-exit-code.txt` = 0.
Review: `grep -c '^--- PHASE ' evidence/01-active-plan/phase-markers.txt` must = 14 | `cat evidence/01-active-plan/run-exit-code.txt` must = 0 | validator reads summary.md and opens each cited evidence path (wc -c > 0).
Verdict: PASS → advance P02; queue P04, P06 unblocked | FAIL → attempt++; attempt > 3 → escalate.
Mock guard: `run.sh` intentionally probes `block-test-files.js` at C-M2 — hook MUST reject; DO NOT disable it.
</validation_gate>

<task id="3" phase="P02" depends_on="P00">
Decide disposition of 3 orphan hooks (config-loader, patterns, verify-e2e): REGISTER | RELOCATE | DELETE; close H-ORPH-1..3.
Phase file: `phase-02-orphan-hook-decision.md`
Executor: `fullstack-developer` | Validator: `code-reviewer`
</task>

<validation_gate id="VG-P02" blocking="true">
Prerequisites: P00 verdict = PASS | `hooks/hooks.json` parses as valid JSON.
Execute: executor classifies each orphan via grep for callers; drafts `decision.md` with rationale; executes each decision (edit hooks.json for REGISTER, `git mv` for RELOCATE, `git rm` for DELETE); smoke-tests REGISTERs.
Capture: `evidence/02-orphan-hooks/{decision.md,hooks-json-before.txt,hooks-json-after.txt,git-diff.patch,<hook>-fires.txt,caller-grep.txt}`.
Pass criteria: 3 orphans each have explicit disposition | REGISTERed hooks have smoke-test proof of firing | RELOCATEd hooks have `git mv` diff + grep showing no old-path callers | DELETEd hooks have `git rm` diff + content justification | `node -e "JSON.parse(require('fs').readFileSync('hooks/hooks.json'))"` exits 0 | dispositions sum to 3 matching actual git changes.
Review: `jq '.hooks | keys | length' hooks/hooks.json` + validator reads decision.md and cross-checks every row's evidence file.
Verdict: PASS → advance P03 | FAIL → attempt++.
Mock guard: smoke-tests invoke real hook scripts with synthetic tool payloads — NO test files authored.
</validation_gate>

<task id="4" phase="P03" depends_on="P02">
Sync CLAUDE.md + SKILLS.md + COMMANDS.md counts to disk reality; close INV-1..3.
Phase file: `phase-03-inventory-sync.md`
Executor: `fullstack-developer` | Validator: `code-reviewer`
</task>

<validation_gate id="VG-P03" blocking="true">
Prerequisites: P02 verdict = PASS (hook count finalized).
Execute: executor captures disk counts (`ls -1 skills/ | wc -l` etc.), diffs against CLAUDE.md claims, updates doc files, runs final diff.
Capture: `evidence/03-inventory/{before-counts.txt,after-counts.txt,claude-md-diff.patch,skills-md-diff.patch,commands-md-diff.patch,final-diff.txt}`.
Pass criteria: CLAUDE.md skill count = `ls -1 skills/ | wc -l` | commands count = `ls -1 commands/*.md | wc -l` | hooks count = hooks in hooks.json | agents count = 5 | rules count = 8 | SKILLS.md Specialized matches CLAUDE.md | `final-diff.txt` shows zero discrepancies.
Review: validator runs each counting command itself, compares to CLAUDE.md section headers, asserts match.
Verdict: PASS → advance (queue P06, P08) | FAIL → attempt++.
Mock guard: counts derived from real `ls`, not cached; no synthetic inventory.
</validation_gate>

<task id="5" phase="P04" depends_on="P01">
Validate platform-detector agent against ≥5 external repo specimens; close H4.
Phase file: `phase-04-platform-detection-external.md`
Executor: `researcher` | Validator: `researcher` (read-only)
</task>

<validation_gate id="VG-P04" blocking="true">
Prerequisites: P01 verdict = PASS | ≥5 external specimens available on disk OR cloneable via `gh repo clone` into `/tmp/vf-platform-specimens/`.
Execute: executor invokes platform-detector on each specimen, captures classification, compares to expected.
Capture: `evidence/04-platform-detect/{specimens.md,<specimen>.md,summary.md,mismatches.md}`.
Pass criteria: ≥5 specimens covering iOS, Python API, CLI, Fullstack, ambiguous edge case | per specimen: source URL + HEAD SHA + expected + actual + TRUE/FALSE/PARTIAL | aggregate accuracy ≥80% (≥4/5) | mismatches have root cause + proposed patch.
Review: validator opens each specimen file, asserts URL+SHA present, confirms accuracy computation.
Verdict: PASS → advance P05 | FAIL (<80%) → attempt++; propose platform-detector patch then re-run.
Mock guard: specimens are REAL external repos (or clones), NOT synthetic fixtures. No platform-detector modification unless accuracy < 80%.
</validation_gate>

<task id="6" phase="P05" depends_on="P01,P04">
Prove 5-scenario benchmark claim with pre-existing oracles; close B5.
Phase file: `phase-05-benchmark-scenarios.md` (contains full VG-05 with Iron Rule guard and reality table)
Executor: `fullstack-developer` | Validator: `code-reviewer`
</task>

<validation_gate id="VG-P05" blocking="true">
Prerequisites: P01+P04 verdicts = PASS | demo-matrix.md resolves each canonical scenario to IN-SCOPE / OUT-OF-SCOPE | each IN-SCOPE scenario's demo has PRE-EXISTING oracle file (verified via `git show HEAD:<oracle-file>` non-empty).
Execute: per IN-SCOPE scenario S: `git worktree add /tmp/vf-bench-<S> HEAD`, apply defect patch, commit, run `/validate` → capture verdict, run demo's pre-existing oracle → capture exit code, remove worktree.
Capture: `evidence/05-benchmark/{scenarios.md,<S>-setup.patch,<S>-defect-sha.txt,<S>-vf-output.md,<S>-oracle.txt,<S>-oracle-cmd.txt,scoreboard.md}`.
Pass criteria: scenarios.md lists IN-SCOPE rows with mutation_cmd + defect_sha + oracle_cmd + oracle_file | per in-scope: VF verdict = FAIL AND cites mutated file path (grep-verifiable) | oracle PASSes (exit 0 + green stdout) AND oracle file pre-existed at HEAD^ | scoreboard reports `N_vf/N_scope` and `N_oracle/N_scope` with N_scope = in-scope count | OUT-OF-SCOPE scenarios recorded as BLOCKED_WITH_USER.
Review: validator opens each `<S>-vf-output.md`, greps for mutated path; runs `git show HEAD^:<oracle-file> | wc -c` in the worktree to confirm oracle pre-existence; reads oracle exit code.
Verdict: PASS → B5 CLOSED; competitive claim may cite scoreboard exact ratio | FAIL → B5 stays OPEN; honest ratio published; README MUST NOT claim 5/5-vs-0/5 unless scoreboard shows it.
Mock guard: Oracle MUST pre-exist in demo; if missing → BLOCKED_WITH_USER, NEVER fabricated. The draft's "synthesize a minimal one inline" is REMOVED.
</validation_gate>

<task id="7" phase="P06" depends_on="P03">
Execute plan 260411-1731 Phases 1-6 skill remediation; close R1..R4.
Phase file: `phase-06-skill-remediation.md`
Executor: `fullstack-developer` | Validator: `code-reviewer`
</task>

<validation_gate id="VG-P06" blocking="true">
Prerequisites: P03 verdict = PASS (skill inventory frozen).
Execute: executor audits body-description congruence (R1), trims 4 over-length descriptions (R2), fixes forge-benchmark body table (R3), trims context bloat to ≤9,000 chars (R4).
Capture: `evidence/06-skill-remed/{audit.md,trim-descriptions.patch,forge-benchmark.patch,context-trim.patch,pre-count.txt,final-count.txt,spot-check.md}`.
Pass criteria: audit.md has PASS/SUBTLE/FAIL row per skill | 4 over-length descriptions now ≤1,024 chars (diff verifies) | forge-benchmark 4-dimension table matches `scripts/benchmark/score-project.sh` weights | aggregate body char count ≤ 9,000 (`wc -c` over SKILL.md bodies minus frontmatter) | 5-skill spot-check confirms trigger activation preserved.
Review: validator reads spot-check.md, opens 5 trimmed skills, verifies triggers still make sense; runs char-count independently.
Verdict: PASS → advance P07 | FAIL → attempt++; if semantic degradation → escalate to user for char-budget tradeoff acceptance.
Mock guard: trims real SKILL.md bodies; no fixture skills authored.
</validation_gate>

<task id="8" phase="P07" depends_on="P06">
Deep-review remaining skills per U2 decision; close H1.
Phase file: `phase-07-skill-review-sweep.md`
Executor: parallel pool of 3-5 `researcher` agents | Validator: `code-reviewer`
</task>

<validation_gate id="VG-P07" blocking="true">
Prerequisites: P06 verdict = PASS | `logs/decisions.md` U2 = "all" (review 38) OR "top-20".
Execute: partition skill list across 3-5 parallel researcher sub-agents (assignment-map.md); each owns 8-10 skills; writes per-skill evidence files.
Capture: `evidence/07-skill-review/{reviewed.md,assignment-map.md,needs-fix.md,<skill>.md}`.
Pass criteria: reviewed.md rows count = U2 decision exactly (no drift) | per reviewed: evidence file cites frontmatter check + trigger realism + body-description alignment + MCP tool existence + example invocation proof | every NEEDS_FIX has one-line proposed patch | every FAIL has blocking issue + opens new plan stub.
Review: validator verifies partition (no overlap, no gap), samples 5 randomly chosen per-skill files for completeness.
Verdict: PASS → advance P08 | FAIL → re-partition + re-dispatch.
Mock guard: review reads real SKILL.md files; no fixture review outputs.
</validation_gate>

<task id="9" phase="P08" depends_on="P05,P07">
CONSENSUS + FORGE engines: test OR formally defer per U1.
Phase file: `phase-08-engines-consensus-forge.md` (contains test/defer branches with explicit gates)
Executor: `fullstack-developer` (test) OR `researcher` (defer) | Validator: `code-reviewer`
</task>

<validation_gate id="VG-P08" blocking="true">
Prerequisites: P05+P07 verdicts = PASS | `logs/decisions.md` line matching `^U1: (test|defer)$`.
Execute: branch on U1. Test: /validate-team 3-validator staging (3-agree/2-agree/1-agree) + /forge-execute on a P05 in-scope shallow defect (≤3 iterations). Defer: grep exhaustive scrub targets (README, COMPETITIVE-ANALYSIS, CLAUDE, SPECIFICATION, SKILLS, COMMANDS, docs/**/*.md, site/**/*.md) for forbidden phrases, patch to "planned" language.
Capture: test branch → `evidence/08-engines/{consensus-3agree.md,consensus-2agree.md,consensus-1agree.md,forge-loop-transcript.md,forge-fix-diff.patch}` | defer branch → `docs/ENGINES-DEFERRED.md` + `evidence/08-engines/{claims-grep-before.txt,claims-grep-after.txt,defer-scrub-diff.patch}`.
Pass criteria: see phase-08 VG-08 per-branch criteria (explicit CONSENSUS verdict literals, FORGE ≤3 attempts, scrub AFTER grep = zero matches, deferment-exit criteria measurable, CLAUDE.md updated).
Review: validator reads U1 line, selects branch, runs the greps/applies against post-scrub tree, confirms required literals present/absent.
Verdict: PASS → advance P09 | FAIL → attempt++.
Mock guard: Test branch uses REAL demo worktree defect; NO test files. Defer branch: no mocks applicable.
</validation_gate>

<task id="10" phase="P09" depends_on="P00">
Implement evidence retention + `--clean` + lock protocol; close M4.
Phase file: `phase-09-evidence-retention.md` (contains full VG-09 with concurrency note)
Executor: `fullstack-developer` | Validator: `code-reviewer`
</task>

<validation_gate id="VG-P09" blocking="true">
Prerequisites: P00 verdict = PASS | `.vf-config.json` OR `config/standard.json` fallback | `.vf/state/validation-in-progress.lock` absent OR stale >1h.
Execute: executor cites existing `.gitignore:8-13` (already excludes e2e-evidence), implements `--clean` with retention_days capture at start, implements `--clean --dry-run`, wires lock-file protocol (reuses run.sh:27-37 idiom), demonstrates with `/tmp/vf-cleanup-demo/` synthetic old dir.
Capture: `evidence/09-retention/{gitignore-snapshot.txt,clean-implementation.patch,demo-transcript.md,cleanup.log,lock-refusal.txt,stale-lock-proceed.txt}`.
Pass criteria: gitignore snapshot shows existing block + comment pointing at rules/evidence-management.md | `--clean` removes only dirs older than retention | `--clean --dry-run` lists targets without deleting | live lock refuses cleanup with literal "validation in progress" in stderr | stale lock (>1h, dead PID) proceeds with WARN log | cleanup.log format matches `<ISO-8601 UTC> | <path> | <mtime> | <action>` | campaign evidence dirs NOT removed | `git diff --exit-code rules/evidence-management.md` = 0.
Review: validator greps .gitignore, cats demo-transcript + both lock scenarios, tails cleanup.log and regex-matches format, lists evidence/*/ before+after asserting identical.
Verdict: PASS → advance P10 | FAIL → escalate. CRITICAL: if --clean removed a live-campaign evidence dir, HALT campaign and restore from git.
Mock guard: real `/validate --clean` code path; synthetic path under `/tmp/`; real `kill -0` for PID checks.
</validation_gate>

<task id="11" phase="P10" depends_on="P02,P09">
Wire config profile enforcement into hooks using real schema; close M7.
Phase file: `phase-10-config-enforcement.md` (contains full VG-10 with corrected schema + per-hook matrix)
Executor: `fullstack-developer` | Validator: `code-reviewer`
</task>

<validation_gate id="VG-P10" blocking="true">
Prerequisites: P02+P09 verdicts = PASS | `config/{strict,standard,permissive}.json` parse as valid JSON.
Execute: executor implements shared resolver (`hooks/lib/resolve-profile.js`) with precedence `VF_PROFILE > ~/.claude/.vf-config.json strictness > config/standard.json`; patches each hook to consult resolved profile + per-hook enabled/warn/disabled state; runs per-profile demo with synthetic probe under `/tmp/vf-profile-demo/`; tests env-override (`DISABLE_OMC`) precedence; tests rollback via `git stash`.
Capture: `evidence/10-config-profiles/{hook-patches.patch,resolver-fallback.txt,strict-demo.txt,standard-demo.txt,permissive-demo.txt,env-override-demo.txt,regression-check.md,rollback-demo.txt}`.
Pass criteria: resolver cites env-precedence line number | fallback to standard when no user config | strict-demo contains "BLOCK" or exit 2 | standard-demo contains "BLOCK" or exit 2 (block_mock_patterns:true) | permissive-demo contains "warn" and exit 0 | DISABLE_OMC overrides profile to exit 0 | regression-check shows P02 behavior preserved under standard | rollback-demo shows pre-P10 behavior restored.
Review: validator opens resolver file at cited line, cats each demo file and greps literals, diffs regression-check vs P02 outputs.
Verdict: PASS → advance P11 | FAIL → escalate. CRITICAL: if any hook stops firing under standard, revert P10 commit.
Mock guard: probe files under `/tmp/vf-profile-demo/` NOT inside ValidationForge sources. No test files authored in this repo.
</validation_gate>

<task id="12" phase="P11" depends_on="P00">
Execute Spec 015 disposition (drop|cherry-pick) per U3; close M6.
Phase file: `phase-11-spec-015-decision.md`
Executor: `researcher` | Validator: `code-reviewer`
</task>

<validation_gate id="VG-P11" blocking="true">
Prerequisites: P00 verdict = PASS | `logs/decisions.md` U3 = "drop" OR "cherry-pick".
Execute: executor discovers quarantine branch via `git branch -a | grep 015`, captures git log summary, writes diff review, executes DROP or CHERRY_PICK workflow, updates VALIDATION_MATRIX.md and CAMPAIGN_STATE.md.
Capture: `evidence/11-spec-015/{branch-log.txt,diff-review.md,matrix-diff.patch,state-diff.patch}` | `docs/SPEC-015-DISPOSITION.md`.
Pass criteria: diff-review.md summarises deletions + additions + quarantine reason | SPEC-015-DISPOSITION.md records DROP (branch deleted, matrix notes closure) OR CHERRY_PICK (specific commits listed, applied as new plan) | VALIDATION_MATRIX and CAMPAIGN_STATE reflect decision.
Review: validator reads disposition doc + matrix diff + state diff, confirms decision consistency.
Verdict: PASS → advance P12 | FAIL → escalate (especially if cherry-pick regresses).
Mock guard: real git operations; no stubbed git history.
</validation_gate>

<task id="13" phase="P12" depends_on="P01,P02,P03,P04,P05,P06,P07,P08,P09,P10,P11">
Run full regression on P02/P03/P05 AND final benchmark; close ALL.
Phase file: `phase-12-regression-final.md`
Executor: `fullstack-developer` | Validator: `code-reviewer` team (3 regression sub-agents + overall)
</task>

<validation_gate id="VG-P12" blocking="true">
Prerequisites: Phases P01..P11 verdicts = PASS (state.json confirms).
Execute: dispatch 3 regression sub-agents in parallel for P02/P03/P05 against current repo state; dispatch executor to re-run `/validate-benchmark`; dispatch overall validator to cross-check every verdict file still cites living evidence paths.
Capture: `evidence/12-regression/{phase-02-regression.md,phase-03-regression.md,phase-05-regression.md,benchmark-before.json,benchmark-after.json,summary.md}`.
Pass criteria: P02 regression PASS (orphan disposition still in effect) | P03 regression PASS (inventory still matches disk) | P05 regression PASS (scoreboard still achievable — re-run subset) | new benchmark grade ≥ A (96/100) written to `.vf/benchmarks/benchmark-260416-campaign.json` | every `validators/P??-verdict.md` file still cites PASS AND every cited evidence path still exists with bytes > 0 | `git status` clean except plan/evidence dirs.
Review: validator opens each regression sub-agent's report, runs the grade computation itself, spot-checks 3 verdict files for evidence link integrity.
Verdict: PASS → advance P13 | FAIL → loop back to failing phase with attempt=1; re-drive through LOOP-CONTROLLER.
Mock guard: regression sub-agents read current repo, not snapshotted evidence; no mocked regression.
</validation_gate>

<task id="14" phase="P13" depends_on="P12">
Campaign closeout: flip status, tag git, write summary, scaffold follow-ups.
Phase file: `phase-13-closeout.md`
Executor: `researcher` | Validator: `code-reviewer`
</task>

<validation_gate id="VG-P13" blocking="true">
Prerequisites: P12 verdict = PASS | every `validators/P??-verdict.md` exists and marks its phase PASS.
Execute: executor synthesises CAMPAIGN-SUMMARY.md, flips plan.md status to `complete`, updates README benchmark link, scaffolds follow-up plan dirs for each BLOCKED_WITH_USER item, commits with conventional message, tags `vf-gap-remediation-260416-complete`.
Capture: `evidence/13-closeout/{CAMPAIGN-SUMMARY.md,plan-status-diff.patch,readme-diff.patch,tag-commit.txt,followup-plans.md}`.
Pass criteria: CAMPAIGN-SUMMARY.md cites duration + gaps-closed count + benchmark before/after + BLOCKED_WITH_USER items (if any) + V1.5 next steps | plan.md frontmatter `status: complete` | GAP-REGISTER.md change log appended | git tag `vf-gap-remediation-260416-complete` exists (`git tag -l | grep vf-gap-remediation-260416-complete`) | README shows current benchmark grade | `logs/state.json current_phase == "DONE"`.
Review: validator runs `git tag -l`, cats CAMPAIGN-SUMMARY.md, checks plan.md frontmatter, reads README diff.
Verdict: PASS → campaign COMPLETE; exit loop | FAIL → escalate (tag conflicts, verdict file missing, etc.).
Mock guard: real git tag and real commit; no simulated closeout.
</validation_gate>

---

<gate_manifest>
Total gates: 14 (VG-P00 → VG-P13)
Sequence: VG-P00 → VG-P01 → VG-P02 → VG-P03 → VG-P04 → VG-P05 → VG-P06 → VG-P07 → VG-P08 → VG-P09 → VG-P10 → VG-P11 → VG-P12 → VG-P13
All gates: BLOCKING (no advancement on FAIL; max 3 attempts per gate before escalation)
Evidence root: plans/260416-1713-gap-remediation-loop/evidence/
Verdict root: plans/260416-1713-gap-remediation-loop/validators/
State file: plans/260416-1713-gap-remediation-loop/logs/state.json
Regression: VG-P12 re-runs VG-P02, VG-P03, VG-P05 — if any regress, loop snaps back to that phase with attempt=1
Escalation: attempt > 3 → write logs/escalation-<PID>.md, halt loop, notify user; user may mark BLOCKED_WITH_USER to continue
Iron Rule: IF the real system doesn't work, FIX THE REAL SYSTEM. No mocks. Ever.
</gate_manifest>

---

## How to feed this to an executor

**Option A (main orchestrator drives loop):**
1. Read `logs/state.json` (or initialize via VG-P00)
2. For `current_phase` in state: find matching `<task>` + `<validation_gate>` above
3. Dispatch executor sub-agent per `<task>` executor field with the phase file path
4. Wait for executor completion
5. Dispatch validator sub-agent (read-only) with phase file + `<validation_gate>` criteria verbatim
6. On PASS: update state.json, advance `current_phase`
7. On FAIL: increment attempt; if >3, write escalation and halt
8. Repeat until `current_phase == "DONE"`

**Option B (single-shot autonomous drive):**
Feed this entire file as the prompt to a single orchestrator Agent with tools
Glob, Grep, Read, Edit, Write, Bash, Agent, TaskCreate/Update/Get/List, and
SendMessage. It will drive the loop autonomously, stopping only on escalation.

**Option C (per-phase manual):**
Copy one `<task>` + `<validation_gate>` pair into an executor prompt when
driving a single phase interactively. Validator sub-agent must still run
separately with `validators/validator-template.md`.
