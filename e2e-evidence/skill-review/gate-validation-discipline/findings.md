# Deep Review: `gate-validation-discipline` skill

Review date: 2026-04-17
Reviewer: auto-claude coder (phase-1-subtask-2)
Worktree: `.auto-claude/worktrees/tasks/004-skill-deep-review-top-10`

## Summary

| Area | Status |
|---|---|
| YAML frontmatter | OK — `name: gate-validation-discipline`, `description:` block-scalar valid |
| Scope section | OK |
| Verification loop steps | OK — all 5 steps coherent |
| Mandatory checklist (7 items) | OK |
| Rules (7 items) | OK |
| Related Skills (4) | All 4 exist in `./skills/` |
| `references/evidence-standards.md` | Mostly accurate; see Findings |
| `references/gate-integration-examples.md` | Contains stale term `Ultrawork` + inconsistent evidence-path convention |

| Severity | Count |
|---|---|
| CRITICAL (causes false PASS verdict) | 0 |
| HIGH (stale reference / broken instruction) | 1 |
| MEDIUM (contradiction with canonical docs) | 2 |
| LOW (nice-to-have) | 3 |

No CRITICAL defects — no finding in this skill would cause a validator to produce a false PASS verdict. The skill still enforces the right discipline; the issues are stale references and path conventions that contradict canonical ValidationForge docs.

## Scope of review

Files opened and read line-by-line:

1. `./skills/gate-validation-discipline/SKILL.md` (83 lines)
2. `./skills/gate-validation-discipline/references/evidence-standards.md` (76 lines)
3. `./skills/gate-validation-discipline/references/gate-integration-examples.md` (85 lines)

Cross-checks performed:

- `./skills/functional-validation/SKILL.md` — reference path, evidence workflow
- `./skills/no-mocking-validation-gates/SKILL.md` — reciprocal cross-link
- `./skills/verification-before-completion/SKILL.md` — reciprocal cross-link (general form)
- `./skills/e2e-validate/SKILL.md` — reciprocal cross-link (multi-step flows)
- `./skills/create-validation-plan/SKILL.md` — listed by SKILL.md scope as "NOT handled here"
- `./rules/team-validation.md` — canonical Team-mode evidence structure
- `./rules/evidence-management.md` — canonical journey-slug evidence structure
- `./CLAUDE.md` — Team Validation diagram + Evidence rules
- `./hooks/hooks.json`, `./hooks/patterns.js`, `./hooks/evidence-quality-check.js`, `./hooks/completion-claim-validator.js`
- `./commands/validate-team.md` — confirms canonical term is "Team Validation" / "validate team" / "parallel validate"
- `./agents/validation-lead.md`, `./agents/verdict-writer.md` — canonical agent names

Commands executed to verify tooling:

| Command | Output (abbreviated) |
|---|---|
| `curl --version` | `curl 8.7.1 (x86_64-apple-darwin25.0) libcurl/8.7.1 ...` |
| `curl --help all \| grep -E "^ *--retry"` | `--retry`, `--retry-delay`, `--retry-all-errors`, `--retry-connrefused`, `--retry-max-time` all present |
| `jq --version` | `jq-1.8.1` |
| `echo '{"users":[1,2,3]}' \| jq -e '.users \| length > 0'` | `true` — exit 0, filter syntax valid |
| `pnpm --version` | `10.33.0` |
| `node --version` | `v25.9.0` |
| `npx playwright screenshot --help` | Usage `npx playwright screenshot [options] <url> <filename>` — matches example in gate-integration-examples.md line 41 |

## Accuracy Issues

### HIGH — `references/gate-integration-examples.md` lines 3, 5: stale term "Ultrawork"

The reference file leads with:

> ## Integration with Ultrawork/Parallel Execution
>
> When multiple agents work in parallel (Ultrawork, Team mode), gate discipline applies...

`Ultrawork` does not exist anywhere else in the repository. Grep across `./skills/`, `./commands/`, `./rules/`, `./agents/`, `CLAUDE.md` returns matches **only inside this one file**. The canonical ValidationForge terms are:

- Skill: `parallel-validation` (at `./skills/parallel-validation/`)
- Command: `/validate-team` (at `./commands/validate-team.md`, triggers `"validate team"`, `"team validation"`, `"parallel validate"`, `"multi-platform validate"`)
- Rule: `./rules/team-validation.md` (section "Multi-Agent Validation Teams")
- CLAUDE.md §"Team Validation" diagram

Recommendation: replace both occurrences of "Ultrawork" with "Team mode" (or drop the bracketed `Ultrawork` entirely). Replace the header with `## Integration with Team Mode / Parallel Execution`.

### MEDIUM — `references/gate-integration-examples.md` line 12: evidence-path convention contradicts `./rules/team-validation.md`

Line 11–12 claim:

> 3. **Evidence is centralized.** All agents write evidence to `e2e-evidence/` with prefixed
>    filenames: `e2e-evidence/{agent-name}-{criterion}.{ext}`.

But the canonical pattern in `./rules/team-validation.md` §"File Ownership" (lines 18–28) and `./CLAUDE.md` §"Team Validation" (lines 85–95) is **subdirectory-per-validator**:

```
e2e-evidence/
  ios/         ← iOS Validator only
  web/         ← Web Validator only
  api/         ← API Validator only
  design/      ← Design Validator only
  report.md    ← Verdict Writer only
```

And `./rules/evidence-management.md` line 5–12 defines the per-journey pattern:

```
e2e-evidence/
  {journey-slug}/
    step-01-{action}-{result}.png
    ...
```

A validator following `gate-integration-examples.md` would write `e2e-evidence/web-login.png`. A validator following `rules/team-validation.md` would write `e2e-evidence/web/step-01-navigate-to-login.png`. These are different layouts.

Recommendation: replace lines 11–12 with a reference to the canonical structure, e.g.:

> 3. **Evidence is centralized per validator.** Each agent owns a subdirectory under `e2e-evidence/`
>    (see `rules/team-validation.md`). File names follow `step-NN-{action}-{result}.{ext}`
>    (see `rules/evidence-management.md`). Never write outside your assigned subdirectory.

### MEDIUM — `references/gate-integration-examples.md` lines 27–48: CI example uses flat filenames that bypass the canonical journey-slug structure

The CI example writes all evidence flat under `e2e-evidence/`:

- `e2e-evidence/build-output.txt`
- `e2e-evidence/users-response.json`
- `e2e-evidence/health-response.json`
- `e2e-evidence/homepage.png`

None of these use the `{journey-slug}/step-NN-*` pattern from `rules/evidence-management.md`. This is likely intentional (CI pipelines aren't journey-scoped), but the example gives no explanation, and a reader following it will produce evidence that the canonical `rules/evidence-management.md` calls non-compliant.

Recommendation: either (a) rewrite the CI example to use `e2e-evidence/ci/step-NN-*.{ext}` to match the canonical shape, or (b) add a sentence acknowledging CI's flat layout is a documented exception.

## Stale References

### LOW — `references/gate-integration-examples.md` lines 9, 10, 16: term "orchestrator" is informal

The canonical name for the coordinator in Team mode is **Lead** (see `./agents/validation-lead.md`, which itself introduces the agent as "the validation team orchestrator"). Both terms co-exist in the codebase, but the `gate-integration-examples.md` file says "orchestrator" three times without once linking the concept to the actual `validation-lead` agent or the `/validate-team` command.

Recommendation: on first use, write "Lead (the `validation-lead` agent)" and then use "Lead" consistently. This helps a reader discover the actual agent they need to dispatch.

## Missing Content

### LOW — SKILL.md "Related Skills" does not list `parallel-validation`

`SKILL.md` lines 78–83 list 4 related skills: `functional-validation`, `no-mocking-validation-gates`, `verification-before-completion`, `e2e-validate`. But `references/gate-integration-examples.md` spends its entire first section on parallel/team execution, which is the `parallel-validation` skill. The reader is sent to parallel-execution content without a pointer to the actual skill that owns that territory.

Recommendation: add to Related Skills:

```
- `parallel-validation` — Multi-agent parallel validation protocol (see gate-integration-examples.md)
```

### LOW — SKILL.md Verification Checklist overlaps ~70% with `verification-before-completion/SKILL.md`

`gate-validation-discipline/SKILL.md` lines 31–39 and `verification-before-completion/SKILL.md` lines 31–52 cover the same checklist items with slightly different phrasing. Each SKILL.md acknowledges the other at the bottom:

- `gate-validation-discipline` line 81: `verification-before-completion — General completion verification (this skill is gate-specific)`
- `verification-before-completion` line 82: `gate-validation-discipline — Gate-specific verification (this skill is the general form)`

The difference is correctly documented but the skills don't explain how they differ in practice (what counts as "gate" vs. general "completion"?). A reader invoking Claude for "mark task complete" could match either.

Recommendation: in `gate-validation-discipline/SKILL.md` Scope section, add one line clarifying: "Use this skill when closing a `/validate` pipeline phase gate; use `verification-before-completion` for single-task completion claims."

## Broken Cross-Links

None found.

All 4 skills referenced by `gate-validation-discipline/SKILL.md` §"Related Skills" exist:

| Linked skill | Path | Exists? |
|---|---|---|
| `functional-validation` | `./skills/functional-validation/SKILL.md` | YES |
| `no-mocking-validation-gates` | `./skills/no-mocking-validation-gates/SKILL.md` | YES |
| `verification-before-completion` | `./skills/verification-before-completion/SKILL.md` | YES |
| `e2e-validate` | `./skills/e2e-validate/SKILL.md` | YES |

All reciprocal links verified: every target skill's Related Skills section links back to `gate-validation-discipline` (confirmed by `grep -n gate-validation-discipline ./skills/**/SKILL.md`).

Both reference files exist:

| Reference | Path | Exists? |
|---|---|---|
| `references/evidence-standards.md` | `./skills/gate-validation-discipline/references/evidence-standards.md` | YES |
| `references/gate-integration-examples.md` | `./skills/gate-validation-discipline/references/gate-integration-examples.md` | YES |

## Anti-Pattern Table Validation (evidence-standards.md lines 63–77)

I re-read each of the 10 anti-patterns in the table and cross-checked against current ValidationForge practice:

| # | Pattern | Still relevant? | Notes |
|---|---|---|---|
| 1 | Report Trust | YES | Matches CLAUDE.md §"Iron Rules" — "NEVER produce a partial verdict — wait for ALL validators" |
| 2 | Existence Checking | YES | Matches CLAUDE.md §"Evidence Quality Standards" — "Describe what you SEE, not that it exists" |
| 3 | Exit Code Only | YES | Matches CLAUDE.md §"Evidence Quality Standards" — "Quote the actual success/failure line" |
| 4 | Premature Advance | YES | Matches rules/execution-workflow.md 7-phase gating |
| 5 | Screenshot Blindness | YES | Enforced by `./hooks/evidence-quality-check.js` (0-byte rejection) + manual review |
| 6 | Status Code Trust | YES | Matches CLAUDE.md §"Evidence Quality Standards" — "Quote actual body AND headers" |
| 7 | Build = Works | YES | Matches CLAUDE.md Iron Rule #8 — "Compilation success ≠ functional validation" and `./hooks/validation-not-compilation.js` |
| 8 | Log Silence | YES | Matches evidence-standards.md own §"Logs" section |
| 9 | Delegation Handoff | YES | Matches rules/team-validation.md — "The orchestrator verifies agent outputs" |
| 10 | Partial Pass | YES | Matches CLAUDE.md Iron Rule #6 — "NEVER produce a partial verdict" |

All 10 anti-patterns remain relevant.

## Good/Bad Example Validation (evidence-standards.md lines 5–62)

I verified each of the 5 evidence-type sections against current ValidationForge evidence standards:

| Evidence type | Good example accurate? | Bad examples still anti-patterns? |
|---|---|---|
| Screenshots | YES (describes 3 cards, sidebar, avatar initials) | YES |
| API Responses | YES (quotes JSON body + status + content-type + response time) | YES |
| Build Output | YES (quotes final line with errors+warnings+artifact path+size) | YES |
| CLI Output | YES (quotes full stdout with summary line) | YES |
| Logs | YES (quotes specific line with timestamp) | YES |

No updates needed; examples are still canonical.

## Tool-Availability Verification (gate-integration-examples.md CI example)

The CI example at lines 23–48 invokes: `pnpm build`, `pnpm start`, `curl --retry 10 --retry-delay 2`, `curl -s ... | jq .`, `npx playwright screenshot <url> <filename>`, `jq -e '...'`, `test -s`.

Every command syntactically valid per current tooling on this worktree (see §"Commands executed to verify tooling" above). `jq -e` exits non-zero on false/null, so the pipeline correctly fails CI when evidence content doesn't match.

Minor note: the `pnpm start &` on line 29 with no wait before line 32's `curl --retry 10 --retry-delay 2 http://localhost:3000/health` is acceptable because `--retry` handles the race. OK as written.

## Verification-Loop Step Accuracy (SKILL.md lines 45–57)

I traced each of the 5 steps:

1. **IDENTIFY** — "List every PASS criterion" — matches `create-validation-plan` SKILL.md output shape.
2. **LOCATE** — "Find the specific files, outputs, or artifacts" — matches `e2e-evidence/` convention in rules/evidence-management.md.
3. **EXAMINE** — "Open files, read content, view screenshots" — enforced by the `evidence-quality-check` hook (flags 0-byte files).
4. **MATCH** — "For each criterion, cite the specific evidence" — matches verdict-writer agent's citation format.
5. **WRITE the verdict** (PASS / FAIL / PARTIAL) — aligns with functional-validation/SKILL.md §"Verdict Format".

The loop is internally consistent and matches the 7-phase pipeline's phase 5 (VERDICT).

## Hook Cross-Reference Check

`gate-validation-discipline/SKILL.md` does NOT reference any specific hook by name. That's fine — the skill describes human/agent discipline, not hook enforcement. The hook layer (`./hooks/completion-claim-validator.js`, `./hooks/evidence-quality-check.js`) independently enforces a subset of the same rules. No mismatch to report.

If a future revision wants to explicitly link them, the correct pointers are:

- Existence of evidence directory: enforced by `./hooks/completion-claim-validator.js` (requires `e2e-evidence/` to be non-empty before accepting "done"-ish output, matching `COMPLETION_PATTERNS` in `./hooks/patterns.js`).
- 0-byte evidence: enforced by `./hooks/evidence-quality-check.js`.

## Recommendations

Ranked by severity:

1. **(HIGH)** Replace "Ultrawork" with "Team mode" in `references/gate-integration-examples.md` lines 3, 5. One-word change per occurrence.
2. **(MEDIUM)** Rewrite `references/gate-integration-examples.md` lines 11–12 to match `rules/team-validation.md` subdirectory-per-validator convention, or explicitly note the deviation.
3. **(MEDIUM)** Add an explanation at the top of the CI example in `references/gate-integration-examples.md` clarifying that CI uses a flat layout as a documented exception, OR convert the example to use `e2e-evidence/ci/step-NN-*`.
4. **(LOW)** Add `parallel-validation` to `SKILL.md` §"Related Skills".
5. **(LOW)** On first use of "orchestrator" in `gate-integration-examples.md`, explicitly name the `validation-lead` agent.
6. **(LOW)** In `SKILL.md` §"Scope", add one-line disambiguation from `verification-before-completion`.

## Iron Rule Preservation

During this review I created zero test files, zero mocks, zero stubs. Evidence of this:

- Only edits in this worktree: `findings.md` (this file) inside `e2e-evidence/skill-review/gate-validation-discipline/` — allowlisted by `./hooks/patterns.js` ALLOWLIST `/e2e-evidence/`.
- All reads are `Read` / `Grep` / `Bash` with `ls` / `grep` / `wc` / `--version` flags — no test harnesses invoked.

Iron Rule intact.
