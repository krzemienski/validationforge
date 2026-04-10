---
name: ai-evidence-analysis
description: >
  AI-powered analysis of validation evidence using vision models for screenshots
  and LLM analysis for API responses and CLI output. Produces confidence scores
  (0-100) and structured findings per evidence item to augment human review.
triggers:
  - "analyze evidence"
  - "AI evidence analysis"
  - "evidence confidence score"
  - "analyze screenshot"
  - "analyze API response"
  - "analyze CLI output"
  - "evidence quality check"
  - "flag evidence issues"
---

# AI-Powered Evidence Analysis

Intelligent analysis of captured validation evidence using vision models and LLMs. Produces confidence scores, structured findings, and verdict labels per evidence item — catching issues human reviewers might miss.

## When to Use

- After capturing evidence in `e2e-evidence/` and before writing the final verdict
- When you want AI-assisted review of screenshot quality (rendering, element presence)
- When validating API response bodies against expected schemas or patterns
- When CLI output contains warnings or errors that need systematic analysis
- When confidence scores are needed to prioritize which evidence to cite in verdicts

## Scope

**Handles:**
- Vision model analysis of screenshot evidence (`.png`, `.jpg`, `.webp`)
- LLM analysis of API response evidence (`.json`)
- LLM analysis of CLI output evidence (`.txt`, `.log`)
- Confidence score assignment (0–100) per evidence item
- Structured findings with severity labels
- Optional execution (skip for offline or cost-sensitive environments)

**Does NOT handle:**
- Evidence capture (use `evidence-capturer` agent)
- Verdict writing (use `verdict-writer` agent)
- Visual inspection checklist (use `visual-inspection`)
- API contract validation (use `api-validation`)

## Supported Evidence Types

| Type | File Extensions | Analysis Model | What It Checks |
|------|----------------|----------------|----------------|
| `screenshot` | `.png`, `.jpg`, `.webp` | Vision (claude-opus/sonnet with vision) | Page load completeness, expected element visibility, layout integrity, visual regressions |
| `api-response` | `.json` | LLM text analysis | Schema compliance, required field presence, error code correctness, edge case coverage |
| `cli-output` | `.txt`, `.log` | LLM text analysis | Error indicators, success markers, unexpected warnings, exit code patterns |

## Analysis Output Schema

Every evidence item analyzed produces an `AnalysisResult` with the following structure:

```json
{
  "evidence_file": "e2e-evidence/journey-slug/step-03-login-response.json",
  "evidence_type": "api-response",
  "confidence": 87,
  "verdict_label": "PASS",
  "findings": [
    {
      "severity": "LOW",
      "finding": "Response includes deprecated field `legacy_token`",
      "recommendation": "Remove `legacy_token` from response; it is not part of current schema"
    }
  ],
  "summary": "API response matches expected schema. Authentication token present. One deprecated field detected.",
  "analyzed_at": "2025-01-15T14:32:00Z"
}
```

### Field Definitions

| Field | Type | Description |
|-------|------|-------------|
| `evidence_file` | string | Relative path to the evidence file analyzed |
| `evidence_type` | `"screenshot"` \| `"api-response"` \| `"cli-output"` | Detected or specified evidence type |
| `confidence` | integer 0–100 | AI confidence that the evidence supports a PASS verdict |
| `verdict_label` | `"PASS"` \| `"FAIL"` \| `"WARN"` | Recommended verdict for this evidence item |
| `findings` | Finding[] | Array of specific observations (may be empty for clean evidence) |
| `summary` | string | 1–3 sentence human-readable summary of the analysis |
| `analyzed_at` | ISO 8601 string | Timestamp of when analysis was performed |

### Confidence Score Interpretation

| Score | Label | Meaning |
|-------|-------|---------|
| 90–100 | PASS | Strong evidence the feature works correctly |
| 70–89 | PASS (with notes) | Evidence is good; minor issues detected |
| 50–69 | WARN | Evidence is ambiguous; human review needed |
| 30–49 | FAIL | Evidence suggests functional problems |
| 0–29 | FAIL | Evidence clearly shows failure or is invalid |

### Finding Schema

```json
{
  "severity": "CRITICAL | HIGH | MEDIUM | LOW",
  "finding": "Specific observation about the evidence",
  "recommendation": "Suggested remediation or follow-up action"
}
```

### Verdict Label Rules

- **PASS**: `confidence >= 70` AND no CRITICAL findings
- **WARN**: `confidence >= 50` AND no CRITICAL findings, but MEDIUM or HIGH findings present
- **FAIL**: `confidence < 50` OR any CRITICAL finding present

## Analysis Protocol

### Step 1: Discover Evidence

```bash
find e2e-evidence/ -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.json" -o -name "*.txt" -o -name "*.log" \) \
  | sort > e2e-evidence/evidence-inventory.txt
cat e2e-evidence/evidence-inventory.txt
```

Skip files that are 0 bytes — empty evidence files are invalid and should be noted as failures.

### Step 2: Classify Evidence Types

For each file, determine its type:
- Image files (`*.png`, `*.jpg`, `*.webp`) → `screenshot`
- JSON files (`*.json`) → `api-response`
- Text/log files (`*.txt`, `*.log`) → `cli-output`

### Step 3: Analyze by Type

#### Screenshot Analysis (Vision Model)

Provide the screenshot to the vision model with a structured prompt:

```
Analyze this screenshot as validation evidence. Answer the following:
1. Is the page fully rendered (no blank areas, spinners, or loading states)?
2. Are there any visible error messages or error states?
3. What key UI elements are visible? List them specifically.
4. Are there any layout defects (overlapping elements, cut-off text, broken images)?
5. Overall: does this screenshot constitute positive evidence that the feature is working?

Respond in JSON matching the AnalysisResult schema.
```

#### API Response Analysis (LLM)

Provide the JSON response body with this prompt:

```
Analyze this API response as validation evidence. Check:
1. Is the HTTP response a success status (2xx)?
2. Are all expected fields present and non-null?
3. Do field values match expected types and formats?
4. Are there any error objects, empty required arrays, or null required fields?
5. Overall: does this response confirm the API is functioning correctly?

Respond in JSON matching the AnalysisResult schema.
```

#### CLI Output Analysis (LLM)

Provide the CLI output text with this prompt:

```
Analyze this CLI output as validation evidence. Check:
1. Are there any ERROR, FATAL, or PANIC lines?
2. Are there unexpected WARNING lines that indicate problems?
3. Is there a success indicator (exit 0, "Done", "Success", "Passed")?
4. Are there any stack traces or exception messages?
5. Overall: does this output indicate successful execution?

Respond in JSON matching the AnalysisResult schema.
```

### Step 4: Save Analysis Results

Save each result as a sidecar file alongside the evidence:

```
e2e-evidence/{journey-slug}/step-03-login-response.json          ← original evidence
e2e-evidence/{journey-slug}/step-03-login-response.analysis.json ← AI analysis result
```

Also append to the aggregate analysis report:

```bash
cat >> e2e-evidence/ai-analysis-report.json << 'EOF'
{
  "evidence_file": "...",
  "confidence": 87,
  ...
}
EOF
```

### Step 5: Generate Analysis Summary

After all evidence is analyzed, produce `e2e-evidence/ai-analysis-summary.md`:

```markdown
# AI Evidence Analysis Summary

**Evidence analyzed:** N files
**Analysis timestamp:** YYYY-MM-DDTHH:MM:SSZ
**Overall confidence:** NN (average)

## Results by Verdict

| Verdict | Count | Files |
|---------|-------|-------|
| PASS    | N     | ... |
| WARN    | N     | ... |
| FAIL    | N     | ... |

## Findings Requiring Attention

### [CRITICAL] Finding
**Evidence:** `e2e-evidence/path/to/file`
**Observed:** ...
**Recommendation:** ...

### [HIGH] Finding
...

## Low-Confidence Items (< 70)

List any items where confidence < 70 and explain why human review is needed.
```

## Enabling and Disabling Analysis

AI evidence analysis is **optional**. It can be disabled in two ways:

1. **Environment variable**: `VALIDATIONFORGE_AI_ANALYSIS=false`
2. **Config flag**: `"ai_evidence_analysis": false` in the active config file (`config/strict.json`, `config/standard.json`, or `config/permissive.json`)

When disabled, this skill exits immediately with a notice:

```
AI evidence analysis is disabled (VALIDATIONFORGE_AI_ANALYSIS=false).
Skipping analysis. Evidence will be reviewed manually by verdict-writer.
```

## Integration with ValidationForge Pipeline

This skill runs between Phase 4 (ANALYZE) and Phase 5 (VERDICT) of the 7-phase pipeline:

```
3. EXECUTE    → Capture evidence to e2e-evidence/
4. ANALYZE    → Root cause investigation for FAILs
  └─ ai-evidence-analysis  ← runs here
5. VERDICT    → verdict-writer reads .analysis.json sidecar files
```

The `verdict-writer` agent is AI-analysis-aware: when `.analysis.json` sidecar files are present, it reads the confidence scores and findings as additional input when writing its PASS/FAIL verdict.

## Anti-Patterns

| Anti-pattern | Correct approach |
|-------------|-----------------|
| Treating AI confidence as a final verdict | Confidence informs the verdict; human/agent judgment makes the final call |
| Skipping analysis for "obvious" evidence | Run analysis on all evidence — it catches subtle issues |
| Caching analysis results across runs | Always re-analyze fresh evidence; never reuse results from a previous attempt |
| Using analysis to override a clear failure | If a screenshot shows an error page, that is a FAIL regardless of confidence score |
| Running analysis on 0-byte evidence files | Empty files are invalid evidence; flag them as FAIL before analyzing |

## Related Skills

- `visual-inspection` — Manual visual checklist for UI validation
- `api-validation` — Structured API contract validation via curl
- `functional-validation` — End-to-end platform validation protocol
- `gate-validation-discipline` — Evidence examination before completion claims
- `sequential-analysis` — Deep root cause analysis for FAILs
