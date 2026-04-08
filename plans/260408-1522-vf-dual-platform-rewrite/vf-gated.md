<mock_detection_protocol>
Before executing any task, check intent:
- Creating .test.*, _test.*, *Tests.*, test_* files → STOP
- Importing mock libraries (nock, sinon, jest.mock, unittest.mock) → STOP
- Creating in-memory databases (SQLite :memory:, H2) → STOP
- Adding TEST_MODE or NODE_ENV=test flags → STOP
- Rendering components in isolation (Testing Library, Storybook) → STOP
- Creating fake stdin JSON that bypasses real hook logic → STOP
- Writing wrapper scripts that stub hook behavior → STOP
Fix the REAL system instead. No exceptions.
</mock_detection_protocol>

---

## Decision Record

_(Preserved from vf.md — see original for full context)_

### Key Decisions
- **V1**: Keep patterns.ts + JS wrapper for pattern consolidation
- **V2**: Auto-select top 10 benchmark skills by impact
- **V3**: Harden both shell scripts (defense in depth)
- **V4**: Two commits for PostToolUse fix (change + verification)

### Red-Team Findings: C1-C5 (Critical), H6-H12 (High), M13-M15 (Medium)
See `plans/reports/red-team-260408-1417-vf-plan-review.md` for details.

---

## Phase 0: Inventory and Scoping

<task id="0.1">
Read the full directory tree of the ValidationForge project. Classify every file into: CC Hook / CC Skill / CC Command / CC Rule / CC Agent / Shell Script / OC Plugin / OC Config / Documentation / Other.
Files: entire project root
</task>

<task id="0.2">
For CC hooks: catalog hook type (pre/post), trigger event, file target, exit code behavior.
For CC skills: verify SKILL.md frontmatter (name, description), confirm dir name matches.
For CC commands: catalog slash syntax, arguments, agent routing.
For shell scripts: catalog purpose, inputs, external calls (curl, wget, etc.).
For OC plugin: catalog exported hooks, tools, imports. Analysis only — no fixes.
Files: hooks/*.js, skills/*/SKILL.md, commands/*.md, rules/*.md, agents/*.md, scripts/*.sh, .opencode/plugins/validationforge/*.ts
</task>

<task id="0.3">
Cross-reference patterns: identify all files containing hardcoded regex arrays that match patterns.ts exports. Produce duplication inventory.
Files: hooks/*.js, .opencode/plugins/validationforge/patterns.ts
</task>

<task id="0.4">
Write scoping document with file classification table, scope in/out, primitive counts, and pattern duplication inventory.
Output: audit-artifacts/phase-0-inventory.md
</task>

<validation_gate id="VG-0" blocking="true">
Prerequisites: Project directory accessible, all file paths valid
Execute:
  ```bash
  # Verify scoping document exists and is non-empty
  wc -l audit-artifacts/phase-0-inventory.md | tee audit-artifacts/vg0-inventory-check.txt

  # Count classified files vs total files in scope
  # Hooks
  ls hooks/*.js 2>/dev/null | wc -l | xargs -I{} echo "hooks_js: {}" >> audit-artifacts/vg0-file-counts.txt
  # Skills
  ls skills/*/SKILL.md 2>/dev/null | wc -l | xargs -I{} echo "skills: {}" >> audit-artifacts/vg0-file-counts.txt
  # Commands
  ls commands/*.md 2>/dev/null | wc -l | xargs -I{} echo "commands: {}" >> audit-artifacts/vg0-file-counts.txt
  # Rules
  ls rules/*.md 2>/dev/null | wc -l | xargs -I{} echo "rules: {}" >> audit-artifacts/vg0-file-counts.txt
  # Agents
  ls agents/*.md 2>/dev/null | wc -l | xargs -I{} echo "agents: {}" >> audit-artifacts/vg0-file-counts.txt
  # Shell scripts
  ls scripts/*.sh 2>/dev/null | wc -l | xargs -I{} echo "scripts: {}" >> audit-artifacts/vg0-file-counts.txt
  # OC plugin
  ls .opencode/plugins/validationforge/*.ts 2>/dev/null | wc -l | xargs -I{} echo "oc_plugin: {}" >> audit-artifacts/vg0-file-counts.txt

  cat audit-artifacts/vg0-file-counts.txt
  ```
Pass criteria:
  - [ ] audit-artifacts/phase-0-inventory.md exists and has >50 lines (comprehensive classification)
  - [ ] File counts match inventory: hooks=7, skills=40, commands=15, rules=8, agents=5, scripts>=4, oc_plugin=2
  - [ ] Zero "unknown" classifications in the inventory document (grep for "unknown" or "unclassified")
  - [ ] Shell scripts explicitly listed as in-scope (grep inventory for "scripts/*.sh" entries)
  - [ ] Pattern duplication cross-reference section present (grep for "duplication" or "patterns.ts")
Review: cat audit-artifacts/phase-0-inventory.md | head -80; cat audit-artifacts/vg0-file-counts.txt
Verdict: PASS → proceed to Phase 1 | FAIL → fix classification gaps → re-run counts
Mock guard: IF tempted to generate fake file counts or invent classification → STOP → read actual files
</validation_gate>

---

## Phase 1: Deep Analysis

<task id="1.1">
For each of the 7 CC hooks: read complete file. Map trigger event, decision logic, exit codes, output channel (stdout vs stderr). Flag PostToolUse protocol violations (stdout JSON + exit 0 instead of stderr + exit 2). Document per-hook with file:line references.
Files: hooks/*.js
</task>

<task id="1.2">
For each of the 40 CC skills: read SKILL.md. Verify frontmatter validity (name matches dir, description ≤1024 chars). Flag stale tool references, broken paths.
Files: skills/*/SKILL.md
</task>

<task id="1.3">
For each of the 15 CC commands: read file. Verify frontmatter, argument interpolation safety. Flag missing descriptions, broken agent routing.
Files: commands/*.md
</task>

<task id="1.4">
For each of the 4+ shell scripts: read complete file. Flag unsanitized inputs, SSRF vectors, path traversal, missing validation. Rank by trust level.
Files: scripts/*.sh
</task>

<task id="1.5">
OC plugin surface scan: read both .ts files. Catalog hooks, tools, args schemas. Note enforcement logic duplication from CC hooks. Note shell.env hook (M13), unsanitized args (H6). Document only — no fixes.
Files: .opencode/plugins/validationforge/index.ts, .opencode/plugins/validationforge/patterns.ts
</task>

<task id="1.6">
Rules + Agents: read each. Catalog purpose/scope. Flag contradictions (M15). Verify || true finding (M14) — search hooks.json. If absent, mark fabricated.
Files: rules/*.md, agents/*.md, hooks/hooks.json
</task>

<task id="1.7">
Write organized analysis document with per-file findings table including file:line references.
Output: audit-artifacts/phase-1-analysis.md
</task>

<validation_gate id="VG-1" blocking="true">
Prerequisites: Phase 0 inventory document exists at audit-artifacts/phase-0-inventory.md
Execute:
  ```bash
  # Verify analysis document exists and is comprehensive
  wc -l audit-artifacts/phase-1-analysis.md | tee audit-artifacts/vg1-analysis-check.txt

  # Verify every in-scope hook was analyzed (7 hooks)
  for hook in hooks/*.js; do
    name=$(basename "$hook")
    grep -q "$name" audit-artifacts/phase-1-analysis.md && echo "FOUND: $name" || echo "MISSING: $name"
  done | tee audit-artifacts/vg1-hook-coverage.txt

  # Verify PostToolUse protocol status documented
  grep -c "PostToolUse\|protocol violation\|stderr\|exit 2" audit-artifacts/phase-1-analysis.md | xargs -I{} echo "protocol_refs: {}" >> audit-artifacts/vg1-analysis-check.txt

  # Verify shell scripts analyzed
  for script in scripts/*.sh; do
    name=$(basename "$script")
    grep -q "$name" audit-artifacts/phase-1-analysis.md && echo "FOUND: $name" || echo "MISSING: $name"
  done | tee -a audit-artifacts/vg1-hook-coverage.txt

  # Verify file:line references present
  grep -cE '[a-z-]+\.(js|ts|sh|md):[0-9]+' audit-artifacts/phase-1-analysis.md | xargs -I{} echo "line_refs: {}" >> audit-artifacts/vg1-analysis-check.txt

  # Verify || true finding addressed (M14)
  grep -q "|| true\|fabricated\|M14" audit-artifacts/phase-1-analysis.md && echo "M14: addressed" || echo "M14: MISSING"

  cat audit-artifacts/vg1-analysis-check.txt
  cat audit-artifacts/vg1-hook-coverage.txt
  ```
Pass criteria:
  - [ ] audit-artifacts/phase-1-analysis.md exists and has >100 lines
  - [ ] All 7 hooks appear in coverage check (zero "MISSING" lines for hooks)
  - [ ] All shell scripts appear in coverage check (zero "MISSING" lines for scripts)
  - [ ] PostToolUse protocol status documented (protocol_refs > 5)
  - [ ] File:line references present (line_refs > 10)
  - [ ] M14 (|| true finding) explicitly addressed (verified or marked fabricated)
  - [ ] Every in-scope file read — no file left unanalyzed
Review: cat audit-artifacts/vg1-analysis-check.txt; cat audit-artifacts/vg1-hook-coverage.txt; head -60 audit-artifacts/phase-1-analysis.md
Verdict: PASS → proceed to Phase 2 | FAIL → identify unread files → complete analysis → re-run
Mock guard: IF tempted to fabricate analysis or skip reading a file → STOP → read actual file content
</validation_gate>

---

## Phase 2: Git Hygiene and Baseline

<task id="2.1">
Review git state. Ensure .gitignore covers node_modules/, dist/, .env, *.local, build artifacts, .omc/state/, audit-artifacts/.
Commit all current working state.
</task>

<task id="2.2">
Tag baseline: v0-pre-audit (rollback point). Confirm audit/plugin-improvements branch active.
</task>

<task id="2.3">
Write rollback procedure to audit-artifacts/rollback.md.
Output: audit-artifacts/rollback.md
</task>

<validation_gate id="VG-2" blocking="true">
Prerequisites: Git repository initialized, working directory is project root
Execute:
  ```bash
  # Check git status clean
  git status --porcelain 2>&1 | tee audit-artifacts/vg2-git-status.txt

  # Verify tag exists
  git tag -l 'v0-pre-audit' | tee audit-artifacts/vg2-tag-check.txt

  # Verify branch
  git branch --show-current | tee audit-artifacts/vg2-branch.txt

  # Verify rollback doc
  cat audit-artifacts/rollback.md 2>&1 | head -10 | tee audit-artifacts/vg2-rollback-check.txt

  # Verify .gitignore entries
  for pattern in "node_modules" "dist/" ".env" "*.local" ".omc/state" "audit-artifacts"; do
    grep -q "$pattern" .gitignore && echo "FOUND: $pattern" || echo "MISSING: $pattern"
  done | tee audit-artifacts/vg2-gitignore-check.txt
  ```
Pass criteria:
  - [ ] git status --porcelain outputs empty or only untracked audit-artifacts/ (clean working state)
  - [ ] v0-pre-audit tag exists (non-empty output from git tag -l)
  - [ ] Current branch is audit/plugin-improvements
  - [ ] audit-artifacts/rollback.md exists and contains rollback command
  - [ ] .gitignore covers all required patterns (zero "MISSING" lines)
Review: cat audit-artifacts/vg2-git-status.txt; cat audit-artifacts/vg2-tag-check.txt; cat audit-artifacts/vg2-branch.txt
Verdict: PASS → proceed to Phase 3A | FAIL → fix git state → re-run
Mock guard: IF tempted to skip tagging or fake clean status → STOP → run actual git commands
</validation_gate>

---

## Phase 3A: Documentation Overhaul

<task id="3A.1">
Write/update README.md with dual-platform identity, verified inventory counts, installation steps for CC and OC, quick start per primitive type, troubleshooting. All content based on Phase 1 analysis — not aspirational.
Files: README.md
</task>

<task id="3A.2">
Write/update ARCHITECTURE.md with CC hook lifecycle, CC skill lifecycle, OC plugin lifecycle, pattern sharing architecture, data flow diagrams.
Files: ARCHITECTURE.md
</task>

<task id="3A.3">
Write SKILLS.md: index of all 40 skills (name, description, category).
Write COMMANDS.md: index of all 15 commands (syntax, description, agent routing).
Files: SKILLS.md, COMMANDS.md
</task>

<task id="3A.4">
Verify CC installation steps by executing install.sh in a clean tmpdir.
</task>

<validation_gate id="VG-3A" blocking="true">
Prerequisites: Phase 1 analysis exists at audit-artifacts/phase-1-analysis.md
Execute:
  ```bash
  # Test install.sh in clean tmpdir
  tmpdir=$(mktemp -d)
  cd "$tmpdir" && git init
  bash /Users/nick/Desktop/validationforge/scripts/install.sh 2>&1 | tee /Users/nick/Desktop/validationforge/audit-artifacts/vg3a-install-output.txt
  install_exit=$?
  echo "EXIT: $install_exit" >> /Users/nick/Desktop/validationforge/audit-artifacts/vg3a-install-output.txt
  cd /Users/nick/Desktop/validationforge

  # Verify all 4 docs exist and are non-empty
  for doc in README.md ARCHITECTURE.md SKILLS.md COMMANDS.md; do
    if [ -f "$doc" ] && [ -s "$doc" ]; then
      lines=$(wc -l < "$doc")
      echo "OK: $doc ($lines lines)"
    else
      echo "FAIL: $doc missing or empty"
    fi
  done | tee audit-artifacts/vg3a-docs-check.txt

  # Verify README describes actual behavior (not aspirational)
  grep -c "aspirational\|coming soon\|planned\|TODO\|TBD" README.md | xargs -I{} echo "aspirational_refs: {}" >> audit-artifacts/vg3a-docs-check.txt

  # Verify SKILLS.md has all 40 skills
  grep -cE '^\|' SKILLS.md | xargs -I{} echo "skills_table_rows: {}" >> audit-artifacts/vg3a-docs-check.txt

  # Verify COMMANDS.md has all 15 commands
  grep -cE '^\|' COMMANDS.md | xargs -I{} echo "commands_table_rows: {}" >> audit-artifacts/vg3a-docs-check.txt

  # Clean up tmpdir
  rm -rf "$tmpdir"

  cat audit-artifacts/vg3a-docs-check.txt
  cat audit-artifacts/vg3a-install-output.txt | tail -5
  ```
Pass criteria:
  - [ ] install.sh exits 0 in clean tmpdir
  - [ ] All 4 docs exist and are non-empty (zero "FAIL" lines in docs-check)
  - [ ] Zero aspirational references in README (aspirational_refs = 0)
  - [ ] SKILLS.md table rows >= 41 (header + 40 skills)
  - [ ] COMMANDS.md table rows >= 16 (header + 15 commands)
  - [ ] README describes dual-platform identity (grep for "Claude Code" AND "OpenCode")
  - [ ] Phase 3B does NOT write to README.md, ARCHITECTURE.md, SKILLS.md, or COMMANDS.md
Review: cat audit-artifacts/vg3a-docs-check.txt; cat audit-artifacts/vg3a-install-output.txt
Verdict: PASS → proceed to Phase 3B | FAIL → fix docs/install → re-run
Mock guard: IF tempted to skip install test or write aspirational docs → STOP → test real install, describe real behavior
</validation_gate>

---

## Phase 3B: CC Hook Protocol Fix + Shell Script Audit

<task id="3B.1">
**P0: PostToolUse Protocol Fix (Commit 1)** — Fix all 5 PostToolUse hooks: change output from process.stdout.write(JSON) + exit 0 to process.stderr.write(message) + exit 2.
Files: hooks/completion-claim-validator.js, hooks/validation-not-compilation.js, hooks/validation-state-tracker.js, hooks/mock-detection.js, hooks/evidence-quality-check.js
</task>

<task id="3B.2">
**P0: Verification (Commit 2)** — Pipe test JSON to each fixed hook. Capture stderr + exit code. Save to audit-artifacts/posttool-protocol-verification.txt.
Output: audit-artifacts/posttool-protocol-verification.txt
</task>

<task id="3B.3">
**P1: Shell Script Hardening** — health-check.sh: add URL scheme whitelist (http/https only). install.sh: validate clone target, add --depth 1. sync-opencode.sh: validate paths. evidence-collector.sh: validate against traversal.
Files: scripts/health-check.sh, scripts/install.sh, scripts/sync-opencode.sh, scripts/evidence-collector.sh
</task>

<task id="3B.4">
**P2: hooks.json Verification** — Verify ${CLAUDE_PLUGIN_ROOT} interpolation. Verify all 7 hooks registered.
Files: hooks/hooks.json
</task>

<task id="3B.5">
**P3: OC Plugin Documentation** — Document shell.env, shell injection, (input as any) casts. Save to audit-artifacts/oc-plugin-findings.md. NO fixes.
Output: audit-artifacts/oc-plugin-findings.md
</task>

<task id="3B.6">
**README Review** — Review README.md for technical accuracy. File comments to audit-artifacts/readme-review.md. Do NOT edit README.md.
Output: audit-artifacts/readme-review.md
</task>

<validation_gate id="VG-3B" blocking="true">
Prerequisites: Phase 3A complete (VG-3A passed), all 5 PostToolUse hooks exist
Execute:
  ```bash
  mkdir -p audit-artifacts

  # Test each fixed PostToolUse hook: must exit 2 + stderr message
  echo "=== PostToolUse Protocol Verification ===" > audit-artifacts/vg3b-protocol-test.txt

  # 1. validation-not-compilation.js
  stderr=$(echo '{"tool_name":"Bash","tool_result":{"stdout":"build succeeded","exit_code":0}}' | node hooks/validation-not-compilation.js 2>&1 >/dev/null)
  exit_code=$?
  echo "validation-not-compilation: exit=$exit_code stderr='$stderr'" >> audit-artifacts/vg3b-protocol-test.txt
  [ $exit_code -eq 2 ] && echo "  PASS: exit 2" >> audit-artifacts/vg3b-protocol-test.txt || echo "  FAIL: expected exit 2, got $exit_code" >> audit-artifacts/vg3b-protocol-test.txt

  # 2. completion-claim-validator.js
  stderr=$(echo '{"tool_name":"Bash","tool_result":{"stdout":"All checks passed successfully"}}' | node hooks/completion-claim-validator.js 2>&1 >/dev/null)
  exit_code=$?
  echo "completion-claim-validator: exit=$exit_code stderr='$stderr'" >> audit-artifacts/vg3b-protocol-test.txt
  [ $exit_code -eq 2 ] && echo "  PASS: exit 2" >> audit-artifacts/vg3b-protocol-test.txt || echo "  FAIL: expected exit 2, got $exit_code" >> audit-artifacts/vg3b-protocol-test.txt

  # 3. mock-detection.js
  stderr=$(echo '{"tool_name":"Write","tool_input":{"content":"jest.mock(\"./api\")"}}' | node hooks/mock-detection.js 2>&1 >/dev/null)
  exit_code=$?
  echo "mock-detection: exit=$exit_code stderr='$stderr'" >> audit-artifacts/vg3b-protocol-test.txt
  [ $exit_code -eq 2 ] && echo "  PASS: exit 2" >> audit-artifacts/vg3b-protocol-test.txt || echo "  FAIL: expected exit 2, got $exit_code" >> audit-artifacts/vg3b-protocol-test.txt

  # 4. evidence-quality-check.js
  stderr=$(echo '{"tool_name":"Write","tool_input":{"file_path":"e2e-evidence/test.png","content":""}}' | node hooks/evidence-quality-check.js 2>&1 >/dev/null)
  exit_code=$?
  echo "evidence-quality-check: exit=$exit_code stderr='$stderr'" >> audit-artifacts/vg3b-protocol-test.txt
  [ $exit_code -eq 2 ] && echo "  PASS: exit 2" >> audit-artifacts/vg3b-protocol-test.txt || echo "  FAIL: expected exit 2, got $exit_code" >> audit-artifacts/vg3b-protocol-test.txt

  # 5. validation-state-tracker.js
  stderr=$(echo '{"tool_name":"Bash","tool_result":{"stdout":"npm test\n5 passing"}}' | node hooks/validation-state-tracker.js 2>&1 >/dev/null)
  exit_code=$?
  echo "validation-state-tracker: exit=$exit_code stderr='$stderr'" >> audit-artifacts/vg3b-protocol-test.txt
  [ $exit_code -eq 2 ] && echo "  PASS: exit 2" >> audit-artifacts/vg3b-protocol-test.txt || echo "  FAIL: expected exit 2, got $exit_code" >> audit-artifacts/vg3b-protocol-test.txt

  # 6. Regression: PreToolUse hook still works (block-test-files.js)
  result=$(echo '{"tool_name":"Write","tool_input":{"file_path":"src/auth.test.ts"}}' | node hooks/block-test-files.js 2>/dev/null)
  echo "$result" | grep -q "deny\|block\|DENY\|BLOCK" && echo "REGRESSION: PASS (block-test-files still blocks)" >> audit-artifacts/vg3b-protocol-test.txt || echo "REGRESSION: FAIL (block-test-files not blocking)" >> audit-artifacts/vg3b-protocol-test.txt

  # 7. Shell script SSRF check
  if [ -f scripts/health-check.sh ]; then
    bash scripts/health-check.sh "file:///etc/passwd" 2>&1 | tee audit-artifacts/vg3b-ssrf-test.txt
    ssrf_exit=$?
    [ $ssrf_exit -ne 0 ] && echo "SSRF: PASS (rejected file:// URL, exit=$ssrf_exit)" >> audit-artifacts/vg3b-protocol-test.txt || echo "SSRF: FAIL (accepted file:// URL)" >> audit-artifacts/vg3b-protocol-test.txt
  fi

  # 8. Shell script normal operation
  if [ -f scripts/health-check.sh ]; then
    bash scripts/health-check.sh "http://localhost:9999/health" 2>&1 | tee audit-artifacts/vg3b-health-normal.txt
    echo "HEALTH_NORMAL: exit=$?" >> audit-artifacts/vg3b-protocol-test.txt
  fi

  cat audit-artifacts/vg3b-protocol-test.txt
  ```
Pass criteria:
  - [ ] All 5 PostToolUse hooks: exit 2 + stderr message (5x "PASS: exit 2" in output)
  - [ ] Zero "FAIL: expected exit 2" lines
  - [ ] All 5 hooks still detect their target patterns (non-empty stderr on triggering input)
  - [ ] block-test-files.js regression: PASS (still blocks test file writes)
  - [ ] health-check.sh rejects file:///etc/passwd (SSRF: PASS)
  - [ ] audit-artifacts/oc-plugin-findings.md exists and is non-empty
  - [ ] audit-artifacts/readme-review.md exists
  - [ ] No writes to README.md, ARCHITECTURE.md, SKILLS.md, COMMANDS.md (file ownership respected)
Review: cat audit-artifacts/vg3b-protocol-test.txt; wc -l audit-artifacts/oc-plugin-findings.md; wc -l audit-artifacts/readme-review.md
Verdict: PASS → proceed to Phase 4 | FAIL → fix failing hooks/scripts → re-run from Execute
Mock guard: IF tempted to bypass hook testing or stub stdin → STOP → pipe real JSON to real hooks
</validation_gate>

---

## Phase 4: Full CC Audit and Pattern Consolidation

<task id="4.1">
**P0: Pattern Consolidation** — Create hooks/patterns.js that re-exports from patterns.ts (or contains extracted JS values). Replace all hardcoded arrays in all 7 hooks with require('./patterns') imports. Delete unused local pattern arrays.
Files: hooks/patterns.js (new), hooks/*.js (modify), .opencode/plugins/validationforge/patterns.ts (reference)
</task>

<task id="4.2">
**P1: Per-Hook Sanitization** — For each CC hook: verify input parsing (JSON.parse with try/catch), pattern matching correctness, no hardcoded paths, consistent error messages. Apply fixes. Update audit-progress.json after each file.
Files: hooks/*.js, audit-artifacts/audit-progress.json
</task>

<task id="4.3">
**P2: Cross-Cutting Concerns** — Check enforcement overlap between hooks (block-test-files vs mock-detection on Write/Edit). Check contradictions between hooks and rules (M15). Standardize error message format: [ValidationForge] {hook-name}: {message}.
Files: hooks/*.js, rules/*.md
</task>

<validation_gate id="VG-4" blocking="true">
Prerequisites: VG-3B passed, all hooks in working state
Execute:
  ```bash
  mkdir -p audit-artifacts

  # 1. Verify patterns.js exists and is importable
  node -e "const p = require('./hooks/patterns'); console.log('exports:', Object.keys(p).join(', '))" 2>&1 | tee audit-artifacts/vg4-patterns-check.txt
  patterns_exit=$?
  echo "patterns_require: exit=$patterns_exit" >> audit-artifacts/vg4-patterns-check.txt

  # 2. Verify no hardcoded pattern arrays remain in hooks
  echo "=== Duplication Check ===" >> audit-artifacts/vg4-patterns-check.txt
  for hook in hooks/*.js; do
    [ "$(basename "$hook")" = "patterns.js" ] && continue
    # Check for inline regex arrays (3+ regexes in a row = likely hardcoded)
    count=$(grep -cE '^\s*(\/.*\/|new RegExp)' "$hook" 2>/dev/null || echo 0)
    echo "$(basename $hook): inline_regexes=$count" >> audit-artifacts/vg4-patterns-check.txt
  done

  # 3. Run each hook with triggering input to verify no regressions after consolidation
  echo "=== Post-Consolidation Regression ===" >> audit-artifacts/vg4-patterns-check.txt

  # block-test-files (PreToolUse — should deny)
  echo '{"tool_name":"Write","tool_input":{"file_path":"src/foo.test.js"}}' | node hooks/block-test-files.js 2>/dev/null | grep -q "deny\|block\|DENY\|BLOCK"
  echo "block-test-files: regression=$([ $? -eq 0 ] && echo PASS || echo FAIL)" >> audit-artifacts/vg4-patterns-check.txt

  # evidence-gate-reminder (PreToolUse — should inject checklist)
  echo '{"tool_name":"TaskUpdate","tool_input":{"status":"completed"}}' | node hooks/evidence-gate-reminder.js 2>/dev/null
  egate_exit=$?
  echo "evidence-gate-reminder: exit=$egate_exit" >> audit-artifacts/vg4-patterns-check.txt

  # validation-not-compilation (PostToolUse — should exit 2 on build success)
  echo '{"tool_name":"Bash","tool_result":{"stdout":"build succeeded"}}' | node hooks/validation-not-compilation.js 2>/dev/null
  vnc_exit=$?
  echo "validation-not-compilation: exit=$vnc_exit (expect 2)" >> audit-artifacts/vg4-patterns-check.txt

  # completion-claim-validator (PostToolUse — should exit 2 on completion claim)
  echo '{"tool_name":"Bash","tool_result":{"stdout":"All tests passed"}}' | node hooks/completion-claim-validator.js 2>/dev/null
  ccv_exit=$?
  echo "completion-claim-validator: exit=$ccv_exit (expect 2)" >> audit-artifacts/vg4-patterns-check.txt

  # mock-detection (PostToolUse — should exit 2 on mock pattern)
  echo '{"tool_name":"Write","tool_input":{"content":"jest.mock(\"./service\")"}}' | node hooks/mock-detection.js 2>/dev/null
  md_exit=$?
  echo "mock-detection: exit=$md_exit (expect 2)" >> audit-artifacts/vg4-patterns-check.txt

  # 4. Verify audit-progress.json is complete
  if [ -f audit-artifacts/audit-progress.json ]; then
    node -e "const p=JSON.parse(require('fs').readFileSync('audit-artifacts/audit-progress.json','utf8')); console.log('completed:', p.files_completed?.length || 0, 'remaining:', p.files_remaining?.length || 0)" 2>&1 >> audit-artifacts/vg4-patterns-check.txt
  else
    echo "audit-progress.json: MISSING" >> audit-artifacts/vg4-patterns-check.txt
  fi

  # 5. Verify standardized error messages
  grep -r "\[ValidationForge\]" hooks/*.js | wc -l | xargs -I{} echo "standardized_messages: {}" >> audit-artifacts/vg4-patterns-check.txt

  cat audit-artifacts/vg4-patterns-check.txt
  ```
Pass criteria:
  - [ ] hooks/patterns.js exists and require() succeeds (patterns_require: exit=0)
  - [ ] All exports present: TEST_PATTERNS, MOCK_PATTERNS, BUILD_PATTERNS, COMPLETION_PATTERNS at minimum
  - [ ] Zero hooks have inline_regexes > 2 (pattern consolidation complete, no duplication)
  - [ ] All hook regressions PASS (each hook still detects its target pattern)
  - [ ] PostToolUse hooks exit 2 (validation-not-compilation, completion-claim-validator, mock-detection)
  - [ ] audit-progress.json exists with files_remaining = 0
  - [ ] standardized_messages >= 5 (error format standardized across hooks)
Review: cat audit-artifacts/vg4-patterns-check.txt
Verdict: PASS → proceed to Phase 5 | FAIL → fix consolidation/regressions → re-run
Mock guard: IF tempted to create a stub patterns.js that doesn't actually export real patterns → STOP → export real regex patterns
</validation_gate>

---

## Phase 5: Benchmark Skill Creation

<task id="5.1">
**Part 1a: Hook Test Runner** — Write scripts/benchmark/test-hooks.sh with 8-10 test cases per hook. Pipe stdin JSON, capture exit code + stdout/stderr, compare against expected. JSON output per hook.
Output: scripts/benchmark/test-hooks.sh
</task>

<task id="5.2">
**Part 1b: Skill Structural Validator** — Write scripts/benchmark/validate-skills.sh. Parse YAML frontmatter for all 40 skills. Verify name matches dir, description ≤1024 chars, reference files exist. JSON output per skill.
Output: scripts/benchmark/validate-skills.sh
</task>

<task id="5.3">
**Part 1c: Command Structural Validator** — Write scripts/benchmark/validate-cmds.sh. Parse frontmatter for all 15 commands. JSON output per command.
Output: scripts/benchmark/validate-cmds.sh
</task>

<task id="5.4">
**Part 2: Benchmark Skill** — Use /skill-creator to build skills/validate-audit-benchmarks/SKILL.md. Input: category. References automated test results. Guides agent to evaluate top 10 skills by impact.
Output: skills/validate-audit-benchmarks/SKILL.md
</task>

<task id="5.5">
**Part 3: Results Aggregator** — Write scripts/benchmark/aggregate-results.sh. Reads all JSON from Parts 1 and 2. Applies weighted rubric (correctness 40%, format 20%, error handling 20%, security 20%). Generates baseline JSON.
Output: scripts/benchmark/aggregate-results.sh
</task>

<task id="5.6">
Run full benchmark suite. Save baseline results to audit-artifacts/benchmark-baseline.json.
</task>

<validation_gate id="VG-5" blocking="true">
Prerequisites: VG-4 passed, all hooks consolidated and working
Execute:
  ```bash
  mkdir -p audit-artifacts

  # 1. Run hook test runner
  bash scripts/benchmark/test-hooks.sh 2>&1 | tee audit-artifacts/vg5-hook-tests.txt
  hook_test_exit=$?
  echo "hook_test_runner: exit=$hook_test_exit" >> audit-artifacts/vg5-benchmark-check.txt

  # 2. Run skill structural validator
  bash scripts/benchmark/validate-skills.sh 2>&1 | tee audit-artifacts/vg5-skill-validation.txt
  skill_val_exit=$?
  echo "skill_validator: exit=$skill_val_exit" >> audit-artifacts/vg5-benchmark-check.txt

  # 3. Verify benchmark skill exists
  if [ -f skills/validate-audit-benchmarks/SKILL.md ]; then
    lines=$(wc -l < skills/validate-audit-benchmarks/SKILL.md)
    echo "benchmark_skill: exists ($lines lines)" >> audit-artifacts/vg5-benchmark-check.txt
  else
    echo "benchmark_skill: MISSING" >> audit-artifacts/vg5-benchmark-check.txt
  fi

  # 4. Run aggregator
  bash scripts/benchmark/aggregate-results.sh 2>&1 | tee audit-artifacts/vg5-aggregation.txt
  agg_exit=$?
  echo "aggregator: exit=$agg_exit" >> audit-artifacts/vg5-benchmark-check.txt

  # 5. Verify baseline JSON exists and is valid
  if [ -f audit-artifacts/benchmark-baseline.json ]; then
    node -e "const b=JSON.parse(require('fs').readFileSync('audit-artifacts/benchmark-baseline.json','utf8')); console.log('hooks_scored:', Object.keys(b.hooks || {}).length, 'skills_scored:', Object.keys(b.skills || {}).length)" 2>&1 >> audit-artifacts/vg5-benchmark-check.txt
  else
    echo "baseline_json: MISSING" >> audit-artifacts/vg5-benchmark-check.txt
  fi

  # 6. Count hook test PASS/FAIL
  pass_count=$(grep -c "PASS" audit-artifacts/vg5-hook-tests.txt 2>/dev/null || echo 0)
  fail_count=$(grep -c "FAIL" audit-artifacts/vg5-hook-tests.txt 2>/dev/null || echo 0)
  echo "hook_tests: pass=$pass_count fail=$fail_count" >> audit-artifacts/vg5-benchmark-check.txt

  cat audit-artifacts/vg5-benchmark-check.txt
  ```
Pass criteria:
  - [ ] Hook test runner executes end-to-end (hook_test_runner: exit=0)
  - [ ] Hook tests: all 7 hooks scored, pass > fail (zero unexpected FAILs)
  - [ ] Skill structural validator runs (skill_validator: exit=0)
  - [ ] Benchmark skill created and has >30 lines
  - [ ] Aggregator runs (aggregator: exit=0)
  - [ ] audit-artifacts/benchmark-baseline.json exists with valid JSON containing hooks_scored >= 7 and skills_scored >= 10
Review: cat audit-artifacts/vg5-benchmark-check.txt; head -20 audit-artifacts/benchmark-baseline.json
Verdict: PASS → proceed to Phase 6 | FAIL → fix failing scripts → re-run
Mock guard: IF tempted to hardcode PASS results or skip running actual hooks → STOP → pipe real JSON through real hooks
</validation_gate>

---

## Phase 6: Improvement Pass

<task id="6.1">
Run benchmark suite. Identify all files below 70% score threshold. Prioritize by user impact: hooks that fire on every tool call > specific tool hooks > top 10 skills > rest.
</task>

<task id="6.2">
For each below-threshold file: read benchmark failure details, fix specific issues, re-run benchmark on that file, record delta in audit-artifacts/benchmark-deltas.json.
</task>

<task id="6.3">
Run full benchmark suite after all fixes. Compare final vs baseline. Generate audit-artifacts/benchmark-deltas.md.
Output: audit-artifacts/benchmark-deltas.md, audit-artifacts/benchmark-deltas.json
</task>

<validation_gate id="VG-6" blocking="true">
Prerequisites: VG-5 passed, baseline JSON exists
Execute:
  ```bash
  # 1. Run full benchmark suite (post-improvement)
  bash scripts/benchmark/test-hooks.sh 2>&1 | tee audit-artifacts/vg6-final-hooks.txt
  bash scripts/benchmark/validate-skills.sh 2>&1 | tee audit-artifacts/vg6-final-skills.txt
  bash scripts/benchmark/aggregate-results.sh 2>&1 | tee audit-artifacts/vg6-final-aggregate.txt

  # 2. Compare final vs baseline
  if [ -f audit-artifacts/benchmark-baseline.json ] && [ -f audit-artifacts/benchmark-baseline.json ]; then
    node -e "
      const base = JSON.parse(require('fs').readFileSync('audit-artifacts/benchmark-baseline.json','utf8'));
      const final_path = 'audit-artifacts/benchmark-baseline.json'; // aggregator overwrites — check for benchmark-final.json
      // Check for regressions
      let regressions = 0;
      const hooks = base.hooks || {};
      for (const [name, score] of Object.entries(hooks)) {
        if (typeof score === 'number') console.log('hook:', name, 'baseline:', score);
      }
      console.log('regressions:', regressions);
    " 2>&1 | tee audit-artifacts/vg6-comparison.txt
  fi

  # 3. Verify deltas document exists
  wc -l audit-artifacts/benchmark-deltas.md 2>/dev/null | tee audit-artifacts/vg6-deltas-check.txt

  # 4. Count hooks below 70%
  grep -c "below_threshold\|< 70\|FAIL" audit-artifacts/vg6-final-hooks.txt 2>/dev/null | xargs -I{} echo "below_threshold_hooks: {}" >> audit-artifacts/vg6-deltas-check.txt

  cat audit-artifacts/vg6-deltas-check.txt
  ```
Pass criteria:
  - [ ] All hooks at or above 70% threshold (below_threshold_hooks = 0)
  - [ ] No file regressed from baseline (regressions = 0 in comparison)
  - [ ] audit-artifacts/benchmark-deltas.md exists and documents per-file deltas
  - [ ] audit-artifacts/benchmark-deltas.json exists with valid JSON
  - [ ] Top 10 skills evaluated and improved where needed
Review: cat audit-artifacts/vg6-deltas-check.txt; head -30 audit-artifacts/benchmark-deltas.md
Verdict: PASS → proceed to Phase 7 | FAIL → continue fixing below-threshold files → re-run
Mock guard: IF tempted to lower threshold or skip re-running benchmarks → STOP → run real benchmark
</validation_gate>

---

## Phase 7: Final Validation and Release

<task id="7.1">
Run complete benchmark suite — save final results.
Compare final vs baseline vs Phase 6 intermediate results.
</task>

<task id="7.2">
Verify end-to-end CC path: hooks load and fire on expected triggers (pipe test JSON), skills discoverable (frontmatter parse), commands executable, shell scripts run on clean checkout.
</task>

<task id="7.3">
Verify documentation accuracy: README installation works on clean environment, ARCHITECTURE.md matches actual code paths.
</task>

<task id="7.4">
Commit final state. Tag release: v1-post-audit.
</task>

<validation_gate id="VG-7" blocking="true">
Prerequisites: VG-6 passed, all improvements applied
Execute:
  ```bash
  mkdir -p audit-artifacts

  echo "=== Phase 7 Final Validation ===" > audit-artifacts/vg7-final-validation.txt

  # 1. Run final benchmark suite
  bash scripts/benchmark/test-hooks.sh 2>&1 | tee audit-artifacts/vg7-final-hooks.txt
  bash scripts/benchmark/validate-skills.sh 2>&1 | tee audit-artifacts/vg7-final-skills.txt
  bash scripts/benchmark/aggregate-results.sh 2>&1 | tee audit-artifacts/vg7-final-aggregate.txt
  echo "benchmark_suite: complete" >> audit-artifacts/vg7-final-validation.txt

  # 2. E2E: Pipe test JSON through all hooks
  echo "=== E2E Hook Verification ===" >> audit-artifacts/vg7-final-validation.txt
  for hook in hooks/*.js; do
    [ "$(basename "$hook")" = "patterns.js" ] && continue
    name=$(basename "$hook" .js)
    echo '{"tool_name":"Bash","tool_input":{},"tool_result":{"stdout":"test"}}' | node "$hook" 2>/dev/null
    echo "$name: exit=$?" >> audit-artifacts/vg7-final-validation.txt
  done

  # 3. Skill frontmatter parse check (sample 5)
  echo "=== Skill Frontmatter Spot Check ===" >> audit-artifacts/vg7-final-validation.txt
  for skill in $(ls -d skills/*/SKILL.md 2>/dev/null | head -5); do
    dir=$(basename $(dirname "$skill"))
    head -5 "$skill" | grep -q "name:" && echo "$dir: frontmatter OK" || echo "$dir: frontmatter MISSING"
  done >> audit-artifacts/vg7-final-validation.txt

  # 4. README install test (clean tmpdir)
  tmpdir=$(mktemp -d)
  cd "$tmpdir" && git init
  bash /Users/nick/Desktop/validationforge/scripts/install.sh 2>&1 | tail -3 >> /Users/nick/Desktop/validationforge/audit-artifacts/vg7-final-validation.txt
  install_exit=$?
  echo "install_test: exit=$install_exit" >> /Users/nick/Desktop/validationforge/audit-artifacts/vg7-final-validation.txt
  cd /Users/nick/Desktop/validationforge
  rm -rf "$tmpdir"

  # 5. Verify v1-post-audit tag
  git tag -l 'v1-post-audit' | tee -a audit-artifacts/vg7-final-validation.txt

  # 6. Must-pass criteria summary
  echo "=== Exit Criteria ===" >> audit-artifacts/vg7-final-validation.txt
  # P0 fixed: PostToolUse protocol
  grep -c "exit=2" audit-artifacts/vg7-final-validation.txt | xargs -I{} echo "posttool_exit2_count: {}" >> audit-artifacts/vg7-final-validation.txt
  # No regressions
  grep -c "FAIL\|REGRESSION" audit-artifacts/vg7-final-hooks.txt | xargs -I{} echo "hook_failures: {}" >> audit-artifacts/vg7-final-validation.txt
  # Benchmark scores
  echo "benchmark_final: see vg7-final-aggregate.txt" >> audit-artifacts/vg7-final-validation.txt

  cat audit-artifacts/vg7-final-validation.txt
  ```
Pass criteria:
  **Must pass (blocks release):**
  - [ ] All P0 from Phase 3B/4 fixed: PostToolUse hooks exit 2 (posttool_exit2_count >= 5)
  - [ ] No hook regression (hook_failures = 0)
  - [ ] README installation succeeds on clean checkout (install_test: exit=0)
  - [ ] Benchmark scores >= baseline for all files
  - [ ] v1-post-audit tag exists

  **Should pass (documented if not):**
  - [ ] All P1 findings fixed or documented with rationale
  - [ ] All docs match actual behavior
  - [ ] Benchmark scores >= 70% for all hooks and top 10 skills

  **Nice to have (no release block):**
  - [ ] All P2 findings addressed
  - [ ] Benchmark scores >= 90%
  - [ ] Command structural validation complete
Review: cat audit-artifacts/vg7-final-validation.txt; cat audit-artifacts/vg7-final-aggregate.txt
Verdict: PASS (all must-pass) → tag release → DONE | FAIL → fix → re-run from failed criterion
Mock guard: IF tempted to tag release without passing must-pass criteria → STOP → fix real issues first
</validation_gate>

---

<gate_manifest>
Total gates: 8
Sequence: VG-0 → VG-1 → VG-2 → VG-3A → VG-3B → VG-4 → VG-5 → VG-6 → VG-7
All gates: BLOCKING (no advancement on FAIL)
Evidence directory: audit-artifacts/
Total tasks: 27

Evidence files produced:
  VG-0: vg0-inventory-check.txt, vg0-file-counts.txt
  VG-1: vg1-analysis-check.txt, vg1-hook-coverage.txt
  VG-2: vg2-git-status.txt, vg2-tag-check.txt, vg2-branch.txt, vg2-rollback-check.txt, vg2-gitignore-check.txt
  VG-3A: vg3a-install-output.txt, vg3a-docs-check.txt
  VG-3B: vg3b-protocol-test.txt, vg3b-ssrf-test.txt, vg3b-health-normal.txt
  VG-4: vg4-patterns-check.txt
  VG-5: vg5-hook-tests.txt, vg5-skill-validation.txt, vg5-aggregation.txt, vg5-benchmark-check.txt
  VG-6: vg6-final-hooks.txt, vg6-final-skills.txt, vg6-comparison.txt, vg6-deltas-check.txt
  VG-7: vg7-final-validation.txt, vg7-final-hooks.txt, vg7-final-skills.txt, vg7-final-aggregate.txt

If ANY gate FAILS: Fix real system → re-run from FAILED gate → do NOT skip
Mock detection: Embedded at top of document — halts on any test/mock/stub pattern
Platform: CLI (Node.js hooks via stdin JSON piping, shell scripts)
</gate_manifest>

---

## References

- Original plan: `plans/260408-1522-vf-dual-platform-rewrite/vf.md`
- Red-team report: `plans/reports/red-team-260408-1417-vf-plan-review.md`
- CC Hook Protocol Audit: `plans/reports/researcher-260408-1523-cc-hook-protocol.md`
- Benchmark Feasibility: `plans/reports/researcher-260408-1523-benchmark-feasibility.md`
