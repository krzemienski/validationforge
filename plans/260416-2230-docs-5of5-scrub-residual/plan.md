---
name: Residual Docs Scrub (5/5 vs 0/5 language cleanup)
date: 2026-04-16
status: pending
gap_ids: [P12_REGRESSION_RESIDUAL]
depends_on: []
type: doc
---

# Residual Docs Scrub

## Why

P12 regression validator flagged that `5/5 vs 0/5` language still appears in two documents:
- PRD.md (lines 610, 659, 772)
- MARKETING-INTEGRATION.md (line 96)

This language was removed from SPECIFICATION.md, README.md, and COMPETITIVE-ANALYSIS.md during earlier phases. Residual cleanup deferred to P13 follow-up.

## Acceptance Criteria

- `5/5 vs 0/5` language removed from PRD.md
- `5/5 vs 0/5` language removed from MARKETING-INTEGRATION.md
- Replaced with neutral language (e.g., "benchmark proof incomplete")
- No other doc content changed
- Evidence: diff captured showing removals only

## Inputs

- PRD.md (lines 610, 659, 772)
- MARKETING-INTEGRATION.md (line 96)
- Prior scrub reference (SPECIFICATION.md, README.md, COMPETITIVE-ANALYSIS.md)

## Steps

1. Read PRD.md lines 600–650, 650–700, 760–780 (context)
2. Identify exact `5/5` / `0/5` phrases
3. Replace with neutral language
4. Repeat for MARKETING-INTEGRATION.md line 90–100
5. Capture diffs
6. Verify no unintended changes

## Success Criteria

- 4/4 instances removed (3 in PRD, 1 in MARKETING)
- Replacement language is neutral and contextually correct
- No other content modified
- Diffs show removals only

## Quick Fix

Expected duration: 15 min. Low risk; doc cleanup only.

---

**Status:** Pending (quick follow-up; anytime post-campaign)
