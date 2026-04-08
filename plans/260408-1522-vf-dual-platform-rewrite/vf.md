# ValidationForge Audit Plan — Dual-Platform Plugin System

## Decision Record

### Principles
1. **CC-Primary, OC-Secondary** — Claude Code hooks are the production enforcement layer; OpenCode plugin is a sync target
2. **Audit What Exists** — 752 LOC of executable code, not 22K LOC of markdown. Scope to behavior, not prose
3. **Checkpoint Everything** — No phase should lose state to context compaction
4. **Measurable Gates** — Prioritized exit criteria (P0 fixed, P1 documented), not absolutes
5. **Deferred OC Security** — OC plugin sanitization is a separate track; don't block CC audit on it

### Decision Drivers
1. Red-team found the existing plan audits a CC product as if it were pure OC — identity crisis blocks every phase (C1)
2. 67+ files in Phase 4 scope guaranteed context compaction data loss without checkpointing (C4)
3. Phase 5/6 benchmarks were unexecutable prose — need tooling, not documents (C3)
4. **PostToolUse protocol violation** — 5/7 PostToolUse hooks silently lost (stdout JSON + exit 0 instead of stderr + exit 2). Enforcement reminders never reach agent. This is the single biggest functional bug.
5. **Pattern duplication** — 62 regex patterns hardcoded identically in hooks AND patterns.ts. Drift risk on every update.

### Red-Team Findings Addressed

| ID | Finding | Severity | Addressed In |
|----|---------|----------|-------------|
| C1 | Wrong platform framing | Critical | Identity section, all phases |
| C2 | Phase 0 false inventory claims | Critical | Phase 0 (verified inventory) |
| C3 | Unexecutable benchmarks | Critical | Phase 5 (three-part system) |
| C4 | No checkpointing | Critical | Phase 4 (audit-progress.json) |
| C5 | README write conflict | Critical | Phase 3A/3B ownership split |
| H6 | OC unsanitized args | High | Deferred to OC security track |
| H7 | Duplicate enforcement logic | High | Phase 4 (pattern consolidation) |
| H8 | Shell scripts unaudited | High | Phase 1 + Phase 3B |
| H9 | Impossible gate conditions | High | All gates (prioritized criteria) |
| H10 | No rollback strategy | High | Phase 2 (rollback.md) |
| H11 | No MVP cut | High | Phase 5 MVP scope |
| H12 | Unverifiable Phase 3A gate | High | Gate rewritten |
| M13 | shell.env hook validity | Medium | Phase 1 (document, don't fix) |
| M14 | Fabricated || true finding | Medium | Phase 1 (verify, remove if false) |
| M15 | Constraint contradictions | Medium | Constraints section rewritten |

### Validated Decisions (from interview)

| # | Question | Decision | Rationale |
|---|----------|----------|-----------|
| V1 | Pattern consolidation architecture | Keep patterns.ts + JS wrapper | CC hooks require() a patterns.js wrapper; OC plugin imports .ts directly. No build step. |
| V2 | Top 10 benchmark skills | Auto-select by impact | Use whatever combination of core + platform skills has highest user impact. Not predetermined. |
| V3 | Shell script hardening | Harden both scripts | health-check.sh gets URL scheme whitelist. install.sh gets additional validation. Defense in depth. |
| V4 | PostToolUse fix commit strategy | Two commits: change + verification | First commit fixes all 5 hooks. Second adds verification test. Keeps fix and proof together. |

### Researcher Findings Integrated

| Source | Key Finding | Impact |
|--------|-------------|--------|
| CC Hook Protocol Audit | 5/7 PostToolUse hooks use wrong output protocol — feedback silently lost | Phase 3B P0 fix |
| CC Hook Protocol Audit | 62 regex patterns duplicated across 6 files, drift risk | Phase 4 consolidation |
| CC Hook Protocol Audit | ${CLAUDE_PLUGIN_ROOT} untested in hooks.json | Phase 3B verification |
| Benchmark Feasibility | Three-part system: bash tests + skill + aggregator | Phase 5 architecture |
| Benchmark Feasibility | Hooks 95% testable, skills 60%, commands 65%, rules 0% | Phase 5 scope |
| Benchmark Feasibility | Evaluate top 10 skills by impact, not all 40 | Phase 5 MVP |

---

## Identity

ValidationForge is a **dual-platform validation enforcement system** for LLM coding agents:

| Platform | Location | Role | LOC |
|----------|----------|------|-----|
| **Claude Code** (primary) | `hooks/`, `skills/`, `commands/`, `rules/`, `agents/`, `scripts/` | Production enforcement via 7 hooks, 40 skills, 15 commands, 8 rules, 5 agents, 4 shell scripts | ~618 JS + ~134 shell |
| **OpenCode** (secondary) | `.opencode/plugins/validationforge/` | Sync target mirroring CC enforcement via 2 TypeScript files | ~275 TS |

The CC layer is the source of truth. The OC layer is a port. This audit treats them accordingly.

---

## Verified Inventory

### Claude Code Layer
| Category | Count | Location | LOC | Notes |
|----------|-------|----------|-----|-------|
| Hooks | 7 | `hooks/*.js` | 343 | JS, CC hook system. **5 PostToolUse hooks have protocol violations.** |
| Skills | 40 | `skills/*/SKILL.md` | ~22K | Markdown with YAML frontmatter |
| Commands | 15 | `commands/*.md` | ~3K | Slash commands |
| Rules | 8 | `rules/*.md` | ~2K | Injected context |
| Agents | 5 | `agents/*.md` | ~1K | Agent definitions |
| Shell scripts | 4 | `scripts/*.sh` | 134 | install.sh, health-check.sh, sync-opencode.sh, evidence-collector.sh, detect-platform.sh |
| Hook manifest | 1 | `hooks/hooks.json` | 57 | Uses ${CLAUDE_PLUGIN_ROOT} variable |
| Config | 3 | `config/*.json` | ~60 | strict/standard/permissive enforcement levels |

### OpenCode Layer
| Category | Count | Location | LOC | Notes |
|----------|-------|----------|-----|-------|
| Plugin | 2 | `.opencode/plugins/validationforge/*.ts` | 275 | index.ts (161) + patterns.ts (114) |
| Config | 1 | `opencode.json` | 6 | Plugin registration |

### Shared
| File | Purpose | Used By |
|------|---------|---------|
| `patterns.ts` | Declares 62 regex patterns as "single source of truth" | OC plugin (imports). CC hooks (should require, but currently hardcode duplicates). |

### Out of Scope
- Markdown documentation quality (audited for factual accuracy only, not style)
- OC plugin security fixes (H6) — deferred to separate OC security track
- MCP servers, built-in tools, external integrations

---

## Phase 0: Inventory and Scoping

**Goal**: Classify every file. Produce a single scoping document.

### Steps
1. Read full directory tree
2. Classify each file: CC Hook / CC Skill / CC Command / CC Rule / CC Agent / Shell Script / OC Plugin / OC Config / Documentation / Other
3. For CC hooks: catalog hook type (pre/post), trigger event, file target, exit code behavior
4. For CC skills: verify SKILL.md frontmatter (`name`, `description`), confirm dir name matches
5. For CC commands: catalog slash syntax, arguments, agent routing
6. For shell scripts: catalog purpose, inputs, external calls (curl, wget, etc.)
7. For OC plugin: catalog exported hooks, tools, imports. Note: analysis only, fixes deferred
8. Cross-reference patterns: identify all files containing hardcoded regex arrays that match patterns.ts (feeds H7/Phase 4)

### Deliverable
`audit-artifacts/phase-0-inventory.md` — file classification table, scope in/out, primitive counts

### Gate
- [ ] Scoping document complete
- [ ] Every file classified (no unknowns)
- [ ] Shell scripts explicitly in scope

---

## Phase 1: Deep Analysis

**Goal**: Structured analysis of all CC enforcement code + OC plugin surface scan.

### Steps — CC Hooks (primary)
For each of the 7 hooks:
1. Read complete file. Map: trigger event, decision logic, exit codes, output channel (stdout vs stderr)
2. Flag: **PostToolUse protocol violations** (stdout JSON + exit 0 instead of stderr + exit 2)
3. Flag: missing error handling, inconsistent exit codes, silent failures, edge cases
4. Verify hook output protocol compliance per CC spec:
   - PreToolUse: `hookSpecificOutput.permissionDecision` via stdout + exit 0
   - PostToolUse: stderr + exit 2 for feedback, or silent exit 0
   - Other: stdout for context injection + exit 0
5. Map data flow: stdin JSON → parse → evaluate → exit code + output channel

### Steps — CC Skills
For each of the 40 skills:
1. Read SKILL.md. Verify frontmatter validity (`name` matches dir, `description` ≤1024 chars)
2. Flag: stale tool references, references to nonexistent files, broken reference paths
3. Categorize by function: platform validation / quality gate / analysis / specialized / operational / forge orchestration

### Steps — CC Commands
For each of the 15 commands:
1. Read file. Verify frontmatter, argument interpolation safety
2. Flag: missing descriptions, broken agent routing targets

### Steps — Shell Scripts (addresses H8)
For each of the 4 scripts:
1. Read complete file
2. Flag: unsanitized inputs, SSRF vectors (health-check.sh: `$1` passed directly to curl), path traversal, missing input validation
3. Rank by trust level: install.sh (highest — modifies system + clones repo), health-check.sh (network calls), others
4. Document: what each script does, what it trusts, what it doesn't validate

### Steps — OC Plugin (surface scan only)
1. Read both .ts files
2. Catalog: hooks registered, tools defined, args schemas
3. Note enforcement logic duplicated from CC hooks (H7): `isBlockedTestFile`, `detectMockPatterns`, `isBuildSuccess`, `isCompletionClaim`
4. Note `shell.env` hook (line 143 of index.ts) — not in documented OC hook list (M13). Document, don't fix.
5. Note unsanitized args in `vf_validate` tool (line 33: `--platform ${args.platform}` — shell injection via string interpolation). Document, don't fix (H6 deferred).
6. Verify opencode.json registration matches actual files

### Steps — Rules + Agents
1. Read each rule/agent file. Catalog purpose and scope
2. Flag contradictions between rules (M15)
3. Verify previously reported `|| true` finding (M14) — search hooks.json for `|| true`. If absent, mark as fabricated.

### Deliverable
`audit-artifacts/phase-1-analysis.md` — organized by category, with per-file findings table including file:line references

### Gate
- [ ] Analysis document saved
- [ ] Every in-scope file read (no file unread)
- [ ] All flags documented with file:line references
- [ ] PostToolUse protocol status documented per hook

---

## Phase 2: Git Hygiene and Baseline

**Goal**: Clean state, rollback capability, working branch.

### Steps
1. Review git state: uncommitted changes, branch structure
2. Ensure `.gitignore` covers: `node_modules/`, `dist/`, `.env`, `*.local`, build artifacts, `.omc/state/`, `audit-artifacts/`
3. Commit all current working state
4. Tag baseline: `v0-pre-audit` (rollback point)
5. Create or confirm working branch: `audit/plugin-improvements`
6. Write rollback procedure to `audit-artifacts/rollback.md`:
   ```
   git checkout main && git reset --hard v0-pre-audit
   ```

### Deliverable
Clean git state. Tag exists. Rollback doc.

### Gate
- [ ] `git status` clean
- [ ] `v0-pre-audit` tag exists
- [ ] `audit/plugin-improvements` branch active
- [ ] `audit-artifacts/rollback.md` written

---

## Phase 3A: Documentation Overhaul

**Goal**: Accurate docs describing actual behavior. **This phase OWNS all documentation file writes.**

### Steps
1. Write/update `README.md`:
   - Identity: dual-platform (CC primary, OC secondary)
   - What exists: hooks (7), skills (40), commands (15), rules (8), agents (5), shell scripts (4)
   - Installation for CC: plugin placement, hook registration via hooks.json
   - Installation for OC: plugin placement in `.opencode/plugins/`, opencode.json config
   - Quick start for each primitive type
   - Troubleshooting common issues
   - **All content based on Phase 1 analysis, not aspirational**
2. Write/update `ARCHITECTURE.md`:
   - CC hook lifecycle: hooks.json registration → stdin JSON → evaluate → exit code + output channel
   - CC skill lifecycle: `skills/*/SKILL.md` → frontmatter parse → context injection on demand
   - OC plugin lifecycle (brief, noting it mirrors CC via patterns.ts import)
   - Pattern sharing: patterns.ts as single source, CC hooks require() it, OC plugin imports it
   - Data flow diagrams for enforcement pipeline
3. Write `SKILLS.md`: index of all 40 skills (name, description, category)
4. Write `COMMANDS.md`: index of all 15 commands (syntax, description, agent routing)
5. Verify every CC installation step by executing it in a clean directory

### Deliverable
README.md, ARCHITECTURE.md, SKILLS.md, COMMANDS.md

### Gate

<validation_gate id="VG-3A" blocking="true" platform="cli">
  <prerequisites>Phase 1 analysis document exists at audit-artifacts/phase-1-analysis.md</prerequisites>
  <execute>
    Run install.sh in a clean tmpdir:
    ```bash
    tmpdir=$(mktemp -d) && cd "$tmpdir" && git init &&
    bash /path/to/validationforge/install.sh 2>&1 | tee audit-artifacts/vg3a-install-output.txt
    ```
  </execute>
  <pass_criteria>
    - [ ] install.sh exits 0
    - [ ] ~/.claude/plugins/validationforge/ exists with hooks/, skills/, commands/
    - [ ] ~/.claude/rules/vf-*.md files installed (count matches rules/ count)
    - [ ] ~/.claude/.vf-config.json exists with valid JSON
    - [ ] All 4 docs written, describing actual behavior (not aspirational)
    - [ ] Phase 3B does NOT write to these files (reviews only)
  </pass_criteria>
  <evidence>audit-artifacts/vg3a-install-output.txt</evidence>
</validation_gate>

---

## Phase 3B: CC Hook Protocol Fix + Shell Script Audit

**Goal**: Fix the PostToolUse protocol violation. Audit shell scripts. Document OC plugin status.

### P0: PostToolUse Protocol Fix (addresses researcher finding, validated V4 — two commits)

**Commit 1: Protocol change** — Fix all 5 PostToolUse hooks:
1. Change output channel from `process.stdout.write(JSON)` to `process.stderr.write(message)`
2. Change exit code from `process.exit(0)` (silent) to `process.exit(2)` (feedback)
3. Simplify output: plain text feedback message to stderr, not JSON

**Commit 2: Verification** — Add proof the fix works:
4. Pipe test JSON to each fixed hook, capture stderr + exit code
5. Save verification output to `audit-artifacts/posttool-protocol-verification.txt`

**Affected files:**
- `hooks/completion-claim-validator.js` — line 32-39
- `hooks/validation-not-compilation.js` — stdout JSON output
- `hooks/validation-state-tracker.js` — stdout JSON output
- `hooks/mock-detection.js` — stdout JSON output
- `hooks/evidence-quality-check.js` — stdout JSON output

### P1: Shell Script Hardening (addresses H8, validated V3 — harden both)
1. `health-check.sh`: **SSRF vector** — `$1` passed directly to curl with no URL validation. Add URL scheme whitelist (http/https only, reject file://, gopher://, dict://, etc.).
2. `install.sh`: Add validation: verify clone target matches expected repo URL, validate `cp` target paths exist, add `--depth 1` to git clone for smaller attack surface.
3. `sync-opencode.sh`: Validate source/dest paths. Check symlink targets don't escape project root.
4. `detect-platform.sh`: Review detection logic. No external calls — low risk.
5. `evidence-collector.sh`: Validate file paths against traversal.

### P2: hooks.json Verification
1. Test `${CLAUDE_PLUGIN_ROOT}` variable interpolation by running a hook via the CC harness
2. Verify all 7 hooks are registered (no orphans, no missing entries)

### P3: OC Plugin Documentation (document only, NO fixes)
1. Note: `shell.env` hook (index.ts:143) not in documented OC hook list
2. Note: `vf_validate` tool has shell injection via string interpolation (index.ts:33)
3. Note: `permission.ask` hook uses `(input as any)` casts (index.ts:71-78)
4. Save findings to `audit-artifacts/oc-plugin-findings.md` for future OC security track

### README Review
1. Review README.md written by Phase 3A for technical accuracy
2. File comments in `audit-artifacts/readme-review.md` — do NOT directly edit README.md

### Deliverable
Fixed CC hooks (5 files). Fixed shell scripts. OC findings doc. README review notes.

### Gate

<validation_gate id="VG-3B" blocking="true" platform="cli">
  <execute>
    For each of the 5 fixed PostToolUse hooks, pipe triggering input and verify:
    ```bash
    # Example: validation-not-compilation.js
    echo '{"tool_result":{"stdout":"build succeeded"}}' | node hooks/validation-not-compilation.js 2>stderr.txt; echo "exit:$?"
    # Expected: exit:2, stderr.txt contains "compilation is NOT validation"
    # NOT expected: exit:0, stdout contains JSON
    ```
  </execute>
  <pass_criteria>
    - [ ] All 5 PostToolUse hooks: exit 2 + stderr message (not exit 0 + stdout JSON)
    - [ ] All 5 hooks: still detect their target patterns (no false negatives after protocol change)
    - [ ] health-check.sh rejects `file:///etc/passwd` URL (exit 1 or error message)
    - [ ] health-check.sh accepts `http://localhost:3000/health` (normal operation)
    - [ ] ${CLAUDE_PLUGIN_ROOT} verified by running one hook through CC harness
    - [ ] No write conflicts with Phase 3A
  </pass_criteria>
  <regression>Re-test block-test-files.js (PreToolUse, unchanged) still blocks test file writes</regression>
  <evidence>audit-artifacts/posttool-protocol-verification.txt</evidence>
</validation_gate>

---

## Phase 4: Full CC Audit and Pattern Consolidation

**Goal**: Deep sanitization of CC hooks. Eliminate pattern duplication. Checkpointed progress.

### Scope
CC hooks (7 files, ~343 LOC) + patterns.ts consolidation. OC plugin deferred.

### Checkpointing (addresses C4)
After auditing each file, update `audit-artifacts/audit-progress.json`:
```json
{
  "phase": 4,
  "files_completed": ["hooks/block-test-files.js"],
  "files_remaining": ["hooks/evidence-gate-reminder.js", "..."],
  "findings_count": 0,
  "last_updated": "2026-04-08T16:00:00Z"
}
```
On context recovery: read this file first, resume from `files_remaining`.

### P0: Pattern Consolidation (addresses H7 — 62 duplicated patterns)
1. Create `hooks/patterns.js` that re-exports from `patterns.ts` (or compile patterns.ts to JS, or extract a shared `patterns.js` used by both)
2. Replace all hardcoded arrays in all 7 hooks with `require('./patterns')` imports
3. Verify each hook still functions after pattern source change
4. Delete the now-unused local pattern arrays
5. Update patterns.ts comment to reflect it's now the actual single source (not just declared)

**Architecture decision (validated V1)**: Keep `patterns.ts` as the single source of truth. Create a `hooks/patterns.js` wrapper that re-exports for CC hooks via `require()`. OC plugin continues to `import` from `.ts` directly.

**Technical sketch — hooks/patterns.js:**
```javascript
// hooks/patterns.js — Bridge: CC hooks require() this, it re-exports from patterns.ts
// Hand-maintained. When patterns.ts adds a new export, add it here.
// Why not require patterns.ts directly? CC hooks run in Node.js, patterns.ts is TypeScript.
const {
  TEST_PATTERNS, ALLOWLIST, MOCK_PATTERNS, BUILD_PATTERNS,
  COMPLETION_PATTERNS, VALIDATION_COMMAND_PATTERNS,
  isBlockedTestFile, detectMockPatterns, isBuildSuccess,
  isCompletionClaim, isValidationCommand,
} = require('../.opencode/plugins/validationforge/patterns');
// Note: requires patterns.ts to be compiled to .js first, OR use a bundled copy.
// If require() fails on .ts, alternative: duplicate the JS values here and add
// a drift-detection check in the benchmark test runner (Phase 5).
module.exports = {
  TEST_PATTERNS, ALLOWLIST, MOCK_PATTERNS, BUILD_PATTERNS,
  COMPLETION_PATTERNS, VALIDATION_COMMAND_PATTERNS,
  isBlockedTestFile, detectMockPatterns, isBuildSuccess,
  isCompletionClaim, isValidationCommand,
};
```

**Open question**: Can Node.js `require()` a `.ts` file without ts-node? If not, the wrapper must contain the JS values directly (extracted from patterns.ts) and Phase 5 benchmark must include a drift-detection test comparing wrapper values against patterns.ts exports.

### P1: Per-Hook Sanitization
For each CC hook:
1. Read complete file
2. Verify: input parsing (JSON.parse with try/catch), pattern matching correctness
3. Check: no hardcoded paths that break on different systems
4. Check: consistent error messages (structured format)
5. Apply fixes
6. Update `audit-progress.json`

### P2: Cross-Cutting Concerns
1. Check for enforcement overlap between hooks (e.g., both block-test-files.js and mock-detection.js trigger on Write/Edit — do they conflict?)
2. Check for contradictions between hooks and rules (M15)
3. Standardize error message format: `[ValidationForge] {hook-name}: {message}`

### Deliverable
Consolidated pattern source. Sanitized hook files. Completed `audit-progress.json`. Findings summary.

### Gate
- [ ] All P0 findings fixed (pattern consolidation complete, zero duplication)
- [ ] All P1 findings documented with fix or rationale
- [ ] No regressions (each hook tested after changes)
- [ ] `audit-progress.json` shows all files completed

---

## Phase 5: Benchmark Skill Creation

**Goal**: Build executable benchmark tooling via `/skill-creator`. Three-part system, not prose.

### Why Not Prose (addresses C3)
The previous plan defined 400+ criteria as markdown text. Skills are markdown instructions — they can't "run" benchmarks. We need a system that orchestrates actual validation.

### Architecture: Three-Part Benchmark System

```
Phase 5 Workflow
├─ PART 1: Automated Testing (bash scripts)
│  ├─ scripts/benchmark/test-hooks.sh      → hook test results JSON
│  ├─ scripts/benchmark/validate-skills.sh → skill structure results JSON
│  └─ scripts/benchmark/validate-cmds.sh   → command structure results JSON
│
├─ PART 2: Skill-Guided Evaluation (LLM + SKILL.md)
│  ├─ skills/validate-audit-benchmarks/SKILL.md
│  ├─ Agent evaluates subjective criteria for top 10 skills
│  └─ Agent records scores in audit-artifacts/manual-evaluation.json
│
└─ PART 3: Results Aggregation (bash script)
   └─ scripts/benchmark/aggregate-results.sh
      ├─ Merges automated + manual scores
      ├─ Applies weighted rubric
      └─ Generates audit-artifacts/benchmark-baseline.json
```

### Steps

**Part 1: Automated Test Scripts**
1. Write `scripts/benchmark/test-hooks.sh`:
   - 8-10 test cases per hook (happy path, edge cases, adversarial inputs)
   - Pipe stdin JSON, capture exit code + stdout/stderr
   - Compare against expected output
   - JSON output per hook with pass/fail/score

   **Test case format (concrete example for implementor):**
   ```bash
   # PreToolUse hooks receive: {"tool_input": {"file_path": "...", ...}}
   # PostToolUse hooks receive: {"tool_result": {"stdout": "...", ...}}

   # Test: block-test-files.js should DENY test file writes
   result=$(echo '{"tool_input":{"file_path":"src/auth.test.ts"}}' | node hooks/block-test-files.js 2>/dev/null)
   exit_code=$?
   echo "$result" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1
   [ $? -eq 0 ] && echo "PASS: blocks test file" || echo "FAIL: did not block test file"

   # Test: block-test-files.js should ALLOW evidence files
   result=$(echo '{"tool_input":{"file_path":"e2e-evidence/step-01.png"}}' | node hooks/block-test-files.js 2>/dev/null)
   [ -z "$result" ] && echo "PASS: allows evidence file" || echo "FAIL: blocked evidence file"

   # Test: validation-not-compilation.js should flag build success (PostToolUse — stderr after fix)
   stderr=$(echo '{"tool_result":{"stdout":"build succeeded"}}' | node hooks/validation-not-compilation.js 2>&1 >/dev/null)
   exit_code=$?
   [ $exit_code -eq 2 ] && echo "PASS: exit 2 on build success" || echo "FAIL: expected exit 2, got $exit_code"
   ```
2. Write `scripts/benchmark/validate-skills.sh`:
   - Parse YAML frontmatter for all 40 skills
   - Verify: name matches dir, description ≤1024 chars, reference files exist
   - JSON output per skill with structural compliance score
3. Write `scripts/benchmark/validate-cmds.sh`:
   - Parse frontmatter for all 15 commands
   - Verify: description present, argument interpolation safety
   - JSON output per command

**Part 2: Benchmark Skill (via /skill-creator)**
4. Use `/skill-creator` to build `skills/validate-audit-benchmarks/SKILL.md`:
   - Input: category (hooks/skills/commands/all)
   - References automated test results from Part 1
   - Guides agent to evaluate subjective criteria for **top 10 skills by impact** (auto-selected: mix of core pipeline + platform-specific based on actual usage and enforcement criticality — validated V2):
     - Instruction clarity (parseable by LLM without ambiguity)
     - Tool reference accuracy (all mentioned tools exist)
     - Context efficiency (no unnecessary verbosity)
     - Trigger accuracy (agent selects skill for intended use cases)
   - Agent records reasoning to `audit-artifacts/skill-evaluation-reasoning.md`

**Part 3: Results Aggregation**
5. Write `scripts/benchmark/aggregate-results.sh`:
   - Reads all JSON from Parts 1 and 2
   - Applies scoring rubric:
     - Correctness: 40% (does it do what it claims?)
     - Format compliance: 20% (follows platform conventions?)
     - Error handling: 20% (graceful failure?)
     - Security posture: 20% (inputs validated?)
   - Generates `audit-artifacts/benchmark-baseline.json`

6. Run full benchmark suite. Save baseline results.

### MVP Scope (addresses H11)
| Must Do | Effort | Automation |
|---------|--------|-----------|
| Hook test runner (7 hooks) | 2h | 100% automated |
| Skill structural validation (40 skills) | 1h | 100% automated |
| Benchmark skill (top 10 skills) | 2h | LLM-guided |
| Results aggregator | 1h | 100% automated |

| Can Defer |
|-----------|
| Command structural validation (low risk, 15 files) |
| Rule evaluation (100% subjective, 8 files) |
| Full 40-skill instruction quality (evaluate top 10 only) |

### Deliverable
`scripts/benchmark/` test suite. `skills/validate-audit-benchmarks/SKILL.md`. Baseline results JSON.

### Gate
- [ ] Hook test runner executes end-to-end (7 hooks, all pass)
- [ ] Skill structural validator runs (40 skills scored)
- [ ] Benchmark skill created and invocable
- [ ] Baseline scores recorded in `audit-artifacts/benchmark-baseline.json`

---

## Phase 6: Improvement Pass

**Goal**: Measurable improvements using benchmark system from Phase 5.

### Steps
1. Run benchmark suite. Identify all files below 70% score threshold
2. Prioritize by user impact:
   - Hooks that fire on every tool call > hooks that fire on specific tools
   - Top 10 skills (by usage) > remaining 30 skills
   - Commands > shell scripts
3. For each below-threshold file:
   - Read benchmark failure details (which specific test cases failed)
   - Fix the specific issues (not speculative improvements)
   - Re-run benchmark on that file
   - Record delta in `audit-artifacts/benchmark-deltas.json`
4. After all fixes: run full benchmark suite
5. Compare final vs baseline. Generate `audit-artifacts/benchmark-deltas.md`

### Deliverable
Improved files. `benchmark-deltas.md` showing measurable improvement per file.

### Gate
- [ ] All hooks at or above 70% threshold
- [ ] No file regressed from baseline
- [ ] Deltas documented per file
- [ ] Top 10 skills evaluated and improved where needed

---

## Phase 7: Final Validation and Release

**Goal**: End-to-end validation with prioritized exit criteria.

### Steps
1. Run complete benchmark suite — save final results
2. Compare final vs baseline vs Phase 6 intermediate results
3. Verify end-to-end (CC path):
   - Hooks load and fire on expected triggers (pipe test JSON, verify response)
   - Skills discoverable and loadable (check frontmatter parse)
   - Commands executable via slash syntax
   - Shell scripts run without error on clean checkout
4. Verify documentation accuracy:
   - README installation steps work on clean environment
   - ARCHITECTURE.md matches actual code paths
5. Commit final state with benchmark summary in commit message
6. Tag release: `v1-post-audit`

### Exit Criteria (prioritized — addresses H9)

**Must pass (blocks release):**
- All P0 from Phase 3B/4 fixed and verified (PostToolUse protocol, pattern consolidation)
- No hook regression (hooks that worked before still work)
- README installation succeeds on clean checkout
- Benchmark scores >= baseline for all files

**Should pass (documented if not):**
- All P1 findings fixed or documented with rationale
- All docs match actual behavior
- Benchmark scores >= 70% for all hooks and top 10 skills

**Nice to have (no release block):**
- All P2 findings addressed
- Benchmark scores >= 90%
- Command structural validation complete

### Deliverable
Final benchmark report. Tagged release. Change summary.

### Gate
- [ ] All "must pass" criteria met
- [ ] Any unmet "should pass" items documented in release notes
- [ ] `v1-post-audit` tag created

---

## Constraints

1. Read every file completely before forming conclusions. Never infer file contents.
2. Do not begin implementation until Phase 1 analysis is complete and saved.
3. Respect phase gates — do not advance until gate is satisfied.
4. **Checkpoint mandate**: any phase touching >5 files MUST maintain `audit-progress.json` (C4).
5. Commit at phase boundaries with meaningful messages.
6. Never introduce dependencies not already in the codebase without justification.
7. If a phase gate cannot be met, stop and report the blocker with evidence.
8. All documentation must describe actual behavior, not aspirational behavior.
9. **File ownership**: Phase 3A owns documentation writes. Phase 3B reviews but does not write docs (C5).
10. **OC plugin security fixes are OUT OF SCOPE** — document, defer to OC security track (H6).
11. **Shell scripts are IN SCOPE** — they are enforcement infrastructure (H8).
12. Do not conflate CC hooks with OC plugin hooks. Different protocols, languages, execution models.
13. **Report blockers with evidence** — this is not "meta-discussion," it is required diligence (M15 fix).

---

## Output Format

| Phase | Deliverable | Location |
|-------|-------------|----------|
| 0 | File classification, scope | `audit-artifacts/phase-0-inventory.md` |
| 1 | Per-file findings | `audit-artifacts/phase-1-analysis.md` |
| 2 | Clean git, tag, rollback | `audit-artifacts/rollback.md` |
| 3A | README, ARCHITECTURE, SKILLS, COMMANDS | Project root docs |
| 3B | Fixed CC hooks, fixed scripts, OC findings | `audit-artifacts/oc-plugin-findings.md` |
| 4 | Consolidated patterns, sanitized hooks | `audit-artifacts/audit-progress.json` |
| 5 | Benchmark suite + baseline | `scripts/benchmark/`, `audit-artifacts/benchmark-baseline.json` |
| 6 | Improved files + deltas | `audit-artifacts/benchmark-deltas.md` |
| 7 | Final report, tagged release | `audit-artifacts/final-report.md` |

All audit artifacts go to `audit-artifacts/`. User-facing docs go to project root.

---

## Validation Log

### Session — 2026-04-08
**Trigger:** `--validate` flag on `--hard` plan rewrite
**Questions asked:** 4

| # | Domain | Question | Decision |
|---|--------|----------|----------|
| 1 | Architecture | Pattern consolidation: TS source + JS wrapper vs plain JS vs ts-node | Keep patterns.ts + JS wrapper |
| 2 | Scope | Which 10 skills for benchmark evaluation | Auto-select by impact (mix of core + platform) |
| 3 | Security | Harden health-check.sh only vs both scripts | Harden both (defense in depth) |
| 4 | Risk | PostToolUse fix: one commit per hook vs atomic vs change+verify | Two commits: protocol change + verification |

**All decisions applied to plan phases 3B, 4, and 5.**

---

## References

- Red-team report: `plans/reports/red-team-260408-1417-vf-plan-review.md`
- CC Hook Protocol Audit: `plans/reports/researcher-260408-1523-cc-hook-protocol.md`
- Benchmark Feasibility Report: `plans/reports/researcher-260408-1523-benchmark-feasibility.md`
- Previous plan (superseded): `plans/260307-unified-validationforge-product/vf.md`
- Draft rewrite (incorporated): `plans/260307-unified-validationforge-product/vf-rewrite-draft.md`
