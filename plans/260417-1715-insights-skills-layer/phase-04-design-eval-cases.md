# Phase 04 — Design eval cases for all three skills

## Context Links
- Plan: `plans/260417-1715-insights-skills-layer/plan.md`
- Authoritative eval format: `~/.claude/skills/skill-creator/SKILL.md` §*Test Cases* and §*Running and evaluating test cases*
- Schema reference: `~/.claude/skills/skill-creator/references/schemas.md` §*evals.json*, §*eval_metadata.json* (defined inline in SKILL.md Step 1)
- Grader protocol: `~/.claude/skills/skill-creator/agents/grader.md`

## Overview
- **Priority:** P1 — without realistic evals, Phase 5 benchmarks prove nothing.
- **Status:** pending (blocked by Phases 1, 2, 3 — draft SKILL.md must exist before evals are written against it)
- **Description:** For each of the three skills, produce 2–3 eval cases that mirror real user phrasings a real person would type. Save each skill's eval set to `plans/260417-1715-insights-skills-layer/evals/{skill}/evals.json`. Assertions are drafted in parallel with Phase 5 runs (skill-creator Step 2 "draft assertions while runs are in progress") but the prompt + expected_output is frozen here.

## Key Insights (from discovery)
- skill-creator emphasizes *realistic* prompts — with filepaths, clip IDs, company names, profanity, typos where the user would actually type them. Sanitized abstract prompts ("Format this data") have been shown to degrade eval quality.
- Assertions must be *discriminating* (grader.md §Step 6 "Critique the Evals"): a hallucinated output should fail them, a correct output should pass.
- 2–3 cases during development is the skill-creator default; expansion waits for a follow-up tuning plan (see plan.md Unresolved Questions).
- For subjective elements (quality of the audit report), assertions are a poor fit — the skill-creator guide says lean on qualitative user review for those.
- Evals include both positive cases (skill should trigger and produce the workflow) and a near-miss case per skill to confirm it does not overreach. Full trigger-eval sweep is deferred to Phase 7.

## Requirements

### Functional
- Three `evals.json` files, one per skill, each with 2–3 entries.
- Each entry has: `id`, `prompt` (realistic), `expected_output` (human-readable description), `files` (optional input artifacts), and `expectations` (draft list — finalized in Phase 5 Step 2).
- Prompts must be plausible human input, not test-like. Include artifact names, line numbers, casual wording.
- Each skill's eval set includes at least one scenario that exercises the skill's bundled script/template.

### Non-functional
- `evals.json` validates against the schema in `~/.claude/skills/skill-creator/references/schemas.md` §*evals.json*.
- Store under `plans/260417-1715-insights-skills-layer/evals/{skill}/` — the workspace is a sibling of `plan.md`, matching the skill-creator workspace convention.

## Architecture

### Directory layout
```
plans/260417-1715-insights-skills-layer/
├── plan.md
├── phase-01..phase-08.md
└── evals/
    ├── gt-perfect/
    │   ├── evals.json
    │   └── files/                  # input artifacts (optional)
    ├── root-cause-first/
    │   └── evals.json
    └── audit/
        └── evals.json
```

### Prompt design matrix

| Skill | Eval 1 (happy path) | Eval 2 (harder) | Eval 3 (near-miss, optional) |
|-------|---------------------|------------------|------------------------------|
| gt-perfect | "the detector says 12 shorts on seq_A but ground truth is 16. figure out why." | "run through all 80 GT videos and tell me the clips where stall count is off by 1+" | "detector looks fine but I want to add a new GT clip for seq_D" — *should still trigger, then route to a different workflow* |
| root-cause-first | "the OCR is missing the sponsored label on frame 340 of video X. Fix it." | "login works locally but 500s in staging — can you debug" | "rename `handle_click` to `on_click` across the codebase" — *should NOT trigger* |
| audit | "Do a full functional audit of the SessionForge dashboard content list view." | "is the mobile iOS checkout flow still working end to end after yesterday's API change?" | "why is my login button throwing a null pointer" — *should NOT trigger (routes to root-cause-first)* |

### Draft assertion seeds (finalized in Phase 5)

Per eval, the grader checks:
- *gt-perfect*: did the model invoke `scripts/gt-diff.py`? did it frame-inspect the first failing clip before proposing a fix? did it produce a commit message in the `fix-NNN: <cause> -> <result>` format?
- *root-cause-first*: did the model create `.debug/<issue>/evidence.md` BEFORE any Edit/Write on src? did the evidence.md name ONE specific function + line in the hypothesis section?
- *audit*: did the model capture a visual artifact (PNG/JSON) before any code-path investigation? did it run the DB schema check once, up front?

## Related Code Files

### CREATE
- `/Users/nick/Desktop/validationforge/plans/260417-1715-insights-skills-layer/evals/gt-perfect/evals.json`
- `/Users/nick/Desktop/validationforge/plans/260417-1715-insights-skills-layer/evals/root-cause-first/evals.json`
- `/Users/nick/Desktop/validationforge/plans/260417-1715-insights-skills-layer/evals/audit/evals.json`
- Optional input artifacts under each skill's `evals/files/` subdir (e.g. a sample mismatched detection JSON for gt-perfect).

### MODIFY
- None.

### DELETE
- None.

## Implementation Steps

Follow skill-creator's *Test Cases* section and the §*Step 1: Spawn all runs* parameter list.

1. **(skill-creator §Test Cases)** For each skill, extract 2–3 real user phrasings. Favor prompts from:
   - git commit history on the detector repo (for gt-perfect);
   - actual past bug-fix Slack-style messages (for root-cause-first);
   - the SessionForge audit ask that motivated the skill (for audit).
2. Write `evals.json` per skill with schema-conformant entries. Do NOT write assertions yet — that happens in Phase 5 Step 2 while the runs execute.
3. If a case requires an input artifact (e.g. a sample detection JSON with a seeded mismatch for gt-perfect), put it under `evals/{skill}/files/` and reference from the `files` array.
4. **(skill-creator §Running — Step 1 metadata)** Author the `eval_metadata.json` stubs per eval with descriptive `eval_name`s (not "eval-0") — will be populated with assertions in Phase 5.
5. Present eval set to user for sign-off: "here are 2–3 prompts per skill I'd like to try — do these look right, or do you want to add more?" per skill-creator guidance.
6. Freeze prompts once the user confirms. Anything they change at this point should be versioned (v1 → v2 in the same file).

## Todo List
- [ ] Draft 2–3 prompts per skill from real past phrasings
- [ ] Write `evals.json` per skill (schema-valid)
- [ ] Create input artifacts under `evals/{skill}/files/` where needed
- [ ] Stub `eval_metadata.json` per eval with descriptive names
- [ ] Get user sign-off on prompt set
- [ ] Freeze prompts; document any post-sign-off edits

## Success Criteria
- Three `evals.json` files exist, each schema-valid per `schemas.md`.
- Each file has ≥2 entries with realistic prompts (containing concrete artifacts, IDs, filepaths).
- User has explicitly approved the prompt set.
- Each eval has a descriptive `eval_name` ready for benchmark.json aggregation.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Prompts too sanitized → bad triggering signal | Medium | High | Cross-check against real past session phrasings before freezing |
| Assertions drafted prematurely and constrain the skill | Low | Medium | Phase 5 Step 2 explicitly draws assertions AFTER observing the initial outputs |
| User asks for more evals mid-Phase-5 | Medium | Low | Version-bump: `evals.json` → `evals.v2.json`; re-run with expanded set in iteration-2 |
| Input artifacts become stale (GT corpus changes) | Low | Medium | Keep artifacts minimal; regenerate them from source on demand |

## Security Considerations
- Input artifacts must not contain real user data or production credentials; scrub before committing.
- Eval prompts that reference internal URLs (e.g. SessionForge staging) should use redacted placeholders (`staging.example.com`) unless the repo is private.

## Next Steps
- Phase 5 (run + grade) depends on this phase complete and frozen.
- Phase 7 (description optimization) uses a disjoint trigger-eval set — this phase only covers execution evals.
