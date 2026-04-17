# Consensus Engine

## Engine Identity

The CONSENSUS engine is the execution-time agreement gate in ValidationForge's three-engine architecture. It is a peer to `rules/team-validation.md` — where team validation coordinates multiple specialized validators across platforms, the consensus engine coordinates multiple **independent** validators against the **same** feature and synthesizes a single verdict with a confidence score.

```
FORGE builds code → VALIDATE proves it works → CONSENSUS confirms agreement
```

Within that triad:
- **FORGE** (`rules/forge-execution.md`) — produces the artifact
- **VALIDATE** (`rules/execution-workflow.md`) — proves the artifact works once
- **CONSENSUS** (this rule) — proves the artifact works according to ≥2 independent reviewers

Relationship to sibling rules:
- `rules/team-validation.md` — N validators, N platforms, N verdicts. Different journeys per validator. Parallel coverage.
- `rules/consensus-engine.md` (this file) — N validators, 1 feature, 1 synthesized verdict. Same journeys across all validators. Parallel agreement.

Both share the parallel orchestration pattern but differ in intent. Team validation maximizes **coverage**; consensus maximizes **confidence**.

## Roles

| Role | Count | Responsibility | Skills Used |
|------|-------|---------------|-------------|
| **Coordinator** | 1 | Spawns validators, monitors completion, invokes synthesizer. Does NOT validate or write evidence. | consensus-engine, preflight, parallel-validation |
| **Validator-N** | ≥2, default 3 | Independently executes the full journey list, captures its own evidence, writes its own per-journey PASS/FAIL verdicts. Blind to peer verdicts until synthesis. | functional-validation, platform-specific validation skills, evidence-capturer agent |
| **Synthesizer** | 1 | Reads all validator verdicts, applies the Synthesis States table, computes confidence, invokes disagreement protocol when needed, writes the unified consensus report. | consensus-synthesis, consensus-disagreement-analysis, verdict-writer (specialization) |

**Default roster:** Coordinator + 3 Validators + Synthesizer = 5 agents. The Validator count is configurable via `--validators N` where `N ≥ 2`. Odd counts (3, 5) are preferred to avoid 1:1 ties on binary verdicts, but not required — SPLIT is handled explicitly.

## File Ownership

Each role owns a well-defined slice of the evidence tree, and no role may write outside its slice.

```
e2e-evidence/
  consensus/
    validator-1/   ← Validator-1 only (exclusive write)
      step-01-*.{png,json,txt}
      verdict.md
    validator-2/   ← Validator-2 only (exclusive write)
      step-01-*.{png,json,txt}
      verdict.md
    validator-3/   ← Validator-3 only (exclusive write)
      step-01-*.{png,json,txt}
      verdict.md
    report.md      ← Synthesizer only (exclusive write)
```

| Owner | Writes To | Reads From |
|-------|-----------|------------|
| **Coordinator** | *(nothing)* | validator-N/verdict.md (to detect completion) |
| **Validator-N** | `e2e-evidence/consensus/validator-{N}/` exclusively | source code, runtime artifacts |
| **Synthesizer** | `e2e-evidence/consensus/report.md` exclusively | all `validator-N/` directories |

**Ownership is absolute.** A validator that writes to another validator's directory invalidates the independence guarantee and the run must be discarded. The coordinator owning nothing is the load-bearing invariant: a coordinator that captures evidence has an implicit bias toward its own observations.

## Synthesis States

After all validators complete, the synthesizer maps the verdict tuple `(pass_count, fail_count, total)` per journey to a synthesis state, then emits a final verdict with a confidence tier.

| State | Condition | Final Verdict | Confidence | Action |
|-------|-----------|---------------|------------|--------|
| **UNANIMOUS_PASS** | All validators PASS | PASS | HIGH | Emit PASS with consensus citation |
| **UNANIMOUS_FAIL** | All validators FAIL | FAIL | HIGH | Emit FAIL with consensus citation |
| **MAJORITY_PASS** | pass_count > fail_count AND ≥⅔ PASS | PASS | MEDIUM | Run disagreement protocol; if resolved, emit PASS (MEDIUM) with dissent noted |
| **MAJORITY_FAIL** | fail_count > pass_count AND ≥⅔ FAIL | FAIL | MEDIUM | Run disagreement protocol; if resolved, emit FAIL (MEDIUM) with dissent noted |
| **SPLIT** | Neither side reaches ⅔ | DISAGREEMENT_UNRESOLVED | LOW | Run disagreement protocol; if unresolved, escalate to human |

**Per-journey synthesis.** State is computed per journey, not per run. A feature with 10 journeys can have 7 UNANIMOUS_PASS, 2 MAJORITY_PASS, and 1 SPLIT — the report reflects each independently. The overall run verdict is the weakest verdict across journeys (one SPLIT → overall DISAGREEMENT_UNRESOLVED).

## Confidence Formula

Confidence is a direct function of agreement ratio, not of validator count or evidence volume.

```
agreement_ratio = max(pass_count, fail_count) / total_validators

confidence =
  HIGH    if agreement_ratio == 1.0                  (unanimous)
  MEDIUM  if agreement_ratio >= 2/3 (after disagreement analysis resolves it)
  LOW     if agreement_ratio <  2/3                  (split; unresolved)
```

Confidence degrades monotonically: a validator joining late or a re-run flipping does not upgrade confidence above what the final tuple supports. Evidence quality cannot substitute for agreement — a HIGH confidence verdict requires unanimity regardless of how compelling one validator's evidence is.

## Disagreement Protocol

When synthesis state is anything other than UNANIMOUS_PASS or UNANIMOUS_FAIL, the synthesizer MUST invoke the disagreement protocol before finalizing the verdict.

1. **Identify diverging criteria.** For each PASS criterion in the journey, compute per-validator verdict. Isolate the criteria where validators disagree (the "diverging set").
2. **Invoke `sequential-analysis`.** For each diverging criterion, run the sequential-analysis skill over the cited evidence from all validators. The goal is root cause: is the disagreement about (a) missing evidence on one side, (b) contradictory evidence, (c) different interpretation of the same evidence, or (d) validator error?
3. **Re-resolve when possible.**
   - **(a) Missing evidence** → re-run the missing validator on that criterion only; re-synthesize.
   - **(b) Contradictory evidence** → the real system is non-deterministic OR a validator captured stale state; re-run the full journey for the minority side; re-synthesize.
   - **(c) Different interpretation** → the PASS criterion is under-specified; escalate to the planner to sharpen the criterion; do NOT re-resolve in this run.
   - **(d) Validator error** (e.g., invalid evidence, unreachable citations) → discard that validator's verdict for the criterion; re-synthesize with remaining validators.
4. **Escalate when not.** If root cause analysis cannot resolve the disagreement (e.g., genuine ambiguity in what the feature should do), mark the journey DISAGREEMENT_UNRESOLVED with LOW confidence and surface the disagreement to the human in the report. Do NOT silently downgrade to MAJORITY.

The synthesizer NEVER invents a verdict to break a tie. SPLIT is a real, reportable outcome — shipping a DISAGREEMENT_UNRESOLVED journey requires an explicit human override, not an implicit one.

## Iron Rules (Carry-Over)

All Iron Rules from `rules/validation-discipline.md` apply unchanged to every validator in the consensus run:

1. **No mocks, no test files, no test doubles.** Each validator exercises the real system.
2. **Evidence cited or the verdict is invalid.** Every PASS/FAIL the validator emits must cite specific evidence files in its own `validator-{N}/` directory.
3. **Compilation is not validation.** A validator that reports PASS because the build succeeded has emitted an invalid verdict; the synthesizer must treat it as validator error (case d).
4. **Screenshots describe what is SEEN.** API responses quote the body. Logs include timestamps. Zero-byte files are invalid evidence.
5. **Preflight before spawning.** The coordinator runs preflight before spawning validators. If preflight fails, no validator is spawned and the run is aborted.

Consensus raises the bar but does not change the bar. A validator that cuts corners on evidence compromises the entire run — its verdict, whether PASS or FAIL, cannot be trusted to represent the real system.

## Relationship to /forge-plan --consensus

`/forge-plan --consensus` and this engine are **philosophically aligned but operationally distinct**. They apply the consensus principle at different points in the pipeline.

| Aspect | `/forge-plan --consensus` | `rules/consensus-engine.md` (this) |
|--------|---------------------------|-------------------------------------|
| **When** | Planning time (before any code is written) | Execution time (after code is built, before ship) |
| **Inputs** | A specification / problem statement | A running system + validation plan |
| **Agents** | 3 planner perspectives (e.g., security, performance, correctness) | ≥2 Validators (default 3), all executing the same plan |
| **Output** | 1 synthesized implementation plan | 1 synthesized PASS/FAIL verdict with confidence |
| **Disagreement handling** | Perspectives merged into a unified plan | SPLIT → DISAGREEMENT_UNRESOLVED, escalated |
| **Primary metric** | Plan quality (completeness, tradeoffs surfaced) | Verdict confidence (agreement ratio) |

Both reduce single-agent bias. `/forge-plan --consensus` reduces **planning bias** (one agent misses a dimension); this engine reduces **validation bias** (one validator misses a defect or fabricates a PASS). A project using both gets consensus at both ends: 3 perspectives shape the plan, then ≥2 Validators confirm the implementation.

They do not share primitives — the forge-plan perspectives are cognitive roles in a single agent call; the consensus-engine Validators are independent agent spawns with isolated evidence directories. Confusing the two is a category error: do not reuse forge-plan perspectives as consensus Validators, and do not expect execution-time consensus to catch planning-time blind spots.
