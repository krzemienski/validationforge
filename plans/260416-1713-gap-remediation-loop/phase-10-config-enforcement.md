---
phase: P10
name: Config profile enforcement
date: 2026-04-16
status: pending
gap_ids: [M7]
executor: fullstack-developer
validator: code-reviewer
depends_on: [P02, P09]
---

# Phase 10 — Config Profile Enforcement Wiring

## Why

Three enforcement profiles exist: `config/strict.json`, `config/standard.json`,
`config/permissive.json`. Hooks run unconditionally — none read the active
profile. TECHNICAL-DEBT.md M7: config disconnected from runtime.

## Pass criteria

<validation_gate id="VG-10" blocking="true">
  <prerequisites>
    - P02 verdict = PASS (hook inventory frozen)
    - P09 verdict = PASS (cleanup+lock ready; prevents collision with this phase)
    - `config/{strict,standard,permissive}.json` exist and parse as valid JSON
  </prerequisites>

  <schema_correction note="Reality check 2026-04-16">
    Original draft invented a triple "block / ask / advisory". The actual schema
    in `config/*.json` uses `"enabled" | "warn" | "disabled"` per hook plus
    per-profile boolean `rules.*`. Evidence from disk:
      - `config/standard.json:19-27` — every hook `"enabled"`
      - `config/permissive.json:19-27` — `block-test-files: "warn"`,
        `evidence-quality-check: "disabled"`, most others `"warn"`
      - `config/strict.json:19-27` — every hook `"enabled"`
        (strictness comes from `rules.*`, not hook state)
    This phase implements the REAL schema. The invented `"ask"` state is REMOVED.
  </schema_correction>

  <pass_criteria>
    1. Every hook in `hooks/hooks.json` reads the active profile BEFORE enforcing.
       Resolver (lives at `hooks/lib/resolve-profile.js` or equivalent; cite the
       line number) uses precedence:
         env `VF_PROFILE` > `~/.claude/.vf-config.json` `strictness` > `config/standard.json`
       Per-hook behavior by resolver result:
         - `"enabled"` AND matching `rules.<feature>=true` → block (exit 2) + stderr reason
         - `"enabled"` AND matching `rules.<feature>=false` → advisory (exit 0) + stderr note
         - `"warn"` → advisory (exit 0) regardless of `rules.<feature>`
         - `"disabled"` → exit 0 silently, no action
    2. Resolver falls back to `config/standard.json` when no user config found.
       Evidence: `evidence/10-config-profiles/resolver-fallback.txt` captures a
       run with `HOME=/tmp/empty-home` and cites which profile was selected.
    3. Per-profile demonstration with a synthetic probe under `/tmp/`:
       ```
       mkdir -p /tmp/vf-profile-demo/src
       cat > /tmp/vf-profile-demo/src/probe.ts <<'EOF'
       import { jest } from '@jest/globals';
       jest.mock('./fake');
       EOF
       for P in strict standard permissive; do
         VF_PROFILE=$P node hooks/mock-detection.js < test-payload.json \
           2> evidence/10-config-profiles/$P-demo.txt
         echo "exit=$?" >> evidence/10-config-profiles/$P-demo.txt
       done
       ```
       Validator greps:
         - `strict-demo.txt`: contains "BLOCK" OR `exit=2`
         - `standard-demo.txt`: contains "BLOCK" OR `exit=2`
           (standard.json:11 has `block_mock_patterns: true`)
         - `permissive-demo.txt`: contains "warn" (case-insensitive) AND `exit=0`
    4. Existing override env vars (`DISABLE_OMC`, `VF_SKIP_HOOKS`) still work
       AND take precedence over profile state. Evidence:
       `evidence/10-config-profiles/env-override-demo.txt` shows
       `DISABLE_OMC=1 VF_PROFILE=strict` → hook exits 0 silently.
    5. No regression in Phase 02 registrations:
       `evidence/10-config-profiles/regression-check.md` re-runs each smoke
       invocation from P02 under `standard` profile and reports structurally
       equivalent output (same blocking behavior, same matchers firing).
    6. Rollback tested (not just documented):
       ```
       git stash   # stash P10 hook edits
       VF_PROFILE=standard node hooks/block-test-files.js < test-payload.json
       git stash pop
       ```
       Evidence: `evidence/10-config-profiles/rollback-demo.txt` shows hooks
       still functional without P10 code (proving clean revert path exists).
  </pass_criteria>

  <review>
    Validator: (a) opens the resolver file and cites the env-precedence site;
    (b) cats each per-profile demo, greps expected literals; (c) cats env-override
    demo; (d) diffs regression-check against P02 outputs and asserts behavioral
    equivalence; (e) confirms rollback transcript shows pre-P10 behavior restored.
  </review>
  <verdict>
    PASS → advance P11. FAIL → escalate.
    CRITICAL: if ANY hook stops firing under `standard` profile (regression),
    revert the P10 commit immediately before continuing.
  </verdict>
  <mock_guard>
    Probe files live at `/tmp/vf-profile-demo/src/probe.ts` — NOT inside
    ValidationForge sources. block-test-files.js does not fire on them
    (correct — they're not in this repo's src/lib), but mock-detection flags
    the `jest.mock` content correctly. No test files authored inside this repo.
  </mock_guard>
</validation_gate>

### Per-hook behavior matrix

Not every hook supports every state meaningfully. This matrix is the ground
truth (derived from actual hook scripts and hooks/hooks.json):

| Hook | Blocking trigger | `"warn"` meaning | `"disabled"` meaning |
|------|------------------|------------------|----------------------|
| block-test-files | test-file path under src/lib | stderr + exit 0 | skip entirely |
| mock-detection | jest.mock/sinon/.stub | stderr + exit 0 | skip entirely |
| evidence-gate-reminder | never blocks (advisory) | identical to enabled | skip injection |
| validation-not-compilation | never blocks (advisory) | identical | skip |
| completion-claim-validator | never blocks (advisory) | identical | skip |
| validation-state-tracker | never blocks (state only) | no stderr | skip state writes |
| evidence-quality-check | empty evidence files | stderr + exit 0 | skip entirely |

For the 4 never-blocking hooks, `"warn"` ≡ `"enabled"` — they were always
advisory. The resolver doc MUST state this honestly: `rules.*` booleans matter
only for the 3 gating hooks (block-test-files, mock-detection, evidence-quality-check).
Everything else is stderr discipline irrespective of profile.

## Inputs

- `config/strict.json`, `config/standard.json`, `config/permissive.json`
- `~/.claude/.vf-config.json` (user config)
- All hook files under `hooks/`
- `hooks/config-loader.js` — if Phase 02 REGISTERED this, leverage it

## Steps

1. Dispatch executor.
2. Executor introduces / confirms shared profile-resolution helper.
3. Executor patches each enforcing hook to consult profile + alter behaviour.
4. Executor demonstrates:
   - `VF_PROFILE=strict` → block
   - `VF_PROFILE=standard` → ask
   - `VF_PROFILE=permissive` → advisory
5. Dispatch validator.

## Evidence outputs

| File | Source |
|------|--------|
| `evidence/10-config-profiles/hook-patches.patch` | code diffs |
| `evidence/10-config-profiles/strict-demo.txt` | strict output |
| `evidence/10-config-profiles/standard-demo.txt` | standard output |
| `evidence/10-config-profiles/permissive-demo.txt` | permissive output |
| `evidence/10-config-profiles/regression-check.md` | Phase 02 sanity |

## Failure modes

- No single resolver → refactor to `hooks/lib/resolve-profile.js`.
- Profile switch has no effect → verify config path (`$HOME` vs `~`).
- Env overrides broken → restore precedence: env > profile > default.

## Duration estimate

3–5 hours.
