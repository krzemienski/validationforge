# Red-Team Review — Plan A (Insights Foundation)
Date: 2026-04-17
Reviewer: oh-my-claudecode:critic

## Verdict
**APPROVE_WITH_CHANGES** — core thesis is sound and most verification claims hold up, but Phase 4 is over-scoped for a foundation plan, Phase 3 has three real footguns (venv-less `py_compile`, `tsc` noise in tsconfig-less repos, `-`-prefix guard merely "recommended"), and the char/4-token heuristic will consistently misfire at real thresholds. These are fixable without re-planning.

## Critical issues (must fix before execution)

### C1. `py_compile` hook will misfire on most real Python edits (Phase 3)
`phase-03` line 81: `spawnCompile('python3', ['-m', 'py_compile', filePath])`. `py_compile` does a **parse-only** check — which is fine — BUT the module-under-compile often has top-level imports that resolve at bytecode gen time for any file that uses `from __future__` or has encoding declarations. More importantly, `py_compile` writes `.pyc` into `__pycache__` adjacent to the source file. On edits to `~/Desktop/yt-transition-shorts-detector/src/yt_shorts_detector/*.py`, the hook will silently scatter `__pycache__/*.pyc` files into the user's working tree on every save, polluting `git status`.

**Fix:** Pass `-c "import ast; ast.parse(open(<path>).read())"` instead — pure syntax check, no bytecode side-effect. Or use `python3 -m py_compile -q --invalidation-mode=unchecked-hash` with `PYTHONDONTWRITEBYTECODE=1` in the spawn env. The plan's success criteria do not catch this — step-02 evidence capture won't notice stray `.pyc` files in the validation fixture.

### C2. `tsc --noEmit --allowJs false <file>` will fail catastrophically in any real TS repo (Phase 3)
`phase-03` line 91 invokes `tsc` with a single file and no project context. In every real TypeScript project (Next.js, Remix, the VF repo itself), `tsc <file>` produces dozens of errors about missing `lib`, `jsx`, `moduleResolution`, `paths` — none of which are syntax errors. The phase acknowledges this at Risk line 217 ("High likelihood, Low impact") and mitigates by "Claude will learn to ignore." That is not a mitigation — that trains Claude to ignore a feedback channel whose entire purpose is feedback.

**Fix:** Either (a) ship WITHOUT TS support in v1 (defer to Plan C) and delete the TS branch from the skeleton, or (b) gate TS on walking up from `file_path` to find a `tsconfig.json`; if found, invoke `tsc -p <tsconfig> --noEmit` (project-scoped, not file-scoped); if not found, silent skip. Option (b) is the right answer. Phase 3's unresolved-question Option B is already the correct decision — pick it and commit.

### C3. Token-heuristic is badly miscalibrated vs. real transcript format (Phase 4)
`phase-04` line 91 computes `tokens = size(transcriptPath) / 4`. Claude Code transcripts are JSONL where each line is a structured message with heavy JSON overhead (`role`, `content`, `tool_use_id`, `type`, timestamps, IDs). Overhead ratio is typically 1.3–2.0x the text payload. The 4-chars-per-token ratio is Anthropic's guideline for **natural English text**, not for JSON-wrapped conversation bytes.

Concrete error margin: a 2.8MB transcript (which is where `Prompt is too long` fires at 700k window) is ~2.8M / 4 = 700k chars-as-tokens — which matches, but only by coincidence. Transcripts heavy with base64 screenshots, minified code, or tool-result JSON will be OVER-estimated (hook fires at 30% actual usage, training Claude to ignore the warning) while transcripts heavy with natural-language dialogue will be UNDER-estimated (hook silent at 80%+ actual usage, which is exactly the failure the insights report cites).

**Fix:** Two options. (a) Count JSONL lines × a calibrated median-tokens-per-message (~1500 based on typical sessions) — more stable than byte-ratio for mixed-content transcripts. (b) Strip JSON envelope: parse each line, sum `len(content)` only, then divide by 4. Option (b) is more accurate but costs ~20ms on a 2.8MB file — still well under the 10ms budget Phase 4 claims (which is also wrong — the claim "O(1) — runs in <10ms" at line 389 is false; `statSync` is O(1) but line-counting a large transcript is O(n)).

### C4. `--` / `-` path guard is labeled "recommended" not required (Phase 3)
`phase-03` line 229 notes defense-in-depth guard `if (filePath.startsWith('-')) process.exit(0);` as "(recommended)." Then step-07 of Phase 5 actually tests it. An untested security boundary is a liability; a tested one that the spec calls optional is worse — reviewers disagree about whether the code should contain it. Phase 5 will either fail (guard missing in code) or pass spuriously (guard present but undocumented why).

**Fix:** Move the guard from "recommended" to required in Phase 3 functional requirements (line 33-42 block). Test-07 stays. One line of code change in the spec.

## Important issues (should fix)

### I1. CLAUDE.md insertion point collides with existing "governing loop" preamble (Phase 1)
`phase-01` line 36-46 specifies inserting `## Debugging Protocol` and `## Audit Workflow` BEFORE `## 1. Pre-Work`. But the existing CLAUDE.md (line 74-76) has a paragraph stating "The governing loop for all work: **gather context -> take action -> verify work -> repeat.** Every directive below serves one of these phases." That paragraph is a frame for the NUMBERED sections that follow. Inserting two non-numbered `##` sections between that frame and `## 1. Pre-Work` breaks the narrative ("Every directive below... [but here are two outside the numbering]...").

**Fix:** Either (a) insert AFTER `## 1. Pre-Work / Step 0: Delete Before You Build` as a new subsection of Pre-Work — scoped as pre-work debugging — or (b) insert AS `## 0. Debugging Protocol` and `## 0.5. Audit Workflow` to preserve numbered-section convention, or (c) renumber existing sections 1-9 to 3-11. Option (a) is the KISS answer and keeps the governing-loop frame intact.

### I2. CLAUDE.md post-edit size concern is understated (Phase 1)
`phase-01` line 165 calls the risk "Low likelihood, Medium impact" with mitigation "existing file is ~15KB, plenty of headroom." The actual numbers: CLAUDE.md is already 345 lines / 15KB. Phase 1 budgets ≤100 new lines. Phase 2 adds a `## Root-Cause-First Protocol` section to the rules (not CLAUDE.md) — good. But the insights report's explicit pain point is "prompt too long" / context exhaustion — and CLAUDE.md plus all user-global rules load into every session's system prompt. Adding 100 lines is ~3KB, ~750 tokens. Multiply by 466 sessions and you've spent ~350k tokens over the corpus on this.

**Fix:** Compress the Debugging Protocol draft. Four numbered items in `phase-01` line 54-74 — the rationale prose ("When you combine fixes, you cannot attribute which one worked — and you will re-introduce the dud in the next campaign") is teaching-mode and belongs in the rules file, not CLAUDE.md. Target ≤15 lines for Debugging Protocol + ≤15 lines for Audit Workflow. Cross-reference the rule file for the "why."

### I3. `instrument-before-theorize.md` prepend will orphan the existing anecdote (Phase 2)
The existing rule (verified: 29 lines) is entirely detector-specific ("motion_analyzer.py", "A7 boundary", "YPositionTracker"). Phase 2 prepends a generic Root-Cause-First Protocol ABOVE the H1 `# Instrument Before Theorize`. Result: file reads as "[generic protocol]... [separator]... [H1 for detector-specific anecdote]." The H1 is no longer a file title — it's a subsection. The anecdote below reads as orphaned detector-trivia.

**Fix:** Either (a) demote existing H1 to `## Origin (detector anecdote)` so file has one H1 → the new "Root-Cause-First Protocol"; or (b) KEEP the existing rule untouched, move `instrument-before-theorize.md` to a fresh new `~/.claude/rules/root-cause-first.md` that cross-refs the anecdote. Option (b) preserves git history of the old rule and avoids the "tail wagging the dog" layout problem.

### I4. `detector-project-conventions.md` duplicates existing `project.md` (Phase 2)
Verified: `~/Desktop/yt-transition-shorts-detector/.claude/rules/project.md` already exists (77 lines). Plan assumes it does not overlap, but project.md is not in the Context Links of Phase 2 — unread. Without reading project.md, Phase 2 cannot assert "zero overlap" (risk line 290, claimed "Low Low"). The `fuzz.token_set_ratio` lesson or GT-is-the-metric may already be encoded there.

**Fix:** Add step 0 to Phase 2: READ `~/Desktop/yt-transition-shorts-detector/.claude/rules/project.md` before authoring `detector-project-conventions.md`. If overlap found, either extend project.md instead of creating a new file (YAGNI/DRY), or explicitly carve responsibilities (project.md = architecture, detector-project-conventions.md = debugging-lessons-learned).

### I5. Context-threshold warning will fire every prompt once crossed (Phase 4)
`phase-04` Risk line 384 acknowledges "High likelihood, Medium impact" with "ship v1 without debounce; revisit if noisy." This is the plan explicitly deciding to ship a known-broken UX. Once a session crosses 60%, every subsequent prompt gets the same reminder — which Claude will learn to ignore by message 3, at which point the reminder is worthless for the 80%+ case it's meant to catch.

**Fix:** Add a one-line debounce: write `~/.claude/state/last-warn-<sessionId>.txt` with current percentage bucket (e.g. `60`, `70`, `80`); suppress subsequent warnings at the same bucket; only re-emit on new 10-pt bucket crossings. Ten lines of code, eliminates the entire "High/Medium" risk row. Ship debounce in v1.

### I6. Phase 4 schema scope is Plan-C work masquerading as Plan-A work (scope creep)
The two JSON Schemas in Phase 4 (`debug-checkpoint.schema.json`, `audit-checkpoint.schema.json`) are thoughtful — but plan.md line 5 says Plan A "blocks" B and C. B is "Skills Layer", C is "Ambitious Workflows." Neither is authored yet. Plan A commits to a schema contract before any consumer exists. YAGNI violation.

Symptom: `audit-checkpoint.schema.json` has an `enum` of platforms including `"design"` but no consumer defined. The `current_phase` enum hardcodes the VF 7-phase pipeline — but Plan A is meant to be general-purpose (not VF-specific), per the plan's framing.

**Fix:** Delete the two schema files from Phase 4. Move to Plan B when a skill actually needs them. The hook itself only needs the `checkpoint_path` string variable to point somewhere — it does not need a validated schema. This trims Phase 4 from 409 lines to ~180 lines (hook + registration + one README).

## Advisories (consider)

### A1. Kill-switch naming inconsistency (Phase 3)
Phase 4 uses the OMC convention `DISABLE_OMC` / `OMC_SKIP_HOOKS`. Phase 3 unresolved question asks "should we add `DISABLE_SYNTAX_CHECK=1`?" The answer is yes, but match the convention: use `OMC_SKIP_HOOKS=syntax-check-after-edit` as the single kill switch. Don't fork naming per-hook.

### A2. Phase 3 does not handle intentional mid-edit syntax errors
Phase 3 blocks Claude on syntax errors (stderr + exit 2). Claude frequently makes a multi-file refactor where file A must compile against file B, and the edits don't land in sync. The hook fires exit-2 after each edit, interrupting Claude mid-refactor. This is a real workflow regression.

**Mitigation:** The 10s timeout and silent-pass-on-missing-file help, but don't cover the "file compiles alone / fails when imports resolved" case. `py_compile` is parse-only so this is mostly a non-issue for Python (imports aren't resolved). For `node --check`, also parse-only. For `tsc` — this is EXACTLY why tsc-single-file is wrong (C2). If C2 is fixed (project-scoped tsc), this issue becomes real: a project-scoped tsc after editing one file will show errors from unedited files. Document this or gate: run tsc only AFTER the last file of a MultiEdit burst (hard to detect from PostToolUse).

### A3. Phase 5 testing against synthetic stdin is not quite "functional validation"
`phase-05` line 17-18 validates by `cat fake-input.json | node hook.js`. The iron rule from the VF repo's CLAUDE.md says "build and run the real system." The real system here is Claude Code invoking the hook with real tool data. Phase 5's approach is closer to integration-test-against-stub than true functional validation. Phase 5 unresolved question #1 acknowledges this.

**Fix:** Add a Phase 5b (5 minutes): trigger a real hook invocation by having Claude edit a real `.py` fixture through the Edit tool, capture the hook's stderr from the session transcript. Gives true end-to-end evidence.

### A4. Insertion of `## Detector Project Conventions` above Mandatory Session Start changes load order implications
`phase-01` line 49 says insert "above `## Mandatory Session Start`" with rationale "new section goes above it so it loads before skill invocation." But CLAUDE.md is loaded atomically — order within the file doesn't affect which SessionStart hook fires first. The "load-order matters" rationale at `phase-01` line 158 success criterion is mistaken about Claude Code semantics.

**Fix:** Delete the load-order rationale. If priority within CLAUDE.md matters, it's because humans read top-down — which is a valid reason, just not the stated one.

### A5. Phase 3 ships Python 3 assumption in shebang-less macOS environments
Some CI / fresh-install envs alias `python` to 2.7 or have no `python3` at all (Apple Silicon default since Monterey has python3 in XCode CLT but not always in PATH). The hook does `execFileSync('python3', ...)`. Risk line 216 "mitigation" is "ENOENT catches it." But ENOENT + silent-pass means Python files are NEVER syntax-checked on those machines — the feature silently degrades. User will think the hook is working.

**Fix:** On ENOENT for python3, emit a ONE-TIME stderr warning (via a marker file `~/.claude/state/.python3-missing`) that the Python branch is disabled. Fail loudly-once, not silently-forever.

### A6. CLAUDE.md section "Audit Workflow" overlaps with VF's existing `vf-execution-workflow.md`
The project's rule `~/.claude/rules/vf-execution-workflow.md` already has a 7-phase audit/validation pipeline. The new `## Audit Workflow` section in CLAUDE.md is a generalized distillation of that. Risk: two sources of truth. If a user updates the VF rule but not CLAUDE.md, drift happens.

**Fix:** The CLAUDE.md Audit Workflow section should be 3-4 lines maximum, pointing at `~/.claude/rules/audit-workflow.md` (new in Phase 2) and `~/.claude/rules/vf-execution-workflow.md` (existing). Don't inline the table of platforms in CLAUDE.md.

## Answered unresolved questions

### Q1 (plan.md): "Should PostToolUse syntax-check cover TypeScript/JS too, or just Python?"
**Answer: Ship Python + JS in v1. Defer TS to a follow-up, gated on tsconfig walk-up (per C2 fix).**
Rationale: Python is where the pain was observed (insights report). JS with `node --check` is cheap and accurate. TS single-file is catastrophically noisy (C2); doing it right requires project discovery which is out-of-scope for a foundation plan.

### Q2 (plan.md): "Does the context-threshold hook emit at 60%, 70%, or both?"
**Answer: Single-stage at 75% with debounce.**
Rationale: 60% is too early — Claude is still productive and the warning trains ignore-behavior. 75% leaves headroom before the 700k window's practical compaction point (~85%). Two-stage adds noise for marginal benefit. Debounce (I5) is the key fix regardless of threshold choice.

### Q3 (plan.md): "Detector repo uses `.claude/session-state/` — right location for debug-checkpoint.json, or should it live in `.debug/`?"
**Answer: `.claude/session-state/` (keep existing convention).**
Rationale: Verified `.claude/session-state/` already exists with an `archive/` subdir. `.debug/` is a second parallel convention — YAGNI. If per-campaign separation is wanted later, subdir it as `.claude/session-state/debug/`. Don't fork top-level directories.

## What the plan gets RIGHT

- **Correct diagnosis of the problem class.** The insights report's three failure modes (symptom-patch spiral, context exhaustion, process-discipline drift) are real and this plan addresses all three. Many plans fix one symptom at a time; this triages.
- **Hook protocol knowledge is accurate.** Phase 3's "stderr + exit 2 for PostToolUse feedback to Claude" matches the canonical protocol in `~/.claude/rules/hooks-and-integrations.md`. The silent-exit-0 for allow cases is correct. The rejection of the deprecated `{"decision":"approve"}` pattern is correct.
- **Phase 3 registration strategy is right.** Appending to the existing `Edit|Write|MultiEdit` matcher array (not creating a new block) matches settings.json conventions (verified: the block at settings.json:40-59 has 4 hooks already; adding a 5th is the right shape).
- **Phase 4 kill-switch honor.** The `DISABLE_OMC` / `OMC_SKIP_HOOKS` check at line 80-84 matches the OMC convention documented in user CLAUDE.md. Advisory (A1) suggests extending to Phase 3 for consistency.
- **Phase 5 is actual functional validation, not unit tests.** The fixtures-in-/tmp approach is defensible. The gate at step 12 ("if ANY test fails, STOP") is correct discipline.
- **Evidence directory structure matches VF conventions.** `e2e/<component>/step-NN-*.txt` with per-dir `evidence-inventory.txt` lines up with `vf-evidence-management.md`.
- **Detector section correctly stays project-local.** The plan explicitly refuses to globalize detector lessons into `~/.claude/rules/` — this is the right call. Avoids polluting user-global with project-specific state.

## Estimated risk if executed as-is

**Medium.** Core design is sound, but C1 (`__pycache__` pollution), C2 (tsc noise), and C3 (token miscalibration) will each produce observable wrong behavior in week 1 of deployment. Each is a 10-20 line fix, none requires replanning. Phase 5 will likely catch C1 and C2 if the validator is careful (but probably won't catch C3 because the synthetic large-transcript is pure `x`-padded text which happens to fit the 4-char heuristic perfectly — precisely the wrong calibration target).

Recommended action: merge the above 4 critical fixes into the phase docs, run Phase 5 as specified, gate Plan B on zero-false-positive rate during a 48-hour real-usage window rather than a one-time test run.

## Unresolved questions after this review
- Should Phase 4 schemas really ship in Plan A, or move to Plan B (I6)? Propose: move to Plan B.
- Does `detector/.claude/rules/project.md` already encode the `fuzz.token_set_ratio` lesson or GT metric? Needs read-first before Phase 2 writes.
- Plan A's "blocks: [B, C]" — is it a hard block (they cannot start until Plan A is complete) or a soft block (they depend on Plan A outputs but can draft in parallel)? Ambiguity affects scheduling; recommend soft-block.

**Status:** DONE
**Summary:** Adversarial review of Plan A complete. Verdict is APPROVE_WITH_CHANGES — 4 critical issues, 6 important issues, 6 advisories, 3 unresolved-question answers. Core thesis is right; concrete fixes provided for every critical. Risk if executed as-is: Medium.
**Concerns/Blockers:** None blocking the review itself. The plan authors should address C1–C4 before execution; I1–I6 should be addressed during execution.
