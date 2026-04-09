---
name: retrospective-validation
description: Validate methodologies and approaches using historical evidence and past results
triggers:
  - "retrospective validation"
  - "validate methodology"
  - "historical validation"
  - "did our approach work"
  - "post-mortem analysis"
context_priority: reference
---

# Retrospective Validation

Validate whether a methodology, process, or technical approach actually worked by analyzing historical evidence. Uses past validation results, deployment outcomes, and incident history to assess effectiveness.

## When to Use

- After a sprint/milestone to evaluate the validation approach used
- When deciding whether to continue or change a methodology
- When comparing two approaches (A/B validation strategy)
- Post-incident to assess if validation should have caught the issue
- When building a case for adopting or abandoning a practice

## Four-Phase Process

```
Phase 1: COLLECT     Phase 2: ANALYZE      Phase 3: CORRELATE    Phase 4: CONCLUDE
Historical           Categorize &          Map causes to         Confidence score
evidence             quantify outcomes     effects               & recommendations
```

## Phase 1: Collect Historical Evidence

Gather all available evidence from past validation runs, deployments, and incidents.

### Evidence Sources

| Source | What to Collect | Location |
|--------|----------------|----------|
| Past validation reports | PASS/FAIL verdicts, evidence quality | `e2e-evidence/*/report.md` |
| Git history | Deploy frequency, revert frequency | `git log --oneline` |
| Incident reports | Production issues post-deploy | Issue tracker, post-mortems |
| Build logs | Build failure rate over time | CI/CD logs |
| User feedback | Bug reports, complaints | Issue tracker |

```bash
mkdir -p e2e-evidence/retrospective

# Collect past validation reports
find e2e-evidence -name "report.md" -not -path "*/retrospective/*" \
  | sort | while read f; do
    echo "=== $f ===" >> e2e-evidence/retrospective/step-01-past-reports.txt
    head -20 "$f" >> e2e-evidence/retrospective/step-01-past-reports.txt
    echo "" >> e2e-evidence/retrospective/step-01-past-reports.txt
  done

# Collect deploy history
git log --oneline --since="30 days ago" --grep="deploy\|release\|revert" \
  > e2e-evidence/retrospective/step-01-deploy-history.txt

# Collect revert rate
TOTAL_DEPLOYS=$(git log --oneline --since="30 days ago" --grep="deploy\|release" | wc -l)
REVERTS=$(git log --oneline --since="30 days ago" --grep="revert" | wc -l)
echo "Deploys: $TOTAL_DEPLOYS, Reverts: $REVERTS" \
  > e2e-evidence/retrospective/step-01-revert-rate.txt
```

## Phase 2: Analyze Outcomes

Categorize and quantify the collected evidence.

### Metrics to Calculate

| Metric | Formula | Good | Concerning |
|--------|---------|------|------------|
| Validation PASS rate | PASS journeys / total journeys | >90% | <80% |
| False PASS rate | Production bugs that validation missed / total PASSes | <5% | >10% |
| False FAIL rate | Investigations that found no real bug / total FAILs | <10% | >20% |
| Revert rate | Reverts / deploys | <5% | >10% |
| Mean time to detect | Time from deploy to bug detection | <1h | >24h |
| Evidence quality | Reports with cited evidence / total reports | >95% | <80% |

### Analysis Template

```markdown
## Outcome Analysis

**Period:** YYYY-MM-DD to YYYY-MM-DD
**Total validation runs:** N
**Total deploys:** N

### Validation Effectiveness
- PASS rate: N%
- FAIL rate: N%
- False PASS (bugs in prod that validation missed): N
- False FAIL (unnecessary investigations): N

### Deploy Quality
- Deploys: N
- Reverts: N (N%)
- Production incidents: N
- Mean time to detect: Xh
```

Save to `e2e-evidence/retrospective/step-02-analysis.md`.

## Phase 3: Correlate Causes and Effects

Map validation practices to outcomes.

### Correlation Matrix

For each production incident or revert, trace back:

```markdown
## Incident Correlation

### Incident: {description}
**Date:** YYYY-MM-DD
**Severity:** CRITICAL/HIGH/MEDIUM/LOW
**Root cause:** {technical cause}

**Validation gap analysis:**
- Was this feature validated before deploy? YES/NO
- If YES, what type of validation? {build gates only / e2e / visual / etc.}
- If YES, why didn't validation catch it? {missing journey / wrong criteria / flaky flow / etc.}
- If NO, why was validation skipped? {time pressure / oversight / no plan / etc.}

**Would ValidationForge have caught it?**
- Which skill would apply? {skill name}
- What journey would detect it? {journey description}
- Confidence: HIGH/MEDIUM/LOW
```

### Pattern Detection

Look for patterns across multiple incidents:

| Pattern | Indicates |
|---------|-----------|
| Most incidents in UI rendering | Visual inspection is insufficient |
| Most incidents in API integration | Integration validation needs strengthening |
| Most incidents after "urgent" deploys | Process shortcuts are the problem |
| Low false FAIL rate but high false PASS | Validation criteria are too lenient |
| High false FAIL rate | Validation is too brittle (flaky flows) |

## Phase 4: Conclude

### Confidence Formula

```
Confidence = Detection × Accuracy × Longevity

Where:
  Detection (D) = 1 - (false_pass_rate)     # How often we catch real bugs
  Accuracy  (A) = 1 - (false_fail_rate)     # How often our FAILs are real
  Longevity (L) = days_since_last_miss / 30 # Stability over time (capped at 1.0)
```

| Confidence Score | Rating | Action |
|-----------------|--------|--------|
| >0.8 | HIGH | Methodology is working — maintain it |
| 0.5-0.8 | MEDIUM | Methodology has gaps — identify and fix |
| <0.5 | LOW | Methodology is ineffective — redesign required |

### Report Template

```markdown
# Retrospective Validation Report

**Methodology evaluated:** {description}
**Period:** YYYY-MM-DD to YYYY-MM-DD
**Confidence score:** X.XX ({HIGH/MEDIUM/LOW})

## Key Findings

1. {finding with evidence}
2. {finding with evidence}
3. {finding with evidence}

## What's Working
- {practice} — evidence: {cite specific outcome}

## What's Not Working
- {practice} — evidence: {cite specific failure}

## Recommendations

### Continue
- {practice to maintain}

### Start
- {new practice to adopt}

### Stop
- {practice to abandon}

## Evidence Files
[list all files in e2e-evidence/retrospective/]
```

Save to `e2e-evidence/retrospective/report.md`.

## Integration with ValidationForge

- Retrospective evidence goes to `e2e-evidence/retrospective/`
- Results inform updates to validation plans (`create-validation-plan`)
- False PASS analysis reveals missing journeys to add to future validation
- False FAIL analysis reveals flaky flows to fix or quarantine
- Confidence score tracks overall validation system health over time
- The `verdict-writer` agent can reference retrospective findings in meta-verdicts
