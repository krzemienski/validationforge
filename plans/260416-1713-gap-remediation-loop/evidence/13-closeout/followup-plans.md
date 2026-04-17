# Follow-Up Plans Scaffolded — Campaign 260416-1713

## Summary

5 follow-up plans created to address BLOCKED_WITH_USER items and NEEDS_FIX skills identified during the gap remediation campaign. All plans are standalone stubs (30–60 lines each) ready for execution in V1.5/V2.0 planning cycles.

## Plans Created

| Plan Dir | File | Bytes | Purpose | Gap ID | Status |
|----------|------|-------|---------|--------|--------|
| `260416-2230-demo-scaffolding-for-b5` | `plan.md` | 924 | Demo oracle scaffolding for B5 (5-scenario benchmark) | B5 | pending |
| `260416-2230-skill-triggers-fix` | `plan.md` | 859 | Add invocation triggers for 4 skills (flutter, full-functional-audit, fullstack, rust-cli) | NEEDS_FIX | pending |
| `260416-2230-engines-v1.5-consensus-bed` | `plan.md` | 1,108 | CONSENSUS engine test bed (multi-agent voting, 3+ scenarios) | CONSENSUS | pending |
| `260416-2230-engines-v2.0-forge-bed` | `plan.md` | 1,266 | FORGE engine real-system exercise (defect detection + fix loops) | FORGE | pending |
| `260416-2230-docs-5of5-scrub-residual` | `plan.md` | 994 | Residual 5/5 vs 0/5 language cleanup (PRD.md, MARKETING-INTEGRATION.md) | P12_REGRESSION_RESIDUAL | pending |

**Total bytes:** 5,151 (average 1,030 bytes/plan)

## Plan Execution Priority

1. **Immediate (post-campaign):** `skill-triggers-fix` (30 min) — quick metadata update, no code changes
2. **V1.5 (next cycle):** `demo-scaffolding-for-b5`, `engines-v1.5-consensus-bed` — blockers for B5 retry + CONSENSUS validation
3. **V1.5 (concurrent):** `docs-5of5-scrub-residual` (15 min) — quick doc cleanup, can run anytime
4. **V2.0 (future):** `engines-v2.0-forge-bed` — depends on V1.5 CONSENSUS bed stability

## Next Steps

- **V1.5 Lead:** Review all 5 plans; prioritize skill-triggers-fix first, then demo-scaffolding-for-b5
- **V1.5 Schedule:** B5 retry + CONSENSUS bed in parallel after demo oracle ready
- **V2.0 Lead:** Schedule FORGE bed after V1.5 CONSENSUS bed reaches feature parity

---

All plans follow the same structure: frontmatter + Why + Acceptance Criteria + Inputs + Steps + Success Criteria. Ready for immediate execution.
