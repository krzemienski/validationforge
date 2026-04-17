# Campaign Decisions Log

Captured via `AskUserQuestion` at campaign start (P00 preflight).
Date: 2026-04-16
Source: main orchestrator (user prompt in `/cook` invocation).

---

U1: test
U2: all
U3: drop

---

## Rationale (verbatim from question copy)

### U1 — CONSENSUS + FORGE engines (test)

> Run `/validate-team` 3-validator staging + `/forge-execute` (≤3 iterations)
> on a P05 in-scope defect. Requires engines work end-to-end today.

Branch selected in P08 → TEST. Defer path NOT taken. Phase 08 executor will be
`fullstack-developer`; no doc-scrub required.

### U2 — Phase 07 skill deep-review scope (all)

> Review every SKILL.md body (38 skills). More thorough, more parallel
> researcher work.

Phase 07 must partition all 38 skills across 3–5 parallel researcher sub-agents.
No top-20 shortcut. Aggregate `reviewed.md` row count must equal disk skill
count frozen by P03.

### U3 — Spec 015 quarantined branch disposition (drop)

> Delete the quarantine branch; matrix closes with DROP rationale. Fastest path.

Phase 11 executor (`researcher`) must: discover the quarantine branch, write
`docs/SPEC-015-DISPOSITION.md` with DROP rationale, delete the branch, update
`VALIDATION_MATRIX.md` + `CAMPAIGN_STATE.md`. No cherry-pick commits.

---

## Binding

These answers are BLOCKING for P00, P07, P08, P11. Any executor or validator
encountering a decision-dependent step MUST read this file first and honor the
literal answer. Changes require a new AskUserQuestion round and an addendum
section appended below this line (never overwrite).
