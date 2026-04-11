# Rule: No Mocks, Stubs, or Test Doubles
Source hooks: `hooks/block-test-files.js`, `hooks/mock-detection.js`.
Benchmark enforcement: `scripts/benchmark/score-project.sh` — +20 each for
"no test/spec files in src/ or lib/" and "no mock/stub patterns in src/".

## The Rule
IF the real system does not work, FIX THE REAL SYSTEM. Never create mocks, stubs, test
doubles, fakes, or `*.test.*` / `*.spec.*` files inside `src/` or `lib/`. Validation
runs against real binaries, real HTTP endpoints, or real simulators.

## What the hooks actually block
- Creating files matching `*.test.*` or `*.spec.*` under `src/` or `lib/` via Write/Edit
- JS/TS source files containing `jest.mock`, `sinon.`, `.mock(`, or `.stub(`

## What the hooks do NOT block (but you should still avoid)
- `__tests__/` or `__mocks__/` directories outside `src/`/`lib/`
- `_test.go` / `test_*.py` — not in current scoring, may be added later
- In-memory replacements of external dependencies for "test" purposes

## Allowed
- Call the real binary, curl the real HTTP endpoint, boot the real simulator
- Capture evidence to `e2e-evidence/<journey>/step-<NN>-<name>.<ext>`

## Why
Mocks drift from reality. A passing mock proves the mock agrees with itself, not with
the system being validated. Real-system checks catch real bugs.
