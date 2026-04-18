# Phase C1 Evidence — Shared State + Checkpoint Library

**Date:** 2026-04-18  
**Branch:** insights/phase-0-schema-freeze

---

## 1. Harness Output (4/4 PASS)

```
[scenario a] write-valid-read-back
HARNESS PASS: (a) write-valid-read-back — campaignId=1776473450400-ab12cd baselineScore=7/8

[scenario b] write-invalid-expect-structured-error
HARNESS PASS: (b) write-invalid-expect-structured-error — 1 error(s) — field "lastUpdated": missing required field

[scenario c] atomic-crash-sim
HARNESS PASS: (c) atomic-crash-sim — V1 intact (baselineScore=5/8), orphaned .tmp present=true

[scenario d] append-failed-approaches-order
HARNESS PASS: (d) append-failed-approaches-order — A@48 < B@138 — correct insertion order

────────────────────────────────────────────────────────────
Scenarios: 4 passed, 0 failed
HARNESS PASS: all 4/4 scenarios
```

---

## 2. Lib Line Count

```
137 ~/.claude/scripts/common/checkpoint-lib.js
```

✅ Under 200-line limit.

---

## 3. checkpoints.log — WRITE entries after harness run

```
2026-04-18T00:50:50.402Z WRITE /var/folders/.../vf-checkpoint-harness-34355/gt-a.json 9b59df1823e17f33
2026-04-18T00:50:50.402Z WRITE /var/folders/.../vf-checkpoint-harness-34355/gt-c.json cf3074f613d5b0b7
```

`grep -c WRITE ~/.claude/state/checkpoints.log` → **2** (scenarios a + c each called writeCheckpoint once).

---

## 4. Schema Coverage vs Spec §5

Phase 0 schemas at `~/.claude/state/schemas/` were inspected. They cover all spec §5 requirements and are richer than the sketches (additional fields, validated `campaignId` patterns). **No changes needed** — preserved as canonical.

| Schema | $id | Required fields | Status enum | Pattern |
|--------|-----|----------------|-------------|---------|
| gt-campaign | ✓ | schemaVersion, campaignId, targetRepo, iterations, baselineScore, currentScore, lastUpdated | — | `^[0-9]{13}-[a-f0-9]{6}$` |
| audit-campaign | ✓ | schemaVersion, campaignId, targetRepo, bugs, currentPhase, lastUpdated | scout/fix/review/complete | `^[0-9]{13}-[a-f0-9]{6}$` |
| debug-checkpoint | ✓ | schemaVersion, campaignId, targetRepo, hypotheses, fixesAttempted, currentState, lastUpdated | pending/confirmed/rejected | `^[a-f0-9]{12}$` |

---

## 5. CLI Smoke Test

```bash
$ node ~/.claude/scripts/common/checkpoint-lib-cli.js append-failed-approach \
    cli-smoke-test '{"hypothesis":"cli test","outcome":"pending"}'
appended to /private/tmp/.debug/cli-smoke-test/failed-approaches.md

$ cat /tmp/.debug/cli-smoke-test/failed-approaches.md
## 2026-04-18T00:51:54.651Z

- **hypothesis**: cli test
- **outcome**: pending

---
```

✅ CLI `append-failed-approach` subcommand works end-to-end.

---

## 6. Deliverables

| File | Status | Notes |
|------|--------|-------|
| `~/.claude/scripts/common/checkpoint-lib.js` | ✅ created | 137 LOC, stdlib only |
| `~/.claude/scripts/common/checkpoint-lib.test-harness.js` | ✅ created | 4/4 scenarios pass |
| `~/.claude/scripts/common/checkpoint-lib-cli.js` | ✅ created | append-failed-approach verified |
| `~/.claude/state/README.md` | ✅ created | schemas section + invariants |
| schemas (3×) | ✅ preserved | Phase 0 canonical, no changes needed |

---

## 7. Fix Applied During Implementation

**Root cause:** hand-rolled validator mapped `"type":"integer"` against JS `typeof` which returns `"number"` for all numeric values. Fix: `types.some(t => t === actual || (t === 'integer' && actual === 'number' && Number.isInteger(val)))`.
