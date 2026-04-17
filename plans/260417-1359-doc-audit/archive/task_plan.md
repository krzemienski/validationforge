# ValidationForge: Ship-Ready Plan

## Context
Reflection score: 2.45/5.0 (REJECTED). Core gap: plugin never installed or run against a real project. A validation tool that hasn't been validated is self-contradictory.

## Phase 1: Fix Dishonest Claims [CRITICAL]
- [x] Remove "Score: Unit tests catch 0/5. ValidationForge catches 5/5" from README (implies measured comparison)
- [x] Ensure README language describes FEATURES, not RESULTS
- [x] Remove any benchmarking language that implies execution
Status: **DONE**

## Phase 2: Skill Content Audit (5 representative skills)
- [x] `e2e-validate/SKILL.md` — orchestrator: all 8 workflows, 6 refs exist
- [x] `functional-validation/SKILL.md` — fixed broken platform-routing cross-refs
- [x] `web-validation/SKILL.md` — Playwright MCP tool names verified
- [x] `forge-setup/SKILL.md` — workflow steps match actual files
- [x] `ios-validation/SKILL.md` — simctl/xcodebuild references verified
Status: **DONE**

## Phase 2b: Full Command Cross-Reference Audit
- [x] All 15 commands audited
- [x] All agent references (5) verified — files exist
- [x] All skill references (7 unique) verified — files exist
- [x] All rule references (8) verified — files exist
- [x] Zero broken cross-references found
Status: **DONE**

## Phase 3: Install Plugin Locally
- [x] Created symlink: `~/.claude/plugins/cache/validationforge/validationforge/1.0.0` → actual directory
- [x] Registered in `installed_plugins.json` as `validationforge@validationforge` (scope: user)
- [x] Verified symlink resolves: all 40 skills, 15 commands, 5 agents, 8 rules, 7 hooks accessible
- [ ] Verify Claude Code recognizes the plugin (requires session restart)
- [ ] Verify hooks load (requires session restart)
Status: **PARTIALLY DONE** — registration complete, live load untested

## Phase 4: Run Against Real Project (blog-series/site)
- [x] Execute VF methodology manually against blog-series/site
- [x] Platform detection: Web (Next.js 15)
- [x] Build verification: `pnpm build` — 27 pages, exit code 0
- [x] Server startup: localhost:3847, HTTP 200
- [x] Playwright MCP validation: homepage (18 posts), post page (full article), post-to-post navigation
- [x] Evidence captured: 4 screenshots + inventory in `e2e-evidence/web-validation/`
- [x] Verdict written: PASS on all 6 criteria (`e2e-evidence/web-validation/VERDICT.md`)
- [x] Expand validation to all 18 posts, error states, responsive checks
  - 18/18 posts HTTP 200 via curl
  - Deep content verification: Posts 01, 09, 18 via Playwright MCP
  - 404 error handling: `/posts/post-99-nonexistent` returns 404
  - Responsive: mobile 375x812 on homepage, Post 07, about page
  - About page: renders correctly
  - Evidence: 6 screenshots in `e2e-evidence/web-validation/expanded/`
  - Verdict: PASS 7/7 criteria (`expanded/VERDICT.md`)
- [ ] Run `/validate` as automated plugin command (requires live plugin load after session restart)
- [ ] Run `/validate-benchmark` to produce a real benchmark score
Status: **PARTIAL** — expanded manual validation PASS (18/18 posts + responsive + errors), automated command and benchmark pending session restart

## Phase 5: Update README with Honest Status
- [x] Add "Verification Status" section documenting what's been tested vs not
- [x] Replace fabricated comparison with honest feature descriptions
- [x] Fix install instructions (removed references to nonexistent GitHub repo and install.sh)
- [x] Document known limitations
Status: **DONE**

## Decisions
- 2026-03-09: Reflection identified 2 broken hooks (fixed), dishonest README claims, zero end-to-end testing
- 2026-03-09: Approach — fix honesty issues first, then attempt real installation
