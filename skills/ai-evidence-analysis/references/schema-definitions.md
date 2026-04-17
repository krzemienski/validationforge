# Schema Definitions

This file is loaded by the `ai-evidence-analysis` skill when you need the full field reference for `AnalysisResult` output — field types, confidence-to-verdict mapping, and the `Finding` sub-schema. Load this when writing or validating the JSON output of an analysis run.

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
