Loaded `functional-validation` skill.

**Recommended path for Python API validation (no tests, no mocks):**

Per the skill's platform table, a Python API routes to `references/api-validation.md` — `curl` + response verification is the primary tool. Workflow:

1. **Define PASS criteria first** — specific observable outputs per endpoint (status, schema, field values), not "works."
2. **Start the real stack** — `uvicorn`/`gunicorn`/`flask run` + the real database + any downstreams. Poll `/health` until 200 before hitting anything else.
3. **Exercise endpoints with `curl`** — hit each route with real payloads, `tee` response bodies to `e2e-evidence/api/step-NN-<endpoint>.json`.
4. **Capture logs** — `tail -f app.log 2>&1 | tee e2e-evidence/api/server.log` during the run.
5. **Verify evidence** — `jq` each response against the PASS criteria; cite specific fields/values in the verdict. A `200 OK` alone is not a PASS.
6. **On FAIL** — read the stack trace in the real server logs, fix the handler, restart, re-validate from step 1 (no partial re-runs).

Want me to load `references/api-validation.md` for the full curl/evidence protocol, or is the framework already clear and you'd like to point me at the specific API under test?

