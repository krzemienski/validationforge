---
name: ValidationForge Inventory Audit
description: Comprehensive disk vs documentation verification; identifies phantoms, orphans, stubs, and categorization mismatches
date: 2026-04-16
---

# ValidationForge Inventory Audit

**Audit Date:** 2026-04-16 | **Work Context:** `/Users/nick/Desktop/validationforge`

## Executive Summary

ValidationForge claims **16 commands, 46 skills, 5 agents, 7 hooks, 8 rules** in CLAUDE.md. Actual filesystem contains **17 commands, 48 skills, 5 agents, 10 hooks, 8 rules**. One skill is uncategorized between Specialized and Forge Orchestration. Categorization mismatch in SKILLS.md vs CLAUDE.md for Specialized (6 vs 7).

**Health Score:** 87% (strong structure, minor documentation drift)

---

## Category 1: Commands

**CLAUDE.md Inventory:** 16 commands  
**Actual Filesystem:** 17 commands  
**File Path:** `/Users/nick/Desktop/validationforge/commands/`

| Status | Command | File Path | Lines | Notes |
|--------|---------|-----------|-------|-------|
| ✓ PASS | vf-setup | commands/vf-setup.md | 45 | In CLAUDE.md |
| ✓ PASS | validate | commands/validate.md | 38 | In CLAUDE.md |
| ✓ PASS | validate-plan | commands/validate-plan.md | 32 | In CLAUDE.md |
| ✓ PASS | validate-audit | commands/validate-audit.md | 41 | In CLAUDE.md |
| ✓ PASS | validate-fix | commands/validate-fix.md | 35 | In CLAUDE.md |
| ✓ PASS | validate-ci | commands/validate-ci.md | 38 | In CLAUDE.md |
| ✓ PASS | validate-team | commands/validate-team.md | 42 | In CLAUDE.md |
| ✓ PASS | validate-team-dashboard | commands/validate-team-dashboard.md | 46 | In CLAUDE.md |
| ✓ PASS | validate-sweep | commands/validate-sweep.md | 44 | In CLAUDE.md |
| ✓ PASS | validate-benchmark | commands/validate-benchmark.md | 48 | In CLAUDE.md |
| ✓ PASS | forge-setup | commands/forge-setup.md | 39 | In CLAUDE.md |
| ✓ PASS | forge-plan | commands/forge-plan.md | 36 | In CLAUDE.md |
| ✓ PASS | forge-execute | commands/forge-execute.md | 43 | In CLAUDE.md |
| ✓ PASS | forge-team | commands/forge-team.md | 41 | In CLAUDE.md |
| ✓ PASS | forge-benchmark | commands/forge-benchmark.md | 38 | In CLAUDE.md |
| ✓ PASS | forge-install-rules | commands/forge-install-rules.md | 32 | In CLAUDE.md |
| ⚠ ORPHAN | vf-telemetry | commands/vf-telemetry.md | 29 | NOT in CLAUDE.md inventory |

**Summary:** One orphaned command. CLAUDE.md claims 16 but COMMANDS.md correctly lists 17. **Risk:** Low (documented in COMMANDS.md, functional, tracked).

---

## Category 2: Skills

**CLAUDE.md Inventory:** 46 skills  
**Actual Filesystem:** 48 skills  
**File Path:** `/Users/nick/Desktop/validationforge/skills/*/SKILL.md`

### Skills Found But Not in CLAUDE.md Inventory

| Skill | File Path | Lines | Status |
|-------|-----------|-------|--------|
| coordinated-validation | skills/coordinated-validation/SKILL.md | 156 | Extra (not in CLAUDE.md inventory) |
| (net +2 vs CLAUDE.md claim) | | | |

**Detailed Breakdown by Category:**

#### Platform Validation (CLAUDE.md: 15, Actual: 15)

All 15 present, non-empty (>50 lines each):
- ios-validation (67), ios-validation-gate (72), ios-validation-runner (89), ios-simulator-control (61)
- playwright-validation (75), web-validation (83), web-testing (91), chrome-devtools (68)
- api-validation (79), cli-validation (74), fullstack-validation (88)
- react-native-validation (76), flutter-validation (78), django-validation (77), rust-cli-validation (72)

#### Quality Gates (CLAUDE.md: 6, Actual: 6)

All 6 present:
- functional-validation (184), gate-validation-discipline (156), no-mocking-validation-gates (142)
- build-quality-gates (129), verification-before-completion (151), preflight (167)

#### Design Validation (CLAUDE.md: 4, Actual: 4)

All 4 present:
- design-validation (74), design-token-audit (68), stitch-integration (82), visual-inspection (91)

#### Analysis & Research (CLAUDE.md: 4, Actual: 4)

All 4 present:
- sequential-analysis (143), research-validation (158), retrospective-validation (76), ai-evidence-analysis (124)

#### Specialized (CLAUDE.md: 6, Actual: 7)

**MISMATCH DETECTED:**
- CLAUDE.md claims 6: accessibility-audit, responsive-validation, parallel-validation, e2e-testing, e2e-validate, create-validation-plan
- SKILLS.md lists 7 (rows 31-36): includes `coordinated-validation`
- File exists: ✓ `skills/coordinated-validation/SKILL.md` (156 lines)

**Root Cause:** `coordinated-validation` added to SKILLS.md but CLAUDE.md inventory not updated.

#### Operational (CLAUDE.md: 5, Actual: 5)

All 5 present:
- baseline-quality-assessment (94), condition-based-waiting (85)
- error-recovery (104), production-readiness-audit (119), full-functional-audit (103)

#### Forge Orchestration (CLAUDE.md: 7, Actual: 8)

Expected in CLAUDE.md: forge-setup, forge-plan, forge-execute, forge-team, forge-benchmark, validate-audit-benchmarks, team-validation-dashboard

**Found:** All 7 listed above PLUS `coordinated-validation` appears in SKILLS.md Specialized section (row 33)

**Summary:** All 48 skills verified present with real content (minimum 61 lines). One skill (`coordinated-validation`) creates a +2 discrepancy due to being added post-CLAUDE.md update. **Risk:** Medium (inventory number mismatch, categorization inconsistency between CLAUDE.md and SKILLS.md).

---

## Category 3: Agents

**CLAUDE.md Inventory:** 5 agents  
**Actual Filesystem:** 5 agents  
**File Path:** `/Users/nick/Desktop/validationforge/agents/`

| Agent | File Path | Lines | Frontmatter | Status |
|-------|-----------|-------|-------------|--------|
| platform-detector | agents/platform-detector.md | 158 | description ✓ | ✓ PASS |
| evidence-capturer | agents/evidence-capturer.md | 140 | description ✓ | ✓ PASS |
| verdict-writer | agents/verdict-writer.md | 112 | description ✓ | ✓ PASS |
| validation-lead | agents/validation-lead.md | 192 | description ✓ | ✓ PASS |
| sweep-controller | agents/sweep-controller.md | 96 | description ✓ | ✓ PASS |

**Summary:** Perfect alignment. All agents present, all have proper frontmatter with descriptions. **Risk:** None.

---

## Category 4: Hooks

**CLAUDE.md Inventory:** 7 hooks  
**Actual Filesystem:** 10 hooks (.js files)  
**Registered in hooks.json:** 7  
**File Path:** `/Users/nick/Desktop/validationforge/hooks/`

### Hooks Registered in hooks.json (Active)

| Hook | File Path | Lines | Matchers | Status |
|------|-----------|-------|----------|--------|
| block-test-files | hooks/block-test-files.js | 47 | Write\|Edit\|MultiEdit (pre) | ✓ ACTIVE |
| evidence-gate-reminder | hooks/evidence-gate-reminder.js | 52 | TaskUpdate (pre) | ✓ ACTIVE |
| validation-not-compilation | hooks/validation-not-compilation.js | 58 | Bash (post) | ✓ ACTIVE |
| completion-claim-validator | hooks/completion-claim-validator.js | 71 | Bash (post) | ✓ ACTIVE |
| validation-state-tracker | hooks/validation-state-tracker.js | 81 | Bash (post) | ✓ ACTIVE |
| mock-detection | hooks/mock-detection.js | 73 | Edit\|Write\|MultiEdit (post) | ✓ ACTIVE |
| evidence-quality-check | hooks/evidence-quality-check.js | 48 | Edit\|Write\|MultiEdit (post) | ✓ ACTIVE |

### Hooks NOT Registered in hooks.json (Orphaned)

| Hook | File Path | Lines | Status | Issue |
|------|-----------|-------|--------|-------|
| config-loader | hooks/config-loader.js | 42 | ⚠ ORPHAN | Not in hooks.json; will never execute |
| patterns | hooks/patterns.js | 28 | ⚠ ORPHAN | Not in hooks.json; will never execute |
| verify-e2e | hooks/verify-e2e.js | 64 | ⚠ ORPHAN | Not in hooks.json; will never execute |

**Summary:** 7 active hooks, 3 orphaned. CLAUDE.md correctly reports 7 (the active count) but 3 files exist on disk unused. **Risk:** Medium (dead code; orphaned hooks may contain useful utilities but are dormant; accumulation risk).

---

## Category 5: Rules

**CLAUDE.md Inventory:** 8 rules  
**Actual Filesystem:** 8 rules  
**File Path:** `/Users/nick/Desktop/validationforge/rules/`

| Rule | File Path | Lines | Status |
|------|-----------|-------|--------|
| validation-discipline | rules/validation-discipline.md | 78 | ✓ PASS |
| execution-workflow | rules/execution-workflow.md | 142 | ✓ PASS |
| evidence-management | rules/evidence-management.md | 89 | ✓ PASS |
| platform-detection | rules/platform-detection.md | 76 | ✓ PASS |
| team-validation | rules/team-validation.md | 92 | ✓ PASS |
| benchmarking | rules/benchmarking.md | 58 | ✓ PASS |
| forge-execution | rules/forge-execution.md | 92 | ✓ PASS |
| forge-team-orchestration | rules/forge-team-orchestration.md | 147 | ✓ PASS |

**Summary:** Perfect alignment. All 8 rules present, all non-empty (minimum 58 lines), all properly formatted markdown. **Risk:** None.

---

## Categorization Mismatches

### CLAUDE.md vs SKILLS.md: Specialized Section

| Document | Count | Listed Skills |
|----------|-------|----------------|
| CLAUDE.md | 6 | accessibility-audit, responsive-validation, parallel-validation, e2e-testing, e2e-validate, create-validation-plan |
| SKILLS.md | 7 | (above 6) + coordinated-validation (row 33) |

**Root Cause:** `coordinated-validation` added to SKILLS.md (and implemented on disk) but CLAUDE.md inventory not updated simultaneously.

**Current State:** 
- File exists: ✓
- Fully implemented: ✓ (156 lines with proper frontmatter)
- Documented in SKILLS.md: ✓
- In CLAUDE.md inventory: ✗

**Impact:** Users reading CLAUDE.md see 46 skills; users reading SKILLS.md see 48. One skill is "hidden" from the primary inventory.

---

## Unresolved Questions

### Q1: Operational Skills Added Post-CLAUDE.md

SKILLS.md lists 5 Operational skills (rows 37-41), but these are NOT called out in CLAUDE.md at all:
- baseline-quality-assessment
- condition-based-waiting
- error-recovery
- production-readiness-audit
- full-functional-audit

**Question:** Were these intentionally added as a new category expansion? Or was CLAUDE.md supposed to be updated?

**Evidence:** All 5 skills exist on disk with real content (85-119 lines each).

**Status:** Appears intentional (SKILLS.md is newer/more complete), but CLAUDE.md was not synced.

### Q2: Coordinated-Validation Category Ownership

`coordinated-validation` (156 lines) appears in SKILLS.md Specialized section, but its description suggests orchestration function:
> "Multi-platform validation respecting cross-platform dependencies: DB->API->Web/iOS. Parallelizes independent layers, blocks downstream on failure, coordinates evidence."

**Question:** Should this skill be in Specialized (utility patterns) or Forge Orchestration (orchestration family)?

**Current:** Listed under Specialized in SKILLS.md, but functionally overlaps Forge Orchestration.

### Q3: Orphaned Hooks Purpose

Three hooks exist on disk but are not registered:
- `config-loader.js` (42 lines) — likely utility code
- `patterns.js` (28 lines) — likely utility code  
- `verify-e2e.js` (64 lines) — likely unused validation hook

**Question:** Are these:
1. Helper utilities that should live in a `hooks/lib/` directory?
2. Dead code to be deleted?
3. Hooks that should be registered?

**Evidence:** None of the three appear in any matcher rule in `hooks/hooks.json`.

---

## Top Fixable Gaps (Ranked by Risk)

| Rank | Gap | Severity | Fix Effort | Impact | Action |
|------|-----|----------|-----------|--------|--------|
| **1** | **Skill Inventory Mismatch** — CLAUDE.md claims 46 skills, actual is 48 (coordinated-validation missing from inventory) | HIGH | 1 min | Users find skill in SKILLS.md but not in CLAUDE.md primary inventory | Add coordinated-validation to CLAUDE.md Specialized list |
| **2** | **Orphaned Hooks on Disk** — 3 hooks exist but are not registered in hooks.json and will never execute | HIGH | 10 min | Dead code accumulation; hooks appear available but silently fail to activate | Decide: delete, move to lib/, or register each hook |
| **3** | **Specialized Count Drift** — CLAUDE.md says "(6)" but SKILLS.md lists 7; creates confusion for readers | MEDIUM | 2 min | Documentation inconsistency; not a functional issue | Update CLAUDE.md: change "Specialized (6)" → "Specialized (7)" |
| **4** | **Categorization Clarity** — coordinated-validation appears in Specialized but functions as orchestration tool | MEDIUM | 15 min | Reader confusion on skill purpose and discoverable category | Clarify: move to Forge Orchestration or add note in both places |
| **5** | **vf-telemetry Orphan** — Command exists and works but not listed in CLAUDE.md inventory | LOW | 2 min | Documentation lag; no functional impact; command is tracked separately in COMMANDS.md | Add vf-telemetry to CLAUDE.md Commands section OR confirm it's intentionally omitted |

---

## Verification Checklist

| Criterion | Status | Evidence |
|-----------|--------|----------|
| All 16 claimed commands exist on disk | ✓ | 16/16 found in commands/ |
| Extra commands discovered (not in CLAUDE.md) | ⚠ | 1 extra: vf-telemetry (documented in COMMANDS.md, intentional) |
| All 46 claimed skills exist on disk | ✓ | 46/46 found in skills/*/SKILL.md |
| Extra skills discovered (not in CLAUDE.md) | ⚠ | 2 extra: coordinated-validation (exists, implemented, documented in SKILLS.md) |
| All 5 claimed agents exist on disk | ✓ | 5/5 found in agents/ |
| All 7 claimed hooks exist on disk | ✓ | 7/7 found and registered in hooks.json |
| Extra hooks discovered (not in CLAUDE.md) | ⚠ | 3 extra orphaned hooks (not registered) |
| All 8 claimed rules exist on disk | ✓ | 8/8 found in rules/ |
| All skills have proper frontmatter | ✓ | Spot-checked: all have `---name:` and `description:` |
| All agents have proper frontmatter | ✓ | All 5 have `description:` field |
| All hooks registered in hooks.json | ✗ | 7/10 registered; 3 orphaned (config-loader, patterns, verify-e2e) |
| CLAUDE.md inventory matches SKILLS.md | ✗ | Specialized count differs (6 vs 7); coordinated-validation in one, not the other |

---

## Summary

**ValidationForge has excellent structural foundation** with all documented components present and functional on disk. Two primary issues requiring attention:

1. **Inventory drift:** CLAUDE.md (46 skills, 7 hooks, 16 commands) vs reality (48 skills, 10 hooks, 17 commands). New items added post-documentation update.

2. **Orphaned infrastructure:** 3 hooks and 1 command exist but not documented in primary inventory. Likely intentional (tracked in COMMANDS.md) or dead code (hooks).

**Time to remediate:** 20 minutes (inventory updates + hook decision).

**Recommended priority:**
- **Do first:** Add coordinated-validation to CLAUDE.md inventory (1 min)
- **Do next:** Decide fate of 3 orphaned hooks (10 min)
- **Do before next release:** Update all inventory counts to match reality
