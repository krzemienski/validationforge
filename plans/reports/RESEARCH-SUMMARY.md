# Developer Tool Benchmarks: Research Summary
**Quick Reference** | 2026-03-07

Full report: `/Users/nick/Desktop/blog-series/validationforge/plans/reports/researcher-260307-1510-benchmark-design-for-validation-tools.md` (743 lines)

---

## 5 Core Benchmark Principles

| Principle | Why | How |
|-----------|-----|-----|
| **Reproducibility** | Results must be independently verifiable | Version control, containers, metadata logging, deterministic execution |
| **Transparency** | Build trust through openness | Public datasets, methodology docs, auditable code, no cherry-picking |
| **Real-World Relevance** | Synthetic benchmarks don't reflect reality | Start with curated real scenarios (GitHub commits); add synthetic edge cases |
| **Multi-Metric Evaluation** | Prevents Goodhart's Law gaming | Precision + Recall + F1 + Coverage; never single-number rankings |
| **Continuous Validation** | Catch regressions automatically | CI integration, baseline comparison, timestamped results |

---

## Benchmark Landscape

### Code Generation Benchmarks
- **HumanEval (164 problems):** Industry standard; pass@k metric; 28.8%→96.3% in 4 years
- **MBPP (1,000 problems):** Google benchmark; real problem framing; 58% pass rate
- **SWE-Bench (1,865 problems):** Real GitHub issues; execution-based success; dual pass→pass + fail→pass

### Bug Detection / Security Benchmarks
- **OWASP Benchmark:** Executable apps, CWE-mapped, precision/recall/F1
- **CASTLE:** 250 micro-benchmarks, 25 CWEs; surprising: LLMs (F1=0.753) > static tools (F1=0.386)
- **Snyk / SonarQube / Semgrep:** Detection rates <38% combined; teams use all 3 together

---

## Metrics that Matter (Validation Tools)

### Primary Metrics
| Metric | Formula | Target | Why |
|--------|---------|--------|-----|
| **Recall (Detection Rate)** | TP/(TP+FN) | 60-85% | Misses = broken tool |
| **Precision** | TP/(TP+FP) | >70% | High FP = tool ignored |
| **F1 Score** | 2(P·R)/(P+R) | >0.70 | Balanced metric |
| **False Positive Rate** | FP/(FP+TN) | <30% | Developer trust |
| **Time-to-Evidence** | Median(invocation→first_TP) | <100ms | DevEx metric |

### Secondary Metrics
- **CWE Coverage:** % of weakness categories handled (25 CWEs = comprehensive)
- **Value-Add Ratio:** % of tool detections that unit tests miss (target: >40%)
- **Scenario Difficulty:** Complexity distribution (simple, medium, hard)

---

## Actionable 5-Step Plan

### Phase 1: Launch (3-6 months)
1. Curate 20-50 real scenarios (GitHub commit reversions)
2. Open repository with full methodology docs
3. Evaluate 3-4 tools (including market leaders)
4. Multi-dimensional scorecard (no leaderboard)
5. GitHub Actions CI: PR benchmark → main baseline comparison

### Phase 2: Scale (6-12 months)
1. Grow to 200+ scenarios
2. Automated scenario QA (test oracle verification)
3. 8-10 tools evaluated
4. Academic partnership for independent validation

### Phase 3: Credibility (12+ months)
1. 500+ scenarios, diverse CWEs/languages
2. Published research paper
3. Third-party audits
4. Industry adoption metrics

---

## Repository Structure (Battle-Tested)

```
validation-benchmark/
├── scenarios/
│   ├── metadata.yaml                    # All scenarios: CWE, source, complexity
│   ├── 001-sql-injection/
│   │   ├── buggy/                       # Pre-fix state
│   │   ├── fixed/                       # Post-fix state
│   │   └── scenario.yaml                # Detailed metadata
│   └── 002-race-condition/ ...
├── tools/
│   ├── base-evaluator.py                # Shared harness logic
│   ├── semgrep-eval.py                  # Tool-specific harness
│   └── codeql-eval.py ...
├── results/
│   ├── latest/                          # Current results
│   └── history/                         # Timestamped results
├── .github/workflows/
│   ├── benchmark-ci.yml                 # PR (no secrets)
│   └── benchmark-main.yml               # Main (baseline compare)
├── docs/
│   ├── METHODOLOGY.md                   # Design rationale
│   ├── SCENARIO-DESIGN.md               # How scenarios created
│   └── LIMITATIONS.md                   # Honest gaps
└── scripts/
    ├── run-all-evals.sh
    ├── compare-baselines.py
    └── generate-report.py
```

**Key Pattern:** Scenarios in version control; results in CI artifacts; tools have tool-agnostic base class

---

## What Wins: Benchmark Adoption Factors

### Credibility Drivers (High Impact)
✅ Independent evaluators (not vendor)
✅ Published methodology paper
✅ Open datasets (GitHub/Zenodo)
✅ Honest documentation of gaps
✅ Multi-metric scorecards (not rankings)
✅ GitHub CI with regression detection

### Credibility Killers (High Impact)
❌ Vendor-only benchmarks
❌ Single-metric leaderboards (gaming-prone)
❌ Closed datasets
❌ Marketing-driven scenario selection
❌ No methodology docs

### Real-World Insights
- **78% false positives:** Real static analysis studies report 76-90% FP rates
- **No tool wins:** Combined Snyk + CodeQL + Semgrep + FindSecBugs only catches 38.8% of bugs
- **Teams run multiple tools:** Practitioners use Snyk AND SonarQube together, not "best one"
- **Cost of FP:** High FP = developers ignore all warnings (developer trust metric critical)

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It's Bad | Better Approach |
|--------------|-------------|-----------------|
| Synthetic-only bugs | Doesn't match real distribution | Start with real commits, add synthetic edge cases |
| Single-metric ranking | Invites gaming (Goodhart's Law) | Multi-dimensional scorecard |
| Vendor-funded eval | Inherent bias | Independent third-party or neutral sponsor |
| Closed datasets | Can't replicate | Public GitHub/Zenodo |
| No methodology | Can't audit | Published paper + detailed docs |
| FP optimized away | Unrealistic performance | Report FP rate transparently |

---

## Implementation Checklists

### Reproducibility Checklist
- [ ] Version control for all code, datasets, configs
- [ ] Container or environment snapshot (Docker/Conda)
- [ ] Metadata logging (OS, hardware, seeds, timestamps)
- [ ] Immutable dataset storage (S3 versioning or git-lfs)
- [ ] Deterministic execution (no timing-dependent behavior)
- [ ] Full artifact logging (tool output, exit codes, traces)

### Transparency Checklist
- [ ] Public dataset (GitHub or Zenodo)
- [ ] Methodology document (design rationale, not marketing)
- [ ] Open-source evaluation code (no proprietary scoring)
- [ ] Failure analysis (publish what tools miss, not just wins)
- [ ] Limitation documentation (what benchmark doesn't measure)
- [ ] Third-party reproducibility confirmation

### Benchmark Scenario Checklist
- [ ] Real-world sourcing (commit reversions preferred)
- [ ] CWE mapping (standard weakness enumeration)
- [ ] Complexity distribution (simple, medium, hard)
- [ ] Test oracle (clear success criteria)
- [ ] Language diversity (not Python-only)
- [ ] Known blind spots (documented per tool)

---

## Code Examples (Implementation)

### pass@k Metric (Code Generation)
```python
def compute_pass_at_k(num_correct: int, num_total: int, k: int) -> float:
    """Probability that ≥1 of k samples passes tests."""
    import math
    numerator = math.comb(num_total - num_correct, k)
    denominator = math.comb(num_total, k)
    return 1 - (numerator / denominator)
```

### F1 Score (Detection)
```python
precision = tp / (tp + fp)
recall = tp / (tp + fn)
f1 = 2 * (precision * recall) / (precision + recall)
```

### Regression Detection
```python
change = (current - baseline) / baseline
if metric in ['precision', 'recall']:
    flag_regression = change < -0.05  # 5% drop = regression
elif metric in ['latency_ms']:
    flag_regression = change > 0.05   # 5% increase = regression
```

---

## Unresolved Questions

1. Synthetic vs Real trade-off: How much synthetic is too much?
2. CWE representation bias: Should rare CWEs be oversampled for coverage?
3. False positive ambiguity: Is it non-buggy code, or code dev didn't intend to fix?
4. Tool collaboration effects: Should benchmarks measure tool combinations?
5. Temporal evolution: How to keep benchmarks fresh without constant curation?
6. Goodhart's Law detection: How do we spot when vendors are gaming?
7. Language coverage: Does Python performance predict other languages?

---

## Key Takeaway

**Credible benchmarks from transparent, independent evaluators drive adoption faster than vendor benchmarks.** HumanEval, SWE-Bench, and OWASP Benchmark succeeded because they combined:
- Real/curated scenarios (not cherry-picked)
- Multi-metric transparency (not single rankings)
- Honest documentation (gaps included)
- Reproducible methodology (papers + open code)
- Independent governance (not vendor-controlled)

Start lean (20-50 real scenarios), measure multi-dimensionally, publish methodology, iterate.
