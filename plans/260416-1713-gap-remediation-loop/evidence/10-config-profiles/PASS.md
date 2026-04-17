# VG-10 PASS Evidence

## Criterion 1 — Resolver env-precedence + 3 hooks patched

Resolver at `hooks/lib/resolve-profile.js`.
Env-precedence at **line 68** (`[precedence-1]`):
```
const envVal = (process.env.VF_PROFILE || '').trim().toLowerCase();
if (VALID.includes(envVal)) { ... source: 'env:VF_PROFILE' }
```
Three gating hooks patched to use `resolveProfile()`/`hookState()`/`ruleEnabled()`:
- `hooks/block-test-files.js`
- `hooks/mock-detection.js`
- `hooks/evidence-quality-check.js`

## Criterion 2 — Fallback to standard when no user config

`resolver-fallback.txt` run with `HOME=/tmp/empty-home VF_PROFILE=""`:
- `"source": "fallback:standard"`
- `"name": "standard"`

## Criterion 3 — Per-profile demos

| Profile | exit | Behavior |
|---------|------|----------|
| strict  | 2    | BLOCK — `[strict]` tag in stderr, `block_mock_patterns=true` |
| standard | 2   | BLOCK — `[standard]` tag in stderr, `block_mock_patterns=true` |
| permissive | 0 | WARN — `[permissive]` tag in stderr, `mock-detection: "warn"` in permissive.json |

Evidence: `strict-demo.txt`, `standard-demo.txt`, `permissive-demo.txt`

## Criterion 4 — DISABLE_OMC wins over VF_PROFILE=strict

`env-override-demo.txt`: `DISABLE_OMC=1 VF_PROFILE=strict` → exit=0, empty stdout, empty stderr.

## Criterion 5 — P02 regression under standard

`regression-check.md`:
| Hook | exit | Method |
|------|------|--------|
| block-test-files (`/myproject/src/auth.test.ts`) | 0 + stdout `permissionDecision:deny` | PreToolUse CC protocol |
| mock-detection (`jest.mock` content) | 2 | hard block |
| evidence-quality-check (empty e2e-evidence file) | 2 | hard block |

Note: `block-test-files` uses `permissionDecision:"deny"` via stdout (not exit 2) per CC PreToolUse
protocol. ALLOWLIST correctly excludes `validationforge/` paths (plugin self-exemption).

## Criterion 6 — Rollback tested

`rollback-demo.txt`:
- `git stash` removed P10 code (resolve-profile.js untracked, hook edits reverted)
- Pre-P10 hook output: `BLOCKED: "..."` (no `[standard]` profile tag — proving pre-P10 code ran)
- `git stash pop` restored P10 code cleanly
- Both stash and pop: exit=0

## 4 never-blocking hooks — not patched (correct per phase matrix)

`evidence-gate-reminder`, `validation-not-compilation`, `completion-claim-validator`,
`validation-state-tracker` are advisory-only. For these hooks `"warn"` ≡ `"enabled"` —
they never exit 2. `rules.*` booleans have no effect on them. They remain on `config-loader.js`
and do not require patching.

## Verdict: PASS
