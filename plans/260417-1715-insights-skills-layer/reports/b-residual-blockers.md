# Plan B Residual Blockers

Branch: `insights/phase-0-schema-freeze`  
Date: 2026-04-17

## Summary

Phase B4 (eval cases) and the B5 scaffold are complete in-session. The following
phases remain **blocked on out-of-session infrastructure** and cannot proceed
without explicit token-budget approval and a parallel-Claude execution environment.

---

## B5 — Actual 300 benchmark runs

**Status:** BLOCKED — out-of-session infra required  
**What it needs:**

- A terminal session with `claude` CLI in PATH and an active API key with sufficient quota.
- Parallel-Claude execution: `EVAL_COUNT × RUNS_PER_EVAL × 2 configs × MAX_ITERATIONS`
  = 3 × 3 × 2 × 5 = **90 eval runs** for the standard benchmark.
  For description-optimization (run_loop.py): 5 iter × 20 queries × 3 samples × 1 skill
  = **300 description-opt runs** (separate from the eval runs above).
- Token budget approval: each `claude -p` invocation consumes 5 000–15 000 tokens.
  90 eval runs ≈ 0.5–1.4 M tokens. 300 desc-opt runs ≈ 1.5–4.5 M tokens.
- Script to invoke: `plans/260417-1715-insights-skills-layer/scripts/run-evidence-gate-benchmark.sh`

**Unblock by:**
```bash
CLAUDE_RUN_TOKEN_CAP=5000000 \
  bash plans/260417-1715-insights-skills-layer/scripts/run-evidence-gate-benchmark.sh \
  --max-iterations 5 --runs-per-eval 3
```

---

## B6 — Iterate on benchmark feedback

**Status:** BLOCKED — depends on B5 actual results  
**What it needs:**

- `iteration-1/benchmark.json` produced by B5 runs.
- Human review of `eval-viewer/generate_review.py` output.
- User sign-off on which assertions to tighten before iteration 2.

**Unblock by:** completing B5 and running:
```bash
python -m scripts.aggregate_benchmark \
  plans/260417-1715-insights-skills-layer/evals/evidence-gate/iteration-1 \
  --skill-name evidence-gate
```

---

## B7 — Description optimization (run_loop.py)

**Status:** BLOCKED — needs `claude -p` budget + eval-viewer setup  
**What it needs:**

- `skill-creator/scripts/run_loop.py` available in PATH.
- 20-query trigger-eval set (separate from execution evals; to be authored per
  skill-creator §"Description Optimization" Step 1).
- Token budget: ~1.5–4.5 M tokens for 5 optimization iterations.
- A browser or `--static` fallback to view `eval-viewer/generate_review.py` output.

**Unblock by:**
1. Author the 20-query trigger-eval set (not yet written).
2. Run:
   ```bash
   python -m scripts.run_loop \
     --eval-set plans/260417-1715-insights-skills-layer/evals/evidence-gate/trigger-evals.json \
     --skill-path ~/.claude/skills/evidence-gate \
     --model claude-sonnet-4-6 \
     --max-iterations 5 \
     --verbose
   ```

---

## B8 — Functional validation (manual)

**Status:** BLOCKED — requires manual user invocation in a live Claude Code session  
**What it needs:**

- User opens a real debugging scenario (e.g. an OCR miss in `yt-transition-shorts-detector`).
- User invokes `/evidence-gate` manually and confirms:
  - `.debug/<issue-id>/evidence.md` is created before any `src/` edit.
  - All required sections are non-empty.
  - The skill correctly declines to trigger on a pure refactor prompt.

**Unblock by:** user running a live session with the `/evidence-gate` skill active.

---

## Already complete (in-session)

| Phase | Deliverable | Status |
|-------|-------------|--------|
| B1 | `/evidence-gate` SKILL.md | ✅ shipped (`~/.claude/skills/evidence-gate/SKILL.md`) |
| B4 | `evals/evidence-gate/evals.json` (3 entries) | ✅ |
| B4 | `evals/evidence-gate/eval_metadata.json` | ✅ |
| B5 | `scripts/run-evidence-gate-benchmark.sh` scaffold | ✅ |
| B-residual | This document | ✅ |
