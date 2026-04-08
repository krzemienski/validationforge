# Team Adoption Guide

How to introduce functional validation to a team of agents or developers.

## The Pitch (30 seconds)

"We stop writing test files. Instead, we build the real system, run it, interact
with it as users would, and capture evidence that it works. No mocks, no stubs,
no test frameworks. Real system validation produces trustworthy evidence and
catches bugs that unit tests miss."

## Phase 1: Remove the Safety Net (Day 1)

1. **Delete existing test files.** They create false confidence and maintenance burden.
   ```bash
   find . -name "*.test.*" -o -name "*.spec.*" -o -name "__tests__" | head -20
   # Review what exists. Remove test files. Keep the code they were testing.
   ```

2. **Install the block hook.** Prevent new test file creation at the tooling level.
   The `block-test-files` pre-tool-use hook rejects Write/Edit operations targeting
   test file patterns.

3. **Set up `e2e-evidence/` directory.** All validation evidence goes here.
   ```bash
   mkdir -p e2e-evidence
   echo "e2e-evidence/" >> .gitignore  # Evidence is ephemeral, not committed
   ```

## Phase 2: Teach the Protocol (Week 1)

1. **Share the Quick Reference Card** (`references/quick-reference-card.md`).
   Every team member should have it accessible.

2. **Do one validation together.** Pick a feature, walk through the 4-step protocol
   as a team. Build, exercise, capture, write verdict.

3. **Review evidence quality.** The first few verdicts will say "it works" instead of
   citing specific evidence. Coach toward: "Screenshot shows X, response contains Y."

## Phase 3: Integrate into Workflow (Week 2-3)

1. **Add evidence capture to CI.** Use the CI/CD integration pattern from
   `gate-validation-discipline` to automate evidence capture in pipelines.

2. **Require verdicts before merge.** PRs include a validation verdict section
   with evidence citations. No verdict = no merge.

3. **Track validation debt.** Features without validation evidence are tracked
   the same way you would track tech debt. They get validated in the next sprint.

## Common Objections and Responses

**"Unit tests are faster."**
Total cost: write mock + maintain mock + debug mock drift + manually test anyway.
Functional validation: run real system + capture evidence. One of these is actually faster.

**"We need test coverage metrics."**
Coverage metrics measure lines executed, not features working. 100% coverage with
mocks can still ship broken features. Evidence of real system behavior is the metric.

**"What about regression testing?"**
Capture validation evidence in CI. If the real system breaks, CI catches it.
No mock to drift, no false passes. Real regressions caught by real system validation.

**"Integration tests are slow."**
If your real system is slow, that is a bug. Fix it. Users experience that slowness too.
Mocking the slowness hides a real production problem.

**"Our team is used to TDD."**
TDD's insight is "define expected behavior before implementing." Keep that insight.
Write PASS criteria before implementing. Then validate against the real system
instead of a test harness.

## Success Metrics

After 30 days of functional validation:

- **Zero test files** in the repository
- **Evidence directory** populated for every feature
- **Build + validate** time measured and improving
- **Production bugs** decreasing (mocks were hiding them before)
- **Developer confidence** increasing (evidence is trustworthy)

## Escalation Path

If an agent or team member resists:

1. Ask them to name a bug that only a mock would catch but real validation wouldn't
2. Ask them to show a mock that has never drifted from reality
3. If they have a legitimate case (rare), document it and escalate to the team lead
4. The answer is almost always: fix the real system, don't mock around it
