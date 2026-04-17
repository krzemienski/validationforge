---
name: FORGE Engine Real-System Exercise (V2.0)
date: 2026-04-16
status: pending
gap_ids: [FORGE]
depends_on: [CONSENSUS]
type: engine
---

# FORGE Engine Real-System Exercise

## Why

P08 deferred FORGE engine testing to V2.0. Engine is designed to autonomously fix validation FAILs against a real system, but has never been exercised. Real-system test bed validates autonomous detection, fix proposal, and re-validation loops under bounded conditions.

## Acceptance Criteria

- Real-like system created (Flask API + SQLite DB + browser UI, or equivalent mock)
- 5 intentional defects injected into real system
- FORGE engine detects 5/5 defects
- FORGE proposes fixes for 5/5 defects
- FORGE re-validates after each fix (4/5 successful, 1 expected failure acceptable)
- Evidence captured per loop iteration
- Benchmark ≥ A on FORGE test set

## Inputs

- FORGE engine code (src/engines/forge.js or equivalent)
- FORGE specification from P08 analysis (evidence/08-engines/forge-spec.md)
- Real-system scaffolding (from P01 benchmark suite — Flask API)
- Defect seeding strategy (intentional bugs: schema, logic, UI rendering)
- Evidence capture + lock protocol (M4)

## Steps

1. Extract FORGE spec from P08 analysis
2. Create mock real system (Flask API + DB + UI)
3. Define 5 intentional defects (schema, logic, network, UI, config)
4. Inject defects into running system
5. Wire FORGE to detect + propose + fix + re-validate
6. Run full loop; capture evidence per iteration
7. Analyze fix success rate (expect 4/5 minimum)
8. Re-benchmark; verify ≥ A

## Success Criteria

- 5/5 defects detected (FAIL verdicts with evidence)
- 5/5 fixes proposed (evidence-backed)
- 4+/5 re-validations succeed (PASS after fix)
- Evidence audit passes (non-empty files, real system outputs)
- Benchmark score ≥ A

## Dependencies

Soft dependency on CONSENSUS (V1.5): Both engines should reach feature parity before V2.0.

## Timing

V2.0 priority. Post-V1.5. Estimated: 2–3 weeks.

---

**Status:** Pending V2.0 planning (after V1.5 CONSENSUS bed stable)
