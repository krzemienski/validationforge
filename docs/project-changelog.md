# Project Changelog

All notable changes to ValidationForge.

Format: loose semver; dates ISO 8601; newest first.

---

## 2026-04-17 — Post-Review Remediation Release

**Scope**: Full-codebase `/start:review` produced 24 findings (1 CRITICAL, 10 HIGH,
8 MEDIUM, 6 LOW). All findings addressed in 9 fix commits between `398d638` and
`3a796d6`, pushed to `main`. Review synthesis: [`plans/reports/review-260417-1631-full-codebase.md`](../plans/reports/review-260417-1631-full-codebase.md).

### Fixed — CRITICAL

- **OpenCode plugin silent no-op on test-file blocking** (`.opencode/plugins/validationforge/index.ts:70`, review ID C1).
  Handler was registered on `"permission.ask"`, which is not a documented OpenCode
  event — the authoritative spec uses `permission.asked` / `permission.replied` (past
  tense). Moved the gate to `"tool.execute.before"` — the correct enforcement point
  regardless of permission-prompt flow. Commit `a24019b`.

### Fixed — HIGH

- **OpenCode custom tools fail to register** (H1). Replaced `tool.schema.string()`
  (not in the public API) with `zod` schemas (`zod@3.23.8` already declared) and
  corrected the import from `"@opencode-ai/plugin/tool"` subpath to
  `"@opencode-ai/plugin"`. Commit `a24019b`.
- **Architecture doc rot — phantom `vm.runInNewContext` bridge** (`README.md:207,335,411`;
  `ARCHITECTURE.md:43,204-213`; H2). README and ARCHITECTURE described a "CommonJS
  bridge using vm.runInNewContext()" at `hooks/patterns.js` that does not exist.
  Actual file lives at `hooks/lib/patterns.js`, is plain pre-compiled TypeScript
  output (`tsc --module commonjs`), and contains no `vm`, no sandbox, no runtime
  bridge. Fiction removed; real regen command documented. See ADR `docs/adr/001-patterns-no-vm-bridge.md`.
  Commit `3db4e6e`.
- **Installer hardened against curl-pipe supply-chain risks** (`install.sh`, H3+H4+M5+M6):
  pinned clone to `$VF_REF` (defaults `v$VF_VERSION`); `https://github.com/`
  allowlist on `VF_SOURCE` unless `VF_ALLOW_ALT_SOURCE=1`; `/tmp` install requires
  `VF_ALLOW_TMP_INSTALL=1`; atomic `ln -sfn` for plugin cache symlink with
  ownership check; `installed_plugins.json` written via
  `tempfile.mkstemp` + `os.replace` under `fcntl.flock`. New single-page
  `docs/install-security.md`. Commit `4b2dc6d`.
- **Duplicate config-resolution systems consolidated** (`hooks/lib/*.js`, H5+H6).
  `config-loader.js` collapsed to a 3-line compat shim over `resolve-profile.js`;
  added module-level memoization and a `VF_PROFILE=standard` fast path that
  skips fs I/O entirely (in-memory frozen defaults). Estimated ~1-2s/session
  reclaimed at ~50 tool calls. Commit `f99dd6c`.
- **Rule duplication + stale markers + weak skill triggers** (H7+H8+H9).
  Removed `[planned V2.0]` markers on `/forge-execute` (README.md + CLAUDE.md);
  `rules/forge-execution.md` now references `execution-workflow.md` as the
  canonical phase definition rather than duplicating the 7 phases;
  `skills/consensus-engine/SKILL.md` gained 12 trigger phrases + explicit
  negative scope so natural prompts like "get a second opinion" or "catch flaky
  behavior" reliably auto-invoke. Commit `bc7486f`.
- **Test-file blocking silent-broken in stock Claude Code** (`hooks/hooks.json`,
  M2 — promoted from MED to HIGH by authoritative doc check). Matcher was
  `TaskUpdate`, a non-documented tool name — case-sensitive matching meant
  `evidence-gate-reminder.js` never fired for marketplace users. Changed to
  `TodoWrite|TaskUpdate`; hook now parses both payload shapes (TodoWrite's
  `todos[]` array + TaskUpdate's scalar `status`). Commit `5f504b5`.

### Fixed — MEDIUM

- **ReDoS risk in MOCK_PATTERNS** (`hooks/lib/patterns.js` + `.opencode/plugins/validationforge/patterns.ts`, M3).
  Five greedy `.*` quantifiers replaced with bounded alternatives
  (`[^'"]{0,200}`, `[^)]{0,500}`, etc.). Hostile 100k-char input now terminates
  in **0.17ms** vs unbounded backtracking. All 5 legitimate test-code regression
  patterns still match. Commit `effb547`.
- **CWD-relative evidence path** (`hooks/completion-claim-validator.js`, M4).
  `EVIDENCE_DIR = 'e2e-evidence'` was resolved against the hook's inherited CWD,
  so a Bash command that `cd`'d somewhere else silently bypassed the completion
  gate. Now resolves against `CLAUDE_PROJECT_ROOT` → `data.cwd` → `process.cwd()`
  with `stat.size > 0` freshness check. Commit `effb547`.
- **mock-detection scans every pattern on every write** (M7). `.filter` → `.some`
  for short-circuit; 200KB input cap prevents scan on adversarial bundled files.
  Commit `effb547`.
- **Infinite animations flicker under reduced-motion** (M8). HTML artifacts at
  `~/.agent/diagrams/validationforge-hyper-{marketing,deck}.html` now fully
  disable looping animations (cursor blink, pulse, gradient-shift) under
  `prefers-reduced-motion: reduce` instead of just shortening them to 0.01ms.

### Fixed — LOW

- All 7 `agents/*.md` files gained explicit `name:` frontmatter (L1).
- `block-test-files.js` allowlist check replaced with `.some()` short-circuit (L4).
- OpenCode plugin `vf_check_evidence` gained a path-traversal guard on
  `args.journey` (L3).
- `uninstall.sh` consumes a manifest written by `install.sh` so it only removes
  files it tracked — protects user-authored `vf-*.md` rule files that happened
  to share the prefix (L2).
- Deck dot-nav buttons gained `aria-label` derived from slide headings (L5).
- Marketing HTML in-flow links carry an underline by default so colorblind
  readers don't rely on color alone (L6).

### Performance

- Hook per-invocation cost down ~2-5ms per config read with the memoization
  + fast path; `VF_PROFILE=standard` bypasses all fs I/O. Measured on Darwin
  25.5.0 / Node 16.

### Docs

- Added: `docs/install-security.md`, `docs/adr/001-patterns-no-vm-bridge.md`.
- Updated: `README.md`, `ARCHITECTURE.md`, `docs/opencode-plugin-parity.md`
  (patterns.js and hook-name corrections).
- Archived: `plans/reports/review-260417-1631-full-codebase.md` (the review
  synthesis that drove this remediation).

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
