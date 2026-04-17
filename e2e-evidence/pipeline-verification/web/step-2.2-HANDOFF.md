# Subtask 2.2 Handoff — Run `/validate-ci --platform web` Manually

**Status:** BLOCKED inside auto-claude sandbox. Handoff required to a live
Claude Code session running on the host with full permissions.

**Captured:** 2026-04-17T06:11:00Z by auto-claude coder worker for
phase-2-web-run / subtask 2.2 of the "End-to-End Pipeline Verification" spec.

---

## Why this cannot run inside auto-claude

The auto-claude coder harness registers a PreToolUse callback that rejects any
Bash call containing the `claude` executable. This is independent of
`dangerouslyDisableSandbox` and independent of `~/.claude/settings.json`
permissions. The rejection message was:

> Command 'claude' is not in the allowed commands for this project

This matches `implementation_plan.json` subtask 2.2's
`verification_type: "manual"` and `verification_note`. The plan author
anticipated this limitation; phase 2 was always designed for orchestrator-run
execution.

---

## Prerequisite state at handoff time

1. Web fixture is running — verified immediately before handoff:
   - `curl -sI http://localhost:3847` → `HTTP/1.1 200 OK`
   - Listener: `node *:3847 (LISTEN)` (see `lsof -nP -iTCP:3847 -sTCP:LISTEN`)
   - Evidence file: `./step-2.2-fixture-probe.txt`
2. Worktree location of this handoff:
   `/Users/nick/Desktop/validationforge/.auto-claude/worktrees/tasks/001-end-to-end-pipeline-verification/e2e-evidence/pipeline-verification/web/`
3. Fixture evidence directory (where `/validate-ci` will write before copy):
   `/Users/nick/Desktop/blog-series/site/e2e-evidence/` — already cleaned
   (`rm -rf e2e-evidence/web && mkdir -p e2e-evidence/web`) per Iron Rule
   "never reuse previous-attempt evidence".

> **If the fixture is no longer up when the orchestrator runs this:**
> `cd /Users/nick/Desktop/blog-series/site && npx next start -p 3847 &`
> then wait for `curl -sI http://localhost:3847` to return `HTTP/1.1 200 OK`.

---

## Exact commands to run (copy-paste)

Open a **fresh Claude Code session on the host** (not via auto-claude), then:

```bash
# 1. Re-confirm the fixture is healthy (should print HTTP/1.1 200 OK)
curl -sI http://localhost:3847 | head -3

# 2. Change to the fixture directory
cd /Users/nick/Desktop/blog-series/site

# 3. Run validate-ci for the web platform and capture exit code
claude --print "/validate-ci --platform web"
echo "validate-ci exit code = $?"

# 4. Copy the produced evidence back into the worktree
WORKTREE=/Users/nick/Desktop/validationforge/.auto-claude/worktrees/tasks/001-end-to-end-pipeline-verification
cp -R ./e2e-evidence/* "$WORKTREE/e2e-evidence/pipeline-verification/web/"

# 5. Record the exit code alongside the evidence
echo "validate-ci --platform web exit=$?" > \
  "$WORKTREE/e2e-evidence/pipeline-verification/web/step-2.2-exit-code.txt"
```

Replace the placeholder `$?` in step 5 with the numeric value you saw in step 3
(run them as two separate commands if you prefer not to rely on `$?`
propagation).

---

## Acceptance criteria (from implementation_plan.json)

After the manual run, these must all be true:

- [ ] `claude --print "/validate-ci --platform web"` exited with code **0**
- [ ] `./e2e-evidence/pipeline-verification/web/report.md` exists
- [ ] `report.md` references **≥3 screenshots** (look for `*.png` citations)
- [ ] `report.md` cites specific evidence per journey
- [ ] `report.md` contains a PASS/FAIL column

And, from subtask 2.3 (downstream verification):

- [ ] `find ./e2e-evidence/pipeline-verification/web -type f | wc -l` ≥ 4
- [ ] Zero 0-byte files in that directory
  (`find ./e2e-evidence/pipeline-verification/web -type f -size 0` → empty)

---

## If `/validate-ci` fails or exits nonzero

This is still a valid scientific outcome — the point of phase 2 is to **prove
the pipeline runs**, not to prove the Next.js fixture passes. If the exit code
is 1, capture the output regardless; the plan's fix-loop policy in
`verification_strategy.fix_loop_policy` governs subsequent action:

> 3-strike max per journey (CLAUDE.md Iron Rule 5). If a journey fails 3x,
> halt and escalate to user — do NOT fabricate a PASS.

Do not hand-edit `report.md` to convert a FAIL into a PASS under any
circumstance. Iron Rule 2: no mocks. Iron Rule 7: never reuse previous-attempt
evidence.

---

## Next step after handoff completes

Once `report.md` is present in the worktree's `e2e-evidence/pipeline-verification/web/`
and `step-2.2-exit-code.txt` is written, mark subtask 2.2 `completed` in
`implementation_plan.json`, then proceed to subtask 2.3 (evidence-quality check)
which runs from inside the sandbox.
