# ValidationForge Findings

## Session 2026-03-09: Deep Reflection Audit

### Hooks (7 total)
| Hook | Syntax | Functional Test | Status |
|------|--------|-----------------|--------|
| block-test-files.js | PASS | Blocks `*.test.tsx`, allows normal files | Working |
| evidence-gate-reminder.js | PASS | Injects checklist on TaskUpdate | Working |
| validation-not-compilation.js | PASS | **Was broken** — `data.tool_result` is object, not string. Fixed. | Fixed |
| completion-claim-validator.js | PASS | **Was broken** — same object bug. Fixed. | Fixed |
| mock-detection.js | PASS | Detects `jest.mock()` | Working |
| evidence-quality-check.js | PASS | Warns on empty evidence | Working |
| validation-state-tracker.js | PASS | Detects playwright commands | Working |

### Bug: tool_result Object vs String
`data.tool_result` from Claude Code is `{stdout: "...", exit_code: 0}` (object), not a plain string.
Two hooks used regex `.test()` on the object, which coerces to `"[object Object]"` — always false.
Fix: `const output = typeof result === 'string' ? result : (result.stdout || '');`

### Plugin Format Verification
- hooks.json format matches ECC 1.8.0 and full-featured-plugin example
- plugin.json has `"skills": "./skills/"` matching OMC pattern
- `${CLAUDE_PLUGIN_ROOT}` used in hook commands (standard pattern)

### File Inventory (Verified on Disk)
- 40 skill directories, each with SKILL.md
- 15 command .md files
- 5 agent .md files
- 8 rule .md files
- 7 hook .js files + hooks.json
- 3 config .json files (strict, standard, permissive)

### Command Cross-Reference Audit (Session 2, Phase 2b)
- All 15 commands audited for cross-references
- Agent references: 5 unique (platform-detector, evidence-capturer, verdict-writer, validation-lead, sweep-controller) — all exist
- Skill references: 7 unique (ios-validation, web-validation, api-validation, cli-validation, fullstack-validation, design-validation, create-validation-plan) — all exist
- Rule references: 8 unique (all 8 rules) — all exist
- **Zero broken cross-references** across all 15 commands

### Plugin Installation (Session 2, Phase 3)
- Symlinked to `~/.claude/plugins/cache/validationforge/validationforge/1.0.0`
- Registered in `installed_plugins.json` as `validationforge@validationforge` (scope: user)
- All plugin directories accessible through symlink (verified with ls)
- Plugin format matches ECC and OMC patterns (auto-discovery of skills/, commands/, agents/, rules/, hooks/)

### README Fixes (Session 2, Phase 5)
- Removed dishonest "Score: 0/5 vs 5/5" benchmark claim
- Added "Verification Status" table documenting exactly what's verified and what's not
- Fixed install instructions (removed references to nonexistent GitHub repo and install.sh)

### Phase 4: Functional Validation Against blog-series/site (Session 3)
- **Target**: blog-series/site (Next.js 15, App Router, TypeScript, Tailwind v4)
- **Method**: VF 7-phase pipeline executed manually via Playwright MCP
- **Results**:
  - Platform detection: Web/Next.js identified from package.json
  - Build: `pnpm build` — 27 pages, exit code 0
  - Server: HTTP 200 on localhost:3847
  - Homepage: 18 post cards, hero stats (23,479 sessions, 363 worktrees), navigation
  - Post 03 article: title, subtitle, code blocks, Mermaid diagrams, data tables, tags, prev/next nav
  - Post 04 via navigation: renders correctly after clicking "Next" link
  - Console: Vercel analytics errors only (expected on localhost)
- **Evidence**: 4 screenshots + inventory in `e2e-evidence/web-validation/`
- **Verdict**: PASS on all 6 predefined criteria

### Phase 4b: Expanded Validation (Session 4)
- **All 18 posts HTTP 200**: curl verified every post URL returns 200
- **Deep content verification** (3 posts via Playwright MCP accessibility tree):
  - Post 01 (first): hero stats, SVG charts, data tables, Mermaid diagrams, code blocks, tags, nav
  - Post 09 (middle): pipeline diagram, code blocks, data tables, metrics, tags, prev/next nav
  - Post 18 (last): decision framework, cost tables, code blocks, finale content, "Previous" only (correct)
- **Error state**: `/posts/post-99-nonexistent` returns HTTP 404 (correct)
- **Responsive layout** (375x812 mobile viewport):
  - Homepage: hero stacks vertically, stats centered, post cards single-column, sidebar toggle
  - Post 07: article readable, code blocks scroll, Mermaid scales, tags wrap, nav stacks
  - About page: stats grid wraps to 2-column, text readable, footer accessible
- **About page**: title, methodology, stats grid (6 metrics), author bio all render
- **Console**: zero application errors (only Vercel analytics failures on localhost)
- **Evidence**: 6 screenshots in `e2e-evidence/web-validation/expanded/`
- **Verdict**: PASS on 7/7 criteria (see `expanded/VERDICT.md`)

### Plugin Infrastructure Fix (Session 4)
- Dead symlink at `~/.claude/plugins/cache/validationforge/validationforge/1.0.0` — recreated
- Incomplete plugin.json (missing commands, agents, rules declarations) — fixed with all 5 directories
- Plugin won't load in current session (fundamental: plugins load at session startup)

---

## 2026-04-08 — Subtask-1-1: Pipeline Gap Analysis (commands/validate.md vs CLAUDE.md 7-phase spec)

### Audit: commands/validate.md Pipeline Stages

Current `commands/validate.md` "Pipeline Stages" section lists **5 stages**:

| validate.md Stage | Phase # | Notes |
|-------------------|---------|-------|
| 1. PREFLIGHT | Phase 2 in spec | Present, but ordering is wrong (before PLAN) |
| 2. PLAN | Phase 1 in spec | Present, but executed *after* Preflight (inverted from spec) |
| 3. APPROVE | — not a phase | Interactive gate within Plan; not canonical |
| 4. EXECUTE | Phase 3 in spec | Present |
| 5. REPORT | Phase 5 in spec | Present, but named REPORT instead of VERDICT |

### Missing Phases (Confirmed)

**Phase 0 — RESEARCH**: Not present in validate.md at all. The CLAUDE.md spec requires a dedicated research step before planning: gather applicable standards (WCAG, HIG, security standards), identify validation criteria, and map standards to VF skills. The `rules/execution-workflow.md` calls this "Understand what to validate and how" and invokes the `research-validation` skill.

**Phase 4 — ANALYZE**: Not present as a separate phase in validate.md. After EXECUTE, the command goes directly to REPORT/VERDICT. The spec defines Phase 4 as an explicit root-cause investigation step for FAILs using `sequential-analysis`, `visual-inspection`, and `chrome-devtools` skills. Without it, failures go unreported until the final verdict with no intermediate diagnosis.

**Phase 6 — SHIP**: Not present in validate.md. The spec defines Phase 6 as a production readiness audit and deploy decision gate, invoked via the `production-readiness-audit` skill. Security and deployment FAILs are blocking; other FAILs can be CONDITIONAL with documented risk. This phase is the difference between "tests passed" and "safe to deploy."

### Additional Ordering Issue

The validate.md inverts the PREFLIGHT/PLAN order: it runs PREFLIGHT (Phase 2) *before* PLAN (Phase 1). The canonical spec and `rules/execution-workflow.md` specify PLAN first (define what to validate) then PREFLIGHT (verify the system can run it). This means validate.md could reject a session before even defining what journeys to run.

### Summary Table

| Phase | Canonical Name | Present in validate.md | Status |
|-------|---------------|------------------------|--------|
| 0 | RESEARCH | No | **MISSING** |
| 1 | PLAN | Yes (misordered — runs after Preflight) | Present but misplaced |
| 2 | PREFLIGHT | Yes (runs first — before Plan) | Present but misplaced |
| 3 | EXECUTE | Yes | Present |
| 4 | ANALYZE | No | **MISSING** |
| 5 | VERDICT | Yes (named REPORT) | Present but renamed |
| 6 | SHIP | No | **MISSING** |

### Conclusion

`commands/validate.md` covers only **5 stages** (Preflight → Plan → Approve → Execute → Report) and is missing **3 canonical phases**: Phase 0 (Research), Phase 4 (Analyze), and Phase 6 (Ship). The APPROVE step is not a canonical pipeline phase. Phase ordering is inverted (Preflight before Plan). The REPORT naming diverges from the canonical VERDICT name.

---

### Updated Verification Status
| Area | Status |
|------|--------|
| File inventory (40 skills, 15 commands, 7 hooks, 5 agents, 8 rules) | Verified |
| Hook syntax and functional behavior (all 7) | Verified |
| Cross-references (commands → skills, agents, rules) | Verified — zero broken |
| Plugin manifest format | Verified (updated with all 5 directory declarations) |
| **VF methodology against real project (2/18 posts)** | **Verified — PASS** |
| **VF methodology expanded (18/18 posts + responsive + errors)** | **Verified — PASS (7/7 criteria)** |
| Plugin loaded in live Claude Code session | Not verified (requires restart) |
| `/validate` command as automated pipeline | Not verified (manual execution only) |
| `${CLAUDE_PLUGIN_ROOT}` resolution | Not verified |
| Benchmark scoring | Not verified |
| Skill content quality (all 40) | Partially verified (5 deep, rest spot-checked) |
