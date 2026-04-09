---
name: production-readiness-audit
description: Systematic audit of application readiness for production deployment
triggers:
  - "production readiness"
  - "deploy audit"
  - "is this ready for production"
  - "production checklist"
  - "readiness review"
context_priority: reference
---

# Production Readiness Audit

Systematic multi-phase audit to determine if an application is ready for production deployment. Produces an evidence-backed readiness report with PASS/FAIL verdicts per category.

## When to Use

- Before first production deployment
- Before major version releases
- After significant refactoring
- When stakeholders ask "is this ready?"

## Audit Phases

```
Phase 1: CODE QUALITY ──────> Phase 2: SECURITY ──────> Phase 3: PERFORMANCE
     |                             |                          |
     v                             v                          v
Phase 4: RELIABILITY ───────> Phase 5: OBSERVABILITY ──> Phase 6: DOCUMENTATION
     |                             |                          |
     v                             v                          v
Phase 7: DEPLOYMENT ────────> Phase 8: FINAL VERDICT
```

Phases 1-3 can run in parallel. Phases 4-6 can run in parallel. Phase 7 depends on 1-6. Phase 8 synthesizes all results.

## Phase 1: Code Quality

```bash
mkdir -p e2e-evidence/prod-audit/code-quality
```

### Checklist

| # | Item | How to Verify | Evidence |
|---|------|---------------|----------|
| 1.1 | No TODO/FIXME/HACK in critical paths | `grep -rn "TODO\|FIXME\|HACK" src/` | Save output |
| 1.2 | No hardcoded secrets | `grep -rn "password\|secret\|api.key\|token" src/ --include="*.{ts,js,py,swift}"` | Save output |
| 1.3 | Error handling in all API calls | Review network/API code paths | Document findings |
| 1.4 | No console.log/print debugging | `grep -rn "console\.log\|print(" src/` | Save output |
| 1.5 | Dependencies are current | `npm outdated` or equivalent | Save output |
| 1.6 | No known vulnerabilities | `npm audit` or equivalent | Save output |

## Phase 2: Security

```bash
mkdir -p e2e-evidence/prod-audit/security
```

### Checklist

| # | Item | How to Verify | Evidence |
|---|------|---------------|----------|
| 2.1 | Authentication works | Exercise login flow via real UI | Screenshots |
| 2.2 | Authorization enforced | Access protected routes without auth | Screenshot of redirect/403 |
| 2.3 | Input sanitization | Submit XSS payloads in forms | Screenshot showing sanitized output |
| 2.4 | HTTPS enforced | Check for HTTP redirects | `curl -I http://...` output |
| 2.5 | Security headers present | Check response headers | `curl -I https://...` output |
| 2.6 | CORS configured correctly | Check `Access-Control-*` headers | Save headers |
| 2.7 | Rate limiting on auth endpoints | Send rapid requests | Response codes logged |
| 2.8 | Sensitive data not in URLs | Review routes for query params with PII | Document findings |

## Phase 3: Performance

```bash
mkdir -p e2e-evidence/prod-audit/performance
```

### Checklist

| # | Item | How to Verify | Evidence |
|---|------|---------------|----------|
| 3.1 | Page loads under 3s | Lighthouse or browser timing | Performance trace |
| 3.2 | LCP under 2.5s | Lighthouse audit | Score report |
| 3.3 | No memory leaks (long-running) | Heap snapshot comparison | Before/after snapshots |
| 3.4 | Images optimized | Check for uncompressed images | File sizes listed |
| 3.5 | Lazy loading for below-fold content | Inspect network waterfall | Network log |
| 3.6 | API responses under 500ms | Measure endpoint response times | Timing data |

## Phase 4: Reliability

```bash
mkdir -p e2e-evidence/prod-audit/reliability
```

### Checklist

| # | Item | How to Verify | Evidence |
|---|------|---------------|----------|
| 4.1 | Graceful error handling | Trigger errors — verify user-friendly messages | Screenshots |
| 4.2 | Network failure resilience | Disconnect network — verify app doesn't crash | Screenshots |
| 4.3 | Data validation at boundaries | Submit invalid data — verify rejection | Screenshots + API responses |
| 4.4 | State recovery after errors | Trigger error, then navigate — verify clean state | Screenshots |
| 4.5 | Concurrent access handling | Multiple tabs/users if applicable | Document findings |

## Phase 5: Observability

```bash
mkdir -p e2e-evidence/prod-audit/observability
```

### Checklist

| # | Item | How to Verify | Evidence |
|---|------|---------------|----------|
| 5.1 | Error tracking configured | Check for Sentry/Datadog/etc. integration | Config file reference |
| 5.2 | Structured logging in place | Review log output format | Sample log entries |
| 5.3 | Health check endpoint exists | `curl /health` or `/api/health` | Response saved |
| 5.4 | Key metrics tracked | Review analytics/monitoring setup | Document what's tracked |

## Phase 6: Documentation

```bash
mkdir -p e2e-evidence/prod-audit/documentation
```

### Checklist

| # | Item | How to Verify | Evidence |
|---|------|---------------|----------|
| 6.1 | README has setup instructions | Read README — can a new dev start? | Note completeness |
| 6.2 | Environment variables documented | `.env.example` or docs exist | File reference |
| 6.3 | API endpoints documented | Swagger/OpenAPI or README section | File reference |
| 6.4 | Deployment process documented | Check for deploy docs/scripts | File reference |

## Phase 7: Deployment

```bash
mkdir -p e2e-evidence/prod-audit/deployment
```

### Checklist

| # | Item | How to Verify | Evidence |
|---|------|---------------|----------|
| 7.1 | Build succeeds in production mode | `npm run build` / equivalent | Build log |
| 7.2 | Environment variables configured | All required vars have values | Checklist (no values!) |
| 7.3 | Database migrations ready | Review pending migrations | Migration list |
| 7.4 | Rollback plan exists | Document rollback steps | Written plan |
| 7.5 | SSL certificate valid | Check cert expiration | `openssl` output |

## Phase 8: Final Verdict

Synthesize all phase results into a single readiness report.

```markdown
# Production Readiness Audit Report

**Application:** {name}
**Version:** {version}
**Audit date:** YYYY-MM-DD
**Auditor:** ValidationForge

## Summary

| Phase | Items | Pass | Fail | Skip | Verdict |
|-------|-------|------|------|------|---------|
| 1. Code Quality | 6 | N | N | N | PASS/FAIL |
| 2. Security | 8 | N | N | N | PASS/FAIL |
| 3. Performance | 6 | N | N | N | PASS/FAIL |
| 4. Reliability | 5 | N | N | N | PASS/FAIL |
| 5. Observability | 4 | N | N | N | PASS/FAIL |
| 6. Documentation | 4 | N | N | N | PASS/FAIL |
| 7. Deployment | 5 | N | N | N | PASS/FAIL |

## Overall Verdict: READY | NOT READY | CONDITIONAL

### Blocking Issues (must fix before deploy)
1. [CRITICAL issue with evidence reference]

### Non-Blocking Issues (fix soon after deploy)
1. [Issue with evidence reference]

### Recommendations
1. [Improvement suggestion]
```

Save to `e2e-evidence/prod-audit/report.md`.

## Severity Rules

- **Any Phase 2 (Security) FAIL** = NOT READY (blocking)
- **Any Phase 7 (Deployment) FAIL** = NOT READY (blocking)
- **Phase 1, 3, 4 FAILs** = CONDITIONAL (document risk acceptance)
- **Phase 5, 6 FAILs** = CONDITIONAL (non-blocking but tracked)
- **All phases PASS** = READY

## Integration with ValidationForge

- All evidence goes to `e2e-evidence/prod-audit/{phase}/`
- The `verdict-writer` agent reads phase reports for overall verdict
- This audit complements but does NOT replace feature-level validation
- Run this AFTER all feature-level validations have passed
