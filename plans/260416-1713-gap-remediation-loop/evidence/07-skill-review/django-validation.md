---
name: django-validation
skill_name: django-validation
review_date: 2026-04-16
reviewer: P07-R2
---

## Frontmatter Check

| Field | Status | Notes |
|-------|--------|-------|
| name | ✅ PASS | "django-validation" |
| description | ✅ PASS | 249 chars; accurate summary of Django/Flask validation flow |
| triggers | ✅ PASS | 5 trigger phrases; all realistic ("django framework testing", "flask validation") |
| context_priority | ✅ PASS | "standard" — appropriate for platform-specific skill |
| YAML parses | ✅ PASS | Valid YAML frontmatter |

## Trigger Realism

| Phrase | Realism | Note |
|--------|---------|-------|
| "django framework testing" | 5/5 | Exact user language for Django validation |
| "flask validation" | 5/5 | Direct Flask synonym |
| "django server check" | 4/5 | Good; slightly less common than "testing" |
| "migration validation" | 4/5 | Specific to data layer; valid use case |
| "django endpoint testing" | 5/5 | Common phrase |

## Body-Description Alignment

**Description claims:**
> Django/Flask validation: dependencies → system check → migrations → server startup → health/CRUD endpoints → auth flows → admin check. Uses curl, captures HTTP/migrations/logs.

**Body delivers:**
- ✅ Dependencies installation (Step 1: `pip install -r requirements.txt`)
- ✅ System check (Step 2: `python manage.py check`)
- ✅ Migrations (Step 3: `showmigrations`, `migrate`)
- ✅ Server startup (Step 4: `runserver` / `flask run` / Gunicorn)
- ✅ Health/CRUD endpoints (Step 5-6: curl GET list, POST create, GET detail, PUT update, DELETE)
- ✅ Auth flows (Step 7: token auth, JWT, unauthenticated checks)
- ✅ Admin check (Step 8: `/admin/` reachability)
- ✅ Evidence capture: logs, JSON responses, HTTP status
- ✅ curl-based testing throughout

**Verdict:** ✅ **PASS** — Body comprehensively delivers on description.

## MCP Tool References

| Tool | Mentioned | Confirmed |
|------|-----------|-----------|
| curl | Yes | Used throughout (Steps 5-8) |
| psql | Yes | Step 3: `dbshell` mentioned; Step 8: shell operations |
| python/pip | Yes | Steps 1-4 |
| manage.py | Yes | Steps 2-3, 8 |

All tools are standard shell + curl. No exotic MCP dependencies.

## Example Invocation Proof

User: **"I need to validate a Django API"** or **"Flask validation with migrations"**

Skill immediately applies: Step 1 (dependencies), Step 2 (system check), Step 3 (migrations), Step 4 (server), Step 5-8 (endpoints + auth). Path is clear.

## Verdict

**Status:** ✅ **PASS**

This skill is production-ready. Frontmatter valid, trigger phrases realistic, body delivers 100% on description, PASS criteria rigorous (12-item checklist), and error table comprehensive (11 symptoms).

### Proposed Patches
None. Skill is solid.

### Follow-Ups
None required.
