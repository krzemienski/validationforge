# Phase 08 — Functional validation against real scenarios

## Context Links
- Plan: `plans/260417-1715-insights-skills-layer/plan.md`
- Authoritative validation discipline: `~/Desktop/validationforge/.claude/rules/evidence-before-completion.md`, `~/Desktop/validationforge/.claude/rules/no-mocks.md`
- ValidationForge philosophy: `/Users/nick/Desktop/validationforge/CLAUDE.md` §*The Iron Rules*
- Evidence conventions: `~/.claude/rules/vf-evidence-management.md`

## Overview
- **Priority:** P1 — the no-mocks mandate means benchmark scores alone are insufficient. Each skill must demonstrably work on a real scenario.
- **Status:** pending (blocked by Phase 7)
- **Description:** Manually invoke each skill via its trigger (`/gt-perfect`, `/root-cause-first`, `/audit`) against a genuinely real-world scenario. Capture transcript + evidence. Confirm the skill's encoded workflow was followed end-to-end, not shortcut. Save per-skill validation reports to `plans/260417-1715-insights-skills-layer/reports/skill-validation-{name}-260417.md`.

## Key Insights (from discovery)
- ValidationForge's core rule: compilation success ≠ functional validation. A passing benchmark proves the skill works on the eval prompts; this phase proves it works in the wild.
- Each skill has a natural real-world test scenario:
  - `/gt-perfect`: use an actual known-mismatched detector run (insights report referenced multiple past GT misses — pick one that is still open or reproducible).
  - `/root-cause-first`: seed a real small bug in a sandbox branch of some project, ask the model to fix it, verify `.debug/<issue>/evidence.md` materializes BEFORE any src edit.
  - `/audit`: audit a real SessionForge dashboard page (or other live project view) — the exact scenario that motivated the skill's existence.
- Evidence must be specific and cited per `evidence-before-completion.md` — transcripts with exact file paths, quoted outputs, timestamps.
- "No mocks" applies recursively — the validation itself does not seed synthetic data where a real reproduction exists.

## Requirements

### Functional
- One `reports/skill-validation-{name}-260417.md` per skill, containing:
  - The exact trigger prompt used.
  - Timestamped transcript excerpt showing the skill was invoked and its workflow followed.
  - Cited evidence artifacts (screenshots for `/audit`, evidence.md for `/root-cause-first`, gt-diff output for `/gt-perfect`).
  - PASS / FAIL verdict against each step of the skill's encoded workflow.
  - List of any workflow steps shortcut, and whether the shortcut was principled.
- If any skill FAILs validation, return to Phase 6 for targeted iteration; do not mark the plan complete.

### Non-functional
- No test files, no mocks, no stubs (per `no-mocks.md`).
- No synthetic scenarios when a real reproduction exists.
- Every PASS cites specific evidence; every FAIL cites what was expected and what was observed.

## Architecture

### Per-skill validation scenario
| Skill | Real scenario | Expected workflow artifacts |
|-------|---------------|-----------------------------|
| `/gt-perfect` | Run against a currently-known-mismatched clip (e.g. a seq_X with stall count delta ≥ 1 in the detector repo). | `scripts/gt-diff.py` output; frame extraction evidence; a `fix-NNN` commit on a sandbox branch. |
| `/root-cause-first` | In a sandbox branch, seed a subtle real-world bug (e.g. off-by-one in a utility function); ask the model to fix. | `.debug/<issue>/evidence.md` committed before any src edit; `failed-approaches.md` exists if any attempt fails. |
| `/audit` | Audit a SessionForge dashboard page or another live VF-adjacent page. | `e2e-evidence/<feature>/step-01-<view>.png` captured before any code-path investigation; one-pass DB schema check output. |

### Evidence bundle layout
```
plans/260417-1715-insights-skills-layer/reports/
├── skill-validation-gt-perfect-260417.md
├── skill-validation-root-cause-first-260417.md
├── skill-validation-audit-260417.md
└── evidence/
    ├── gt-perfect/
    │   ├── gt-diff-output.txt
    │   ├── step-01-frame-extracted.png
    │   └── commit-hash.txt
    ├── root-cause-first/
    │   ├── evidence.md.captured
    │   └── src-edit-diff.patch
    └── audit/
        ├── step-01-dashboard.png
        ├── step-02-db-schema-check.txt
        └── transcript-excerpt.md
```

### Validation flow (per skill)
```
identify real scenario  →  invoke /<skill> via trigger phrase
        │
        ▼
capture transcript + artifacts in plans/.../reports/evidence/<skill>/
        │
        ▼
step-by-step check: did workflow step N happen before step N+1?
        │
        ▼
write skill-validation-<name>-260417.md
        │
        ├─ PASS → mark phase complete
        └─ FAIL → loop back to Phase 6 with concrete failure diff
```

## Related Code Files

### CREATE
- `plans/260417-1715-insights-skills-layer/reports/skill-validation-gt-perfect-260417.md`
- `plans/260417-1715-insights-skills-layer/reports/skill-validation-root-cause-first-260417.md`
- `plans/260417-1715-insights-skills-layer/reports/skill-validation-audit-260417.md`
- `plans/260417-1715-insights-skills-layer/reports/evidence/{skill}/` bundles per table above

### MODIFY
- None on first pass. On FAIL, targeted SKILL.md edits per Phase 6 loop.

### DELETE
- None.

## Implementation Steps

Observe validationforge's iron rules throughout — build/run the real system; evidence before claims.

1. **(per skill)** Identify the real scenario and sandbox it:
   - `/gt-perfect`: pull latest detector main, find a clip with an open GT mismatch via `python -m yt_shorts_detector detect …` + diff against `ground_truth/*.json`.
   - `/root-cause-first`: in a throwaway branch of a VF-adjacent project, introduce a real bug (off-by-one, wrong conditional, typo in a selector). Commit the bug separately so the diff is clear. Then reset your context and ask the model to fix.
   - `/audit`: pick an actual running dashboard page, boot it, prepare the trigger prompt.
2. **(per skill)** Invoke the skill by natural trigger phrase (not `/skill-name` command — we are testing triggering too). Example: "the detector is giving 12 shorts on seq_X but GT says 14, figure out why."
3. Capture full transcript + every artifact produced. Save to `plans/.../reports/evidence/<skill>/`.
4. Apply the validation checklist per skill:
   - `/gt-perfect`: did `gt-diff.py` run first? was a frame extracted before threshold tweaks? was the commit in `fix-NNN` format?
   - `/root-cause-first`: did `.debug/<issue>/evidence.md` materialize before any src edit? did the hypothesis section name ONE specific function + line? was it committed before the fix?
   - `/audit`: was a visual artifact captured first? was the DB schema check performed once, up front?
5. Write `skill-validation-<name>-260417.md` per validation discipline: prompt used, workflow checklist with PASS/FAIL per step, cited evidence for each.
6. On FAIL: write a concrete failure diff (what the skill said to do vs what happened), hand back to Phase 6 for one more iteration. Do NOT mark the plan complete.
7. On PASS for all three skills: update plan.md status to `complete`, run `ck plan check <id>` if CLI available, else edit plan.md directly.

## Todo List
- [ ] Identify real scenario per skill (no synthetic)
- [ ] Seed `/root-cause-first` bug in a sandbox branch with clean diff
- [ ] Invoke each skill via natural trigger phrase
- [ ] Capture transcript + artifacts to evidence bundle
- [ ] Apply workflow checklist per skill
- [ ] Write validation report per skill with cited evidence
- [ ] Handle FAILs via Phase 6 loop; do not ship until all PASS
- [ ] Update plan.md status to complete

## Success Criteria
- Three validation reports exist; each has PASS verdicts on every step of its skill's encoded workflow.
- Every PASS cites a specific evidence artifact with path + timestamp.
- Any shortcut is called out explicitly and judged principled or not.
- No mocks, no stubs, no synthetic data introduced during validation.
- `/gt-perfect` produces a real diff and a real `fix-NNN` commit (on a sandbox branch) fixing a real mismatch.
- `/root-cause-first` produces `.debug/<issue>/evidence.md` committed BEFORE any src edit — visible in git log.
- `/audit` produces a non-empty screenshot captured before any code investigation.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| No real GT mismatch available at validation time | Medium | High | Keep a reserved open mismatch from Phase 1 discovery; alternatively pick any historical mismatch reproducible from git |
| Seeded bug for `/root-cause-first` is too obvious → model skips evidence.md | Medium | High | Pick a subtle bug (off-by-one in edge case) so the workflow genuinely matters |
| SessionForge or equivalent audit target not running | Medium | High | Pre-boot the target before starting Phase 8; document env setup |
| Skill fails validation after optimization in Phase 7 | Medium | Medium | Loop back to Phase 6 with concrete failure signal; re-run Phase 7 after |
| Evidence bundle grows large (screenshots) | Low | Low | Keep evidence under the workspace; VF's retention policy handles archival |

## Security Considerations
- Sandbox branches only — never validate on main or shared branches.
- Seeded bug must be reverted before merging the validation branch anywhere.
- Screenshots may contain user data / internal URLs — redact before committing to a public repo.
- `.debug/<issue>/evidence.md` from validation run may contain repro payloads — scrub or keep in a local-only branch.

## Next Steps
- On all PASS: mark plan complete; notify downstream Plan C that `/root-cause-first` is ready for PreToolUse hook wiring.
- Post-completion: open a tuning plan to expand eval sets beyond 2–3 prompts (plan.md Unresolved Question).
- Optional: run `package_skill.py` per skill if `present_files` tool is available.
