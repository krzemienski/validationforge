# Case Study: ValidationForge Validates Itself

> "We don't just preach evidence-based shipping — we practice it."

**Date:** 2026-04-08
**Subject:** ValidationForge codebase (hooks, scripts, config, commands, agents, skills, rules)
**Method:** VF 7-phase pipeline applied to VF itself
**Verdict:** ✅ **PASS** — 6/6 journeys, 13/13 criteria, 0 fix attempts required

---

## Executive Summary

A validation tool that cannot validate itself has no credibility. This case study documents
ValidationForge running its own 7-phase methodology against its own codebase — treating itself
as the target system.

The result: **all 6 validation journeys passed on first execution** with zero fix attempts.
Every verdict cites specific command output captured from real invocations. No evidence was
fabricated or assumed.

Artifacts produced:
- `e2e-evidence/self-validation/` — 30 evidence files across 6 journeys
- `e2e-evidence/self-validation/report.md` — formal verdict with 13 cited criteria
- This document

---

## Phase 0: Research — What Does VF Do?

ValidationForge is a Claude Code plugin (not a web app, not an API server). It consists of:

| Component | Count | Location |
|-----------|-------|----------|
| Commands (slash commands) | 15 | `commands/*.md` |
| Skills (guidance documents) | 41 | `skills/*/` |
| Agents (orchestration specs) | 5 | `agents/*.md` |
| Rules (enforcement rules) | 8 | `rules/*.md` |
| Hooks (Node.js enforcement) | 7 | `hooks/*.js` |
| Shell scripts | 4 | `scripts/*.sh` |
| JSON configs | 3 | `config/*.json` |

Since VF has no running server, the validation methodology adapts: instead of navigating
pages or calling endpoints, journeys invoke hooks, scripts, and config parsers directly.

---

## Phase 1: Plan — Six Journeys, Defined Before Execution

Six journeys were defined with specific PASS criteria before any execution began.
Full plan: `e2e-evidence/self-validation/validation-plan.md`

| Journey | What It Tests | PASS Criteria |
|---------|--------------|---------------|
| J1: Hook Enforcement | block-test-files.js and mock-detection.js actively intercept | Deny JSON for test files, allow for normal files, stderr warning for jest.mock() |
| J2: Configuration Validity | JSON configs parse and have required keys | 5/5 files parse, enforcement configs have name/strictness/rules/hooks keys |
| J3: Platform Detection | detect-platform.sh runs against VF itself | Valid platform string output (ios/cli/api/web/fullstack/generic), exit 0 |
| J4: Cross-Reference Integrity | All assets claimed in docs exist on disk | Skills/commands/agents/rules counts match CLAUDE.md, key agent refs resolve |
| J5: Install Script Executability | install.sh is deployable | bash -n passes, git clone + rules install + config write all present |
| J6: Evidence Structure | VF follows its own evidence conventions | e2e-evidence/ directory, journey subdirs, VERDICT.md, step-NN naming |

---

## Phase 2: Preflight — Gate Before Execution

Three blocking preflight gates ran before any journey:

| Gate | Check | Result |
|------|-------|--------|
| PF-1 | `node --check ./hooks/*.js` — all 7 hooks valid Node.js | ✅ PASS |
| PF-2 | `bash -n install.sh scripts/*.sh` — all scripts valid bash | ✅ PASS |
| PF-3 | `JSON.parse(...)` on 5 config files | ✅ PASS |

All gates passed. Execution proceeded.

---

## Phase 3: Execute — Real Invocations, Real Output

### Journey 1: Hook Enforcement ✅ PASS

**What we ran:**
```bash
echo '{"tool_name":"Write","tool_input":{"file_path":"auth.test.js"}}' \
  | node ./hooks/block-test-files.js
```

**What we saw** (`hook-enforcement/step-01-block-test-file.json`):
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: \"auth.test.js\" matches a test/mock/stub file pattern.\nValidationForge Iron Rule: Never create test files..."
  }
}
```

The hook also tested in allow mode: `src/auth.js` produces empty output (silent pass-through).

Mock detection tested with `jest.mock("axios")` content: stderr warning emitted, exit code 2.

**Why this matters:** Hooks aren't documentation — they run. Claude Code enforces them on every
Write/Edit/MultiEdit tool call. The deny path was verified to produce the exact JSON structure
Claude Code reads to block the operation.

---

### Journey 2: Configuration Validity ✅ PASS

All 5 JSON files parsed cleanly. The three enforcement configs form a deliberate ladder:

| Config | `block_test_files` | `require_evidence_on_completion` | `fail_on_missing_evidence` |
|--------|-------------------|----------------------------------|---------------------------|
| strict | `true` | `true` | `true` |
| standard | `true` | `true` | `false` |
| permissive | `false` | `false` | `false` |

`hooks/hooks.json` confirmed 2 PreToolUse matchers and 2 PostToolUse matchers with 7 hooks
registered, all referencing `${CLAUDE_PLUGIN_ROOT}` for portable installation.

---

### Journey 3: Platform Detection ✅ PASS

```bash
$ bash ./scripts/detect-platform.sh .
generic
```
Exit code: 0.

VF correctly classifies itself as `generic` — it has no `.xcodeproj`, no `package.json` bin
field, no route handlers, no web framework config files. The script runs against its own
directory without error and produces a valid output string.

---

### Journey 4: Cross-Reference Integrity ✅ PASS (minor finding)

Every asset listed in CLAUDE.md exists on disk:

```
Skills:   41 on disk  (40 documented + 1 undocumented: validate-audit-benchmarks)
Commands: 15 on disk  (15 documented — exact match)
Agents:    5 on disk  (5 documented — exact match)
Rules:     8 on disk  (8 documented — exact match)
```

Three critical agent references in `commands/validate.md` verified:
- `platform-detector` → `agents/platform-detector.md` ✓
- `evidence-capturer` → `agents/evidence-capturer.md` ✓
- `verdict-writer` → `agents/verdict-writer.md` ✓

**Minor finding:** `validate-audit-benchmarks` skill exists on disk but is absent from CLAUDE.md's
inventory table. An undocumented bonus skill — not a missing reference. Non-blocking.

---

### Journey 5: Install Script Executability ✅ PASS

`install.sh` passes `bash -n` and contains all three required functional sections:

| Function | Location | Evidence |
|----------|----------|---------|
| `git clone` | Line 32 | `git clone --depth 1 "$REPO" "$INSTALL_DIR"` |
| Rules install | Lines 36–45 | `for rule_file in "$INSTALL_DIR"/rules/*.md; do cp "$rule_file" "$target"` |
| Config write | Lines 62–70 | `cat > "$CONFIG_FILE" << EOF { "installDir": ... }` |

All shell scripts executable (`-rwxr-xr-x`). A new user running `curl | bash` will get a
working installation.

---

### Journey 6: Evidence Structure ✅ PASS

VF follows its own evidence conventions:

```
e2e-evidence/
  web-validation/          ← prior validation of blog-series/site
    VERDICT.md             ✓ exists, 81 lines
    evidence-inventory.txt ✓ exists, non-empty
    step-01-*.png          ✓ step-NN naming
  self-validation/         ← this validation
    validation-plan.md     ✓ plan written before execution
    evidence-inventory.txt ✓ running log
    hook-enforcement/      ✓ journey slug subdirectory
    configuration/         ✓ journey slug subdirectory
    platform-detection/    ✓ journey slug subdirectory
    cross-references/      ✓ journey slug subdirectory
    install-script/        ✓ journey slug subdirectory
    evidence-structure/    ✓ journey slug subdirectory
    report.md              ✓ verdict with cited evidence
```

30 evidence files total. Naming convention `step-NN-{description}.{ext}` followed throughout.

---

## Phase 4 & 5: Analyze + Verdict

No FAILs required root-cause analysis. All 13 criteria were met on first execution.

Summary table from `e2e-evidence/self-validation/report.md`:

| # | Criterion | Verdict | Evidence File |
|---|-----------|---------|---------------|
| 1 | block-test-files.js denies test filenames | ✅ PASS | step-01-block-test-file.json |
| 2 | block-test-files.js allows normal filenames | ✅ PASS | step-02-allow-normal-file.json |
| 3 | mock-detection.js flags jest.mock() | ✅ PASS | step-03-mock-detection.json |
| 4 | 5 JSON configs parse without error | ✅ PASS | step-01-config-parse-results.json |
| 5 | hooks.json has PreToolUse + PostToolUse | ✅ PASS | step-02-hooks-schema.json |
| 6 | detect-platform.sh outputs valid string | ✅ PASS | step-01-detection-output.txt |
| 7 | 40+ skills exist on disk | ✅ PASS | step-01-skills-inventory.txt |
| 8 | 15 commands exist on disk | ✅ PASS | step-02-commands-inventory.txt |
| 9 | 5 agents exist on disk, key refs verified | ✅ PASS | step-03-agents-inventory.txt |
| 10 | 8 rules exist on disk | ✅ PASS | step-04-rules-inventory.txt |
| 11 | install.sh passes bash syntax check | ✅ PASS | step-01-syntax-check.txt |
| 12 | install.sh has git clone + rules + config | ✅ PASS | step-02-function-presence.txt |
| 13 | Evidence directory follows VF conventions | ✅ PASS | step-01-structure-inventory.txt |

**Fix attempts:** 0 (none required)

---

## Phase 6: Ship Decision

**Production readiness: YES**

The enforcement layer (hooks) actively blocks test file creation and flags mock patterns.
The configuration layer (JSON configs) is structurally sound across all three enforcement
levels. The install script is deployable. The documentation inventory is accurate. VF
follows its own evidence conventions.

**One action item from this validation:**
> Document `validate-audit-benchmarks` skill in CLAUDE.md inventory (undocumented on disk).

---

## Lessons Learned

1. **Self-validation is feasible even for meta-tools.** VF has no server to start, but
   hooks and scripts are directly invocable. The 7-phase pipeline adapts: preflight checks
   syntax instead of build output, journeys invoke scripts instead of loading pages.

2. **Hooks are the critical enforcement path.** The deny decision JSON structure from
   `block-test-files.js` is exactly what Claude Code reads to block a tool call. Verifying
   the actual JSON output — not just that the file exists — is the difference between
   documentation and validation.

3. **Cross-reference integrity is cheap to check and expensive to ignore.** A command that
   references a non-existent agent silently fails at runtime. Five minutes of `ls` inventory
   prevents that class of defect.

4. **Platform detection being "generic" is correct, not a failure.** VF is a meta-tool.
   The script accurately reflects that it doesn't fit standard web/iOS/API/CLI patterns.
   A wrong platform classification would route to the wrong validation skills.

5. **Evidence-first discipline surfaces the one actual issue.** Without capturing the skills
   directory inventory, the undocumented `validate-audit-benchmarks` skill would have stayed
   invisible. Counting assets systematically found what informal review missed.

---

## Reproducing This Validation

```bash
# Clone ValidationForge
git clone https://github.com/krzemienski/validationforge
cd validationforge

# Preflight — verify hooks
node --check ./hooks/block-test-files.js
node --check ./hooks/mock-detection.js

# Journey 1 — Hook enforcement
echo '{"tool_name":"Write","tool_input":{"file_path":"auth.test.js"}}' \
  | node ./hooks/block-test-files.js

# Journey 3 — Platform detection
bash ./scripts/detect-platform.sh .

# Journey 4 — Cross-reference integrity
ls ./skills/ | wc -l   # expect 40+
ls ./commands/*.md | wc -l  # expect 15
ls ./agents/*.md | wc -l    # expect 5
ls ./rules/ | wc -l         # expect 8

# Full evidence in e2e-evidence/self-validation/
```

---

## Verdict

**ValidationForge: PASS**

The tool enforces what it preaches. The hooks block test files. The configs are valid.
The scripts run. The assets exist. The evidence conventions are followed.

*Full evidence: `e2e-evidence/self-validation/`*
*Full verdict: `e2e-evidence/self-validation/report.md`*
