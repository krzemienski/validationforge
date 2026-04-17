# Project Changelog

All notable changes to ValidationForge.

Format: loose semver; dates ISO 8601; newest first.

---

## 2026-04-17 — Plugin Audit Consolidation Release

**Scope**: 34-commit session consolidating 10 worktrees, auditing all 52 skills to Grade A,
and producing a productionized docs + plugin state. Published as a fast-forward push from
`main` → `origin/audit/plugin-improvements`.

### Added

- **CONSENSUS engine** (3 skills from merged worktree 019):
  - `consensus-engine` — orchestrate N independent validators assessing the same feature
  - `consensus-synthesis` — synthesize N per-validator verdicts into a confidence-scored CONSENSUS verdict
  - `consensus-disagreement-analysis` — root-cause analysis when validators disagree
- **Evidence dashboard** (skill from merged worktree 012):
  - `evidence-dashboard` — structured HTML + markdown dashboard of captured validation evidence
  - `/validate-dashboard` command to trigger dashboard generation
- **Ecosystem integration guides** (from merged worktree 013):
  - `docs/integrations/vf-with-omc.md` — OMC multi-agent orchestration hand-off
  - `docs/integrations/vf-with-ecc.md` — ECC code-quality gates → VF runtime validation
  - `docs/integrations/vf-with-superpowers.md` — TDD methodology → VF real-system validation
- **Documentation site (Astro Starlight)** from merged worktree 015:
  - Full docs site at `site/` with 82 pages (up from 37 at session start)
  - Skill + command MDX coverage: 52/52 skills, 19/19 commands
- **E2E pipeline verification** scaffold + harness from merged worktree 001
- **Plugin live-load verification** from merged worktree 002 (5 phases: standalone hooks,
  CLAUDE_PLUGIN_ROOT resolution, live-session proxies, subagent session limits)
- **10 skill deep-review findings** on disk under `e2e-evidence/skill-review/` from worktree 004

### Fixed — CRITICAL

- **preflight iOS detection** (`skills/preflight/references/auto-fix-actions.md`):
  Replaced broken `[ -d "*.xcodeproj" ]` quoted-glob test with `shopt -s nullglob` +
  array-length check. Without this fix, every iOS project that didn't use Swift Package
  Manager at the root silently routed to `PLATFORM=unknown`, skipping the iOS preflight
  checklist entirely.
- **e2e-validate preflight gate** (`skills/e2e-validate/SKILL.md`, `workflows/full-run.md`,
  `workflows/ci-mode.md`): Previously `preflight` was listed only as a Related Skill and
  was never invoked. Now explicit Iron-Rule-4 gate with CLEAR/WARN/BLOCKED verdicts,
  `--preflight` flag, and `--skip-preflight` emergency override. CI mode exits code 2 on
  BLOCKED.

### Fixed — HIGH

- **cli-validation exit codes**: Replaced `$BINARY ... 2>&1 | tee FILE; echo "Exit: $?"`
  (captures tee's exit, always 0) with redirect-then-echo pattern that preserves the
  binary's exit code. Prevents silent failure masking.
- **ios-validation idb flags**: Replaced non-existent `--x/--y` named flags with positional
  coordinates; replaced `--udid booted` pseudonym with real UDID capture via
  `xcrun simctl list devices booted`.
- **web-validation MCP params**: Corrected `includeStatic=false` → `static=false`
  (canonical Playwright MCP param name verified via Context7); added missing
  `element="..."` kwarg to `browser_click` calls; removed non-existent `filename=`
  parameter from `browser_console_messages`.
- **api-validation auth order**: Added prerequisite note that Step 3 (login) must run
  before Step 2 (CRUD) since Step 2 uses `$TOKEN` created by Step 3.
- **fullstack-validation delete cascade**: Activated Layer-4 Step-1 from a stub comment
  into an actual `browser_click` call; fixed literal `DELETED_ID` placeholder to use the
  real resource ID from the prior create step.
- **functional-validation gitignore guidance**: Replaced `echo "e2e-evidence/" >> .gitignore`
  (discards all evidence) with project-compliant pattern that preserves `report.md` and
  `evidence-inventory.txt` verdict artifacts.
- **no-mocking-validation-gates catalog**: Split pattern catalog into "hook-enforced" vs
  "Iron Rule (not hook-enforced)" sections to prevent false claims of hook-based protection
  for patterns like `__mocks__/`, `*_test.py`, Java/Kotlin/Rust test files, `conftest.py`,
  `testing/`, `factories/`.
- **gate-validation-discipline term**: Replaced stale "Ultrawork" with canonical "Team mode"
  throughout `references/gate-integration-examples.md`.

### Fixed — Style / Clarity

- 7 B-grade skills upgraded to A via targeted SKILL.md edits:
  `chrome-devtools` (WHY vs Playwright), `design-token-audit` (regex-quantifier clarification),
  `e2e-testing` (strategy-vs-execution WHY), `full-functional-audit` (Phase 3/4/5 subsections),
  `validate-audit-benchmarks` (expanded body), `web-testing` (decision-matrix north-star rule),
  `evidence-dashboard` (When to Use / When NOT).
- Sweeps across reference docs for residual `includeStatic`, `--udid booted`, `Ultrawork`
  patterns in `e2e-validate/references/*`, `functional-validation/references/*`,
  `visual-inspection/SKILL.md`, `site/src/content/docs/skills/*.mdx`.

### Documentation

- **Inventory accuracy**: `SKILLS.md`, `COMMANDS.md`, `CLAUDE.md`, `README.md` brought into
  alignment with on-disk counts (52 skills, 19 commands, 7 hooks, 7 agents, 9 rules).
- **Site MDX coverage**: Scaffolded 42 new skill pages + 3 new command pages so the site now
  exhaustively covers every active skill and command.
- **Site stale sweep**: Corrected 3 `includeStatic` occurrences, 5 `idb --udid booted`
  patterns, preflight verdict-enum drift in MDX pages.
- **Root cleanup**: Archived 8 transient agent-artifact `.md` files (progress.md,
  whats-next.md, findings.md, task_plan.md, MERGE_REPORT.md, CAMPAIGN_STATE.md,
  LAUNCH-PLAN.md, skill-review-results.md) to `plans/260417-1359-doc-audit/archive/`.
  Canonical root docs (CLAUDE, README, CONTRIBUTING, PRD, ARCHITECTURE, SPECIFICATION,
  PRIVACY, SKILLS, COMMANDS) retained.

### Platform Parity

- **OpenCode plugin** (`.opencode/`): Added 7 missing skill symlinks
  (ai-evidence-analysis, coordinated-validation, django-validation, flutter-validation,
  react-native-validation, rust-cli-validation, team-validation-dashboard) + 2 missing
  command symlinks (vf-telemetry, validate-team-dashboard). Final parity: 52 skills,
  19 commands mirrored.

### Verified

- **Plugin install smoke test**: `.claude-plugin/plugin.json` + `marketplace.json` parse
  clean; all resource directories present; hook `node --check` passes on all 7 .js files;
  all 52 SKILL.md files have valid YAML frontmatter.
- **Site build**: `npm run build` → 82 pages in 2.61s, zero errors, Pagefind index built,
  sitemap generated.
- **Project benchmark**: Grade A 96/100 held across every session checkpoint
  (post-merge-4, post-critical-fixes, post-all-fixes, post-worktree-cleanup).
- **Playwright MCP tool verification**: `browser_fill_form` confirmed canonical per
  Context7 `/microsoft/playwright-mcp` README — prior audit false positive cleared.

### Removed

- 10 auto-claude worktrees pruned (001, 002, 003, 004, 005, 006, 012, 013, 015, 019).
- 10 auto-claude branches deleted after successful merge/cherry-pick/abandonment.

### Acknowledged Non-Blockers

- `skill-audit-workspace/` contains stale "Ultrawork" snapshots from prior benchmark runs;
  these are caches, not live skills — pruneable in future housekeeping.
- `cli-validation` lines 173/177 use `| tee` for JSON/CSV output without `$?` capture
  (stylistic only, not a correctness bug — exit-code-masking fix landed elsewhere).
- Live plugin install against a fresh Claude Code session was not exercised this release;
  manifest + resource validity was verified structurally.

---

## Older releases

Pre-2026-04-17 history not back-filled into this changelog. See `git log` for full commit
history. The `audit/plugin-improvements` branch carries every commit from project inception
through the 2026-04-17 release.
