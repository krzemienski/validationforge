---
skill: api-validation
reviewer: R1
date: 2026-04-16
verdict: PASS
---

# api-validation review

## Frontmatter check
- name: `api-validation`
- description: `"Validate APIs via curl: health checks, CRUD cycles (create/read/update/delete), auth (token, 401/403), error responses, pagination. Captures JSON bodies and status codes. Use on API changes."` (200 chars)
- description_well_formed: yes
- yaml_parses: yes

## Trigger realism
Would invoke on: `"api testing"`, `"curl validation"`, `"api contract"`, `"endpoint verification"`.
Realism score: 5/5. Triggers are API-specific and realistic. User would naturally phrase requests this way.

## Body-description alignment
PASS. Body delivers on all promised features:
- Health checks (Step 1) ✓
- CRUD cycles (Step 2: create, read, update, delete) ✓
- Auth validation (Step 3: token, 401, 403) ✓
- Error responses (Step 4: 400, 404, 422) ✓
- Pagination (Step 5) ✓
- Captures JSON bodies and status codes ✓

PASS Criteria template at end provides concrete verdicts. Common failures table aids debugging.

## MCP tool existence
- `curl` — shell command (always available)
- `jq` — shell command (always available)

No external MCP servers. Pure shell-based validation.

## Example invocation proof
User: `"Validate the API CRUD cycle for users endpoint"`
Would execute Steps 1-6 per documented protocol, capturing evidence to e2e-evidence/.

## Verdict
**PASS**

Clear, actionable skill with complete CRUD protocol. Shell-based approach ensures availability. PASS Criteria template is concrete. Evidence capture patterns are explicit.
