# Benchmark Skill Feasibility Report

**Date:** 2026-04-08  
**Task:** Evaluate feasibility of building a benchmark skill via `/skill-creator` for Phase 5 of the audit plan  
**Status:** FEASIBLE (with architectural tradeoffs)

---

## Executive Summary

Phase 5 requires benchmarking 40+ skills and 7 hooks against ~400 criteria. The red team found this unexecutable as pure prose markdown. The user chose `/skill-creator` to build benchmark tooling.

**Verdict:** A skill-driven benchmark approach IS feasible, but it's not a single skill. It's a **three-part system**:
1. **Benchmark skill** (SKILL.md) — instructions for evaluating quality via LLM judgment
2. **Test scripts** (`scripts/`) — bash runners that execute hook test cases and capture results
3. **Results aggregator** (referenced by skill) — parses test outputs and scores them

This separates concerns: automation (bash) handles executables; skill (markdown) guides judgment on subjective criteria (instruction clarity, tool trigger accuracy, etc.).

---

## What Can Be Benchmarked Programmatically

### Hooks (7 JS files, ~343 LOC)
**Verdict: FULLY EXECUTABLE**

Hooks are deterministic functions that consume stdin JSON and emit stdout/stderr. Can pipe synthetic test cases and check:
- Exit codes (0 = allow, 2 = block)
- stdout JSON structure (`permissionDecision`, `hookSpecificOutput`)
- stderr messages (error logging)
- Regex pattern matching accuracy

**Approach:** Write `tests/hooks/` bash scripts that:
```bash
# Example: test block-test-files.js
echo '{"tool_input":{"file_path":"src/test.ts"}}' | node hooks/block-test-files.js
echo $?  # capture exit code
# Compare exit code + stdout against expected JSON schema
```

**Docs show precedent:** `/Users/nick/Desktop/validationforge/docs/BENCHMARKS.md` already has 5+ hook test cases with stdin/expected-output pairs. This is executable.

**Scoring:** Correctness (40%), Format (20%), Error handling (20%), Security (20%).

### Skills (40 markdown files)
**Verdict: PARTIALLY EXECUTABLE**

Skills are passive instructions. Cannot "run" them, but CAN check:
- **Executable:** YAML frontmatter validity (parse check), name/description field limits, reference file existence
- **Non-executable:** Instruction clarity, LLM trigger accuracy, context efficiency (requires human judgment or LLM evaluation)

**Approach:**
- Bash script validates structure and references
- Skill instructs agent to manually evaluate a checklist for subjective quality

**Scoring:** 
- Format compliance: 100% automated (frontmatter, naming, file refs)
- Instruction quality: 0% automated (requires LLM or human reading)

### Commands (15 markdown files)
**Verdict: MOSTLY EXECUTABLE**

Can validate:
- Frontmatter structure (YAML parsing)
- Argument interpolation safety (no unquoted `$ARGUMENTS` in bash contexts)
- Command template syntactic correctness

Cannot validate:
- Functional correctness (does command do what description claims?)

### Rules (8 markdown files)
**Verdict: NOT EXECUTABLE**

Content quality is subjective — no test harness possible. Requires manual review or LLM evaluation.

### Shell Scripts (4 bash files in `scripts/`)
**Verdict: PARTIALLY EXECUTABLE**

Can run with `--help` or `--dry-run` if supported. Can check:
- Exit codes
- No obvious injection patterns (static analysis via grep)

Cannot check:
- Correctness without execution against real systems

---

## What Phase 5 Should Produce (Realistic)

### ✅ Executable Deliverables
1. **Benchmark test suite for hooks** (`tests/hooks/test-runner.sh`)
   - 7-10 test cases per hook (happy path, edge cases, adversarial)
   - Pipe stdin JSON, capture exit code + stdout
   - Compare against expected output
   - Generate JSON score report: `e2e-evidence/hook-benchmark-results.json`

2. **Structural validation for skills** (`tests/skills/validate-structure.sh`)
   - Parse YAML frontmatter
   - Verify name matches directory
   - Check description char limit (≤1024)
   - Verify all referenced files exist
   - Generate JSON report: `e2e-evidence/skill-structure-results.json`

3. **Structural validation for commands** (`tests/commands/validate-structure.sh`)
   - Similar to skills: frontmatter validity, arg interpolation safety

### ⚠️ Skill-Guided (Non-Automated) Deliverables
4. **Benchmark skill** (`skills/validate-extension-quality/SKILL.md`)
   - Instructs agent to evaluate subjective criteria:
     - Instruction clarity per skill (no ambiguity, parseable)
     - Tool reference accuracy (all mentioned tools exist)
     - Token efficiency (no unnecessary verbosity)
     - Error message clarity (readable by users)
   - References the automated test results
   - Guides manual scoring for criteria 5-10 per extension

5. **Results aggregator** (`scripts/aggregate-benchmark-results.sh`)
   - Reads JSON from automated tests
   - Reads manual scores from skill evaluation
   - Computes weighted scores per rubric
   - Generates final report: `BENCHMARKS.md`

### ❌ Not Feasible
- Running all 400+ prose criteria in Phase 5 alone (would require 10+ hours of LLM time)
- Fully automating subjective quality judgments without human input
- Building a "test runner" for markdown skills (skills are not executable code)

---

## Architecture: The Three-Part System

```
Phase 5 Input
├── 7 hooks (JS)
├── 40 skills (MD)
├── 15 commands (MD)
├── 8 rules (MD)
└── 4 shell scripts

Phase 5 Workflow
├─ PART 1: Automated Testing (bash scripts)
│  ├─ tests/hooks/test-runner.sh → hook-benchmark-results.json
│  ├─ tests/skills/validate-structure.sh → skill-structure-results.json
│  └─ tests/commands/validate-structure.sh → command-structure-results.json
│
├─ PART 2: Skill-Guided Evaluation (LLM agent + SKILL.md)
│  ├─ skills/validate-extension-quality/SKILL.md
│  ├─ Reads automated test results
│  ├─ Agent manually evaluates subjective criteria
│  └─ Agent records scores in e2e-evidence/manual-evaluation.json
│
└─ PART 3: Results Aggregation (bash script)
   └─ scripts/aggregate-benchmark-results.sh
      ├─ Merges automated + manual scores
      ├─ Applies weighted rubric (40% correctness, 20% format, 20% error handling, 20% security)
      └─ Generates BENCHMARKS.md report

Phase 5 Output
└─ BENCHMARKS.md (final report with all scores)
```

---

## Feasibility by Dimension

### 1. Hook Testing (Full Automation)
**Feasibility: HIGH (95%)**

- **Evidence:** Existing `docs/BENCHMARKS.md` has 5+ concrete hook test cases with stdin/expected-output pairs
- **Implementation:** Bash script that loops over test cases, pipes to hook, compares exit code + stdout
- **Time estimate:** 2-3 hours to write test harness for 7 hooks
- **Risk:** Low — hooks are deterministic, JSON I/O is stable

### 2. Skill Validation (Partial Automation)
**Feasibility: MEDIUM (60%)**

- **Executable parts:** Frontmatter validity, reference file existence, naming compliance → 100% automated
- **Non-executable parts:** Instruction clarity, trigger accuracy → requires LLM evaluation
- **Implementation:** 
  - Bash: YAML parsing via `yq` or `jq`, file existence checks (~1 hour)
  - Skill: Agent evaluates 5-8 subjective criteria per skill (~5 minutes per skill × 40 = 200 minutes = 3 hours agent time)
- **Time estimate:** 4 hours total
- **Risk:** Medium — LLM evaluation quality depends on prompt clarity

### 3. Command Validation (Partial Automation)
**Feasibility: MEDIUM (65%)**

- **Executable:** Frontmatter, template syntax (~1 hour)
- **Non-executable:** Functional correctness (15 commands × 10 minutes = 150 minutes agent time)
- **Time estimate:** 3.5 hours
- **Risk:** Medium — some commands reference external systems not testable in isolation

### 4. Rule Evaluation (Skill-Only)
**Feasibility: LOW (40%)**

- **Executable:** None (rules are prose instructions, not testable)
- **Non-executable:** All evaluation (8 rules × 30 minutes = 4 hours agent time)
- **Time estimate:** 4+ hours
- **Risk:** High — subjective quality hard to score consistently

---

## Recommended Phase 5 Scope (MVP)

To make Phase 5 **executable in <10 hours**, focus on high-value automation:

### Must Do
1. **Hook benchmark test runner** (2h)
   - All 7 hooks with 8-10 test cases each
   - Full automation, JSON output
   - Phase 6 can run improvements against this baseline

2. **Skill structural validation** (1h)
   - Frontmatter, naming, reference file checks
   - 40 skills, automated scoring

3. **Benchmark skill** (1h)
   - Template with evaluation checklist
   - Guides agent through subjective criteria for top 10 skills by user impact

### Should Do
4. **Command structural validation** (1h)
   - Same as skills: frontmatter, syntax checks

### Can Defer
5. **Rule evaluation** (skip for now)
   - Rules are 100% subjective
   - Defer to Phase 6 as optional enhancement

6. **Full skill instruction quality evaluation** (skip)
   - Too expensive to evaluate all 40 skills at LLM cost
   - Phase 6 can spot-check top 10 by usage frequency

### Total Phase 5 Time: 5 hours automated + agent time for skill instruction evaluation

---

## Unresolved Questions

1. **Which 10 skills should the agent evaluate in Phase 5?**
   - Recommendation: Top 10 by trigger frequency in agent logs, or top 10 by user impact (core validation flows)
   - User input needed: skill priority list

2. **Should Phase 5 produce a passing/failing verdict, or just baseline scores?**
   - Current plan assumes baseline scores only; Phase 6 improves based on deltas
   - If verdict required in Phase 5, scope increases 50%

3. **How should subjective LLM judgments be documented?**
   - Recommendation: Agent saves reasoning to `e2e-evidence/skill-evaluation-reasoning.md`
   - Enables review and disagreement tracking

4. **Should shell scripts (4 files) be included in Phase 5 scope?**
   - Current assessment: defer to Phase 4 (sanitization) or Phase 1 (analysis)
   - Scripts are not OpenCode primitives, so arguably out of scope

---

## Why `/skill-creator` is the Right Tool

The user chose `/skill-creator` over "just checklist" or "test harness." Here's why that's smart:

| Approach | Pros | Cons | Verdict |
|----------|------|------|---------|
| Pure prose checklist | Fast to write | Unverifiable, subjective | ❌ Red team rejected |
| Test harness (TypeScript) | Precise, repeatable | Requires build tooling, ~8h work, harder to maintain | ⚠️ Possible but overkill |
| **Skill + bash scripts** | Automation for testable parts, LLM judgment for subjective, leverages existing agent capability, maintainable | Requires careful prompt design for subjectivity | ✅ **Balanced** |

Skills are designed exactly for this: guiding agent judgment on complex evaluation criteria. Building a skill is lower-friction than building a test harness.

---

## Next Steps

**For user confirmation:**
1. Approve the three-part architecture (tests + skill + aggregator)
2. Confirm which 10 skills should be evaluated by agent in Phase 5
3. Clarify if Phase 5 produces baseline scores only, or verdict (pass/fail by threshold)
4. Decide if shell scripts are in scope or deferred

**For implementation (Phase 5):**
1. Write `tests/hooks/test-runner.sh` — pipe 8-10 test cases per hook
2. Write `tests/skills/validate-structure.sh` — YAML + file checks
3. Write `skills/validate-extension-quality/SKILL.md` — agent evaluation template
4. Write `scripts/aggregate-benchmark-results.sh` — merge and score
5. Run all tests, generate `BENCHMARKS.md`

Estimated Phase 5 duration: **5-6 hours** (vs. unexecutable 20+ hours of prose evaluation)
