# Static Audit Report: 6 ValidationForge Skills

**Date:** 2025-04-17  
**Audited Skills:** 6  
**Total Lines Analyzed:** 864  
**Bundled Resources:** 4 reference files, 0 scripts  

---

## Executive Summary

| Skill | Priority | Description Issues | Body Issues | Critical Gaps |
|-------|----------|-------------------|------------|----------------|
| team-validation-dashboard | **MED** | 3 (under-triggers) | 6 (1 HIGH) | Script paths unclear, data availability buried |
| validate-audit-benchmarks | **HIGH** | 3 (under-triggers) | 6 (2 HIGH) | Scripts not bundled, scoring rubric vague |
| verification-before-completion | **MED** | 3 (under-triggers) | 5 (1 HIGH) | Enforcement mechanism undefined, heavy reference dependency |
| visual-inspection | **MED** | 3 (ok triggers) | 5 (no HIGH) | Rigid checklist, poor platform-specific guidance |
| web-testing | **MED** | 3 (ok triggers) | 6 (1 HIGH) | Decision matrix lacks reasoning, verdict thresholds undefined |
| web-validation | **HIGH** | 3 (ok triggers) | 6 (2 HIGH) | Port detection fragile, route discovery unmaintainable |

---

## Detailed Findings by Skill

### 1. team-validation-dashboard
**File:** `team-validation-dashboard.audit.json`  
**Priority:** MED

**Strengths:**
- Clear step-by-step workflow
- Precise data format specifications (snapshot.json, ownership.json)
- Color-coded urgency levels are intuitive

**Critical Issues:**
- Architecture diagram misleads (scripts listed but not bundled)
- Data availability note admits coverage_pct/regression_count show as 0 in real use
- Score threshold definitions (Critical <60, Needs Attention 60–79) are hardcoded, not explained

**Top Fixes:**
1. Move data availability warning to frontmatter description
2. Clarify script locations relative to skill directory
3. Link posture_score calculation directly to /validate-benchmark

---

### 2. validate-audit-benchmarks
**File:** `validate-audit-benchmarks.audit.json`  
**Priority:** HIGH

**Strengths:**
- Weight distribution (60/20/20 hooks/skills/commands) is clear
- A-F grading scale is familiar and actionable
- Regression comparison against baseline is powerful

**Critical Issues:**
- Entire skill references bash scripts (test-hooks.sh, validate-skills.sh, aggregate-results.sh) without bundling them
- Scoring rubric for "Hook Correctness" is vague—what exactly counts as correct?
- Baseline initialization not explained (how to initialize on first run?)

**Top Fixes:**
1. Bundle or provide explicit paths to all three benchmark scripts
2. Define "Hook Correctness" scoring rubric in detail (exit codes, pattern accuracy, protocol compliance)
3. Explain baseline initialization workflow

---

### 3. verification-before-completion
**File:** `verification-before-completion.audit.json`  
**Priority:** MED

**Strengths:**
- Core rule is clear and imperative (5 concrete steps)
- Evidence-citation-examples.md reference is excellent
- Checklist format is self-policing
- Read-only security policy prevents false completions

**Critical Issues:**
- Checklist (lines 32–57) uses vague "Good vs Bad" without explaining reasoning
- Evidence citation format relies heavily on external reference file (circular dependency)
- Enforcement mechanism unclear: is this a reminder, a blocker, or optional discipline?

**Top Fixes:**
1. Inline anti-patterns table from evidence-citation-examples.md (don't reference off-skill)
2. Add hook into Claude Code task completion flow
3. Clarify enforcement: blocker vs. reminder vs. optional?

---

### 4. visual-inspection
**File:** `visual-inspection.audit.json`  
**Priority:** MED

**Strengths:**
- 7-category checklist is comprehensive (layout, typography, interactive, hierarchy, platform-specific, dark/light mode, edge cases)
- Evidence capture protocol for Web (Playwright MCP) and iOS (xcrun simctl) is concrete
- Report template is structured and machine-parseable
- Anti-patterns table helps users avoid false negatives
- Bundled references (ios-hig-checklist.md, web-wcag-checklist.md, defect-pattern-database.md)

**Critical Issues:**
- 7-category checklist is rigid—assumes every UI has all categories (no guidance on skip logic)
- Platform-specific sections send users off-skill to references instead of inline summaries
- Error handling missing (what if screenshot capture times out?)
- Severity-to-verdict mapping undefined (is 1 CRITICAL finding = FAIL journey?)

**Top Fixes:**
1. Add decision tree for skipping irrelevant categories
2. Inline 1-line summary of platform-specific checklists (HIG, WCAG)
3. Define severity-to-verdict mapping
4. Add error handling for screenshot capture failures

---

### 5. web-testing
**File:** `web-testing.audit.json`  
**Priority:** MED

**Strengths:**
- 5-layer model is well-conceived (integration → E2E → a11y → performance → security)
- Decision matrix provides quick at-a-glance view of which layers apply
- Each layer has concrete commands (curl, browser tools, Lighthouse)
- Evidence organization (layers → subdirectories) is clear
- Security validation includes specific test payloads (XSS, SQLi, path traversal)

**Critical Issues:**
- Decision matrix lacks reasoning (why does "New page/route" need Layer 4 Performance, but "Style/layout change" doesn't?)
- Layer 1 (Integration) shows examples but doesn't explain evidence interpretation
- Layer 2 (E2E) is minimal and delegates without explaining what "critical user journeys" means
- Layer 4 (Performance) doesn't define FAIL threshold (is 3.8s LCP a blocker?)
- Layer 5 (Security) test payloads lack expected behavior definitions

**Top Fixes:**
1. Expand decision matrix with reasoning column
2. Define verdict thresholds for each layer (especially performance metrics)
3. Add layer dependencies section (Layer 2 requires Layer 1, etc.)
4. Clarify security test expectations (reject vs sanitize vs drop)

---

### 6. web-validation
**File:** `web-validation.audit.json`  
**Priority:** HIGH

**Strengths:**
- 8-step workflow is sequential and actionable
- Evidence capture is systematic (health → navigation → console → network → forms → responsive → routes)
- Both Playwright MCP and Chrome DevTools MCP examples provided
- Common Failures troubleshooting is comprehensive
- PASS Criteria template is concrete and machine-checkable

**Critical Issues:**
- Step 1 (Start Dev Server) uses loose heuristics for framework detection (what if pnpm AND npm both exist?)
- Step 2 (Health Check) hardcodes port 3000, but Step 1 doesn't determine actual port
- Step 3 (Page Navigation) shows both Playwright and Chrome DevTools examples but doesn't explain when to use each
- Step 6 (Form Validation) uses template values (user@example.com) that may not match real validation rules
- Step 8 (Route Coverage) hardcodes routes as bash array—unmaintainable for 47+ routes

**Top Fixes:**
1. Fix port detection: Step 1 should output PORT variable; Step 2 should use it
2. Improve framework detection (check for dev command names, ask user if unsure)
3. Add tool comparison: Playwright MCP vs Chrome DevTools MCP (when to use each?)
4. Add form rule discovery guidance (inspect HTML attributes, read error messages, check API docs)
5. Replace hardcoded route list with dynamic discovery (React Router, Django urls.py, OpenAPI spec)

---

## Rubric Application

### Description Quality (30–80w, pushy what+when)
- **team-validation-dashboard:** 27w, under-triggers (missing "when to use vs when stale")
- **validate-audit-benchmarks:** 22w, under-triggers (scope not defined)
- **verification-before-completion:** 20w, under-triggers (enforcement mechanism absent)
- **visual-inspection:** 24w, ok (clear what+when)
- **web-testing:** 26w, ok (clear what+when)
- **web-validation:** 19w, ok (clear what+when)

### Body Quality (progressive disclosure, explain WHY not MUST-spam)
- **team-validation-dashboard:** Good workflow, but architecture diagram is misleading
- **validate-audit-benchmarks:** Lightweight (80 lines), but references automation without delivering it
- **verification-before-completion:** Core rule is clear, but relies on external references
- **visual-inspection:** Comprehensive, but rigid and sends users off-skill
- **web-testing:** Excellent model, but lacks decision rubric and thresholds
- **web-validation:** Actionable, but fragile detection and unmaintainable lists

### Evidence & Citations
- **Strengths across all:** Concrete examples (commands, paths, JSON structures, test payloads)
- **Weakness across all:** Missing error recovery (what if the happy path fails?)

---

## Cross-Skill Issues

### 1. Script Bundling Inconsistency
- **Skills missing scripts:** team-validation-dashboard, validate-audit-benchmarks, web-validation, web-testing
- **Impact:** Users who extract skills cannot execute them in isolation
- **Fix:** Bundle scripts or provide explicit paths relative to ValidationForge root

### 2. Tool Availability Assumptions
- **visual-inspection:** Assumes Playwright MCP or Chrome DevTools MCP are available (not verified)
- **web-validation:** Same assumption, plus hardcoded port 3000
- **Fix:** Add preflight checks for tool availability and port detection

### 3. Circular Reference Dependencies
- **verification-before-completion:** Relies on evidence-citation-examples.md (external reference)
- **visual-inspection:** Relies on ios-hig-checklist.md, web-wcag-checklist.md (external references)
- **Fix:** Inline critical content, keep references for detailed deep-dives only

### 4. Verdict Thresholds Undefined
- **web-testing:** Performance metrics (LCP 3.5s = Needs Work) but no FAIL threshold
- **visual-inspection:** Severity levels (CRITICAL/HIGH/MEDIUM/LOW) but no PASS/FAIL mapping
- **Fix:** Define thresholds explicitly per skill

### 5. Framework/Platform Detection Fragile
- **web-validation:** Detects frameworks by lock file (pnpm-lock.yaml, package-lock.json) but doesn't handle edge cases
- **Fix:** Improve detection heuristics, ask user for confirmation

---

## Opportunity Summary

### High Priority (blocks execution)
1. **validate-audit-benchmarks:** Bundle scripts or mark as reference-only
2. **web-validation:** Fix port detection and framework detection
3. **web-testing:** Define verdict thresholds for all layers

### Medium Priority (blocks clarity)
1. **team-validation-dashboard:** Clarify data availability limitations upfront
2. **verification-before-completion:** Define enforcement mechanism
3. **visual-inspection:** Add decision tree for category relevance

### Low Priority (documentation polish)
1. All skills: Add error recovery guidance
2. All skills: Clarify tool/framework assumptions in prerequisites

---

## Test Prompts Delivered

Each audit includes 3 realistic Claude Code prompts:
- **team-validation-dashboard:** Multi-project setup, ownership assignment, re-benchmarking
- **validate-audit-benchmarks:** Hook regression check, grade calculation, validation specifics
- **verification-before-completion:** Login form completion, API/UI changes, delegation rejection
- **visual-inspection:** Landing page redesign, iOS safe area, multi-severity reporting
- **web-testing:** Dashboard validation (all layers), performance threshold decision, CSS-only change
- **web-validation:** Django port mismatch, form validation discovery, route coverage at scale

---

## Files Generated

```
team-validation-dashboard.audit.json
validate-audit-benchmarks.audit.json
verification-before-completion.audit.json
visual-inspection.audit.json
web-testing.audit.json
web-validation.audit.json
```

All reports saved to `/Users/nick/Desktop/validationforge/skill-audit-workspace/_reports/`

---

**Audit Complete**
