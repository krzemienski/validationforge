# Validation Discipline

## No-Mock Mandate

Never create test files, mocks, stubs, or test doubles. This includes:
- Files named `*.test.*`, `*.spec.*`, `*.mock.*`
- Any file importing `jest.mock`, `sinon`, or similar test frameworks
- In-memory fakes substituting for real services

## Evidence Standards

Every PASS/FAIL verdict must cite specific evidence:
- **Screenshots**: Describe what you SEE, not that the file exists
- **API responses**: Quote actual body AND status code, not just "it worked"
- **Build output**: Quote the actual success/failure line
- **Empty files**: 0-byte or near-empty files are INVALID evidence

## Gate Protocol

Never claim completion without personally examining the evidence:
1. Run the journey against the REAL system
2. Capture evidence to `e2e-evidence/{journey-slug}/`
3. Write verdict citing specific evidence
4. Only then mark the journey complete

## Iron Rules

```
1. IF the real system doesn't work, FIX THE REAL SYSTEM.
2. NEVER mark a journey PASS without specific cited evidence.
3. NEVER skip preflight — if it fails, STOP.
4. NEVER exceed 3 fix attempts per journey.
5. Compilation success is NOT functional validation.
```
