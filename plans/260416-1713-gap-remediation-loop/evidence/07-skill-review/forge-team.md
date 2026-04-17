---
name: forge-team
skill_name: forge-team
review_date: 2026-04-16
reviewer: P07-R2
---

## Frontmatter Check

| Field | Status | Notes |
|-------|--------|-------|
| name | ✅ PASS | "forge-team" |
| description | ✅ PASS | 156 chars; clear summary of wave-based parallel validation |
| triggers | ✅ PASS | 3 trigger phrases; all realistic |
| context_priority | ✅ PASS | "reference" — correct. Team mode is for multi-platform projects. |
| YAML parses | ✅ PASS | Valid |

## Body-Description Alignment

**Description claims:**
> Multi-agent parallel validation with wave-based dependencies: DB/Design → API → Web/iOS. Each validator owns isolated evidence directory. Blocks downstream on upstream failure. Use for fullstack.

**Body delivers:**
- Multi-agent (Architecture: Lead + 6 validators + verdict writer)
- Wave-based dependencies (Dependency Graph: Wave 0 → Wave 1 → Wave 2)
- DB/Design → API → Web/iOS order (lines 34-40: explicit dependency chain)
- Isolated evidence directories (lines 288-294: each validator exclusively owns directory)
- Blocks downstream on upstream failure (Section: Blocked Validator Handling, lines 138-163)
- Use for fullstack (Trigger: "Projects with 2+ detected platforms")

**Verdict:** ✅ **PASS** — Body delivers on all claims.

## Wave-Based Orchestration Sophistication

**Wave execution loop** (lines 87-127): For each wave, spawn all validators in parallel, wait for all to complete, evaluate failures, propagate blocking to dependents. Prevents wasting compute on broken dependencies.

**BLOCKED handling** (lines 138-163): Transitive blocking (if API FAILs, Web and iOS are BLOCKED). BLOCKED is distinct from FAIL (root cause attribution differs). Clear protocol.

**Conflict resolution** (lines 297-304): Includes dependency cycle detection ("halt orchestration, report error, require manual review"). Prevents infinite loops.

## Verdict

**Status:** ✅ **PASS**

This skill is sophisticated multi-agent orchestration. Wave-based dependencies are correct, evidence ownership is rigorous, conflict resolution is thoughtful. No blocking issues.

### Proposed Patches
None required.

### Follow-Ups
**Verify:** Does the coordinated-validation skill (R4 partition) exist and provide the dependency graph API referenced on line 116?
