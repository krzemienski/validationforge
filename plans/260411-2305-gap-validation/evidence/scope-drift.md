# Scope Drift Ledger

Collected from Phase B plan-diff analysis. Ranked by severity, then temporal order.

## CRITICAL

| ID | Plan | What changed | Why it matters |
|----|------|-------------|----------------|
| SD-01 | 260411-2242-vf-gap-closure | Phase 4 "live Claude Code session" was substituted with autonomous `node hooks/foo.js <<EOF` invocation — directly contradicts plan-manual.md line 10 "CANNOT be executed autonomously". | The product's core value proposition is that hooks fire inside CC to block test file creation. Running the hook's JS directly proves the JS parses JSON correctly, **not** that CC actually dispatches PreToolUse to the hook. |
| SD-02 | 260411-2242-vf-gap-closure | Phase 5 "/validate real external project run" was substituted with direct execution of `scripts/detect-platform.sh` and a walkthrough of existing evidence directories. The `/validate` command itself never ran. | VF markets "7-phase pipeline via /validate". No one has ever seen /validate run end-to-end. README:304 admits this. The gap-closure plan claimed it was closed. |

## HIGH

| ID | Plan | What changed | Why it matters |
|----|------|-------------|----------------|
| SD-03 | 260307-unified-validationforge-product | Platform pivot: OC-first → CC-primary. OC remains as adapter. | The foundational persona prompt (vf.md) is still framed as OC-first, creating documentation/reality drift if anyone reads vf.md expecting to understand the current product. |
| SD-04 | 260408-1313-hybrid-opencode-audit | Stopped at Phase 0; Phases 1-7 silently abandoned. No retirement notice. | 7 phases worth of planned audit work exists in the plan but produced zero artifacts. A reviewer following the plan file would expect 7 more phase docs. |
| SD-05 | 260411-1731-skill-optimization-remediation | "5.0/5.0" metric measures structural pass (validate-skills.sh) not semantic quality. Only 10 of 48 skills deep-reviewed. | Any downstream doc citing "5.0/5.0" implies content quality verified. It was not. |
| SD-06 | 260411-1747-vf-grade-a-push | Benchmark scored VF by VF's own script. Self-referential. | Claim "Grade A / 96" is true against VF's own criteria but untested as a cross-project benchmark. README:284-289 added this caveat later. |
| SD-07 | 260411-2242-vf-gap-closure | Phase 6b (transcript-analyzer) was "deferred to new plan" but the new plan was never created. | Work is neither done nor actively planned. Stranded deliverable. |

## MEDIUM

| ID | Plan | What changed | Why it matters |
|----|------|-------------|----------------|
| SD-08 | 260307-unified-validationforge-product | Skill count grew from 16 target → 48 disk, with no single plan documenting the growth. Distributed across spec-* merges. | Makes "what did each plan deliver?" hard to reconstruct from git alone. |
| SD-09 | 260411-1731-skill-optimization-remediation | Plan status was `in_progress` in its own frontmatter even after VERIFICATION.md declared complete. The flip happened in a subsequent plan (260411-2242 Phase 0). | Administrative drift — status fields drift from reality. |
| SD-10 | 260411-2242-vf-gap-closure | plan.md frontmatter still `status: in_progress` despite VERIFICATION.md claiming all 15 criteria met. | Same pattern as SD-09: closure is declared in evidence files but not in the plan's own frontmatter. |
| SD-11 | PRD.md + SPECIFICATION.md | Both docs carry inventory counts (41 skills, 15 commands, 5 hooks) that pre-date the Wave 3-4 skill/command additions. | Public-facing design docs contradict README.md current inventory. |

## LOW

| ID | Plan | What changed | Why it matters |
|----|------|-------------|----------------|
| SD-12 | 260307-unified-validationforge-product | Naming convention drift: `vf.md` → `plan.md`. | Minor, affects tooling that expects one filename. |
| SD-13 | 260411-2305-gap-validation | This plan. Working tree modified on `.vf/benchmarks/benchmark-2026-04-11.json` while VERIFICATION.md (of the preceding plan) claimed "clean". | Low severity — benchmark output auto-regenerates. |

## Summary

| Severity | Count |
|----------|------:|
| CRITICAL | 2 |
| HIGH | 5 |
| MEDIUM | 4 |
| LOW | 2 |
| **Total** | **13** |

All 13 drift rows have a concrete plan + cited evidence. The gap-validation plan's rule 5 ("No silent rewrites of what was planned") is satisfied: every silent rewrite is now on the record.
