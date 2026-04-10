# CLI Output Analysis Reference

LLM prompt templates, output schema definitions, and example analysis output for
AI-powered CLI evidence analysis.

## Overview

CLI output evidence (`.txt` files captured by `cli-validation`) is analyzed using
an LLM that evaluates the command output against three quality dimensions:

1. **Error indicators** — Are error messages, exceptions, or non-zero exit codes present?
2. **Success markers** — Are expected success signals present in the output?
3. **Unexpected warnings** — Are deprecation notices, resource warnings, or unexpected messages present?

Every analysis produces a structured `CliOutputAnalysisResult` with a `confidence`
score (0–100) and specific `findings` organized by analysis category.

---

## LLM Prompt Template

Use this exact prompt structure when submitting a CLI output file to the LLM.
Replace `{journey_name}`, `{command}`, `{expected_exit_code}`, and
`{expected_success_markers}` with values from the active validation plan.

```
You are a CLI validation expert analyzing captured command-line output as validation evidence.

Journey: {journey_name}
Command: {command}
Expected exit code: {expected_exit_code}
Expected success markers: {expected_success_markers}

Below is the captured CLI output:

---OUTPUT START---
{cli_output}
---OUTPUT END---

Analyze this CLI output across three dimensions:

### 1. Error Indicators
Scan the output for signals that the command failed or encountered errors:
- Non-zero exit code lines (e.g. "exit code: 1", "Process exited with code 2", "returned 1")
- Explicit error keywords: ERROR, FATAL, CRITICAL, Exception, Traceback, panic, Segmentation fault
- Stack traces (multi-line error dumps with file paths and line numbers)
- Build or compile failure messages (e.g. "Build failed", "Compilation error", "FAILED")
- Test failure summaries (e.g. "X tests failed", "FAIL", "FAILED: N tests")
- File not found or permission denied messages
- Connection refused, timeout, or network error messages
- Out of memory or resource exhaustion indicators

For each error indicator found, record the exact line(s) from the output as evidence.

### 2. Success Markers
Verify that expected success signals appear in the output:
- For each item in "Expected success markers", check whether a matching line or phrase
  is present in the output
- Also check for common success patterns: "Build succeeded", "All tests passed",
  "SUCCESS", "Done", "Completed", "✓", "OK", "Installed", "Deployed"
- Exit code 0 (if present in output)
- Any explicit completion or summary line confirming the command finished successfully

For each success marker, state whether it is PRESENT, ABSENT, or PARTIAL (present but
accompanied by error context).

### 3. Unexpected Warnings
Identify warnings and non-critical issues that were not anticipated:
- Deprecation warnings (e.g. "DeprecationWarning:", "deprecated", "will be removed in")
- Security advisories or vulnerability notices
- Performance warnings (slow queries, high memory usage, timeout approach)
- Compatibility warnings (version mismatch, unsupported runtime)
- Skipped steps or partial execution notices
- "WARN" or "WARNING" level log lines that are not part of expected output
- Missing optional dependencies or configuration values using defaults

Distinguish between warnings that are benign (expected in the environment) vs.
warnings that indicate a potential issue requiring investigation.

### 4. Confidence Assessment
Based on dimensions 1–3, assign a confidence score (0–100):
- 90–100: No error indicators, all expected success markers present, no unexpected warnings
- 70–89: No errors, most success markers present, minor or benign warnings only
- 50–69: Some success markers present, but unexpected warnings or unclear error indicators
- 30–49: Notable error indicators present, or multiple expected success markers absent
- 0–29:  Clear failure — explicit errors, non-zero exit code, or no success markers found

Respond ONLY with a JSON object matching the CliOutputAnalysisResult schema below.
Do not include markdown fences or explanatory text outside the JSON.
```

---

## Output Schema

### `CliOutputAnalysisResult`

```json
{
  "evidence_file": "e2e-evidence/journey-slug/step-03-build-output.txt",
  "evidence_type": "cli-output",
  "confidence": 91,
  "verdict_label": "PASS",
  "error_indicators": {
    "errors_found": false,
    "exit_code_present": true,
    "exit_code_value": 0,
    "exit_code_correct": true,
    "error_lines": [],
    "notes": "Exit code 0. No error keywords or stack traces detected."
  },
  "success_markers": [
    {
      "marker": "Build succeeded",
      "status": "PRESENT",
      "matched_line": "Build succeeded. 0 errors, 0 warnings.",
      "notes": "Explicit build success line found at end of output."
    }
  ],
  "unexpected_warnings": [
    {
      "warning": "npm warn deprecated request@2.88.2",
      "severity": "LOW",
      "benign": true,
      "notes": "Deprecation notice for transitive dependency; does not affect build output."
    }
  ],
  "findings": [
    {
      "severity": "LOW",
      "finding": "Deprecation notice for `request@2.88.2` (transitive dependency) present in install output",
      "recommendation": "Review dependency tree; consider updating or replacing packages that depend on the deprecated `request` library"
    }
  ],
  "summary": "Build command completed successfully with exit code 0. Build succeeded line confirmed. One deprecation notice for a transitive npm dependency detected but does not affect the build outcome.",
  "analyzed_at": "2025-01-15T14:32:00Z"
}
```

### Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `evidence_file` | string | yes | Relative path to the CLI output evidence file |
| `evidence_type` | `"cli-output"` | yes | Always `"cli-output"` for this analysis type |
| `confidence` | integer 0–100 | yes | Overall confidence that the CLI output supports a PASS verdict |
| `verdict_label` | `"PASS"` \| `"WARN"` \| `"FAIL"` | yes | Recommended verdict derived from confidence and findings |
| `error_indicators` | CliErrorResult | yes | Structured assessment of error signals in the output |
| `success_markers` | SuccessMarkerCheck[] | yes | Per-marker presence check results |
| `unexpected_warnings` | UnexpectedWarning[] | yes | Non-critical warnings detected (empty array if none) |
| `findings` | Finding[] | yes | Consolidated finding list across all categories |
| `summary` | string | yes | 1–3 sentence human-readable synthesis of the analysis |
| `analyzed_at` | ISO 8601 string | yes | Timestamp of when analysis was performed |

### `CliErrorResult` Schema

```json
{
  "errors_found": true,
  "exit_code_present": true,
  "exit_code_value": 1,
  "exit_code_correct": false,
  "error_lines": [
    "ERROR: Cannot find module './config/database'",
    "Error: ENOENT: no such file or directory, open './config/database.js'"
  ],
  "notes": "Exit code 1. Two error lines found indicating missing module."
}
```

| Field | Type | Description |
|-------|------|-------------|
| `errors_found` | boolean | `true` if any error indicators were detected in the output |
| `exit_code_present` | boolean | `true` if an exit code line is present in the captured output |
| `exit_code_value` | integer \| null | The exit code value if present; `null` if not captured |
| `exit_code_correct` | boolean \| null | `true` if exit code matches expected; `null` if exit code not present |
| `error_lines` | string[] | Exact lines from the output that contain error indicators |
| `notes` | string | Free-text description of the error analysis |

### `SuccessMarkerCheck` Schema

```json
{
  "marker": "All tests passed",
  "status": "PRESENT",
  "matched_line": "✓ All tests passed (47 tests, 0 failures)",
  "notes": "Full test suite pass line found at end of test run output."
}
```

| Field | Type | Description |
|-------|------|-------------|
| `marker` | string | The expected success marker from the validation plan |
| `status` | `"PRESENT"` \| `"ABSENT"` \| `"PARTIAL"` | Whether the marker was found in the output |
| `matched_line` | string \| null | The exact line from the output that satisfies this marker; `null` if ABSENT |
| `notes` | string | Specific observation about the marker's presence or absence |

**Status definitions:**

| Status | Meaning |
|--------|---------|
| `PRESENT` | Marker phrase or equivalent confirmation is clearly present in the output |
| `ABSENT` | No matching phrase or equivalent found anywhere in the output |
| `PARTIAL` | A partial match is found, but accompanied by contradicting error context or incomplete output |

### `UnexpectedWarning` Schema

```json
{
  "warning": "DeprecationWarning: Buffer() is deprecated due to security and usability issues",
  "severity": "MEDIUM",
  "benign": false,
  "notes": "Node.js security deprecation warning; indicates code using deprecated Buffer constructor"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `warning` | string | The warning text as it appears in the output (quoted exactly) |
| `severity` | `"CRITICAL"` \| `"HIGH"` \| `"MEDIUM"` \| `"LOW"` | Impact level of the warning |
| `benign` | boolean | `true` if the warning is known to be harmless in this environment; `false` if it requires investigation |
| `notes` | string | Context explaining why the warning is or is not a concern |

### `Finding` Schema

```json
{
  "severity": "HIGH",
  "finding": "Exit code 2 returned; expected 0. Last error line: 'FAILED: 3 test suites'",
  "recommendation": "Review failing test suites; run tests locally with verbose output to identify root cause"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `severity` | `"CRITICAL"` \| `"HIGH"` \| `"MEDIUM"` \| `"LOW"` | Impact level of the finding |
| `finding` | string | Specific factual observation — quote exact output lines where possible |
| `recommendation` | string | Actionable next step to investigate or remediate |

### Severity Definitions

| Severity | Definition | CLI Output Examples |
|----------|-----------|---------------------|
| `CRITICAL` | Command completely failed or produced output that indicates a broken system | Non-zero exit code, explicit build failure, unhandled exception, segmentation fault |
| `HIGH` | Major failure indicator; command may have partially succeeded | Test suite failures, connection errors, missing required files or modules |
| `MEDIUM` | Noticeable issue; command may have completed but with quality problems | Security deprecation warnings, skipped tests, unexpected fallback behavior |
| `LOW` | Minor issue; command succeeded but with informational noise | Benign deprecation notices for transitive deps, verbose debug output, minor version skew |

### Verdict Label Rules

Derived automatically from `confidence` and `findings`:

| Condition | Verdict |
|-----------|---------|
| `confidence >= 70` AND no CRITICAL findings | `PASS` |
| `confidence >= 50` AND no CRITICAL findings AND MEDIUM or HIGH findings present | `WARN` |
| `confidence < 50` OR any CRITICAL finding | `FAIL` |

---

## Example Analysis Output

### Example 1: Full PASS — Build and Install Completed Successfully

**Evidence file:** `e2e-evidence/build-journey/step-02-npm-install-build.txt`
**Journey:** Application Build
**Command:** `npm install && npm run build`
**Expected exit code:** `0`
**Expected success markers:** `["added N packages", "Build succeeded"]`

```json
{
  "evidence_file": "e2e-evidence/build-journey/step-02-npm-install-build.txt",
  "evidence_type": "cli-output",
  "confidence": 95,
  "verdict_label": "PASS",
  "error_indicators": {
    "errors_found": false,
    "exit_code_present": true,
    "exit_code_value": 0,
    "exit_code_correct": true,
    "error_lines": [],
    "notes": "Exit code 0 confirmed. No error keywords, stack traces, or failure lines detected in output."
  },
  "success_markers": [
    {
      "marker": "added N packages",
      "status": "PRESENT",
      "matched_line": "added 342 packages, and audited 343 packages in 18s",
      "notes": "npm install completed with 342 packages installed."
    },
    {
      "marker": "Build succeeded",
      "status": "PRESENT",
      "matched_line": "✓ Build succeeded (12.4s)",
      "notes": "Build success line present at end of output with timing."
    }
  ],
  "unexpected_warnings": [],
  "findings": [],
  "summary": "Build completed successfully. npm install added 342 packages and the build step succeeded in 12.4 seconds. No error indicators or unexpected warnings detected.",
  "analyzed_at": "2025-01-15T14:32:00Z"
}
```

---

### Example 2: WARN — Test Suite Passed with Deprecation Warnings

**Evidence file:** `e2e-evidence/test-journey/step-04-test-run.txt`
**Journey:** Unit Test Execution
**Command:** `npm test`
**Expected exit code:** `0`
**Expected success markers:** `["tests passed", "Test Suites: N passed"]`

```json
{
  "evidence_file": "e2e-evidence/test-journey/step-04-test-run.txt",
  "evidence_type": "cli-output",
  "confidence": 73,
  "verdict_label": "WARN",
  "error_indicators": {
    "errors_found": false,
    "exit_code_present": true,
    "exit_code_value": 0,
    "exit_code_correct": true,
    "error_lines": [],
    "notes": "Exit code 0. No error keywords detected. Tests ran to completion."
  },
  "success_markers": [
    {
      "marker": "tests passed",
      "status": "PRESENT",
      "matched_line": "Tests:       47 passed, 47 total",
      "notes": "All 47 tests passed."
    },
    {
      "marker": "Test Suites: N passed",
      "status": "PRESENT",
      "matched_line": "Test Suites: 8 passed, 8 total",
      "notes": "All 8 test suites completed without failures."
    }
  ],
  "unexpected_warnings": [
    {
      "warning": "DeprecationWarning: Buffer() is deprecated due to security and usability issues. Please use the Buffer.alloc(), Buffer.allocUnsafe(), or Buffer.from() methods instead.",
      "severity": "MEDIUM",
      "benign": false,
      "notes": "Security-relevant deprecation in Node.js runtime. Indicates application code or a direct dependency is using the deprecated Buffer constructor."
    },
    {
      "warning": "npm warn deprecated uuid@3.4.0: Please upgrade to version 7 or higher.",
      "severity": "LOW",
      "benign": true,
      "notes": "Transitive dependency deprecation notice for uuid v3; does not affect test execution."
    }
  ],
  "findings": [
    {
      "severity": "MEDIUM",
      "finding": "Node.js security deprecation warning: `Buffer()` constructor used in application code or direct dependency",
      "recommendation": "Search codebase for `new Buffer(` and `Buffer(` calls; replace with `Buffer.from()`, `Buffer.alloc()`, or `Buffer.allocUnsafe()` as appropriate"
    },
    {
      "severity": "LOW",
      "finding": "Transitive dependency `uuid@3.4.0` is deprecated; version 7 or higher recommended",
      "recommendation": "Update the dependency that requires uuid v3 to use a newer uuid version; run `npm ls uuid` to identify which package pulls it in"
    }
  ],
  "summary": "All 47 tests across 8 suites passed with exit code 0. Two unexpected warnings detected: a security-relevant Node.js Buffer deprecation and a transitive uuid deprecation notice. Human review of the Buffer deprecation is recommended.",
  "analyzed_at": "2025-01-15T14:35:22Z"
}
```

---

### Example 3: FAIL — Deployment Script Errors with Non-Zero Exit Code

**Evidence file:** `e2e-evidence/deploy-journey/step-06-deploy-script.txt`
**Journey:** Production Deployment
**Command:** `./scripts/deploy.sh --env production`
**Expected exit code:** `0`
**Expected success markers:** `["Deployment complete", "Health check passed"]`

```json
{
  "evidence_file": "e2e-evidence/deploy-journey/step-06-deploy-script.txt",
  "evidence_type": "cli-output",
  "confidence": 5,
  "verdict_label": "FAIL",
  "error_indicators": {
    "errors_found": true,
    "exit_code_present": true,
    "exit_code_value": 1,
    "exit_code_correct": false,
    "error_lines": [
      "ERROR: Health check failed after 3 attempts — /health returned HTTP 503",
      "FATAL: Deployment rollback triggered",
      "Error: Rollback completed. Previous version restored."
    ],
    "notes": "Exit code 1. Three error lines found: health check failure, fatal error triggering rollback, and rollback completion message."
  },
  "success_markers": [
    {
      "marker": "Deployment complete",
      "status": "ABSENT",
      "matched_line": null,
      "notes": "No deployment completion line found. Rollback occurred before deployment could complete."
    },
    {
      "marker": "Health check passed",
      "status": "ABSENT",
      "matched_line": null,
      "notes": "Health check explicitly failed: '/health returned HTTP 503' per error line."
    }
  ],
  "unexpected_warnings": [],
  "findings": [
    {
      "severity": "CRITICAL",
      "finding": "Deployment script exited with code 1 after health check failure; automatic rollback was triggered",
      "recommendation": "Investigate why /health returns 503 post-deployment; check application startup logs and database connectivity before re-attempting deployment"
    },
    {
      "severity": "CRITICAL",
      "finding": "Neither expected success marker ('Deployment complete', 'Health check passed') is present; both are absent from the output",
      "recommendation": "Do not proceed with deployment until the root cause of the health check failure is identified and resolved"
    }
  ],
  "summary": "Deployment script failed with exit code 1. Health check returned HTTP 503 after 3 attempts, triggering an automatic rollback. Both expected success markers are absent. This is a FAIL — the deployment did not complete.",
  "analyzed_at": "2025-01-15T14:38:47Z"
}
```

---

## Usage Notes

### Providing Expected Success Markers

The `{expected_success_markers}` placeholder should be populated from the validation
plan's journey definition. Use phrases that appear literally in the command's typical
output:

```
Good: "Build succeeded", "All tests passed", "Deployment complete", "added N packages"
Avoid: Vague descriptions like "output indicates success" or "no errors"
```

If the success marker contains a variable number (e.g., "added 342 packages"), use a
pattern description: `"added N packages"`. The LLM will recognize this as a numeric
wildcard when matching against the output.

If no expected success markers are defined, use `"none specified — infer from output"`.
The LLM will apply standard success signal detection heuristics.

### Handling Missing Exit Code in Evidence Files

Some CLI output evidence files do not include the exit code because the capture
command did not append it. When exit code is not present in the file:

1. Set `error_indicators.exit_code_present` to `false`
2. Set `error_indicators.exit_code_value` to `null`
3. Set `error_indicators.exit_code_correct` to `null`
4. Add a MEDIUM finding: `"Exit code not captured in evidence file; analysis limited to output text"`
5. Reduce confidence by 10–15 points

Always capture exit codes in evidence files using:

```bash
COMMAND_TO_RUN 2>&1 | tee e2e-evidence/journey-slug/step-N-output.txt
echo "EXIT_CODE:$?" | tee -a e2e-evidence/journey-slug/step-N-output.txt
```

### Distinguishing Errors from Expected Failure Output

Some commands intentionally produce output that contains error-like keywords as part
of normal operation (e.g., a migration tool that prints "ERROR: Table already exists —
skipping" as an idempotency notice). When analyzing such output:

- Prioritize the exit code over the presence of error keywords
- Look for the overall command completion status line
- If error lines appear alongside a success completion line, note this as PARTIAL for
  the relevant success marker and create a LOW or MEDIUM finding for investigation

Ambiguous error patterns should always be flagged as findings rather than silently
dismissed, even when the exit code suggests success.

### Sidecar File Naming

Analysis results are saved as sidecar files alongside the original CLI output:

```
e2e-evidence/journey-slug/step-03-build.txt                    ← original evidence
e2e-evidence/journey-slug/ai-analysis-step-03-build.json       ← this analysis result
```

The `verdict-writer` agent reads `ai-analysis-*.json` sidecar files when present to
incorporate AI findings into its PASS/FAIL verdict reasoning.

### Zero-Byte or Truncated Evidence Files

CLI output files that are 0 bytes are **invalid evidence**. Do not attempt to analyze
them. Instead, flag immediately:

```json
{
  "evidence_file": "e2e-evidence/journey-slug/step-03-output.txt",
  "evidence_type": "cli-output",
  "confidence": 0,
  "verdict_label": "FAIL",
  "error_indicators": {
    "errors_found": true,
    "exit_code_present": false,
    "exit_code_value": null,
    "exit_code_correct": null,
    "error_lines": [],
    "notes": "File is 0 bytes — no output captured"
  },
  "success_markers": [],
  "unexpected_warnings": [],
  "findings": [
    {
      "severity": "CRITICAL",
      "finding": "Evidence file is empty (0 bytes); no CLI output was captured",
      "recommendation": "Re-run the command with output capture; verify the command produces output and the capture path is writable"
    }
  ],
  "summary": "Invalid evidence: CLI output file is empty. This evidence cannot support any verdict.",
  "analyzed_at": "2025-01-15T14:42:00Z"
}
```

### Common CLI Error Keyword Patterns

The following keywords and patterns are strong indicators of failure regardless of
the tool or command being analyzed:

| Pattern | Indicator Type | Example |
|---------|---------------|---------|
| `ERROR:` / `error:` | Hard error | `ERROR: Cannot connect to database` |
| `FATAL:` / `fatal:` | Hard error | `FATAL: Out of memory` |
| `FAILED` / `FAIL` | Hard error | `BUILD FAILED`, `FAILED: 3 tests` |
| `Exception` / `exception` | Hard error | `NullPointerException`, `KeyError` |
| `Traceback (most recent call last)` | Stack trace | Python exception |
| `at Object.<anonymous>` | Stack trace | Node.js stack trace line |
| `panic:` | Hard error | Go runtime panic |
| `Segmentation fault` | Hard error | C/C++ or native crash |
| `Permission denied` | Access error | File or directory access failure |
| `No such file or directory` | Missing resource | `ENOENT` errors |
| `Connection refused` | Network error | Service not running |
| `Timed out` / `timeout` | Network error | Service unreachable or slow |
| `exit status N` (N > 0) | Non-zero exit | Process returned failure code |

---

## Related References

- `skills/cli-validation/SKILL.md` — CLI validation protocol with output capture commands
- `skills/ai-evidence-analysis/SKILL.md` — Full skill documentation including all three analysis types
- `skills/ai-evidence-analysis/references/confidence-scoring.md` — Scoring rubric and aggregation rules
- `skills/sequential-analysis/SKILL.md` — Root cause analysis for CLI FAILs
