# Phase 02 — Strengthen Rules + Add Audit-Workflow

## Context Links
- Plan: `plans/260417-1715-insights-foundation/plan.md`
- Phase 1 (blocker): `plans/260417-1715-insights-foundation/phase-01-cross-repo-claude-md-additions.md`
- Rule to MODIFY: `~/.claude/rules/instrument-before-theorize.md`
- Rule to REFERENCE (and generalize from): `~/.claude/rules/ocr-debug-protocol.md`
- Rules to CREATE: `~/.claude/rules/audit-workflow.md`, `~/Desktop/yt-transition-shorts-detector/.claude/rules/detector-project-conventions.md`
- Project reference: `~/Desktop/yt-transition-shorts-detector/.claude/ralph-loop-findings.md`

## Overview
- **Priority:** P1 (blocks Phases 3, 4 for cross-references)
- **Status:** draft
- **Description:** Promote `instrument-before-theorize.md` from a debugging heuristic to a "Root-Cause-First Protocol" with written-hypothesis requirement + one-fix-at-a-time rule + stop-after-2-attempts. Create `audit-workflow.md` as the non-OCR generalization (web, iOS, API, data). Create project-local `detector-project-conventions.md` encoding ralph-loop lessons.

## Key Insights
- `instrument-before-theorize.md` already encodes "empirical > theoretical" with the A7 boundary anecdote. We **extend** it — preserve all existing content, prepend a Root-Cause-First protocol section.
- `ocr-debug-protocol.md` is detector-specific but its STRUCTURE (mandatory-first-step, decision-tree, never-do, quick-test-template) generalizes. The new `audit-workflow.md` reuses that structure for web/iOS/API.
- Detector project conventions combine: (a) the CLAUDE.md localizations from Phase 1 + (b) lessons from `ralph-loop-findings.md` + (c) the `ios-frame-precision-analysis.md` observations. This file is more exhaustive than the CLAUDE.md section (which is a summary).
- Detector `.claude/` already has a rules directory — no new directory is created.

## Requirements
### Functional
- `~/.claude/rules/instrument-before-theorize.md` gains a top section "Root-Cause-First Protocol" with: hypothesis-before-fix checklist, one-fix-at-a-time rule, stop-after-2-failed-attempts rule. Existing body preserved verbatim below.
- `~/.claude/rules/audit-workflow.md` exists with: visual-first step, decision-tree-by-platform, never-do list, quick-verify templates per platform (web/iOS/API/data), cross-reference to `ocr-debug-protocol.md` for the OCR case.
- `~/Desktop/yt-transition-shorts-detector/.claude/rules/detector-project-conventions.md` exists with: GT-match-is-success metric (and the comparison script path), no-thread-unsafe-state-in-parallel-collectors (cite ralph-loop-findings), fuzz.token_set_ratio > fuzz.ratio (with line reference if possible), grayscale pipeline is separate, iOS frame-0 skip known issue.

### Non-functional
- New/modified rules ≤ 120 lines each.
- Kebab-case filenames (already compliant).
- All cross-references use absolute `~/.claude/rules/` or relative within the detector repo.
- No code changes — rules are prose + code snippets; no hook registration touched here.

## Architecture
### File layout after this phase
```
~/.claude/rules/
├── instrument-before-theorize.md    (MODIFY — prepend Root-Cause-First Protocol)
├── audit-workflow.md                 (CREATE)
└── ocr-debug-protocol.md             (unchanged — target of cross-refs)

~/Desktop/yt-transition-shorts-detector/.claude/rules/
├── detector-project-conventions.md   (CREATE)
├── instrument-before-theorize.md     (unchanged — mirrored from user-global)
├── ocr-debug-protocol.md              (unchanged)
├── hooks-and-integrations.md         (unchanged)
├── project.md                         (unchanged)
└── tui-patterns.md                    (unchanged)
```

### Section drafts

#### `instrument-before-theorize.md` — PREPENDED section
```markdown
## Root-Cause-First Protocol

Before any code change during debugging, write the root-cause hypothesis in
this format:

```
HYPOTHESIS: <what you believe is broken, in one sentence>
EVIDENCE:  <file:line, command output, screenshot path, or TRACE line>
PREDICTED FIX: <minimal change to validate the hypothesis>
FALSIFIER: <what observation would prove this wrong>
```

### Rules
1. **One fix at a time.** Never bundle fixes. If you want to adjust HSV AND
   add a PSM fallback AND loosen a filter — that's three separate branches,
   three separate validation runs, three separate evidence captures.
2. **No fix without a written hypothesis.** If you cannot fill the template
   above, you do not have a hypothesis; you have a guess. Instrument more.
3. **Stop after 2 failed attempts on the same hypothesis.** If attempts 1
   and 2 both fail, do not attempt 3. Both fixes shared an assumption;
   instrument that assumption, re-derive the hypothesis, and write a new
   template entry.
4. **Document reverts.** When a fix is reverted, append a line to the
   relevant plan or checkpoint:
   `REVERTED <short-sha> — <one-line reason>`. This is how you prevent the
   same dud from being re-proposed in a future session.

### Why
The insights report over 466 sessions surfaced recurring symptom-patch
spirals: threshold tweak → failure → fallback chain → failure → guard →
failure → revert → repeat. Each step skipped the hypothesis template.
Writing the hypothesis forces the empirical check — if you cannot cite
evidence, you cannot write EVIDENCE, and the protocol halts you before
the dud fix ships.

---

[existing content preserved below: "When debugging detection boundary..."]
```

#### `~/.claude/rules/audit-workflow.md` — CREATE
```markdown
# Audit Workflow

Visual-first workflow for audits (functional, UI, schema, data). This is the
non-OCR generalization of `~/.claude/rules/ocr-debug-protocol.md`.

## Mandatory First Step (by platform)

| Platform | First step (before reading code) |
|----------|----------------------------------|
| Web UI   | Screenshot the actual rendered state via Playwright or real browser. |
| iOS      | `xcrun simctl io <device> screenshot /tmp/audit.png` + a11y tree. |
| API      | `curl -v <endpoint>` — capture headers AND body to a file. |
| Database | `psql -c '\d+ <table>'` — read the schema; compare to the ORM model. |
| CLI      | Run the binary with `--help` AND a real invocation; capture stdout/stderr. |

**If you cannot produce a file, screenshot, or transcript from the platform's
own interface, STOP.** No amount of code reading substitutes for this step.

## Decision Tree

- **Output matches expected** → the bug is not where you thought; re-scope.
- **Output differs from expected** → capture the diff as evidence and form
  a hypothesis (see `instrument-before-theorize.md` Root-Cause-First Protocol).
- **Platform refuses to produce output** (server down, DB unreachable,
  simulator boot failure) → that IS the bug; fix the platform first.

## Never Do (audit anti-patterns)

- Debug against another engineer's shared session or a production mirror —
  seed your own workspace.
- Read the route handler before checking the DB schema. Schema drift is
  invisible from the handler.
- Chain hypotheses across platforms ("it works on Web so iOS must have a
  client bug") — audit each platform independently, then correlate.
- Add a symptom-patch (retry, fallback, guard) before capturing the
  failing-platform evidence.

## Quick-Verify Templates

### Web
```bash
# Boot a clean session, navigate, screenshot.
npx playwright screenshot --browser=chromium \
  --wait-for-selector='[data-testid="loaded"]' \
  http://localhost:3000/page ./audit-web-$(date +%s).png
```

### iOS
```bash
DEVICE=$(xcrun simctl list devices booted | awk -F'[()]' '/\(Booted\)/ {print $2; exit}')
xcrun simctl io "$DEVICE" screenshot /tmp/audit-ios.png
xcrun simctl spawn "$DEVICE" log stream --level debug > /tmp/audit-ios.log &
```

### API
```bash
curl -v -H 'Accept: application/json' \
  -o >(tee /tmp/audit-api-body.json) \
  -D /tmp/audit-api-headers.txt \
  http://localhost:8080/v1/resource
```

### Database
```bash
psql "$DATABASE_URL" -c '\d+ users' > /tmp/audit-schema-users.txt
psql "$DATABASE_URL" -c 'SELECT column_name, data_type, is_nullable
  FROM information_schema.columns WHERE table_name=$$users$$;' \
  > /tmp/audit-schema-users.csv
```

## Cross-References
- OCR-specific workflow: `~/.claude/rules/ocr-debug-protocol.md`
- Root-cause-before-patch discipline: `~/.claude/rules/instrument-before-theorize.md`
- Evidence directory convention: `~/.claude/rules/vf-evidence-management.md`
```

#### `~/Desktop/yt-transition-shorts-detector/.claude/rules/detector-project-conventions.md` — CREATE
```markdown
# Detector Project Conventions

Project-local conventions learned from the OCR campaigns, adaptive-rescan
work, and iOS precision-tuning roadmap. Load-bearing — violating these has
cost 10+ hour sessions historically.

## GT Match Is the Success Metric

A detection change that improves one local metric but degrades GT coverage
is a regression. Before declaring victory on any detection change:

```bash
python3 scripts/groundtruth/compare_all_gt_vs_detection.py \
  > .planning/gt-delta-$(date +%Y%m%d-%H%M).txt
```

Cite the delta (gained / lost / net). A net-negative run means the change
is rejected, even if the "target" video improved.

## No Thread-Unsafe State in Parallel Collectors

The adaptive re-scan campaign (see `~/Desktop/yt-transition-shorts-detector/.claude/ralph-loop-findings.md`)
introduced per-frame state into a shared parallel collector and caused
race-condition flapping — PASS/FAIL results depended on thread scheduling.

Rules:
- Cross-frame state lives in the tracker (`src/yt_shorts_detector/y_position_tracker.py`),
  never in the collector.
- If you think you need shared state in a collector, you actually need
  either (a) a serialized pass or (b) per-thread local state merged at the end.

## `fuzz.token_set_ratio`, Not `fuzz.ratio`

Short Shorts titles (≤ 4 tokens) mis-score under `fuzz.ratio` — the order
penalty is too harsh when particles are dropped. Use `token_set_ratio`.

- Correct: `rapidfuzz.fuzz.token_set_ratio(candidate, gt_title)`
- Wrong:   `rapidfuzz.fuzz.ratio(candidate, gt_title)`

If you see `fuzz.ratio` anywhere in matching code during a review, flag it.

## Grayscale Scan Is a Separate Pipeline

`_detect_sponsored_label` uses a grayscale preprocessing pipeline, not the
white-mask pipeline used by `WhiteTextOCR`. Failures in one do NOT imply
failures in the other.

- If white-mask misses text but grayscale catches it → run grayscale more
  frequently; do NOT add PSM fallbacks to the white-mask path.
- If both miss it → preprocessing issue (HSV threshold, text color); fix
  at the mask level.

See `~/.claude/rules/ocr-debug-protocol.md` for the full decision tree.

## Known Issues (2026-04-17)

- **Frame-0 skip bug** — 14/46 HeadSpin videos have GT starting at frame ≥ 1.
  Root cause in `extract_keyframes.py`. Under investigation.
- **GT regeneration gap** — `G` key on VideoDetailScreen silently overwrites
  existing GT; needs confirmation dialog before regenerating.
- **Log streaming unverified** — StreamRouter → OrchestratorBridge →
  AutoFocusLog live rendering during agent runs not end-to-end verified.

## Mandatory Session Start

Invoke `yt-shorts-detector-guidelines` skill at every session start. The
skill encodes iron rules and pitfalls that have cost 60+ sessions historically
when skipped.
```

## Related Code Files
### Modify
- `~/.claude/rules/instrument-before-theorize.md` — prepend Root-Cause-First Protocol block; preserve existing body verbatim.

### Create
- `~/.claude/rules/audit-workflow.md`
- `~/Desktop/yt-transition-shorts-detector/.claude/rules/detector-project-conventions.md`

### Delete
- None.

## Implementation Steps
1. Read current `~/.claude/rules/instrument-before-theorize.md` (29 lines); note its exact content.
2. Prepend the Root-Cause-First Protocol section above the existing `# Instrument Before Theorize` H1. (The new section becomes the lead; the existing body stays as context/anecdote.)
3. Write `~/.claude/rules/audit-workflow.md` with the content block from Architecture.
4. Confirm `~/Desktop/yt-transition-shorts-detector/.claude/rules/` exists (verified in discovery — it does).
5. Write `detector-project-conventions.md` with the content block from Architecture.
6. `wc -l` each file; confirm ≤ 120 lines.
7. Render-check: `grep -c '^\`\`\`' <file>` must be even on each.
8. Save file list and line counts to `plans/260417-1715-insights-foundation/reports/phase-02-filelist.txt`.

## Todo List
- [ ] Read existing instrument-before-theorize.md
- [ ] Prepend Root-Cause-First Protocol section
- [ ] Create audit-workflow.md
- [ ] Create detector-project-conventions.md (project-local)
- [ ] Verify line counts within budget
- [ ] Render-check (matched fences)
- [ ] Save filelist + line counts to reports/

## Success Criteria
- [ ] `grep -c '^## Root-Cause-First Protocol' ~/.claude/rules/instrument-before-theorize.md` returns `1`.
- [ ] `grep -c 'Empirical > Theoretical. Instrument > Reason' ~/.claude/rules/instrument-before-theorize.md` returns `1` (existing content preserved).
- [ ] `test -f ~/.claude/rules/audit-workflow.md` passes.
- [ ] `grep -q '## Mandatory First Step' ~/.claude/rules/audit-workflow.md` passes.
- [ ] `grep -q 'ocr-debug-protocol.md' ~/.claude/rules/audit-workflow.md` passes (cross-ref preserved).
- [ ] `test -f ~/Desktop/yt-transition-shorts-detector/.claude/rules/detector-project-conventions.md` passes.
- [ ] `grep -q 'token_set_ratio' ~/Desktop/yt-transition-shorts-detector/.claude/rules/detector-project-conventions.md` passes.
- [ ] Reports filelist saved with line counts.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Prepend breaks the existing anecdote context | Low | Low | Separator `---` line between new and old sections; re-read after write. |
| `audit-workflow.md` drifts from ocr-debug-protocol.md structure and causes confusion | Med | Low | Explicit cross-reference; matching heading hierarchy (Mandatory First Step, Decision Tree, Never Do, Quick-Verify). |
| Detector conventions duplicates CLAUDE.md section from Phase 1 | Low | Low | Phase 1 CLAUDE.md section is a 4-bullet summary; this file is the exhaustive version. Bullets reference this file as the authority. |
| GT comparison script path wrong | Low | Med | Script path verified during discovery (`scripts/groundtruth/compare_all_gt_vs_detection.py` exists per project CLAUDE.md). |
| User edits ralph-loop-findings.md post-phase and invalidates the cross-reference | Low | Low | Cross-reference uses file name, not line number; survives edits. |

## Security Considerations
- Rules files are prose — no executable commands run at load time.
- Quick-verify templates shell out to `curl`, `psql`, `xcrun`, `npx playwright`. All use localhost or `$DATABASE_URL`; no credentials hard-coded.
- `psql "$DATABASE_URL"` relies on user-set env var — if unset, command errors loudly (safe failure mode).
- No path traversal vectors (all absolute `~/.claude/` or project-relative).

## Next Steps
- Phase 3 and Phase 4 cross-reference `instrument-before-theorize.md` and `audit-workflow.md` in hook user-facing messages.
- The Debugging Protocol section added in Phase 1 cross-references `instrument-before-theorize.md`; once Phase 2 lands, that reference resolves to the promoted-to-Root-Cause-First content.

## Unresolved Questions
- Should `audit-workflow.md` include a "Container / Docker" platform row in the Mandatory First Step table? Not in the current insights corpus, but likely useful.
- Does detector-project-conventions.md need a line-number citation for the `fuzz.token_set_ratio` location, or is the prose rule enough? Ask the user whether grep-confirming at review time is sufficient.
- Ralph-loop-findings.md path — is that the final name, or will it be archived under `.planning/` soon? If archived, update the cross-reference.
