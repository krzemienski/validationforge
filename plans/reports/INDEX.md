# Research Reports Index
**Benchmark Design Research** | 2026-03-07

---

## Available Reports

### 1. Full Research Report (743 lines)
**File:** `researcher-260307-1510-benchmark-design-for-validation-tools.md`

Comprehensive research synthesis covering:
- **Section 1:** Existing benchmarks (HumanEval, MBPP, SWE-Bench, OWASP, CASTLE)
- **Section 2:** Trust pillars for credible benchmarks (reproducibility, transparency, real-world relevance, multi-metric evaluation)
- **Section 3:** Metrics that matter for validation tools (detection rate, precision, recall, F1, time-to-evidence)
- **Section 4:** Scenario design patterns (bug injection methodologies, controlled construction)
- **Section 5:** Repository distribution design (structure, CI/CD patterns, results reporting)
- **Section 6:** Real-world benchmark examples (SWE-Bench, OWASP, BigCode, Codabench)
- **Section 7:** Marketing & adoption lessons
- **Section 8:** Technical implementation patterns (pass@k, precision/recall/F1, regression detection)
- **Section 9:** Unresolved questions (7 open research areas)

**Best for:** Deep understanding of benchmark architecture, implementation details, scientific rigor

---

### 2. Quick Reference Summary (227 lines)
**File:** `RESEARCH-SUMMARY.md`

Actionable quick-reference covering:
- 5 Core principles (reproducibility, transparency, real-world relevance, multi-metric, continuous validation)
- Benchmark landscape (code generation vs bug detection)
- Metric table (what matters, target ranges, why)
- 5-step implementation plan (Phase 1: launch, Phase 2: scale, Phase 3: credibility)
- Repository structure template (battle-tested pattern)
- Adoption factors (what wins vs what kills credibility)
- Implementation checklists (reproducibility, transparency, scenario design)
- Code examples (pass@k, F1, regression detection)
- Unresolved questions (7 areas)

**Best for:** Executive briefing, implementation planning, quick reference during execution

---

## Key Findings Summary

### 5 Core Benchmark Principles
1. **Reproducibility** — Version control, containers, metadata, deterministic execution
2. **Transparency** — Public datasets, methodology docs, auditable code, no cherry-picking
3. **Real-World Relevance** — Curated real scenarios (GitHub commits) > synthetic
4. **Multi-Metric Evaluation** — Precision + Recall + F1 + Coverage (prevents gaming)
5. **Continuous Validation** — CI integration, regression detection, timestamped results

### Winning Benchmarks (Why They Succeeded)
- **HumanEval (164 problems):** Industry standard; pass@k metric; reproducible; 28.8%→96.3% in 4 years
- **SWE-Bench (1,865 problems):** Real GitHub issues; execution-based success; academic credibility
- **OWASP Benchmark:** Executable apps; CWE-mapped; neutral third-party; no vendor involvement
- **CASTLE (250 benchmarks):** Surprising finding: LLMs (F1=0.753) > static tools (F1=0.386)

### Metrics That Matter
| Metric | Target | Why |
|--------|--------|-----|
| Recall (Detection Rate) | 60-85% | Misses = broken tool |
| Precision | >70% | High FP = tool ignored |
| F1 Score | >0.70 | Balanced metric |
| False Positive Rate | <30% | Developer trust |
| Time-to-Evidence | <100ms | DevEx metric |

### Reality Check (False Positives)
- Real-world static analysis: **76-90% false positive rates** (Tencent study)
- No single tool catches >38% of vulnerabilities (combined 4 tools)
- Teams use **multiple tools in combination**, not "the best one"

### What Works vs What Doesn't
**✅ Works:** Independent evaluators, published papers, open datasets, honest docs, multi-metrics, GitHub CI
**❌ Doesn't:** Vendor benchmarks, single rankings, closed datasets, marketing-driven design, no methodology

---

## Implementation Roadmap

### Phase 1: Launch (3-6 months)
- Curate 20-50 real scenarios (GitHub commit reversions)
- Evaluate 3-4 tools (include market leaders)
- Open repo with full methodology
- Multi-dimensional scorecard (no leaderboard)
- GitHub Actions CI: PR benchmark + main baseline comparison

### Phase 2: Scale (6-12 months)
- 200+ scenarios
- Automated scenario QA
- 8-10 tools evaluated
- Academic partnership for independent validation

### Phase 3: Credibility (12+ months)
- 500+ scenarios
- Published research paper
- Third-party audits
- Industry adoption metrics

---

## Repository Structure (Recommended)

```
validation-benchmark/
├── scenarios/              # Immutable benchmark cases
├── tools/                  # Evaluation harnesses
├── results/                # Latest + timestamped history
├── .github/workflows/      # PR benchmark → main baseline compare
├── docs/                   # METHODOLOGY.md, SCENARIO-DESIGN.md, LIMITATIONS.md
└── scripts/                # Evaluation + reporting automation
```

**Key Pattern:** Scenarios in version control; results in CI artifacts; tool-agnostic base harness

---

## Adoption & Marketing Insights

**Credible benchmarks from transparent, independent evaluators drive adoption faster than vendor benchmarks.**

Evidence:
- HumanEval (OpenAI) became industry standard despite initial 28.8% performance
- SWE-Bench (Scale AI) drove agent developer adoption through real issue resolution
- OWASP Benchmark trusted because independent, not vendor-controlled
- Snyk + SonarQube both popular because teams run **both**, not "one vs other"

**Credibility drivers:**
1. Independent governance (not vendor-controlled)
2. Published methodology (paper + docs, not blog post)
3. Open datasets (GitHub/Zenodo, public reproducibility)
4. Honest documentation (gaps included, not hidden)
5. Multi-metric transparency (scorecards, not rankings)
6. GitHub CI integration (signals confidence in methodology)

---

## Unresolved Research Questions

1. **Synthetic vs Real:** How much synthetic injection is acceptable before losing real-world relevance?
2. **CWE Bias:** Should rare CWEs be oversampled for comprehensive coverage?
3. **False Positive Definition:** Is it non-buggy code, or code the developer didn't intend to fix?
4. **Tool Combinations:** Should benchmarks measure tools together instead of individually?
5. **Temporal Evolution:** How to keep benchmarks fresh without constant curation?
6. **Gaming Detection:** How to spot when vendors are optimizing for benchmark artifacts?
7. **Language Prediction:** Does Python performance predict Go/Rust performance?

---

## Quick Start Checklist

For launching a validation tool benchmark:

**Reproducibility (MANDATORY)**
- [ ] Version control for all code, datasets, configs
- [ ] Container snapshot (Docker/Conda)
- [ ] Metadata logging (OS, hardware, seeds)
- [ ] Deterministic execution (no timing-dependent behavior)

**Transparency (MANDATORY)**
- [ ] Public dataset (GitHub or Zenodo)
- [ ] Methodology document (design rationale)
- [ ] Open-source evaluation code
- [ ] Limitation documentation (honest gaps)

**Benchmark Design**
- [ ] 20-50 curated real scenarios (start here)
- [ ] CWE mapping (standard weakness enumeration)
- [ ] Test oracles (clear success criteria)
- [ ] Language diversity (not single-language)

**Evaluation & Reporting**
- [ ] Multi-dimensional scorecard (no single ranking)
- [ ] GitHub Actions CI (PR + main workflows)
- [ ] Regression detection (baseline comparison)
- [ ] Tool-agnostic evaluation harness

---

## Sources & References

Full citations available in main report. Key references:

- [SWE-Bench GitHub](https://github.com/SWE-bench/SWE-bench) — Real-world GitHub issue resolution
- [HumanEval (arXiv 2107.03374)](https://arxiv.org/pdf/2107.03374) — Code generation benchmark design
- [MBPP (arXiv 2108.07732)](https://arxiv.org/pdf/2108.07732) — Crowd-sourced Python problems
- [CASTLE (TASE 2025)](https://ssvlab.github.io/lucasccordeiro/papers/tase2025.pdf) — Hybrid tool + LLM evaluation
- [OWASP Benchmark](https://owasp.org/www-project-benchmark/) — Security detection rates
- [Omnibenchmark (arXiv 2409.17038)](https://arxiv.org/html/2409.17038) — Reproducible benchmark orchestration
- [Bencher](https://bencher.dev) — Continuous benchmarking platform

---

## Contact & Follow-up

For detailed implementation guidance, refer to:
1. **Full Report** → Section 5 (Repository Design) for architecture patterns
2. **Full Report** → Section 8 (Technical Implementation) for code examples
3. **Summary** → Implementation Checklists for quick execution
4. **Unresolved Questions** → Section 9 for research gaps needing exploration

Generated: 2026-03-07 | Research Agent
