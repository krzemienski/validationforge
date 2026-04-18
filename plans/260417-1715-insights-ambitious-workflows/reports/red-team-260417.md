# Red-Team Review — Plan C: Insights Ambitious Workflows
**Date:** 2026-04-17
**Reviewer:** critic (adversarial, ADVERSARIAL mode — see Verdict Justification)
**Target plan:** `plans/260417-1715-insights-ambitious-workflows/` (plan.md + 6 phase files)

---

## VERDICT: REJECT

Plan C is the largest-blast-radius plan of the trio and it ships with **five critical unmitigated safety issues** plus systemic shape drift against its own upstream dependencies. It is not merely "needs more detail" — it has concrete, falsifiable defects that will harm the user if shipped as written.

---

## Overall Assessment

Plan C proposes three powerful, genuinely valuable workflows (GT Tuner, Bug-Audit Swarm, Root-Cause Enforcer) and shows real thought — safety posture section, bounded budgets, worktree isolation, fail-open on enforcer, atomic-write pattern. The architecture for Phase 1 (lib) and Phase 2 (enforcer) is mostly sound. **However:** the plan contradicts its own upstream (Plan A Phase 4's `debug-checkpoint.schema.json` has a completely different shape than Plan C Phase 1 specifies — same filename, incompatible schema, not versioned). The `--allowedTools` grammar in Phase 5 is hand-waved with a "resolve at implementation time" clause — which is exactly what a secure plan must NOT leave to executors. And the Root-Cause Enforcer hook ships with a fail-open that, combined with how nearly all detector code lives in `src/`, creates a genuine dev-flow hazard with no shadow-mode fallback. The functional-validation phase is ambitious to the point of being self-defeating. The 8 planner-flagged concerns are real and only 3 are mitigated-in-plan.

---

## Pre-commitment Predictions

Before reading in detail, based on the task description I predicted the most likely problem areas:
1. `--allowedTools` argument grammar being wrong or unverified.
2. Environment/credential leakage to subagents.
3. Schema drift between Plan A and Plan C's duplicated `debug-checkpoint.schema.json`.
4. Root-Cause Enforcer friction against legitimate refactors.
5. Worktree disk/collision hazards at scale.

**Actually found:** All 5 confirmed. Additionally surfaced: fail-open philosophy is dangerous given the plan's own statement that the hook is intended as a "gate"; token-budget enforcement is soft (depends on `usage.total_tokens` JSONL fields that the plan itself documents as unreliable); `failed-approaches.md` consumed by coordinator grows unbounded; Phase 6 E2E validation will likely hit the same `Prompt is too long` pathology the insights report flagged, invalidating its own evidence capture.

---

## Critical Findings (blocks execution)

### C1. Schema collision with Plan A — same filename, incompatible shape (drift BEFORE v1 ships)

**Evidence.** Plan A Phase 4 (`phase-04-context-threshold-warn-and-checkpoint-scaffolding.md` lines 175–238) defines `~/.claude/state/schemas/debug-checkpoint.schema.json` with required fields:
```
required: ["campaign_id","target_file","hypotheses","fixes_attempted","current_state","last_updated"]
```
Plan C Phase 1 (`phase-01-shared-state-and-checkpoint-library.md` lines 142–156) defines the **same file path** with required fields:
```
required: ["issue_id","hypothesis","evidence_files","failed_approaches_ref"]
```
No field overlaps (`campaign_id` vs `issue_id`; `hypotheses` array vs singular `hypothesis`; `target_file` absent in C). Phase 1 does not declare schema versioning. Phase 1 does NOT reference Plan A's schema at all — Plan C acts as if it is the first writer of this file.

Confidence: HIGH. Impact: Plan B's `/root-cause-first` skill (which is upstream of Plan C's enforcer) will write checkpoints conforming to one schema; Plan C's enforcer will validate against the other and block every edit. The enforcer's `validateEvidence` will claim `evidence.md` is malformed even when the /root-cause-first skill wrote it correctly.

**Why this matters.** This is a silent, compile-clean contradiction that only fires at runtime when the enforcer blocks real user edits with confusing error messages. Debugging it will consume hours because both files exist, both are valid JSON, and both are "the" `debug-checkpoint.schema.json`.

**Fix.** One of:
- (a) Plan C Phase 1 explicitly declares itself an **extension** of Plan A's schema — renaming its own to `debug-checkpoint-v2.schema.json` with migration notes, OR
- (b) Plan A and Plan C schemas are reconciled pre-commit — agree on a single shape that serves both use cases, add a `$version` field, and gate Plan C Phase 1 step 1 on "Plan A + reconciled schema present".

Current Phase 1 step 1 says "Verify Plan A completed — if not, BLOCK" but does not verify schema compatibility. That verification must be added.

---

### C2. `--allowedTools` grammar is unverified and Phase 5 admits it

**Evidence.** Phase 5 line 60:
> "Per `headless.md`, tool argument patterns supported by `--allowedTools` vary; authors MUST re-verify the exact syntax (e.g. `Bash(git *)` vs `Bash:git`) at implementation time. **Placeholder syntax above is illustrative** — resolve via the reference before shipping."

I verified against `headless.md` (the authority this plan cites). The reference shows exactly one pattern: `"Bash(npm install),mcp__filesystem"` — that is, `Bash(<literal command prefix>)`. Wildcards like `Bash(git:*)` and `Bash(git *)` are **not documented** in the reference. Yet Phase 5's whitelists (lines 50–58) specify:
```
Bash(git:*), Bash(node:*), Bash(python3:*), Edit(scripts/gt-tuner/*)
```
None of these are documented grammar. `Edit(scripts/...)` is particularly suspect — the reference shows tool-arg matching only for `Bash`. Phase 5 explicitly shrugs this off rather than resolving it.

Confidence: HIGH. Impact: If the grammar silently parses as a no-match (i.e., the permission system treats `Bash(git:*)` as a literal-prefix match that never matches the real command `git status`), THEN ALL git/node/python calls from the coordinator get denied — coordinator can't run. Worse: if an unknown pattern is silently treated as "unscoped Bash allow" (degrade-open) in some CLI versions, the whitelist is broken and arbitrary bash flows through. **Neither failure mode is recoverable by the subagent at runtime.**

**Why this matters.** The ENTIRE safety story of Plan C's headless runners rests on `--allowedTools` being correctly restrictive. A plan that explicitly punts this to the implementer is shipping a gun with "check whether it's loaded" as a runtime responsibility.

**Fix.** Before any implementation: run `claude -p "echo hi" --allowedTools "Bash(git:*)" --verbose` on a probe and capture the actual permission check behavior. Document the ACTUAL grammar with a live example in Phase 5 §5. If the grammar only supports literal prefixes, rewrite whitelists to enumerate every git subcommand needed (`Bash(git status), Bash(git add), Bash(git commit)`, etc.) — tedious but verifiable. `--disallowedTools WebFetch,WebSearch` is subtractive and per `headless.md` weaker than an allowlist (because the allowlist list would need to NOT include those tools to have the same effect); Phase 5 uses BOTH which is belt-and-suspenders, fine.

---

### C3. Subagent credential leakage — zero env scrubbing

**Evidence.** Phase 5 `common.sh` (lines 64–107) inherits the parent shell environment verbatim into every `claude -p` invocation. The parent shell in a typical dev machine has `ANTHROPIC_API_KEY`, `GITHUB_TOKEN`, `OPENAI_API_KEY`, `AWS_*`, etc. Phase 5 §11 "Security Considerations" says only "No secrets in logs — document that users must not paste credentials into prompts." It does NOT mention subagent env scope.

Per headless.md, subagents spawned via `Task` inherit the parent Claude's toolset, and a bash-scoped tool can `echo $ANTHROPIC_API_KEY`. A whitelist `Bash(git:*)` — if it even works — does NOT prevent a whitelisted bash call from exfiltrating env (e.g. `git config --get user.email` is harmless, but `git --exec-path && env` is not; many innocuous-looking git subcommands accept `--exec-path` or env-passthrough flags).

Confidence: HIGH. Impact: A single prompt-injection-style subagent bug in Scout/Fixer/Video-Worker can exfiltrate the user's API keys to any site Claude can reach — and since `WebFetch/WebSearch` are disallowed, the exfil path is via a log entry that Claude writes, which the user later grep's. Still an exposure even if not instantly weaponized.

**Why this matters.** Plans A/B were about guidance and documentation; Plan C is the first plan that spawns headless agents that run bash. Every security-sensitive variable is in scope unless explicitly scrubbed.

**Fix.** `common.sh` must run each `claude -p` with `env -i` plus an explicit allowlist. Minimum to keep workflows functional:
```
env -i \
  PATH="$PATH" HOME="$HOME" PWD="$PWD" USER="$USER" \
  TERM="${TERM:-xterm}" LANG="${LANG:-C.UTF-8}" \
  CLAUDE_CODE_AUTO_COMPACT_WINDOW="${CLAUDE_CODE_AUTO_COMPACT_WINDOW}" \
  CLAUDE_RUN_TOKEN_CAP="${CLAUDE_RUN_TOKEN_CAP:-}" \
  CLAUDE_ISSUE_ID="${CLAUDE_ISSUE_ID:-}" \
  claude -p ...
```
Explicitly exclude: `*_API_KEY`, `*_TOKEN`, `*_SECRET`, `AWS_*`, `GITHUB_*` (except `GITHUB_ISSUE_ID` if needed). If Anthropic CLI requires `ANTHROPIC_API_KEY` to auth, that's a degenerate case — document it loudly, mitigate with keyring-only auth if available.

---

### C4. Root-Cause Enforcer fires on legitimate refactors — no shadow mode, no granular opt-out

**Evidence.** Phase 2 §5 `diff-shape guard` (lines 58–63):
> "If remaining unique files >3 → block. [...] For each .js/.ts/.py/.go source file in the diff, grep for function/class signatures. If >2 distinct → block."

And from the yt-shorts-detector survey: `src/yt_shorts_detector/` contains virtually all detection engine code. A legitimate rename across 3 files (e.g. `detect_stalls → detect_stall_transitions` — a common refactor) will: (a) touch 3+ files → blocked, (b) change 2+ function signatures → blocked.

The only escape is `CLAUDE_SKIP_ROOT_CAUSE_GATE=1`, which per Phase 2 F6 logs every bypass to `~/.claude/state/bypass.log`. There is NO:
- Shadow mode (log but don't block) for the first N days
- Per-path carve-out (e.g. "allow refactors in `src/yt_shorts_detector/refactor/`")
- Per-branch opt-out (e.g. branches matching `refactor/*` skip the gate)
- Per-commit-message escape (e.g. `[refactor] rename X` message)
- Session-level opt-out flag (only env var)

Worse: Phase 3 explicitly says (§4 NF2): "All subagents inherit `CLAUDE_SKIP_ROOT_CAUSE_GATE=0` (enforcer stays on) — but coordinator pre-writes a stub `evidence.md` skeleton per video and requires subagent to fill it." A pre-written STUB evidence.md that the subagent "fills" is **exactly the checkbox-gaming failure mode** this hook is supposed to prevent. The hook will pass because the file exists and the sections are present — but the content may be hallucinated, and Plan C explicitly designs its own subagents to satisfy the enforcer mechanically rather than meaningfully.

Confidence: HIGH. Impact: User flow-state destroyed on first real refactor; enforcer-is-blocking incidents will drive rapid adoption of the bypass flag, at which point the enforcer is decorative.

**Why this matters.** The planner flagged this as concern #8 ("enforcer fail-open philosophy"). Plan C's mitigation is fail-open-on-error (hook bugs don't block dev) but there's NO soft-mode for `false positives` (hook works correctly but its heuristics are wrong for this repo). A hook that cries wolf 3x per day will be disabled within 48 hours. An enforcer that the plan's own automation systematically gamings cannot possibly enforce anything.

**Fix.** Three stacked changes:
1. Add shadow mode: `CLAUDE_ROOT_CAUSE_MODE=shadow|enforce` with default `shadow` for first 7 days after install. Shadow logs would-block events to `~/.claude/state/shadow.log` without blocking; user reviews log, graduates to `enforce` when signal/noise is acceptable.
2. Add commit-message escape: lines matching `(?i)(refactor|rename|cleanup):` in the staged commit message skip the diff-shape guard (but still require evidence.md for root-cause edits).
3. Delete the Phase 3 "pre-write stub evidence.md" pattern. If subagents can't pass the enforcer honestly, they shouldn't pass it.

---

### C5. Phase 6 functional-validation will self-DoS on context window

**Evidence.** Phase 6 §4 NF3: `CLAUDE_RUN_TOKEN_CAP=500000`, NF4: tuner runs 1 iteration only. Phase 6 runs lib-harness + enforcer 7 scenarios + tuner 1 iteration with 2 subagents + swarm scout→fixer→reviewer + resume test + synthesis reports → all in ONE session.

The insights report (cited by Plan A) documented 16 `Prompt is too long` incidents in long-running sessions. Phase 6 spawns subagents (tuner spawns 2 video-workers, swarm spawns scout+fixer+reviewer), captures full JSONL logs back into the orchestrator, reads them back during synthesis. The evidence files alone (`step-02-one-iter-run.jsonl`, `step-05-fixer-transcript.jsonl`) are themselves large — reading them into context for synthesis will blow the window.

The plan acknowledges this risk at `risks § "Phase exceeds wall-clock budget"` but the mitigation — "Steps are independent; partial completion with explicit per-workflow verdicts is acceptable" — contradicts Phase 6's own §9 success criteria: "All 4 `verdict.md` files exist and each ends with `Final: PASS`. Any FAIL → phase fails."

Confidence: MEDIUM-HIGH (Realist Check: the mitigation exists but contradicts the pass criterion, so in practice the phase WILL partial-fail and the criterion WILL be adjusted post-hoc, which is fine operationally but invalidates the evidence contract).

**Why this matters.** Phase 6 is the only functional validation gate; if it routinely produces partial evidence, the plan's "don't ship without evidence" discipline decays into "ship with whatever evidence survived."

**Fix.** Split Phase 6 into 3 sessions explicitly: Phase 6A (lib + enforcer), Phase 6B (tuner), Phase 6C (swarm). Each session produces its own synthesis report. Merge predicate for the plan's ship-gate: all 3 sessions' verdicts must be PASS. No session-spanning state except the evidence files on disk. This also neatly sidesteps the self-DoS and makes failure semantics crisp: if the tuner demo fails, swarm still runs (the user asked this explicitly; Phase 6 doesn't answer it; the A→B→C split does).

---

## Major Findings (causes significant rework)

### M1. `failed-approaches.md` grows unbounded — coordinator reads degrade silently

**Evidence.** Phase 3 F7 (accept/reject flow): every rejected proposal appends to `.gt-tuner/failed-approaches.md` with root_cause + reason + counterexample. Phase 2 F7: git revert appends. Phase 1 F3: `appendFailedApproach` — no rotation, no truncation, no pagination. Phase 3 §4 NF3 says coordinator "reads failed approaches before proposing" (implicit in architecture; explicit in video-worker prompt's "Known failed approaches" context).

20 iter × 5 failures = 100 entries per campaign. 10 campaigns = 1000. At an estimated ~500 bytes per markdown block (root_cause JSON + reason + counterexample paths + timestamp), that's ~500KB — large enough that reading it into every subagent prompt consumes 100K+ tokens per spawn.

Confidence: HIGH. Impact: After ~10 campaigns, every subagent spawn silently pays a 100K-token tax reading historical failures, AND the LLM's attention on the ACTUAL task degrades. This is the classic "log file becomes infra burden" failure.

**Fix.** Rotation policy: when file exceeds 100KB, roll to `failed-approaches-<iso>.md.gz` and keep only last 30 days of content inline. Coordinator reads only the current (trimmed) file by default; gzipped history available by flag. Also: dedupe — if two proposals have the same `{file, line, reason}` hash, consolidate into one entry with a counter.

---

### M2. Worktree disk consumption — 8 parallel × full repo × no cleanup guarantee

**Evidence.** Phase 3 F9: `max_parallel_subagents=8`. Each subagent runs in its own worktree. yt-shorts-detector is a Python repo with `videos/` containing test clips — `du -sh` indicates the repo is likely several GB with the clips. Each worktree = repo checkout + any per-worktree `.venv`. At 8 parallel × 2-5GB = 16-40GB disk per iteration. 20 iterations without cleanup failure = potentially 320GB+ if cleanup fails silently.

Phase 3 §10 mitigation: "`retain_failed_worktrees=false` default; startup sweep of stale dirs >7 days." But Step 4.4 says cleanup MUST be idempotent — that's a gap. "Idempotent" ≠ "guaranteed-to-run on coordinator crash."

Confidence: HIGH. Impact: On a laptop, a crashed coordinator mid-iteration with `retain_failed_worktrees=true` (user sets for debugging) can fill the disk in a single run. Disk-full on macOS can corrupt the user's filesystem session.

**Fix.**
1. Hard cap on active worktrees regardless of `max_parallel_subagents` (`max_active_worktrees=4` default, user-overridable).
2. Per-worktree disk quota: reject worktree creation if available disk < 2× expected worktree size.
3. On coordinator startup, remove orphan worktrees OLDER than 1h (not 7 days — 7 days is absurd for a system that runs 20 iter/hour).
4. Document: tuner requires ≥50GB free disk; check at preflight.

---

### M3. Concurrent campaigns — 6-hex random collision under tight timing

**Evidence.** Phase 1 §10 risk: "Two workflows write same campaign_id. Mitigation: `campaign_id` includes timestamp + 6-char hex random; collision probability negligible." Phase 3 Step 5.1: `campaign-id = <iso-date>-<6hex>`.

`2^24 = 16M` possibilities. Birthday paradox for 2 concurrent spawns in same second is ~1/16M — negligible for humans. But: if a script loops `/gt-tuner` in a shell `for` loop (the planner flagged this scenario), OR two different operator sessions launch at the same wall-clock second with identical PRNG seeds (possible if `Math.random()` is seeded by time with second-granularity on some platforms), collision risk rises.

More concretely: Phase 5's soft-stop ABORT flow may cause the wrapper to exit and be re-launched by the operator within 1 second on the same ISO timestamp. Second launch collides — second coordinator overwrites first's campaign JSON.

Confidence: MEDIUM. Impact: silent state loss for one campaign. The atomic-write pattern protects against concurrent writes within a campaign but NOT against two campaigns colliding on ID.

**Fix.** Campaign ID = `<iso-timestamp-with-milliseconds>-<pid>-<6hex-from-crypto-random>`. PID + ms + crypto random makes collision essentially impossible. Additionally: Phase 1 `writeCheckpoint` should refuse (with structured error) if the file already exists AND was not written by the current process — detect via a `writer_pid` field, not just path.

---

### M4. Git post-commit hook template has a correctness bug

**Evidence.** Phase 2 §5 git post-commit template:
```bash
issue_id="${CLAUDE_ISSUE_ID:-$(git rev-parse --abbrev-ref HEAD | sed -E 's|.*/([^/]+)$|\1|')}"
```
For a branch `issue-rc-enforcer-test/probe`, this sed extracts `probe` — NOT `rc-enforcer-test`. The hook then calls `append-failed-approach probe ...`. The enforcer hook (Phase 2 F3) resolves issue-id as `issue-rc-enforcer-test` via a different regex: `/(?:^|\/)(issue-[\w-]+|[A-Z]+-\d+)(?:\/|$)/`. **The post-commit hook and the enforcer resolve the same branch to different issue IDs.**

Confidence: HIGH. Impact: A revert auto-logs to `.debug/probe/failed-approaches.md` while the enforcer reads from `.debug/rc-enforcer-test/failed-approaches.md`. Silent split-brain — user reverts, the log is written to a directory no one reads.

**Fix.** Both hooks MUST use the same issue-id resolution function. Move `resolveIssueId` to `checkpoint-lib.js` (single source of truth) and have both the JS hook and the bash hook call it via the CLI wrapper.

---

### M5. Token cap enforcement is soft — `usage.total_tokens` is documented-unreliable

**Evidence.** Phase 5 §5 JSONL shape comment:
> "Wrappers parse via `jq`; do not assume Claude emits exactly this — document that the parser is tolerant of missing `usage` fields."

Phase 5 `watch_budget` (lines 95–106) polls `jq 'map(.usage.total_tokens // 0) | add'`. If `usage` is missing from N% of records, the reported-used count is LOWER than actual, and the cap will never fire. The only safety net is wall-clock timeout (F6: 2 hours default).

Confidence: HIGH. Impact: a runaway agent can burn well beyond the configured token cap. The "token cap" is theater without a robust source.

**Fix.** Use `total_cost_usd` (documented in `headless.md` output schema, line 77) as a secondary bound, OR route all coordinator requests through a proxy that counts tokens authoritatively. Minimum: document the cap as an ADVISORY bound and make wall-clock timeout the primary hard bound (2h is too long for a soft-capped budget — reduce default to 30min for any single `claude -p` invocation; coordinator can re-invoke).

---

### M6. Enforcer breaks during tuner/swarm automation — Phase 3 NF2 admits it

**Evidence.** Phase 3 §4 NF2: "All subagents inherit `CLAUDE_SKIP_ROOT_CAUSE_GATE=0` (enforcer stays on) — but coordinator pre-writes a stub `evidence.md` skeleton per video and requires subagent to fill it."

If the subagent fills the stub and the enforcer passes, the enforcer is providing no actual enforcement — it's checking that a template file exists. If the subagent fails to fill the stub and the enforcer blocks, the tuner iteration stalls. Either way, the enforcer is non-load-bearing in automation — yet the plan claims defense-in-depth by running automation INSIDE the enforcer.

Confidence: HIGH. Impact: false sense of safety. The enforcer looks strict; in automation it is either bypassed-in-effect (stub-filled) or a stall source.

**Fix.** For tuner/swarm subagents, the enforcer should check a *different* artifact — a machine-readable `evidence.json` with a verified hash of the actual regression script output. The coordinator writes evidence.json with `script_stdout_sha256` AFTER running the regression; the enforcer validates the hash against what would be regenerated. This converts "checkbox" enforcement to "receipt" enforcement.

---

## Minor Findings (suboptimal but functional)

- **MN1.** Phase 1 §4 NF1 says "hand-rolled draft-07 subset OR bundled ajv." Schema drift risk is lower if the entire stack uses ajv; hand-rolling is YAGNI violation given that Plan A and Plan B will also validate against the same schemas. Pick one.
- **MN2.** Phase 2 bypass log (`~/.claude/state/bypass.log`) grows unbounded — same M1 issue, lower severity.
- **MN3.** Phase 4 §10 risk: "Skill description too pushy fires on every prompt (Medium)." The mitigation ("validated by trigger-rate test in success criteria") is fine but the test's threshold ("<10%" rate) is generous for a skill that should only fire on explicit invocation.
- **MN4.** Phase 3 `arbiter.js` Step 4.2: `applyDiff(worktreePath, diffText) — git apply --index`. Partial diff failures (some hunks apply, some don't) leave worktrees in a mixed state. Use `git apply --3way` with explicit rollback on partial failure, OR `git am` for a cleaner all-or-nothing semantic.
- **MN5.** Phase 5 uses `stat -f%z || stat -c%s` for BSD/GNU portability, but does not handle the case where `rotate_log` is called on a file that's being written to concurrently. File rotation mid-write corrupts the current record.
- **MN6.** Phase 3 Step 5.3 "per-subagent timeout" is specified but no value given. Unbounded defaults will cause hung subagents to consume full wall-clock budget.
- **MN7.** Phase 4 §5 scout "Failed" state vs "rejected" state distinction isn't carried through to the state machine diagram cleanly; the diagram shows both but the transition rules collapse them.

---

## What's Missing

- **Rollout plan.** When does the enforcer flip from shadow to enforce? Who approves? There's no staged rollout, just a "ship it" semantics. Given the user-facing friction of this hook, absence of staging is a real risk.
- **Rollback plan for enforcer.** If the enforcer is shipped and fires too aggressively, how does the user disable it quickly? Uninstall steps are not documented. `DISABLE_OMC=1` is mentioned in Plan A Phase 4 context but not Plan C Phase 2.
- **Audit tool for tuner campaigns.** Plan C ships SQLite scoreboard + campaign JSON + failed-approaches markdown — three separate data sources. There's no single "show me what the tuner did in campaign X" command. Unattended hours-long runs with no audit UI is a non-trivial observability gap.
- **Concurrent `/gt-tuner` lockout.** Plan acknowledges campaign collision risk but doesn't specify a file lock. Two operators could launch `/gt-tuner` simultaneously and silently corrupt each other's worktree base branches if they happen to choose the same base.
- **Plan B dependency pinning.** Phase 2 says the enforcer invokes `/root-cause-first` skill (Plan B). If Plan B ships a minor version bump that changes the evidence.md template, the enforcer's regex checks break silently. No version pinning mechanism.
- **OOM behavior.** 8 parallel detection runs on 64GB RAM is plausible but tight (user's env per CLAUDE.md: EasyOCR GPU + PyTorch, each run ~2-4GB RAM). OOM kill of a subagent — does the coordinator notice? Plan 3 Step 5.3 says "per-subagent timeout; hung subagents are marked BLOCKED" but OOM isn't a timeout, it's a zero-exit-code process death. Needs explicit `wait` + exit-code check.
- **Phase 3 stub-evidence.md — what happens if the subagent refuses to fill it?** Coordinator waits forever? Marks BLOCKED? Silently advances? Not documented.
- **Schema versioning field on ALL three schemas.** Without `$version`, Plan A vs Plan C drift (C1) repeats every time someone touches the schema.

---

## Ambiguity Risks (plan reviews)

1. `"coordinator spawns subagents via Task tool"` (Phase 3 §5) — Interpretation A: Claude Code Task tool (interactive session). Interpretation B: `claude -p` subprocess spawn (headless). Phase 5 implies B, Phase 3 implies A. If B, subagents don't inherit parent conversation context; if A, they may.
   - **Risk if wrong interpretation chosen:** If coordinator is implemented as A but wrapped by Phase 5's `claude -p`, the "Task dispatch" becomes a nested `claude -p` call — cost blows up, token accounting breaks.

2. `"max_parallel_subagents=8"` (Phase 3 F9) — Interpretation A: 8 concurrent subagents, each running a full regression. Interpretation B: 8 subagents total across the entire campaign, serialized.
   - **Risk if wrong interpretation chosen:** Disk + RAM implications differ by 8×. Plan language implies A; risk assessment implies A. Arbiter design (per-proposal worktree) confirms A. But `config.json` shape (line 118 `max_parallel_subagents`) reads like a pool size, not a per-iter cap — ambiguous whether the pool is drained between iterations.

3. `"zero regressions on previously-matching videos"` (Phase 3 F6) — Interpretation A: exact score equality required. Interpretation B: post-score ≥ pre-score (allows improvements).
   - Phase 3 §5 predicate says `post[v] < pre[v]` → regression. That's B. But F6 English says "zero regressions" which reads as A (strict). Pick one explicitly.

4. `"Scouts' allowedTools whitelist: Bash(rw only within repo)"` (Phase 4 §4 NF2) — What grammar is `Bash(rw only within repo)`? This is not a real `--allowedTools` token. The whitelist is informal text, not an implementable spec.

---

## The 8 Planner-Flagged Concerns — Adjudicated

| # | Concern | Valid? | Worst case | Mitigated in plan? | Fix fits in plan? |
|---|---------|--------|------------|---------------------|--------------------|
| 1 | `--allowedTools` grammar | **YES — CRITICAL (C2)** | Security whitelist is broken; arbitrary bash possible | **NO** — Phase 5 punts to implementation time | Live-verify grammar pre-ship; this is a pre-coding step, fits in plan |
| 2 | Subagent credential leakage | **YES — CRITICAL (C3)** | API keys exfilled via log/Bash | **NO** — Phase 5 silent on env scope | `env -i` + explicit allowlist fits in Phase 5 `common.sh` |
| 3 | Concurrent campaign collisions | **YES — MAJOR (M3)** | Silent state overwrite | PARTIAL — mentioned in risk table, not addressed in code | Add PID + ms + crypto random to campaign ID; trivial |
| 4 | `failed-approaches.md` unbounded | **YES — MAJOR (M1)** | Coordinator spawns degrade to 100K-token context tax | **NO** — risk table says "deferred" | Add rotation to Phase 1 `appendFailedApproach`; fits |
| 5 | `git apply --index` partial failure | **YES — MINOR (MN4)** | Worktree in mixed state; arbiter scores garbage | **NO** — Phase 3 step 4.2 uses plain `git apply` | Switch to `git am` or `--3way`; fits |
| 6 | Resume-after-upgrade schema drift | **YES — CRITICAL (C1)** | Enforcer blocks legitimate edits due to schema mismatch | **NO** — Phase 1 doesn't reconcile with Plan A | Reconcile schemas pre-commit; requires coordination, fits if both plans re-ship together |
| 7 | Subagent output determinism | **YES — MINOR** | Coordinator can't deterministically rank proposals | PARTIAL — Phase 3 §10 says malformed JSON → BLOCKED | Acceptable; the uncertainty is the point |
| 8 | Enforcer fail-open philosophy | **YES — CRITICAL (C4)** | Enforcer either blocks legitimate refactors (fail-closed in practice) or is bypassed (fail-open in effect), no middle ground | **NO** — shadow mode absent | Add shadow mode + commit-message escape; fits in Phase 2 |

**Summary: 5 of 8 concerns are CRITICAL in the current plan and 2 more are MAJOR. Only #7 is reasonably mitigated.**

---

## Multi-Perspective Notes

- **Executor.** "Phase 3 tells me to 'resolve the `--allowedTools` grammar at implementation time' — I don't have authority to make that call. If I guess wrong, I ship either a broken coordinator or a broken safety boundary. Escalate back to planner."
- **Stakeholder.** "Three workflows, each of which can autonomously burn 500K-2M tokens per run, landing behind an enforcer hook that the plan's own tests show will have false-positives on refactors. Net value vs risk — if the tuner saves 2 days of manual GT work per month AND the enforcer doesn't get disabled after the first week, this is a win. If the enforcer gets disabled, the tuner is the only win and it's gated on Phase 2 landing first."
- **Skeptic.** "The insights report flagged 16 `Prompt is too long` incidents. Plan A addresses this with a warn hook. Plan C then introduces three new long-running workflows AND a functional-validation phase that runs all three in one session. The fix is itself a source of the problem. Unless Phase 6 is split, Plan C's own demo will be a case study in the failure mode Plan A is trying to prevent."

---

## Verdict Justification

**REJECT.** Escalated to ADVERSARIAL mode on finding C1 (schema drift) in first pass — that alone is a silent cross-plan contradiction that will fire at runtime. After escalation, C2 (unverified `--allowedTools` grammar admitted in-plan) and C3 (no env scrubbing) compounded the case for rejection. C4 (no shadow mode) and C5 (Phase 6 self-DoS) are structural.

**Realist Check recalibration:**
- C1: Confirmed CRITICAL. Worst case is silent enforcer blocks; detection is slow because the error surface says "evidence.md malformed" not "schemas disagree." No mitigating factors.
- C2: Confirmed CRITICAL. Worst case is security boundary is broken OR coordinator can't run; either fails the entire Plan. Mitigation: grammar verification is a single pre-coding step.
- C3: Initially labeled CRITICAL; Realist Check: no mitigating factor exists (no existing env scrubbing layer in Plan A/B upstream). Confirmed CRITICAL.
- C4: Initially labeled CRITICAL; Realist Check: mitigating factor is that `CLAUDE_SKIP_ROOT_CAUSE_GATE=1` provides instant escape. Worst case is a week of annoyance before users turn it off permanently — that outcome means the plan ships and its main enforcement deliverable dies silently within 7 days. Severity stays CRITICAL because the plan's *stated goal* is enforcement, and shipping an enforcement tool that is predictably disabled within a week is a complete failure of the investment.
- C5: Initially labeled CRITICAL; Realist Check: mitigating factor is that Phase 6 results in partial evidence, not corruption — user can re-run subsets. Downgraded to CRITICAL→"soft CRITICAL" but kept at CRITICAL because the success criterion CONTRADICTS the mitigation (plan says "any FAIL → phase fails" but the realistic mitigation requires accepting partial FAILs). Logically incoherent success criterion stays as CRITICAL.

Mode: ADVERSARIAL (escalated, 5 CRITICAL findings).

**What would change this verdict to REVISE:**
1. Reconcile Plan A + Plan C `debug-checkpoint.schema.json` — one file, one shape, versioning field.
2. Phase 5 rewrites `--allowedTools` whitelist with live-verified grammar, OR downgrades all subagent launches to use `--disallowedTools` with a tight denylist and a non-interactive permission-mode fallback.
3. Phase 5 `common.sh` uses `env -i` with explicit allowlist.
4. Phase 2 adds shadow mode (default for 7 days) + commit-message escape + documented uninstall procedure.
5. Phase 6 splits into 6A/6B/6C, one workflow per session.

**What would change to ACCEPT:** All of the above + M1 (rotation), M3 (collision-proof IDs), M4 (issue-id resolver consolidation), M5 (token cap fallback), M6 (receipt-based enforcement for automation).

---

## Open Questions (unscored — low-confidence or author-refutable)

- Is there a real risk that the enforcer's regex issue-id extractor `/(?:^|\/)(issue-[\w-]+|[A-Z]+-\d+)(?:\/|$)/` misses common branch patterns like `fix/JIRA-123` or `feat-123-description`? The regex accepts `JIRA-123` but not `feat-123`. Author likely has intentional scope; flagged for confirmation.
- Phase 3's SQLite `PRAGMA journal_mode=WAL` — on macOS with FileVault + Time Machine active, WAL file rotation has historically been flaky. Not in-plan, but worth confirming on the user's specific setup.
- Does `claude -p` reliably propagate non-zero exit codes from the `timeout` command on macOS (Phase 5 lines 126, 134–138 assume exit 124 = wall-clock timeout)? macOS `timeout` (from coreutils) returns 124; BSD-equivalent behavior differs. Phase 5 risk table mentions `gtimeout` fallback — worth confirming on first dry-run.
- Is the swarm's "2 consecutive empty scouts = DONE" (Phase 4 F8) tuned for yt-shorts-detector-sized repos? A larger monorepo might have scouts find bugs only every 5th try. Configurable per §10 but no guidance on when to change.
- Phase 2 NF1 says "<300ms for the allow path." `execSync('git rev-parse --show-toplevel')` from a cold cache can be 100ms+ on its own. `git diff --name-only` twice adds 100-200ms. Realistic target might be 500-800ms. Non-critical but the success criterion is probably unrealistic.

---

**Status:** DONE
**Summary:** Red-team review complete. Plan C is REJECTED with 5 CRITICAL findings (schema drift vs Plan A, unverified `--allowedTools` grammar, no env scrubbing, no enforcer shadow mode, Phase 6 self-DoS) and 6 MAJOR findings. 5 of 8 planner-flagged concerns are unmitigated-CRITICAL in the current plan. Specific fixes are listed per finding; Plan C must re-ship jointly with Plan A schema reconciliation.
**Concerns/Blockers:** Plan C depends on Plans A + B per its own frontmatter (`blockedBy:`); the schema drift with Plan A is a pre-existing contradiction that BOTH plans must address. This review recommends a joint A+C revision pass before either ships.
