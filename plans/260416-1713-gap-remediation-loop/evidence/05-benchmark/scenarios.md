# P05 Scenario Inventory

**Date:** 2026-04-16
**Executor:** fullstack-developer (a4128d005b3e7d966)
**Methodology:** IN-SCOPE requires BOTH (a) target demo dir exists AND (b) pre-existing oracle file ships with the demo at HEAD (not authored by this campaign).

---

## Scenario Table

| id | scenario_name | target_demo | mutation_cmd | defect_sha | oracle_cmd | oracle_file | status | rationale |
|----|---------------|-------------|--------------|------------|------------|-------------|--------|-----------|
| S1 | API field rename (JSON key drift) | `demo/python-api/` | `sed -i '' 's/"in_stock"/"inStock"/g' app.py` | N/A | N/A | N/A | OUT_OF_SCOPE | Demo dir EXISTS (`demo/python-api/app.py`). No pre-existing oracle: zero test files found under `demo/python-api/` (excluding `.venv`). Only committed files: `app.py`, `README.md`, `requirements.txt`. Oracle missing → BLOCKED_WITH_USER. |
| S2 | JWT signature mismatch | any auth demo | N/A | N/A | N/A | N/A | OUT_OF_SCOPE | No auth-capable demo exists in `demo/` or `benchmark/scaffolds/`. `demo/python-api/app.py` has no JWT/auth code. No scaffold with auth layer found. Missing demo → BLOCKED_WITH_USER. |
| S3 | iOS deep link broken | `demo/ios-app/` | N/A | N/A | N/A | N/A | OUT_OF_SCOPE | `demo/ios-app/` does not exist. Only iOS artifact is `benchmark/scaffolds/swift-ios/` which contains only `.claude/settings.json` and `.vf/benchmarks/` — no Xcode project, no Swift source, no oracle. Missing demo → BLOCKED_WITH_USER. |
| S4 | DB migration regression | DB-backed demo | N/A | N/A | N/A | N/A | OUT_OF_SCOPE | No DB-backed demo exists. `demo/python-api/app.py` uses in-memory list store only (no SQLAlchemy, no Alembic, no migration files). Missing demo → BLOCKED_WITH_USER. |
| S5 | CSS overflow clipping CTA | `demo/nextjs-web/` | N/A | N/A | N/A | N/A | OUT_OF_SCOPE | `demo/nextjs-web/` does not exist. `benchmark/scaffolds/node-nextjs/` contains only `.claude/settings.json` and `.vf/benchmarks/` — no Next.js source, no pages, no oracle. Missing demo → BLOCKED_WITH_USER. |

---

## Discovery Evidence

```
demo/ contents (at HEAD):
  DEMO-SCENARIO.md
  generate-demo.py
  python-api/
    app.py          — Flask, in-memory store, no auth, no DB, no tests
    README.md
    requirements.txt
    .venv/          — installed packages only (not committed)
  vf-demo.gif

benchmark/scaffolds/ contents (all 8 dirs):
  node-cli/         — .claude/ + nothing else
  node-express/     — .claude/ + .vf/benchmarks/
  node-fullstack/   — .claude/ + nothing else
  node-nextjs/      — .claude/ + .vf/benchmarks/
  node-react/       — .claude/ + nothing else
  python-cli/       — .claude/ + nothing else
  python-flask/     — .claude/ + .vf/benchmarks/
  swift-ios/        — .claude/ + .vf/benchmarks/

Conclusion: No scaffold contains app source code or test files.
All 5 scenarios are OUT_OF_SCOPE. N_scope = 0.
```
