---
name: no-mocking-validation-gates
description: "Iron rule: no mocks/stubs/test files. Hook blocks *.test.ts, __tests__/, jest.mock(), etc. When mocking tempts: diagnose why real system unavailable, fix it, validate real system instead."
triggers:
  - "block test file"
  - "mock detection"
  - "prevent mocking"
  - "test double elimination"
  - "real system validation redirect"
context_priority: critical
---

# No-Mocking Validation Gates

## Scope

This skill handles: blocking mock/test file creation, detecting mock code patterns, redirecting to real validation.
Does NOT handle: how to validate (use `functional-validation`), evidence examination (use `gate-validation-discipline`).

## The Iron Rule

Mocking creates **false confidence**. Mock drift is the silent killer:

```
Month 1: API returns {"data": [...]}          Mock returns {"data": [...]}       MATCH
Month 3: API adds {"data": [...], "meta": {}} Mock still returns {"data": [...]} DRIFT
Month 6: Code crashes on missing "meta"       Tests still pass                   BUG HIDDEN
```

The tests pass. The code is broken. The mock is lying.

## What Gets Blocked

The pre-tool-use hook rejects Write/Edit operations targeting:

| Category | Examples |
|----------|----------|
| Test files | `*.test.ts`, `*.spec.js`, `*_test.go`, `test_*.py`, `*Tests.swift` |
| Test dirs | `__tests__/`, `__mocks__/`, `mocks/`, `stubs/`, `fixtures/` |
| Mock code | `jest.mock()`, `vi.fn()`, `sinon.stub()`, `unittest.mock`, `XCTest`, `gomock` |

For the complete pattern catalog (12 thought patterns, all blocked file patterns,
all blocked code patterns by language), see `references/mock-pattern-catalog.md`.

## What Is NOT Blocked

- Playwright or browser automation (interacts with the real system)
- Database seed scripts (populates real databases with real data)
- API client code that calls real endpoints
- Integration with real external services via staging/dev environments
- Files in `e2e-evidence/`, `validation-evidence/`, `.claude/`, `validationforge/`

## When You Want to Mock: The Three-Step Correction

1. **DIAGNOSE** — Why can't I use the real system? (not running? not configured? too slow?)
2. **FIX** — Make the real system available (start it, configure it, fix it)
3. **VERIFY** — Validate through the real system (run it, exercise it, capture evidence)

For detailed commands and a real-world mock-drift example, see `references/real-system-validation-guide.md`.

## Rules

1. **NEVER create** any file matching blocked patterns — the hook will reject it
2. **NEVER write** mock/stub/spy code in any language — the hook detects it
3. **ALWAYS fix** the real dependency instead of mocking it
4. **ALWAYS validate** through the actual system interface
5. **Slowness is a bug** — profile and fix it, don't mock around it

## Security Policy

This skill blocks file creation and code patterns. It never modifies existing production code,
never disables security checks, and never introduces new functionality. It only prevents
the creation of mock/test artifacts.

## Related Skills

- `functional-validation` — The protocol for how to validate through the real system
- `gate-validation-discipline` — Evidence examination before marking tasks complete
- `e2e-validate` — End-to-end validation flows for complex user journeys
- `error-recovery` — When real system validation fails, structured recovery
