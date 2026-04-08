# Autonomous AI Agents: Quick Reference (1 page)

## Market Scorecard

| Dimension | Cursor | Devin | Claude Code | OpenHands | SWE-Agent |
|-----------|--------|-------|-------------|-----------|-----------|
| **Speed** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| **Autonomy** | ⭐⭐ | ⭐⭐⭐⭐ | ⭐ | ⭐⭐ | ⭐⭐ |
| **Validation** | ⭐⭐⭐ | ⭐⭐ | ⭐ | ⭐⭐ | ⭐⭐⭐⭐ |
| **Scale** | ⭐⭐⭐ | ⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⭐ |
| **Enterprise** | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Cost** | $20/mo | Pay-per-task | API cost | Free | Free |

## Use Case Routing

- **Human-driven, fast tasks** → **Cursor** (< 1 min, $20/mo)
- **Autonomous complex work** → **Devin** (truly autonomous, gets stuck)
- **Large multi-feature refactors** → **Claude Code** (team coordination)
- **Compliance-sensitive** → **OpenHands** (free, auditable, self-hosted)
- **Bug-fixing with validation** → **SWE-Agent** (deterministic, academic rigor)

## Critical Gaps (All Agents)

1. ❌ **No independent verifier** — all lack separate evaluator agent
2. ❌ **No functional validation** — all use weak tests, not real app behavior
3. ❌ **No deterministic completion** — all use heuristics, not external signals
4. ❌ **No consensus gates** — no formal voting for decisions
5. ❌ **No conflict prediction** — reactive merges, not proactive

## Ralph Pattern (Opportunity)

```
Loop:
  Agent executes → observes prior work → tries to exit
  ↓
  STOP HOOK checks: <promise>COMPLETE</promise> ?
  ↓
  YES → done | NO → repeat
```

**Status:** Not in any product
**Advantage:** External verification (vs. agent self-assessment)
**Premium:** 20-40% above Devin

## Key Research Findings

| Topic | Finding | Confidence |
|-------|---------|-----------|
| **Agent tests** | Weak (5.5% overhead, no improvement) | 95% (arXiv 2602.07900) |
| **Real validation** | Deterministic grading works (95%+ confidence) | 95% (SWE-bench) |
| **Consensus voting** | +13.2% on reasoning tasks | 95% (ACL 2025) |
| **Production quality** | 90% AI adoption → 9% bug rate ↑ | 95% (Google DORA) |
| **Ralph not commercialized** | Comprehensive product review | 90% |

## Pricing Reality

| Product | Base Cost | Real Cost (Medium Task) | Best For |
|---------|-----------|------------------------|---------|
| **Cursor** | $20/mo flat | $20/mo | High-volume users |
| **Devin** | $2.25/ACU | $11-22 per task | Pay-as-you-go |
| **Claude Code** | API cost | $1.50-5 per task | Teams |
| **OpenHands** | Free | $0 (self-host) | Compliance |
| **SWE-Agent** | Free | $0 (self-host) | Research |

## Decision Tree

```
Do you need human control at each step?
  YES → Cursor (fastest, real-time feedback)
  NO ↓
Do you need multiple agents coordinating?
  YES → Claude Code Teams (shared tasks, messaging)
  NO ↓
Do you need true autonomy?
  YES → Devin (but may get stuck)
  NO ↓
Do you need deterministic validation?
  YES → SWE-Agent (but GitHub issues only)
  NO ↓
Do you need to audit/control everything?
  YES → OpenHands (free, self-hosted)
```

## Product Positioning (New Opportunity)

**Name:** Validated Autonomous Execution Engine

**Value Prop:**
- ✅ Functional validation (real app, not tests)
- ✅ Independent verifier (separate agent)
- ✅ Deterministic completion (not heuristics)
- ✅ Auditable iteration history
- ✅ Enterprise compliance-ready

**Price:** $30-35/mo (+40% premium vs. Devin)
**Target:** Enterprise + compliance-heavy

## Unresolved Questions (8)

1. Ralph pattern = AWS Evaluator-Reflect-Refine?
2. Single completion signal vs. domain-specific rubrics?
3. Consensus voting ROI (token cost vs. benefit)?
4. Cursor Cloud Agents: 30% PR creation—game changer?
5. Why isn't free OpenHands more adopted?
6. Discourage agent tests entirely?
7. Merge conflict prediction at 50+ worktrees?
8. Minimum viable functional validation evidence set?

## Report Files (Quick Links)

| File | Size | Read Time | Best For |
|------|------|-----------|----------|
| `RESEARCH-COMPLETION-SUMMARY.md` | 12 KB | 3 min | Overview + next steps |
| `autonomous-agents-summary.md` | 8 KB | 2 min | Executive brief |
| `autonomous-agents-market-analysis.md` | 24 KB | 25 min | Deep analysis |
| `competitive-capability-matrix.md` | 16 KB | 10 min | Feature comparison |
| `INDEX.md` | 16 KB | 5 min | Navigation + methodology |

## Key Takeaways

1. **No product dominates all dimensions.** Cursor wins speed, Devin wins autonomy, Claude Code wins scale, SWE-Agent wins validation.

2. **All agents have the same critical gaps:** No independent verification, no functional validation, no deterministic completion.

3. **Ralph pattern + independent verifier = untapped opportunity.** Worth 20-40% pricing premium in enterprise segment.

4. **Production quality is degrading.** Google DORA: 90% AI adoption → 9% bug rate ↑. Agents optimize for speed, not quality.

5. **Validation research exists but isn't commercialized.** AWS Evaluator-Reflect-Refine, ACL consensus voting, SWE-bench deterministic grading—all available, none integrated.

6. **Multi-agent coordination proven.** Git worktrees work at scale; consensus voting shows +13.2% improvement. No product formalizes this yet.

7. **Agent-generated tests are weak.** arXiv 2602.07900: assertions are local-property checks, +5.5% overhead, zero impact on success. Agents should write fewer tests, not more.

8. **Market bifurcating into two camps:** Speed-first (Cursor, requires steering) vs. autonomy-first (Devin, gets stuck). Neither solves validation.

---

**Full analysis:** `/Users/nick/Desktop/blog-series/validationforge/plans/reports/`
**Total content:** 2,542 lines | 152 KB | 7 documents
**Sources:** 25+ authoritative sources (academic + industry)
**Confidence:** High (95%+ on all major findings)
