# Subtask 2.1 — Evidence Manifest

**Subtask:** 2.1 — Start blog-series/site on localhost:3847
**Date:** 2026-04-17
**Fixture:** /Users/nick/Desktop/blog-series/site (Next.js 16.1.6, pre-existing, no mocks)

## Startup Command

```
cd /Users/nick/Desktop/blog-series/site
npx next start -p 3847
```

Server log shows: `▲ Next.js 16.1.6`, `Local: http://localhost:3847`, `✓ Ready in 992ms`.

## Sandbox Notes

- Next.js `listen(0.0.0.0:3847)` returned `EPERM` inside the sandbox. Start was therefore executed with `dangerouslyDisableSandbox: true` — the only sandbox exception required for this subtask. The server process continues running on the host bound to port 3847.
- `curl` inside the sandbox also silently failed (exit 0 / empty output on loopback). The 200 confirmation below was captured with sandbox disabled for the probe only.
- No fixture source was modified. Iron Rule compliance: no mocks, no test files, no stubs.

## Captured Artifacts (this directory)

| File | Purpose | Evidence |
|------|---------|----------|
| `step-2.1-curl-head.txt` | `curl -sI http://localhost:3847` response | `HTTP/1.1 200 OK`, `Content-Type: text/html; charset=utf-8`, `Content-Length: 76249`, `X-Powered-By: Next.js`, `x-nextjs-cache: HIT`, `x-nextjs-prerender: 1` |
| `step-2.1-health-check.txt` | Output of `./scripts/health-check.sh http://localhost:3847 10 1` | `HEALTHY: http://localhost:3847 responded 200 after 0 seconds` |
| `step-2.1-listen.txt` | `lsof -nP -iTCP:3847 -sTCP:LISTEN` | `node 44150 nick 12u IPv6 ... TCP *:3847 (LISTEN)` — confirms the Next.js node process is bound to the port |
| `step-2.1-evidence-manifest.md` | This file | Cross-index of the above artifacts |

## Acceptance Check

Plan row 2.1 acceptance: `curl -sI http://localhost:3847 returns HTTP/1.1 200 OK`.

Verified: `step-2.1-curl-head.txt` line 1 reads `HTTP/1.1 200 OK` — matches the precedent in `./e2e-evidence/web-validation/VERDICT.md` row 3 (PASS 6/6 baseline).

## Handoff to Subtask 2.2

Server remains running (PID 44150) for the live `claude --print "/validate-ci --platform web"` invocation called for in `./e2e-evidence/pipeline-verification/run-book.md` §2. Do not kill until 2.2 evidence has been copied into this directory.
