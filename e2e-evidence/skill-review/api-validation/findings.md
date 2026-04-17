# api-validation Skill — Deep Review Findings

**Skill file:** `./skills/api-validation/SKILL.md` (223 lines, single-file skill — no `references/` or `workflows/` directory)
**Reviewer:** auto-claude (phase-2-subtask-3)
**Date:** 2026-04-17

## Summary

Verified all 6 Steps (Health / CRUD / Auth / Error / Pagination / Rate limit),
Prerequisites table, Evidence Standards, Common Failures table, and PASS
Criteria Template against curl 8.7.1 + jq 1.8.1 on this machine, sibling
reference `./skills/e2e-validate/references/api-validation.md`, and inbound
cross-references from fullstack-validation, parallel-validation,
functional-validation, research-validation, e2e-validate.

Evidence: `command-verification-transcript.txt`, `crossref-check.txt`.

### Severity roll-up

| Severity | Count |
|----------|-------|
| CRITICAL | 0     |
| HIGH     | 3     |
| MEDIUM   | 7     |
| LOW      | 4     |

**No CRITICAL defects.** HIGH issues: (F1) Step 2 CRUD uses `$TOKEN` that's
only created in Step 3 — ordering bug; (F2) Delete verification narrates
"Expected: 404" but has no mechanical assertion; (F3) Create curl omits
`-w "%{http_code}"` despite PASS criterion requiring 201.

---

## Accuracy Issues

### F1 [HIGH] — `$TOKEN` used in Step 2 CRUD but only created in Step 3

**Location:** SKILL.md lines 36-89 (Step 2 — every curl sends
`-H "Authorization: Bearer $TOKEN"`) vs. lines 96-102 (Step 3 — where
`$TOKEN` is first set via login).

**Problem:** Steps run 1 → 2 → 3. Running Step 2 literally against a fresh
shell has `$TOKEN` unset; every CRUD call sends `Authorization: Bearer `
(empty value) and 401s against any authenticated API. curl ships the empty
header without complaint (verified in `command-verification-transcript.txt`).

**Impact:** First-pass failure; validator must reorder or patch. For public
APIs the header is ignored and the issue is silent — misleading.

**Suggested fix:** Reorder Step 3 before Step 2, OR add a Step-2 prelude
stating `$TOKEN` is a prerequisite (with a reference to Step 3's login
call), OR make public-API `$TOKEN=""` an explicit option.

### F2 [HIGH] — Delete verification narrates "Expected: 404" but never asserts it

**Location:** SKILL.md lines 85-91.

```bash
curl -s -w "\nHTTP_STATUS:%{http_code}" http://localhost:PORT/api/RESOURCE/$RESOURCE_ID \
  -H "Authorization: Bearer $TOKEN" \
  | tee e2e-evidence/api-read-after-delete-RESOURCE.txt
Expected: 404 response.
```

**Problem:** "Expected: 404" is prose; tee writes the body, but no grep or
exit-check verifies 404. Common Failures row 4 (line 207) warns about "CRUD
read-after-delete returns 200 — soft delete not filtering correctly" — the
exact failure the Step cannot detect.

**Impact:** False PASS on deletion when soft-delete filter is broken. PASS
criterion line 217 ("subsequent read returns 404") unfalsifiable.

**Suggested fix:**
```bash
grep -q "HTTP_STATUS:404" e2e-evidence/api-read-after-delete-RESOURCE.txt \
  || { echo "FAIL: resource still readable after DELETE" >> e2e-evidence/api-read-after-delete-RESOURCE.txt; exit 1; }
```
Apply the same pattern to every Step-4 "Expected: 400/404/422" block.

### F3 [HIGH] — Create curl omits `-w "%{http_code}"`; PASS criterion demands 201

**Location:** SKILL.md lines 34-45; PASS criterion line 214.

**Problem:** PASS criterion requires Create → 201. The curl invocation has
no `-w` flag so status is discarded; tee writes only body. Then
`RESOURCE_ID=$(jq -r '.id // .data.id' ...)` can pull `null` or an ID
from an error body, silently masking a 500. Only Create/Read-single/Read-list/
Update omit `-w` — auth/delete/error cases all use it. Inconsistent.

**Impact:** "Create returns 201" cannot be mechanically verified.

**Suggested fix:** Add `-w "\nHTTP_STATUS:%{http_code}\n"` to every Step-2
curl; switch tee target to `.txt` or use a helper that captures body+status
separately and pre-filters before jq.

### F4 [MEDIUM] — Evidence-path convention `api-<action>-RESOURCE.json` violates journey-slug rule

**Location:** Every evidence path in SKILL.md. Same class as ios F3 /
web F13 / cli F6 / fullstack F7. Orchestrator reference uses
`j{N}-*.json`; CLAUDE.md mandates nested `{journey-slug}/step-NN-*.{ext}`.
Multi-validator runs collide at flat root of `e2e-evidence/`.

**Suggested fix:** `JOURNEY=api-validation` at top; rewrite all paths.

### F5 [MEDIUM] — `jq -r '.id // .data.id'` defaults to literal `"null"` on error bodies

**Location:** SKILL.md line 43.

**Problem:** jq `//` is false/null-coalescing but prints literal `null`
(4 chars) when both branches are null. `{"error":"bad"}` yields
`$RESOURCE_ID="null"`. Subsequent curl hits `/api/RESOURCE/null` — may 404
coincidentally, masking that Create failed.

**Empirical evidence** (`command-verification-transcript.txt`): confirmed
both `{"id":"abc"}` → `abc` and `{"error":"bad"}` → `null`.

**Suggested fix:**
```bash
RESOURCE_ID=$(jq -r '.id // .data.id // ""' ...)
if [ -z "$RESOURCE_ID" ] || [ "$RESOURCE_ID" = "null" ]; then
  echo "FAIL: Create did not return usable ID"; exit 1; fi
```

### F6 [MEDIUM] — No "When to Use" or "Related Skills" section

Skill is INBOUND-heavy (5 skills cite it — `crossref-check.txt`) but has
no outbound links. Same gap as every other platform skill.

**Suggested fix:** Append When-to-Use list + Related-Skills block
(fullstack-validation, e2e-validate, parallel-validation,
research-validation, gate-validation-discipline, no-mocking-validation-gates,
verification-before-completion).

### F7 [MEDIUM] — Step 6 rate-limit loop fires only 20 requests; has no threshold check

**Location:** SKILL.md lines 183-190. 20 requests finds neither a 100/minute
Shopify-style nor 1000/hour GitHub-style threshold. Loop doesn't capture
`Retry-After` header (no `-D -`). PASS on dev envs that disable rate limit.

**Suggested fix:** Document required configuration; add post-loop grep for
429 + header capture; warn on 20 consecutive 200s as "threshold may be > 20".

### F8 [MEDIUM] — Pagination `limit=2&offset=2` brittle on small datasets and non-offset APIs

**Location:** SKILL.md lines 163-180. Empty/tiny seed data passes without
proving anything. Offset-pagination assumption excludes GitHub
(page/per_page), Stripe (cursor), Elasticsearch (from/size), Relay
(after/first).

**Suggested fix:** Require seeded dataset ≥ 2 × limit; document 3 common
schemes; `diff` page1 vs page2 and require non-empty diff.

### F9 [MEDIUM] — PASS Criterion "Response times under 500ms" unverified

**Location:** SKILL.md line 222. No step uses `-w "%{time_total}"`. Same as
web F15. Validator marks PASS without evidence or skips.

**Suggested fix:** Drop the bullet, or add `-w "\nTIME:%{time_total}s"` to
every Step-2 curl + awk post-process.

### F10 [MEDIUM] — Prerequisites "Evidence directory exists" uses `mkdir -p` as verification

Same nit as web F11 / ios F11 / cli F12. Side effect, not check.
**Suggested fix:** `test -d e2e-evidence || mkdir -p e2e-evidence`.

### F11 [LOW] — `PORT` literal placeholder

Same as e2e-validate F14, web F6. Literal `curl http://localhost:PORT/...`
fails with "curl: (3) Port number ended with 'O'". Use `${PORT}` with
`PORT="${PORT:-3000}"` preamble.

### F12 [LOW] — Content-Type application consistency

Step 2 correctly omits Content-Type on GETs and includes on POST/PATCH.
No finding; recorded for orthogonality with e2e-validate ref.

### F13 [LOW] — Auth tests don't capture response headers

`WWW-Authenticate: Bearer error="invalid_token"` is informative for debugging
but the skill captures only body/status. Add `-D -` or `-i` for auth errors.

### F14 [LOW] — Common Failures row 5 "Auth token not returned" has vague fix

"Check auth service and token signing" doesn't narrow problem. Suggest more
actionable: "Check /auth/login route; verify JWT_SECRET env var; inspect
response for `token` or `access_token` field".

### F15 [LOW] — Inbound references all resolve

Verified (`crossref-check.txt`): 5 inbound references all point to existing
files. No broken links.

### F16 [MEDIUM] — Auth coverage is Bearer-only; misses API-key and cookie auth

**Location:** Step 3 covers only Bearer. Subtask brief asked for
"bearer/API-key/cookie cases".

**Suggested fix:** Add sub-sections for:
- API key: `-H "X-API-Key: $API_KEY"`
- Cookie: `-c cookies.txt` for login, `-b cookies.txt` for protected.

---

## Stale References / Missing Content / Broken Cross-Links

- Inbound refs all resolve (F15).
- Missing: When-to-Use (F6), Related-Skills (F6), Evidence-Inventory
  (same gap as web F18), GraphQL section despite YAML "REST/GraphQL" claim,
  API-key and cookie auth (F16).
- No broken cross-links.

---

## Recommendations (priority-ordered)

1. **[HIGH] Reorder Steps 2/3 or prereq `$TOKEN` (F1).**
2. **[HIGH] Wire assertion into delete-verify + error blocks (F2).**
3. **[HIGH] Capture `-w %{http_code}` on every CRUD curl (F3).**
4. **[MEDIUM] Journey-slug evidence paths (F4).**
5. **[MEDIUM] Guard `RESOURCE_ID=null` (F5).**
6. **[MEDIUM] Add When-to-Use + Related-Skills (F6).**
7. **[MEDIUM] Threshold-aware rate limit (F7).**
8. **[MEDIUM] Pagination schemes (F8).**
9. **[MEDIUM] Response-time measurement (F9).**
10. **[MEDIUM] API-key + cookie auth (F16).**
11. **[LOW] mkdir verification (F10); PORT literal (F11); auth header capture (F13); fix vagueness (F14).**

**None CRITICAL.** Highest-impact cluster: F1 + F3 + F2 — skill's step
order doesn't compose and its PASS criteria are narrative-only.

---

## Evidence

- `command-verification-transcript.txt` — curl/jq versions; every jq
  filter from the skill tested; curl `-X DELETE`/`-w` syntax verified.
- `crossref-check.txt` — 5 inbound references inventoried.

Iron Rule preserved. No mocks/stubs/test-files created.
