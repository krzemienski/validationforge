---
name: validate-audit-benchmarks
description: "Use for ValidationForge plugin maintainers — scores the plugin's own structural integrity, NOT a user project's validation (that's forge-benchmark). Audits the 7 hooks (60% weight — they're the enforcement layer), 48 skills (20% — check frontmatter + schema), and 17 commands (20% — check YAML + references). Produces an A-F grade with regressions flagged against prior benchmarks. Reach for it on phrases like 'audit the plugin', 'validate the validation primitives', 'are the hooks still working', 'benchmark the plugin', or before any ValidationForge release."
triggers:
  - "audit benchmarks"
  - "run benchmark suite"
  - "score hook correctness"
  - "validate primitives"
  - "quality metrics"
  - "audit the plugin"
  - "benchmark plugin itself"
  - "plugin structural integrity"
context_priority: reference
---

# Validate Audit Benchmarks

Score the structural integrity and functional correctness of ValidationForge primitives.

## When to Use

- After modifying hooks, skills, or commands
- Before releases to verify no regressions
- During audits to establish baseline metrics

## Automated Benchmark Scripts

Run the full suite:

```bash
bash scripts/benchmark/aggregate-results.sh
```

Or run individual validators:

```bash
bash scripts/benchmark/test-hooks.sh       # Hook functional tests (stdin JSON piping)
bash scripts/benchmark/validate-skills.sh   # Skill frontmatter validation
bash scripts/benchmark/validate-cmds.sh     # Command frontmatter validation
```

## Scoring Rubric

| Dimension | Weight | Source |
|-----------|--------|--------|
| Hook Correctness | 60% | test-hooks.sh — exit codes, pattern matching, protocol compliance |
| Skill Structure | 20% | validate-skills.sh — frontmatter, naming, description length |
| Command Structure | 20% | validate-cmds.sh — frontmatter, description presence |

**Why these weights:** Hooks are weighted 60% because they are the enforcement layer — a failing hook silently defeats every skill and command downstream. Skills (20%) and commands (20%) are equal because each is an invocable surface, and both need to be individually reachable.

## Grades

| Grade | Score | Meaning |
|-------|-------|---------|
| A | 90-100% | Production ready |
| B | 80-89% | Minor issues |
| C | 70-79% | Needs attention |
| D | 60-69% | Significant issues |
| F | <60% | Failing |

## Sample output

```
ValidationForge Plugin Benchmark — 2026-04-17T14:22Z
------------------------------------------------------
Hooks (60%): 7/7 passing
  PASS block-test-files.js (exit 2 on *.test.ts)
  PASS evidence-gate-reminder.js (stderr on TaskUpdate)
  PASS completion-claim-validator.js (catches "done" w/o evidence)
  PASS mock-detection.js (flags jest.mock)
  PASS validation-not-compilation.js (post-build reminder)
  PASS evidence-quality-check.js (flags 0-byte files)
  PASS validation-state-tracker.js (tracks validate runs)
Skills (20%): 48/48 frontmatter valid
Commands (20%): 17/17 frontmatter valid

Aggregate: 100.0% — Grade A (prior: 98.1% — +1.9pp)
No regressions vs audit-artifacts/benchmark-baseline.json
```

## Baseline Comparison

Results save to `audit-artifacts/benchmark-baseline.json`. Compare after changes:

```bash
# Run benchmark, compare with previous baseline
bash scripts/benchmark/aggregate-results.sh
# Review: cat audit-artifacts/benchmark-baseline.json
```

## Top 10 Skills by Impact

When evaluating skills manually, prioritize these by user-facing impact:

1. **functional-validation** — Core Iron Rule enforcement
2. **e2e-validate** — Orchestrator routing all workflows
3. **create-validation-plan** — Journey discovery
4. **gate-validation-discipline** — Evidence gates
5. **no-mocking-validation-gates** — Mock blocking
6. **preflight** — Prerequisites check
7. **verification-before-completion** — Premature completion prevention
8. **error-recovery** — Fix loop protocol
9. **forge-execute** — Execution orchestration
10. **forge-plan** — Plan orchestration
