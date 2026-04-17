# ValidationForge Inventory Audit — 2026-04-17

## Summary

**Status:** MULTIPLE DISCREPANCIES DETECTED  
**Severity:** MODERATE (counts mismatched in 3/5 docs; 2 skills missing from SKILLS.md; 1 command missing; description drift in CLAUDE.md Forge Orchestration category)

---

## File-by-File Audit

### README.md

**Claimed counts (line 5):**
```
52 skills | 19 commands | 7 registered hooks (+3 support .js) | 7 agents | 9 rules
```

**Real counts:**
- Skills: 52 ✓
- Commands: 19 ✓
- Hooks: 7 .js files ✓
- Agents: 7 ✓
- Rules: 9 ✓

**Match:** YES

**Note:** Line 28 claims "48 skills, 17 commands, 5 agents" — **STALE** (case study from earlier version).  
Line 319 repeats stale inventory: "48 skills, 17 commands, 7 hooks, 5 agents, 8 rules".

**Description drift:** None detected in header claims.

**Fix complexity:** TRIVIAL (update two lines with current counts)  
**Estimated lines to change:** 2 (lines 28, 319)

---

### SKILLS.md

**Claimed count (line 3):**
```
51 skills across 8 categories
```

**Real count:** 52 skills on disk

**Missing entries (in doc, not listed):**
- `e2e-testing` (Specialized category, on disk)
- `e2e-validate` (Specialized category, on disk)

**Match:** NO — claims 51, but lists 51 unique entries (CLAUDE.md shows all 52)

**Phantom entries:** None detected

**Description drift samples:**
- SKILLS.md line 10: `ios-validation-gate` → "Three-gate iOS validation"
  - SKILL.md: "Gates-based iOS validation with explicit PASS/FAIL gates" (acceptable variation)
- SKILLS.md line 87: `team-validation-dashboard` → "Aggregate team validation metrics..."
  - SKILL.md frontmatter: "Aggregate team validation posture..." (acceptable variation)

No critical drift detected.

**Fix complexity:** MODERATE (add 2 missing skills to index)  
**Estimated lines to change:** 3 (header count + 2 skill rows)

---

### COMMANDS.md

**Claimed count (line 3):**
```
18 slash commands across 2 families
```

**Real count:** 19 commands on disk

**Missing entries (in doc, not listed):**
- `/validate-dashboard` (Validation Commands family, on disk at `/Users/nick/Desktop/validationforge/commands/validate-dashboard.md`)

**Match:** NO — claims 18, actual is 19

**Phantom entries:** None detected

**Description drift:** None detected

**Fix complexity:** TRIVIAL (update count + add 1 row to Validation Commands table)  
**Estimated lines to change:** 2

---

### HOOKS.md

**Status:** FILE DOES NOT EXIST

Hook documentation is present in:
- CLAUDE.md (lines 180–190): Documents all 7 hooks with triggers and purposes
- README.md (lines 162–170): Detailed hook table

No separate HOOKS.md file required; coverage is adequate in CLAUDE.md and README.md.

---

### CLAUDE.md

**Claimed counts (line 133–139, 142, 168, 180, 192):**
- Commands: 19 ✓
- Skills: 52 ✓
- Agents: 7 ✓
- Hooks: 7 ✓
- Rules: 8 ✗ (actual: 9)

**Real counts matched:** 4/5

**Missing entries:**
- **Rules section (line 192):** Missing `consensus-engine.md` from rules/ directory
  - On disk: `/Users/nick/Desktop/validationforge/rules/consensus-engine.md`
  - Doc lists only 8 rules (validation-discipline, execution-workflow, evidence-management, platform-detection, team-validation, benchmarking, forge-execution, forge-team-orchestration)

**Phantom entries:** None detected

**Description drift (Forge Orchestration, line 163):**
- CLAUDE.md lists: `forge-setup, forge-plan, forge-execute, forge-team, forge-benchmark, validate-audit-benchmarks, team-validation-dashboard, coordinated-validation`
- **Issue:** `coordinated-validation` is **NOT a Forge Orchestration skill** — it's a Specialized skill.
- This creates category confusion: coordinated-validation appears in both Specialized AND Forge Orchestration, doubling its coverage claim.

**Fix complexity:** MODERATE (1 missing rule; 1 miscategorization; 1 count fix)  
**Estimated lines to change:** 3 (rules count line + 1 rule row + move coordinated-validation out of Forge Orchestration)

---

## Discrepancy Summary

| Issue | File(s) | Severity | Fix Type |
|-------|---------|----------|----------|
| Skills count 51 vs 52 | SKILLS.md | HIGH | Missing 2 entries |
| Commands count 18 vs 19 | COMMANDS.md | HIGH | Missing 1 entry |
| Rules count 8 vs 9 | CLAUDE.md | HIGH | Missing 1 entry |
| Stale inventory (48/17/5) | README.md | MEDIUM | Out of sync |
| Categorization drift | CLAUDE.md | MEDIUM | coordinated-validation misplaced |

---

## Prioritized Fix List (Blast Radius → Effort)

1. **SKILLS.md line 3:** Change "51 skills" → "52 skills" (1 word change)
2. **SKILLS.md Specialized section:** Add `e2e-testing` and `e2e-validate` (2 rows)
3. **COMMANDS.md line 3:** Change "18 slash commands" → "19 slash commands" (1 word)
4. **COMMANDS.md Validation Commands:** Add `/validate-dashboard` row (1 row)
5. **CLAUDE.md line 142:** Change skill count "52" if currently wrong (verify)
6. **CLAUDE.md Rules section:** Add `consensus-engine` rule (1 row); update count 8→9
7. **CLAUDE.md Forge Orchestration:** Remove `coordinated-validation` from list (move to Specialized only)
8. **README.md lines 28, 319:** Update stale inventory claims (2 lines)

**Total estimated effort:** ~10 lines across 4 files. **Elapsed time to fix: <5 minutes**.

---

## Evidence

- Disk counts verified 2026-04-17 13:52 (see task preamble)
- All skill/command/hook/agent/rule directories enumerated via `find` + `ls`
- SKILLS.md/COMMANDS.md/CLAUDE.md parsed via grep for content extraction
- Cross-reference: SKILLS.md lists 51 × 8 categories ≠ 52 actual skills
- Cross-reference: COMMANDS.md lists 18 ÷ 2 families ≠ 19 actual commands
- Cross-reference: CLAUDE.md lists 8 rules, but `rules/` contains 9 files
