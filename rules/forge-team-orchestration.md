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

## Platform Dependency Map

Platforms have implicit validation dependencies. A downstream platform cannot be
meaningfully validated until its upstream dependencies pass.

```
DB (database schema / migrations)
 └── API (server routes, data layer)
      ├── Web (browser UI, REST/GraphQL calls)
      └── iOS (native client, REST/GraphQL calls)

Integration (cross-platform flows: e.g. API→Web→iOS together)
 └── depends on ALL platforms
```

| Platform     | Depends On            |
|--------------|-----------------------|
| DB           | *(none — independent)*|
| API          | DB                    |
| Web          | API                   |
| iOS          | API                   |
| Integration  | API, Web, iOS (all)   |

Any platform not listed above (e.g. CLI, Design) is treated as **independent** unless
the lead explicitly declares additional dependencies in the run configuration.

## Dependency-Aware Spawning Protocol

Before spawning any validator the lead MUST:

1. **Resolve the dependency graph** — build an ordered list of platforms grouped into
   waves (see Execution Waves below).
2. **Check upstream status** — a platform may only be spawned when every platform it
   depends on has reported `PASS`.
3. **Never skip the check** — even if a dependency validator finished quickly, its
   status must be read from the completion report before spawning dependents.
4. **Record spawn decisions** — log each spawning decision as:
   `SPAWN {platform} — deps: {dep1=PASS, dep2=PASS}` or
   `BLOCK {platform} — deps: {dep1=FAIL}`.

## Failure Blocking Rules

When a validator reports `FAIL`:

- **FAIL propagates** — every platform that directly or transitively depends on the
  failed platform is marked `BLOCKED`.
- **BLOCKED validators are never spawned** — do not waste resources running a
  validator whose upstream dependency has already failed.
- **BLOCKED is reported as BLOCKED, not FAIL** — the verdict writer must distinguish:
  - `FAIL` — the validator ran and produced a failing verdict.
  - `BLOCKED` — the validator was never spawned because an upstream dependency failed.
- **BLOCKED verdicts cite the blocking dependency** — e.g.:
  `"Web: BLOCKED — API validator reported FAIL; web validation skipped."`
- **BLOCKED does not count toward fix-attempt quota** — only a `FAIL` on a validator
  that actually ran consumes one of the 3 allowed fix attempts.
- **Unblocking** — after a fix loop resolves the upstream `FAIL`, the lead may
  re-spawn the previously blocked validators; they start with a fresh attempt count.

## Execution Waves

Validators are grouped into waves based on their dependency depth. All validators in
a wave are spawned in parallel; the next wave starts only when every validator in the
current wave has reported `PASS`.

```
Wave 1 — Independent platforms (no upstream dependencies)
  └── DB validator (spawned immediately)
  └── CLI validator (if present; spawned immediately)
  └── Design validator (if present; spawned immediately)

Wave 2 — Platforms depending only on Wave 1
  └── API validator  (requires DB = PASS)

Wave 3 — Platforms depending only on Wave 2
  └── Web validator  (requires API = PASS)
  └── iOS validator  (requires API = PASS)

Wave 4 — Cross-platform integration
  └── Integration validator (requires Web = PASS AND iOS = PASS)
```

Wave advancement rules:
- **All validators in the current wave must report PASS** before the next wave starts.
- **Any FAIL in a wave** halts advancement: subsequent waves are marked BLOCKED.
- **Within a wave**, validators run in parallel and do not block each other.
- **If a project has no DB or API layer**, collapse waves accordingly — e.g. a
  pure-web project with no API dependency places the Web validator in Wave 1.
