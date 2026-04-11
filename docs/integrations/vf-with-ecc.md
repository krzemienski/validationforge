# ValidationForge + Everything Claude Code (ECC)

**Positioning**: ECC enforces code quality, craft standards, and engineering rigor. ValidationForge enforces real-system validation discipline. Used together, they provide a two-gate pipeline: code must be both high-quality AND prove it works.

## Why This Combination

ECC focuses on the craft of writing code — style, clarity, testability, security, language idioms. It catches bad code before it ships. ValidationForge focuses on whether the running system actually works end-to-end, catching bad behavior before it ships. These gates are orthogonal:

- Code can pass ECC's quality gates and still be functionally broken (code is clean but logic is wrong)
- Code can pass VF's validation and still be a maintenance nightmare (it works but nobody can read it)

Using both gives you a pipeline where nothing ships until it is **both** well-crafted **and** demonstrably working.

## Workflow Example

Developer implements a new rate-limiting feature for the API.

1. **ECC's code-reviewer skill** fires on the diff and flags issues:
   - Missing null check on request IP
   - Hardcoded magic numbers instead of config
   - No explicit error type
2. Developer fixes the code until ECC passes
3. **ECC's security-review skill** confirms the rate limiter doesn't leak timing information
4. Developer runs `/validate` (VF)
5. **VF's execute phase**:
   - Step 1: Hit the endpoint 100 times within 1 minute — expect 429 after 60th request
   - Step 2: Wait 1 minute — expect 200 again
   - Step 3: Confirm the 429 response includes `Retry-After` header
6. **VF's verdict** PASS — rate limiting works through the real HTTP interface
7. Merge

Without ECC: the implementation might be functional but unmaintainable and insecure.
Without VF: the code might be beautifully crafted but the rate limiter is off-by-one and triggers at 61 requests instead of 60 — ECC cannot catch this because it only reads code.

## Handling Overlap

ECC and VF both have security review skills. These are **not** duplicates — they operate at different layers:

| Concern | ECC security review | VF security audit |
|---|---|---|
| SQL injection in source code | YES — scans code for unsafe queries | NO — assumes code is already reviewed |
| Leaked secrets in commits | YES — scans for patterns like `API_KEY=` | NO — not a VF concern |
| Missing CORS headers on real API response | NO — cannot see runtime behavior | YES — `curl -I` captures actual headers |
| Broken auth when cookies are disabled | NO — cannot simulate browser state | YES — Playwright session reproduces |

Run ECC first (static analysis), then VF (runtime verification).

## Configuration Snippet

Enable both plugins:

```json
{
  "plugins": [
    {
      "name": "everything-claude-code",
      "path": "~/.claude/plugins/everything-claude-code",
      "enabled": true
    },
    {
      "name": "validationforge",
      "path": "~/.claude/plugins/validationforge",
      "enabled": true
    }
  ]
}
```

Per-project `.claude/settings.json`:

```json
{
  "plugins": {
    "everything-claude-code": {
      "skills": ["code-reviewer", "security-review", "tdd-workflow"],
      "enforcement": "strict"
    },
    "validationforge": {
      "profile": "strict",
      "evidence_dir": "e2e-evidence",
      "pipeline_order": ["ecc-quality-gate", "vf-validation-gate"]
    }
  }
}
```

The `pipeline_order` key is illustrative — actual ordering depends on how each plugin's hooks register. In practice, ECC's hooks fire on file edits (pre-commit-like) and VF's hooks fire on task completion (post-build-like), so they naturally sequence.

## Sample Output (Illustrative)

```
[Developer edits src/middleware/rate-limiter.ts]

[ECC: code-reviewer] Scanning diff...
  [HIGH]  Missing null check on req.ip (line 34)
  [MED]   Magic number 60 should be RATE_LIMIT_MAX_REQUESTS config
  [LOW]   Function too long (87 lines), consider extracting

[Developer fixes all 3 issues]

[ECC: code-reviewer] Re-scanning...
  Clean

[ECC: security-review] Rate limiter timing attack check...
  PASS — constant-time comparison confirmed

[Developer] /validate

[VF phase 2: Preflight]
  - API server: PASS
  - Redis (rate limiter backend): PASS

[VF phase 3: Execute]
  journey-1-rate-limit-enforcement
    step-01-burst-60-requests.txt: 200 x 60
    step-02-request-61.json: status=429, headers.Retry-After=60
    step-03-wait-60s-retry.json: status=200

[VF phase 5: Verdict]
  journey-1-rate-limit-enforcement: PASS
  Evidence: e2e-evidence/rate-limiter/
  ECC quality gate: PASS
  VF validation gate: PASS
  Merge decision: APPROVED
```

## Caveats

- **Duplicate skills**: Both plugins have `code-reviewer` skills. The Claude Code skill discovery picks the one loaded last. Use ECC's (more mature) or explicitly disable one via `.claude/settings.json`.
- **Context budget**: ECC's 400+ skills + VF's 48 skills is a lot. Strongly recommend VF's platform-aware skill loading (spec 008) to reduce VF footprint when working on a single-platform project.
- **ECC's tdd-workflow may conflict with VF's block-test-files**: Same resolution as the Superpowers guide — configure VF to scan only validation directories, not your main source tree.
- **Agent name collisions**: Both plugins register some agents (e.g., `code-reviewer`). Verify by running `ls ~/.claude/plugins/*/agents/` and resolve any duplicates.

## Runtime Verification

This integration has not been verified in a live session. To verify:

1. Install both plugins
2. Configure hook overrides as above
3. Make a code change and observe ECC's hooks fire first
4. Run `/validate` and observe VF's pipeline execute
5. Confirm both gates report independently
6. Record findings in `e2e-evidence/vf-with-ecc-integration/`
