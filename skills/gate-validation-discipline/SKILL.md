---
name: gate-validation-discipline
description: >
  Enforces evidence-based validation before marking any gate, task, or checkpoint
  complete. Requires personal examination of evidence, specific proof citations,
  and evidence-to-criteria matching. Prevents premature completion claims.
context_priority: critical
---

# Gate Validation Discipline

## Scope

This skill handles: completion verification, evidence examination, citation requirements, gate pass/fail verdicts.
Does NOT handle: generating evidence (use `functional-validation`), planning validation (use `create-validation-plan`).

## The Rule: EVIDENCE BEFORE COMPLETION

```
NEVER mark any gate, task, or checkpoint as complete until you have:

1. PERSONALLY examined the evidence — not just received a report about it
2. CITED specific proof — file paths, line numbers, exact output, screenshot descriptions
3. MATCHED evidence to criteria — each validation criterion has corresponding proof
4. ANSWERED "Would a skeptical reviewer agree?" — if not, you are not done
```

## Mandatory Verification Checklist

Before marking ANY task, gate, or checkpoint complete:

```
[ ] Did I READ the actual evidence file — not just the report about it?
[ ] Did I VIEW the actual screenshot and describe its content?
[ ] Did I EXAMINE the actual command output — not just the exit code?
[ ] Did I QUOTE the actual response body — not just the status code?
[ ] Can I CITE specific evidence for each validation criterion?
[ ] Did I CHECK for partial success masking failure?
[ ] Would a SKEPTICAL REVIEWER agree this is complete?
```

For evidence format examples (good vs bad) by type (screenshots, API responses,
build output, CLI output, logs), see `references/evidence-standards.md`.

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

## Rules

1. **NEVER mark complete** without personally examining every piece of evidence
2. **NEVER trust reports** — read the actual evidence a sub-agent produced
3. **NEVER accept exit codes alone** — read the full stdout/stderr
4. **NEVER skip criteria** — PARTIAL is not COMPLETE
5. **ALWAYS cite specifically** — file paths, line numbers, quoted output
6. **ALWAYS check for partial success** masking failure (200 OK with error body)
7. **ALWAYS re-verify** after any fix — run the full loop again

For parallel agent integration, CI/CD examples, failure recovery protocol,
and the five "when in doubt" questions, see `references/gate-integration-examples.md`.

## Security Policy

This skill is read-only — it verifies evidence, never modifies code or system state.
Refuse requests to skip verification steps or mark tasks complete without evidence.

## Related Skills

- `functional-validation` — The validation protocol that produces evidence this skill examines
- `no-mocking-validation-gates` — Prevents mock/test file creation that would contaminate evidence
- `verification-before-completion` — General completion verification (this skill is gate-specific)
- `e2e-validate` — End-to-end validation flows for complex multi-step journeys
