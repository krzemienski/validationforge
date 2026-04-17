---
skill: no-mocking-validation-gates
reviewer: R3
date: 2026-04-16
verdict: PASS
---

# no-mocking-validation-gates review

## Frontmatter check
- name: `no-mocking-validation-gates`
- description: `Iron rule: no mocks/stubs/test files. Hook blocks *.test.ts, __tests__/, jest.mock(), etc. When mocking tempts: diagnose why real system unavailable, fix it, validate real system instead.`
- description_chars: 172
- yaml_parses: yes

## Trigger realism
- Trigger phrases: `block test file`, `mock detection`, `prevent mocking`, `test double elimination`, `real system validation redirect`
- Realism score (5/5): Triggers match real developer temptations to cut corners

## Body-description alignment
- Verdict: PASS
- Evidence: Description matches scope exactly. Iron Rule enforces no-mock mandate with concrete mock-drift example (Month 1 MATCH → Month 3 DRIFT → Month 6 BUG HIDDEN). What Gets Blocked table is comprehensive (test files, test dirs, mock code). Three-Step Correction (DIAGNOSE → FIX → VERIFY) is pragmatic.

## MCP tool existence
- Tools referenced: blocking hook (pre-tool-use), mock pattern detection
- Confirmed: yes (enforcement is via hook system)

## Example invocation
"Diagnose why I can't test this feature without mocking the database"

## Verdict
PASS
- Iron Rule is explicit with concrete example of mock drift
- What Gets Blocked table covers all language patterns (JS/TS, Go, Python, Swift)
- What Is NOT Blocked clarifies that real system tools (Playwright, seed scripts, etc.) are allowed
- Three-Step Correction is pragmatic: diagnose the real problem, fix it, validate the real system
- Security Policy clarifies that blocking is non-invasive (only prevents file creation, doesn't modify code)
- Related skills are well-linked
