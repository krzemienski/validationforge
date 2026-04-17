---
name: Skill Invocation Triggers Fix (4 missing skills)
date: 2026-04-16
status: pending
gap_ids: [NEEDS_FIX]
depends_on: []
type: skill
---

# Skill Triggers Fix

## Why

4 skills from P06/P07 deep review are missing keyword invocation triggers in their SKILL.md files:
- flutter-validation
- full-functional-audit
- fullstack-validation
- rust-cli-validation

Without triggers, these skills are never auto-invoked by keyword matching.

## Acceptance Criteria

- All 4 skills have trigger keywords added to SKILL.md frontmatter
- Keywords match common entry points (e.g., `flutter-validation` triggers on "flutter", "flutter driver")
- Skills tested with 1 keyword invocation per skill
- Evidence captured for all 4 triggers firing

## Inputs

- Current skill SKILL.md files (skills/*/SKILL.md)
- Skill activation patterns from skill-activation-forced-eval.js

## Steps

1. Read current trigger syntax in working skills (ios-validation, web-validation)
2. Define triggers for 4 missing skills
3. Add triggers to SKILL.md frontmatter
4. Test each trigger keyword in a conversation
5. Verify skill auto-invokes on keyword match

## Success Criteria

- 4/4 skills have trigger keywords
- 4/4 skills auto-invoke on keyword
- Evidence captured (skill invocation logs)

## Quick Fix

Expected duration: 30–45 min. Low risk; no code changes, metadata only.

---

**Status:** Pending (quick follow-up)
