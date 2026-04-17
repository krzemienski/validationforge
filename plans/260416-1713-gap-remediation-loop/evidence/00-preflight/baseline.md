# P00 Baseline Snapshot

**Date:** 2026-04-16  
**Executor:** researcher (P00 preflight scan)  
**Status:** PASS criteria verification

---

## Git State

**Branch:** main  
**HEAD SHA:** 689fcdd759a7b5bb5ab052d2f04338f8dcf20609  
**Status:** Clean (modified files: .DS_Store, .vf/benchmarks/benchmark-2026-04-11.json tracked; untracked: plans/ dirs + reports/)

---

## Benchmark History

**Latest benchmark file:** `.vf/benchmarks/benchmark-2026-04-11.json`  
**Timestamp:** 2026-04-12T01:20:42Z  
**Grade:** A  
**Total Score:** 96/100  

**Breakdown:**
- Coverage: 95/100 (35% weight) — 8 journeys validated, 64 plans found
- Evidence Quality: 100/100 (30% weight)
- Enforcement: 100/100 (25% weight)
- Speed: 80/100 (10% weight)

---

## Inventory Counts (Disk)

| Category | Count | Source |
|----------|-------|--------|
| Skills | 48 | `ls -1 skills/` |
| Commands | 17 | `ls -1 commands/*.md` |
| Hooks | 10 | `find hooks/ -type f -name *.{js,cjs}` |
| Agents | 5 | `ls -1 agents/` |
| Rules | 8 | `ls -1 rules/` |

---

## CLAUDE.md Claimed vs Disk Inventory

Per `/Users/nick/Desktop/validationforge/CLAUDE.md` lines 130–194 (Inventory section):
- Commands: claimed **16**, disk **17** (+1 mismatch)
- Skills: claimed **46**, disk **48** (+2 mismatch)
- Hooks: claimed **7**, disk **10** (+3 mismatch — 3 orphans)
- Agents: claimed **5**, disk **5** ✓
- Rules: claimed **8**, disk **8** ✓

---

## Active Plan State (260411-2305-gap-validation)

**Script:** `plans/260411-2305-gap-validation/run.sh`  
**Phases found:** PREFLIGHT, C, D, E, F, G, H (7 phases total)

**Evidence directory:** `plans/260411-2305-gap-validation/evidence/` (6 files)
- `A1-disk-counts.txt` (101 bytes) ✓
- `A2-claimed-counts.txt` (3828 bytes) ✓
- `A3-inventory-drift.md` (4936 bytes) ✓
- `B1-plan-index.txt` (4969 bytes) ✓
- `C1-current-symlink.txt` (330 bytes) ✓
- `scope-drift.md` (4969 bytes) ✓

All evidence files non-empty. Phase C–H execution not yet attempted (orchestrator halted).

---

## Decisions Resolved

**File:** `logs/decisions.md`

- **U1:** test (CONSENSUS + FORGE engines tested in P08, not deferred)
- **U2:** all (Phase 07 to review all 38 skills, not top-20 shortcut)
- **U3:** drop (Spec 015 quarantine branch to be deleted, not cherry-picked)

All answers greppable in format `^U[123]: `.

---

## Benchmark Scenarios (P05 Demo Matrix)

**Scaffold base:** `benchmark/scaffolds/`

Existing scaffolds:
1. node-cli
2. node-express
3. node-fullstack
4. node-nextjs
5. node-react
6. python-cli
7. python-flask
8. swift-ios

**Status:** 8 scaffolds exist; no demo/ dir found. Scenarios may be generated from scaffolds on-demand. P05 will discover canonical 5.

---

## Notes

- Git state acceptable (only plan dirs + reports untracked; .DS_Store allowed)
- Benchmark exists and scores well (A grade, 96/100)
- Inventory drift detected: +1 command, +2 skills, +3 hooks (likely additions post-CLAUDE.md)
- Active plan evidence present but execution not yet run
- All decisions finalized in logs/decisions.md
- Phase 00 ready for validator check
