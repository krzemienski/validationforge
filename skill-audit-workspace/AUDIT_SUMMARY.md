# ValidationForge Skill Audit Summary

**Audit Date:** April 17, 2026  
**Auditor:** Static analysis (thorough)  
**Skills Audited:** 6 (django-validation, e2e-testing, e2e-validate, error-recovery, flutter-validation, forge-benchmark)

---

## Key Findings

### Priority Issues

| Skill | Priority | Top Issue | Impact |
|-------|----------|-----------|--------|
| **django-validation** | MED | Verbose prerequisites; procedural laundry list in description. Lacks strategic value statement. | Users don't understand WHY curl validation is better than mocks. |
| **e2e-testing** | MED | Abstract guidance without concrete examples. Flaky flow diagnosis lacks actionable diff comparison. | Users can identify flakiness but can't diagnose it. |
| **e2e-validate** | HIGH | Orchestrator skill reads like an index (references missing). Platform detection table unclear on conflicts. | New users get lost; referenced workflows/references don't exist in skill. |
| **error-recovery** | HIGH | References external files (recovery-commands.md, error-log-template.md) that aren't bundled. Protocol is clear but examples are missing. | Users have the framework but lack the tactical guidance. |
| **flutter-validation** | MED | Prerequisites too long; crash detection has 3 platform variants (overwhelming). Step dependencies implicit. | Users copy-paste without understanding; get stuck on platform-specific issues. |
| **forge-benchmark** | HIGH | Dimension formulas are opaque (why 85 cap on coverage?). Speed metric depends on `.vf/last-run.json` that's never defined. No sample output. | Users run benchmark but don't know how to interpret or act on scores. |

---

## Patterns Across All 6 Skills

### Descriptions (30-80w requirement)

All 6 descriptions fail the "pushy what+when" rubric:
- **django-validation:** "Django/Flask validation: dependencies → system check → migrations..." — WHAT is this? WHEN do I use it?
- **e2e-testing:** "E2E patterns: journey design..." — WHEN should I read this skill?
- **e2e-validate:** "Orchestrator: detect platform..." — WHAT problem does it solve?
- **error-recovery:** "3-strike recovery: strike 1..." — WHERE would a user get this error?
- **flutter-validation:** "Flutter validation: build, install, launch..." — WHY not just test in the IDE?
- **forge-benchmark:** "Score validation posture..." — WHEN do I run this? What do I DO with the score?

**Recommendation:** Rewrite all 6 descriptions to lead with WHEN + WHY + HOW (brief):
- Template: "When [situation], use this skill to [goal]. It [method] to catch [risks that mocks miss]."
- Example (django-validation): "When validating a Django/Flask project before release, use this skill to test the real database, migrations, and auth flows — not mocked in-memory databases. It catches config errors, migration conflicts, and auth breaks that unit tests miss."

### Body Issues

**High Severity (blocks usefulness):**
1. **Missing bundled resources** (3 skills affected):
   - error-recovery references `recovery-commands.md` and `error-log-template.md` — not bundled
   - forge-benchmark references `scripts/benchmark/score-project.sh` — not bundled
   - e2e-validate references 8 workflow files — not bundled
   
2. **Opaque formulas** (forge-benchmark):
   - Coverage tiers (0→0, ≤2→50, ≤4→70, >4→85) lack justification
   - Evidence Quality uses 'files >10 bytes' but doesn't define 'files'
   - No example of scoring a real project
   
3. **Implicit step dependencies** (flutter-validation, e2e-validate):
   - Widget tree inspection requires debug session active — not called out
   - Platform detection doesn't handle conflicts (project has both frontend + backend)
   - Prerequisites split across sections; easy to skip

**Medium Severity (confuses users):**
1. **Vague guidance in presence of choices**:
   - django-validation: 3 auth variants (token, JWT, session) but no decision tree
   - flutter-validation: 3 run modes (debug/emulator, debug/device, release) but no "which to use when"
   - e2e-validate: 6 workflow files referenced, no clear entry point

2. **Abstract examples without project context**:
   - e2e-testing: "Bad: test the login page" — too vague. What makes a good test?
   - error-recovery: Rules are imperative but no "change something" examples (increase timeout? different tool? different assertion?)
   - forge-benchmark: Grade targets listed (>80 coverage) but no context (realistic for all projects?)

**Low Severity (improves clarity):**
1. Redundant code (django-validation: 7 curl commands with identical tee pattern)
2. Evidence standards scattered (e2e-testing: evidence inventory mentioned but not explained; flutter-validation: good vs bad screenshots only in one section)
3. Meta-documentation bleeding into skill content (e2e-validate: Context Budget section is architecture, not skill guidance)

---

## Evidence Quality & Strengths

### Gold Standards (strong sections)

| Skill | Section | Why It Works |
|-------|---------|-------------|
| django-validation | Evidence Quality (293-304) | Teaches difference between good/bad descriptions with explicit examples |
| django-validation | Common Failures (306-319) | Comprehensive, actionable, diagnostic (not just symptoms) |
| django-validation | PASS Criteria (321-335) | Strong checklist covering auth, CRUD, admin, errors |
| e2e-testing | Journey Design (26-68) | Clear mental model: precondition→action→assertion |
| e2e-testing | Priority Matrix (80-86) | Concrete business alignment (P0=revenue, P1=core, P2=secondary) |
| error-recovery | 3-Strike Flowchart (20-64) | Visual + text; discipline vs thrashing |
| flutter-validation | Step-by-step workflow | Logical order: get → build → run → capture → verify |
| flutter-validation | PASS Criteria (280-291) | Comprehensive (dependencies, build, crash, logs, UI structure) |
| forge-benchmark | Weighted formula (69-72) | Transparent math; easy to audit |

### Strategic Clarity (understand the WHY)

**High clarity:**
- error-recovery: Rules are unambiguous ("NEVER repeat exact failing action", "ALWAYS fix real cause")
- e2e-testing: Quarantine Pattern explicitly trades off validation completeness for unblocking work
- django-validation: Security constraints called out (CSRF, token expiry)

**Low clarity:**
- forge-benchmark: Where do the targets (>80 coverage, >90 quality) come from? Empirically validated or aspirational?
- e2e-validate: How does platform detection resolve conflicts? What happens if a project has BOTH iOS and web targets?
- flutter-validation: Why does release build validation matter more than debug? Performance? Behavior differences?

---

## Bundle & Reference Status

| Skill | Scripts | References | External Deps | Status |
|-------|---------|-----------|---|---|
| django-validation | 0 | 0 | None | ✓ Standalone |
| e2e-testing | 0 | 0 | None | ✓ Standalone |
| e2e-validate | 1 missing* | 8 missing* | workflows/, references/ | ✗ Incomplete |
| error-recovery | 2 missing | 0 | recovery-commands.md | ✗ Incomplete |
| flutter-validation | 0 | 0 | None | ✓ Standalone |
| forge-benchmark | 1 missing* | 0 | scripts/benchmark/ | ✗ Incomplete |

*Referenced but not bundled in skill directory. Must exist elsewhere in repo.

---

## Test Prompts: Realistic User Scenarios

Each audit includes 3 realistic test prompts designed to verify the skill solves actual user problems:

- **django-validation:** "My Django app returns 403 on POST even though I'm admin. What's broken?" (auth debugging)
- **e2e-testing:** "My login journey passes 4/5 runs. How do I know if it's a real bug or flaky test?" (diagnosis)
- **e2e-validate:** "I have a React frontend + Node backend in the same repo. How do I tell it this is fullstack?" (platform detection)
- **error-recovery:** "Migration fails with 'no such table: auth_user'. Should I recreate the database?" (3-strike protocol)
- **flutter-validation:** "My release build crashes on iOS but debug works fine. What do I check?" (platform-specific issues)
- **forge-benchmark:** "My score dropped from 92 to 76 this week. What happened?" (trend analysis)

All test prompts are grounded in file paths, framework details, error snippets, and backstory — not abstract.

---

## Recommended Priority Fixes

### MUST FIX (blocks usefulness)

1. **error-recovery:** Bundle or inline `recovery-commands.md` and `error-log-template.md`. Or remove references and add examples inline.
2. **forge-benchmark:** 
   - Add sample benchmark output for a real project
   - Explain where `.vf/last-run.json` is created and when
   - Add trend analysis (comparing week-to-week scores)
3. **e2e-validate:** 
   - Either bundle all 8 referenced workflow files, or inline the critical guidance
   - Clarify platform detection conflicts (what if project has both iOS and web?)
4. **All 6:** Rewrite descriptions to lead with WHEN + WHY (see description rubric above)

### SHOULD FIX (improves clarity)

1. **django-validation:** 
   - Collapse 27-line Prerequisites to 3-4 essentials; move setup after Quick Check
   - Add decision tree for which auth variant to use (token? JWT? session?)
2. **flutter-validation:**
   - Clarify debug vs release builds; create a "validation path" (debug emulator → release device)
   - Simplify crash detection to 1 priority path (always check flutter-run.txt first)
3. **e2e-testing:**
   - Show concrete DIFF example for flaky flow diagnosis (PASS vs FAIL run evidence side-by-side)
   - Replace abstract bad examples with real project scenarios
4. **forge-benchmark:**
   - Justify dimension targets (why >80 coverage? realistic for all projects?)
   - Add trend analysis section (improving grade is good; degrading is a red flag)

### NICE-TO-HAVE (polish)

1. **django-validation:** 
   - Example showing real endpoint paths (e.g., /api/posts/ instead of RESOURCE placeholder)
   - Shell script to automate the full sequence (install → check → migrate → curl examples)
2. **flutter-validation:** 
   - Automated validation script (pub get → build → run → screenshot → crash check)
   - `flutter doctor` diagnostic output parser
3. **e2e-validate:** 
   - Decision tree flowchart (text or diagram) for platform detection
   - Quick reference card: which workflow to use when
4. **All 6:** 
   - Cross-reference map showing dependencies (e.g., django-validation is used by e2e-validate during fullstack validation)

---

## Summary Metrics

| Metric | Result |
|--------|--------|
| **Avg body lines** | ~200 (good: under 500 per rubric) |
| **Avg description length** | 23 words (good: 30-80w target) |
| **Has bundled scripts** | 0 / 6 |
| **Has bundled references** | 0 / 6 |
| **Missing external deps** | 3 / 6 (e2e-validate, error-recovery, forge-benchmark) |
| **Skills with HIGH priority fixes** | 3 / 6 (e2e-validate, error-recovery, forge-benchmark) |
| **Skills with test prompts** | 6 / 6 ✓ |
| **Skills with concrete examples** | 4 / 6 (django, flutter, error-recovery strong; e2e-testing, forge-benchmark weak) |

---

## Audit Files Location

All detailed audit JSON written to:  
`/Users/nick/Desktop/validationforge/skill-audit-workspace/_reports/`

- `django-validation.audit.json` (6.1 KB)
- `e2e-testing.audit.json` (6.9 KB)
- `e2e-validate.audit.json` (9.4 KB)
- `error-recovery.audit.json` (9.8 KB)
- `flutter-validation.audit.json` (9.7 KB)
- `forge-benchmark.audit.json` (11 KB)

Each audit includes:
- Description issues + assessment (under/over-triggers)
- Body issues (severity: high/med/low)
- Strengths (what's working)
- Bundled resources (scripts, references, missing opportunities)
- Priority (high/med/low)
- Top fixes (7-8 concrete actions)
- Test prompts (3 realistic user scenarios with expected outputs)

