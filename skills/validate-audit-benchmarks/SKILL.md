---
name: validate-audit-benchmarks
description: Run automated benchmark suite to score hook correctness, skill/command structural integrity, and aggregate quality metrics.
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

## Grades

| Grade | Score | Meaning |
|-------|-------|---------|
| A | 90-100% | Production ready |
| B | 80-89% | Minor issues |
| C | 70-79% | Needs attention |
| D | 60-69% | Significant issues |
| F | <60% | Failing |

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
