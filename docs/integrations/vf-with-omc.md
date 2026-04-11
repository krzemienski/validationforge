# ValidationForge + Oh-My-Claudecode (OMC)

**Positioning**: OMC orchestrates multi-agent workflows and dispatches work across specialized agents. ValidationForge validates the output those agents produce against the running system.

## Why This Combination

OMC excels at decomposing complex requests into coordinated agent workflows — planners, executors, reviewers, debuggers — each with specialized skills. What OMC does not provide is end-to-end functional verification that the code the agents produced actually works against the real system. VF fills that gap.

Without VF, an OMC workflow can pass all its internal reviews (code review agent approves, executor reports success) while the feature is subtly broken when exercised through the real UI, API, or CLI. With VF, OMC's output lands in a validation pipeline that captures evidence from the real running system.

## Workflow Example

User asks Claude Code to "add a password reset flow to the auth API".

1. **OMC's planner agent** decomposes the task:
   - Add `POST /auth/password-reset` endpoint
   - Add token generation and email dispatch
   - Add token verification endpoint
   - Update DB schema
2. **OMC's executor agent** implements each step, writing code to `src/auth/`
3. **OMC's code reviewer agent** reviews the diff against style standards
4. **ValidationForge's block-test-files hook** intercepts any attempt to create `*.test.*` files inside `src/auth/` — the agents are allowed to write implementation code but NOT test files that mock the real system
5. **User runs `/validate`** — VF's pipeline executes:
   - **Preflight**: Confirms API server starts, DB reachable
   - **Execute**: Hits `POST /auth/password-reset` with a real email, captures response; extracts the token from the test email inbox (or DB); hits the verify endpoint
   - **Verdict**: PASS or FAIL with evidence in `e2e-evidence/password-reset/`
6. **If FAIL**, the feedback goes back to OMC's executor to fix, re-validate in a loop

## Configuration Snippet

Enable both plugins in your Claude Code plugin registry (typically `~/.claude/installed_plugins.json`):

```json
{
  "plugins": [
    {
      "name": "oh-my-claudecode",
      "path": "~/.claude/plugins/oh-my-claudecode",
      "enabled": true
    },
    {
      "name": "validationforge",
      "path": "~/.claude/plugins/validationforge",
      "enabled": true
    }
  ]
}
```

Per-project configuration in `.claude/settings.json`:

```json
{
  "plugins": {
    "oh-my-claudecode": {
      "agents": ["planner", "executor", "code-reviewer"]
    },
    "validationforge": {
      "profile": "standard",
      "evidence_dir": "e2e-evidence"
    }
  }
}
```

## Sample Output (Illustrative)

After running the password reset workflow through OMC → VF:

```
[OMC planner] Decomposed into 4 subtasks
[OMC executor] src/auth/password-reset.ts written
[VF hook: block-test-files] BLOCKED attempt to create src/auth/password-reset.test.ts
[OMC executor] Skipped test file, moved to next subtask
[OMC executor] src/auth/token-verify.ts written
[OMC code-reviewer] Approved diff
[User] /validate

[VF phase 2: Preflight]
  - API server: PASS (200 on /health)
  - Database: PASS (SELECT 1 succeeded)
[VF phase 3: Execute]
  - journey-1-password-reset-flow
    step-01-request-reset.json: status=200, token_sent=true
    step-02-verify-token.json: status=200, new_password_set=true
    step-03-login-new-password.json: status=200, session_id=abc123
[VF phase 5: Verdict]
  journey-1-password-reset-flow: PASS
  Evidence: e2e-evidence/password-reset/
```

## Caveats

- **Agent name conflicts**: If OMC and VF both register agents with the same name, the last-loaded plugin wins. Check `~/.claude/plugins/*/agents/` for overlaps before running.
- **Hook ordering is not guaranteed**: When both plugins register hooks for the same event (e.g., `PreToolUse`), the execution order depends on plugin load order. VF's `block-test-files` is idempotent, so re-triggering is safe.
- **Context budget**: Running OMC (many agents) and VF (48 skills) together consumes significant context. Use VF's platform-aware skill loading (see spec 008) to reduce the VF footprint for single-platform projects.
- **OMC planners may request test files**: OMC's executor may attempt to write unit tests as part of its workflow. VF will block these. If you need unit tests as well as VF validation, use a different directory (e.g., keep unit tests under `test/` and let VF scan only `src/`).

## Runtime Verification

This integration has not been verified in a live session combining both plugins. The configuration and workflow above are derived from each plugin's published interface. To verify:

1. Install both plugins
2. Restart Claude Code
3. Run a simple workflow (e.g., "add a GET /users endpoint")
4. Confirm OMC's executor runs and VF's block-test-files hook fires on any test file attempt
5. Run `/validate` and confirm VF's pipeline completes with a verdict

Record findings in `e2e-evidence/vf-with-omc-integration/` and update this document.
