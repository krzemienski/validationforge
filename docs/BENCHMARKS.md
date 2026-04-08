# ValidationForge Benchmark Suite

## Scoring Rubric

Each test case scores 0-2 points across four dimensions:

| Dimension | Weight | 0 (Fail) | 1 (Partial) | 2 (Pass) |
|-----------|--------|----------|-------------|----------|
| **Correctness** | 40% | Wrong output or crash | Correct behavior with minor defect | Exact expected output |
| **Format Compliance** | 20% | Missing/malformed JSON | Valid JSON, wrong schema | Correct hookSpecificOutput structure |
| **Error Handling** | 20% | Crash on bad input | Swallows error silently | Logs to stderr, exits 0 |
| **Security** | 20% | Allows injection/traversal | Partial mitigation | No exploitable behavior |

**Max score per case:** 8 points (2 per dimension). **Normalized:** (actual / max) * 100.

---

## Hook Benchmarks

### H1: block-test-files.js (PreToolUse)

Reads `tool_input.file_path` or `tool_input.filePath`. Blocks test/mock/stub patterns via `permissionDecision:"deny"`. Allowlists `e2e-evidence/`, `validationforge/`, `.claude/`.

| # | Category | Input (stdin JSON) | Expected Output | Rubric |
|---|----------|--------------------|-----------------|--------|
| 1 | Happy: test file | `{"tool_input":{"file_path":"src/auth.test.ts"}}` | JSON with `permissionDecision:"deny"` | Correctness: blocks; Format: valid deny JSON |
| 2 | Happy: spec file | `{"tool_input":{"file_path":"lib/utils.spec.jsx"}}` | `permissionDecision:"deny"` | Pattern `.spec.[jt]sx?` matched |
| 3 | Happy: mock dir | `{"tool_input":{"file_path":"src/mocks/api.js"}}` | `permissionDecision:"deny"` | Pattern `/mocks/` matched |
| 4 | Happy: normal file | `{"tool_input":{"file_path":"src/auth/login.ts"}}` | Silent exit 0, no stdout | No false positive |
| 5 | Allowlist: e2e-evidence | `{"tool_input":{"file_path":"e2e-evidence/login/step-01.png"}}` | Silent exit 0 | Allowlist overrides test patterns |
| 6 | Allowlist: .claude | `{"tool_input":{"file_path":".claude/hooks/test-blocker.js"}}` | Silent exit 0 | `.claude/` allowlisted |
| 7 | Edge: empty file_path | `{"tool_input":{"file_path":""}}` | Silent exit 0 | Empty string = no-op |
| 8 | Edge: missing field | `{"tool_input":{}}` | Silent exit 0 | Falls back to empty string |
| 9 | Edge: malformed JSON | `{not json` | stderr error, exit 0 | Error recovery in catch block |
| 10 | Edge: empty stdin | `` (empty) | stderr error, exit 0 | JSON.parse("") throws |
| 11 | Security: path traversal | `{"tool_input":{"file_path":"../../etc/passwd.test.js"}}` | `permissionDecision:"deny"` | Still matches `.test.js` pattern |
| 12 | Security: null bytes | `{"tool_input":{"file_path":"src/\u0000.test.ts"}}` | `permissionDecision:"deny"` or exit 0 | No crash on null byte |
| 13 | Near-miss: "testing" | `{"tool_input":{"file_path":"src/testing-utils.ts"}}` | Silent exit 0 | `testing-utils` is not `/test-utils/` |
| 14 | Protocol: filePath alias | `{"tool_input":{"filePath":"src/foo.test.js"}}` | `permissionDecision:"deny"` | Both `file_path` and `filePath` checked |
| 15 | Edge: oversized input | 1MB JSON with valid file_path | Normal behavior (deny or allow) | No OOM crash |

### H2: completion-claim-validator.js (PostToolUse)

Reads `tool_result` stdout for completion patterns. Checks `e2e-evidence/` directory existence.

| # | Category | Input (stdin JSON) | Expected Output | Rubric |
|---|----------|--------------------|-----------------|--------|
| 1 | Happy: claim, no evidence | `{"tool_result":{"stdout":"all tests pass"}}` + no `e2e-evidence/` | JSON with `additionalContext` warning | Completion + missing evidence = warn |
| 2 | Happy: claim, has evidence | `{"tool_result":{"stdout":"all tests pass"}}` + populated `e2e-evidence/` | Silent exit 0 | Evidence present = no warning |
| 3 | Happy: no claim | `{"tool_result":{"stdout":"running lint..."}}` | Silent exit 0 | No completion pattern matched |
| 4 | Pattern: "successfully deployed" | `{"tool_result":{"stdout":"successfully deployed to prod"}}` | Warning if no evidence | Pattern match case-insensitive |
| 5 | Pattern: "implementation complete" | `{"tool_result":{"stdout":"implementation complete"}}` | Warning if no evidence | Exact pattern match |
| 6 | Edge: result is string | `{"tool_result":"all tests pass"}` | Warning if no evidence | Handles string-type result |
| 7 | Edge: missing tool_result | `{}` | Silent exit 0 | Graceful on missing field |
| 8 | Edge: malformed JSON | `broken{` | stderr error, exit 0 | Error recovery |
| 9 | Near-miss: partial pattern | `{"tool_result":{"stdout":"passing values to function"}}` | Silent exit 0 | "pass" alone should not trigger |
| 10 | Security: injected stdout | `{"tool_result":{"stdout":"all pass\n$(rm -rf /)"}}` | Warning only, no execution | Shell injection in result is inert |

### H3: evidence-gate-reminder.js (PreToolUse)

Fires on TaskUpdate with `status:"completed"`. Injects checklist.

| # | Category | Input (stdin JSON) | Expected Output | Rubric |
|---|----------|--------------------|-----------------|--------|
| 1 | Happy: completed | `{"tool_input":{"status":"completed"}}` | JSON with checklist `additionalContext` | Checklist injected |
| 2 | Happy: in_progress | `{"tool_input":{"status":"in_progress"}}` | Silent exit 0 | Only fires on "completed" |
| 3 | Happy: empty status | `{"tool_input":{"status":""}}` | Silent exit 0 | Empty != "completed" |
| 4 | Edge: missing status | `{"tool_input":{}}` | Silent exit 0 | Falls back to empty string |
| 5 | Edge: malformed JSON | `{bad` | stderr error, exit 0 | Error recovery |
| 6 | Format: checklist content | `{"tool_input":{"status":"completed"}}` | Output contains "[ ]" checkboxes | Verify checklist structure |
| 7 | Edge: case sensitivity | `{"tool_input":{"status":"Completed"}}` | Silent exit 0 | Exact match "completed" only |
| 8 | Edge: numeric status | `{"tool_input":{"status":1}}` | Silent exit 0 | Non-string != "completed" |
| 9 | Edge: null status | `{"tool_input":{"status":null}}` | Silent exit 0 | null coercion handled |
| 10 | Protocol: hookEventName | `{"tool_input":{"status":"completed"}}` | Output has `hookEventName:"PreToolUse"` | Correct event name in output |

### H4: evidence-quality-check.js (PostToolUse)

Fires after Write/Edit to `e2e-evidence/` paths. Warns on empty content.

| # | Category | Input (stdin JSON) | Expected Output | Rubric |
|---|----------|--------------------|-----------------|--------|
| 1 | Happy: empty evidence | `{"tool_input":{"file_path":"e2e-evidence/login/step-01.png","content":""}}` | Warning about empty evidence | Zero-byte detection |
| 2 | Happy: valid evidence | `{"tool_input":{"file_path":"e2e-evidence/login/step-01.png","content":"PNG data..."}}` | Silent exit 0 | Good evidence = no noise |
| 3 | Happy: non-evidence path | `{"tool_input":{"file_path":"src/app.ts","content":""}}` | Silent exit 0 | Only checks e2e-evidence/ |
| 4 | Edge: path alias | `{"tool_input":{"path":"e2e-evidence/x.json","content":""}}` | Warning | Checks both `file_path` and `path` |
| 5 | Edge: new_string field | `{"tool_input":{"file_path":"e2e-evidence/x.md","new_string":""}}` | Warning | Edit tool uses `new_string` |
| 6 | Edge: missing content fields | `{"tool_input":{"file_path":"e2e-evidence/x.md"}}` | Warning (empty string fallback) | Both content and new_string missing |
| 7 | Edge: malformed JSON | `{bad` | stderr error, exit 0 | Error recovery |
| 8 | Near-miss: similar path | `{"tool_input":{"file_path":"src/e2e-evidence-helper.ts","content":""}}` | Warning (contains "e2e-evidence") | Uses `.includes()` not exact prefix |
| 9 | Security: traversal in path | `{"tool_input":{"file_path":"e2e-evidence/../../secret","content":""}}` | Warning (path contains "e2e-evidence") | No filesystem write from hook |
| 10 | Protocol: hookEventName | (case 1 input) | Output has `hookEventName:"PostToolUse"` | Correct event name |

### H5: mock-detection.js (PostToolUse)

Scans `content` or `new_string` for 20 mock/test framework patterns.

| # | Category | Input (stdin JSON) | Expected Output | Rubric |
|---|----------|--------------------|-----------------|--------|
| 1 | Happy: jest.mock | `{"tool_input":{"content":"jest.mock('./api')"}}` | Warning about mock pattern | Pattern detected |
| 2 | Happy: sinon.stub | `{"tool_input":{"content":"sinon.stub(obj, 'method')"}}` | Warning | Pattern detected |
| 3 | Happy: Python mock | `{"tool_input":{"content":"from unittest.mock import patch"}}` | Warning | Python pattern detected |
| 4 | Happy: clean code | `{"tool_input":{"content":"const result = await fetch(url)"}}` | Silent exit 0 | No mock patterns |
| 5 | Pattern: vitest | `{"tool_input":{"content":"vi.mock('./module')"}}` | Warning | `vi.mock(` pattern |
| 6 | Pattern: XCTestCase | `{"tool_input":{"content":"class LoginTests: XCTestCase {}"}}` | Warning | Swift test pattern |
| 7 | Pattern: describe/it | `{"tool_input":{"content":"describe('auth', () =>"}}` | Warning | Test framework pattern |
| 8 | Edge: empty content | `{"tool_input":{"content":""}}` | Silent exit 0 | Empty = no-op |
| 9 | Edge: missing content | `{"tool_input":{}}` | Silent exit 0 | Falls back to empty |
| 10 | Edge: new_string field | `{"tool_input":{"new_string":"jest.mock('./x')"}}` | Warning | Edit tool field |
| 11 | Near-miss: "describe" in comment | `{"tool_input":{"content":"// describe the algorithm"}}` | Silent exit 0 | Regex requires `describe('` |
| 12 | Near-miss: "assert" in name | `{"tool_input":{"content":"const assertValid = true"}}` | Warning (false positive) | `assert.\w+(` matches. Known limitation |
| 13 | Edge: malformed JSON | `{bad` | stderr error, exit 0 | Error recovery |
| 14 | Security: oversized content | 1MB content string, no patterns | Silent exit 0 | No regex catastrophic backtracking |
| 15 | Pattern: gomock | `{"tool_input":{"content":"ctrl := gomock.NewController(t)"}}` | Warning | Go mock pattern |

### H6: validation-not-compilation.js (PostToolUse)

Checks `tool_result` stdout for build success patterns.

| # | Category | Input (stdin JSON) | Expected Output | Rubric |
|---|----------|--------------------|-----------------|--------|
| 1 | Happy: build succeeded | `{"tool_result":{"stdout":"build succeeded"}}` | Reminder: compilation != validation | Pattern matched |
| 2 | Happy: webpack compiled | `{"tool_result":{"stdout":"webpack 5.0 compiled successfully"}}` | Reminder | Pattern matched |
| 3 | Happy: cargo build | `{"tool_result":{"stdout":"cargo build complete"}}` | Silent exit 0 | "cargo build" alone, no "succeeded" | 
| 4 | Happy: no build output | `{"tool_result":{"stdout":"linting complete"}}` | Silent exit 0 | No build pattern |
| 5 | Pattern: xcodebuild | `{"tool_result":{"stdout":"** BUILD SUCCEEDED **"}}` | Reminder | Case-sensitive `BUILD SUCCEEDED` |
| 6 | Pattern: tsc | `{"tool_result":{"stdout":"tsc --noEmit passed"}}` | Reminder | `tsc.*--noEmit` pattern |
| 7 | Edge: result as string | `{"tool_result":"compiled successfully"}` | Reminder | String-type handling |
| 8 | Edge: missing tool_result | `{}` | Silent exit 0 | Graceful fallback |
| 9 | Edge: malformed JSON | `{bad` | stderr error, exit 0 | Error recovery |
| 10 | Near-miss: "build" alone | `{"tool_result":{"stdout":"running build step 3"}}` | Silent exit 0 | Requires success qualifier |

### H7: validation-state-tracker.js (PostToolUse)

Checks `tool_input.command` for validation-related commands.

| # | Category | Input (stdin JSON) | Expected Output | Rubric |
|---|----------|--------------------|-----------------|--------|
| 1 | Happy: playwright | `{"tool_input":{"command":"npx playwright test"}}` | Evidence capture reminder | Pattern matched |
| 2 | Happy: curl localhost | `{"tool_input":{"command":"curl http://localhost:3000/api"}}` | Reminder | `curl.*localhost` matched |
| 3 | Happy: simctl | `{"tool_input":{"command":"xcrun simctl screenshot booted"}}` | Reminder | `simctl` matched |
| 4 | Happy: unrelated | `{"tool_input":{"command":"git status"}}` | Silent exit 0 | No validation pattern |
| 5 | Pattern: npm run dev | `{"tool_input":{"command":"npm run dev"}}` | Reminder | `npm run (dev|start|build)` |
| 6 | Pattern: lighthouse | `{"tool_input":{"command":"lighthouse https://localhost"}}` | Reminder | `lighthouse` matched |
| 7 | Edge: missing command | `{"tool_input":{}}` | Silent exit 0 | Optional chaining to empty |
| 8 | Edge: malformed JSON | `{bad` | stderr error, exit 0 | Error recovery |
| 9 | Edge: empty command | `{"tool_input":{"command":""}}` | Silent exit 0 | Empty string, no match |
| 10 | Security: injection | `{"tool_input":{"command":"curl localhost; rm -rf /"}}` | Reminder only | Hook reads, never executes command |

---

## Skill Benchmarks

40 skills across 7 categories. Each criterion scored 0-2 per skill.

### Evaluation Criteria (all categories)

| # | Criterion | What to Check | 0 | 1 | 2 |
|---|-----------|---------------|---|---|---|
| S1 | Frontmatter: name | `name:` matches directory name, kebab-case, `^[a-z][a-z0-9-]+$` | Missing or mismatched | Present but wrong case | Exact match |
| S2 | Frontmatter: description | `description:` exists, 10-200 chars, no jargon | Missing | Too short/long | Clear, actionable |
| S3 | Instruction voice | Body uses imperative verbs ("Run", "Check", "Invoke") not passive | All passive | Mixed | Consistent imperative |
| S4 | Tool references | Only references real CC tools (Read, Write, Edit, Bash, Glob, Grep, Agent, etc.) | References fake tools | 1 fake reference | All tools valid |
| S5 | Trigger accuracy | Skill description would cause correct agent selection for its use case | Wrong triggers | Ambiguous | Precise match |
| S6 | Context efficiency | No redundant preamble, no repeated CLAUDE.md content, under 500 lines | >500 lines or heavy duplication | Minor verbosity | Lean and focused |
| S7 | Reference completeness | `references/` files exist if SKILL.md cites them | Cited but missing | Partial | All cited files exist |
| S8 | Security: no secrets | No hardcoded paths, API keys, tokens, or credentials | Contains secrets | Hardcoded home paths | Clean |
| S9 | Iron rule compliance | Never suggests mocks/tests/stubs as remediation | Suggests mocks | Ambiguous language | Explicit no-mock stance |
| S10 | Cross-reference validity | Links to other skills/commands/agents resolve to real files | Broken links | Untested links | All verified |
| S11 | Platform consistency | Platform-specific skills reference correct toolchain | Wrong platform tools | Minor mismatch | Correct toolchain |
| S12 | Progressive disclosure | Uses headers/sections so agent can read incrementally | Wall of text | Some structure | Clear sections with headers |

### Category-Specific Checks

| Category | Skills | Additional Check |
|----------|--------|-----------------|
| **Platform (11)** | ios-validation, web-validation, api-validation, cli-validation, fullstack-validation, playwright-validation, chrome-devtools, ios-simulator-control, ios-validation-gate, ios-validation-runner, web-testing | Platform indicators match `platform-detector` agent logic |
| **Quality (6)** | functional-validation, gate-validation-discipline, no-mocking-validation-gates, build-quality-gates, verification-before-completion, preflight | References 7-phase pipeline stages correctly |
| **Design (4)** | design-validation, design-token-audit, stitch-integration, visual-inspection | Evidence capture includes visual artifacts |
| **Analysis (3)** | sequential-analysis, research-validation, retrospective-validation | Output format specified and parseable |
| **Specialized (6)** | accessibility-audit, responsive-validation, parallel-validation, e2e-testing, e2e-validate, create-validation-plan | No overlap with platform skills |
| **Operational (5)** | baseline-quality-assessment, condition-based-waiting, error-recovery, production-readiness-audit, full-functional-audit | Defines clear entry/exit conditions |
| **Forge (5)** | forge-setup, forge-plan, forge-execute, forge-team, forge-benchmark | References `allowed-tools` from corresponding command |

---

## Command Benchmarks

15 commands in two patterns: `validate-*` (name + triggers) and `forge-*` (description + allowed-tools).

### Evaluation Criteria

| # | Criterion | What to Check | 0 | 1 | 2 |
|---|-----------|---------------|---|---|---|
| C1 | Frontmatter present | Valid YAML between `---` delimiters | Missing or broken YAML | Partial fields | Complete and parseable |
| C2 | Description quality | `description:` is 10-150 chars, describes action not implementation | Missing | Vague | Clear verb-noun summary |
| C3 | validate-* has name | `name:` field matches filename (sans `.md`) | Missing for validate-* | Mismatched | Exact match |
| C4 | forge-* has allowed-tools | `allowed-tools:` lists valid CC tool names | Missing for forge-* | Contains invalid tool | All tools valid |
| C5 | Body references valid skills | Skill names in body match `skills/*/` directories | References nonexistent skill | Untested | All verified |
| C6 | Body references valid agents | Agent names match `agents/*.md` filenames | References nonexistent agent | Untested | All verified |
| C7 | No broken cross-refs | Links to other commands (e.g., "see /validate-fix") resolve | Broken references | Untested | All verified |
| C8 | $ARGUMENTS safety | If command accepts arguments, they are validated/sanitized in instructions | Raw interpolation | Partial sanitization | Safe usage or N/A |
| C9 | Naming convention | Filename is kebab-case, matches `name:` field or `forge-*` pattern | Wrong convention | Minor deviation | Correct |
| C10 | Pipeline stage reference | References correct pipeline stages (PREFLIGHT, PLAN, EXECUTE, etc.) | Wrong stage names | Incomplete | Correct stages |
| C11 | Output path consistency | References `e2e-evidence/` for output, not ad-hoc paths | Wrong output path | Inconsistent | Always `e2e-evidence/` |
| C12 | Iron rule presence | Includes or references the no-mock iron rule | Contradicts iron rule | Silent | Explicitly stated |

### Command Inventory

| Command | Pattern | Key Checks |
|---------|---------|------------|
| validate | validate-* | C1-C3, C5 (platform skills), C6 (platform-detector, evidence-capturer, verdict-writer) |
| validate-plan | validate-* | C1-C3, output is plan only (no execution) |
| validate-audit | validate-* | C1-C3, read-only constraint stated |
| validate-fix | validate-* | C1-C3, 3-strike limit documented |
| validate-ci | validate-* | C1-C3, exit codes documented |
| validate-team | validate-* | C1-C3, C6 (validation-lead), file ownership rules |
| validate-sweep | validate-* | C1-C3, C6 (sweep-controller), stop conditions |
| validate-benchmark | validate-* | C1-C3, 4 dimensions defined |
| vf-setup | validate-* | C1-C3, config output path documented |
| forge-setup | forge-* | C1, C4, init behavior specified |
| forge-plan | forge-* | C1, C4, journey discovery method |
| forge-execute | forge-* | C1, C4, fix loop max attempts |
| forge-team | forge-* | C1, C4, file ownership per validator |
| forge-benchmark | forge-* | C1, C4, trend tracking output |
| forge-install-rules | forge-* | C1, C4, target path `.claude/rules/` |

---

## Agent Benchmarks

5 agents. Each evaluated on role clarity, constraints, and protocol compliance.

### Evaluation Criteria

| # | Criterion | What to Check | 0 | 1 | 2 |
|---|-----------|---------------|---|---|---|
| A1 | Frontmatter: description | `description:` exists, 10-200 chars | Missing | Vague | Clear role summary |
| A2 | Frontmatter: capabilities | `capabilities:` array with 2+ entries | Missing | 1 entry | 2+ relevant entries |
| A3 | Identity section | Defines Role, Output, and Constraint explicitly | Missing | Partial | All three present |
| A4 | Read-only enforcement | Read-only agents (platform-detector) never reference Write/Edit | References write tools | Ambiguous | Explicit read-only |
| A5 | Evidence directory compliance | Writes to `e2e-evidence/` not custom paths | Wrong output path | Inconsistent | Always `e2e-evidence/` |
| A6 | Handoff protocol | Defines what it produces for the next agent in the chain | No handoff | Implicit | Explicit handoff section |
| A7 | No-mock enforcement | Never suggests mocks/tests as remediation | Suggests mocks | Silent | Explicit prohibition |
| A8 | Output format specified | Defines exact output structure (JSON schema, markdown template) | No format | Vague format | Exact template |
| A9 | Error/stop conditions | Defines when to stop or escalate | No stop conditions | Partial | Clear stop table |
| A10 | File ownership | Specifies which directories/files it owns exclusively | No ownership | Implicit | Explicit ownership table |
| A11 | Constraint testability | Constraints are specific enough to verify (not "be careful") | Vague platitudes | Some specific | All verifiable |
| A12 | Inter-agent references | References to other agents match `agents/*.md` names | Broken references | Untested | All verified |

### Per-Agent Matrix

| Criterion | platform-detector | evidence-capturer | verdict-writer | sweep-controller | validation-lead |
|-----------|:-:|:-:|:-:|:-:|:-:|
| A1 Description | -- | -- | -- | -- | -- |
| A2 Capabilities | -- | -- | -- | -- | -- |
| A3 Identity | -- | -- | -- | -- | -- |
| A4 Read-only | **MUST PASS** | N/A | N/A | N/A | N/A |
| A5 Evidence dir | N/A | **MUST PASS** | **MUST PASS** | **MUST PASS** | **MUST PASS** |
| A6 Handoff | JSON output | inventory file | report.md | sweep-report.md | unified report.md |
| A7 No-mock | -- | -- | **MUST PASS** | **MUST PASS** | -- |
| A8 Output format | JSON schema | file naming convention | verdict template | sweep report template | aggregated report |
| A9 Stop conditions | max 3 levels deep | N/A | N/A | 3-strike limit | all validators done |
| A10 File ownership | none (read-only) | `e2e-evidence/{journey}/` | `e2e-evidence/report.md` | `e2e-evidence/sweep-report.md` | `e2e-evidence/report.md`, `.vf/state/` |
| A11 Testability | -- | -- | -- | -- | -- |
| A12 Inter-agent refs | none | verdict-writer | none | none | platform-detector, evidence-capturer, verdict-writer |

**MUST PASS** = hard gate. Failure on these criteria blocks the agent from shipping.

---

## Baseline Scores

Initial benchmark run: **PENDING**

### Hook Scores

| Hook | Cases | Correctness | Format | Error Handling | Security | Total | Grade |
|------|-------|-------------|--------|----------------|----------|-------|-------|
| block-test-files | 15 | --/30 | --/30 | --/30 | --/30 | --/120 | -- |
| completion-claim-validator | 10 | --/20 | --/20 | --/20 | --/20 | --/80 | -- |
| evidence-gate-reminder | 10 | --/20 | --/20 | --/20 | --/20 | --/80 | -- |
| evidence-quality-check | 10 | --/20 | --/20 | --/20 | --/20 | --/80 | -- |
| mock-detection | 15 | --/30 | --/30 | --/30 | --/30 | --/120 | -- |
| validation-not-compilation | 10 | --/20 | --/20 | --/20 | --/20 | --/80 | -- |
| validation-state-tracker | 10 | --/20 | --/20 | --/20 | --/20 | --/80 | -- |

### Skill Scores (by category)

| Category | Skills | Criteria | Max Score | Actual | Grade |
|----------|--------|----------|-----------|--------|-------|
| Platform | 11 | 12 | 264 | -- | -- |
| Quality | 6 | 12 | 144 | -- | -- |
| Design | 4 | 12 | 96 | -- | -- |
| Analysis | 3 | 12 | 72 | -- | -- |
| Specialized | 6 | 12 | 144 | -- | -- |
| Operational | 5 | 12 | 120 | -- | -- |
| Forge | 5 | 12 | 120 | -- | -- |

### Command Scores

| Command | C1 | C2 | C3/C4 | C5 | C6 | C7 | C8 | C9 | C10 | C11 | C12 | Total | Grade |
|---------|----|----|-------|----|----|----|----|----|----|-----|-----|-------|-------|
| validate | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | --/24 | -- |
| *(14 more)* | | | | | | | | | | | | | |

### Agent Scores

| Agent | A1 | A2 | A3 | A4 | A5 | A6 | A7 | A8 | A9 | A10 | A11 | A12 | Total | Grade |
|-------|----|----|----|----|----|----|----|----|----|----|-----|-----|-------|-------|
| platform-detector | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | --/24 | -- |
| evidence-capturer | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | --/24 | -- |
| verdict-writer | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | --/24 | -- |
| sweep-controller | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | --/24 | -- |
| validation-lead | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | --/24 | -- |

### Grading Scale

| Grade | Score | Meaning |
|-------|-------|---------|
| A | 90-100% | Production ready |
| B | 80-89% | Minor issues, shippable |
| C | 70-79% | Needs attention before shipping |
| D | 60-69% | Significant gaps |
| F | <60% | Failing, must remediate |
