# Site MDX Audit Report
**Date:** 2026-04-17  
**Scope:** Astro Starlight site content alignment with main branch skills/commands

---

## Skills MDX Coverage

**Total MDX pages (excl. index):** 10 / 52 expected  
**Coverage:** 19.2% — CRITICAL GAP

### Pages Missing (Skills exist on main, no MDX)
42 skills lack site documentation:
- accessibility-audit, ai-evidence-analysis, baseline-quality-assessment, build-quality-gates, chrome-devtools, cli-validation, condition-based-waiting, consensus-disagreement-analysis, **consensus-engine**, coordinated-validation, create-validation-plan, design-token-audit, design-validation, django-validation, e2e-testing, error-recovery, **evidence-dashboard**, flutter-validation, forge-benchmark, forge-execute, forge-plan, forge-setup, forge-team, full-functional-audit, fullstack-validation, gate-validation-discipline, ios-simulator-control, ios-validation, ios-validation-gate, ios-validation-runner, no-mocking-validation-gates, parallel-validation, production-readiness-audit, react-native-validation, research-validation, responsive-validation, rust-cli-validation, sequential-analysis, stitch-integration, team-validation-dashboard, validate-audit-benchmarks, verification-before-completion, visual-inspection, web-testing

### Phantom Pages (MDX exists, no SKILL.md)
None detected. All 10 site MDX files map to valid skills.

### Spot-Check Results
- **consensus-engine:** ✗ MISSING (SKILL.md exists, no .mdx)
- **evidence-dashboard:** ✗ MISSING (SKILL.md exists, no .mdx)
- **preflight:** ✓ PRESENT. Description sync: **PARTIAL MATCH**
  - SKILL.md: "Run BEFORE any validation session… auto-attempts one fix per failed check… CLEAR / BLOCKED / WARN verdict"
  - Site .mdx: "Pre-execution checklist… auto-fixes common failures… saves preflight report"
  - *Gap:* Site omits verdict enum and structured report location (e2e-evidence/preflight-report.md)

---

## Commands MDX Coverage

**Total MDX pages (excl. index):** 16 / 19 expected  
**Coverage:** 84.2%

### Pages Missing
3 commands lack site documentation:
- validate-consensus (exists: validate-consensus.md)
- validate-dashboard (exists: validate-dashboard.md)  
- validate-team-dashboard (exists: validate-team-dashboard.md)

### Phantom Pages
None. All 16 site MDX files map to valid command .md files.

---

## Stale-Pattern References in Site Content

### includeStatic=false (DEPRECATED PARAMETER)
**Count:** 3 references across 2 files  
**Files:**
- `site/src/content/docs/skills/web-validation.mdx:117, 123` — references `browser_network_requests includeStatic=false`
- `site/src/content/docs/skills/playwright-validation.mdx:149` — references `browser_network_requests → includeStatic=false`

**Risk:** These docs reference a parameter no longer supported. Should be removed or updated to current API.

### Ultrawork
**Count:** 0 references — ✓ CLEAN

---

## Summary

| Metric | Result |
|--------|--------|
| Skills MDX coverage | 10/52 (19%) |
| Commands MDX coverage | 16/19 (84%) |
| Phantom skill pages | 0 |
| Phantom command pages | 0 |
| Stale references | 3 (includeStatic=false) |
| Critical gaps | consensus-engine, evidence-dashboard |

## Recommended Regen Approach

1. **Priority 1 (Critical):**
   - Create `consensus-engine.mdx` (high-stakes validation orchestration)
   - Create `evidence-dashboard.mdx` (post-validation analysis)

2. **Priority 2 (High):**
   - Add 3 missing command pages (validate-consensus, validate-dashboard, validate-team-dashboard)
   - Sync preflight.mdx description with SKILL.md verdict/report details

3. **Priority 3 (Cleanup):**
   - Remove/update 3 includeStatic=false references in web-validation.mdx and playwright-validation.mdx

4. **Estimated Effort:** MODERATE
   - ~2 hours to author 5 new pages (consensus-engine, evidence-dashboard, 3 commands)
   - ~30 min to sync descriptions and clean stale refs
   - **Automation opportunity:** Generate MDX frontmatter + stubs from SKILL.md/command.md frontmatter; author bodies manually

---

**Unresolved Qs:**
- Should consensus-engine and evidence-dashboard pages be auto-generated from SKILL.md or written custom?
- Are the 3 missing command pages intentionally undocumented, or oversight?
