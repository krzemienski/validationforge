# ValidationForge Audit Plan — Dual-Platform Plugin System

## RALPLAN Decision Record

### Principles
1. **CC-Primary, OC-Secondary** — Claude Code hooks are the production enforcement layer; OpenCode plugin is a sync target
2. **Audit What Exists** — 838 LOC of executable code, not 22K LOC of markdown. Scope to behavior, not prose
3. **Checkpoint Everything** — No phase should lose state to context compaction
4. **Measurable Gates** — Replace absolutes with prioritized exit criteria (P0 fixed, P1 documented)
5. **Deferred OC Security** — OC plugin sanitization is a separate track; don't block CC audit on it

### Decision Drivers
1. Red-team found the existing plan audits a CC product as if it were pure OC — identity crisis blocks every phase
2. 67+ files in Phase 4 scope guaranteed context compaction data loss without checkpointing
3. Phase 5/6 benchmarks were unexecutable prose — need tooling, not documents

### Viable Options

**Option A: Full Rewrite (8 phases, dual-platform framing, benchmark skill)**
- Pros: Addresses all 15 red-team findings, preserves audit granularity, builds reusable tooling
- Cons: Higher upfront effort (~12h), requires /skill-creator dependency

**Option B: Patch Existing Plan (fix identity, add checkpoints, defer benchmarks)**
- Pros: Faster (~4h), minimal structural change
- Cons: Leaves C3 (unexecutable benchmarks) and C4 (no checkpointing) as known debt; OC-centric framing still leaks through examples and context sections
- **Invalidated**: Patching cannot fix the identity section, context section, plugin_format_spec examples, and OC-specific constraints without effectively rewriting 80%+ of the document

**Option C: Split into two plans (CC audit + OC audit)**
- Pros: Clean separation, no cross-contamination
- Cons: Duplicates Phase 0-2 work, loses the unified inventory view needed to detect enforcement duplication (H7)
- **Invalidated**: The duplicate-enforcement finding (H7) requires a single audit that sees both platforms simultaneously

**Selected: Option A**

---

## Identity

ValidationForge is a **dual-platform validation enforcement system** for LLM coding agents:

| Platform | Location | Role | LOC |
|----------|----------|------|-----|
| **Claude Code** (primary) | `hooks/`, `skills/`, `commands/`, `rules/`, `agents/`, `scripts/` | Production enforcement via 7 hooks, 40 skills, 15 commands, 8 rules, 5 agents, 5 shell scripts | ~838 executable |
| **OpenCode** (secondary) | `.opencode/plugins/validationforge/` | Sync target mirroring CC enforcement via 2 TypeScript files | ~275 |

The CC layer is the source of truth. The OC layer is a port. This audit treats them accordingly.

---

## Context — Verified Inventory

### Claude Code Layer
| Category | Count | Location | Notes |
|----------|-------|----------|-------|
| Hooks | 7 | `hooks/*.js` | 618 LOC total. JS, run via CC hook system |
| Skills | 40 | `skills/*/SKILL.md` | Markdown with YAML frontmatter |
| Commands | 15 | `commands/*.md` | Slash commands |
| Rules | 8 | `rules/*.md` | Injected context |
| Agents | 5 | `agents/` | Agent definitions |
| Shell scripts | 5 | `scripts/` | install.sh, health-check.sh, sync-opencode.sh, evidence-collector.sh, detect-platform.sh |

### OpenCode Layer
| Category | Count | Location | Notes |
|----------|-------|----------|-------|
| Plugin files | 2 | `.opencode/plugins/validationforge/*.ts` | TypeScript, OC plugin SDK |
| Config | 1 | `opencode.json` | Plugin registration |
| Plugin dir | 1 | `.opencode/` | Exists and is populated |

### Out of Scope
- Markdown documentation (~22K LOC) — audited for accuracy in Phase 3A, not for "code quality"
- OC plugin security fixes (H6) — deferred to separate OC security track
- MCP servers, built-in tools, external integrations

---

## Phase 0: Inventory and Scoping

**Goal**: Classify every file. Produce a single scoping document.

### Steps
1. Read full directory tree
2. Classify each file: CC Hook / CC Skill / CC Command / CC Rule / CC Agent / Shell Script / OC Plugin / OC Config / Documentation / Other
3. For CC hooks: catalog hook type (pre/post), trigger event, file target
4. For CC skills: verify SKILL.md frontmatter (`name`, `description`), confirm dir name matches
5. For CC commands: catalog slash syntax, arguments, agent routing
6. For shell scripts: catalog purpose, inputs, external calls (curl, wget, etc.)
7. For OC plugin: catalog exported hooks, tools, imports. Note: analysis only, fixes deferred
8. Cross-reference: any CC hook logic duplicated in OC plugin? (feeds H7 finding)

### Deliverable
`audit-artifacts/phase-0-inventory.md` — file classification table, scope in/out, primitive counts

### Gate
Scoping document complete. Every file classified. Shell scripts included in scope.

---

## Phase 1: Deep Analysis

**Goal**: Structured analysis of all CC enforcement code + OC plugin surface scan.

### Steps — CC Hooks (primary)
For each of the 7 hooks:
1. Read complete file. Map: trigger event, decision logic, exit codes, stderr output
2. Flag: missing error handling, inconsistent exit code usage, silent failures, edge cases in pattern matching
3. Verify hook output protocol compliance (exit 2 + stderr to block, exit 0 silent to allow)
4. Map data flow: what input does the hook receive? What does it inspect? What does it output?

### Steps — CC Skills
For each of the 40 skills:
1. Read SKILL.md. Verify frontmatter validity
2. Flag: stale tool references, references to nonexistent files, descriptions >1024 chars
3. Categorize by function: platform validation / quality gate / analysis / specialized / operational / forge orchestration

### Steps — CC Commands
For each of the 15 commands:
1. Read file. Verify frontmatter, argument interpolation
2. Flag: missing descriptions, broken agent routing

### Steps — Shell Scripts (NEW — addresses H8)
For each of the 5 scripts:
1. Read complete file
2. Flag: unsanitized inputs, SSRF vectors (especially health-check.sh curl calls), path traversal, missing input validation
3. Rank by trust level: install.sh (highest — modifies system), health-check.sh (network calls), others
4. Document: what each script does, what it trusts, what it doesn't validate

### Steps — OC Plugin (surface scan only)
1. Read both .ts files
2. Catalog: hooks registered, tools defined, args schemas
3. Note enforcement logic that duplicates CC hooks (H7)
4. Note unsanitized args (H6) — document but DO NOT fix (deferred)
5. Verify opencode.json registration matches actual files

### Steps — Rules + Agents
1. Read each rule/agent file. Catalog purpose and scope
2. Flag contradictions between rules (M15)

### Deliverable
`audit-artifacts/phase-1-analysis.md` — organized by category, with findings table per file

### Gate
Analysis document saved. Every in-scope file read. All flags documented with file:line references.

---

## Phase 2: Git Hygiene and Baseline

**Goal**: Clean state, rollback capability, working branch.

### Steps
1. Review git state: uncommitted changes, branch structure
2. Ensure `.gitignore` covers: `node_modules/`, `dist/`, `.env`, `*.local`, build artifacts, `.omc/state/`
3. Commit all current working state
4. Tag baseline: `v0-pre-audit` (rollback point)
5. Create or confirm working branch: `audit/plugin-improvements`
6. Document rollback procedure:
   ```
   git checkout main
   git reset --hard v0-pre-audit
   # or: git revert audit/plugin-improvements..HEAD
   ```

### Deliverable
Clean git state. Tag exists. Rollback instructions in `audit-artifacts/rollback.md`.

### Gate
`git status` clean. `v0-pre-audit` tag exists. `audit/plugin-improvements` branch active. Rollback doc written.

---

## Phase 3A: Documentation Overhaul

**Goal**: Accurate docs describing actual behavior. **This phase OWNS README.md writes.**

### Steps
1. Write/update `README.md`:
   - Identity: dual-platform (CC primary, OC secondary)
   - What exists: hooks, skills, commands, rules, agents, shell scripts
   - Installation for CC: hook placement, skill registration
   - Installation for OC: plugin placement, opencode.json config
   - Quick start for each primitive type
   - Troubleshooting common issues
   - **All content based on Phase 1 analysis, not aspirational**
2. Write/update `ARCHITECTURE.md`:
   - CC hook lifecycle: trigger → evaluate → exit code → effect
   - CC skill lifecycle: directory discovery → frontmatter parse → context injection
   - OC plugin lifecycle (brief, noting it mirrors CC)
   - Data flow diagrams for enforcement pipeline
   - Dependency map between components
3. Write `SKILLS.md`: index of all 40 skills with name, description, category
4. Write `COMMANDS.md`: index of all 15 commands with syntax, description, agent routing
5. Verify every installation step by executing it

### Deliverable
README.md, ARCHITECTURE.md, SKILLS.md, COMMANDS.md — all describing actual behavior

### Gate
A developer with zero context can install and invoke the CC hooks using only README.md. Phase 3B does NOT write to README.md (reviews only).

---

## Phase 3B: CC Hook Format Compliance + Shell Script Audit

**Goal**: Fix CC hook issues. Audit shell scripts. OC plugin format noted but not fixed.

### Steps — CC Hooks
1. Audit each hook against CC hook output protocol:
   - PreToolUse: exit 2 + stderr to block, JSON `permissionDecision: "ask"` to prompt, exit 0 silent to allow
   - PostToolUse: exit 2 + stderr for feedback, exit 0 silent otherwise
   - Other triggers: exit 0 + stdout for context injection
2. Fix any protocol violations
3. Standardize error handling across all 7 hooks

### Steps — Shell Scripts (addresses H8)
1. Audit `install.sh`: validate all paths, check for arbitrary code execution vectors
2. Audit `health-check.sh`: validate URLs before curl, check for SSRF (user-controlled URL → curl)
3. Audit `sync-opencode.sh`: validate source/dest paths
4. Audit `evidence-collector.sh`: validate file paths, check for path traversal
5. Audit `detect-platform.sh`: review detection logic for false positives
6. Fix all identified issues

### Steps — OC Plugin (document only)
1. Note format compliance status against OC plugin SDK spec
2. Note: shell.env hook type validity (M13)
3. Do NOT fix — document findings for OC security track

### Steps — README Review
1. Review README.md written by Phase 3A for technical accuracy
2. File issues or comments — do NOT directly edit README.md (3A owns it)

### Deliverable
Fixed CC hook files. Fixed shell scripts. OC plugin findings document.

### Gate
All CC hooks pass protocol compliance check. All shell scripts have validated inputs. No write conflicts with Phase 3A.

---

## Phase 4: Full CC Audit and Sanitization

**Goal**: Deep sanitization of CC hooks. Checkpointed progress.

### Scope
CC hooks only (7 files, ~618 LOC). OC plugin deferred.

### Checkpointing (addresses C4)
After auditing each file, write progress to `audit-artifacts/audit-progress.json`:
```json
{
  "phase": 4,
  "files_completed": ["hooks/block-test-files.js", "hooks/evidence-gate-reminder.js"],
  "files_remaining": ["hooks/validation-not-compilation.js", ...],
  "findings_count": 12,
  "last_updated": "2026-04-08T15:00:00Z"
}
```
On context recovery: read this file first, resume from `files_remaining`.

### Steps
For each CC hook:
1. Read complete file
2. Verify: input validation, pattern matching correctness, exit code usage, error handling
3. Check: no silent failures, no swallowed errors, consistent stderr messaging
4. Check: no hardcoded paths that break on different systems
5. Apply fixes
6. Update `audit-progress.json`

For cross-cutting concerns:
7. Check for duplicate enforcement logic between hooks (e.g., two hooks checking for test files)
8. Check for contradictions between hooks and rules (M15)
9. Standardize error message format across all hooks

### Deliverable
Sanitized hook files. Completed `audit-progress.json`. Findings summary.

### Gate
All P0 findings fixed. All P1 findings documented. No regressions in existing hook behavior. `audit-progress.json` shows all files completed.

---

## Phase 5: Benchmark Skill Creation

**Goal**: Build executable benchmark tooling using /skill-creator, not prose checklists.

### Why Not Prose (addresses C3)
The previous plan defined 400+ criteria as markdown text. Skills are markdown instructions — they can't "run" benchmarks. The agent can't execute a prose rubric. We need a skill that orchestrates actual validation.

### Steps
1. Use `/skill-creator` to build `validate-audit-benchmarks` skill:
   - Input: category (hooks / skills / commands / scripts) or "all"
   - For hooks: invoke each hook with test inputs, verify exit codes and stderr output
   - For skills: verify frontmatter, check file references exist, measure description length
   - For commands: verify frontmatter, check agent routing targets exist
   - For scripts: run with `--help` or `--dry-run` if supported, verify exit codes
   - Output: structured results per file with pass/fail/score
2. Define scoring rubric embedded in the skill:
   - Correctness (40%): does it do what it claims?
   - Format compliance (20%): follows platform conventions?
   - Error handling (20%): graceful failure?
   - Security posture (20%): inputs validated?
3. Run baseline benchmark on current state. Save results to `audit-artifacts/benchmark-baseline.json`

### Deliverable
`skills/validate-audit-benchmarks/SKILL.md` + supporting scripts. Baseline results JSON.

### Gate
Benchmark skill runs end-to-end. Baseline scores recorded for all in-scope files.

---

## Phase 6: Improvement Pass

**Goal**: Measurable improvements using benchmark skill from Phase 5.

### Steps
1. Run benchmark skill. Identify all files below 70% score
2. Prioritize by user impact: hooks that fire on every tool call > hooks that fire on specific tools > skills > commands > scripts
3. For each below-threshold file:
   - Read benchmark failure details
   - Fix specific issues (not speculative improvements)
   - Re-run benchmark on that file
   - Record delta
4. After all fixes: run full benchmark suite
5. Compare final vs baseline. Document per-file deltas in `audit-artifacts/benchmark-deltas.md`

### Deliverable
Improved files. `benchmark-deltas.md` showing measurable improvement per file.

### Gate
All files at or above 70% threshold. No file regressed from baseline. Deltas documented.

---

## Phase 7: Final Validation and Release

**Goal**: End-to-end validation with prioritized exit criteria.

### Steps
1. Run complete benchmark suite — save final results
2. Compare final vs baseline vs Phase 6 results
3. Verify end-to-end (CC path):
   - Hooks load and fire on expected triggers
   - Skills discoverable and loadable
   - Commands executable via slash syntax
   - Shell scripts run without error on clean checkout
4. Verify documentation accuracy:
   - README installation steps work on clean environment
   - ARCHITECTURE.md matches actual code paths
5. Commit final state
6. Tag release: `v1-post-audit`

### Exit Criteria (prioritized, not absolute — addresses H9)

**Must pass (blocks release):**
- All P0 findings from Phase 4 fixed and verified
- No hook regression (hooks that worked before still work)
- README installation succeeds on clean checkout
- Benchmark scores >= baseline for all files

**Should pass (documented if not):**
- All P1 findings fixed or documented with rationale
- All docs match actual behavior
- Benchmark scores >= 70% for all files

**Nice to have (no release block):**
- All P2 findings addressed
- Benchmark scores >= 90%

### Deliverable
Final benchmark report. Tagged release. Change summary.

### Gate
All "must pass" criteria met. Any unmet "should pass" items documented in release notes.

---

## Constraints

1. Read every file completely before forming conclusions. Never infer file contents.
2. Do not begin implementation until Phase 1 analysis is complete and saved.
3. Respect phase gates — do not advance until gate is satisfied.
4. **Checkpoint mandate**: any phase touching >5 files MUST maintain `audit-progress.json` (addresses C4).
5. Commit at phase boundaries with meaningful messages explaining what changed and why.
6. Never introduce dependencies not already in the codebase without explicit justification.
7. If a phase gate cannot be met, stop and report the blocker with evidence.
8. All documentation must describe actual behavior, not aspirational behavior.
9. **File ownership**: Phase 3A owns README.md writes. Phase 3B reviews but does not write to it (addresses C5).
10. **OC plugin security fixes are OUT OF SCOPE** — document findings, defer fixes to OC security track (addresses H6).
11. **Shell scripts are IN SCOPE** — they are enforcement infrastructure (addresses H8).
12. Do not conflate CC hooks with OC plugin hooks. They use different protocols, different languages, different execution models.

---

## Output Format

| Phase | Deliverable |
|-------|-------------|
| 0 | `audit-artifacts/phase-0-inventory.md` — file classification, scope |
| 1 | `audit-artifacts/phase-1-analysis.md` — per-file findings |
| 2 | Clean git state, `v0-pre-audit` tag, `audit-artifacts/rollback.md` |
| 3A | README.md, ARCHITECTURE.md, SKILLS.md, COMMANDS.md |
| 3B | Fixed CC hooks, fixed shell scripts, OC findings doc |
| 4 | Sanitized hooks, `audit-progress.json`, findings summary |
| 5 | Benchmark skill + baseline results |
| 6 | Improved files + `benchmark-deltas.md` |
| 7 | Final benchmark report, `v1-post-audit` tag, release notes |

All artifacts go to `audit-artifacts/` unless they are user-facing docs (README, ARCHITECTURE, etc.).
