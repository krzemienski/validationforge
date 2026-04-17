# Deep Review: `no-mocking-validation-gates` skill

Review date: 2026-04-17
Reviewer: auto-claude coder (phase-1-subtask-3)
Worktree: `.auto-claude/worktrees/tasks/004-skill-deep-review-top-10`
Node: v25.9.0

## Summary

| Area | Status |
|---|---|
| YAML frontmatter | OK — `name: no-mocking-validation-gates`, description block-scalar valid |
| Scope section | OK |
| Iron Rule / mock-drift illustration | OK |
| "What Gets Blocked" table | ⚠ Several rows overstate what the hook actually blocks |
| "What Is NOT Blocked" allowlist | OK — matches `hooks/patterns.js` ALLOWLIST 1:1 |
| 3-Step Correction | OK (DIAGNOSE / FIX / VERIFY) |
| Rules (5 items) | OK, but Rule 2 wording "the hook detects it" implies PreToolUse rejection when the actual hook is PostToolUse + stderr |
| Related Skills (4) | All 4 exist in `./skills/` (functional-validation, gate-validation-discipline, e2e-validate, error-recovery) |
| `references/mock-pattern-catalog.md` | Multiple factually-incorrect "blocked pattern" claims (see Accuracy Issues) |
| `references/real-system-validation-guide.md` | Mostly accurate; `xcrun simctl erase all` is very aggressive — reader should be warned |

| Severity | Count |
|---|---|
| CRITICAL (causes false PASS verdict) | 0 |
| HIGH (SKILL/reference claim a pattern is blocked that is NOT blocked) | 4 |
| MEDIUM (missing/overclaimed detection patterns) | 5 |
| LOW (wording, imprecision, improvement) | 5 |

No CRITICAL defects — no finding would cause a validator to produce a false PASS verdict during /validate. The gravest issues are **false promises of protection**: the skill tells readers that certain file paths and mock patterns will be stopped by a hook, but several of those claims do not match the actual `hooks/block-test-files.js` + `hooks/patterns.js` + `hooks/mock-detection.js` behaviour. A reader who trusts the catalog could still slip a test artifact into the repo and believe the Iron Rule is enforced when it is not.

## Scope of review

Files opened and read line-by-line:

1. `./skills/no-mocking-validation-gates/SKILL.md` (77 lines)
2. `./skills/no-mocking-validation-gates/references/mock-pattern-catalog.md` (116 lines)
3. `./skills/no-mocking-validation-gates/references/real-system-validation-guide.md` (125 lines)
4. `./hooks/block-test-files.js` (57 lines) — PreToolUse hook
5. `./hooks/mock-detection.js` (35 lines) — PostToolUse hook
6. `./hooks/patterns.js` (54 lines) — CommonJS bridge
7. `./hooks/hooks.json` (57 lines) — hook wiring
8. `./.opencode/plugins/validationforge/patterns.ts` (115 lines) — canonical pattern source

Cross-checks performed:

- `./skills/functional-validation/SKILL.md` — reciprocal cross-link target
- `./skills/gate-validation-discipline/SKILL.md` — reciprocal cross-link target
- `./skills/e2e-validate/SKILL.md` — reciprocal cross-link target
- `./skills/error-recovery/SKILL.md` — reciprocal cross-link target
- `./commands/validate.md` — referenced by block-test-files hook error message

Commands executed to verify claims:

| Command | Purpose | Result |
|---|---|---|
| `node ./e2e-evidence/skill-review/no-mocking-validation-gates/test-patterns.js` | Exercise every pattern against candidate paths + code | Recorded in `pattern-test-transcript.txt` (74 lines) |
| `node --version` | tooling baseline | `v25.9.0` |

(Tooling baseline: `docker`, `xcrun`, `psql` are referenced by the guide but the worktree sandbox disallows those commands, so the guide's commands are checked via syntax/flag review only. This is noted in LOW-4.)

## Accuracy Issues (HIGH — false protection claims)

These are the most important findings. Each is a claim that the hook **will block** a pattern, verified empirically to be **NOT blocked**.

### HIGH-1: SKILL.md + catalog claim `__mocks__/` is a blocked test directory. It is NOT blocked.

- SKILL.md `./skills/no-mocking-validation-gates/SKILL.md:34`:
  `| Test dirs | __tests__/, __mocks__/, mocks/, stubs/, fixtures/ |`
- catalog `./skills/no-mocking-validation-gates/references/mock-pattern-catalog.md:36`:
  `| __mocks__/ | JavaScript/TypeScript | Jest manual mock directory |`
- Actual patterns in `./.opencode/plugins/validationforge/patterns.ts`:
  `/\/__tests__\//` (covers `__tests__/`), `/\/mocks\//`, `/\/stubs\//`, `/\/fixtures\//`, `/\/test-utils\//`.
  There is **no** `/\/__mocks__\//` pattern.
- Empirical evidence (`pattern-test-transcript.txt:3-5`):
  ```
  __mocks__/api.ts           -> NOT-BLOCKED
  __mocks__/api.js           -> NOT-BLOCKED
  /project/__mocks__/api.ts  -> NOT-BLOCKED
  ```
  `/\/mocks\//` does NOT match `__mocks__/` because the underscores break the substring.
- Fix options (Phase 4 will apply one): **either** add `/\/__mocks__\//` to `patterns.ts` (preferred, since it matches reader expectation), **or** drop the claim from SKILL.md/catalog. The spec forbids editing hooks/ and rules/ source, but `patterns.ts` is the hook's own config not a rule file — still, the safer move per spec scope is to adjust the catalog + SKILL.md claims.
  Actually the spec says "Do NOT modify commands/, agents/, rules/, or hooks/ source" — `patterns.ts` lives under `.opencode/plugins/validationforge/` not `hooks/`, but `hooks/patterns.js` reads it. To stay strictly inside the review's scope, fix the SKILL.md/catalog claim in Phase 4.

### HIGH-2: catalog claims `*_test.py` is a blocked Python pattern. Only `test_*.py` is blocked.

- catalog `./skills/no-mocking-validation-gates/references/mock-pattern-catalog.md:32`:
  `| *_test.py, test_*.py | Python | pytest or unittest tests |`
- Actual regex: `/test_[^/]+\.py$/` (in `patterns.ts:8`). This matches `test_foo.py` but not `my_module_test.py`.
- Empirical (`pattern-test-transcript.txt:12-13`):
  ```
  my_module_test.py          -> NOT-BLOCKED
  /project/my_module_test.py -> NOT-BLOCKED
  ```
  Contrast with `test_foo.py -> BLOCK: /test_[^/]+\.py$/` (transcript:22).
- Why this matters: pytest's `python_files` setting commonly adds `*_test.py` in addition to the default `test_*.py`. A codebase using the `*_test.py` convention would have tests silently created past the hook.
- Fix in Phase 4: correct the catalog row to `test_*.py` only, OR (follow-up) request a `patterns.ts` addition of `/_test\.py$/`.

### HIGH-3: catalog claims Java/Kotlin/Rust test file names are blocked. None of them are.

- catalog rows 33 & 34 in `./skills/no-mocking-validation-gates/references/mock-pattern-catalog.md`:
  ```
  | *Test.java, *Test.kt | Java/Kotlin | JUnit test classes |
  | *_test.rs            | Rust        | #[cfg(test)] modules |
  ```
- `patterns.ts` TEST_PATTERNS contain no `.java`, `.kt`, or `.rs` entry.
- Empirical (`pattern-test-transcript.txt`):
  ```
  _test.rs              -> NOT-BLOCKED
  /project/src/lib_test.rs -> NOT-BLOCKED
  SomeTest.java         -> NOT-BLOCKED
  SomeTest.kt           -> NOT-BLOCKED
  /project/SomeTest.java -> NOT-BLOCKED
  ```
- Why this matters: Iron Rule applies to all languages; Java and Kotlin are mainstream JVM targets and Rust is a ValidationForge-supported platform (see `./skills/cli-validation/SKILL.md`). A reader of the catalog who trusts the table would believe `UserServiceTest.java` is blocked — it is not.
- Fix in Phase 4: either drop the claim rows (safer given spec scope) or flag them with "Blocked by rules/validation-discipline, not by hook" if the rule text does cover them. A quick `grep` in `./rules/validation-discipline.md` is recommended before editing.

### HIGH-4: catalog claims `conftest.py`, `testing/`, and `factories/` are blocked. None are.

- catalog rows in `./skills/no-mocking-validation-gates/references/mock-pattern-catalog.md`:
  - line 39 `| test-utils/, testing/ | Any | Test utility modules |`
  - line 41 `| conftest.py | Python | pytest configuration and fixtures |`
  - line 42 `| factories/ | Any | Test data factory patterns |`
- `patterns.ts` TEST_PATTERNS contains `/\/test-utils\//` (which matches `test-utils/`) but does NOT contain `/\/testing\//`, any `conftest\.py` pattern, or `/\/factories\//`.
- Empirical (`pattern-test-transcript.txt`):
  ```
  testing/helpers.ts         -> NOT-BLOCKED
  /project/testing/helpers.ts -> NOT-BLOCKED
  factories/user.ts          -> NOT-BLOCKED
  /project/factories/user.ts -> NOT-BLOCKED
  conftest.py                -> NOT-BLOCKED
  /project/conftest.py       -> NOT-BLOCKED
  ```
- Why this matters: all three directory/file conventions are mainstream pytest/test-framework patterns. A `conftest.py` is the most common vehicle for Python test fixtures (which the catalog's Python section also flags as forbidden). The Iron Rule expects the hook to block these; it does not.
- Fix in Phase 4: split the catalog row so `test-utils/` stays in the "Blocked by hook" column and `testing/` moves to an "Iron Rule manual enforcement" column; drop or re-classify `conftest.py` and `factories/`.

## Accuracy Issues (MEDIUM — code pattern over-claims)

The catalog's "Blocked Code Patterns by Language" sections list many patterns as "ALL BLOCKED — do not use any of these". Empirically, `hooks/mock-detection.js` (which uses `MOCK_PATTERNS` from `patterns.ts`) detects only a subset.

### MED-1: JavaScript/TypeScript — `jest.fn()`, `jest.spyOn`, `vi.fn()`, `vi.spyOn`, `sinon.mock`, `sinon.fake`, MSW (`setupServer`, `http.get`), `@testing-library/react` imports are NOT detected.

- Catalog `./skills/no-mocking-validation-gates/references/mock-pattern-catalog.md:46-63` claims all 13 JS/TS patterns are "ALL BLOCKED".
- Empirical detection from `pattern-test-transcript.txt:29-41`:
  ```
  jest.mock    -> DETECTED
  jest.fn      -> NOT-DETECTED
  jest.spyOn   -> NOT-DETECTED
  vi.mock      -> DETECTED
  vi.fn        -> NOT-DETECTED
  vi.spyOn     -> NOT-DETECTED
  sinon.stub   -> DETECTED
  sinon.mock   -> NOT-DETECTED
  sinon.fake   -> NOT-DETECTED
  nock         -> DETECTED
  MSW setupServer -> NOT-DETECTED
  MSW http.get -> NOT-DETECTED
  @testing-library import -> NOT-DETECTED
  ```
- Notable: this is also inconsistent with SKILL.md "What Gets Blocked" row `vi.fn()` (SKILL.md:36) — `vi.fn()` is not in `MOCK_PATTERNS`.
- Fix in Phase 4: either tighten the catalog to list only the patterns actually in `MOCK_PATTERNS` with a header "These specific patterns trigger the mock-detection hook; the Iron Rule forbids all mocking — if the hook misses something, the discipline still applies", or split the table into "Hook-detected" vs "Discipline-forbidden". The latter is more honest.

### MED-2: Python — `from unittest import mock`, `import mock`, `@patch(...)`, `@patch.object`, `with patch(...)`, `monkeypatch.setattr`, `@pytest.fixture`, `pytest.mark.parametrize` are NOT detected.

- Catalog `./skills/no-mocking-validation-gates/references/mock-pattern-catalog.md:66-78` claims 9 Python patterns are "ALL BLOCKED".
- Empirical: only `from unittest.mock import` is detected (transcript:43-50). Everything else returns NOT-DETECTED.
- Specifically dangerous gaps: `@patch('module.Class')` is the Python idiom most likely to appear in actual mocking code; the catalog says it's blocked; the hook does not see it.
- Fix: same split as MED-1 — clarify what the hook sees vs. what the discipline forbids.

### MED-3: Swift — `import XCTest` alone, `XCTAssertEqual`, `XCTAssertTrue`, `XCTAssertNil`, `XCTestExpectation` are NOT detected.

- Catalog `./skills/no-mocking-validation-gates/references/mock-pattern-catalog.md:83-91` claims 7 Swift patterns are "ALL BLOCKED".
- Empirical: only `class.*Tests.*XCTestCase` and `@testable import` are detected (transcript:52-57). The regex `/XCTestCase/` also fires for any line literally containing "XCTestCase", but a test class written `class FooTest: XCTestCase` (singular `Test`) still matches the same regex (matches substring), but `XCTAssertEqual(a, b)` does NOT mention XCTestCase so is not matched.
- Critical gap: a Swift test file named `FooTests.swift` (which IS blocked at file-creation time) is redundant to prevent assertions, but if an edit is made to an allowlisted file that includes XCTAsserts, mock-detection would silently accept.

### MED-4: Go — `import "testing"`, `func TestMyFunction(t *testing.T)`, `httptest.NewServer`, `mock.NewMockClient` NOT detected.

- Catalog `./skills/no-mocking-validation-gates/references/mock-pattern-catalog.md:96-103` claims 6 Go patterns are "ALL BLOCKED".
- Empirical (transcript:60-66):
  ```
  import testing         -> NOT-DETECTED
  func Test caps         -> NOT-DETECTED     ← Go convention is uppercase Test
  func test lower        -> DETECTED (only lowercase matches)
  httptest.NewServer     -> NOT-DETECTED
  httptest.NewRecorder   -> DETECTED
  gomock.NewController   -> DETECTED
  mock.NewMockClient     -> NOT-DETECTED
  ```
- **Subtle bug in `MOCK_PATTERNS`**: the regex `/func test.*\(\)/` is case-sensitive lowercase, but Go testing convention requires `func TestXxx(t *testing.T)` (capital T). So the one Go function pattern the hook checks actually matches non-test helpers rather than real tests.
- This is the only finding that touches hook source behaviour directly. Per spec scope (no hook edits), the fix is to correct the catalog's claim for Go. A follow-up TODO should be logged to request `MOCK_PATTERNS` update (change to `/func [Tt]est.*\(/` or add a second entry).

### MED-5: Rust — ALL listed patterns (`#[cfg(test)]`, `mod tests`, `#[test]`, `fn test_something`, `mock!`, `automock`) NOT detected.

- Catalog `./skills/no-mocking-validation-gates/references/mock-pattern-catalog.md:107-115` claims 6 Rust patterns are "ALL BLOCKED".
- Empirical (transcript:68-73): every Rust pattern returns NOT-DETECTED.
- Rust has no file-pattern coverage (HIGH-3) AND no code-pattern coverage. The skill currently provides zero enforcement for Rust beyond the Iron Rule as prose. The cli-validation skill explicitly mentions `cargo` as a supported tool, so this gap matters.

## Stale References / Broken Cross-Links

### STALE-1: SKILL.md "What Gets Blocked" row example mismatches hook patterns.

- SKILL.md `./skills/no-mocking-validation-gates/SKILL.md:36`:
  `| Mock code | jest.mock(), vi.fn(), sinon.stub(), unittest.mock, XCTest, gomock |`
- `vi.fn()` is NOT in `MOCK_PATTERNS`. `XCTest` alone (not `XCTestCase`) is not matched either. `gomock` is represented only by `/gomock\.NewController/`.
- Reclassified as HIGH-adjacent but listed here because SKILL.md is the first/only surface a reader sees from the tool-tip. Recommended replacement examples: `jest.mock(), vi.mock(), sinon.stub(), from unittest.mock import, XCTestCase, gomock.NewController`.

### STALE-2: `real-system-validation-guide.md` uses `iPhone 16` as the default simulator name.

- `./skills/no-mocking-validation-gates/references/real-system-validation-guide.md:37, 54`:
  `xcrun simctl boot "iPhone 16"` and `xcodebuild ... 'platform=iOS Simulator,name=iPhone 16' build`
- Current Xcode 16.x ships both "iPhone 16" and "iPhone 16 Pro"; this is fine today. Flag as LOW: these device names rotate each Xcode release and the guide will need a refresh pass every autumn. Safer would be `xcrun simctl list devices available` + pick a device, or `name=Any iOS Simulator Device`.

## Missing Content / Wording Gaps

### LOW-1: Rule 2 wording ("the hook detects it") implies PreToolUse blocking; `mock-detection.js` is PostToolUse.

- SKILL.md `./skills/no-mocking-validation-gates/SKILL.md:60`:
  `2. NEVER write mock/stub/spy code in any language — the hook detects it`
- `./hooks/hooks.json:43-47` registers `mock-detection.js` under `PostToolUse` matcher `Edit|Write|MultiEdit`. The hook writes to stderr and `process.exit(2)`. In the current Claude Code hook spec, a PostToolUse exit-2 surfaces an error to the model but does NOT undo the already-completed write.
- A reader might assume "hook detects it" means the Edit is rejected (as with `block-test-files.js`). In reality the file IS written; the stderr message serves as discipline feedback to the model.
- Recommendation: clarify wording to "the hook warns after the fact (PostToolUse); revert the change manually".

### LOW-2: SKILL.md says "e2e-validate — End-to-end validation flows"; `e2e-validate` is labeled in CLAUDE.md as the 7-phase orchestrator.

- SKILL.md `./skills/no-mocking-validation-gates/SKILL.md:75`:
  `- e2e-validate — End-to-end validation flows for complex user journeys`
- Canonical description in `./skills/e2e-validate/SKILL.md` presents it as orchestrator for the whole /validate pipeline, not only "end-to-end" journeys. Wording mismatch is minor but can mislead.

### LOW-3: Catalog's `__tests__/` row lists pattern as "Jest test directory convention" — the hook regex `/\/__tests__\//` catches any `__tests__/` path regardless of language.

- Minor precision nit: it is blocked for any language, not only Jest.

### LOW-4: `real-system-validation-guide.md` uses `xcrun simctl erase all`.

- `./skills/no-mocking-validation-gates/references/real-system-validation-guide.md:36`:
  `xcrun simctl shutdown all && xcrun simctl erase all`
- `simctl erase all` wipes every simulator on the host (not just the one the validator is using). Real developers running this command lose all simulator state, not just the flaky one. Suggest documenting it as "aggressive reset — targets the specific UDID instead: `xcrun simctl erase <UDID>`".
- This is not validated from inside this sandbox (xcrun is not available to this worktree), so severity is LOW on safety grounds, not verified at runtime.

### LOW-5: Catalog's "12 Thought Patterns" uses `docker run -d -p 5432:5432 postgres:16` without a volume.

- `./skills/no-mocking-validation-gates/references/mock-pattern-catalog.md:11`:
  `docker run -d -p 5432:5432 postgres:16`
- Missing `-v` for data persistence and missing `-e POSTGRES_PASSWORD=...`. The other guide (`real-system-validation-guide.md:22`) includes the password flag, so the catalog should align for consistency.

## Recommendations (for Phase 4)

Priority order (CRITICAL first; all HIGH should be fixed, MEDIUM as time permits):

1. **HIGH-1** — In `./skills/no-mocking-validation-gates/SKILL.md` line 34 and `./skills/no-mocking-validation-gates/references/mock-pattern-catalog.md` line 36, remove or correctly qualify the `__mocks__/` claim. Either drop it, or add an explicit footnote: "`__mocks__/` is forbidden by the Iron Rule (via `rules/validation-discipline.md`) but not by the `block-test-files` hook pattern. Treat it as blocked."
2. **HIGH-2** — In `mock-pattern-catalog.md` line 32, change `| *_test.py, test_*.py |` to `| test_*.py, *.test.py |` (or only `test_*.py` and add a follow-up TODO for `*_test.py`).
3. **HIGH-3** — In `mock-pattern-catalog.md` lines 33-34, drop Java/Kotlin/Rust rows from the "blocked file patterns" table OR move them to a separate "Forbidden by Iron Rule (manual enforcement)" sub-table so readers do not believe the hook catches them.
4. **HIGH-4** — In `mock-pattern-catalog.md` lines 39, 41, 42, correct the rows for `testing/`, `conftest.py`, and `factories/`. Keep `test-utils/` in the hook-blocked column; move the other three to "Iron Rule (not hook-enforced)".
5. **STALE-1** — In SKILL.md line 36, change the Mock code example list to patterns that are actually detected: `jest.mock(), vi.mock(), sinon.stub(), from unittest.mock import, XCTestCase, gomock.NewController`.
6. **MED-1..5** — Restructure `mock-pattern-catalog.md` "Blocked Code Patterns by Language" to distinguish **(A)** patterns the `mock-detection` hook actually flags (the real MOCK_PATTERNS) from **(B)** patterns that are forbidden by the Iron Rule but the hook does not see. Both get a "do not use" directive; only (A) triggers hook output.
7. **LOW-1** — In SKILL.md Rule 2 (line 60), replace "the hook detects it" with "the `mock-detection` hook will flag it after the edit; revert the change immediately".
8. **LOW-2** — In SKILL.md line 75, replace "End-to-end validation flows for complex user journeys" with "Orchestrator for the 7-phase /validate pipeline" to match `./skills/e2e-validate/SKILL.md` and `./CLAUDE.md`.
9. **LOW-5** — Align the docker command in `mock-pattern-catalog.md` line 11 with the one in `real-system-validation-guide.md` line 22 (`-e POSTGRES_PASSWORD=devpass`).
10. **Follow-up (outside this task)** — log a ticket to expand `MOCK_PATTERNS` in `.opencode/plugins/validationforge/patterns.ts` to cover `jest.fn`, `vi.fn`, `@patch`, `func Test`, and the Rust attributes. This is the actual enforcement gap. The review's scope forbids editing hook source, so this review records the gap without changing it.

## Success criteria (per implementation_plan.json phase-1-subtask-3)

- [x] findings.md exists at `./e2e-evidence/skill-review/no-mocking-validation-gates/findings.md`
- [x] SKILL.md claims vs hook behavior gap documented (HIGH-1, HIGH-3, MED-*)
- [x] Every language in the catalog was checked for syntax accuracy (JS/TS, Python, Swift, Go, Rust — all five present in catalog, all empirically tested in `test-patterns.js`)

## Evidence files captured

- `./e2e-evidence/skill-review/no-mocking-validation-gates/findings.md` (this file)
- `./e2e-evidence/skill-review/no-mocking-validation-gates/test-patterns.js` (reproducible probe)
- `./e2e-evidence/skill-review/no-mocking-validation-gates/pattern-test-transcript.txt` (transcript of probe output)
