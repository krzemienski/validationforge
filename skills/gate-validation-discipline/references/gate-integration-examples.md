# Gate Integration Examples

## Integration with Team Mode / Parallel Execution

When multiple agents work in parallel (Team mode), gate discipline applies
to each agent independently:

1. **Each agent verifies its own work.** Agent A cannot mark Agent B's task complete.
2. **The orchestrator verifies agent outputs.** When agents report completion, the orchestrator
   runs the verification loop on their evidence before advancing the pipeline.
3. **Evidence is centralized.** All agents write evidence to `e2e-evidence/` with prefixed
   filenames: `e2e-evidence/{agent-name}-{criterion}.{ext}`.
4. **Gates are sequential.** Even if agents work in parallel, gates are checked in dependency
   order. Phase 2 gates cannot pass until Phase 1 gates pass.
5. **Conflicting evidence triggers review.** If Agent A's evidence contradicts Agent B's,
   the orchestrator must investigate before marking either complete.

## Integration with CI/CD

In non-interactive environments (CI pipelines, automated deployments), gate discipline
still applies but evidence capture is automated:

```yaml
# Example: CI gate validation
steps:
  - name: Build
    run: pnpm build 2>&1 | tee e2e-evidence/build-output.txt

  - name: Start server
    run: pnpm start &

  - name: Wait for server
    run: curl --retry 10 --retry-delay 2 http://localhost:3000/health

  - name: Capture API evidence
    run: |
      curl -s http://localhost:3000/api/users | jq . > e2e-evidence/users-response.json
      curl -s http://localhost:3000/api/health | jq . > e2e-evidence/health-response.json

  - name: Capture screenshot evidence
    run: npx playwright screenshot http://localhost:3000 e2e-evidence/homepage.png

  - name: Verify evidence
    run: |
      # Each evidence file must exist AND contain expected content
      jq -e '.users | length > 0' e2e-evidence/users-response.json
      jq -e '.status == "healthy"' e2e-evidence/health-response.json
      test -s e2e-evidence/homepage.png  # non-empty screenshot
```

Key principle: CI gates must produce **readable evidence artifacts**, not just pass/fail
exit codes. Store evidence as pipeline artifacts for post-mortem review.

## Failure Recovery

When evidence does not match criteria:

1. **Do NOT mark the gate as passed.** Partial evidence is not evidence.
2. **Identify the gap.** Which specific criterion lacks evidence? Which evidence contradicts expectations?
3. **Diagnose the root cause.** Is the feature broken, or is the evidence capture wrong?
   - Feature broken: fix the implementation, re-validate from Step 1
   - Evidence capture wrong: fix the capture method, re-capture
4. **Re-run the verification loop.** After fixing, start the full loop again — do not
   just re-check the one failed criterion.
5. **Document the failure.** Record what failed, why, and what was done to fix it.

## The Five "When In Doubt" Questions

If any answer is "no" or "I'm not sure," you are not done.

1. **Can I quote the specific evidence that proves each criterion?**
   Not "it works" — the exact output, screenshot content, or response body.

2. **Did I examine the evidence myself, or am I trusting someone else's report?**
   Trust but verify. Read what the sub-agent produced.

3. **Could this evidence be from a cached/stale result?**
   Timestamps matter. Evidence from a previous run is not evidence for this run.

4. **Does the evidence prove the criterion, or just not-disprove it?**
   "No errors" is not proof of correctness. "Expected output present" is proof.

5. **Would I stake my reputation on this completion claim?**
   If you would hedge, qualify, or add caveats — you are not done.
