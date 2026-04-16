# ValidationForge: Technical Debt & Launch Blockers

**Version:** 1.0.0 | **Date:** March 10, 2026
**Purpose:** Honest inventory of what must be fixed before VF can launch.

---

## Severity Definitions

| Level | Meaning | Action |
|-------|---------|--------|
| **BLOCKER** | Cannot launch without fixing | Fix before any public announcement |
| **HIGH** | Significantly degrades experience | Fix before Week 2 (soft launch) |
| **MEDIUM** | Noticeable gap, workarounds exist | Fix before Week 6 (growth phase) |
| **LOW** | Nice-to-have improvement | Backlog for V1.5+ |

---

## 1. BLOCKER Issues (Must Fix Before Launch)

### 1.1 `/validate` End-to-End Pipeline — NEVER TESTED

**Status:** The core command has never been run as an automated pipeline.

**What we know:**
- Manual execution of the 7-phase pipeline works (7/7 journeys PASS against blog-series/site)
- The `/validate` command .md file exists and describes the pipeline
- But: no verification that Claude Code reads the command, loads the skills, executes the phases, and produces a report automatically

**Risk:** If `/validate` doesn't work, VF has no product. Everything else is scaffolding.

**Fix plan:**
1. Install plugin in fresh Claude Code session
2. Run `/validate` against blog-series/site (known-good web project)
3. Run `/validate` against a Python API project (second platform)
4. Document all failures and fix them
5. Re-run until clean execution on both project types

**Estimated effort:** 2-4 hours of testing + 4-8 hours of fixes

### 1.2 Plugin Load Verification — NEVER TESTED

**Status:** Plugin has never been verified loading in a fresh Claude Code session.

**What we know:**
- plugin.json exists with correct manifest format
- Symlink was created at `~/.claude/plugins/cache/validationforge/validationforge/1.0.0`
- Symlink was found dead in Session 4 and recreated
- Plugin format matches ECC and OMC patterns
- Hooks require session restart to activate

**Risk:** If the plugin doesn't load, users can't use VF at all.

**Fix plan:**
1. Kill all Claude Code sessions
2. Verify symlink is alive
3. Start fresh session
4. Check: are skills discoverable? Do commands work? Are hooks firing?
5. If not: debug plugin.json, paths, registration

**Estimated effort:** 1-2 hours

### 1.3 `/vf-setup` Initialization — NEVER TESTED

**Status:** The setup command has never been run.

**What we know:**
- Command .md file exists
- Should create `~/.claude/.vf-config.json`
- Should configure strictness level, evidence directory, platform overrides

**Risk:** First-run experience fails → user abandons immediately.

**Fix plan:**
1. Run `/vf-setup` after plugin loads
2. Verify config file creation
3. Verify subsequent `/validate` reads config
4. Test all 3 strictness levels

**Estimated effort:** 1-2 hours

### 1.4 SPECIFICATION.md Inventory Mismatch **[RESOLVED]**

**Status:** SPECIFICATION.md v1.0.0 says 16 skills, 5 commands, 5 hooks, 3 agents. Reality: 41 skills, 15 commands, 7 hooks, 5 agents, 8 rules.

**Risk:** Users read the spec, find different numbers on disk → credibility loss.

**Fix plan:**
- Update SPECIFICATION.md Section 4 (Skill Inventory) to match PRD v2.0.0 Section 4
- Update all references to old numbers throughout the document
- Or: deprecate SPECIFICATION.md in favor of PRD.md as source of truth

**Estimated effort:** 2-4 hours (if updating spec) or 15 minutes (if deprecating)

**Resolution:** SPECIFICATION.md has been deprecated with a notice pointing to PRD.md as single source of truth. All authoritative docs (CLAUDE.md, README.md, PRD.md, SPECIFICATION.md) now use consistent 41-skill count.

### 1.5 Demo GIF — DOESN'T EXIST

**Status:** No demonstration of VF catching a real bug.

**Risk:** README without demo → no one installs.

**Fix plan:**
1. Set up a project with a known bug (API field renamed, JWT expiry, CSS overflow)
2. Run `/validate` against it
3. Record VF detecting the bug and writing FAIL verdict
4. Convert to GIF, embed in README

**Estimated effort:** 2-3 hours

---

## 2. HIGH Issues (Fix Before Soft Launch)

### 2.1 Skill Quality — Only 5/40 Deep-Reviewed

**Status:** 5 skills have been deeply reviewed. 35 are spot-checked at best.

**What we know:**
- L0-L2 core skills (functional-validation, no-mocking-validation-gates, gate-validation-discipline, verification-before-completion, error-recovery) are well-written
- e2e-validate (L4 orchestrator, 2,563 lines) is the most complex and highest-risk
- Platform-specific skills (ios-validation, web-validation, api-validation, cli-validation) contain detailed instructions but haven't been functionally tested

**Risk:** Skills with bad instructions cause Claude to produce wrong output → user gets bad validation.

**Fix plan:**
- Priority review: e2e-validate, create-validation-plan, preflight (core pipeline skills)
- Secondary review: web-validation, api-validation (most common platforms)
- Tertiary review: ios-validation, cli-validation, fullstack-validation
- Total: 10 skills deep-reviewed before launch

**Estimated effort:** 4-6 hours

### 2.2 README Honesty

**Status:** Current README.md (23KB) contains a "Score: 0/5 vs 5/5" benchmark claim that was flagged and partially fixed in Session 2, but the overall README may still overstate what's verified.

**Fix plan:**
- Add "Verification Status" table (what works, what's unverified)
- Remove any claims not backed by actual testing
- Add honest "Known Limitations" section
- Update install instructions to reflect actual working method

**Estimated effort:** 1-2 hours

### 2.3 `${CLAUDE_PLUGIN_ROOT}` Resolution — UNVERIFIED

**Status:** Hook commands use `${CLAUDE_PLUGIN_ROOT}` variable. Never verified that Claude Code resolves this correctly at runtime.

**What we know:**
- This is the standard pattern used by OMC and ECC
- hooks.json references it in all 7 hook commands
- If it doesn't resolve: hooks don't fire → enforcement is gone

**Risk:** All 7 hooks silently fail if the variable doesn't resolve.

**Fix plan:**
1. Start Claude Code session with plugin loaded
2. Trigger a hook (e.g., try to create a test file → block-test-files should fire)
3. If hook doesn't fire: check `${CLAUDE_PLUGIN_ROOT}` resolution
4. If variable fails: switch to absolute paths or alternative pattern

**Estimated effort:** 30 minutes to verify, 1-2 hours to fix if broken

### 2.4 Platform Detection — UNTESTED ON REAL PROJECTS

**Status:** platform-detector agent exists but has never been tested against real iOS, API, CLI, or Fullstack projects (only Web/Next.js verified).

**Risk:** VF claims 6-platform support but only works on 1.

**Fix plan:**
1. Test against Swift/iOS project (blog-series/claude-code-ios or similar)
2. Test against Python API project
3. Test against CLI project (Go or Rust)
4. Fix detection signals for any failures
5. Document which platforms are verified vs unverified

**Estimated effort:** 3-4 hours

---

## 3. MEDIUM Issues (Fix Before Growth Phase)

### 3.1 CONSENSUS Engine — NOT IMPLEMENTED

**Status:** Skills and commands exist (validate-team, parallel-validation), but the 3-reviewer unanimous voting mechanism described in the PRD has never been tested.

**Risk:** Marketing describes CONSENSUS but it doesn't work → trust erosion.

**Fix plan:**
- Test /validate-team with 3 parallel validators
- Verify unanimous agreement requirement
- Verify disagreement reports
- Defer to V1.5 if significant work needed; remove from V1.0 marketing

**Estimated effort:** 4-8 hours

### 3.2 FORGE Engine — NOT IMPLEMENTED

**Status:** Skills exist (forge-setup, forge-plan, forge-execute, forge-team, forge-benchmark) and commands exist, but the autonomous build→validate→fix loop has never been tested.

**Risk:** Same as CONSENSUS — marketed but unverified.

**Fix plan:**
- Test /forge-execute with a project that has a fixable bug
- Verify 3-strike limit
- Verify fix loop actually works
- Defer to V2.0 if significant work needed; remove from V1.0 marketing

**Estimated effort:** 6-12 hours

### 3.3 Benchmark Scoring — UNVERIFIED

**Status:** /validate-benchmark command and benchmarking rule exist. The 4-dimension scoring model (Coverage 35%, Evidence 30%, Enforcement 25%, Speed 10%) is documented but never executed.

**Risk:** Benchmark claims are theoretical, not empirical.

**Fix plan:**
- Run /validate-benchmark against blog-series/site
- Verify scoring produces sensible numbers
- Calibrate weights if needed
- Generate first real benchmark report

**Estimated effort:** 2-3 hours

### 3.4 Evidence Retention & Cleanup — NOT IMPLEMENTED

**Status:** e2e-evidence/ directories are created during validation but there's no cleanup, rotation, or retention policy enforcement.

**Risk:** Evidence accumulates without bound, clutters repos.

**Fix plan:**
- Add `.gitignore` patterns for e2e-evidence/
- Implement retention policy from config (evidence_retention_days: 30)
- Add `/validate --clean` option

**Estimated effort:** 2-3 hours

---

## 4. LOW Issues (Backlog for V1.5+)

### 4.1 Missing Platform References
- React Native (mobile cross-platform)
- Flutter (mobile cross-platform)
- Python CLI (argparse/click)
- Rust CLI (clap)
- Django/Flask API

### 4.2 No npm Package
- Currently GitHub-only distribution
- npm would enable `npm install -g validationforge`

### 4.3 No GitHub Actions Template
- CI/CD integration documented but no starter workflow

### 4.4 No Visual Evidence Dashboard
- Evidence is markdown files; no HTML report viewer

### 4.5 No Telemetry or Usage Analytics
- Can't measure adoption without explicit opt-in analytics

### 4.6 Design Skills Untested
- design-validation, design-token-audit, stitch-integration haven't been validated
- Lower priority (niche use case)

---

## 4B. Risks Identified by Consensus Review (March 10, 2026)

> Added after Architect + Critic consensus review of planning artifacts.

### R1. Claude Code Plugin API Stability (HIGH)
VF depends entirely on Claude Code's plugin system (plugin.json, hooks.json, `${CLAUDE_PLUGIN_ROOT}`, skill discovery). If Anthropic changes the plugin API — which is not yet stable or officially versioned — VF breaks overnight. No mitigation plan exists.

### R2. Context Window Exhaustion (MEDIUM)
40 SKILL.md files total ~6,600 lines. If the e2e-validate orchestrator loads multiple skill layers (L0-L4) simultaneously, VF's own instructions could crowd out user codebase in the context window. No document addresses context budget management. Consider adding `context_priority` fields to skill frontmatter.

### R3. Install Friction (MEDIUM)
Current install requires: create nested directory, symlink, manually edit `installed_plugins.json`, restart Claude Code — 4 friction points. Launch plan targets "<30 seconds" but current process takes 2-3 minutes for experienced users.

### R4. Benchmark Scenarios Never Executed (BLOCKER — added)
The 5/5 vs 0/5 benchmark table is the primary marketing differentiator but has never been empirically measured. Zero evidence exists of any scenario being executed. A product preaching "evidence-based shipping" must have evidence for its own claims. Fix: Run all 5 scenarios and capture evidence before launch.

### R5. Config Profiles Disconnected from Hooks (MEDIUM)
The 3 config profiles (strict/standard/permissive) exist as JSON files but hooks.json has no mechanism to read them. Each hook runs unconditionally. The config system is decorative.

### R6. No Self-Validation (LOW)
A validation tool should validate itself. No plan exists to run `/validate` against the VF codebase as a demonstration of the methodology.

---

## 5. Debt-to-Launch Priority Matrix

```
IMPACT ON LAUNCH
     ↑
     │  1.1 /validate     1.2 Plugin load
     │  1.5 Demo GIF      1.3 /vf-setup
     │                     1.4 Spec mismatch
HIGH │─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
     │  2.1 Skill quality  2.3 Plugin root
     │  2.2 README         2.4 Platform detect
     │
MED  │─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
     │  3.1 CONSENSUS     3.3 Benchmark
     │  3.2 FORGE          3.4 Retention
     │
LOW  │  4.1-4.6 (backlog)
     └──────────────────────────────────────→
          LOW            MEDIUM            HIGH
                    EFFORT TO FIX
```

---

## 6. Total Effort Estimate

| Category | Items | Estimated Hours |
|----------|:-----:|:---------------:|
| BLOCKER | 5 | 10-19 hours |
| HIGH | 4 | 9-14 hours |
| MEDIUM | 4 | 14-26 hours |
| LOW | 6 | Backlog |
| **Total to launch** | **9** | **19-33 hours** |
| **Total to growth phase** | **13** | **33-59 hours** |

**Timeline:** With focused effort, launch blockers can be resolved in 1 sprint (1 week). HIGH issues in the following week. MEDIUM issues over the next month.

---

## 7. Decision Required: SPECIFICATION.md

Two options:

**Option A: Update SPECIFICATION.md**
- Pro: Maintains separate spec document
- Con: 4 hours of work, creates two sources of truth (SPEC + PRD)
- Risk: Spec and PRD diverge again

**Option B: Deprecate SPECIFICATION.md, PRD.md is source of truth**
- Pro: Single source of truth, no maintenance burden
- Con: Loses the "spec" as a reference document
- Recommendation: Add deprecation notice to top of SPECIFICATION.md pointing to PRD.md

**Recommendation:** Option B. PRD.md is more comprehensive and current. Add `> DEPRECATED: See PRD.md for current specification.` to SPECIFICATION.md header.

---

## 8. Resolved Items

### 8.1 patterns.js CommonJS Bridge — RESOLVED ✅

**Original status:** `hooks/patterns.js` was generated by a fragile runtime bridge that used `vm.runInNewContext` to strip TypeScript syntax from `patterns.ts` at startup. This approach was error-prone, non-standard, and required `fs.readFileSync` at hook load time.

**Risk (when open):** Any Node.js version or platform where `vm.runInNewContext` behaved differently could silently break all 5 enforcement hooks, eliminating VF's no-mock guarantees entirely.

**Resolution (April 2026):**
- Added `tsconfig.hooks.json` — a dedicated TypeScript config that compiles `patterns.ts` to CommonJS for the `hooks/` directory.
- Added `npm run build:patterns` script to `package.json` (`tsc --project tsconfig.hooks.json`).
- Ran the build step to replace the fragile bridge with a properly compiled `hooks/patterns.js`.
- All 5 hooks (`block-test-files`, `mock-detection`, `validation-not-compilation`, `completion-claim-validator`, `validation-state-tracker`) verified working against synthetic inputs.
- Zero `vm.runInNewContext` calls remain in production hook code.

**Ongoing maintenance:** When `patterns.ts` is modified, run:
```bash
npm run build:patterns
```
This regenerates `hooks/patterns.js`. The file is marked `AUTO-GENERATED` — do not edit it directly.

## X. Inherited from Plan 260408-1522 (Dual-Platform Audit)

### X.1 Duplicate enforcement patterns (H7 from plan 260408-1522)
62 regex patterns hardcoded identically in hooks/ JS files AND patterns.ts.
Drift risk on every update.
**Severity:** HIGH
**Fix:** Consolidate into single source (patterns.ts, with JS compile step)
**Owner:** Future plan

### X.2 Shell script side effects (H8 from plan 260408-1522)
install.sh, uninstall.sh, health-check.sh have unaudited filesystem side
effects on user's ~/.claude directory.
**Severity:** HIGH
**Fix:** Add dry-run mode, URL scheme whitelist, input validation
**Owner:** Future plan

### X.3 shell.env hook validity (M13 from plan 260408-1522)
Hook shell.env handling never verified across bash 3.2 (macOS) and bash 5+.
**Severity:** MEDIUM
**Fix:** Cross-platform smoke test
**Owner:** Future plan

### 3.1 CONSENSUS engine — TRIAGED (not tested)
Skills `coordinated-validation`, `forge-team` + command `/validate-team` exist.
3-reviewer unanimous voting mechanism documented but untested with live agents.
Status: TRIAGED to debt (scope: needs separate test plan)

### 3.2 FORGE engine — TRIAGED (not tested)
Skills `forge-execute`, `forge-plan`, `forge-setup`, `forge-benchmark`,
`forge-team` + commands exist. Autonomous build→validate→fix loop never
tested end-to-end.
Status: TRIAGED to debt (scope: needs separate test plan)

### 3.4 Evidence retention / cleanup — PARTIAL VERIFY
scripts/evidence-cleanup.sh syntax-checks clean via bash -n.
Full retention policy not exercised.
Status: TRIAGED (smoke only)

## Gap validation closure — 2026-04-16

- [ ] C-M3: FAIL
- [ ] flagged

Source: plans/260411-2305-gap-validation/GAP-VALIDATION-REPORT.md
