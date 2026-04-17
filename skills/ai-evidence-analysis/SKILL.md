---
name: ai-evidence-analysis
description: "Use after capturing validation evidence (phase 3.5, between capture and verdict writing) when you want AI to systematically review screenshots, API responses, and CLI output — flagging issues a human reviewer might skim past. Produces a 0-100 confidence score and structured findings per evidence item (3 types supported: screenshot / api-response / cli-output). Optional and easy to disable in offline or cost-sensitive environments. Reach for this on phrases like 'review my evidence', 'score the screenshots', 'AI check the API responses', 'spot issues in the logs', or when the verdict-writer agent needs confidence signals before ruling PASS/FAIL."
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
  - "review my evidence"
  - "score the screenshots"
---

# AI-Powered Evidence Analysis

Intelligent analysis of captured validation evidence using vision models and LLMs. Produces confidence scores, structured findings, and verdict labels per evidence item — catching issues human reviewers might miss.

## When to Use

- After capturing evidence in `e2e-evidence/` and before writing the final verdict
- When you want AI-assisted review of screenshot quality (rendering, element presence)
- When validating API response bodies against expected schemas or patterns
- When CLI output contains warnings or errors that need systematic analysis
- When confidence scores are needed to prioritize which evidence to cite in verdicts

## How to disable

Three equivalent ways, pick whichever fits your workflow:

- Env var: `export VF_AI_ANALYSIS=disabled`
- Config: set `ai_analysis.enabled = false` in your ValidationForge config
- Offline mode: if no API credentials are configured, analysis is auto-skipped

When disabled, the pipeline continues unchanged — verdicts are written by humans/agents without AI confidence scores.

## Common mistakes

Bad patterns that show up when this skill is misused:

- **Treating the confidence score as a verdict.** The score is a signal for the verdict-writer, not the verdict itself. A 70 needs human review; a 95 still needs a sanity check.
- **Analyzing evidence that shouldn't exist.** Empty files, zero-byte screenshots, log files with no content — don't feed these to a model hoping for insight. Flag them as invalid evidence and move on.
- **Over-indexing on findings list length.** A clean PASS has zero findings. More findings doesn't mean more thorough analysis; it usually means the model is hallucinating to fill the array.
- **Running AI analysis in CI without a cost budget.** Vision analysis on 50 screenshots per build adds up fast. Cap the number of files analyzed per run, or disable in CI and let humans review.

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

## Analysis Output

Every evidence item analyzed produces an `AnalysisResult` JSON object containing `evidence_file`, `evidence_type`, a 0–100 `confidence` score, a `verdict_label` (PASS/WARN/FAIL), a list of `findings` with severity, a 1–3 sentence `summary`, and an `analyzed_at` timestamp. Verdict labels are derived from confidence thresholds and finding severity — a CRITICAL finding forces FAIL regardless of score.

> For the full field-by-field schema, confidence-to-verdict mapping table, and `Finding` sub-schema, see `references/schema-definitions.md`. Load that file when writing the JSON output or validating an existing analysis file.

## Analysis Protocol

The analysis pipeline has five sequential steps. Steps 1–3 (discover, classify, analyze) are the heavy-lift portion — their details live in a reference file so the core SKILL.md stays lean. Steps 4–5 (save results, generate summary) define the output structure the verdict-writer depends on and live inline below.

### Steps 1–3: Discover, Classify, Analyze

**Fast path**: `bash scripts/detect-evidence-type.sh --evidence-dir=e2e-evidence --write-tsv` produces `e2e-evidence/_classified.tsv` that pre-classifies every evidence file by category. Read that TSV to skip inline extension/content heuristics; fall back to the reference-file heuristics only when the script is unavailable.

> For Steps 1–3 detail (the `find` discovery snippet, the extension + magic-byte classification branches, and the exact model prompts for screenshot / api-response / cli-output analysis), see `references/analysis-protocol.md`. Load that file when you're about to invoke a model on an evidence item.

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
