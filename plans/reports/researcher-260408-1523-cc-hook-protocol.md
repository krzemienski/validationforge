# CC Hook Protocol Compliance Audit

**Date:** 2026-04-08 | **Analyst:** researcher  
**Scope:** 7 ValidationForge hooks + patterns.ts duplication  
**Status:** CRITICAL PROTOCOL ISSUES IDENTIFIED

---

## Executive Summary

Of the 7 hooks, **3 have protocol violations** that contradict the Claude Code hook spec. The most critical issue: PostToolUse hooks output JSON to stdout, but per CC spec, PostToolUse feedback must go to stderr with exit 2 (stdout is not visible to Claude in PostToolUse context). Additionally, all hooks have hardcoded patterns that duplicate patterns.ts—the declared single source of truth. Error handling is generally robust but unevenly applied.

---

## Hook Protocol Compliance Table

| Hook | Type | Matcher | Protocol Status | Error Handling | Pattern Duplication | Exit Code Correctness |
|------|------|---------|-----------------|-----------------|--------------------|-----------------------|
| **block-test-files.js** | PreToolUse | Write\|Edit\|MultiEdit | ✅ COMPLIANT | ✅ Good (try/catch) | ❌ DUPLICATED (TEST_PATTERNS, ALLOWLIST) | ✅ Correct (exit 0 for deny output) |
| **evidence-gate-reminder.js** | PreToolUse | TaskUpdate | ✅ COMPLIANT | ✅ Good (try/catch) | ❌ NO DUP (but missing shared patterns) | ✅ Correct (exit 0 for context) |
| **completion-claim-validator.js** | PostToolUse | Bash | ❌ **PROTOCOL VIOLATION** | ⚠️ Missing fs import check | ❌ DUPLICATED (COMPLETION_PATTERNS) | ❌ WRONG (stdout JSON in PostToolUse) |
| **validation-not-compilation.js** | PostToolUse | Bash | ❌ **PROTOCOL VIOLATION** | ✅ Good (try/catch) | ❌ DUPLICATED (BUILD_PATTERNS) | ❌ WRONG (stdout JSON in PostToolUse) |
| **validation-state-tracker.js** | PostToolUse | Bash | ❌ **PROTOCOL VIOLATION** | ✅ Good (try/catch) | ❌ DUPLICATED (VALIDATION_PATTERNS) | ❌ WRONG (stdout JSON in PostToolUse) |
| **mock-detection.js** | PostToolUse | Edit\|Write\|MultiEdit | ❌ **PROTOCOL VIOLATION** | ✅ Good (try/catch) | ❌ DUPLICATED (MOCK_PATTERNS) | ❌ WRONG (stdout JSON in PostToolUse) |
| **evidence-quality-check.js** | PostToolUse | Edit\|Write\|MultiEdit | ❌ **PROTOCOL VIOLATION** | ✅ Good (try/catch) | ❌ NO DUP (custom logic) | ❌ WRONG (stdout JSON in PostToolUse) |

---

## Critical Issues (Must Fix Before Audit)

### 1. PostToolUse Protocol Violation (5 hooks: 80% of PostToolUse hooks)

**Affected:** completion-claim-validator.js, validation-not-compilation.js, validation-state-tracker.js, mock-detection.js, evidence-quality-check.js

**Problem:** All 5 output JSON to stdout. Per Claude Code hook spec (from hooks-reference.md), PostToolUse feedback should:
- Write message to **stderr** (not stdout)
- Exit with code **2** (not 0)
- NOT output JSON hookSpecificOutput in PostToolUse context

**Current Pattern (WRONG):**
```javascript
process.stdout.write(JSON.stringify({ hookSpecificOutput: { ... } }));
process.exit(0);  // Missing: should be exit 2
```

**Correct Pattern (per CC spec):**
```javascript
process.stderr.write('Feedback message here\n');
process.exit(2);  // Signal feedback without blocking
// Or just: process.exit(0); for silent pass-through
```

**Impact:** PostToolUse feedback is silently lost to Claude. Hooks fire but reminders never reach user.

**Recommendation:** PostToolUse hooks should either:
- **Silent path:** Exit 0 with no output (feedback only in next user message)
- **Feedback path:** Stderr + exit 2 (visible in transcript as hook note)

Currently mixing both patterns inconsistently.

---

### 2. Pattern Duplication (5 hooks + patterns.ts)

**Issue:** block-test-files.js, completion-claim-validator.js, validation-not-compilation.js, validation-state-tracker.js, and mock-detection.js each define local arrays that are **character-identical** to patterns.ts exports.

**Hardcoded Arrays:** TEST_PATTERNS, ALLOWLIST, COMPLETION_PATTERNS, BUILD_PATTERNS, MOCK_PATTERNS, VALIDATION_COMMAND_PATTERNS

**Current State:**
- patterns.ts declares these as "single source of truth" (line 1-2)
- Each hook re-hardcodes the exact arrays
- No require() calls to patterns.ts from hooks
- When a pattern needs updating, 6 files must change

**Drift Risk:** If someone updates patterns.ts but forgets one hook, detection becomes inconsistent. Already happened at least once (patterns.ts has BUILD_PATTERNS at lines 52-63 which is used by validation-not-compilation.js but hardcoded identically).

**Recommendation:** Hooks must require/import from patterns.ts, not hardcode.

---

### 3. Error Handling Inconsistency

**Block-test-files.js (Line 27):** Missing safety check before requiring 'fs':
```javascript
const hasEvidence = fs.existsSync(EVIDENCE_DIR) &&
  fs.readdirSync(EVIDENCE_DIR).length > 0;
```
If 'fs' module fails to load (rare but possible), hook crashes. Should wrap in try/catch or require at top.

**All others:** Properly wrapped in try/catch at line 74-78 level. ✅

---

## Medium Issues (Address in Next Audit Cycle)

### 4. hooks.json Variable Interpolation

**Line 10, 19, 30, 34, 38, 47, 51:** All use `${CLAUDE_PLUGIN_ROOT}` variable.

**Question:** Does this variable exist in Claude Code hook runtime? Needs verification:
- [ ] Test with actual hook invocation to confirm variable interpolation works
- [ ] If it doesn't, paths are broken (hooks won't execute)
- [ ] Fallback: use absolute paths or relative-to-hooks-dir paths

**Current assumption:** Works correctly, but untested in this audit.

---

### 5. Exit Code Semantics Mismatch

**block-test-files.js (Line 69):** Outputs JSON to stdout AND exits 0. This works for PreToolUse (Claude sees stdout), but exit code 0 + "deny" is semantically confusing.

Should be:
- Exit 0 = silent allow (no output needed)
- Exit 2 = block + deny (per spec, though this hook uses JSON instead)

Current code works by accident (PreToolUse does see stdout), but mixes two patterns. Not broken, but unclear.

---

## Pattern Compliance Matrix

| Pattern Array | Declared in patterns.ts | Hardcoded in Hooks | Match Status |
|---------------|------------------------|--------------------|--------------|
| TEST_PATTERNS | ✅ Lines 4-20 | ✅ block-test-files.js:10-26 | 🔴 IDENTICAL (16 patterns each) |
| ALLOWLIST | ✅ Lines 22-27 | ✅ block-test-files.js:28-33 | 🔴 IDENTICAL (4 patterns each) |
| MOCK_PATTERNS | ✅ Lines 29-50 | ✅ mock-detection.js:5-26 | 🔴 IDENTICAL (20 patterns each) |
| BUILD_PATTERNS | ✅ Lines 52-63 | ✅ validation-not-compilation.js:5-16 | 🔴 IDENTICAL (10 patterns each) |
| COMPLETION_PATTERNS | ✅ Lines 65-70 | ✅ completion-claim-validator.js:5-10 | 🔴 IDENTICAL (4 patterns each) |
| VALIDATION_PATTERNS | ✅ Lines 72-81 (VALIDATION_COMMAND_PATTERNS) | ✅ validation-state-tracker.js:14-23 | 🔴 IDENTICAL (8 patterns each) |

**Total duplication:** 62 regex patterns hardcoded twice.

---

## Prioritized Audit Action Items

### CRITICAL (Week 1)
1. **Fix PostToolUse protocol** — All 5 PostToolUse hooks must use stderr + exit 2 (or silent exit 0). Audit cannot pass until PostToolUse feedback path is spec-compliant.
2. **Verify ${CLAUDE_PLUGIN_ROOT} interpolation** — Run hooks.json through CC parser to confirm variable substitution works. If broken, fix path references.

### HIGH (Week 2)
3. **Eliminate pattern duplication** — Create patterns.js in hooks/ directory that re-exports from patterns.ts (or use a build step). All hooks must require() from single source.
4. **Fix completion-claim-validator.js fs import** — Add fs import error handling or move fs require to top of hook.
5. **Validate exit code semantics** — Audit spec says exit 2 for denials. block-test-files.js uses JSON + exit 0. Document why and either fix or document exception.

### MEDIUM (Week 3)
6. **Test all hooks end-to-end** — Actual hook invocation (not code review) to confirm:
   - PreToolUse hooks correctly block writes
   - PostToolUse feedback reaches user
   - Pattern detection works on real code/commands
   - Error handling doesn't crash harness

---

## Unresolved Questions

1. **Does ${CLAUDE_PLUGIN_ROOT} variable exist at hook runtime?** Need to test hooks.json with actual CC execution.
2. **Can patterns.ts be imported in Node.js hook context?** patterns.ts is TypeScript with exports. Hooks are Node.js scripts. Need verification that require/import works.
3. **Should PostToolUse feedback be stderr or silent?** Current spec says either, but inconsistent implementation suggests confusion. Audit plan must clarify intent per feature (informational reminders → silent; true violations → stderr).
4. **Is e2e-evidence/ allowlist path correct in block-test-files.js?** ALLOWLIST includes `/e2e-evidence` but path matching is regex `.test()`. Will this catch both `e2e-evidence/file.txt` and `path/to/e2e-evidence/file.txt`? Need test case.

---

## Recommendations for Audit Plan

The new audit plan must include a **Hook Validation Gate** phase that:

1. **Protocol verification:** Each hook runs in isolation against test JSON inputs. Verify:
   - Correct exit code for hook type (0 for silent, 2 for feedback, 0 with JSON for PreToolUse)
   - Correct output channel (stderr for feedback, stdout for PreToolUse JSON, nothing for silent)
   - No hook crashes on malformed input

2. **Pattern accuracy:** Compare each hook's hardcoded patterns against patterns.ts byte-for-byte. Flag any drift.

3. **Integration test:** Run hooks.json through CC hook parser (if available) to confirm `${CLAUDE_PLUGIN_ROOT}` resolves correctly.

4. **Functional coverage:** For each hook, provide a test case (file write, bash output, task update) that should trigger it. Verify hook fires and produces expected feedback.

**Success criteria:** All 7 hooks pass, no protocol violations, patterns synchronized, exit codes documented.

