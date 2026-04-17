---
name: CONSENSUS Engine Test Bed (V1.5)
date: 2026-04-16
status: pending
gap_ids: [CONSENSUS]
depends_on: []
type: engine
---

# CONSENSUS Engine Test Bed

## Why

P08 deferred CONSENSUS engine testing to V1.5. Engine exists as code stub but has never been exercised against real hypothesis scenarios. Test bed validates multi-agent consensus voting on problem prioritization.

## Acceptance Criteria

- 3+ hypothesis scenarios defined and runnable
- CONSENSUS engine dispatches agents to vote on scenario priority
- Voting produces consensus (70%+ agent agreement on top hypothesis)
- Evidence captured for all 3 scenarios (agent votes, consensus output, timing)
- Benchmark ≥ A on CONSENSUS test set

## Inputs

- CONSENSUS engine code (src/engines/consensus.js or equivalent)
- Hypothesis test scenarios from P08 analysis (evidence/08-engines/scenarios.md)
- Evidence capture infrastructure (M4 — evidence retention)

## Steps

1. Extract hypothesis scenarios from P08 analysis
2. Implement 3 test scenarios (real-world debugging problems)
3. Wire CONSENSUS engine to dispatch agents
4. Collect agent votes per scenario
5. Verify consensus algorithm (70%+ threshold)
6. Capture evidence per scenario
7. Re-benchmark; verify ≥ A

## Success Criteria

- 3/3 scenarios produce consensus (documented votes)
- Consensus matches expected priority ranking (human verification)
- Evidence audit passes (non-empty files, real agent output)
- Benchmark score ≥ A

## Timing

V1.5 priority. Prerequisite: B5 demo oracle scaffolding may be needed.

---

**Status:** Pending V1.5 planning
