Improve the `{SKILL}` skill in the ValidationForge plugin based on its audit.

INPUTS:
- Audit JSON: /Users/nick/Desktop/validationforge/skill-audit-workspace/_reports/{SKILL}.audit.json
- LIVE SKILL.md: /Users/nick/Desktop/validationforge/skills/{SKILL}/SKILL.md
- Skill dir: /Users/nick/Desktop/validationforge/skills/{SKILL}/
- Snapshot (DO NOT EDIT): /Users/nick/Desktop/validationforge/skill-audit-workspace/{SKILL}/skill-snapshot/

TASK:
1. Read the audit JSON — focus on `top_fixes`, `body.issues`, `description.issues`.
2. Read the current SKILL.md end-to-end.
3. Apply the audit's recommended fixes to the LIVE skill file at the path above. If the audit recommends bundled references/scripts, create them under `/Users/nick/Desktop/validationforge/skills/{SKILL}/references/` or `.../scripts/`.
4. Rewrite the YAML `description:` field per audit recommendations (target 30-80 words, pushy, what+when phrasing, concrete trigger phrases).
5. Preserve scope and cross-references. Don't break the skill's actual capabilities.
6. After edits: tighten with fresh eyes. Explain WHY instead of MUST/ALWAYS/NEVER spam. Imperative voice. Keep <500 lines.

OUTPUT: write change log to `/Users/nick/Desktop/validationforge/skill-audit-workspace/{SKILL}/improvement-log.json` with this schema:
{
  "skill_name": "{SKILL}",
  "changes_applied": [{"fix": "...", "implemented": true, "details": "..."}],
  "changes_skipped": [{"fix": "...", "reason": "..."}],
  "files_created": ["..."],
  "files_modified": ["SKILL.md"],
  "description_before": "...",
  "description_after": "...",
  "line_count_before": 0,
  "line_count_after": 0,
  "self_review_notes": "1-3 sentences"
}

CONSTRAINTS:
- Don't break YAML frontmatter syntax (validate after edit).
- Don't remove existing behaviors — only refactor/clarify/tighten.
- If a recommended reference would require fabricating substantial content, prefer concise inline guidance.

Echo at end: `DONE {SKILL}: X applied, Y skipped, lines OLD->NEW`
