# Forge Execution Rules

## Phase Gate Protocol

Every validation run follows the 7-phase pipeline. Phases are sequential — never skip a phase.

1. **Research** must complete before Plan begins
2. **Plan** must produce a written validation plan before Preflight
3. **Preflight** must PASS before Execute begins — if preflight fails, STOP
4. **Execute** captures evidence per journey — never mark a journey complete without evidence
5. **Analyze** investigates every FAIL using sequential thinking
6. **Verdict** synthesizes all evidence — never produce a partial verdict
7. **Ship** is optional — only after all journeys PASS

## Fix Loop Discipline

- Maximum 3 fix attempts per journey
- Each attempt must produce NEW evidence (never reuse previous evidence)
- Each attempt must fix a DIFFERENT root cause (not retry the same fix)
- After 3 failures, mark the journey as UNFIXABLE and move on
- Log every attempt in the forge state file

## State Persistence

- Write state to `.validationforge/forge-state.json` after every phase transition
- Include: run_id, current phase, journey verdicts, attempt counts, timestamps
- On resume: read state and continue from the last incomplete phase
- On completion: archive state with final verdicts

## Evidence Chain of Custody

- Evidence is captured at execution time, never fabricated after the fact
- Every evidence file must be non-empty and contain actual observations
- Evidence file names follow the pattern: `step-{NN}-{description}.{ext}`
- Each journey directory must have an `evidence-inventory.txt` listing all evidence files
- Timestamps in evidence must match the execution timeline

## Parallel Execution Safety

When running journeys in parallel:
- Each journey owns its evidence subdirectory exclusively
- No journey may write to another journey's evidence directory
- Shared resources (dev server, database) must be accessed safely
- If a journey modifies shared state, subsequent journeys must account for it
