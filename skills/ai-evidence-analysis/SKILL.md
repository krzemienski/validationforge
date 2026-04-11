---
name: ai-evidence-analysis
description: >
  AI-powered analysis of validation evidence using vision models for screenshots
  and LLM analysis for API responses and CLI output. Produces confidence scores
  (0-100) and structured findings per evidence item to augment human review.
context_priority: standard
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

Determine evidence type using **both file extension and content inspection**:

#### By File Extension (primary detection)

| Extension | Evidence Type | Analysis Model |
|-----------|--------------|----------------|
| `.png`, `.jpg`, `.jpeg`, `.webp` | `screenshot` | Vision (claude-sonnet with vision) |
| `.json` | `api-response` | LLM text analysis |
| `.txt`, `.log` | `cli-output` | LLM text analysis |

#### By Content (fallback when extension is ambiguous)

When the extension is missing or generic (e.g., no extension, `.out`, `.data`), inspect the first 512 bytes of the file:

```bash
file_head=$(head -c 512 "$evidence_file")

# Detect JSON
if echo "$file_head" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
  evidence_type="api-response"
# Detect image magic bytes (PNG: \x89PNG, JPEG: \xFF\xD8)
elif xxd -l 4 "$evidence_file" | grep -qE "8950 4e47|ffd8 ffe"; then
  evidence_type="screenshot"
# Default to CLI output for readable text
else
  evidence_type="cli-output"
fi
```

Skip analysis (and flag as invalid) for:
- Files that are 0 bytes
- Files that cannot be read (permissions error)
- Binary files with no detected image magic bytes

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

Save each result using the standard output format. The output file is named sequentially within the journey directory:

```
e2e-evidence/{journey-slug}/ai-analysis-step-NN-{description}.json
```

Where:
- `{journey-slug}` is the kebab-case journey name (e.g., `user-login`, `api-create-order`)
- `NN` is a zero-padded two-digit step counter scoped to the analysis run (01, 02, …)
- `{description}` is a short kebab-case label derived from the evidence file being analyzed

**Examples:**
```
e2e-evidence/user-login/ai-analysis-step-01-screenshot-home.json
e2e-evidence/user-login/ai-analysis-step-02-api-response-auth.json
e2e-evidence/user-login/ai-analysis-step-03-cli-output-build.json
e2e-evidence/api-create-order/ai-analysis-step-01-response-body.json
```

**Original evidence files are never modified.** Analysis results are always new files.

Also append each result to the aggregate analysis report:

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

AI evidence analysis is **optional**. Check the disabled/offline state before invoking any model calls.

### Disable Checks (must run before Step 1)

```bash
# 1. Check environment variable
if [ "${VF_AI_ANALYSIS}" = "disabled" ]; then
  echo "AI evidence analysis is disabled (VF_AI_ANALYSIS=disabled)."
  echo "Skipping analysis. Evidence will be reviewed manually by verdict-writer."
  exit 0
fi

# 2. Check config flag in active config file
config_file="config/standard.json"  # or strict.json / permissive.json
if command -v jq >/dev/null 2>&1; then
  ai_enabled=$(jq -r 'if .ai_analysis.enabled == false then "false" else "true" end' "$config_file" 2>/dev/null)
  if [ "$ai_enabled" = "false" ]; then
    echo "AI evidence analysis is disabled (config: ai_analysis.enabled=false)."
    echo "Skipping analysis. Evidence will be reviewed manually by verdict-writer."
    exit 0
  fi
fi
```

### Disable Methods

| Method | Value | Effect |
|--------|-------|--------|
| `VF_AI_ANALYSIS=disabled` | Environment variable | Disables for the current shell session |
| `"ai_analysis": { "enabled": false }` | Config file flag | Disables for all runs using that config |

### Offline / Air-Gapped Mode

When running in an **offline** environment without API access (CI behind a firewall, air-gapped workstations), set:

```bash
export VF_AI_ANALYSIS=disabled
```

In offline mode, the skill:
1. Skips all model API calls
2. Produces no `ai-analysis-*.json` files
3. Logs a single notice line: `[ai-evidence-analysis] offline — analysis skipped`
4. Does NOT fail the pipeline — the `verdict-writer` proceeds with raw evidence only

**Never hard-fail the validation pipeline because AI analysis is unavailable.** Offline is an expected operational state, not an error.

## Integration with ValidationForge Pipeline

This skill runs at step 3.5 — between Phase 3 (EXECUTE) and Phase 4 (ANALYZE) — in the 7-phase pipeline:

```
3.   EXECUTE      → Capture evidence to e2e-evidence/
3.5  AI ANALYZE   → ai-evidence-analysis runs here ← confidence scores + findings
4.   ANALYZE      → Root cause investigation for FAILs (informed by AI analysis)
5.   VERDICT      → verdict-writer reads ai-analysis-*.json sidecar files
```

The `verdict-writer` agent is AI-analysis-aware: when `ai-analysis-*.json` sidecar files are present, it reads the confidence scores and findings as additional input when writing its PASS/FAIL verdict.

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
