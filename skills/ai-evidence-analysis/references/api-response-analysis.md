# API Response Analysis Reference

LLM prompt templates, output schema definitions, and example analysis output for
AI-powered API response evidence analysis.

## Overview

API response evidence (`.json` files captured by `api-validation`) is analyzed using
an LLM that evaluates the response body and metadata against four quality dimensions:

1. **Schema compliance** — Do fields match the expected structure and types?
2. **Error handling** — Are error responses correctly structured with codes and messages?
3. **Edge case coverage** — Does the response handle nulls, empty arrays, and boundary values correctly?
4. **Response integrity** — Are required fields present, non-null, and semantically valid?

Every analysis produces a structured `ApiResponseAnalysisResult` with a `confidence`
score (0–100) and specific `findings` organized by analysis category.

---

## LLM Prompt Template

Use this exact prompt structure when submitting an API response file to the LLM.
Replace `{journey_name}`, `{endpoint}`, `{http_method}`, `{expected_status}`, and
`{expected_schema}` with values from the active validation plan.

```
You are an API validation expert analyzing a captured API response as validation evidence.

Journey: {journey_name}
Endpoint: {http_method} {endpoint}
Expected HTTP status: {expected_status}
Expected schema: {expected_schema}

Below is the captured API response (body and headers where available):

---RESPONSE START---
{response_content}
---RESPONSE END---

Analyze this API response across four dimensions:

### 1. Schema Compliance
Compare the response body against the expected schema:
- Are all required fields present? (not missing, not null unless nullable)
- Do field types match expectations? (string vs number vs boolean vs array vs object)
- Do field formats match? (ISO 8601 dates, email format, UUID format, etc.)
- Are any unexpected extra fields present that should not be in the response?
- Are array fields populated correctly (not accidentally empty, correct item structure)?

### 2. Error Handling Detection
Assess whether this response represents correct error handling behavior:
- If the expected status is an error (4xx or 5xx): does the body include a machine-readable
  error code AND a human-readable message?
- If the expected status is success (2xx): are there any embedded error objects, null
  required fields, or partial failure indicators present?
- Is the Content-Type header appropriate (application/json for JSON responses)?
- Does the response avoid leaking sensitive internals (stack traces, SQL errors, internal paths)?

### 3. Edge Case Coverage
Identify potential edge case issues:
- Are nullable fields explicitly `null` vs absent (these have different semantics)?
- Are numeric values within expected ranges (no negative IDs, no future timestamps on created_at)?
- Are string values unexpectedly empty ("") where a value was expected?
- Are pagination fields present and coherent (total >= items returned, cursor values not null)?
- Are relational fields (foreign keys, nested objects) populated and not zero/empty?

### 4. Confidence Assessment
Based on dimensions 1–3, assign a confidence score (0–100):
- 90–100: Response fully matches schema, error handling is correct, no edge case issues
- 70–89: Response mostly matches; minor schema drift or low-severity edge case found
- 50–69: Response has notable issues — missing fields, wrong types, or error structure problems
- 30–49: Response has significant problems — multiple missing required fields or wrong status
- 0–29:  Response clearly failed — wrong status, missing body, or server error returned

Respond ONLY with a JSON object matching the ApiResponseAnalysisResult schema below.
Do not include markdown fences or explanatory text outside the JSON.
```

---

## Output Schema

### `ApiResponseAnalysisResult`

```json
{
  "evidence_file": "e2e-evidence/journey-slug/step-04-create-user-response.json",
  "evidence_type": "api-response",
  "confidence": 88,
  "verdict_label": "PASS",
  "schema_compliance": {
    "compliant": true,
    "required_fields_present": ["id", "email", "created_at", "role"],
    "missing_fields": [],
    "type_mismatches": [],
    "unexpected_fields": ["legacy_token"],
    "notes": "All required fields present. One unexpected deprecated field detected."
  },
  "error_handling": {
    "status_code_correct": true,
    "expected_status": 201,
    "actual_status": 201,
    "error_structure_valid": null,
    "sensitive_data_leaked": false,
    "notes": "Success response; error structure check not applicable."
  },
  "edge_cases": [
    {
      "field": "legacy_token",
      "issue": "Deprecated field present in response; clients may rely on it unexpectedly",
      "severity": "LOW"
    }
  ],
  "findings": [
    {
      "severity": "LOW",
      "finding": "Response includes deprecated field `legacy_token` not in current schema",
      "recommendation": "Remove `legacy_token` from response serializer; add deprecation header if removal is staged"
    }
  ],
  "summary": "User creation response matches current schema with all required fields present and correct types. HTTP 201 returned as expected. One deprecated field `legacy_token` detected in response body.",
  "analyzed_at": "2025-01-15T14:32:00Z"
}
```

### Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `evidence_file` | string | yes | Relative path to the API response evidence file |
| `evidence_type` | `"api-response"` | yes | Always `"api-response"` for this analysis type |
| `confidence` | integer 0–100 | yes | Overall confidence that the response supports a PASS verdict |
| `verdict_label` | `"PASS"` \| `"WARN"` \| `"FAIL"` | yes | Recommended verdict derived from confidence and findings |
| `schema_compliance` | SchemaComplianceResult | yes | Field-by-field schema validation results |
| `error_handling` | ErrorHandlingResult | yes | Error structure and status code correctness assessment |
| `edge_cases` | EdgeCaseIssue[] | yes | Edge case anomalies detected (empty array if none) |
| `findings` | Finding[] | yes | Consolidated finding list across all categories |
| `summary` | string | yes | 1–3 sentence human-readable synthesis of the analysis |
| `analyzed_at` | ISO 8601 string | yes | Timestamp of when analysis was performed |

### `SchemaComplianceResult` Schema

```json
{
  "compliant": false,
  "required_fields_present": ["id", "email"],
  "missing_fields": ["created_at", "role"],
  "type_mismatches": [
    {
      "field": "id",
      "expected_type": "string (UUID)",
      "actual_value": "42",
      "notes": "Integer ID returned; schema expects UUID string"
    }
  ],
  "unexpected_fields": [],
  "notes": "Two required fields missing; one type mismatch on `id`"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `compliant` | boolean | `true` if response passes all schema checks; `false` if any required field is missing or mistyped |
| `required_fields_present` | string[] | Names of required fields that are present and correctly typed |
| `missing_fields` | string[] | Names of required fields that are absent or null |
| `type_mismatches` | TypeMismatch[] | Fields where the actual type or format differs from expected |
| `unexpected_fields` | string[] | Field names present in the response but not in the expected schema |
| `notes` | string | Free-text summary of schema compliance assessment |

### `TypeMismatch` Schema

```json
{
  "field": "created_at",
  "expected_type": "ISO 8601 datetime string",
  "actual_value": "1705329120",
  "notes": "Unix timestamp (integer) returned instead of ISO 8601 string"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `field` | string | Dot-notation path to the mismatched field (e.g. `"user.created_at"`) |
| `expected_type` | string | Human-readable description of the expected type or format |
| `actual_value` | string | The actual value or type observed (quoted for clarity) |
| `notes` | string | Additional context about the mismatch |

### `ErrorHandlingResult` Schema

```json
{
  "status_code_correct": false,
  "expected_status": 400,
  "actual_status": 500,
  "error_structure_valid": false,
  "error_code_present": false,
  "error_message_present": true,
  "sensitive_data_leaked": true,
  "notes": "Server returned 500 with stack trace instead of 400 with validation message"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `status_code_correct` | boolean | `true` if actual HTTP status matches expected status |
| `expected_status` | integer | The HTTP status code expected per the validation plan |
| `actual_status` | integer | The HTTP status code actually present in the evidence |
| `error_structure_valid` | boolean \| null | `true` if error body has both `code` and `message`; `null` if not an error response |
| `error_code_present` | boolean \| null | `true` if a machine-readable error code field is in the body; `null` if not applicable |
| `error_message_present` | boolean \| null | `true` if a human-readable error message is in the body; `null` if not applicable |
| `sensitive_data_leaked` | boolean | `true` if stack traces, SQL, internal paths, or secrets are visible in the response |
| `notes` | string | Free-text description of the error handling assessment |

### `EdgeCaseIssue` Schema

```json
{
  "field": "results",
  "issue": "Empty array returned; no items in response despite non-zero total count",
  "severity": "HIGH"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `field` | string | The field or response area where the edge case was detected |
| `issue` | string | Description of the edge case anomaly |
| `severity` | `"CRITICAL"` \| `"HIGH"` \| `"MEDIUM"` \| `"LOW"` | Impact level of the edge case |

### `Finding` Schema

```json
{
  "severity": "HIGH",
  "finding": "Required field `user_id` is null in 201 Created response",
  "recommendation": "Investigate user creation handler; ensure `user_id` is set before serialization"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `severity` | `"CRITICAL"` \| `"HIGH"` \| `"MEDIUM"` \| `"LOW"` | Impact level of the finding |
| `finding` | string | Specific factual observation — describe what IS in the response, not what should be |
| `recommendation` | string | Actionable next step to investigate or remediate |

### Severity Definitions

| Severity | Definition | API Response Examples |
|----------|-----------|----------------------|
| `CRITICAL` | API is broken or returns data that would cause client failure | Wrong status (500 vs 200), missing required ID field, auth token absent from login response |
| `HIGH` | Major data integrity issue; client behavior would be incorrect | Required field null, type mismatch on primary key, error response missing message |
| `MEDIUM` | Noticeable data quality issue; may cause subtle bugs | Deprecated field present, optional field wrong format, pagination total inconsistent |
| `LOW` | Minor issue; unlikely to affect client behavior | Unexpected extra field, trivially wrong timestamp precision |

### Verdict Label Rules

Derived automatically from `confidence` and `findings`:

| Condition | Verdict |
|-----------|---------|
| `confidence >= 70` AND no CRITICAL findings | `PASS` |
| `confidence >= 50` AND no CRITICAL findings AND MEDIUM or HIGH findings present | `WARN` |
| `confidence < 50` OR any CRITICAL finding | `FAIL` |

---

## Example Analysis Output

### Example 1: Full PASS — User Creation Response Correct

**Evidence file:** `e2e-evidence/user-management-journey/step-03-create-user.json`
**Journey:** User Management — Create User
**Endpoint:** `POST /api/users`
**Expected status:** `201`
**Expected schema:** `{ id: UUID, email: string, role: string, created_at: ISO8601 }`

```json
{
  "evidence_file": "e2e-evidence/user-management-journey/step-03-create-user.json",
  "evidence_type": "api-response",
  "confidence": 97,
  "verdict_label": "PASS",
  "schema_compliance": {
    "compliant": true,
    "required_fields_present": ["id", "email", "role", "created_at"],
    "missing_fields": [],
    "type_mismatches": [],
    "unexpected_fields": [],
    "notes": "All four required fields present with correct types. UUID format confirmed on id field."
  },
  "error_handling": {
    "status_code_correct": true,
    "expected_status": 201,
    "actual_status": 201,
    "error_structure_valid": null,
    "error_code_present": null,
    "error_message_present": null,
    "sensitive_data_leaked": false,
    "notes": "Success response as expected. No error handling checks applicable."
  },
  "edge_cases": [],
  "findings": [],
  "summary": "User creation response is fully compliant. HTTP 201 returned with all required fields (id, email, role, created_at) present and correctly typed. No schema drift, no edge case issues.",
  "analyzed_at": "2025-01-15T14:32:00Z"
}
```

---

### Example 2: WARN — Login Response Has Deprecated Field

**Evidence file:** `e2e-evidence/auth-journey/step-02-login.json`
**Journey:** User Authentication — Login
**Endpoint:** `POST /auth/login`
**Expected status:** `200`
**Expected schema:** `{ access_token: string, token_type: "Bearer", expires_in: integer, user: { id, email } }`

```json
{
  "evidence_file": "e2e-evidence/auth-journey/step-02-login.json",
  "evidence_type": "api-response",
  "confidence": 78,
  "verdict_label": "WARN",
  "schema_compliance": {
    "compliant": true,
    "required_fields_present": ["access_token", "token_type", "expires_in", "user"],
    "missing_fields": [],
    "type_mismatches": [],
    "unexpected_fields": ["legacy_token", "jwt"],
    "notes": "All required fields present. Two unexpected fields detected: `legacy_token` and `jwt`. These duplicate `access_token` and may confuse clients."
  },
  "error_handling": {
    "status_code_correct": true,
    "expected_status": 200,
    "actual_status": 200,
    "error_structure_valid": null,
    "error_code_present": null,
    "error_message_present": null,
    "sensitive_data_leaked": false,
    "notes": "Success response. No sensitive internals detected."
  },
  "edge_cases": [
    {
      "field": "expires_in",
      "issue": "Value is 0; token would be immediately expired on receipt",
      "severity": "HIGH"
    }
  ],
  "findings": [
    {
      "severity": "HIGH",
      "finding": "`expires_in` is 0; token is already expired on receipt by client",
      "recommendation": "Investigate token generation; ensure expiry calculation uses future timestamp. Check for timezone offset bug."
    },
    {
      "severity": "MEDIUM",
      "finding": "Unexpected fields `legacy_token` and `jwt` present alongside `access_token`",
      "recommendation": "Remove deprecated token fields from response serializer to avoid client confusion"
    }
  ],
  "summary": "Login response contains all required fields and returns HTTP 200. However, `expires_in` is 0 (token immediately expired) and two deprecated token fields are present. The expired token issue requires investigation before this journey can pass.",
  "analyzed_at": "2025-01-15T14:35:22Z"
}
```

---

### Example 3: FAIL — Validation Error Response Leaks Stack Trace

**Evidence file:** `e2e-evidence/user-management-journey/step-06-create-user-bad-email.json`
**Journey:** User Management — Input Validation
**Endpoint:** `POST /api/users`
**Expected status:** `422`
**Expected schema:** `{ error: { code: string, message: string, fields: [{ field, message }] } }`

```json
{
  "evidence_file": "e2e-evidence/user-management-journey/step-06-create-user-bad-email.json",
  "evidence_type": "api-response",
  "confidence": 12,
  "verdict_label": "FAIL",
  "schema_compliance": {
    "compliant": false,
    "required_fields_present": [],
    "missing_fields": ["error.code", "error.message", "error.fields"],
    "type_mismatches": [],
    "unexpected_fields": ["stack", "trace", "query"],
    "notes": "Expected 422 validation error structure not present. Response contains raw server internals instead."
  },
  "error_handling": {
    "status_code_correct": false,
    "expected_status": 422,
    "actual_status": 500,
    "error_structure_valid": false,
    "error_code_present": false,
    "error_message_present": true,
    "sensitive_data_leaked": true,
    "notes": "500 returned instead of 422. Response body contains Node.js stack trace and raw SQL query — sensitive internal data leaked."
  },
  "edge_cases": [],
  "findings": [
    {
      "severity": "CRITICAL",
      "finding": "HTTP 500 returned instead of expected 422; input validation error not caught by error handler",
      "recommendation": "Add input validation middleware before controller logic; ensure validation errors are caught and returned as 422, not propagated as unhandled exceptions"
    },
    {
      "severity": "CRITICAL",
      "finding": "Response body contains Node.js stack trace and raw SQL query — internal server details leaked to client",
      "recommendation": "Disable stack trace exposure in production error handler; never include `stack`, `trace`, or `query` fields in API error responses"
    }
  ],
  "summary": "Input validation error response is critically broken. HTTP 500 returned instead of 422. Response body exposes Node.js stack trace and raw SQL query. This is a FAIL — both incorrect error handling and sensitive data leakage detected.",
  "analyzed_at": "2025-01-15T14:38:47Z"
}
```

---

## Usage Notes

### Providing the Expected Schema

The `{expected_schema}` placeholder should be populated from the validation plan's
journey definition. Use concise notation that describes field names and types:

```
Good: "{ id: UUID string, email: string, role: 'admin'|'user', created_at: ISO8601 }"
Good: "array of { id, name, price: number, in_stock: boolean }"
Avoid: Pasting full TypeScript type definitions or OpenAPI YAML — keep it readable
```

If no expected schema is available, use `"unknown — infer from response structure"` and
the LLM will perform a best-effort structural analysis.

### Handling Responses Without HTTP Status in the File

Some evidence files contain only the response body (curl without `-w "%{http_code}"`).
When HTTP status is not available in the evidence file:

1. Set `error_handling.actual_status` to `null`
2. Set `error_handling.status_code_correct` to `null`
3. Add a MEDIUM finding: `"HTTP status code not captured in evidence file; analysis limited to body"`
4. Reduce confidence by 10–15 points

Always capture status codes in evidence files using:

```bash
curl -s -w "\nHTTP_STATUS:%{http_code}" ... | tee evidence-file.txt
```

### Detecting Sensitive Data Leakage

Set `error_handling.sensitive_data_leaked: true` if ANY of the following are visible
in the response body:

- Stack traces (e.g. `at Object.<anonymous>`, `Traceback (most recent call last)`)
- Raw SQL queries (`SELECT`, `INSERT`, `FROM` in error messages)
- Internal file system paths (`/var/app/`, `/home/deploy/`, `C:\inetpub\`)
- Private environment variable names or values
- Internal service hostnames or IP addresses
- Authentication secrets, API keys, or token values

Sensitive data leakage is always a **CRITICAL** finding that forces `verdict_label: "FAIL"`.

### Schema Compliance vs. Strict Contract Validation

This analysis performs **heuristic schema compliance** — it checks for likely issues
rather than strict OpenAPI contract validation. For strict contract validation, use
`api-validation` skill with an explicit schema file.

Heuristic analysis is sufficient for:
- Catching missing required fields
- Detecting obvious type mismatches
- Identifying unexpected extra fields
- Flagging empty arrays or null required values

It is **not** a substitute for:
- Full OpenAPI/JSON Schema validation
- Exhaustive enum value checking
- Nested schema validation across all response paths

### Sidecar File Naming

Analysis results are saved as sidecar files alongside the original response:

```
e2e-evidence/journey-slug/step-04-login-response.json                ← original evidence
e2e-evidence/journey-slug/ai-analysis-step-04-login-response.json   ← this analysis result
```

The `verdict-writer` agent reads `ai-analysis-*.json` sidecar files when present to
incorporate AI findings into its PASS/FAIL verdict reasoning.

### Zero-Byte or Malformed Evidence Files

API response files that are 0 bytes or contain invalid JSON are **invalid evidence**.
Do not attempt to analyze them. Instead, flag immediately:

```json
{
  "evidence_file": "e2e-evidence/journey-slug/step-04-response.json",
  "evidence_type": "api-response",
  "confidence": 0,
  "verdict_label": "FAIL",
  "schema_compliance": {
    "compliant": false,
    "required_fields_present": [],
    "missing_fields": [],
    "type_mismatches": [],
    "unexpected_fields": [],
    "notes": "File is 0 bytes or invalid JSON — cannot analyze"
  },
  "error_handling": {
    "status_code_correct": null,
    "expected_status": null,
    "actual_status": null,
    "error_structure_valid": null,
    "error_code_present": null,
    "error_message_present": null,
    "sensitive_data_leaked": false,
    "notes": "Cannot assess — invalid evidence file"
  },
  "edge_cases": [],
  "findings": [
    {
      "severity": "CRITICAL",
      "finding": "Evidence file is empty or not valid JSON; no response content to analyze",
      "recommendation": "Re-capture API response using curl with full body capture; verify the endpoint returned a body"
    }
  ],
  "summary": "Invalid evidence: API response file is empty or malformed. This evidence cannot support any verdict.",
  "analyzed_at": "2025-01-15T14:42:00Z"
}
```

---

## Related References

- `skills/api-validation/SKILL.md` — API validation protocol using curl with full evidence capture
- `skills/ai-evidence-analysis/SKILL.md` — Full skill documentation including all three analysis types
- `skills/ai-evidence-analysis/references/confidence-scoring.md` — Scoring rubric and aggregation rules
- `skills/sequential-analysis/SKILL.md` — Root cause analysis for API FAILs
