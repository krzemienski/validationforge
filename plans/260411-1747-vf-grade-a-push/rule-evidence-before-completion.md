# Rule: Evidence Before Completion
Source skill: `skills/gate-validation-discipline/SKILL.md`.
Enforcement: soft (TaskUpdate checklist, hook reminder via `hooks/evidence-gate-reminder.js`).

## The Rule
No task is marked complete without **personally examined evidence** proving the exit
criterion was met. Confident prose without an evidence citation is rejected.

## Required per completion claim
1. **File path** of captured evidence (e.g. `e2e-evidence/j5/step-05-post.json`)
2. **Specific citation** — the quoted line, HTTP status, or field value that proves success
3. **Criterion match** — which PASS criterion this evidence satisfies
4. **If no match** — the task is FAIL, not "mostly done" or "should work"

## Prohibited phrasings
- "Build succeeded" (compilation is not validation — see `no-mocks.md`)
- "Tests pass" (test files are blocked; see `no-mocks.md`)
- "Should work" / "looks right" / "I expect it to work"
- "Updated the file" (without running the system that uses it)

## Allowed evidence sources
- `curl -w "%{http_code}" ...` output captured to a file
- Screenshot from simulator / browser
- Exact stdout/stderr from a real binary invocation
- DB query result from a real database

## Why
Confident prose is cheap. Evidence is expensive and load-bearing. The reason this
validator exists is that past agents claimed work was done when it wasn't — and the
claims were plausible enough that reviewers believed them until prod broke.
