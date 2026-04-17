# Engines Deferred

## Status
- VALIDATE engine: shipping (current campaign)
- CONSENSUS engine: planned for V1.5
- FORGE engine: planned for V2.0

## Deferment rationale (2026-04-16)
CONSENSUS (multi-reviewer unanimous voting, planned V1.5) and FORGE (fix-and-retry loop with
3-strike cap) were not executable end-to-end at campaign time because
`demo/*` lacked pre-existing test oracles (see B5 → BLOCKED_WITH_USER).
Executing fabricated oracles would violate the No-Mock Iron Rule.

## Measurable exit criteria

### CONSENSUS exits deferment when:
- `/validate-team` is successfully invoked in ≥ 10 distinct external repos
  (not ValidationForge scaffolds), each producing evidence under `.vf/benchmarks/`.
- At least 3 of those 10 runs demonstrate a real 2-agree HOLD verdict
  (i.e. consensus divergence) with captured transcripts.
- No test-file mocks authored; every validator result is against a real system.

### FORGE exits deferment when:
- `/forge-execute` completes ≥ 10 full 3-strike loops (attempt 1 FAIL →
  fix → attempt 2) against real-system defects in external repos.
- ≥ 80% terminate in PASS before attempt 4.
- No authored test files; every fix diff cites real source lines.
- Worktree-isolated; cleanup verified for all 10.

## User-facing statement (paste into README)
> CONSENSUS and FORGE engines are planned for V1.5 and V2.0 respectively.
> Today, VALIDATE is the only shipping engine; CONSENSUS multi-reviewer
> voting and FORGE fix-and-retry loops are under active design and not
> available for production use. See docs/ENGINES-DEFERRED.md for the
> acceptance criteria that will lift this deferment.

## Owner & re-visit
- Owner: nick@krzemienski.com
- Target re-visit: 2026-07-16 (90 days after this closeout)
