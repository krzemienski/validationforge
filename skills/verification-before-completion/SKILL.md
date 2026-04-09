---
name: verification-before-completion
description: >
  Prevents premature completion claims by requiring personally examined evidence,
  specific citations, and criteria matching before marking any task complete.
  Use whenever completing tasks, closing gates, reporting to leads, or merging code.
context_priority: critical
---

# Verification Before Completion

## Scope

This skill handles: completion verification, evidence examination, citation formatting.
Does NOT handle: generating evidence (use `e2e-validate`), planning validation (use `create-validation-plan`).

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
