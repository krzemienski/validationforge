# Phase 4 — Live Session Limits

This document records what Phase 4 of the plugin-live-load-verification spec
asks for that **cannot** be satisfied from inside the current subagent, and
what the static/proxy substitutes prove instead.

## Execution context at time of writing

The work for this phase was performed by a **subagent of a live Claude Code
session** (not the outer interactive session). Subagents run inside a
constrained sandbox that permits shell commands and file I/O but:

- cannot spawn a second interactive `claude` CLI process
- cannot observe the outer session's hook-invocation telemetry
- cannot enumerate the live slash-command palette as a user would see it
- cannot literally type `/validate` or `/help` at a prompt

Everything in this phase that requires those capabilities is therefore deferred
to the outer session. The rest has been proved via reproducible offline
substitutes.

## Per-subtask coverage

### subtask-4-1 — "All 15 slash commands appear in the command palette"

**Spec asks:** Launch `claude`, run `/help` (or an equivalent listing prompt),
grep the transcript for each of 15 VF command names.

**What cannot be done from a subagent:** Launching a second `claude` process
and capturing its rendered command palette.

**What we proved instead (step-17-command-references.txt):**
- All 15 command markdown files exist under `commands/` (validate,
  validate-plan, validate-audit, validate-fix, validate-ci, validate-team,
  validate-sweep, validate-benchmark, vf-setup, forge-setup, forge-plan,
  forge-execute, forge-team, forge-benchmark, forge-install-rules).
- Each command .md file has non-zero size.
- Every primitive reference (skills/, agents/, hooks/\*.js, scripts/) inside
  each command resolves on disk.
- Total: **15 PASS / 0 FAIL**.

**Still needed from outer session:** Visual confirmation that the 15 commands
appear in the live slash-command palette and are dispatchable by the user.

### subtask-4-2 — "≥ 3 skills are discoverable and invocable"

**Spec asks:** Prompt Claude with trigger phrases for web-validation,
api-validation, preflight; confirm Claude references each skill's content.

**What cannot be done from a subagent:** Driving a live Claude model with
trigger prompts and inspecting the response for skill references.

**What we proved instead (step-18-skill-frontmatter.txt):**
- 41 of 41 skills under `skills/` have a valid `SKILL.md` with YAML
  frontmatter containing both `name` and `description`.
- All 3 spec-required skills are present: `web-validation/SKILL.md`,
  `api-validation/SKILL.md`, `preflight/SKILL.md`.
- Helper-file references inside each SKILL.md body (relative
  `scripts/`, `templates/`, `config/`, `lib/`, `helpers/`, `references/`)
  resolve on disk where present.

**Still needed from outer session:** Confirm that Claude actually activates at
least one of these skills when given the trigger phrase in the live session
(the skills are *discoverable* on disk; *invocation* requires the runtime).

### subtask-4-3 — "block-test-files hook fires in a live Write call"

**Spec asks:** In a live session, issue a Write to `scratch/foo.test.ts`;
confirm Claude Code's PreToolUse dispatcher invokes block-test-files.js,
receives `permissionDecision=deny`, and surfaces the Iron Rule message.

**What cannot be done from a subagent:** Watching the live PreToolUse
dispatcher fire. (Attempting to Write a .test.ts file from this subagent
would itself be blocked by the OUTER session's hooks, but that blocks does
not prove the INSTALLED plugin's hook fired — it might be a different hook
instance.)

**What we proved instead (step-19-realistic-hook-invocations.txt):**
- Piped a Claude-Code-shaped PreToolUse payload
  `{"tool_name":"Write","tool_input":{"file_path":"scratch/foo.test.ts","content":"..."}}`
  to `$INSTALLED_PLUGIN_ROOT/hooks/block-test-files.js`.
- Hook emitted exactly the protocol-conformant
  `hookSpecificOutput.permissionDecision = "deny"` with `hookEventName =
  "PreToolUse"` and a reason quoting the file path and the Iron Rule.
- All 4 assertion conditions PASS (hookEventName, permissionDecision,
  reason mentions Iron Rule, reason quotes path).

**Still needed from outer session:** Observe that the live dispatcher actually
invokes this hook binary on a real Write call and honors the deny. The
payload-response contract is fully proved; the dispatcher-to-hook plumbing
is assumed correct because Claude Code's PreToolUse protocol is documented.

### subtask-4-4 — "evidence-gate-reminder fires on TaskUpdate completed"

**Spec asks:** In a live session, update a todo to status=completed; confirm
the evidence checklist is injected as `additionalContext`.

**What cannot be done from a subagent:** Writing through the outer session's
TaskUpdate tool and inspecting the downstream context injection.

**What we proved instead (step-19-realistic-hook-invocations.txt):**
- Piped a TaskUpdate payload with `status="completed"` to the installed
  evidence-gate-reminder.js.
- Hook emitted `hookSpecificOutput.additionalContext` containing all 5
  "[ ]"-prefixed checklist items, including the distinctive
  "Did you PERSONALLY examine the evidence" phrase from the source.
- All 4 assertion conditions PASS.

**Still needed from outer session:** Observe the live TaskUpdate dispatcher
invoking the hook and injecting its additionalContext into the next turn.

### subtask-4-5 — "Zero [ValidationForge] error lines in live-session logs"

**Spec asks:** Export full session stderr, grep for error signatures.

**What cannot be done from a subagent:** Exporting the outer session's full
debug log.

**What we proved instead (step-20-hook-log-audit.txt):**
- Invoked all 7 installed hooks with benign payloads. Aggregate stderr is
  **empty** across all 7.
- Grepped stderr for 8 error signatures (`[ValidationForge].*error`,
  `ENOENT`, `Cannot find`, `Error:`, `TypeError`, `SyntaxError`,
  `ReferenceError`, `Using inline fallback`). **0 matches.**
- Scanned Phase 2 and Phase 3 captured stderr blocks with the same
  patterns. **0 matches across 6 evidence files.**

**Still needed from outer session:** Confirm no [ValidationForge] error
lines appear in the live session's debug transcript during normal use. The
installed hook binaries themselves are proved error-clean on all their
documented tool-event shapes.

## Summary

| Subtask | Static/offline substitute verdict | Outer-session requirement |
|---------|-----------------------------------|---------------------------|
| 4-1 (15 commands discoverable) | PASS — 15/15 command .md files present with resolving refs | Confirm palette listing |
| 4-2 (≥ 3 skills invocable) | PASS — 41/41 skills parse, 3 spec-required present | Confirm skill activation on trigger |
| 4-3 (block-test-files DENIES) | PASS — installed hook emits correct deny payload | Confirm dispatcher wires deny to live Write call |
| 4-4 (evidence-gate-reminder injects) | PASS — installed hook emits correct additionalContext | Confirm dispatcher surfaces it to Claude's next turn |
| 4-5 (no hook-script errors) | PASS — zero error signatures across all 7 hooks + 6 prior evidence files | Confirm same for live session debug log |

Everything a subagent *can* prove has been proved. The outer session is the
sole authority on dispatcher behaviour and live palette/skill activation.
