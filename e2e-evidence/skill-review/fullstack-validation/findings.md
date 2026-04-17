# fullstack-validation Skill — Deep Review Findings

**Skill file:** `./skills/fullstack-validation/SKILL.md` (209 lines)
**Reviewer:** auto-claude (phase-2-subtask-5)
**Date:** 2026-04-17

## Summary

Verified all 4 Layers (DB / API / Frontend / Integration), Prerequisites,
Bottom-Up Rule, Common Failures, PASS Criteria, and delegation to
api-validation + web-validation against:

- Sibling skills `api-validation/SKILL.md`, `web-validation/SKILL.md`.
- Orchestrator reference `e2e-validate/references/fullstack-validation.md`.
- Host tools (`psql 18.3`, `sqlite3 3.51.0`, `pg_isready 18.3`; mysql and
  mongosh NOT installed) — `tool-baseline-and-crossref.txt`.
- jq type-detection for Layer-2 cross-ref pattern (`if type == "array"`)
  — `jq-and-psql-verification.txt`.

### Severity roll-up

| Severity | Count |
|----------|-------|
| CRITICAL | 0     |
| HIGH     | 3     |
| MEDIUM   | 7     |
| LOW      | 4     |

**No CRITICAL defects.** HIGH issues: (F1) PASS gates between layers are
prose-only, not mechanical; (F2) Layer 4 Delete Cascade Step 1 is literally
a comment `# (capture the delete action via browser automation)` — the
delete never happens, yet Step 2 and Step 3 report successful cascade;
(F3) Layer 2 "API-to-DB cross-ref" captures API count but never compares
to DB count.

---

## Accuracy Issues

### F1 [HIGH] — "PASS gate: Do not proceed to Layer N+1 until..." is narrative-only

**Location:** SKILL.md lines 72, 98, 116 (three gates).

**Problem:** Each PASS gate is a prose sentence. No bash check, no
exit-on-failure, no evidence-read. A validator running the skill shell-style
proceeds regardless of output. `preflight/SKILL.md` enforces its gates with
exit codes; fullstack-validation does not.

**Impact:** Validator runs Layer 1 with empty `db-tables.txt` (migrations
unset), runs Layer 2 anyway, debugs "API error" when root cause is DB,
exactly the anti-pattern the Bottom-Up Rule (line 27) warns against.

**Suggested fix:** Each gate → mechanical check:
```bash
if [ ! -s e2e-evidence/db-tables.txt ] || grep -qi "error\|does not exist" e2e-evidence/db-tables.txt; then
  echo "FAIL: Layer 1 did not PASS — stopping"; exit 1; fi
```

### F2 [HIGH] — Layer 4 Delete Cascade Step 1 is a comment, not a command

**Location:** SKILL.md lines 171-183.

```bash
### Delete cascade
# 1. Delete via frontend
# (capture the delete action via browser automation)

# 2. Verify API returns 404
curl -s -w "\nHTTP_STATUS:%{http_code}" http://localhost:API_PORT/api/items/DELETED_ID ...

# 3. Verify database row removed
psql $DATABASE_URL -c "SELECT count(*) FROM items WHERE id = 'DELETED_ID'" ...
```

**Problem:** Step 1 is literally a comment. Nothing deletes. Steps 2 and 3
reference the placeholder string `DELETED_ID`:
- Step 2 `curl .../items/DELETED_ID` — hits literal string "DELETED_ID",
  returns 404 because no such resource exists (coincidentally matching
  "Expected: 404"!).
- Step 3 `psql ... WHERE id = 'DELETED_ID'` — returns 0 rows because no
  row was ever created.

**Both checks pass vacuously.** PASS criterion line 208 ("Deletes cascade
correctly") is literally unfalsifiable by the current instructions.

**This is the skill's highest-impact bug.**

**Suggested fix:** Activate Step 1:
```bash
# 0. Create an item to delete
CREATED=$(curl -s -X POST http://localhost:API_PORT/api/items \
  -H 'Content-Type: application/json' -d '{"name":"ToDelete"}' | jq -r '.id')

# 1. Delete via frontend
browser_navigate url="http://localhost:FE_PORT/items/$CREATED"
browser_click ref="DELETE_BUTTON_REF" element="Delete button"
browser_take_screenshot filename="e2e-evidence/integration-frontend-after-delete.png"

# 2. Verify API 404
curl -s -w "\nHTTP_STATUS:%{http_code}" http://localhost:API_PORT/api/items/"$CREATED" \
  | tee e2e-evidence/integration-api-after-delete.txt

# 3. Verify DB row removed
psql $DATABASE_URL -c "SELECT count(*) FROM items WHERE id = '$CREATED'" \
  | tee e2e-evidence/integration-db-after-delete.txt
```

### F3 [HIGH] — "API returns DB data" check captures API count but never compares to DB

**Location:** SKILL.md lines 85-93.

```bash
API_COUNT=$(jq 'if type == "array" then length else .data | length end' ...)
echo "API returned $API_COUNT users" | tee e2e-evidence/api-db-crossref.txt
```

**Problem:** Writes API count to a file. Never reads DB count. Never
asserts equality. An API returning 5 mocked users when DB has 7 real users
is not detected.

Also: the jq expression falls back to `.data` — but many APIs use `.users`,
`.items`, `.results` (verified in `jq-and-psql-verification.txt`). For
object responses without `.data`, jq returns 0 — wrong.

**Suggested fix:**
```bash
DB_COUNT=$(psql $DATABASE_URL -t -c "SELECT count(*) FROM users" | tr -d ' ')
API_COUNT=$(jq '
  if type == "array" then length
  elif .data then .data | length
  elif .users then .users | length
  elif .items then .items | length
  else error("unknown list shape") end' e2e-evidence/api-users-list.json)
echo "DB=$DB_COUNT API=$API_COUNT" | tee e2e-evidence/api-db-crossref.txt
[ "$DB_COUNT" = "$API_COUNT" ] || { echo "FAIL: mismatch"; exit 1; }
```

### F4 [MEDIUM] — `$DATABASE_URL`, `$API_PORT`, `$FE_PORT` used but never defined

Every `psql`, every `curl`. Prerequisites list literal `PORT` — doesn't
address shell-var expansion. Fresh-shell run errors:
```
curl: (3) Port number ended with 'T' (http://localhost:API_PORT/...)
```

**Suggested fix:** Preamble:
```bash
: "${DATABASE_URL:=postgresql://localhost/mydb}"
: "${API_PORT:=3001}"
: "${FE_PORT:=3000}"
```

### F5 [MEDIUM] — Layer 1 MySQL `mysql -u USER -p DB` — password-prompt + literal placeholder

`mysql -p` prompts interactively (breaks CI). Users often inline `-pSECRET`
→ password in shell history + `ps`. `USER`/`DB` are literals.

**Suggested fix:** Use `MYSQL_PWD` env var or `~/.my.cnf`; use shell vars
for user/db.

### F6 [MEDIUM] — Migration status section is entirely commented out

Lines 63-70. All 4 migration-tool commands are `#`-prefixed. No tee, no
execution. But Common Failures row 2 warns about migration drift — the
skill doesn't catch the thing it warns about.

**Suggested fix:** Auto-detect migration tool and run actively:
```bash
if [ -d prisma ]; then npx prisma migrate status 2>&1 | tee e2e-evidence/db-migrations.txt
elif [ -f manage.py ]; then python manage.py showmigrations 2>&1 | tee ...
fi
```

### F7 [MEDIUM] — Flat evidence paths (`db-*`, `api-*`, `web-*`, `integration-*`) violate journey-slug rule

Same class as ios F3 / web F13 / api F4 / cli F6. Thread
JOURNEY=fullstack-validation OR document the per-layer-prefix as a
fullstack exception in CLAUDE.md.

### F8 [MEDIUM] — Layer 2/3 delegation is a sentence, not a mechanical call

Line 76: "Follow the full `api-validation` skill procedure" — prose.
Line 102: "Follow the full `web-validation` skill procedure" — prose.

Validators running the inline 3 curl calls in Layer 2 (lines 79-97) stop
there instead of running all 6 steps of api-validation. Half the fullstack
validation is shortcircuited.

**Suggested fix:** Replace delegation sentence with explicit step
checklist referencing the 6 (api) or 8 (web) Steps with line numbers.

### F9 [MEDIUM] — No "When to Use" or "Related Skills" section

Inbound references: functional-validation, e2e-validate, + orchestrator
mirror. No outbound links.

**Suggested fix:** Add Related-Skills block citing api-validation,
web-validation, e2e-validate, functional-validation,
no-mocking-validation-gates, gate-validation-discipline, parallel-validation.

### F10 [MEDIUM] — DB-to-Frontend Read Path doesn't grep-check propagation

Lines 139-154. Inserts row in DB; curls API; screenshots UI. Captures 3
files but never greps for the inserted name. Same "narrative only" pattern
as F1 but for integration.

**Suggested fix:** After each capture, `grep -q "DB Direct Insert" FILE
|| { echo FAIL; exit 1; }`.

### F11 [LOW] — Placeholder convention inconsistent

Mixes UPPERCASE-WORD (`USER`, `DB`, `PORT`, `ID`, `DELETED_ID`) with
shell-style (`$DATABASE_URL`, `$RESOURCE_ID`). Pick one:
`$VARIABLE_NAME` for exports, `<PLACEHOLDER>` for literals.

### F12 [LOW] — No Redis / message queue / blob store layer

Modern fullstack apps have Layer 0.5 infrastructure (Redis, BullMQ/SQS,
S3/R2). Skill treats Layer 1 as RDBMS-only. Add a Layer 0.5 section.

### F13 [LOW] — MySQL `-p` breaks `/validate-ci`

See F5; CI mode impact separate note.

### F14 [LOW] — Integration path naming varies from reference (`integration-*` vs `j{N}-integration-*`)

Same class as F7.

---

## Stale References / Missing Content / Broken Cross-Links

- All outbound (`api-validation`, `web-validation`) resolve.
- Inbound: functional-validation, e2e-validate, e2e-validate reference —
  all resolve.
- Missing: When-to-Use (F9), Related-Skills (F9), mechanical PASS gates
  (F1), delete-action code (F2), active migration check (F6), Redis/queue
  layer (F12), evidence-inventory generator.
- No broken cross-links.

---

## Recommendations (priority-ordered)

1. **[HIGH] Activate Delete Cascade Step 1 (F2) — this is the single
   highest-impact fix: false PASS otherwise.**
2. **[HIGH] Mechanize PASS gates (F1).**
3. **[HIGH] Compare DB vs API count (F3).**
4. **[MEDIUM] Define `$DATABASE_URL`, `$API_PORT`, `$FE_PORT` in
   prerequisites (F4).**
5. **[MEDIUM] Sanitize MySQL password handling (F5).**
6. **[MEDIUM] Activate migration-status check (F6).**
7. **[MEDIUM] Journey-slug evidence paths (F7).**
8. **[MEDIUM] Explicit Layer-2/3 delegation (F8).**
9. **[MEDIUM] When-to-Use + Related-Skills (F9).**
10. **[MEDIUM] Grep-check integration propagation (F10).**
11. **[LOW] Placeholder convention (F11); Layer 0.5 infra (F12); MySQL
    non-interactive (F13); integration naming (F14).**

**None CRITICAL.** Highest-impact: F2 (delete cascade doesn't delete,
claims PASS) and F1 (gate discipline is aspirational).

---

## Evidence

- `tool-baseline-and-crossref.txt` — psql/sqlite3 installed, mysql/mongosh
  not; inbound/outbound cross-ref inventory.
- `jq-and-psql-verification.txt` — jq type-detection on array / object /
  missing-.data; `psql -h localhost` flag syntax verified.

Iron Rule preserved. No mocks/stubs/test-files created.
