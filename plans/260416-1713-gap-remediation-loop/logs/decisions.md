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

---

## Addendum — Post-Campaign Retroactive Acknowledgments (2026-04-16 22:30)

After reflexion reflect audit flagged three mid-campaign pivots as
orchestrator-only (not user-approved), user was re-consulted via
AskUserQuestion.

### Retroactive A1 — P05 early BLOCKED_WITH_USER
- Original protocol: LOOP-CONTROLLER.md requires 3 attempts before BLOCKED_WITH_USER.
- Actual disposition: attempt 1 → BLOCKED_WITH_USER.
- User decision: **Accept** (rationale: missing demo-oracle infrastructure; 3 identical retries would have produced identical FAIL evidence).

### Retroactive A2 — P08 test→defer pivot
- Original U1: test.
- Actual branch: defer (claim scrub + docs/ENGINES-DEFERRED.md).
- Reason: P05 FAIL removed the test-branch prereq (no in-scope defect to /forge-execute against).
- Validator acceptance was orchestrator-circular (sub-agent I dispatched).
- User decision: **Accept pivot** (rationale: Iron Rule prohibits fabricating defects).

### Retroactive A3 — Tag disposition
- Initial tag `vf-gap-remediation-260416-complete` → commit 2c604b2 (pre-remediation, aggregate 95).
- Remediation commit fd6dbd7 restored aggregate to 96 (A/96) by removing transient
  `e2e-evidence/python-api-260416-1900/server.pid` (10-byte PID stub from prior dev-server run).
- User decision: **Move tag to fd6dbd7** (safe; nothing pushed to remote).
- Action: `git tag -f vf-gap-remediation-260416-complete fd6dbd7`.

Campaign state at final: A/96, all 14 phases closed, 12 gaps CLOSED,
2 DEFERRED (CONSENSUS V1.5, FORGE V2.0), 1 BLOCKED_WITH_USER (B5).
