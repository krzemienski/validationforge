# Phase 01 — Cross-Repo CLAUDE.md Additions

## Context Links
- Plan: `plans/260417-1715-insights-foundation/plan.md`
- Source report: `plans/reports/insights-report-260417.md`
- Existing user-global: `~/.claude/CLAUDE.md` (~15KB; Production-Grade Agent Directives)
- Existing detector: `~/Desktop/yt-transition-shorts-detector/CLAUDE.md`
- Sister rules (leveraged by new sections): `~/.claude/rules/instrument-before-theorize.md`, `~/.claude/rules/ocr-debug-protocol.md`
- Hook reference (context for mentions of enforcement): `~/.claude/plugins/cache/superpowers-marketplace/superpowers-developing-for-claude-code/0.3.1/skills/working-with-claude-code/references/hooks.md`

## Overview
- **Priority:** P1 (blocks Phases 2, 3)
- **Status:** draft
- **Description:** Add two top-level sections to `~/.claude/CLAUDE.md` — **Debugging Protocol** and **Audit Workflow** — encoding insights-report findings (symptom-patch spiral, no-visual-first audits). Add a **Detector Project Conventions** section to `yt-transition-shorts-detector/CLAUDE.md` that localizes the hard-learned lessons (GT is the metric, thread-unsafe parallel rescan, fuzz.token_set_ratio).

## Key Insights
- Claude follows CLAUDE.md directives much more reliably than rules files — rules are reference, CLAUDE.md is always-on. Sections added here will survive model context compaction.
- `instrument-before-theorize.md` already exists and is strong — but it lives in rules/, not CLAUDE.md. A ONE-FIX-AT-A-TIME declaration belongs at the top of CLAUDE.md where it cannot be skipped.
- Detector conventions are **project-local** — GT-comparison semantics, ralph-loop-findings lessons, and TUI thread model do not belong in user-global CLAUDE.md.

## Requirements
### Functional
- `~/.claude/CLAUDE.md` contains `## Debugging Protocol` with: ONE FIX AT A TIME, root-cause-before-patch, document-why-on-revert.
- `~/.claude/CLAUDE.md` contains `## Audit Workflow` with: visual/frame inspection FIRST, seed-data-locally, DB-schema-check up-front.
- `yt-transition-shorts-detector/CLAUDE.md` contains `## Detector Project Conventions`.
- New sections cross-reference `~/.claude/rules/instrument-before-theorize.md` and (once Phase 2 lands) `~/.claude/rules/audit-workflow.md`.

### Non-functional
- Each new section ≤ 35 lines; total CLAUDE.md growth ≤ 100 lines.
- Insertion point near top (after the preamble, before Section 1) so load-order is first.
- No emojis (house style). No AI attribution.
- Kebab-case phrasing preserved; match existing CLAUDE.md heading hierarchy (`##` top-level).

## Architecture
### Placement in `~/.claude/CLAUDE.md`
```
[existing preamble: "CLAUDE.md - Production-Grade Agent Directives"]
[existing: "The governing loop for all work..."]

## Debugging Protocol        <-- NEW (insert here)
## Audit Workflow             <-- NEW (insert here)

## 1. Pre-Work                <-- existing
## 2. Understanding Intent    <-- existing
...
```

### Placement in `yt-transition-shorts-detector/CLAUDE.md`
Append `## Detector Project Conventions` after the existing overview, before any skill/mandatory-session-start block. (Current detector CLAUDE.md already has `## Mandatory Session Start` — new section goes above it so it loads before skill invocation.)

### Section drafts (to be inserted verbatim by Phase 2→1 executor)
#### Debugging Protocol (user-global)
```markdown
## Debugging Protocol

When debugging, these rules override any bias toward "try a few things quickly":

1. **One fix at a time.** Never bundle an HSV-threshold tweak with a PSM fallback
   with a filter tolerance adjustment. Each change is its own branch. When you
   combine fixes, you cannot attribute which one worked — and you will re-introduce
   the dud in the next campaign.
2. **Root cause before patch.** State the root cause in writing before any code
   change. Format: `HYPOTHESIS: <what>. EVIDENCE: <file:line or command output>.
   PREDICTED FIX: <minimal change>.` If you cannot write the hypothesis, you do
   not understand the bug. Instrument more (see
   `~/.claude/rules/instrument-before-theorize.md`).
3. **Document why on revert.** If a fix is reverted, append a one-line note to
   the relevant plan or checkpoint: `REVERTED <commit> — REASON: <regression seen>`.
   This prevents the same dud from being re-proposed two sessions later.
4. **Stop after 2 failed attempts.** If attempt 1 and attempt 2 on the same root
   cause both fail, do not attempt 3. Instrument the assumption that both fixes
   share, then re-derive the hypothesis. The insights report shows 2+ hour
   sessions that would have been 20 min with a TRACE print.
```

#### Audit Workflow (user-global)
```markdown
## Audit Workflow

Audits (functional, UI, schema, visual) follow a visual-first order — never
start with cross-workspace debugging or authenticated API calls.

1. **Visual / frame inspection first.** For UI: screenshot the actual state.
   For OCR/detection: extract the frame and inspect the mask. For data: query
   the DB directly with `psql` before theorizing about ORM behavior. The
   authoritative pattern is `~/.claude/rules/ocr-debug-protocol.md`; the
   generalized form is `~/.claude/rules/audit-workflow.md` (Phase 2).
2. **Seed data locally.** If the audit needs a known-state database, web
   session, or simulator, seed it in your own workspace. Do not debug against a
   shared sandbox, another engineer's session, or a production mirror — the
   time spent proving "auth works for Alice but not Bob" is time not spent on
   the actual bug.
3. **DB schema check up-front.** Before reading any route handler, run the
   schema check (`\d+ <table>` or `SHOW CREATE TABLE`). Half of "API returns
   nulls" bugs are schema drifts that no amount of handler-reading will find.
4. **Capture evidence before theorizing.** Every audit hypothesis must cite a
   screenshot path, an `e2e-evidence/` file, or a `psql` transcript. No
   "seems like" or "should be" — only observed artifacts.
```

#### Detector Project Conventions (detector-local)
```markdown
## Detector Project Conventions

Project-specific rules learned from the OCR regression campaigns:

1. **GT match is the success metric.** A detection pass that improves one
   metric but degrades GT coverage is a regression. Before declaring victory
   on any boundary fix, run `scripts/groundtruth/compare_all_gt_vs_detection.py`
   and cite the delta.
2. **No thread-unsafe state in parallel collectors.** The adaptive re-scan
   campaign added per-frame state to a shared collector and introduced
   race-condition flapping (see `ralph-loop-findings.md`). If you need
   cross-frame state, it lives in the tracker, not the collector.
3. **Use `fuzz.token_set_ratio`, not `fuzz.ratio`, for short titles.**
   Short Shorts titles (≤ 4 tokens) consistently mis-score under
   `fuzz.ratio` — the order penalty is too harsh. `token_set_ratio`
   handles reordering and missing particles.
4. **Grayscale scan is a separate pipeline.** The sponsored-label detector
   uses grayscale, not the white mask. Failures in one do not imply failures
   in the other. See `~/.claude/rules/ocr-debug-protocol.md`.
```

## Related Code Files
### Modify
- `~/.claude/CLAUDE.md` — insert two sections (Debugging Protocol, Audit Workflow) after preamble.
- `~/Desktop/yt-transition-shorts-detector/CLAUDE.md` — append one section (Detector Project Conventions).

### Create / Delete
- None.

## Implementation Steps
1. Read `~/.claude/CLAUDE.md` end-to-end; confirm the exact line number where Section 1 ("Pre-Work") begins.
2. Insert `## Debugging Protocol` block immediately before `## 1. Pre-Work`.
3. Insert `## Audit Workflow` immediately after Debugging Protocol, before `## 1. Pre-Work`.
4. Verify the rest of the file is byte-identical below the insertion point (no accidental drift).
5. Read `yt-transition-shorts-detector/CLAUDE.md`; locate the existing `## Mandatory Session Start` section.
6. Insert `## Detector Project Conventions` immediately above `## Mandatory Session Start`.
7. `wc -l` both files; confirm total new lines ≤ 100 for user-global, ≤ 40 for detector.
8. Dry-read both files back to confirm Markdown still renders (no broken fences, no stray backticks).
9. Commit evidence: `diff --stat` output stored at `plans/260417-1715-insights-foundation/reports/phase-01-diffstat.txt`.

## Todo List
- [ ] Read current `~/.claude/CLAUDE.md` and note Section-1 line number
- [ ] Insert Debugging Protocol block
- [ ] Insert Audit Workflow block
- [ ] Verify byte-identical tail in user-global CLAUDE.md
- [ ] Read detector CLAUDE.md and locate Mandatory Session Start
- [ ] Insert Detector Project Conventions above Mandatory Session Start
- [ ] Confirm line counts within budget
- [ ] Render-check both files
- [ ] Save diffstat to reports/

## Success Criteria
- [ ] `grep -c "^## Debugging Protocol" ~/.claude/CLAUDE.md` returns `1`.
- [ ] `grep -c "^## Audit Workflow" ~/.claude/CLAUDE.md` returns `1`.
- [ ] `grep -c "^## Detector Project Conventions" ~/Desktop/yt-transition-shorts-detector/CLAUDE.md` returns `1`.
- [ ] New sections appear BEFORE the existing numbered sections (load-order matters).
- [ ] Diff between pre- and post-phase CLAUDE.md shows ONLY the new blocks — no accidental reformatting of untouched content.
- [ ] Cross-references to `instrument-before-theorize.md` and `audit-workflow.md` use absolute `~/.claude/rules/` paths.
- [ ] Diffstat file saved to reports/.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| CLAUDE.md growth pushes load over context budget | Low | Med | Budget ≤100 new lines; existing file is ~15KB, plenty of headroom. |
| Insertion breaks Markdown (unclosed fence) | Low | High | Render-check step 8; `grep -c '^\`\`\`'` must be even on both files. |
| User-global section contradicts existing Section 1 directives | Med | Med | Debugging Protocol explicitly extends (not replaces) Pre-Work. Language chosen to harmonize. |
| Detector-local section duplicates rules/instrument-before-theorize.md | Low | Low | Detector section is strictly project-specific (GT script, collector module names); zero overlap. |
| Cross-reference to `audit-workflow.md` breaks before Phase 2 lands | Med | Low | Phase 2 is a blocker-dependency of Phase 1 users but not Phase 1 authoring. Link will resolve once Phase 2 ships; harmless dead link in the interim. |

## Security Considerations
- No secrets in any new section. No command invocations embedded in the Markdown (no executable paths with sudo/rm).
- Detector section mentions `psql` as a debugging tool — assumes user has local DB access; no credentials referenced.
- CLAUDE.md is user-global and not committed to any shared repo; nothing leaks to teammates.

## Next Steps
- Phase 2 depends on this phase completing — new rules files will be cross-referenced from Debugging Protocol and Audit Workflow sections.
- Phase 3 and Phase 4 depend transitively (hooks will mention these sections in their user-facing messages).

## Unresolved Questions
- Should the ONE-FIX-AT-A-TIME rule be further enforced by a PreToolUse hook that blocks Edit/Write when more than N files changed in the last 5 minutes without an intervening validation run? (Deferred to Plan C.)
- Does the detector conventions section want a changelog link (to `ralph-loop-findings.md`) or is a prose reference enough?
