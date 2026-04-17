---
phase: P07
name: Skill deep-review sweep (38 remaining)
date: 2026-04-16
status: pending
gap_ids: [H1]
executor: researcher (parallel pool)
validator: code-reviewer
depends_on: [P06]
---

# Phase 07 — Skill Deep-Review Sweep

## Why

10 of 48 skills have received a deep review (`skill-review-results.md` April 8).
TECHNICAL-DEBT.md H1 demands the remaining 38 be reviewed to the same depth so
no skill activates spurious, misleads, or points at broken MCP tools.

Exact scope depends on decision U2 from Phase 00:
- **If U2 == "all":** review 38 skills in 5 parallel sweeps of ~8 each.
- **If U2 == "top-20":** review the 20 most-used skills; defer rest to V1.5.

## Pass criteria

1. `evidence/07-skill-review/reviewed.md` lists every reviewed skill with
   verdict column (PASS / NEEDS_FIX / FAIL).
2. Per reviewed skill: an `evidence/07-skill-review/<skill>.md` file cites:
   - Frontmatter check
   - Trigger phrase realism
   - Body-description alignment
   - Reference to external tools (MCP tool names must exist)
   - Example invocation proven (for skills with scripted examples)
3. Every `NEEDS_FIX` item has a one-line proposed patch.
4. Every `FAIL` item has a blocking issue documented; fix opens a new plan.
5. Count of reviewed skills matches U2 decision exactly (no drift).

## Inputs

- U2 decision from `logs/decisions.md`
- `skills/*/SKILL.md`
- `skill-review-results.md` (template for review format)
- `plans/reports/researcher-260416-1707-inventory-audit.md`

## Steps

1. Dispatch 3–5 parallel researcher sub-agents; each owns 8–10 skills.
2. Each sub-agent writes per-skill evidence files and contributes to the
   aggregate `reviewed.md`.
3. Dispatch validator (code-reviewer) to verify partition + fix-list.

## Evidence outputs

| File | Source |
|------|--------|
| `evidence/07-skill-review/reviewed.md` | Aggregate table |
| `evidence/07-skill-review/<skill>.md` | Per-skill review |
| `evidence/07-skill-review/assignment-map.md` | Sub-agent → skills mapping |
| `evidence/07-skill-review/needs-fix.md` | NEEDS_FIX summary |

## Failure modes

- **Parallel agents overlap:** re-partition before dispatch.
- **MCP tool name drift:** flag FAIL with proposed replacement.
- **Validator wants more detail:** add criteria and re-dispatch.

## Duration estimate

3–6 hours (parallel fan-out wall-clock).
