---
name: Demo Oracle Scaffolding for B5 (5-Scenario Benchmark)
date: 2026-04-16
status: pending
gap_ids: [B5]
depends_on: []
type: integration
---

# Demo Oracle Scaffolding for B5

## Why

P05 benchmark validation blocked on B5: cannot run 5-scenario proof without demo oracle infrastructure. Demo oracle is a set of mocked validation endpoints (with known-good responses) that simulator scenarios validate against. Currently unavailable.

## Acceptance Criteria

- 5 demo oracle endpoint stubs created (endpoints: config, validate, decision, evidence, report)
- Each stub returns well-formed JSON with realistic data
- Scenarios can run against oracles without external dependencies
- Evidence captured for all 5 scenarios
- B5 re-run in Phase 05 (retry) completes with PASS

## Inputs

- P05 validator findings (evidence/05-benchmark/scenarios.md)
- Current benchmark skip logic (benchmark-skip.md notes)

## Steps

1. Extract scenario definitions from `evidence/05-benchmark/scenarios.md`
2. Design 5 oracle endpoint responses (config, validate, decision, evidence, report)
3. Implement stub HTTP server or mock module
4. Wire scenarios to use oracle endpoints
5. Run 5 scenarios; capture evidence
6. Re-validate P05 (Phase 05 retry attempt)

## Success Criteria

- 5/5 scenarios run without external dependency errors
- Evidence captured for all 5 scenarios
- P05 validator reports PASS on retry

## Next Phase

V1.5 integration: CONSENSUS engine + demo oracle test bed

---

**Status:** Pending V1.5 kickoff
