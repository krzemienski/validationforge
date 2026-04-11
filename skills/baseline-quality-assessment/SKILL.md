---
name: baseline-quality-assessment
description: "Capture immutable 'before' evidence before code changes. Proves changes improved targets without regressing existing functionality. Use for refactor, migration, dependency update, bug fix."
triggers:
  - "baseline capture"
  - "before-after comparison"
  - "regression detection"
  - "no-regressions proof"
  - "change impact"
context_priority: standard
---

# Baseline Quality Assessment

## Scope

Applies before any code change that modifies existing behavior: refactoring, migration,
feature addition, dependency update, performance optimization, or bug fix. Creates an
immutable "before" snapshot in `e2e-evidence/baseline/` so post-change validation can
prove: (1) changes improved what they targeted, (2) nothing previously working is broken.

Without a baseline, every claim of "no regressions" is unverifiable.

## When to Use

| Scenario | Baseline Required? |
|----------|--------------------|
| Refactoring | Yes — prove behavior preserved |
| Migration | Yes — prove new stack matches old |
| Feature addition | Yes — prove existing features still work |
| Dependency update | Yes — prove nothing broke |
| Performance optimization | Yes — prove functionality preserved |
| Bug fix | Yes — capture broken state, then fixed state |
| Net-new functionality (zero existing code changes) | Optional |

## 4-Step Baseline Process

### Step 1: Create baseline directory
```bash
mkdir -p e2e-evidence/baseline/
```
This directory is **immutable** after capture. Post-change evidence goes in `e2e-evidence/`, not `baseline/`.

### Step 2: Identify all existing user journeys
Use journey discovery from `create-validation-plan` to list every feature, endpoint, screen, or command.

### Step 3: Capture evidence for each target
Use the appropriate method per platform. See `references/baseline-capture-commands.md` for
platform-specific capture commands and storage path conventions.

### Step 4: Document the assessment
Save to `e2e-evidence/baseline/assessment.md` using the template in
`references/regression-comparison-template.md`.

## Regression Detection

| Severity | Definition | Action |
|----------|-----------|--------|
| **CRITICAL** | Worked in baseline, fails now | Must fix before proceeding |
| **HIGH** | Performance degraded >20% | Should fix before shipping |
| **MEDIUM** | Visual change not in requirements | Evaluate if intentional |
| **Not a regression** | Broken in baseline too | Pre-existing bug, document but don't block |

## Post-Change Comparison

After implementing changes, re-capture the same evidence and compare side-by-side.
Save comparison to `e2e-evidence/regression-check.md`. See `references/regression-comparison-template.md`
for the full template with verdict columns (NO REGRESSION / IMPROVED / REGRESSION).

## Rules

1. **Baseline MUST be captured before any code changes** — once editing starts, "before" state is gone
2. **Baseline evidence is immutable** — never overwrite/edit/delete files in `baseline/`. Re-capture to `baseline-v2/`
3. **Post-change evidence goes in `e2e-evidence/`** — not in `baseline/`. Keep them separate
4. **Regressions are CRITICAL findings** — fix before claiming completion
5. **Pre-existing bugs are not regressions** — baseline proves they existed before your changes
6. **Performance baselines need numbers** — "it felt fast" is not a baseline

## Security Policy

Baseline evidence may contain production-like data. Never commit baseline directories with
PII or credentials. Use `.gitignore` for `e2e-evidence/`.

## Related Skills

- **create-validation-plan** — Plan journeys before capturing baseline
- **preflight** — Ensure system is ready before baseline capture
- **e2e-validate** — Execute post-change validation using same capture methods
- **gate-validation-discipline** — Use regression check as a completion gate

## References

- `references/baseline-capture-commands.md` — Platform-specific capture commands and storage paths
- `references/regression-comparison-template.md` — Full comparison template with verdict format
