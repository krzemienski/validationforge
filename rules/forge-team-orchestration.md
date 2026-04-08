# Forge Team Orchestration Rules

## Validator Assignment

- One validator per platform, maximum 5 validators per run
- Each validator receives ONLY its platform's journeys
- Validators are spawned in parallel, not sequentially
- Each validator prompt MUST include: journeys, evidence path, PASS criteria, iron rules

## Evidence Ownership

- Each validator exclusively owns its evidence directory: `e2e-evidence/{platform}/`
- No validator may read from or write to another validator's directory
- The lead orchestrator does NOT write evidence — only coordinates
- The verdict writer reads ALL evidence directories but writes ONLY to `e2e-evidence/report.md`
- Cross-platform evidence: each validator captures its OWN copy

## Communication Protocol

- Validators report completion via task updates, not messages
- Validators include evidence inventory in their completion report
- If a validator encounters a blocker, it reports immediately to the lead
- Validators do NOT communicate with each other directly

## Verdict Synthesis

- The verdict writer is spawned AFTER all validators complete
- The verdict writer must read every evidence file, not just inventories
- The verdict writer must cite specific evidence for every PASS/FAIL
- Contradictory verdicts between validators are escalated to the lead
- Missing evidence = FAIL, never INCONCLUSIVE

## Lifecycle

1. Lead detects platforms from `.validationforge/config.json`
2. Lead partitions journeys by platform
3. Lead spawns validators in parallel (one per platform)
4. Validators execute, capture evidence, report verdicts
5. Lead waits for ALL validators (never produce partial report)
6. Lead spawns verdict writer with all evidence
7. Verdict writer produces unified report
8. Lead presents report to user
