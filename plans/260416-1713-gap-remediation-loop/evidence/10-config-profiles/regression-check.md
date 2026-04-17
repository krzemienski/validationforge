# P02-equivalent regression check under VF_PROFILE=standard

Note: block-test-files uses permissionDecision:deny via stdout (PreToolUse CC protocol).
ALLOWLIST excludes paths containing 'validationforge/' — test uses external project path.

| Hook | Expected | exit | Result |
|------|----------|------|--------|
| block-test-files (/myproject/src/auth.test.ts) | exit=0 + stdout deny | 0 | PASS |
| mock-detection (jest.mock code) | exit=2 (hard block) | 2 | PASS |
| evidence-quality-check (empty e2e-evidence file) | exit=2 (hard block) | 2 | PASS |

## stdout (block-test-files — permissionDecision deny payload):
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"BLOCKED [standard]: \"/Users/nick/Desktop/myproject/src/auth.test.ts\" matches a test/mock/stub file pattern.\nValidationForge Iron Rule: Never create test files, mock files, or stub files.\nInstead: Build and run the real system. Validate through actual user interfaces.\nRun /validate to start the correct validation workflow."}}
## stderr snippets
block-test-files:

mock-detection:
[ValidationForge] mock-detection [standard]: Mock/test pattern detected in code being written.
ValidationForge Iron Rule: Never create mocks, stubs, or test harnesses.
Fix the real system instead. Run /validate for proper validation.

evidence-quality-check:
[ValidationForge] evidence-quality-check [standard]: Empty evidence file detected.
0-byte files are INVALID evidence. Capture real content (screenshots, logs, API responses).
