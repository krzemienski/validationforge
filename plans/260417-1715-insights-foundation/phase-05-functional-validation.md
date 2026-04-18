# Phase 05 — Functional Validation

## Context Links
- Plan: `plans/260417-1715-insights-foundation/plan.md`
- Phase 3 (target under test): `phase-03-posttooluse-syntax-check-hook.md`
- Phase 4 (target under test): `phase-04-context-threshold-warn-and-checkpoint-scaffolding.md`
- VF validation discipline: `~/.claude/rules/vf-validation-discipline.md`
- Evidence management: `~/.claude/rules/vf-evidence-management.md`
- Hook protocol (exit-code semantics): `~/.claude/plugins/cache/superpowers-marketplace/superpowers-developing-for-claude-code/0.3.1/skills/working-with-claude-code/references/hooks.md` (sections "Simple: Exit Code" and "Exit Code 2 Behavior")

## Overview
- **Priority:** P1 (final gate — blocks marking Plan A complete)
- **Status:** draft
- **Description:** Exercise the two new hooks and the checkpoint schemas against REAL edits and REAL prompts. Capture stderr/stdout, exit codes, and timing. Write a functional-validation report under `plans/reports/`. No unit tests, no mocks — real hook binaries, real stdin JSON, real compiler invocations.

## Key Insights
- Validation runs the hooks as the shell actually invokes them: `cat fake-input.json | node ~/.claude/hooks/<hook>.js`. This is the exact invocation path Claude Code uses.
- Evidence captured: stderr text, exit code, wall-clock duration. Each test produces one `step-NN-*.txt` file under a dedicated evidence directory.
- Two classes of tests per hook: POSITIVE (hook should fire) and NEGATIVE (hook should silent-pass). Each must be exercised.
- Schemas are validated with `ajv` CLI if available, else `python3 -c "import json; json.load(...)"` for structural-parse-only. Semantic schema validation is light-touch.
- No CI/CD harness — this is a one-time validation run against a local dev machine.

## Requirements
### Functional
- Evidence directory: `plans/260417-1715-insights-foundation/reports/e2e/` with subdirs per hook.
- Report file: `plans/260417-1715-insights-foundation/reports/functional-validation-260417.md`.
- Each test captures: input JSON (stdin fixture), stderr output, stdout output, exit code, duration.
- Tests run synchronously from a shell session; outputs saved to files, not kept in memory.
- The report cites every evidence file path and the observed vs expected delta.

### Non-functional
- No test framework (per VF no-mocks mandate). No `jest`, `mocha`, `pytest`.
- No test/spec file creation.
- Fixtures are scratch `.py` / `.js` files in `/tmp/`, deleted after capture.
- Total validation runtime < 2 minutes.

## Architecture

### Evidence directory layout
```
plans/260417-1715-insights-foundation/reports/
├── functional-validation-260417.md          (final report)
├── phase-01-diffstat.txt                    (from Phase 1)
├── phase-02-filelist.txt                    (from Phase 2)
└── e2e/
    ├── syntax-check-after-edit/
    │   ├── step-01-py-valid-silent.txt       (exit 0, empty stderr)
    │   ├── step-02-py-syntax-error-blocked.txt
    │   ├── step-03-js-valid-silent.txt
    │   ├── step-04-js-syntax-error-blocked.txt
    │   ├── step-05-md-file-silent.txt        (non-source skip)
    │   ├── step-06-missing-file-silent.txt
    │   ├── step-07-dash-prefix-guard.txt     (security — path starts with '-')
    │   └── evidence-inventory.txt
    ├── context-threshold-warn/
    │   ├── step-01-small-transcript-silent.txt
    │   ├── step-02-large-transcript-warns.txt
    │   ├── step-03-kill-switch-silent.txt
    │   ├── step-04-env-threshold-override.txt
    │   └── evidence-inventory.txt
    └── schemas/
        ├── step-01-debug-schema-parses.txt
        ├── step-02-audit-schema-parses.txt
        ├── step-03-debug-example-valid.txt
        ├── step-04-debug-example-invalid-rejected.txt
        └── evidence-inventory.txt
```

### Test matrix — syntax-check-after-edit
| # | Input | Expected exit | Expected stderr | Expected stdout |
|---|-------|---------------|-----------------|-----------------|
| 1 | Valid `.py` file (`print('ok')`) | 0 | empty | empty |
| 2 | Invalid `.py` file (`def f(:`) | 2 | compiler error cites filename | empty |
| 3 | Valid `.js` file (`const x = 1;`) | 0 | empty | empty |
| 4 | Invalid `.js` file (`const x =;`) | 2 | `node --check` error | empty |
| 5 | `.md` file (any content) | 0 | empty | empty |
| 6 | `file_path` pointing to non-existent file | 0 | empty | empty |
| 7 | `file_path` starting with `-` (e.g. `-rm`) | 0 | empty | empty (security guard) |

### Test matrix — context-threshold-warn
| # | Setup | Expected exit | Expected stdout contains |
|---|-------|---------------|--------------------------|
| 1 | Small transcript (e.g. 1KB file, window=200000) → ~0.001% | 0 | nothing |
| 2 | Large transcript (e.g. 600KB file, window=700000) → ~85% | 0 | `CONTEXT CHECKPOINT`, `%` |
| 3 | `DISABLE_OMC=1` + large transcript | 0 | nothing |
| 4 | `CONTEXT_WARN_THRESHOLD=30` + ~40% transcript | 0 | `CONTEXT CHECKPOINT` |

### Test matrix — schemas
| # | Action | Expected |
|---|--------|----------|
| 1 | `jq '.' debug-checkpoint.schema.json` | exit 0 |
| 2 | `jq '.' audit-checkpoint.schema.json` | exit 0 |
| 3 | Valid example `debug-checkpoint.json` against schema (via `ajv validate` if present) | pass |
| 4 | Invalid example (missing `hypotheses` field) | rejected |

### Fixture generation commands
```bash
# Valid Python
cat > /tmp/vf-ok.py <<'EOF'
print('ok')
EOF

# Invalid Python
cat > /tmp/vf-bad.py <<'EOF'
def f(:
EOF

# Valid JS
cat > /tmp/vf-ok.js <<'EOF'
const x = 1;
console.log(x);
EOF

# Invalid JS
cat > /tmp/vf-bad.js <<'EOF'
const x =;
EOF

# Small transcript (<60% of 200000-token window)
echo '{"role":"user","content":"hi"}' > /tmp/vf-small-transcript.jsonl

# Large transcript (>85% of 200000-token window → ~600KB)
python3 -c "print('{\"role\":\"user\",\"content\":\"' + 'x'*600000 + '\"}')" \
  > /tmp/vf-large-transcript.jsonl
```

### Invocation pattern (per test)
```bash
STEP=step-02-py-syntax-error-blocked
EVIDENCE=plans/260417-1715-insights-foundation/reports/e2e/syntax-check-after-edit
mkdir -p "$EVIDENCE"

INPUT='{"hook_event_name":"PostToolUse","tool_name":"Write","tool_input":{"file_path":"/tmp/vf-bad.py"}}'

{
  echo "=== INPUT ==="
  echo "$INPUT"
  echo "=== INVOCATION ==="
  echo 'echo "$INPUT" | node ~/.claude/hooks/syntax-check-after-edit.js'
  echo "=== STDERR ==="
  START=$(date +%s%N)
  echo "$INPUT" | node ~/.claude/hooks/syntax-check-after-edit.js 2> /tmp/vf-stderr.txt
  EXIT=$?
  END=$(date +%s%N)
  cat /tmp/vf-stderr.txt
  echo "=== EXIT CODE ==="
  echo "$EXIT"
  echo "=== DURATION (ms) ==="
  echo $(( (END - START) / 1000000 ))
} > "$EVIDENCE/$STEP.txt" 2>&1

# Assertion (captured in report)
if [ "$EXIT" = "2" ]; then echo "PASS: $STEP"; else echo "FAIL: $STEP (expected 2, got $EXIT)"; fi
```

### Report template (`functional-validation-260417.md`)
```markdown
# Functional Validation — Plan A (Insights Foundation)

**Date:** 2026-04-17
**Run ID:** 260417-functional-validation-01
**Validator:** nick

## Scope
Exercise the two new hooks (`syntax-check-after-edit.js`,
`context-threshold-warn.js`) and the two JSON Schemas against real inputs.
No mocks, no test frameworks.

## Results Summary
| Component | Tests | Passed | Failed |
|-----------|-------|--------|--------|
| syntax-check-after-edit | 7 | <N> | <N> |
| context-threshold-warn  | 4 | <N> | <N> |
| schemas                 | 4 | <N> | <N> |
| **Total**               | 15 | <N> | <N> |

## Per-Test Results
(one row per test citing evidence file, observed vs expected)

### syntax-check-after-edit
- step-01 — valid .py silent-pass — PASS — `e2e/syntax-check-after-edit/step-01-py-valid-silent.txt`
  - Expected: exit 0, empty stderr
  - Observed: exit <N>, stderr=<text>
- ... (one bullet per step)

### context-threshold-warn
- ... (one bullet per step)

### schemas
- ... (one bullet per step)

## Verdict
[ ] PASS — all 15 tests matched expected exit codes and output patterns.
[ ] FAIL — <component> tests failed; see <evidence paths>.

## Environment
- Node: `node --version`
- Python: `python3 --version`
- Claude Code: `claude --version`
- CLAUDE_CODE_AUTO_COMPACT_WINDOW: 700000

## Unresolved items
(any test that was skipped or inconclusive, with reason)
```

## Related Code Files
### Create
- `plans/260417-1715-insights-foundation/reports/functional-validation-260417.md`
- `plans/260417-1715-insights-foundation/reports/e2e/syntax-check-after-edit/step-*.txt` (7 files + inventory)
- `plans/260417-1715-insights-foundation/reports/e2e/context-threshold-warn/step-*.txt` (4 files + inventory)
- `plans/260417-1715-insights-foundation/reports/e2e/schemas/step-*.txt` (4 files + inventory)

### Modify
- None.

### Delete
- Temporary fixtures in `/tmp/` (cleanup at end of phase).

## Implementation Steps
1. Verify prerequisites: `node --version` ≥ 16, `python3 --version` ≥ 3.8, `jq` available.
2. Create evidence directory tree: `mkdir -p plans/260417-1715-insights-foundation/reports/e2e/{syntax-check-after-edit,context-threshold-warn,schemas}`.
3. Generate fixtures in `/tmp/` per the commands above.
4. Run syntax-check tests 1–7 sequentially; capture to `step-NN-*.txt`.
5. Run context-threshold tests 1–4; capture.
6. Validate schemas parse; optionally use `ajv` CLI for example validation (if `command -v ajv` succeeds).
7. Write `evidence-inventory.txt` in each subdir via `ls -la *.txt > evidence-inventory.txt && wc -c *.txt >> evidence-inventory.txt`.
8. Compose `functional-validation-260417.md` filling in observed values from each step file.
9. Tally PASS / FAIL counts.
10. Mark plan.md success criteria checkboxes if all tests pass.
11. Clean up `/tmp/vf-*` fixtures.
12. Gate: if ANY test fails, STOP. File issues per hook, re-plan, do not merge.

## Todo List
- [ ] Confirm prerequisites (node, python3, jq)
- [ ] Create evidence directory tree
- [ ] Generate fixtures in /tmp/
- [ ] Run syntax-check tests 1–7
- [ ] Run context-threshold tests 1–4
- [ ] Validate schemas (jq parse + optional ajv)
- [ ] Write per-dir evidence-inventory.txt
- [ ] Compose functional-validation-260417.md report
- [ ] Mark PASS/FAIL per test
- [ ] Clean up /tmp fixtures
- [ ] Gate: halt if any test failed

## Success Criteria
- [ ] `ls plans/260417-1715-insights-foundation/reports/e2e/syntax-check-after-edit/*.txt | wc -l` ≥ 8 (7 steps + inventory).
- [ ] `ls plans/260417-1715-insights-foundation/reports/e2e/context-threshold-warn/*.txt | wc -l` ≥ 5 (4 steps + inventory).
- [ ] `ls plans/260417-1715-insights-foundation/reports/e2e/schemas/*.txt | wc -l` ≥ 5.
- [ ] Every step file contains non-empty `=== EXIT CODE ===` section.
- [ ] Every step file contains `=== DURATION (ms) ===` value < 15000 (15s max per invocation).
- [ ] `functional-validation-260417.md` exists and contains a Results Summary table with actual numbers.
- [ ] Report verdict is **PASS** (15/15) for Plan A to be marked complete.
- [ ] No test/mock/spec files created during validation (`find plans -name '*.test.*' -o -name '*.spec.*'` returns empty).
- [ ] Temporary fixtures in `/tmp/vf-*` cleaned up at end.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| `node --check` exit conventions differ across Node versions | Low | Med | Capture `node --version` in environment section; rerun if mismatched. |
| `python3 -m py_compile` writes `__pycache__` in test fixture dir | High | Low | `cd /tmp` before invocation; `rm -rf /tmp/__pycache__` in cleanup. |
| Context-threshold test 2 (large transcript) takes too long to generate | Low | Low | Use `python3 -c "print('x'*N)"` — O(1) in wall-clock for 600KB. |
| `ajv` not installed; schema semantic validation skipped | High | Low | jq parse-check is sufficient for structural validity; mark ajv-dependent tests as "skipped, reason: ajv not installed" in the report. |
| Hook output format changes between phase plan and implementation | Med | High | Phase 5 is run AFTER Phases 3+4 complete — validates whatever was actually shipped, not the spec. |
| User has CLAUDE_CODE_AUTO_COMPACT_WINDOW set differently → pct math shifts | Low | Low | Tests capture actual env var value; threshold tests use explicit overrides to pin expectations. |
| A hook throws an uncaught exception | Low | High | Report captures non-zero exit with stderr; that IS a failed test — gate halts merge. |
| Evidence files exceed retention period during review | Low | Low | `vf-evidence-management.md` says 30-day default retention; review happens within hours. |

## Security Considerations
- Fixtures are scratch files in `/tmp/` — world-writable but no secrets in content.
- No credentials referenced in tests. No network calls (except possible `ajv` via npx — avoided; use installed-or-skip).
- Test runner shells pipe plain JSON to hook stdin; no `eval`, no `sh -c` with untrusted content.
- File path `-` prefix guard test (step-07) specifically validates the argv-injection defense from Phase 3.
- `DISABLE_OMC=1` kill-switch test (context-threshold step-03) validates the opt-out path works; important for users debugging hook misbehavior.

## Next Steps
- If PASS: mark Plan A success criteria checkboxes in `plan.md`; set plan status to `completed`; proceed to Plan B authoring.
- If FAIL: file regression issue per failing test; re-open Phase 3 or Phase 4 as needed; re-run Phase 5.
- Retention: evidence files kept 30 days per `vf-evidence-management.md`; archive tarball before any `/validate --clean`.

## Unresolved Questions
- Should Phase 5 also run the hooks AGAINST an actual Claude Code session (observation mode), rather than only as a standalone CLI pipe? Would provide higher-fidelity evidence at the cost of session-noise pollution.
- Should we pin expected stderr substrings ("py_compile" / "SyntaxError") or only assert exit code? Substring pinning catches format drift but is brittle across Python versions. Ship exit-code-only for v1.
- Ajv vs. jsonschema (Python) for schema example validation — does the user have a preference? jsonschema (`pip install jsonschema`) is more commonly installed than `ajv-cli`. Use whichever is present; skip-with-reason if neither.
