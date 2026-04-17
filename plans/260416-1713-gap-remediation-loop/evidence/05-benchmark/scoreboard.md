# B5 Scoreboard

**Date:** 2026-04-16
**Executor:** fullstack-developer (a4128d005b3e7d966)
**Phase:** P05 — Benchmark 5-scenario proof

---

IN-SCOPE scenarios: 0

- VF detected (FAIL verdict cites mutated path): 0 / 0
- Oracle PASSes (exit 0 on pre-existing tests): 0 / 0

OUT-OF-SCOPE scenarios: 5 — BLOCKED_WITH_USER

| id | scenario | reason |
|----|----------|--------|
| S1 | API field rename (JSON key drift) | `demo/python-api/` exists but ships zero test files. No oracle present. |
| S2 | JWT signature mismatch | No auth-capable demo exists anywhere in repo. |
| S3 | iOS deep link broken | `demo/ios-app/` absent. `benchmark/scaffolds/swift-ios/` has no app source. |
| S4 | DB migration regression | No DB-backed demo. `demo/python-api/` is in-memory only. |
| S5 | CSS overflow clipping CTA | `demo/nextjs-web/` absent. `benchmark/scaffolds/node-nextjs/` has no app source. |

---

## PASS Criteria Evaluation

| # | Criterion | Result |
|---|-----------|--------|
| 1 | `scenarios.md` lists every scenario with all 8 columns | PASS |
| 2 | Per in-scope: VF verdict = FAIL citing mutated path | N/A — N_scope = 0 |
| 3 | Per in-scope: oracle PASSes and pre-exists at HEAD^ | N/A — N_scope = 0 |
| 4 | scoreboard reports N_vf/N_scope and N_oracle/N_scope | PASS — honest 0/0 |
| 5 | OUT-OF-SCOPE recorded as BLOCKED_WITH_USER with reason | PASS — all 5 |
| 6 | No post-hoc tuning after a VF miss | PASS — no mutations attempted |

---

## Headline claim eligibility

- 5/5-vs-0/5 claim: **INELIGIBLE** — N_scope = 0; no scenario had both a real demo AND a pre-existing oracle.
- Honest ratio: VF **0/0**  Oracle **0/0** (no runnable scenarios)

---

## Root cause of infrastructure gap

The `SPECIFICATION.md` §"Why Not Unit Tests?" table asserts the 5/5-vs-0/5 result as
fact, but the supporting infrastructure was never committed:

1. `benchmark/scaffolds/*/` — all 8 dirs contain only `.claude/settings.json` and
   `.vf/benchmarks/*.json`. No application source, no executables, no test suites.

2. `demo/python-api/` — only real demo; Flask app with no test files at all.
   Could host S1 (field rename) but has no oracle → still BLOCKED_WITH_USER.

3. Iron Rule prevents this campaign from authoring oracles. Scenarios cannot be
   unblocked here; they require pre-existing tests committed before this campaign.

---

## Required P13 follow-up stubs

| stub_id | scenario | action_required |
|---------|----------|-----------------|
| P13-S1 | API field rename | Add `tests/test_api.py` to `demo/python-api/` that exercises the live server and asserts field names; commit before re-running P05. |
| P13-S2 | JWT signature mismatch | Create `demo/python-api-auth/` with JWT endpoints + pre-committed `tests/test_jwt.py`. |
| P13-S3 | iOS deep link | Populate `benchmark/scaffolds/swift-ios/` with minimal Xcode project + XCTest oracle. |
| P13-S4 | DB migration | Extend `demo/python-api/` with SQLAlchemy + Alembic + `tests/test_migration.py` pre-committed. |
| P13-S5 | CSS overflow | Populate `benchmark/scaffolds/node-nextjs/` with Next.js app + Playwright spec pre-committed. |

---

## Phase verdict

**P05 status: FAIL** — B5 gap remains OPEN.

N_scope = 0. The 5/5-vs-0/5 competitive claim in `SPECIFICATION.md` and
`COMPETITIVE-ANALYSIS.md` is empirically **UNPROVEN**. Those documents MUST NOT
present this ratio as a benchmark result until P13 stubs resolve and P05 re-runs
with N_scope ≥ 1.
