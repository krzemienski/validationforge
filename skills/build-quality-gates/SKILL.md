---
name: build-quality-gates
description: Multi-stage build quality enforcement — compile, lint, type-check, bundle analysis
triggers:
  - "build quality"
  - "quality gates"
  - "build pipeline"
  - "pre-deploy checks"
  - "build verification"
---

# Build Quality Gates

Multi-stage build quality enforcement. Each gate must PASS before proceeding to the next. Build gates verify that code compiles and meets structural quality standards — but build gates alone do NOT constitute validation. Functional validation (through real UI) is always required after build gates pass.

## When to Use

- Before any deployment or PR merge
- As the first phase of a validation plan
- When build failures need systematic diagnosis
- As part of `e2e-validate` preflight checks

## Gate Architecture

```
Gate 1: COMPILE     Gate 2: LINT      Gate 3: TYPE-CHECK   Gate 4: BUNDLE
Source → Binary     Style rules       Type safety          Size + deps
   |                   |                  |                    |
   v                   v                  v                    v
 PASS/FAIL          PASS/FAIL          PASS/FAIL            PASS/FAIL
   |                   |                  |                    |
   └───────────────────┴──────────────────┴────────────────────┘
                              |
                        ALL MUST PASS
                              |
                    ┌─────────┴─────────┐
                    │  Build gates are   │
                    │  NECESSARY but NOT │
                    │  SUFFICIENT for    │
                    │  validation.       │
                    └───────────────────┘
```

## Platform Detection

Detect the project's build system:

| Indicator | Build System | Compile Command |
|-----------|-------------|-----------------|
| `package.json` + `next.config.*` | Next.js | `npm run build` |
| `package.json` + `vite.config.*` | Vite | `npm run build` |
| `tsconfig.json` | TypeScript | `npx tsc --noEmit` |
| `*.xcodeproj` | Xcode | `xcodebuild -scheme X build` |
| `Cargo.toml` | Rust | `cargo build` |
| `go.mod` | Go | `go build ./...` |
| `pyproject.toml` | Python | `python -m py_compile` or framework-specific |

## Gate 1: Compile

**Objective:** Code compiles without errors.

```bash
mkdir -p e2e-evidence/build-gates

# Run the appropriate build command
BUILD_CMD="npm run build"  # or detected command
$BUILD_CMD 2>&1 | tee e2e-evidence/build-gates/step-01-compile.log
echo "EXIT_CODE: $?" >> e2e-evidence/build-gates/step-01-compile.log
```

### PASS Criteria
- Exit code 0
- No error lines in output (warnings are OK)
- Build artifacts produced

### FAIL Actions
- Read the full error log
- Identify the first error (cascading errors stem from it)
- Fix and re-run — do NOT proceed to Gate 2

## Gate 2: Lint

**Objective:** Code follows style rules and catches common mistakes.

```bash
# JavaScript/TypeScript
npx eslint . 2>&1 | tee e2e-evidence/build-gates/step-02-lint.log

# Python
ruff check . 2>&1 | tee e2e-evidence/build-gates/step-02-lint.log

# Go
go vet ./... 2>&1 | tee e2e-evidence/build-gates/step-02-lint.log

# Swift
swiftlint 2>&1 | tee e2e-evidence/build-gates/step-02-lint.log

echo "EXIT_CODE: $?" >> e2e-evidence/build-gates/step-02-lint.log
```

### PASS Criteria
- Zero errors (warnings acceptable, but document them)
- No auto-fixable issues remaining

### FAIL Actions
- Run auto-fix if available (`eslint --fix`, `ruff check --fix`)
- Fix remaining issues manually
- Re-run lint

## Gate 3: Type-Check

**Objective:** Type system verifies correctness (typed languages only).

```bash
# TypeScript
npx tsc --noEmit 2>&1 | tee e2e-evidence/build-gates/step-03-typecheck.log

# Python (mypy)
mypy . 2>&1 | tee e2e-evidence/build-gates/step-03-typecheck.log

# Go (included in build, but explicit vet)
go vet ./... 2>&1 | tee e2e-evidence/build-gates/step-03-typecheck.log

echo "EXIT_CODE: $?" >> e2e-evidence/build-gates/step-03-typecheck.log
```

### PASS Criteria
- Zero type errors
- All imports resolve

### Skip Condition
- Dynamically typed language with no type checker configured

## Gate 4: Bundle Analysis

**Objective:** Production bundle is reasonable size, no unexpected dependencies.

```bash
# Next.js (built-in analysis)
ANALYZE=true npm run build 2>&1 | tee e2e-evidence/build-gates/step-04-bundle.log

# Vite
npx vite build --mode production 2>&1 | tee e2e-evidence/build-gates/step-04-bundle.log

# Generic: check output directory size
du -sh dist/ build/ .next/ out/ 2>/dev/null | tee e2e-evidence/build-gates/step-04-bundle.log
```

### PASS Criteria
- Bundle size within project's historical range (or reasonable for app type)
- No unexpected large dependencies
- No source maps in production build (unless intentional)

### Warning Triggers (not FAIL, but document)
- Bundle grew >20% from previous build
- New dependencies added >100KB
- Duplicate dependencies detected

## Gate Report

```markdown
# Build Quality Gate Report

**Project:** {name}
**Build system:** {detected}
**Date:** YYYY-MM-DD

| Gate | Verdict | Duration | Evidence |
|------|---------|----------|----------|
| 1. Compile | PASS/FAIL | Xs | e2e-evidence/build-gates/step-01-compile.log |
| 2. Lint | PASS/FAIL | Xs | e2e-evidence/build-gates/step-02-lint.log |
| 3. Type-check | PASS/FAIL/SKIP | Xs | e2e-evidence/build-gates/step-03-typecheck.log |
| 4. Bundle | PASS/FAIL | Xs | e2e-evidence/build-gates/step-04-bundle.log |

**Overall: PASS | FAIL**

## Warnings
- [list any non-blocking warnings]

## IMPORTANT
Build gates passing does NOT mean the feature works.
Functional validation through real UI is still required.
```

Save to `e2e-evidence/build-gates/report.md`.

## Integration with ValidationForge

- Build gates are the **first** step in any validation plan, never the **only** step
- After all 4 gates PASS, proceed to platform-specific validation (web, iOS, CLI, API)
- The `completion-claim-validator` hook will flag if you claim completion based on build gates alone
- Evidence files go to `e2e-evidence/build-gates/` for the `verdict-writer` agent
