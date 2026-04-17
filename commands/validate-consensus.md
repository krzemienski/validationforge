---
name: validate-consensus
description: Spawn N independent validators to assess the same feature and synthesize a unified consensus verdict with confidence scoring.
triggers:
  - "validate consensus"
  - "consensus validation"
  - "multi-reviewer validate"
  - "unanimous validate"
---

# Validate Consensus

Spawn N (≥2, default 3) **independent** validator agents against the **same** feature, let each capture evidence blindly, then synthesize their per-journey verdicts into a single consensus verdict with a confidence score derived from the level of agreement. Disagreements trigger root-cause investigation before a final verdict is emitted.

This is ValidationForge's **execution-time agreement gate**: where `/validate` is one validator and `/validate-team` is N validators across N platforms, `/validate-consensus` is N validators against the **same** journeys. The goal is **confidence**, not **coverage**.

The authoritative contract for this command is `rules/consensus-engine.md`. In any conflict between this file and the rule, the rule wins.

## Usage

```
/validate-consensus                                  # Auto-detect platform, 3 validators, full scope
/validate-consensus --validators 5                   # 5 independent validators
/validate-consensus --scope src/auth/                # Consensus over a subset of the app
/validate-consensus --platform web                   # Force web platform; skip auto-detect
/validate-consensus --fix                            # On disagreement, apply sweep-controller fix loop
/validate-consensus --strict                         # Require UNANIMOUS_PASS to ship; fail on DISAGREEMENT_UNRESOLVED
/validate-consensus --validators 3 --platform ios --strict
```

### Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--validators N` | `3` | Number of independent validator agents. Range: `2 ≤ N ≤ 5`. Odd counts (3, 5) preferred to avoid 1:1 ties, but not required — SPLIT is handled explicitly. |
| `--scope PATH` | entire project | Limit journey discovery to files under PATH. Every validator gets the same scoped plan. |
| `--platform PLATFORM` | auto-detect | Override platform detection. Values: `ios`, `web`, `api`, `cli`, `fullstack`. |
| `--fix` | off | On disagreement (MAJORITY or SPLIT), invoke `sweep-controller` to apply the `/validate-fix` loop (max 3 attempts per journey) before re-synthesizing. |
| `--strict` | off | Require `UNANIMOUS_PASS` across all journeys to ship. Fails the run on any `MAJORITY_*` or `DISAGREEMENT_UNRESOLVED` journey, regardless of confidence tier. |

## Architecture

```
User: "/validate-consensus --validators 3 src/auth/"
              |
              v
         [COORDINATOR]  ← you (this command)
              |
              +-- preflight skill
              |       -> verify build, services, MCP servers available
              |
              +-- create-validation-plan skill
              |       -> single journey list, scoped to src/auth/
              |
              +-- skills/consensus-engine (Step 2: spawn validators)
              |       |
              |       +-- Task(name="consensus-validator", run_in_background=true) #1
              |       |       -> e2e-evidence/consensus/validator-1/
              |       |
              |       +-- Task(name="consensus-validator", run_in_background=true) #2
              |       |       -> e2e-evidence/consensus/validator-2/
              |       |
              |       +-- Task(name="consensus-validator", run_in_background=true) #3
              |               -> e2e-evidence/consensus/validator-3/
              |
              +-- Monitor loop (never interfere, never peek mid-run)
              |       <- each validator writes its own verdict.md
              |
              +-- skills/consensus-engine (Step 4: spawn synthesizer)
              |       |
              |       +-- Task(name="consensus-synthesizer")
              |               -> reads ALL validator-{N}/report.md
              |               -> applies skills/consensus-synthesis
              |               -> on disagreement: skills/consensus-disagreement-analysis
              |               -> writes e2e-evidence/consensus/report.md
              |
              +-- Emit one-line summary to stdout
                      -> "CONSENSUS: J/K PASS. Overall: {verdict} ({tier})."
```

## Workflow

The command delegates orchestration to `skills/consensus-engine`. The coordinator does **not** validate, does **not** capture evidence, and does **not** write to any validator's subdirectory. Its only responsibilities are: run preflight, spawn validators in parallel, monitor completion, spawn the synthesizer when all validators finish, and print the final summary.

The skill's protocol:

1. **Read the validation plan** — one plan, identical for all validators.
2. **Spawn ≥2 validators in parallel** — each with `run_in_background=true`, each writing to an exclusive `validator-{N}/` subdirectory.
3. **Monitor validators** — watch for completion via `TaskOutput`; never inspect mid-run evidence; never answer questions that would bias a verdict.
4. **Spawn the consensus-synthesizer** — only after **every** validator has written a non-empty `verdict.md`. Partial synthesis is forbidden.
5. **On disagreement, invoke `skills/consensus-disagreement-analysis`** — which wraps `skills/sequential-analysis` to root-cause the divergence.
6. **Emit the unified consensus report** — the synthesizer writes `e2e-evidence/consensus/report.md` using `templates/consensus-report.md`.

See `skills/consensus-engine/SKILL.md` for the full protocol.

## Agent Roles

| Role | Count | Agent | Writes To | Reads From |
|------|-------|-------|-----------|------------|
| **Coordinator** | 1 | *you (this command)* | *nothing* | `validator-{N}/verdict.md` (completion detection only) |
| **Validator** | N (≥2, default 3) | `consensus-validator` | `e2e-evidence/consensus/validator-{N}/` exclusively | source code, runtime artifacts |
| **Synthesizer** | 1 | `consensus-synthesizer` | `e2e-evidence/consensus/report.md` exclusively | all `validator-{N}/` directories |

**The coordinator owning nothing is the load-bearing invariant.** A coordinator that captures evidence has an implicit bias toward its own observations and contaminates the independence property that gives consensus its value. See `rules/consensus-engine.md §File Ownership` for the absolute ownership table.

## Evidence Structure

```
e2e-evidence/
  consensus/
    validator-1/                    ← Validator 1 ONLY (exclusive write)
      step-01-*.{png,json,txt}
      verdict.md
      report.md
      evidence-inventory.txt
    validator-2/                    ← Validator 2 ONLY
      step-01-*.{png,json,txt}
      verdict.md
      report.md
      evidence-inventory.txt
    validator-3/                    ← Validator 3 ONLY
      step-01-*.{png,json,txt}
      verdict.md
      report.md
      evidence-inventory.txt
    disagreement-analysis/          ← skills/consensus-disagreement-analysis ONLY
      step-NN-*.md
    report.md                       ← Synthesizer ONLY (unified verdict)
```

**Ownership is absolute.** A validator that writes to another validator's directory invalidates the independence guarantee and the run must be discarded. The synthesizer is strictly read-only against every `validator-{N}/`.

## Verdict Semantics

Every journey's final verdict is drawn from the synthesis state defined in `rules/consensus-engine.md §Synthesis States`:

| Synthesis State | Final Verdict | Confidence |
|-----------------|---------------|------------|
| **UNANIMOUS_PASS** | `PASS` | **HIGH** |
| **UNANIMOUS_FAIL** | `FAIL` | **HIGH** |
| **MAJORITY_PASS** (≥⅔, after analysis) | `PASS` | **MEDIUM** |
| **MAJORITY_FAIL** (≥⅔, after analysis) | `FAIL` | **MEDIUM** |
| **SPLIT** (<⅔) | `DISAGREEMENT_UNRESOLVED` | **LOW** |

**Confidence formula:**

```
majority_count  = max(pass_count, fail_count)
agreement_ratio = majority_count / total_validators

confidence = HIGH    if agreement_ratio == 1.0                 (unanimous)
confidence = MEDIUM  if agreement_ratio >= 2/3                 (after analysis resolves it)
confidence = LOW     if agreement_ratio <  2/3                 (split; unresolved)
```

**Overall run verdict follows the weakest-link rule.** One journey at `DISAGREEMENT_UNRESOLVED` forces the overall run to `DISAGREEMENT_UNRESOLVED` (LOW); otherwise the weakest per-journey confidence tier sets the overall tier. Evidence quality cannot upgrade confidence — HIGH requires unanimity regardless of how compelling one validator's evidence is.

**`--strict` behavior.** With `--strict`, anything less than `UNANIMOUS_PASS` on every journey exits non-zero. This is the recommended setting for payments, auth, data migrations, and any pre-ship gate where a dissenting validator is a stop-ship signal, not a MEDIUM-confidence merge.

## Integration

| Pairs with | Relationship |
|------------|-------------|
| `/validate` | Single-validator mode. Use for cheap, frequent validation; escalate to `/validate-consensus` when the single-validator PASS is insufficient confidence. |
| `/validate-team` | Multi-platform mode. N validators across N platforms, each with DIFFERENT journeys. Use when coverage matters more than agreement. Consensus is N validators on the SAME journeys; team is N validators on DIFFERENT journeys. |
| `/validate-sweep` | Autonomous fix loop. `--fix` delegates to the sweep controller when a MAJORITY or SPLIT journey can plausibly be fixed and re-validated within the 3-attempt limit. |
| `/validate-fix` | Used under the hood by `--fix` to apply the fix protocol to the dissenting validators' identified defects. |
| `/validate-ci` | CI/CD mode. Combines with `--strict` for pre-merge gates: `/validate-ci --consensus --validators 3 --strict`. |
| `skills/consensus-engine` | Authoritative orchestration protocol this command invokes. |
| `skills/consensus-synthesis` | Voting and confidence-scoring rules used by the synthesizer. |
| `skills/consensus-disagreement-analysis` | Root-cause investigation wrapper around `skills/sequential-analysis`. |
| `rules/consensus-engine.md` | Authoritative contract for file ownership, synthesis states, confidence formula, and iron rules. |
| `templates/consensus-report.md` | The report format emitted by the synthesizer. |

## Pre-Pipeline: Read Config

Before entering the pipeline, read the ValidationForge config written by `/vf-setup`. This mirrors the config-consumption pattern in `commands/validate.md` so all validation commands share a single source of truth for enforcement, evidence directory, and platform.

```bash
CONFIG_FILE="$HOME/.claude/.vf-config.json"

# Defaults used when config is missing (enforcement: standard, evidence_dir: e2e-evidence/)
ENFORCEMENT="standard"
EVIDENCE_DIR="e2e-evidence"
CONFIG_PLATFORM=""

if [ -f "$CONFIG_FILE" ]; then
  ENFORCEMENT=$(jq -r '.enforcement // "standard"' "$CONFIG_FILE" 2>/dev/null)
  EVIDENCE_DIR=$(jq -r '.evidence_dir // "e2e-evidence"' "$CONFIG_FILE" 2>/dev/null)
  CONFIG_PLATFORM=$(jq -r '.platform // empty' "$CONFIG_FILE" 2>/dev/null)
else
  echo "[vf] No config found at $CONFIG_FILE — using defaults (enforcement: standard, evidence_dir: e2e-evidence/)"
fi

# Apply platform from config only if --platform flag was not provided
if [ -z "${FLAG_PLATFORM:-}" ] && [ -n "$CONFIG_PLATFORM" ] && [ "$CONFIG_PLATFORM" != "null" ]; then
  PLATFORM="$CONFIG_PLATFORM"
else
  PLATFORM="${FLAG_PLATFORM:-}"
fi

# Consensus-specific root under the active evidence dir
CONSENSUS_DIR="${EVIDENCE_DIR}/consensus"

# Validator count: default 3, clamp to [2,5]
VALIDATORS="${FLAG_VALIDATORS:-3}"
if [ "$VALIDATORS" -lt 2 ] || [ "$VALIDATORS" -gt 5 ]; then
  echo "[vf] --validators must be in [2,5]; got $VALIDATORS — aborting."
  exit 2
fi

# Print active config summary when VF_VERBOSE is set
if [ -n "${VF_VERBOSE:-}" ]; then
  echo "[vf] Config: enforcement=${ENFORCEMENT} | evidence_dir=${EVIDENCE_DIR} | consensus_dir=${CONSENSUS_DIR} | platform=${PLATFORM:-auto-detect} | validators=${VALIDATORS}"
fi
```

> **Note:** If `~/.claude/.vf-config.json` is missing, defaults apply automatically:
> `enforcement: standard`, `evidence_dir: e2e-evidence/`. Run `/vf-setup` to create a config.

### Enforcement Level Behavior

The `enforcement` value gates how strictly consensus runs. Use this table to understand what each level requires:

| Behavior | `strict` | `standard` | `permissive` |
|----------|----------|------------|--------------|
| Require preflight before spawning validators | ✅ Required — stop if preflight fails | ⚠️ Recommended — warn if skipped | Optional — continue even if skipped |
| Require every validator to cite evidence on every PASS/FAIL | ✅ Required — validator PASS without citations = validator error (case d) | ✅ Required | ⚠️ Warn only |
| Fail run on `DISAGREEMENT_UNRESOLVED` | ✅ Fail — escalate to human | ⚠️ Report but continue to ship decision | Report only |
| Block test files / mocks inside validator dirs | ✅ Hard block | ✅ Hard block | ⚠️ Warn only |
| Max fix attempts per journey under `--fix` | 3 | 3 | 5 |
| Minimum validators | 3 (default) or `--validators ≥ 2` | 2 or `--validators` | 2 or `--validators` |

**Under `--strict`** (the command flag, distinct from `enforcement: strict`), any non-`UNANIMOUS_PASS` journey fails the run regardless of enforcement level. `--strict` + `enforcement: strict` is the recommended combination for pre-ship gates.

## The Iron Rule

```
IF the real system doesn't work, FIX THE REAL SYSTEM.
NEVER create mocks, stubs, test doubles, or test files.
NEVER mark a journey PASS without specific cited evidence.
NEVER allow the coordinator to write evidence — its independence is the product.
NEVER emit a partial synthesis — all N validators must complete first.
NEVER silently drop a dissenting verdict — record or escalate every time.
```

## Examples

```bash
# Default 3-validator consensus for a web app
/validate-consensus --platform web

# High-stakes pre-ship gate: 5 validators, unanimous PASS required to ship
/validate-consensus --validators 5 --strict

# Consensus over a subset of the code (the auth module only)
/validate-consensus --scope src/auth/

# Consensus with autonomous fix loop on disagreement
/validate-consensus --validators 3 --fix

# CI/CD mode: verbose summary, strict gate, 3 validators
VF_VERBOSE=1 /validate-consensus --validators 3 --strict
```

## Output

Final consensus report saved to `e2e-evidence/consensus/report.md`. Each validator's evidence lives under `e2e-evidence/consensus/validator-{N}/`. Disagreement analysis artifacts live under `e2e-evidence/consensus/disagreement-analysis/`.

Exit behavior:

- All journeys `UNANIMOUS_PASS`: report ends with `Overall Verdict: PASS (HIGH)`; exit 0.
- Any journey `MAJORITY_PASS` (resolved): report ends with `Overall Verdict: PASS (MEDIUM)`; exit 0 unless `--strict` is set.
- Any journey `MAJORITY_FAIL` or `UNANIMOUS_FAIL`: report ends with `Overall Verdict: FAIL`; exit 1.
- Any journey `DISAGREEMENT_UNRESOLVED`: report ends with `Overall Verdict: DISAGREEMENT_UNRESOLVED (LOW)`; exit 1 and escalate to human reviewer.
- `--strict` + any non-`UNANIMOUS_PASS` journey: exit 1 regardless of per-journey verdict.

One-line stdout summary for pipeline consumers:

```
ValidationForge CONSENSUS: J/K journeys PASS. Overall: {verdict} ({tier}). Report: e2e-evidence/consensus/report.md
```
