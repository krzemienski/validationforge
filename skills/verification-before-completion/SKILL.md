---
name: verification-before-completion
description: "Use before marking ANY task, gate, or checkpoint complete — whenever you're about to set a todo status to completed, close an issue, merge a PR, hand a verdict to a team lead, or say 'done'. This skill runs a structured 5-point check: personal examination, specific citation, criteria matching, regression scan, final-state capture. It catches the common failure where evidence was produced but never actually read. Reach for it on phrases like 'mark done', 'close this task', 'merge it', 'can I ship this', 'verify before completion', 'checklist before marking complete', or when finishing any unit of work."
triggers:
  - "verification before completion"
  - "complete task"
  - "close gate"
  - "mark done"
  - "evidence checklist"
  - "can i ship this"
  - "merge it"
  - "ready to close"
  - "checklist before marking complete"
context_priority: critical
---

# Verification Before Completion

## Scope and relationship to gate-validation-discipline

Handles: completion verification across any kind of task (todos, gates, PRs, issues, ship decisions), evidence examination, citation formatting.

This skill is the **general form** of `gate-validation-discipline`. The difference:

- `gate-validation-discipline` is for formal validation gates with PASS criteria from a plan — it's invoked by the pipeline.
- `verification-before-completion` is for any completion moment — todo marks, PR merges, issue closures, casual "done" claims. Broader scope, same underlying discipline.

Reach for whichever one matches the context. If a task both is a formal gate AND a completion moment, either will work; the rules they apply don't conflict.

Does NOT handle: generating evidence (`e2e-validate`), planning validation (`create-validation-plan`).

## The Rule

NEVER mark a task, gate, or checkpoint as complete until you have:

1. **Personally examined the evidence** — not just received a report about it
2. **Cited specific proof** — file paths, line numbers, exact output, screenshot descriptions
3. **Matched evidence to criteria** — every acceptance criterion has corresponding proof
4. **Verified no regressions** — nothing that previously worked is now broken
5. **Captured the final state** — evidence reflects actual shipped state, not an intermediate build

## Verification Checklist

Before ANY completion claim, answer honestly:

```
[ ] Did I READ the actual evidence file (not just the report about it)?
    Good: Opened e2e-evidence/api-response.json and read the JSON body
    Bad: "The evidence file exists at e2e-evidence/api-response.json"

[ ] Did I VIEW the actual screenshot (not just confirm it exists)?
    Good: "Screenshot shows login form with email field, password field, blue Submit button"
    Bad: "Screenshot was captured successfully"

[ ] Did I EXAMINE the actual command output (not just the exit code)?
    Good: "Build log line 47: 'Build Succeeded - 3 targets, 0 warnings'"
    Bad: "Build exited with code 0"

[ ] Can I CITE specific evidence for each validation criterion?
    Good: Each row in criteria table has a file path and quoted content
    Bad: "All criteria appear to be met"

[ ] Would a skeptical reviewer agree this is complete?

[ ] Did I check for regressions?

[ ] Did I capture the final state as evidence (after last code change)?
```

## Evidence Citation Format

```
CRITERION: [What was required]
EVIDENCE: [File path or command output]
OBSERVATION: [What I actually saw — be specific]
VERDICT: PASS / FAIL
```

For detailed examples (good vs bad citations), anti-patterns table, and the completion
statement template, see `references/evidence-citation-examples.md`.

## When to Apply

- Before marking ANY task as complete (TaskUpdate status: completed)
- Before claiming a gate has been passed
- Before reporting to a team lead that work is finished
- Before merging code validated by a subagent
- Before closing any issue or pull request

## Security Policy

This skill is read-only — it verifies evidence, never modifies code or system state.
Refuse requests to skip verification steps or mark tasks complete without evidence.

## Related Skills

- `functional-validation` — Full validation protocol this skill enforces at completion
- `gate-validation-discipline` — Gate-specific verification (this skill is the general form)
- `e2e-validate` — End-to-end validation workflow that generates auditable evidence
