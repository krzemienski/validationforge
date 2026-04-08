# Red Team Review — vf.md Audit Plan

**Date:** 2026-04-08
**Plan:** `plans/260307-unified-validationforge-product/vf.md`
**Reviewers:** 4 (Security Adversary, Assumption Destroyer, Failure Mode Analyst, Scope & Complexity Critic)
**Raw findings:** 35 → **Deduplicated:** 15 (5 Critical, 7 High, 3 Medium)
**Accepted:** 15 / 15

---

## Summary

The plan has a **fundamental identity crisis**: it audits a dual-platform Claude Code + OpenCode plugin as if it were a pure OpenCode system. All 4 reviewers independently identified this as the #1 blocker. Secondary issues: unexecutable benchmark phases, no context checkpointing, impossible gate conditions, and over-engineering for the actual codebase size (~838 LOC executable code, ~22K LOC markdown).

## Severity Breakdown

| Severity | Count | Key Theme |
|----------|-------|-----------|
| Critical | 5 | Wrong platform framing, false inventory, unexecutable benchmarks, no checkpointing, write conflicts |
| High | 7 | Real security bugs unscoped, no rollback, impossible gates, no MVP cut, duplicate logic |
| Medium | 3 | Invalid hook type, fabricated finding in synthesis, constraint contradictions |

---

## Findings

### Critical

| # | Finding | Disposition | Applied To |
|---|---------|-------------|------------|
| 1 | Plan targets wrong platform — audits CC plugin as OpenCode-only | Accept | Identity, all phases |
| 2 | Phase 0 inventory claims opencode.json/.opencode/ don't exist — both verified present | Accept | Phase 0 |
| 3 | Phase 5/6 benchmarks unexecutable — no runner, skills are markdown, 400+ criteria for prose | Accept | Phase 5, 6 |
| 4 | Context compaction destroys Phase 4 state — 67+ files, no checkpointing | Accept | Phase 4 |
| 5 | Phase 3A/3B parallel creates README write conflict — both phases write to same file | Accept | Phase 3A, 3B |

### High

| # | Finding | Disposition | Applied To |
|---|---------|-------------|------------|
| 6 | OC plugin has unsanitized args — shell injection via string interpolation, path traversal via join() | Accept | Phase 4 scope |
| 7 | Duplicate enforcement logic — CC hooks and OC plugin have independent regex copies | Accept | Phase 1 scope |
| 8 | Shell scripts unaudited — health-check.sh (SSRF), install.sh (highest-trust file) never in scope | Accept | Phase 0 scope |
| 9 | Phase gates use impossible absolutes — "zero unsanitized inputs" + "all extensions improve" | Accept | All gates |
| 10 | No rollback strategy — half-audited state with no revert path | Accept | Phase 2 |
| 11 | 8 sequential phases with no MVP cut — P0 bugs blocked behind documentation rewrites | Accept | Plan structure |
| 12 | Phase 3A gate unverifiable by AI — "zero context developer can install" can't be tested in-place | Accept | Phase 3A gate |

### Medium

| # | Finding | Disposition | Applied To |
|---|---------|-------------|------------|
| 13 | `shell.env` hook in index.ts may be invalid — not in plan's own plugin_format_spec | Accept | Phase 1 scope |
| 14 | Synthesis report `|| true` finding is fabricated — hooks.json verified: no `|| true` anywhere | Accept | Phase 1 artifacts |
| 15 | Constraints contradict — "no meta-discussion" vs "report blockers with evidence" | Accept | Constraints |

---

## Recommended Plan Restructure

Based on findings, the plan should be **rewritten from scratch** as a 3-phase value-first approach:

### Phase 1: Fix Real Bugs (high-value, immediate)
- Sanitize `index.ts` args (shell injection, path traversal)
- Fix `permission.ask` deny-list incompleteness
- Verify `shell.env` hook validity against OC SDK docs
- Audit `install.sh` and `health-check.sh` for injection
- Consolidate duplicate pattern definitions
- Checkpoint: `audit-progress.json` per file

### Phase 2: Documentation Corrections (patch, not rewrite)
- Correct existing README/ARCHITECTURE with verified facts
- Remove fabricated `|| true` finding from synthesis
- Document dual-platform architecture (CC primary, OC secondary)
- Delete or archive redundant docs (SPECIFICATION, PRD if duplicative)

### Phase 3: Quality Rubric (checklist, not benchmarks)
- Structural checks: frontmatter validity, reference file existence, naming compliance
- Manual rubric for skill instruction quality (5 criteria, not 10)
- Security checklist for the 2 TS files + 7 JS hooks + 4 shell scripts
- Prioritized exit criteria: "All P0 fixed. P1 documented. No regressions."

---

## Validation Log

### Session 1 — 2026-04-08
**Trigger:** Post-red-team validation of vf.md plan
**Questions asked:** 4

#### Questions & Answers

1. **[Architecture]** The plan is framed as a pure OpenCode audit, but the codebase is primarily Claude Code with a secondary OpenCode TS plugin. How should the plan be reframed?
   - Options: Dual-platform audit (Recommended) | Claude Code only | Rewrite plan from scratch
   - **Answer:** Rewrite plan from scratch
   - **Rationale:** User confirmed the plan is fundamentally misframed. A new plan must be written that correctly targets the dual-platform reality.

2. **[Scope]** The plan has 8 sequential phases with strict gates. The red team found this buries high-value bug fixes behind hours of inventory and documentation work. How should phases be structured?
   - Options: Value-first 3 phases (Recommended) | Keep 8 phases reordered | Keep 8 phases as-is
   - **Answer:** Keep 8 phases as-is
   - **Rationale:** User wants to preserve the 8-phase structure despite the rewrite. New plan should maintain this granularity but fix the platform framing.

3. **[Tradeoffs]** Phase 5 requires 400+ benchmark criteria for prose markdown files with no test runner. What should replace this?
   - Options: Rubric checklist only (Recommended) | Manual LLM evaluation | Build a test harness
   - **Answer:** Use `/skill-creator` to build benchmark tooling
   - **Custom input:** "use /skill-creator"
   - **Rationale:** User wants to leverage the skill-creator workflow to build proper benchmark/evaluation tooling rather than accepting any of the proposed alternatives. This could create a skill that acts as the benchmark execution mechanism.

4. **[Risk]** The OpenCode plugin at .opencode/plugins/validationforge/index.ts has real security issues. Should the OC plugin security fixes be prioritized?
   - Options: Fix now as P0 (Recommended) | Include in audit scope only | Defer to OpenCode track
   - **Answer:** Defer to OpenCode track
   - **Rationale:** User wants to handle OC plugin security in a separate OpenCode-specific track, keeping the primary plan focused on Claude Code.

#### Confirmed Decisions
- **Platform framing:** Rewrite from scratch — plan must target dual-platform reality correctly
- **Phase structure:** Keep 8 phases — preserve audit granularity
- **Benchmarks:** Use /skill-creator to build benchmark tooling — not just a checklist
- **OC security:** Defer to separate track — don't mix CC and OC fixes

#### Action Items
- [ ] Rewrite vf.md from scratch with correct dual-platform framing
- [ ] Maintain 8-phase structure but fix all platform-specific references
- [ ] Use /skill-creator in Phase 5 to build benchmark execution skill
- [ ] Create separate OC audit track for .opencode/ TypeScript plugin security

#### Impact on Phases
- **All phases:** Must be rewritten — current OpenCode framing is invalid
- **Phase 5:** Benchmark methodology changes from prose document to skill-creator workflow
- **Phase 4:** OC plugin security deferred — phase focuses on CC hooks only
- **Phase 3A/3B:** Must resolve README write conflict and fix platform-specific docs

---

## Verdict

**Recommendation: REVISE — plan requires full rewrite before execution.**

The red team found 5 Critical, 7 High, 3 Medium issues. The user confirmed the most severe finding (wrong platform framing) and chose to rewrite from scratch while preserving the 8-phase structure.

**Next steps:**
1. Rewrite `vf.md` as a dual-platform audit plan (CC primary, OC secondary track)
2. Use `/skill-creator` during Phase 5 to build benchmark execution tooling
3. Add checkpointing to Phase 4 for context compaction resilience
4. Fix phase gates from absolutes to prioritized exit criteria
