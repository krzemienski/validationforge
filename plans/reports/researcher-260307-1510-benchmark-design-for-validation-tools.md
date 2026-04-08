# Developer Tool Benchmarks: Design & Implementation Guide
**Research Report** | 2026-03-07 | Validation Tool Benchmark Architecture

---

## Executive Summary

Credible developer tool benchmarks share 5 core principles: **reproducibility** (version tracking, environment control), **transparency** (public datasets, methodology docs), **real-world relevance** (avoid synthetic-only benchmarks), **multi-metric evaluation** (avoid Goodhart's Law gaming), and **continuous validation** (CI integration, regression detection).

This report synthesizes findings from SWE-bench (real-world issue resolution), HumanEval (functional correctness via pass@k), MBPP (crowd-sourced problems), OWASP Benchmark (security detection rates), and market leaders (Snyk, SonarQube, Semgrep) to provide actionable guidance for building a credible validation tool benchmark.

---

## 1. EXISTING BENCHMARKS: Landscape & Patterns

### 1.1 Code Generation Benchmarks

#### HumanEval (OpenAI, 2021)
- **Coverage:** 164 hand-crafted Python problems
- **Measurement:** `pass@k` metric — probability that ≥1 of k generated samples passes unit tests
- **Key Insight:** pass@1 = 70% means single attempt has 70% success probability; pass@10 = 90% means ≥1 of 10 attempts succeeds
- **Formula:** Unbiased estimator using combinations: `1 - C(n-c, k) / C(n, k)` where n=samples, c=correct, k=attempts
- **Performance Growth:** Codex (2021): 28.8% pass@1 → O1 Preview (2025): 96.3% pass@1
- **Variants:** HumanEval-X extends to C++, Go, Java, JavaScript (820 tasks)
- **Marketing Impact:** Became industry standard for code generation evaluation; all major LLM vendors benchmark against it

#### MBPP (Google, 2021)
- **Coverage:** ~1,000 crowd-sourced Python problems at entry-level difficulty
- **Measurement:** 3 test cases per problem; pass/fail on semantic correctness
- **Key Difference:** Natural language problem descriptions (vs HumanEval's function signatures); tests interpreter design skill
- **Performance:** Largest models achieve 58% on few-shot; fine-tuning adds ~10% improvement
- **Distribution:** Public on Hugging Face; integrated into BigCode evaluation harness
- **Strength:** Real-world problem framing; tests requirement interpretation vs signature-guided generation

#### SWE-Bench (Real-world Issue Resolution, 2024)
- **Coverage:** Real GitHub issues from major repos; SWE-Bench Pro (2025) = 1,865 problems across 41 repos
- **Measurement:** **Execution-based evaluation** — patch applied to codebase; all tests must pass (both fail→pass and pass→pass)
- **Complexity:** Multi-file edits averaging 107.4 lines across 4.1 files; excludes trivial 1-10 line fixes
- **Key Insight:** Strict dual-condition success: fix specific bug AND don't break existing functionality
- **Performance:** 1.96% → 75% resolution rate in 2 years (2023-2025)
- **Infrastructure:** SWE-Bench++ pipeline: programmatic sourcing → environment synthesis → test oracle extraction → QA
- **Marketing Impact:** Became gold standard for evaluating AI coding agents; used by all major LLM vendors

### 1.2 Security & Bug Detection Benchmarks

#### OWASP Benchmark
- **Coverage:** Fully runnable web applications with thousands of exploitable test cases
- **Measurement:** Per-CWE vulnerability detection
- **Metrics:** True Positives, False Negatives, True Negatives, False Positives
- **Output:** Precision, Recall, F1 for each tool evaluated
- **Strength:** Real, executable code (not synthetic); multiple languages
- **Weakness:** Limited to intentional vulnerabilities; doesn't capture evolution of real bugs

#### CASTLE (2025)
- **Coverage:** 250 hand-crafted micro-benchmarks covering 25 common CWEs
- **Evaluated:** 13 static analysis tools, 10 LLMs, 2 formal verification tools
- **Metric:** CASTLE Score (novel fairness metric for cross-tool comparison)
- **Finding:** Static analyzers avg F1=0.386 vs LLMs avg F1=0.753 (surprising reversal of assumptions)
- **Strength:** Standardized CWE mapping; hybrid evaluation (tools + LLMs)

#### BugBench / HyperPUT
- **Concept:** Synthetic bug injection for benchmarking detection tools
- **Method:** Mutation-based or reverting historical commits to inject realistic bugs
- **Challenge:** High false positive rates (76% false positives in Tencent real-world study; 90%+ when discarded cases included)
- **Evaluation:** Solve rate = fraction of attempts successfully fixing injected bug

#### Snyk, SonarQube, Semgrep Benchmarks
- **Detection Rates:** Highly variable by vulnerability type
- **Example (Python/Django):** Snyk 0/5, SonarQube 1/5, Semgrep 3/5
- **Critical Finding:** Combined detection across all tools = 38.8% (no tool >27%)
- **Marketing Pattern:** Vendors publish only favorable comparisons; independent benchmarks rare
- **Adoption Lesson:** Teams run **multiple tools in combination** rather than choosing one

---

## 2. HOW TO BUILD CREDIBLE BENCHMARKS: Trust Pillars

### 2.1 Reproducibility (MANDATORY)

**Why it matters:** A benchmark is worthless if results can't be replicated independently.

**Implementation checklist:**
- [ ] **Version tracking:** Document all tool versions, runtime versions, and dependencies
- [ ] **Environment control:** Use containers (Docker/Apptainer) or environment modules to ensure consistent execution
- [ ] **Metadata capture:** Record OS, hardware specs, network conditions, randomness seeds
- [ ] **Dataset versioning:** Store benchmark datasets in version control or immutable storage (S3 with versioning)
- [ ] **Deterministic execution:** Remove timing-dependent behavior; report variance when present
- [ ] **Full instrumentation:** Log tool output, exit codes, stack traces; save artifacts for post-hoc analysis

**Tools that enforce this:**
- **Omnibenchmark:** Snakemake workflows + YAML config + Conda/Apptainer for reproducible solo/collaborative benchmarks
- **BenchMake:** Deterministic conversion of scientific datasets into benchmarks via non-negative matrix factorization
- **Codabench:** Meta-benchmark platform with template reuse and on-demand compute resources

### 2.2 Transparency (MANDATORY)

**What transparency requires:**
1. **Public datasets:** All benchmark scenarios publicly available (GitHub, Zenodo, or project repo)
2. **Methodology docs:** Detailed design rationale for why scenarios were chosen
3. **Open source harness:** Evaluation code is auditable; no proprietary scoring logic
4. **Failure analysis:** Publish failures alongside successes; explain why tools failed
5. **No vendor cherry-picking:** Independent evaluators can run benchmarks; results aren't curated

**Anti-pattern to avoid:** Vendor-funded benchmarks that only test strong areas
- Example: Snyk's "speed comparison" claims 5-14x faster than competitors (from Snyk's blog) — inherent bias
- Better: CASTLE or OWASP Benchmark (neutral third party, open methodology)

### 2.3 Real-World Relevance

**Three tiers of realism:**

| Tier | Example | Strength | Weakness |
|------|---------|----------|----------|
| **Synthetic** | Injected bugs via mutation | Controlled, repeatable | Doesn't reflect real bug distribution |
| **Curated Real** | GitHub issues with manual review | Real code, known solutions | Labor-intensive to curate; small scale |
| **Continuous Real** | Automated sourcing + QA pipeline | Large scale, evolving | QA overhead; harder to reproduce |

**Recommendation:** Start with curated real (tier 2) → scale to continuous real (tier 3) only if you have QA capacity.

**Real-world patterns SWE-Bench captured:**
- Multi-file edits are common (avg 4.1 files per fix)
- Avg fix size is ~107 lines (non-trivial)
- Tests reveal true success (no false positives from partial fixes)

### 2.4 Avoiding Goodhart's Law: Multi-Metric Evaluation

**The problem:** When a benchmark becomes the target, tools game the metric.

**Examples in practice:**
- Lighthouse 100 scores by detecting the test and serving stripped-down HTML
- Framework benchmarks optimized for specific benchmark patterns instead of real-world usage
- Detection rate benchmarks hit by adding low-confidence checks (floods false positives)

**Mitigation strategies:**

1. **Measure what matters, not what's easy**
   - Don't just measure detection count; measure false positive rate, precision, recall
   - Use F1 score (harmonic mean) to balance precision ↔ recall

2. **Multiple independent dimensions**
   - **Speed metrics:** Time to first evidence, total analysis time
   - **Quality metrics:** Detection rate, false positive rate, coverage
   - **Relevance metrics:** Real-world bug distribution match, CWE coverage
   - **DevEx metrics:** Integration ease, configuration friction, documentation quality

3. **Composite scoring with weights**
   - Avoid single-number rankings (they invite gaming)
   - Show multi-dimensional scorecards instead
   - Example from CASTLE: evaluated tools on precision/recall/F1 separately, not composite

4. **Red-team your benchmark**
   - Ask: "How would a vendor game this metric?"
   - Inject adversarial scenarios (false positive traps, performance cliffs)
   - Publish failure modes alongside successes

### 2.5 Scientific Rigor

**From reproducible research frameworks:**

| Control | Implementation |
|---------|----------------|
| Variance reduction | Run multiple samples (n ≥ k); compute unbiased estimator (pass@k formula) |
| Statistical confidence | Report confidence intervals, not just point estimates |
| Significance testing | Use paired tests when comparing two tools on same scenarios |
| Effect sizes | Report actual performance gaps, not just p-values |

---

## 3. METRICS THAT MATTER FOR VALIDATION TOOLS

### 3.1 Core Metrics

#### A. Detection Rate (Sensitivity / Recall)
**Definition:** Fraction of real bugs the tool detects

**Formula:** `TP / (TP + FN)` where TP = true positives, FN = false negatives

**Why it matters:** If your tool misses bugs, it's not useful
**Warning:** Alone, this incentivizes false alarms (reduce FN by lowering threshold → increase FP)

**Target by tool type:**
- Security scanner: 60-85% (false negatives are expensive)
- Code quality: 50-70% (some nuance is acceptable)

#### B. False Positive Rate (Specificity)
**Definition:** Fraction of non-bugs incorrectly flagged as bugs

**Formula:** `FP / (FP + TN)` where TN = true negatives

**Why it matters:** High FP exhausts developer trust; developers ignore tool output if overwhelmed
**Real-world data:** Tencent found 76-90% false positives in static analysis

**Target by tool type:**
- Security scanner: <30% (every false alarm is expensive)
- Code quality: <40% (developers tolerate more uncertainty)

#### C. Precision (Positive Predictive Value)
**Definition:** Of all flags raised, how many are real bugs?

**Formula:** `TP / (TP + FP)`

**Why it matters:** Developer trust metric; if 1 in 3 warnings are real, tool seen as noisy

**Real-world example:** Snyk Code detected 11.2% of actual vulnerabilities in comparative test (lowest of 4 tools)

#### D. F1 Score (Harmonic Mean)
**Formula:** `2 * (Precision * Recall) / (Precision + Recall)`

**Why it matters:** Balances precision ↔ recall trade-off; single comparable number for leaderboards
**Caveat:** Equal weighting may not match real-world priorities (security tools weight recall higher)

#### E. Time-to-Evidence
**Definition:** How long from running tool to first actionable result?

**Formula:** `Median(time_from_invocation to first_true_positive_identified)`

**Why it matters:** Fast feedback loops drive adoption; DevX metric
**Real-world:** Snyk claims 5-14x faster than competitors (but from vendor blog — verify independently)

### 3.2 Composite / Derived Metrics

#### Coverage by CWE (Security tools)
**Definition:** What fraction of common weakness enumeration categories does tool handle?

**Formula:** `# of CWE categories with ≥1 detection / total CWEs in benchmark`

**Example:** CASTLE evaluates across 25 CWEs
**Why it matters:** Shows breadth; prevents over-optimization for single category

#### False Negative Distribution
**Definition:** Which bug types does the tool systematically miss?

**Query:** `GROUP BY bug_type, tool; ORDER BY miss_count DESC`

**Why it matters:** Reveals blind spots (e.g., "tool never catches timing bugs")
**Action:** Publish these gaps explicitly — builds credibility by admitting limits

#### Scalability / Performance Percentiles
**Definition:** How does execution time scale with codebase size?

**Formula:** `TIME_PERCENTILE(95) at codebase_size_10K vs 1M LOC`

**Why it matters:** Real codebases are large; linear vs quadratic scaling is critical

---

## 4. BENCHMARK SCENARIO DESIGN: Practical Patterns

### 4.1 Bug Injection Methodology

**Three patterns used in practice:**

#### Pattern A: Mutation-Based (Synthetic)
**Method:** Automatically inject bugs via mutation operators (delete statement, swap comparison, etc.)

**Pros:** Scalable, repeatable
**Cons:** Doesn't match real bug distribution; easy to game

**Example:** BugPilot, HyperPUT

#### Pattern B: Revert Historical Commits (Real but Biased)
**Method:** Pick historical fixes from git; treat the pre-fix state as a bug

**Pros:** Real bugs, real fixes validated in production
**Cons:** Biased toward frequently-fixed bug types; misses rare bugs

**Example:** SWE-Bench sourcing pipeline

#### Pattern C: Feature Implementation → Accidental Breakage (Emergent)
**Method:** Ask agents to add features to real repos; capture unintended test failures as natural bugs

**Pros:** Most realistic bug distribution; mirrors real development
**Cons:** Labor-intensive; requires multi-agent orchestration

**Example:** BugPilot recent approach

**Recommendation:** **Start with B (revert commits), add A (mutation) for synthetic edge cases, scale to C only if QA permits.**

### 4.2 Controlled Scenario Construction

**Scenario template:**
```yaml
scenario_id: "val-001-sql-injection"
cwe_id: 89
bug_type: "SQL Injection"
complexity: "medium"
file_count: 2
line_count: 45
languages: ["python", "javascript"]
real_world_source: "Django 2.2 issue #31455"
injected_via: "commit_revert"
detection_tools_expected: ["semgrep", "snyk", "codeql"]
detection_tools_miss: ["sonarqube"]  # documented blind spot
test_oracle: "3 unit tests verify fix"
pass_criteria: ["security_test_passes", "legacy_tests_not_broken"]
```

**Why this matters:**
- Scenario-level metadata enables analysis of what types fail
- CWE mapping enables vendor comparisons
- `detection_tools_miss` field prevents false negatives (vendor A claims to catch everything)

### 4.3 "Would Unit Tests Have Caught This?" Measurement

**Key insight:** Validation tools should catch bugs that unit tests miss.

**Benchmark design:**
1. For each scenario, maintain **original test suite** (what tests existed pre-bug)
2. Run tool against buggy code; measure detection
3. Run original test suite against buggy code; measure test failure
4. **Compute:** `Tool_Unique_Catches = Tool_Detections - Test_Detections`

**Example outcome:**
- Bug X: Validation tool detects 15/20 instances; unit tests catch only 3/20
- Bug Y: Validation tool detects 4/20 instances; unit tests catch all 20/20 (tool adds no value)

**Metric:** `Value-Add Ratio = Tool_Unique_Catches / Total_Tool_Detections` (target: >40%)

---

## 5. BENCHMARK DISTRIBUTION: Repository Design

### 5.1 Repository Structure (Battle-Tested Pattern)

```
validation-tool-benchmark/
├── README.md                          # Methodology, not just marketing
│   ├── Section 1: Benchmark Design Rationale
│   ├── Section 2: Scenario Construction Method
│   ├── Section 3: Evaluation Protocol
│   └── Section 4: Known Limitations
├── LICENSE                            # CC-BY-4.0 or MIT (permit reuse)
├── .github/
│   └── workflows/
│       ├── benchmark-ci.yml           # Auto-run on main, save results
│       └── regression-detect.yml      # Compare vs baseline
├── scenarios/
│   ├── metadata.yaml                  # All scenarios with CWE, source, complexity
│   ├── 001-sql-injection/
│   │   ├── buggy/                     # Pre-fix state
│   │   │   ├── main.py
│   │   │   └── test_auth.py
│   │   ├── fixed/                     # Post-fix state
│   │   │   ├── main.py
│   │   │   └── test_auth.py
│   │   └── scenario.yaml              # Detailed metadata
│   └── 002-race-condition/
│       ├── buggy/
│       ├── fixed/
│       └── scenario.yaml
├── tools/
│   ├── semgrep-eval.py                # Semgrep harness
│   ├── codeql-eval.py                 # CodeQL harness
│   └── base-evaluator.py              # Shared harness logic
├── results/
│   ├── latest/
│   │   ├── semgrep-results.json       # Tool output + metrics
│   │   ├── codeql-results.json
│   │   └── summary.md                 # Leaderboard-style report
│   └── history/
│       ├── 2026-03-01/
│       └── 2026-02-15/
├── docs/
│   ├── METHODOLOGY.md                 # Deep dive: why this design?
│   ├── SCENARIO-DESIGN.md             # How scenarios were created
│   ├── CWE-MAPPING.md                 # CWE coverage explained
│   └── LIMITATIONS.md                 # Honest gaps & blind spots
├── scripts/
│   ├── run-all-evals.sh               # Execute all tool evaluations
│   ├── compare-baselines.py           # Statistical comparison
│   └── generate-report.py             # Markdown leaderboard
└── CHANGELOG.md                       # Scenario additions, methodology updates
```

**Key principles:**
- **Separation of concerns:** Scenarios ≠ evaluation harness ≠ results reporting
- **Tool-agnostic harnesses:** Base evaluator is generic; tool-specific harnesses inherit
- **Immutable scenario data:** Scenarios in version control; results in `.gitignore` (results live in CI artifacts or separate storage)
- **Transparent history:** Results timestamped; regression detection possible

### 5.2 CI/CD Integration (Continuous Validation)

**Pattern: Bencher-style two-workflow system**

**Workflow 1: Pull Request Benchmark (No Secrets)**
```yaml
name: benchmark-pr
on: pull_request
jobs:
  evaluate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run benchmarks (all tools)
        run: ./scripts/run-all-evals.sh
      - name: Cache results for workflow_run
        uses: actions/upload-artifact@v4
        with:
          name: pr-benchmark-results
          path: results/latest/
```

**Workflow 2: Push to Main (With Secrets, Compares to Baseline)**
```yaml
name: benchmark-main
on:
  workflow_run:
    workflows: [benchmark-pr]
    types: [completed]
jobs:
  upload-results:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Download PR results
        uses: actions/download-artifact@v4
      - name: Compare vs baseline
        run: python3 scripts/compare-baselines.py results/latest results/main
      - name: Comment on PR with results
        if: github.event.workflow_run.event == 'pull_request'
        run: |
          python3 scripts/generate-report.py > /tmp/report.md
          gh pr comment ${{ github.event.workflow_run.pull_requests[0].number }} \
            --body "$(cat /tmp/report.md)"
      - name: Save to results history
        run: |
          cp -r results/latest results/history/$(date +%Y-%m-%d)
          git add results/history
          git commit -m "benchmark: results $(date +%Y-%m-%d)"
          git push
```

**Why two workflows?**
- PR workflow runs without `GITHUB_TOKEN` secret access (security)
- Main workflow has access to secrets; compares against historical baseline
- Regression detection prevents performance degradation

### 5.3 Results Reporting (Anti-Pattern: Leaderboards)

**AVOID:** Flat rankings like "Tool A: 85%, Tool B: 72%"
- Invites gaming
- Hides where each tool excels/fails
- Implies equivalence across CWE types

**PREFER:** Multi-dimensional scorecard

```markdown
## Benchmark Results (2026-03-07)

### By Detection Rate (Recall)
| Tool | SQL Injection | XSS | CSRF | Race Condition | Avg |
|------|---|---|---|---|---|
| Semgrep | 18/20 (90%) | 12/15 (80%) | 8/10 (80%) | 2/5 (40%) | **72.5%** |
| CodeQL | 16/20 (80%) | 14/15 (93%) | 10/10 (100%) | 3/5 (60%) | **83.3%** |

### By False Positive Rate (Precision)
| Tool | SQL Injection | XSS | CSRF | Race Condition | Avg |
|------|---|---|---|---|---|
| Semgrep | 18/25 (72%) | 12/20 (60%) | 8/15 (53%) | 2/8 (25%) | **52.5%** |
| CodeQL | 16/20 (80%) | 14/16 (87%) | 10/10 (100%) | 3/4 (75%) | **85.5%** |

### By CWE Coverage (Breadth)
- **Semgrep:** 23/25 CWEs (92%)
- **CodeQL:** 22/25 CWEs (88%)

### Known Limitations
- Does not include: zero-day patterns, AI-generated vulnerability exploitation
- Scenarios heavily weighted toward common web vulns (SQL, XSS); low coverage for system-level bugs
- False positive rate measured on known-benign code; real codebases may have hidden issues
```

**Why this design:**
- Shows tradeoffs explicitly
- Prevents single-metric gaming
- Documents blind spots
- Enables nuanced selection ("Semgrep best for XSS, CodeQL best for CSRF")

---

## 6. BENCHMARK REPO EXAMPLES (Real-World Models)

### 6.1 High-Quality Examples

#### SWE-Bench (GitHub Reference)
- **Strength:** Real issues, strict execution-based success criteria, multi-file edits
- **Pattern:** Git submodules for each repo; test oracle extraction automated
- **CI:** Runs on Scale AI infrastructure (not just GitHub); leaderboard on scale.com
- **Docs:** Methodology papers published (ICLR 2024, arXiv 2509.16941)

#### OWASP Benchmark
- **Strength:** Fully runnable applications; language-diverse; CWE-mapped
- **Pattern:** Separate source repos per language; evaluation harness language-agnostic
- **Docs:** Clear vulnerability metadata per scenario
- **Weakness:** No automated CI; manual tool evaluation required

#### BigCode Evaluation Harness
- **Strength:** Unified interface for HumanEval, MBPP, and other code gen benchmarks
- **Pattern:** Each benchmark is a task class; harness abstracts execution
- **Languages:** Python, but infrastructure supports multi-language
- **CI:** Runs on Hugging Face spaces; leaderboard updated auto-daily

#### Codabench
- **Strength:** Meta-benchmark platform (benchmarks about benchmarks)
- **Pattern:** YAML-defined benchmarks; pluggable compute backends; reusable templates
- **CI:** Supports multiple execution contexts (local, cloud, cluster)
- **Use case:** For validators benchmarking validators

---

## 7. MARKETING & ADOPTION: What Worked

### 7.1 Benchmarks That Drove Adoption

| Tool | Benchmark | Marketing Impact | What Worked |
|------|-----------|------------------|------------|
| **Snyk** | Internal speed benchmarks, vendor comparisons | High developer adoption ("5x faster") | Developer-first messaging; easy integration shown in benchmarks |
| **SonarQube** | Generic quality scorecards | Medium (enterprise focus) | Free Community Edition; internal benchmarking; governance story |
| **OpenAI (Codex)** | HumanEval (164 problems) | Massive (became industry standard) | Published methodology; reproducible; open-source evaluation code |
| **Google (PaLM)** | MBPP (1,000 problems) | Medium-high (academic credibility) | Crowd-sourced realism; published on Hugging Face; no vendor bias |
| **Scale AI (SWE-Bench)** | Real GitHub issues, 1,865 problems | High (agent developer focus) | Strict success criteria; leaderboard with major vendor participation |

### 7.2 Adoption Patterns

**What drives credibility:**
1. **Methodology transparency** — Papers, not just blog posts
2. **Open-source tooling** — Evaluators can run benchmarks independently
3. **Public datasets** — GitHub or Zenodo, not proprietary
4. **No vendor cherry-picking** — Third-party evals or neutral sponsor
5. **Honest gaps** — Documentation of what benchmark doesn't measure

**What doesn't work:**
- Vendor-only benchmarks (perceived as biased)
- Single-metric leaderboards (easy to game)
- Closed datasets (can't replicate)
- Marketing-driven scenario selection (too convenient for vendor)

### 7.3 Activation Strategy for Validation Tools

**Tier 1: Launch (3-6 months)**
- 20-50 curated real scenarios (revert commits from popular projects)
- 3-4 tools evaluated (including market leaders)
- Open repo with full methodology; GitHub + paper
- CI integration showing regression detection
- No leaderboard; show scorecards instead

**Tier 2: Scale (6-12 months)**
- 200+ scenarios; continuous sourcing pipeline
- 8-10 tools evaluated
- Automated scenario QA (test oracle verification)
- Academic partnership for independent evaluation

**Tier 3: Credibility (12+ months)**
- 500+ scenarios covering diverse CWEs, languages, complexity
- Third-party audits of methodology
- Published research comparing validation approaches
- Industry adoption story (e.g., "X% of top 100 OSS projects use benchmark")

---

## 8. TECHNICAL PATTERNS: Measurement Implementation

### 8.1 Pass@k Implementation (Code Generation)

```python
def compute_pass_at_k(num_correct: int, num_total: int, k: int) -> float:
    """
    Compute pass@k metric (unbiased estimator).

    Args:
        num_correct: Number of correct solutions
        num_total: Total solutions generated
        k: Number of attempts

    Returns:
        Probability that ≥1 of k samples passes tests
    """
    if k > num_total:
        raise ValueError(f"k ({k}) cannot exceed num_total ({num_total})")

    # Avoid overflow in combinations
    import math

    # 1 - C(n-c, k) / C(n, k)
    # = 1 - [(n-c)! / k!(n-c-k)!] / [n! / k!(n-k)!]
    # = 1 - [(n-c)! * (n-k)!] / [n! * (n-c-k)!]

    def comb(n, k):
        if k > n:
            return 0
        return math.comb(n, k)

    numerator = comb(num_total - num_correct, k)
    denominator = comb(num_total, k)

    return 1 - (numerator / denominator)

# Test
assert compute_pass_at_k(7, 10, 1) == 0.7  # 7/10 single shot success
assert compute_pass_at_k(7, 10, 10) > 0.9  # High prob with 10 attempts
```

### 8.2 Precision / Recall / F1 Implementation

```python
from dataclasses import dataclass

@dataclass
class DetectionMetrics:
    true_positives: int
    false_positives: int
    false_negatives: int
    true_negatives: int

    @property
    def precision(self) -> float:
        """TP / (TP + FP)"""
        if self.true_positives + self.false_positives == 0:
            return 0.0
        return self.true_positives / (self.true_positives + self.false_positives)

    @property
    def recall(self) -> float:
        """TP / (TP + FN)"""
        if self.true_positives + self.false_negatives == 0:
            return 0.0
        return self.true_positives / (self.true_positives + self.false_negatives)

    @property
    def f1_score(self) -> float:
        """2 * (precision * recall) / (precision + recall)"""
        if self.precision + self.recall == 0:
            return 0.0
        return 2 * (self.precision * self.recall) / (self.precision + self.recall)

# Example
metrics = DetectionMetrics(
    true_positives=18,
    false_positives=7,
    false_negatives=2,
    true_negatives=73
)
print(f"Precision: {metrics.precision:.2%}")  # 72%
print(f"Recall: {metrics.recall:.2%}")        # 90%
print(f"F1: {metrics.f1_score:.2%}")          # 80%
```

### 8.3 Regression Detection (CI Pattern)

```python
def detect_regression(baseline: dict, current: dict, threshold: float = 0.05) -> list:
    """
    Compare current results vs baseline; flag significant regressions.

    Args:
        baseline: Previous results {metric_name: value}
        current: Current results {metric_name: value}
        threshold: Relative change threshold (5% = 0.05)

    Returns:
        List of regressions [(metric, baseline_val, current_val)]
    """
    regressions = []

    for metric, baseline_val in baseline.items():
        if metric not in current:
            continue

        current_val = current[metric]

        # Skip if values are too small (avoid noise)
        if baseline_val < 0.01:
            continue

        # Relative change
        change = (current_val - baseline_val) / baseline_val

        # Flag if worse (negative for metrics like latency, positive for accuracy)
        if metric in ['precision', 'recall', 'f1_score', 'detection_rate']:
            if change < -threshold:
                regressions.append((metric, baseline_val, current_val, change))
        elif metric in ['latency_ms', 'false_positive_rate']:
            if change > threshold:
                regressions.append((metric, baseline_val, current_val, change))

    return regressions

# Example
baseline = {'precision': 0.85, 'recall': 0.92, 'latency_ms': 150}
current = {'precision': 0.80, 'recall': 0.90, 'latency_ms': 180}

regressions = detect_regression(baseline, current, threshold=0.05)
# [('precision', 0.85, 0.80, -0.059), ('latency_ms', 150, 180, 0.2)]
```

---

## 9. UNRESOLVED QUESTIONS & GAPS

1. **Synthetic vs Real Trade-off:** Is there a principled way to weigh synthetic scenarios (repeatable, controlled) vs real scenarios (authentic distribution)? How much synthetic is "too much"?

2. **CWE Representation Bias:** Real bug distributions heavily skew toward common CWEs (SQL injection, XSS). Should benchmarks oversample rare CWEs for coverage? Would that distort real-world relevance?

3. **False Positive Definition Ambiguity:** For validation tools, is "false positive" a warning on non-buggy code, or a warning on code the developer didn't intend to fix? Real teams often have deliberate technical debt.

4. **Tool Collaboration Effects:** OWASP found that combining 4 detection tools still only catches 38.8% of bugs. Should benchmarks measure tool combinations instead of individual tools? How to compare fairly?

5. **Temporal Evolution:** Benchmarks get stale as codebases evolve. SWE-Bench solves this with continuous sourcing, but requires significant infrastructure. What's the minimum viable continuous benchmark?

6. **Goodhart's Law Measurement:** How do we detect when vendors are gaming a benchmark? Proposed metric: "consistency across independent audits" — but this requires multiple independent evaluators.

7. **Language Coverage:** Most benchmarks focus on Python, JavaScript, Java. What's the right distribution for other languages? Does tool performance on Python predict performance on Go/Rust?

---

## Summary: 5 Actionable Steps

1. **Start with curated real scenarios** (20-50 from GitHub commit reversions) + open methodology doc
2. **Measure multi-dimensional metrics** (precision, recall, F1, false positive rate, CWE coverage) — avoid single number
3. **Distribute as separate repo** with scenarios in version control, CI integration for regression detection
4. **Document limitations explicitly** — show what benchmark doesn't measure; this builds credibility
5. **Run tool evaluations independently** — no vendor involvement in benchmark execution; publish methodology paper

**Marketing payoff:** Credible benchmarks from transparent, independent evaluators drive adoption faster than vendor benchmarks. See: HumanEval (OpenAI), SWE-Bench (Scale AI), OWASP Benchmark.

---

## Sources

- [SWE-Bench GitHub](https://github.com/SWE-bench/SWE-bench)
- [SWE-Bench Pro Whitepaper](https://static.scale.com/uploads/654197dc94d34f66c0f5184e/SWEAP_Eval_Scale%20(9).pdf)
- [HumanEval: Evaluating Large Language Models Trained on Code (arXiv 2107.03374)](https://arxiv.org/pdf/2107.03374)
- [MBPP: Program Synthesis with Large Language Models (arXiv 2108.07732)](https://arxiv.org/pdf/2108.07732)
- [CASTLE: Benchmarking Dataset for Static Code Analysis](https://ssvlab.github.io/lucasccordeiro/papers/tase2025.pdf)
- [Reducing False Positives in Static Bug Detection with LLMs (arXiv 2601.18844)](https://arxiv.org/html/2601.18844v1)
- [BugPilot: Complex Bug Generation for Efficient Learning (arXiv 2510.19898)](https://arxiv.org/pdf/2510.19898)
- [Omnibenchmark: Transparent, Reproducible, Extensible Orchestration (arXiv 2409.17038)](https://arxiv.org/html/2409.17038)
- [Bencher: Continuous Benchmarking Platform](https://bencher.dev)
- [BigCode Evaluation Harness](https://github.com/bigcode-project/bigcode-evaluation-harness)
- [Goodhart's Law in Software Engineering (Jellyfish Blog)](https://jellyfish.co/blog/goodharts-law-in-software-engineering-and-how-to-avoid-gaming-your-metrics/)
- [OWASP Benchmark Project](https://owasp.org/www-project-benchmark/)
- [Snyk vs SonarQube Comparison (Konvu 2026)](https://konvu.com/compare/snyk-vs-sonarqube)
- [SAST Tools Speed Comparison (Snyk Blog)](https://snyk.io/blog/sast-tools-speed-comparison-snyk-code-sonarqube-lgtm/)

