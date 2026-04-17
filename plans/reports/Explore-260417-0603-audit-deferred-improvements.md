# ValidationForge Skills Audit: Pass 2 Deferred Improvements

**Date:** 2026-04-17 | **Skills audited:** 48 | **Deferred items:** 56

---

## Bundled scripts to create (10 items)

| Skill | Script filename | Purpose |
|---|---|---|
| ai-evidence-analysis | `detect-evidence-type.sh` | Detect evidence JSON type (screenshot/api-response/cli-output) with safe fallbacks |
| api-validation | `crud-validator.sh` + `auth-test.sh` + `error-response-test.sh` | HTTP method validation, auth flow testing, error code classification |
| e2e-validate | `detect-platform.sh` | Platform detection script (reuse from plugin root or relocate into skill) |
| forge-execute | `forge-init.sh`, `forge-execute.sh`, `forge-rebuild.sh` | Stateful forge loop orchestration with plan→state→rebuild→reexecute flow |
| forge-plan | `forge-plan.sh`, `consensus-merge.sh` | Feature prioritization and multi-perspective merge logic |
| forge-setup | `detect-platforms.sh`, `install-rules.sh`, `scaffold-directories.sh` | Platform detection, rule installation, directory scaffolding |
| fullstack-validation | `fullstack-validate.sh`, `db-validate.sh`, `api-validate.sh`, `frontend-validate.sh`, `integration-validate.sh` | Per-layer validation harnesses with framework-specific branching |
| ios-validation-runner | `ios-runner.sh` | PID state tracking, interactive pause/resume, phases 1-5 orchestration |
| no-mocking-validation-gates | `scan-for-mocks.sh` | Preflight static analysis for mock detection (complements runtime hook) |
| web-validation | `web-validation-harness.sh` | Framework detection, port discovery, test step orchestration |

---

## Bundled references to create (5 items)

| Skill | Reference file | Status | Note |
|---|---|---|---|
| ai-evidence-analysis | `references/analysis-protocol.md` | High-impact | Body currently 354 lines; split into minimal SKILL.md (<120 lines) + protocol reference |
| ai-evidence-analysis | `references/quick-start-example.md` | Medium-impact | End-to-end example requires real test evidence (better done with test run) |
| e2e-validate | Verify workflow + platform reference files | Verified ✓ | All 10 workflow files and 10 reference files confirmed present |
| functional-validation | Verify platform skill cross-references | Verified ✓ | All 5 platform skills (ios, web, api, cli, fullstack) exist and are correct |
| functional-validation | Verify bundled reference files | Verified ✓ | All 4 files present: evidence-capture-commands.md, common-failure-patterns.md, quick-reference-card.md, team-adoption-guide.md |

---

## Body restructures (34 skills, oversized/low-priority SKILL.md improvements)

| Skill | Line count | Audit priority | Reason deferred |
|---|---|---|---|
| accessibility-audit | 238 | Medium | Scoring rules lack rationale; keyboard test protocol needs examples — better as subagent work |
| baseline-quality-assessment | 94 | Low | Already lean; description was primary gap |
| build-quality-gates | 193 | Low | Well-organized across 4 gates; description was the issue |
| chrome-devtools | 222 | Low | Clear MCP tool references; description was gap |
| cli-validation | 208 | Low | Clear steps and examples; description was primary gap |
| condition-based-waiting | 85 | Low | Tight; 8-strategy table is scannable; references adequate |
| design-token-audit | ~150 | Low | Well-structured; description primary gap |
| design-validation | ~180 | Low | Well-structured; description primary gap |
| django-validation | 335 | Low | Large but well-sectioned by framework; body improvements are subagent-scale |
| e2e-testing | ~160 | Low | Strategic/patterns focus; body already focused |
| error-recovery | 104 | Low | 3-strike diagram and error table already strong |
| flutter-validation | 291 | Low | Large but well-structured by platform |
| forge-benchmark | ~210 | High | Still-design intent (benchmarking not empirical); body improvements blocked until feature complete |
| forge-team | 317 | Medium | Heavy with substantial architecture diagrams; restructure requires careful subagent work |
| full-functional-audit | 99 | Low | Well-scoped; description was gap |
| ios-simulator-control | ~180 | Low | Well-organized command reference |
| ios-validation | 235 | Low | Structured by step; body adequate |
| ios-validation-gate | 226 | High | Well-structured by gate; audit priority high but body is solid |
| parallel-validation | 219 | Low | Well-organized; description was gap |
| playwright-validation | ~180 | Low | Well-structured |
| preflight | 87 | Low | Lean; "How It Works", "Report Format", "Severity Levels" all clear |
| production-readiness-audit | 211 | Low | Well-organized by phase |
| react-native-validation | 354 | Low | Large but organized by platform/workflow; body reform is subagent-scale |
| research-validation | 180 | Low | Well-organized by phase |
| responsive-validation | 198 | Low | Well-structured by viewport |
| retrospective-validation | 212 | Low | Well-organized around historical analysis patterns |
| rust-cli-validation | 195 | Low | Structured |
| sequential-analysis | 192 | Low | Well-structured |
| stitch-integration | 197 | Low | Well-scoped |
| team-validation-dashboard | 172 | Low | Structured dashboard concepts |
| validate-audit-benchmarks | 80 | Low | Focused |
| verification-before-completion | 88 | Low | Lean, well-structured (Rule, Checklist, Citation Format, When to Apply) |
| visual-inspection | 191 | Low | Scoped |
| web-testing | 217 | Low | Strategic content |

---

## Other deferred fixes (7 items)

| Skill | Fix | Classification | Reason |
|---|---|---|---|
| ai-evidence-analysis | Collapse schema documentation (lines 52–84) | Micro-optimization | Schema table is useful for programmatic AnalysisResult consumption; collapsing is net negative for orchestrator-facing skill |
| coordinated-validation | Simplify verdict aggregation table (BLOCKED vs FAIL) | Semantic retention | BLOCKED ≠ FAIL semantically; distinction is important for orchestration |
| coordinated-validation | Add explicit "How to Define Agents" section | Duplication avoidance | Inline paragraph "What counts as an agent?" already covers this; section would duplicate |
| create-validation-plan | Add meta-documentation for context_priority: critical | Edge documentation | Current inline explanation sufficient; optional polish |
| forge-execute | Inject state schema excerpt into Phase 0/5 | Duplication avoidance | forge-state-schema.md already linked in 2 places; inlining duplicates without benefit |
| forge-setup | Expand config schema with additional fields | Premature extension | Fields (project_name, plugin_install_path) not yet consumed; maintenance burden outweighs benefit |
| forge-setup | Add explicit MCP server detection logic | Feature scope creep | Phase 5 now checks MCP availability with remediation; programmatic detection better handled by hooks or preflight |

---

## Summary

- **Skills with zero skipped fixes (grade A candidates for immediate use):** gate-validation-discipline
- **Skills with 1-2 skipped fixes (mostly low-priority body restructuring):** 47 skills
- **Skills with high-priority deferrals:** forge-benchmark, ios-validation-gate, forge-team (body restructure), accessibility-audit (body restructure)
- **Bundled scripts (estimated effort: ~40–60 hours):** 10 scripts across 10 skills
- **Bundled references (estimated effort: ~8–12 hours):** 2 new reference files needed (ai-evidence-analysis); 3 verifications already passed
- **Body restructures (estimated effort: subagent-scale, ~60–100 hours):** 34 skills with low-priority body improvements
- **Other micro-optimizations:** 7 items (skip, not worth follow-up effort)

**Total audit coverage:** 48/48 skills; **Pass 1 completion:** 47 changes applied, 56 deferred for Pass 2.

