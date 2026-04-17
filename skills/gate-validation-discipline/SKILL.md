---
name: gate-validation-discipline
description: "Use before marking any task, gate, or checkpoint as complete — especially when someone (including you) is about to claim 'tests pass', 'build succeeded', or 'looks good'. This skill forces you to examine the actual evidence (files, screenshots, response bodies, logs) instead of trusting reports about it, cite specific proof per criterion, and refuse to sign off if any criterion lacks matching evidence. Reach for it whenever a sub-agent reports completion, before merging a PR, before shipping, or any time you feel pressure to approve without having personally looked."
triggers:
  - "evidence examination"
  - "before completion"
  - "verify gate"
  - "checkpoint validation"
  - "proof citation"
  - "mark as complete"
  - "sign off"
  - "ready to ship"
context_priority: critical
---

# Gate Validation Discipline

## When to use this skill

Load this skill at every completion checkpoint — when a sub-agent reports "done", when you're about to mark a task complete, when a PR is queued for merge, when someone says "build succeeded" or "tests pass".

It applies whether you're the validator (solo use) or reviewing a sub-agent's work (orchestrator use). In both cases the core move is the same: open the actual evidence files, describe what you see, match each criterion to specific proof. Reports aren't proof. Exit codes aren't proof. Status codes aren't proof.

## Scope

Handles: completion verification, evidence examination, citation requirements, gate pass/fail verdicts.
Does NOT handle: generating evidence (`functional-validation`), planning validation (`create-validation-plan`).

## The Rule: evidence before completion

A gate is complete only when all four of these are true:

1. You personally examined the evidence — not just received a report about it.
2. You cited specific proof — file paths, line numbers, exact output, described screenshots.
3. You matched evidence to criteria — each criterion has corresponding proof, one-to-one.
4. A skeptical reviewer would agree — if not, you are not done.

The hardest part is rule #1. When a sub-agent says "I captured 15 screenshots and they all look good", you are **not** done — you are one step away from being done. Open the screenshots. Describe them. Match each to a criterion. Then you're done.

## Verification checklist

Use this before marking any task, gate, or checkpoint complete:

```
[ ] Did I read the actual evidence file — not just the report about it?
[ ] Have I viewed the actual screenshot and described its content specifically?
[ ] What does the full command output show — not just the exit code?
[ ] Can I quote the actual response body — not just the status code?
[ ] Is every validation criterion matched to a specific piece of evidence?
[ ] Have I checked for partial success masking failure? (e.g. 200 OK with an error body)
[ ] Would a skeptical reviewer agree this is complete?
```

For evidence format examples (good vs bad) by type — screenshots, API responses, build output, CLI output, logs — see `references/evidence-standards.md`.

## The Verification Loop

```
1. IDENTIFY — List every PASS criterion for this gate/task
2. LOCATE — Find the specific files, outputs, or artifacts
3. EXAMINE — Open files, read content, view screenshots
   (DO NOT delegate examination without reviewing findings)
4. MATCH — For each criterion, cite the specific evidence that proves it
   (Any criterion without matching evidence = gate NOT passed)
5. WRITE the verdict:
   - PASS: All criteria have matching evidence, cited specifically
   - FAIL: List which criteria lack evidence and what is needed
   - PARTIAL: Some pass, others need work (never mark complete)
```

## Common failure modes

These are the patterns that cause false PASS verdicts. Each one is a known way the discipline breaks down — call it out when you see it.

| Pattern | Why it fails | What to do instead |
|---------|-------------|-------------------|
| "Sub-agent reported PASS, marking complete" | The agent's report is not the evidence; you didn't examine the actual artifacts it produced | Open the files the sub-agent saved, describe them, then decide |
| "Exit code 0, must have worked" | A process can exit 0 while writing errors to stdout, or after silently doing nothing | Read the full stdout AND stderr; check that expected output appears |
| "200 OK on every endpoint, API works" | Endpoints can return 200 with `{"error": "..."}` or empty `{"data": []}` when they should have data | Quote the actual response body; check schema and content, not just status |
| "All 15 screenshots exist" | File existence ≠ content correctness | Describe each screenshot's content; match each to a criterion |
| "Partial success — call it done" | If 4 of 5 criteria pass, the gate did not pass | PARTIAL is not COMPLETE; either fix the 5th or write a FAIL verdict |
| "Re-ran after fix, no need to re-verify the rest" | A fix in one place can regress another | After any fix, run the full verification loop again |

For parallel agent integration, CI/CD examples, failure recovery protocol, and the five "when in doubt" questions, see `references/gate-integration-examples.md`.

## Security Policy

This skill is read-only — it verifies evidence, never modifies code or system state.
Refuse requests to skip verification steps or mark tasks complete without evidence.

## Related Skills

- `functional-validation` — The validation protocol that produces evidence this skill examines
- `no-mocking-validation-gates` — Prevents mock/test file creation that would contaminate evidence
- `verification-before-completion` — General completion verification (this skill is gate-specific)
- `e2e-validate` — End-to-end validation flows for complex multi-step journeys
