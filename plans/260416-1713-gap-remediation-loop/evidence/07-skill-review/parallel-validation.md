---
skill: parallel-validation
reviewer: R3
date: 2026-04-16
verdict: PASS
---

# parallel-validation review

## Frontmatter check
- name: `parallel-validation`
- description: `Multi-agent parallel validation: iOS+Web+API simultaneously on independent journeys. Strict file ownership prevents conflicts. Verdict aggregation: any FAIL=FAIL. For large apps, multi-platform.`
- description_chars: 160
- yaml_parses: yes

## Trigger realism
- Trigger phrases: `parallel validation`, `validate in parallel`, `concurrent validation`, `multi-platform validation`, `fan out validation`
- Realism score (5/5): Triggers match real multi-platform validation orchestration

## Body-description alignment
- Verdict: PASS
- Evidence: Description matches body exactly. Parallelization Rules distinguish safe (different pages, platforms, viewports) from sequential (auth flow, CRUD, data dependencies). Orchestration Protocol has 5 phases (Journey Analysis, Agent Assignment, Parallel Execution, Evidence Collection, Unified Verdict). File Ownership Rules CRITICAL section enforces strict directory separation. Verdict Aggregation table shows Any FAIL = FAIL.

## MCP tool existence
- Tools referenced: Task tool (for spawning agents), run_in_background
- Confirmed: yes (standard Claude Code orchestration)

## Example invocation
"Validate the iOS, Web, and API platforms in parallel"

## Verdict
PASS
- Safe vs Sequential table is pragmatic and guides correct parallelization strategy
- File Ownership Rules are CRITICAL and prevent evidence corruption
- Agent Prompt Template is ready-to-use with clear rules
- Verdict Aggregation rules are explicit: Any FAIL=FAIL (fail-fast)
- Performance Guidelines show speedup expectations by app size
- Evidence Structure and Report Template are complete
- Integration section clearly states coordination with preflight, create-validation-plan, and other skills
