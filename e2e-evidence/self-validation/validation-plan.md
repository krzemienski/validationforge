# Validation Plan — ValidationForge Self-Validation
Generated: 2026-04-08
Platform: cli (confidence: high — no package.json framework, hooks + scripts + markdown inventory)
Scope: entire ValidationForge project (hooks, scripts, config, commands, agents, skills, rules)

## Rationale

ValidationForge is a no-mock validation platform. If VF cannot validate itself, it cannot credibly
validate anything else. This plan applies VF's own 7-phase methodology to VF's own codebase.
Every journey is verifiable by command-line invocation — no mocks, no stubs, no assumed evidence.

## Journey Inventory

| # | Journey | Priority | Dependencies | Steps | Evidence Types |
|---|---------|----------|--------------|-------|----------------|
| J1 | Hook Enforcement | HIGH | none | 3 | json, terminal |
| J2 | Configuration Validity | HIGH | none | 2 | json, terminal |
| J3 | Platform Detection | HIGH | none | 1 | terminal |
| J4 | Cross-Reference Integrity | MEDIUM | none | 4 | terminal |
| J5 | Install Script Executability | MEDIUM | none | 2 | terminal |
| J6 | Evidence Structure | LOW | none | 1 | terminal |

---

## Journey Details

### J1: Hook Enforcement

**Priority:** HIGH
**Dependencies:** none
**Purpose:** Verify that the block-test-files.js hook actively denies writes to test/mock/stub
filenames, and that mock-detection.js flags mock patterns in file content.

**PASS Criteria:**

1. `block-test-files.js` returns `permissionDecision: "deny"` when tool_input.file_path is a
   test file (e.g. `auth.test.js`, `user.spec.ts`, `mocks/api.js`) → json response with deny
2. `block-test-files.js` returns `permissionDecision: "allow"` when tool_input.file_path is a
   normal source file (e.g. `src/auth.js`, `lib/utils.ts`) → json response with allow
3. `mock-detection.js` outputs a warning containing "mock" when invoked with content containing
   `jest.mock(` or `sinon.stub(` → json response with behavior block

**Evidence Required:**
- `step-01-block-test-file.json` — exact JSON output from hook when fed a test filename
- `step-02-allow-normal-file.json` — exact JSON output from hook when fed a normal filename
- `step-03-mock-detection.json` — exact JSON output from mock-detection hook

**Execution order:** 1 → 2 → 3 (sequential)

---

### J2: Configuration Validity

**Priority:** HIGH
**Dependencies:** none
**Purpose:** Verify that all JSON configuration files are syntactically valid and contain their
required top-level keys. Invalid config can silently break VF enforcement.

**PASS Criteria:**

1. `config/strict.json`, `config/standard.json`, `config/permissive.json` all parse with
   `JSON.parse()` without error, and each contains an `enforcement_level` key → json results
2. `hooks/hooks.json` parses and contains a `hooks` object with `PreToolUse` and/or
   `PostToolUse` keys listing the registered hook scripts → json schema output

**Evidence Required:**
- `step-01-config-parse-results.json` — parse results for all 5 JSON config files (strict, standard,
  permissive, hooks.json, package.json) with key presence confirmation
- `step-02-hooks-schema.json` — hooks.json content confirming PreToolUse/PostToolUse structure

**Execution order:** 1 → 2 (sequential)

---

### J3: Platform Detection

**Priority:** HIGH
**Dependencies:** none
**Purpose:** Verify that detect-platform.sh correctly identifies VF's own repository as a
CLI-type project. VF has hooks + scripts + markdown but no web framework, no iOS project,
no API server — it should detect as "cli" or "generic".

**PASS Criteria:**

1. `bash ./scripts/detect-platform.sh .` outputs a valid platform string (one of:
   `ios`, `cli`, `api`, `web`, `fullstack`, `generic`) with exit code 0 → terminal output

**Evidence Required:**
- `step-01-detection-output.txt` — complete stdout from detect-platform.sh including any
  indicators reported and the final platform classification

**Execution order:** 1 (single step)

---

### J4: Cross-Reference Integrity

**Priority:** MEDIUM
**Dependencies:** none
**Purpose:** Verify that VF's internal cross-references are valid — commands that reference
agents, agents that reference skills, and CLAUDE.md inventory counts all match reality.
A broken cross-reference means documentation claims features that don't exist.

**PASS Criteria:**

1. All 40+ skill directories in `skills/` exist on disk and are non-empty → terminal inventory
2. All 15 command files in `commands/` exist on disk → terminal inventory
3. All 5 agent files in `agents/` exist on disk → terminal inventory
4. All 8 rule files in `rules/` exist on disk (or notes if rules directory absent) → terminal
   inventory
5. Key cross-references validated: `commands/validate.md` references `platform-detector` agent
   (agents/platform-detector.md exists), `evidence-capturer` agent (exists), `verdict-writer`
   agent (exists) → grep evidence

**Evidence Required:**
- `step-01-skills-inventory.txt` — `ls ./skills/` output with count
- `step-02-commands-inventory.txt` — `ls ./commands/*.md` output with count
- `step-03-agents-inventory.txt` — `ls ./agents/*.md` output with count
- `step-04-rules-inventory.txt` — rules directory inventory or absence note

**Execution order:** 1 → 2 → 3 → 4 (parallel-safe, sequential for clarity)

---

### J5: Install Script Executability

**Priority:** MEDIUM
**Dependencies:** none
**Purpose:** Verify that install.sh passes bash syntax checking and contains the expected
functional components (git clone, rules installation, config write). A broken install script
means VF cannot be set up by new users.

**PASS Criteria:**

1. `bash -n ./install.sh` exits with code 0 (no syntax errors) → terminal output
2. `install.sh` contains at least one `git clone` invocation → grep result
3. `scripts/detect-platform.sh` and `scripts/health-check.sh` both pass `bash -n` syntax
   check → terminal output

**Evidence Required:**
- `step-01-syntax-check.txt` — output of `bash -n` on install.sh and both scripts (exit 0
  confirms syntax validity)
- `step-02-function-presence.txt` — grep output showing git clone and key function lines in
  install.sh

**Execution order:** 1 → 2 (sequential)

---

### J6: Evidence Structure

**Priority:** LOW
**Dependencies:** none
**Purpose:** Verify that the VF repository itself follows VF's own evidence directory conventions.
VF mandates `e2e-evidence/` exists, uses journey-slug subdirectories, and includes inventory files.
VF should comply with its own rules.

**PASS Criteria:**

1. `e2e-evidence/` directory exists at repository root → directory check
2. At least one journey subdirectory exists under `e2e-evidence/` (e.g. `web-validation/`) →
   directory listing
3. `e2e-evidence/web-validation/VERDICT.md` exists and is non-empty → file check
4. `e2e-evidence/web-validation/evidence-inventory.txt` exists and is non-empty → file check

**Evidence Required:**
- `step-01-structure-inventory.txt` — `find ./e2e-evidence/ -type f` output showing all evidence
  files and confirming directory hierarchy

**Execution order:** 1 (single step)

---

## PASS/FAIL Decision Rules

- **PASS:** All criteria for a journey are met with direct evidence cited
- **FAIL:** Any criterion not met, or evidence is empty/fabricated
- **BLOCKED:** Preflight checks fail → stop, do not execute journeys
- **Max fix attempts per journey:** 3

## Evidence Directory

All evidence for this self-validation goes to: `e2e-evidence/self-validation/`

```
e2e-evidence/self-validation/
  validation-plan.md               ← this file
  evidence-inventory.txt           ← running log of all captured files
  preflight-hooks.txt              ← preflight: hook syntax check results
  preflight-scripts.txt            ← preflight: script syntax check results
  preflight-configs.txt            ← preflight: config parse results
  hook-enforcement/
    step-01-block-test-file.json
    step-02-allow-normal-file.json
    step-03-mock-detection.json
  configuration/
    step-01-config-parse-results.json
    step-02-hooks-schema.json
  platform-detection/
    step-01-detection-output.txt
  cross-references/
    step-01-skills-inventory.txt
    step-02-commands-inventory.txt
    step-03-agents-inventory.txt
    step-04-rules-inventory.txt
  install-script/
    step-01-syntax-check.txt
    step-02-function-presence.txt
  evidence-structure/
    step-01-structure-inventory.txt
  report.md                        ← final verdict (written after all evidence captured)
```

## Preflight Gates (Phase 2 — before any journey executes)

| Gate | Check | Command | Must Pass? |
|------|-------|---------|------------|
| PF-1 | All 7 hooks parse as valid Node.js | `node --check ./hooks/*.js` | YES (blocking) |
| PF-2 | All shell scripts pass bash -n | `bash -n ./scripts/detect-platform.sh` | YES (blocking) |
| PF-3 | All JSON configs parse | `node -e "JSON.parse(...)"` on each | YES (blocking) |

If any preflight gate fails, STOP. Fix the real system. Do not proceed to execute journeys.

## Execution Order

```
Phase 1 (Plan)      → This document
Phase 2 (Preflight) → PF-1, PF-2, PF-3 (all blocking)
Phase 3 (Execute)   → J1 Hook Enforcement
                     J2 Configuration Validity
                     J3 Platform Detection
                     J4 Cross-Reference Integrity
                     J5 Install Script Executability
                     J6 Evidence Structure
Phase 4 (Analyze)   → Review all evidence files
Phase 5 (Verdict)   → Write report.md with per-journey PASS/FAIL
Phase 6 (Ship)      → If any FAIL, fix and re-run (max 3 attempts)
Phase 7 (Docs)      → Case study in docs/case-studies/self-validation.md
```
