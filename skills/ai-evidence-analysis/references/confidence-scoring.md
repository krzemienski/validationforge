# Confidence Scoring Reference

*Loaded by `ai-evidence-analysis` when assigning or calibrating a confidence score (per-item or journey-level) and you need the 0-100 four-tier rubric, per-evidence-type adjustment tables, and the weighted-aggregation + floor-rule formula.*

Scoring rubric (0-100), per-evidence-type criteria, and journey-level aggregation rules
for AI-powered evidence analysis confidence scores (0–100).

## Overview

Every evidence item analyzed by the `ai-evidence-analysis` skill receives a `confidence`
score between 0 and 100. This score represents the AI's certainty that the evidence
supports a PASS verdict for the journey it belongs to.

Confidence scores drive two outcomes:
1. **Per-item `verdict_label`** — `PASS`, `WARN`, or `FAIL` for each individual evidence file
2. **Journey-level score** — Aggregated across all evidence items to produce an overall
   confidence signal that the `verdict-writer` agent uses when writing its final verdict

Confidence scores are **advisory inputs**, not final verdicts. The `verdict-writer` agent
makes the final PASS/FAIL determination using confidence scores plus its own review of
findings and PASS criteria from the validation plan.

---

## The 0–100 Scoring Rubric

Confidence scores are grouped into four tiers that map to evidence quality and certainty:

| Tier | Score Range | Certainty | Meaning |
|------|-------------|-----------|---------|
| **High** | 90–100 | High certainty | Clear, unambiguous evidence. All expected signals present. No defects detected. |
| **Moderate** | 70–89 | Moderate certainty | Evidence is good but has minor gaps or ambiguity. One or more low/medium findings present. |
| **Low** | 50–69 | Low certainty | Significant gaps in evidence. Missing expected signals or notable issues. Human review required. |
| **Insufficient** | 0–49 | Insufficient | Evidence clearly shows failure, is invalid (empty/corrupt), or analysis could not complete. |

### Tier Descriptions

#### Tier 1: High Certainty (90–100)

Evidence at this tier provides **clear, positive confirmation** that the feature being
validated is working correctly.

Characteristics:
- All expected elements, fields, or markers are present
- No error indicators of any kind
- No missing required data
- No ambiguity in the evidence content
- Exit codes, status codes, and response structures are all correct

A score in this tier warrants `verdict_label: "PASS"` with no qualification.

**When to assign 90–100:**
- Screenshot: Page fully rendered, all expected elements visible, zero layout defects
- API response: Status code correct, all required fields present with correct types, no anomalies
- CLI output: Exit code 0, all expected success markers present, no error keywords, no unexpected warnings

---

#### Tier 2: Moderate Certainty (70–89)

Evidence at this tier is **generally good** but has minor issues that introduce some
ambiguity. The feature is working, but attention is warranted on specific findings.

Characteristics:
- Most expected elements or signals are present
- One or more LOW or MEDIUM findings detected
- No CRITICAL or HIGH findings
- Core functionality appears intact despite the issues noted

A score in this tier warrants `verdict_label: "PASS"` when no CRITICAL findings exist,
or `verdict_label: "WARN"` when MEDIUM or HIGH findings are present.

**When to assign 70–89:**
- Screenshot: Page rendered correctly but one expected element is absent or partially rendered (fallback state)
- API response: Required fields present, but a deprecated field or minor format mismatch detected
- CLI output: Exit code 0, success markers present, but deprecation warnings or minor unexpected output detected

---

#### Tier 3: Low Certainty (50–69)

Evidence at this tier has **significant gaps** that prevent confident assessment. The
feature may or may not be working — human review is required.

Characteristics:
- Missing expected elements or signals
- Multiple MEDIUM findings or one or more HIGH findings
- Status codes or exit codes may be incorrect
- Evidence is present but incomplete or partially valid

A score in this tier warrants `verdict_label: "WARN"` in most cases. If HIGH findings
are present, escalate to `verdict_label: "FAIL"`.

**When to assign 50–69:**
- Screenshot: Page partially rendered (loading indicator visible), or multiple expected elements absent
- API response: Some required fields missing, wrong status code, or error structure malformed
- CLI output: Some success markers absent, or notable error keywords present alongside a partial success output

---

#### Tier 4: Insufficient Evidence (0–49)

Evidence at this tier **cannot support a PASS verdict**. It either clearly shows failure,
is technically invalid (empty, corrupt, unreadable), or the analysis was blocked.

Sub-ranges within this tier:

| Score | Condition |
|-------|-----------|
| 30–49 | Evidence shows functional problems — multiple missing fields, wrong status, test failures |
| 0–29 | Evidence clearly shows failure, or is empty/invalid (0-byte file, unreadable content, analysis blocked) |

A score in this tier always warrants `verdict_label: "FAIL"` OR a CRITICAL finding is present.

**When to assign 0–49:**
- Screenshot: Error page rendered, all expected elements absent, or file is 0 bytes
- API response: HTTP 500 instead of expected 2xx, multiple missing required fields, stack trace leaked, or file is 0 bytes / invalid JSON
- CLI output: Non-zero exit code with explicit failure message, all success markers absent, or file is 0 bytes

---

## Per-Evidence-Type Scoring Criteria

### Screenshot Evidence (Vision Model)

Confidence for screenshot evidence is derived from three dimensions:
**page load completeness**, **expected element visibility**, and **visual regression detection**.

#### Scoring Factors

| Factor | Weight | Scoring Impact |
|--------|--------|---------------|
| Page load complete | High | Loading indicators reduce score by 15–30 points; blank/error page reduces to 0–20 |
| Expected elements present | High | Each absent element reduces score by 5–15 points depending on importance |
| No layout defects | Medium | CRITICAL defect reduces to 0–30; HIGH defect reduces by 20–30; LOW defect reduces by 5 |

#### Screenshot Score Bands

| Score | Page Load | Elements | Regressions |
|-------|-----------|----------|-------------|
| 90–100 | Fully rendered | All visible | None detected |
| 70–89 | Fully rendered | Most visible (1 absent or PARTIAL) | LOW severity only |
| 50–69 | Partially rendered OR | Multiple absent (2+) | MEDIUM severity present |
| 30–49 | Not rendered / loading | Most absent | HIGH severity present |
| 0–29 | Error page / blank | All absent | CRITICAL severity OR 0-byte file |

#### Screenshot Score Adjustment Rules

Apply these adjustments to the base score:

| Condition | Adjustment |
|-----------|-----------|
| Loading spinner or skeleton screen visible | −15 to −25 |
| Broken image (placeholder icon) detected | −10 to −15 |
| One ABSENT expected element | −10 |
| Each additional ABSENT expected element | −5 per element |
| PARTIAL element (truncated, wrong state) | −5 |
| LOW severity layout defect | −5 |
| MEDIUM severity layout defect | −15 to −20 |
| HIGH severity layout defect | −25 to −35 |
| CRITICAL severity defect (error page, blank) | Force score ≤ 25 |
| 0-byte screenshot file | Force score = 0 |

---

### API Response Evidence (LLM)

Confidence for API response evidence is derived from four dimensions:
**status code correctness**, **schema compliance**, **error handling validity**, and
**edge case cleanliness**.

#### Scoring Factors

| Factor | Weight | Scoring Impact |
|--------|--------|---------------|
| HTTP status code correct | High | Wrong status (e.g., 500 vs 201) reduces score by 30–50 points |
| All required fields present | High | Each missing required field reduces score by 10–20 points |
| Field types and formats correct | Medium | Each type mismatch reduces score by 5–15 points |
| No sensitive data leaked | High | Any sensitive data leakage forces score ≤ 15 |

#### API Response Score Bands

| Score | Status Code | Required Fields | Schema | Sensitive Data |
|-------|-------------|-----------------|--------|----------------|
| 90–100 | Correct | All present | Fully compliant | None leaked |
| 70–89 | Correct | All present | Minor drift (extra fields, format issue) | None leaked |
| 50–69 | Correct | 1–2 missing | Notable issues (type mismatches) | None leaked |
| 30–49 | Wrong OR | Multiple missing | Significant schema violations | None leaked |
| 0–29 | Server error (5xx) | Most/all missing | Broken | Leaked OR 0-byte file |

#### API Response Score Adjustment Rules

| Condition | Adjustment |
|-----------|-----------|
| HTTP status code matches expected | Base: 100 |
| HTTP status code does not match expected | −30 to −50 |
| Each missing required field | −10 to −20 |
| Each type mismatch on required field | −10 to −15 |
| Extra unexpected fields (non-deprecated) | −5 per field |
| Deprecated field present | −5 |
| Sensitive data leaked (stack trace, SQL, secrets) | Force score ≤ 15 |
| Pagination fields inconsistent (total < returned) | −10 |
| Required array is unexpectedly empty | −15 |
| HTTP status not captured in evidence file | −10 to −15 |
| 0-byte or invalid JSON file | Force score = 0 |

---

### CLI Output Evidence (LLM)

Confidence for CLI output evidence is derived from three dimensions:
**absence of error indicators**, **presence of expected success markers**, and
**unexpected warning assessment**.

#### Scoring Factors

| Factor | Weight | Scoring Impact |
|--------|--------|---------------|
| Exit code correct | High | Wrong or non-zero exit code reduces score by 25–50 points |
| No error keywords detected | High | CRITICAL error keywords reduce score by 30–50 points |
| Expected success markers present | High | Each absent success marker reduces score by 10–20 points |
| Unexpected warnings | Low–Medium | Severity-dependent reduction |

#### CLI Output Score Bands

| Score | Exit Code | Error Keywords | Success Markers | Warnings |
|-------|-----------|---------------|-----------------|----------|
| 90–100 | 0 (correct) | None | All present | None unexpected |
| 70–89 | 0 (correct) | None | Most present | Benign LOW warnings only |
| 50–69 | 0 OR missing | Some ambiguous | Some present | Non-benign MEDIUM warnings |
| 30–49 | Non-zero OR | WARN/ERROR lines | Most absent | HIGH warnings or errors |
| 0–29 | Non-zero (confirmed) | FATAL/CRITICAL lines | All absent | Explicit failure OR 0-byte file |

#### CLI Output Score Adjustment Rules

| Condition | Adjustment |
|-----------|-----------|
| Exit code 0 confirmed | Base: 100 |
| Exit code non-zero | −30 to −50 |
| Exit code not captured in evidence | −10 to −15 |
| Each absent expected success marker | −10 to −20 |
| PARTIAL success marker (present but contradicted) | −10 |
| Low-severity benign deprecation warning | −3 to −5 |
| MEDIUM non-benign deprecation or security warning | −10 to −15 |
| HIGH unexpected warning (resource, compatibility) | −20 to −25 |
| CRITICAL error keyword (FATAL, panic, segfault) | Force score ≤ 25 |
| Stack trace present | −25 to −40 |
| Command output truncated (output seems incomplete) | −10 |
| 0-byte evidence file | Force score = 0 |

---

## Journey-Level Score Aggregation

When multiple evidence items are analyzed for a single journey, their individual
confidence scores are aggregated into a **journey-level confidence score**.

### Aggregation Method

Journey-level confidence is computed as a **weighted average** of individual evidence
scores, adjusted downward by any floor rules triggered by CRITICAL findings.

#### Step 1: Compute the Raw Weighted Average

```
journey_score = sum(weight_i × confidence_i) / sum(weight_i)
```

Where `weight_i` is determined by evidence type:

| Evidence Type | Default Weight |
|--------------|---------------|
| `screenshot` | 1.0 |
| `api-response` | 1.5 |
| `cli-output` | 1.0 |

API response evidence receives higher weight because it provides the most objective,
machine-verifiable signal of functional correctness.

#### Step 2: Apply Floor Rules

After computing the weighted average, apply these floor rules in order:

| Condition | Floor Applied |
|-----------|--------------|
| Any evidence item with `verdict_label: "FAIL"` | Journey score ≤ 65 |
| Any CRITICAL finding across all evidence | Journey score ≤ 50 |
| Two or more CRITICAL findings across all evidence | Journey score ≤ 30 |
| Any 0-byte evidence file in the set | Journey score ≤ 40 |
| More than 50% of evidence items have `verdict_label: "FAIL"` | Journey score ≤ 25 |

Floor rules prevent a strong-performing subset of evidence from masking critical
failures in other evidence items for the same journey.

#### Step 3: Apply Coverage Adjustment

If fewer evidence items were analyzed than expected (some evidence files were skipped,
invalid, or 0-byte), reduce the journey score to reflect incomplete coverage:

| Coverage | Adjustment |
|----------|-----------|
| 100% of expected evidence analyzed | No adjustment |
| 75–99% analyzed | −5 |
| 50–74% analyzed | −10 |
| < 50% analyzed | −20 |

### Aggregation Example

**Journey:** User Authentication (3 evidence files)

| Evidence File | Type | Confidence | Weight | Weighted Score |
|--------------|------|------------|--------|---------------|
| `step-01-login-page.png` | screenshot | 94 | 1.0 | 94.0 |
| `step-02-auth-api-response.json` | api-response | 87 | 1.5 | 130.5 |
| `step-03-server-startup.txt` | cli-output | 72 | 1.0 | 72.0 |

```
Raw weighted average = (94.0 + 130.5 + 72.0) / (1.0 + 1.5 + 1.0)
                     = 296.5 / 3.5
                     = 84.7 → rounded to 85
```

No CRITICAL findings, no 0-byte files, 100% coverage.

**Journey-level confidence: 85** → MODERATE tier → `PASS (with notes)`

---

### Aggregation Example with Floor Rule

**Journey:** Checkout Flow (3 evidence files, one critical failure)

| Evidence File | Type | Confidence | Findings | Weight | Weighted Score |
|--------------|------|------------|----------|--------|---------------|
| `step-05-cart-page.png` | screenshot | 91 | None | 1.0 | 91.0 |
| `step-06-payment-api.json` | api-response | 8 | CRITICAL: 500 error | 1.5 | 12.0 |
| `step-07-order-confirm.png` | screenshot | 5 | CRITICAL: error page | 1.0 | 5.0 |

```
Raw weighted average = (91.0 + 12.0 + 5.0) / (1.0 + 1.5 + 1.0)
                     = 108.0 / 3.5
                     = 30.9 → rounded to 31
```

Floor rule applies: 2 CRITICAL findings → journey score ≤ 30.

**Journey-level confidence: 30** → INSUFFICIENT tier → `FAIL`

---

## Score Interpretation for Verdict Writers

The `verdict-writer` agent uses journey-level confidence scores as one input among
several when writing PASS/FAIL verdicts.

### Recommended Verdict Guidance

| Journey Score | Guidance |
|--------------|----------|
| 90–100 | Strong evidence supports PASS. Cite the top 2–3 evidence items directly. |
| 70–89 | Evidence supports PASS but note all MEDIUM and HIGH findings in the verdict. Recommend remediation for findings. |
| 50–69 | WARN territory. Human review of all evidence required before issuing PASS. Identify which specific gaps block confident assessment. |
| 0–49 | Evidence supports FAIL. Cite CRITICAL findings and failing evidence items directly. Write root cause and remediation. |

### Important Constraints

1. **Confidence score alone cannot produce a PASS verdict.** The `verdict-writer` must
   also verify that PASS criteria from the validation plan are met.

2. **A high confidence score does not override a clear failure.** If a screenshot shows
   a 500 error page, that evidence is FAIL regardless of other items scoring 95.

3. **A low confidence score does not automatically produce a FAIL verdict.** If confidence
   is low due to missing evidence (skipped captures, offline analysis), document the gap
   and defer the verdict rather than defaulting to FAIL.

4. **Never reuse confidence scores from a previous analysis run.** Re-analyze fresh
   evidence every time. Confidence scores are ephemeral and tied to a specific evidence set.

---

## Score Calibration Notes

### Common Miscalibration Patterns to Avoid

| Mistake | Correct Approach |
|---------|-----------------|
| Giving a 95 to a screenshot that shows a spinner | Loading indicators are NOT high-confidence evidence; reduce to 50–65 |
| Giving a 75 to an API response with a missing required field | Missing required fields are HIGH severity; reduce to 40–60 |
| Averaging a 0 with 95s to get 63 | Apply floor rules BEFORE averaging to prevent masking |
| Giving a 60 because "it looks mostly fine" | Assign based on specific criteria, not gestalt impression |
| Assigning 100 when exit code was not captured | Missing exit code = reduce by 10–15 from max |

### Confidence vs. Evidence Completeness

Confidence measures **certainty given the evidence present**, not **evidence quantity**.
A single, crystal-clear API response can score 97. An exhaustive set of screenshots
of a broken page should score 5.

Do not inflate scores because many evidence files were captured. Inflate scores only
when the evidence clearly and specifically supports the feature being validated.

---

## Related References

- `skills/ai-evidence-analysis/SKILL.md` — Full skill documentation
- `skills/ai-evidence-analysis/references/screenshot-analysis.md` — Screenshot prompt templates and schema
- `skills/ai-evidence-analysis/references/api-response-analysis.md` — API response prompt templates and schema
- `skills/ai-evidence-analysis/references/cli-output-analysis.md` — CLI output prompt templates and schema
- `agents/verdict-writer.md` — How the verdict writer uses confidence scores in final verdicts
