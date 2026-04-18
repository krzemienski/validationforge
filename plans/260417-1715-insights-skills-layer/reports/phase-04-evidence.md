# Phase B4 Evidence

Branch: `insights/phase-0-schema-freeze`  
Date: 2026-04-17

---

## 1. evals.json content

File: `plans/260417-1715-insights-skills-layer/evals/evidence-gate/evals.json`

```json
{
  "skill_name": "evidence-gate",
  "evals": [
    {
      "id": 1,
      "prompt": "hey the OCR is dropping the sponsored label on frame 340 of seq_B_120-150s.mp4 — WhiteTextOCR should catch it but phase1.json shows nothing at that timestamp. can you fix it in src/yt_shorts_detector/ocr.py?",
      "expected_output": "Model invokes evidence-gate and creates .debug/ocr-dropping-sponsored/evidence.md BEFORE touching any file under src/. The evidence.md must contain: observed symptom (frame 340, seq_B_120-150s.mp4, no label in phase1.json vs expected label visible), a visual evidence path (extracted frame PNG or mask image), a shell command that reproduces the miss, and ONE specific hypothesis naming a function or line number in ocr.py as the suspected root cause. Model does not emit any Edit/Write on src/ until all sections are filled.",
      "files": [],
      "expectations": []
    },
    {
      "id": 2,
      "prompt": "login is working fine on my local machine but keeps throwing 500s in staging whenever a user tries to sign in with Google OAuth — started right after yesterday's deploy to staging.example.com. logs are in /var/log/app/auth.log. can you debug this and fix it?",
      "expected_output": "Model invokes evidence-gate and creates .debug/staging-oauth-500/evidence.md before any code edit. Observed symptom section explicitly contrasts local (passes) vs staging (500 on Google OAuth callback). Visual evidence path references auth.log or a captured HTTP response showing the 500 body. Minimal repro names the staging URL and OAuth endpoint. Hypothesis section names ONE specific function, env var, or config key suspected to differ between environments. No edits to src/ or lib/ until evidence.md is complete.",
      "files": [],
      "expectations": []
    },
    {
      "id": 3,
      "prompt": "rename handle_click to on_click across the whole codebase — wrong name from the start, no bug, just want consistent naming before the PR review tomorrow",
      "expected_output": "Model does NOT invoke evidence-gate. It recognises this as a pure rename refactor with no behavior change (explicitly excluded in the skill's 'When NOT to invoke' section) and proceeds directly: grep for all occurrences of handle_click, then apply the rename via Edit or a bulk-replace bash command. Evidence-gate must not appear in the model's workflow.",
      "files": [],
      "expectations": []
    }
  ]
}
```

---

## 2. jq validation exit codes

```
=== jq evals.json ===
EXIT:0

=== jq eval_metadata.json ===
EXIT:0
```

Both files are schema-valid JSON. `jq -e .` exited 0 for each.

---

## 3. bash -n result

```
bash -n: EXIT 0
```

`scripts/run-evidence-gate-benchmark.sh` passes bash syntax check with no errors.

---

## 4. Dry-run output of run-evidence-gate-benchmark.sh

Command: `bash scripts/run-evidence-gate-benchmark.sh --dry-run --max-iterations 1`

```
[INFO] loaded 3 evals from .../evals/evidence-gate/evals.json
[INFO] TOKEN_CAP=2000000  MAX_ITERATIONS=1  RUNS_PER_EVAL=3  DRY_RUN=true
[INFO] === iteration 1 / 1 ===

# ── eval 1  run 1  [WITH SKILL] ──
claude -p $'hey the OCR is dropping the sponsored label on frame 340 of seq_B_120-150s.mp4...' \
  --allowedTools Read,Grep,Glob,Bash(git *),Bash(node *),Bash(python3 *),Edit,Task \
  --disallowedTools WebFetch,WebSearch \
  --output-format json \
  --verbose \
  --skill /Users/nick/.claude/skills/evidence-gate \
  > ...iteration-1/eval-1-with-skill/run-1/outputs/transcript.json

# ── eval 1  run 1  [BASELINE — no skill] ──
[same prompt, no --skill flag]
  > ...iteration-1/eval-1-baseline/run-1/outputs/transcript.json

[... repeated for runs 2, 3 × evals 2, 3 ...]

# ── DRY RUN COMPLETE ──
# Total planned invocations: 18 claude -p calls
# Token cap: 2000000
# Workspace: .../evals/evidence-gate
```

18 invocations = 3 evals × 3 runs × 2 configs (with-skill + baseline). Correct.

---

## 5. SKILL.md trigger analysis — why each eval prompt is/isn't a valid trigger

From `~/.claude/skills/evidence-gate/SKILL.md`:

### When to invoke
> - You are about to change code to fix a bug.
> - Something is "failing" and you have an instinct to patch.
> - A test (real reproduction, not a unit test) is red and you want to edit the code under test.
> - Someone asks "why is X failing" and the fix is not yet obvious.

### When NOT to invoke
> - Pure refactor with no behavior change — not a bug, not in scope.
> - Adding a new feature — use a plan skill instead.
> - You already have a fully-filled `.debug/<issue-id>/evidence.md` from a prior invocation — reuse it.

---

### Eval 1 — ocr-sponsored-label-missing-frame-340

**Prompt excerpt:** `"the OCR is dropping the sponsored label on frame 340 … can you fix it in src/yt_shorts_detector/ocr.py?"`

**Should trigger: YES**

Matches "You are about to change code to fix a bug" exactly. The user names the
broken file (`ocr.py`), the artifact (`seq_B_120-150s.mp4`), and the symptom
(missing label in phase1.json). This is the canonical happy-path trigger for
evidence-gate: a concrete bug report with a specific file to edit.

---

### Eval 2 — staging-oauth-500-post-deploy

**Prompt excerpt:** `"login … keeps throwing 500s in staging … can you debug this and fix it?"`

**Should trigger: YES**

Matches "Someone asks 'why is X failing' and the fix is not yet obvious." The
staging-vs-local contrast makes it harder (no obvious root cause from the prompt
alone), which is why this is the "harder" eval — evidence-gate must still gate
the edit even when the root cause is unknown and the logs are on a remote host.

---

### Eval 3 — rename-handle-click-refactor-no-trigger

**Prompt excerpt:** `"rename handle_click to on_click … no bug, just want consistent naming"`

**Should trigger: NO**

Explicitly excluded: "Pure refactor with no behavior change — not a bug, not in
scope." The user explicitly states "no bug". Triggering evidence-gate here would
be overreach and annoy the user. The correct behaviour is to skip evidence-gate
and proceed with a grep-based rename.
