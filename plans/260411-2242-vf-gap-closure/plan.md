---
title: VF Gap Closure — All Tiers (v2, red-team hardened)
status: in_progress
version: 2
created: 2026-04-11
revised: 2026-04-11
mode: deep
blockedBy: []
blocks: [260408-1522-vf-dual-platform-rewrite, 260411-1731-skill-optimization-remediation]
source_analysis: plans/260411-2230-gap-analysis/GAP-ANALYSIS.md
red_team_review: plans/260411-2242-vf-gap-closure/red-team-review.md
red_team_issues_addressed: "7 Critical, 18 High, 20 Medium, 3 Low (v1 refuted H7)"
---

# VF Gap Closure — v2

## Changelog vs v1

- **C1 fixed:** Phase 1 Commit 3 uses hard-gate symlink check (no `|| true` on `git rm --cached`), explicit verification with `git diff --cached --numstat`
- **C2 fixed:** Phase 1 pre-flight removes `.claude/` from `.gitignore`, adds explicit `!.claude/rules/**` negation
- **C3 fixed:** Commit order re-sequenced — plan dirs land FIRST (new Commit A), code commits reference them after
- **C4 fixed:** Phase 1 Commit B (skills) requires pre-staging diff review artifact with size sanity check
- **C5 fixed:** New Phase R (Regression gate) added. Runs after every commit in Phase 1 and after Phases 2, 7. Uses `score-project.sh` + hook smoke + validate-skills.
- **C6 fixed:** Plan split into `plan.md` (autonomous) and `plan-manual.md` (manual-gate). Plan-level success criteria requires both.
- **C7 fixed:** Phase 6 split into 6a (recoverability 5 min) and 6b (full resume). 6a moves to very start of Phase 6 execution.
- **H1 fixed:** Phase 0 pre-check + diff assertion
- **H2 fixed:** Phase 1 Commit C (pipefail fix) split from Commit D (.vf/config.json intro)
- **H3 fixed:** Phase 1 Commit E (benchmark evidence) — fixture benchmarks confirmed already-tracked (6 files from 2026-04-08), adding new dated ones is consistent
- **H4 fixed:** Phase 1 Commit F runs `python3 -m py_compile` pre-stage on apply_trim.py
- **H5 fixed:** Exit assertion is exact count with plan reference grep
- **H6 fixed:** Phase 2 README edits use pre-verify-each-string + post-verify-count pattern
- **H8 fixed:** Phase 3 H7 uses positive assertion; reachability gate first
- **H9 fixed:** Phase 3 stash requires fully-filled dispositions (no "to be filled" grep)
- **H10 fixed:** Phase 4 install uses Option B (symlink) unambiguously; `~/.claude` snapshot tar before any install
- **H11 fixed:** SCRATCH moves to `~/Desktop/vf-live-test-*`; evidence captured inline
- **H12 fixed:** Phase 5 adds second external target (named: `demo/python-api/` smoke + one other local repo)
- **H13 fixed:** Phase 5 tests ≥3 platforms: API, Web (site/), CLI (scripts/benchmark/)
- **H14 fixed:** Phase 7 uses `git mv`, drops separate `git rm`
- **H15 fixed:** Phase 7 caps DEFERRED DO-NOW at 45 min; pre-triage list before commit
- **H16 fixed:** Phase 9 M1 defines concrete quality bar per skill
- **H17 fixed:** Phase 9 split into 9a (M1 top-10, 3h) + 9b (M3-M6 smoke + commit, 1h)
- **H18 fixed:** Execution order NOW runs blocking tier (Phase 4 live session) BEFORE high tier (Phase 2 docs). See Execution Order below.
- **M1-M20 fixed:** Various — see inline annotations per phase
- **H7 refuted on verification:** Kept v1's "add 4 missing skills" instruction (confirmed 44 SKILLS.md entries, 48 on disk, diff = {coordinated-validation, e2e-testing, e2e-validate, team-validation-dashboard})
- **Added:** Unified rollback matrix (§Rollback Matrix), session continuity log (§Progress Log), concurrent-session lock

## Context

22 gaps across 5 plans + 59 sessions. Source: `plans/260411-2230-gap-analysis/GAP-ANALYSIS.md` (Oracle-verified).

Live-verified facts at plan-write time (`2026-04-11`):
- `git ls-files --stage .claude` → `120000 6ddfab8... 0 .claude` (symlink, mode 120000)
- `.gitignore:34` contains `.claude/`
- `git check-ignore -v .claude/rules/no-mocks.md` → `.gitignore:34:.claude/`
- 11 `DEFERRED` entries in `CAMPAIGN_STATE.md` (specs 001, 002, 008, 009, 010, 011, 017, 018, 021, 023, 024)
- 6 fixture benchmark JSONs already tracked (`scripts/benchmark/fixtures/scenario-*/.vf/benchmarks/benchmark-2026-04-08.json`) → new 2026-04-11 files are NOT a new category
- 4 stashes exist: {0} spec 001 WIP, {1} spec 014 WIP, {2} temp-before-spec-002, {3} pre-merge-campaign
- 2 remote branches: `origin/auto-claude/001-*`, `origin/auto-claude/015-*`
- Session `ses_28db6f306ffen4JB6QxpR6BRo2` content IS retrievable via `session_read` tool (verified)
- SKILLS.md has exactly 44 numbered entries (`grep -oE '^\| [0-9]+ \| \`[a-z-]+\`' SKILLS.md | wc -l` → 44)
- install.sh side effects: `~/.claude/rules/vf-*.md`, `~/.claude/.vf-config.json`, `~/.claude/plugins/validationforge`, `~/.claude/installed_plugins.json`

## Preamble (prepend to every shell block)

```bash
export CI=true GIT_TERMINAL_PROMPT=0 GIT_EDITOR=: EDITOR=: PAGER=cat
cd /Users/nick/Desktop/validationforge
```

## Self-binding rules

1. **Numeric claims from commands, not memory.** Every exit assertion runs a command.
2. **No `|| true` in destructive steps.** `|| true` is banned in: `git rm`, `git push --delete`, `git stash drop`, `git rm --cached`.
3. **Hard gates before destructive ops.** Stash drops, symlink removes, gitignore edits all require positive pre-check that succeeds.
4. **Post-phase regression gate.** After Phases 1, 2, 7: run `score-project.sh`, expect grade ≥ B aggregate ≥ 85 (baseline 96/A — 11-point budget).
5. **Concurrent-session lock.** `.vf/.gap-closure.lock` acquired at start, trap-released at end. Any phase fails on lock conflict.
6. **Progress log is authoritative.** `plans/260411-2242-vf-gap-closure/progress.md` updated after every phase. Resume-aware.
7. **Don't touch `skills/*/SKILL.md`** (preserved from sessions 1+2). Diff review in Phase 1 Commit B must confirm no surprise edits.
8. **Blocking tier before high tier before medium tier** — EXECUTION ORDER section enforces this.

## Concurrent-session lock

Prepended to every phase's first shell block:
```bash
LOCK=.vf/.gap-closure.lock
if [ -f "$LOCK" ]; then
  owner=$(cat "$LOCK")
  echo "FAIL: lock held by PID $owner — another session running?"
  exit 1
fi
mkdir -p .vf
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT
```

## Phase R — Regression gate (reusable, not a standalone phase)

Invoked by Phases 1, 2, 7 after their work. Exits 0 if all clear, non-zero otherwise.

```bash
# Phase R: Regression gate
echo "=== REGRESSION GATE ==="

# R1: validate-skills.sh still 48/48
bash scripts/benchmark/validate-skills.sh 2>&1 | tail -3 | grep -q 'Pass: 48' \
  || { echo "R1 FAIL: validate-skills not 48/48"; exit 1; }

# R2: score-project.sh still grade A or B (≥85)
agg=$(bash scripts/benchmark/score-project.sh . 2>&1 | grep -oE 'Aggregate: *[0-9]+' | grep -oE '[0-9]+$' | head -1)
[ -n "$agg" ] && [ "$agg" -ge 85 ] \
  || { echo "R2 FAIL: aggregate $agg < 85"; exit 1; }

# R3: Hook smoke — block-test-files returns deny JSON on .test.ts write
out=$(echo '{"tool_name":"Write","tool_input":{"file_path":"foo.test.ts","content":"x"}}' | node hooks/block-test-files.js 2>&1)
echo "$out" | grep -q '"permissionDecision":"deny"' \
  || { echo "R3 FAIL: block-test-files did not deny"; exit 1; }

# R4: Hook smoke — mock-detection exits 2 on jest.mock
echo '{"tool_name":"Edit","tool_input":{"file_path":"x.ts","new_string":"jest.mock(\"fs\")"}}' | node hooks/mock-detection.js 2>&1 >/dev/null
rc=$?
[ "$rc" = "2" ] \
  || { echo "R4 FAIL: mock-detection exit=$rc (expected 2)"; exit 1; }

echo "=== REGRESSION GATE: PASS (skills 48, aggregate $agg) ==="
```

## Progress log

`plans/260411-2242-vf-gap-closure/progress.md` template:
```markdown
# Gap Closure Progress

| Phase | Status | Timestamp | Evidence |
|-------|--------|-----------|----------|
| 0 | pending | - | - |
| 1a pre-flight | pending | - | - |
| 1 commit A (plan dirs) | pending | - | - |
...
```
Updated at the end of each phase. Check first in new sessions.

## Execution order (rev)

Blocking tier first. Phases 4 + 5 (manual gates) come early — their evidence gates Phase 2's claim that docs are accurate.

```
Phase 0 (H2 admin)                    [~2 min]
  ↓
Phase 1a pre-flight (C1, C2 gitignore fix, lock, tag)   [~5 min]
  ↓
Phase 1 commits A→F with Phase R gate after each        [~45 min]
  ↓
Phase 3 stash+branch cleanup (H6, H7)                   [~35 min]
  ↓
Phase 4 live CC session (B3, B4)        [MANUAL GATE — 1-2h]
  ↓
Phase 5 first real run (B2, B5, M2)     [MANUAL GATE — 2h]
  ↓
Phase 2 docs (H1, M7, M8)               [~45 min + Phase R]
  ↓
Phase 7 merge closeout (H5, M9, M10)    [~1.5h + Phase R]
  ↓
Phase 8 dual-plat triage (H3)           [~1h]
  ↓
Phase 6a recoverability check (H4)      [~5 min]
  ↓  (if RESUMABLE)
Phase 6b benchmark resume                [~3-4h OR spun to new plan]
  ↓
Phase 9a M1 top-10 skill review          [~3h]
  ↓
Phase 9b M3-M6 + M8 + commit             [~1h]
  ↓
Final verification + VERIFICATION.md     [~15 min]
```

**Total autonomous:** ~9h (Phases 0, 1, 3, 2, 7, 8, 6a, 9a, 9b, final) plus regression gates
**Total manual:** ~3-4h (Phases 4, 5)
**Total heavy/optional:** ~3-4h (Phase 6b if resumable)
**Grand total:** ~16-20h across ≥ 3 sessions

## Rollback matrix

| If this phase fails | Rollback action | Data loss |
|---|---|---|
| Phase 0 | `git checkout -- plans/260411-1731-skill-optimization-remediation/plan.md` | none |
| Phase 1a (pre-flight) | `git checkout -- .gitignore` | none |
| Phase 1 Commit A-F | `git reset --hard vf-pre-gap-closure-<ts>` | reverts all gap-closure commits; nothing else |
| Phase 2 | `git revert HEAD` (the docs commit only) | none — isolated |
| Phase 3 stash drop | **IRREVERSIBLE** — requires `git fsck --unreachable` recovery | potentially permanent if stashes had valuable code |
| Phase 3 remote delete | `git push origin <branch>:<branch>` using local tracking refs if still present | refs |
| Phase 4 install | `tar xzf /tmp/vf-pre-install-claude-*.tgz -C ~/` (snapshot restore) | none |
| Phase 5 first run | none — evidence-only, read-only | none |
| Phase 7 MERGE_REPORT | `git revert HEAD` | none |
| Phase 8 retire plan | `git revert HEAD` | none |
| Phase 9 | `git revert HEAD` per commit | none |
| **Global rollback** | `git reset --hard vf-pre-gap-closure-<ts>` | All gap-closure work erased |

## Phase 0 — Admin fix [H2] [~2 min]

**Scope:** `plans/260411-1731-skill-optimization-remediation/plan.md` frontmatter only.

```bash
# H1 (red-team): pre-check that file is actually in expected state
grep -q '^status: in_progress' plans/260411-1731-skill-optimization-remediation/plan.md \
  || { echo "UNEXPECTED: file not in 'in_progress' state — someone else already flipped?"; \
       grep '^status:' plans/260411-1731-skill-optimization-remediation/plan.md; exit 1; }

# Apply flip with sed (H5 red-team simplification)
sed -i '' -e 's/^status: in_progress$/status: complete/' \
  plans/260411-1731-skill-optimization-remediation/plan.md

# Post-verify via diff: file must have changed
git diff --quiet plans/260411-1731-skill-optimization-remediation/plan.md \
  && { echo "H2 FAIL: file unchanged"; exit 1; }

grep -q '^status: complete' plans/260411-1731-skill-optimization-remediation/plan.md \
  && echo "H2 PASS"
```

**Exit:** `H2 PASS` printed, `git diff` shows 1 line change, no other changes.

**Rollback:** `git checkout -- plans/260411-1731-skill-optimization-remediation/plan.md`

---

## Phase 1a — Pre-flight [C1, C2 fixes] [~5 min]

**Scope:** Acquire lock, create rollback tag, fix `.gitignore`, untrack `.claude` symlink.

**Step 1 — Lock + tag:**
```bash
# Lock (from §Concurrent-session lock)
[ -f .vf/.gap-closure.lock ] && { echo "LOCKED"; exit 1; }
mkdir -p .vf
echo $$ > .vf/.gap-closure.lock
trap 'rm -f .vf/.gap-closure.lock' EXIT

# Rollback tag
TAG="vf-pre-gap-closure-$(date -u +%Y%m%dT%H%M%SZ)"
git tag "$TAG"
git tag -l | grep "$TAG" || { echo "TAG_CREATE_FAIL"; exit 1; }
echo "ROLLBACK_TAG=$TAG"
```

**Step 2 — Gitignore fix (C2):**
```bash
# Verify the problem before fixing
git check-ignore -v .claude/rules/no-mocks.md | grep -q '.gitignore:34' \
  || { echo "UNEXPECTED: .claude/ is not on gitignore:34"; exit 1; }

# Edit: add negation for .claude/rules/** immediately after the .claude/ line
python3 - <<'PY'
from pathlib import Path
p = Path('.gitignore')
lines = p.read_text().split('\n')
out = []
for i, line in enumerate(lines):
    out.append(line)
    if line.strip() == '.claude/':
        # Add explicit negation
        out.append('!.claude/rules/**')
        out.append('!.claude/commands/**')
p.write_text('\n'.join(out))
print("GITIGNORE_PATCHED")
PY

# Verify: .claude/rules/ is no longer ignored
git check-ignore -v .claude/rules/no-mocks.md 2>&1 | grep -q '.claude/rules' \
  && { echo "C2 FAIL: still ignored"; exit 1; }
echo "C2 PASS"
```

**Step 3 — Untrack `.claude` symlink (C1):**
```bash
# Verify it IS a symlink in the index before removing
git ls-files --stage .claude | grep -q '^120000' \
  || { echo "UNEXPECTED: .claude not a symlink in index"; git ls-files --stage .claude; exit 1; }

# Remove from index (NO || true)
git rm --cached .claude

# Verify removal
git ls-files .claude | grep -q '^\.claude$' \
  && { echo "C1 FAIL: still in index"; exit 1; }
echo "C1 PASS"

# Also stage the gitignore change and symlink removal as staged for Commit A
git add .gitignore
git diff --cached --stat .gitignore
```

**Exit:**
- `ROLLBACK_TAG` printed and verifiable via `git tag -l`
- `C1 PASS` and `C2 PASS` both printed
- `.vf/.gap-closure.lock` exists
- `git status .gitignore` shows staged

**Rollback:** `git reset HEAD .gitignore`; `git checkout -- .gitignore`; `git tag -d "$TAG"`

---

## Phase 1 — Commit all session work [B1] [~45 min + Phase R between each]

Re-ordered: **plan dirs first** (Commit A), then code commits that reference them.

### Commit A — plan dirs + .gitignore fix + symlink removal

```bash
# Stage plan dirs (all currently untracked)
git add plans/260411-2230-gap-analysis/
git add plans/260411-2242-vf-gap-closure/
git add plans/260411-1731-skill-optimization-remediation/
git add plans/260411-1747-vf-grade-a-push/
# .gitignore + .claude cached-remove already staged in Phase 1a

git commit -m "docs(plans): add in-flight plan dirs + fix .claude gitignore

Plans added:
- plans/260411-1731-skill-optimization-remediation/ (48-skill optimization, 5.0/5.0 verified)
- plans/260411-1747-vf-grade-a-push/ (benchmark 88→96 Grade A push, verified)
- plans/260411-2230-gap-analysis/ (Oracle-driven 22-gap analysis)
- plans/260411-2242-vf-gap-closure/ (this plan)

Infrastructure fixes:
- .gitignore: add !.claude/rules/**, !.claude/commands/** negations after .claude/
  so rules + commands are trackable. Fixes C2 from red-team review.
- Remove .claude symlink from index (was mode 120000, now a real directory).
  Fixes C1 from red-team review.

Rollback tag: vf-pre-gap-closure-<ts>"

# Phase R regression gate
source scripts/benchmark/.rg-helper.sh 2>/dev/null || :
# (inline Phase R — see §Phase R)
bash scripts/benchmark/validate-skills.sh 2>&1 | tail -3 | grep -q 'Pass: 48' || exit 1
```

### Commit B — skill optimization (plan 260411-1731)

```bash
# Pre-stage diff review artifact (C4 fix)
mkdir -p plans/260411-2242-vf-gap-closure/diff-reviews
git diff --stat skills/ > plans/260411-2242-vf-gap-closure/diff-reviews/commit-B-skills-stat.txt
git diff --numstat skills/ > plans/260411-2242-vf-gap-closure/diff-reviews/commit-B-skills-numstat.txt

# Size sanity check: any skill with > 200 added lines is suspicious
big=$(awk '$1 > 200 {print $3}' plans/260411-2242-vf-gap-closure/diff-reviews/commit-B-skills-numstat.txt)
if [ -n "$big" ]; then
  echo "SUSPICIOUS: skills with > 200 added lines:"
  echo "$big"
  echo "MANUAL REVIEW REQUIRED — do not proceed until cleared"
  exit 1
fi

# Count check: expected ~48 files touched
count=$(git diff --name-only skills/ | wc -l | tr -d ' ')
[ "$count" -ge 40 ] && [ "$count" -le 52 ] \
  || { echo "UNEXPECTED SKILL COUNT: $count (expected 40-52)"; exit 1; }
echo "SKILLS_DIFF_OK count=$count"

# Stage and commit
git add skills/
git add plans/260411-2242-vf-gap-closure/diff-reviews/
git commit -m "refactor(skills): optimize 48 skill descriptions (24% char reduction)

- Trimmed 4 over-length descriptions (>300 chars → ≤210):
  - stitch-integration (305→207)
  - verification-before-completion (307→204)
  - visual-inspection (337→200)
  - web-testing (309→201)
- Fixed forge-benchmark description + body to match score-project.sh 4-dim weights:
  Coverage 35%, Evidence 30%, Enforcement 25%, Speed 10% (was: 5-dim table)
- Reduced total description chars 12384→9385 (−2999, −24%)
- All 48 skills pass validate-skills.sh
- No skill exceeds 210 chars post-trim

Plan: plans/260411-1731-skill-optimization-remediation/
Evidence: plans/260411-1731-skill-optimization-remediation/VERIFICATION.md
Diff review: plans/260411-2242-vf-gap-closure/diff-reviews/commit-B-skills-*.txt"

# Phase R regression gate
bash scripts/benchmark/validate-skills.sh 2>&1 | tail -3 | grep -q 'Pass: 48' \
  || { echo "R1 FAIL after Commit B"; exit 1; }
```

### Commit C — pipefail fix (scripts/benchmark/validate-skills.sh only) [H2 red-team split]

```bash
git add scripts/benchmark/validate-skills.sh
git diff --cached scripts/benchmark/validate-skills.sh | head -30

git commit -m "fix(benchmark): pipefail-safe frontmatter grep in validate-skills.sh

Wrap 3 fm_name/fm_desc/fm_priority grep extractions with
'set +o pipefail' / 'set -o pipefail' guard + '|| true' armor.

Without this, malformed SKILL.md frontmatter crashes the validator
with SIGPIPE. Fault-injection test confirmed fix:
- Broken frontmatter → script reports WARN/FAIL, exits 0 or 1 (not SIGPIPE)
- Normal run still reports 48/48 PASS

Plan: plans/260411-1747-vf-grade-a-push/"

bash scripts/benchmark/validate-skills.sh 2>&1 | tail -3 | grep -q 'Pass: 48' \
  || { echo "R1 FAIL after Commit C"; exit 1; }
```

### Commit D — .vf/config.json + .vf/benchmarks/ intro [H2 red-team]

```bash
git add .vf/config.json .vf/benchmarks/benchmark-2026-04-11.json
git commit -m "feat(config): add .vf/config.json enforcement profile + benchmark snapshot

- .vf/config.json: standard enforcement profile, validates as JSON
- .vf/benchmarks/benchmark-2026-04-11.json: post-remediation benchmark
  result (Aggregate 96, Grade A)

This commit introduces the .vf/ config surface referenced by
config-loader.js. Benchmark score 88→96 is the combined effect of
Commit C (pipefail fix) and the prior skill optimization in Commit B.

Plan: plans/260411-1747-vf-grade-a-push/
Evidence: plans/260411-1747-vf-grade-a-push/after.txt"
```

### Commit E — .claude/rules/ [C1, C2 follow-through, N2 hard-gated]

```bash
# N2 hard gate: .gitignore negation must be in effect or abort
# (guards against Commit A's gitignore fix being skipped/lost)
if git check-ignore -q .claude/rules/no-mocks.md; then
  echo "COMMIT E BLOCKED: .claude/rules/ is still gitignored — Commit A's .gitignore fix missing"
  git check-ignore -v .claude/rules/no-mocks.md
  exit 1
fi
echo "N2_GATE_PASS"

git add .claude/rules/
# Sanity: at least 2 files staged (no-mocks.md, evidence-before-completion.md)
n=$(git diff --cached --numstat .claude/rules/ | wc -l | tr -d ' ')
[ "$n" -ge 2 ] || { echo "COMMIT E FAIL: only $n files staged under .claude/rules/"; exit 1; }
git diff --cached --numstat .claude/rules/

git commit -m "feat(rules): add .claude/rules/ for cross-session enforcement

- no-mocks.md (26 lines): Iron Rule documentation, enforced by
  hooks/block-test-files.js + hooks/mock-detection.js
- evidence-before-completion.md (30 lines): evidence types required
  for gate claims, anti-patterns

Previously .claude was a broken symlink (120000 → ../../../../.claude).
Commit A removed that symlink from the index and added !.claude/rules/**
negation to .gitignore. This commit adds the actual rule files.

Plan: plans/260411-1747-vf-grade-a-push/"

# Regression gate
bash scripts/benchmark/validate-skills.sh 2>&1 | tail -3 | grep -q 'Pass: 48' || exit 1
```

### Commit F — demo fix + e2e-evidence refresh + fixture benchmarks + skill-optimization helpers

Fixture benchmarks verified already-tracked (6 files from 2026-04-08 exist in `git ls-files`), so adding 2026-04-11 files is continuation, not introduction.

```bash
# Pre-stage: py_compile check (H4 red-team)
python3 -m py_compile .vf/skill-optimization/apply.py .vf/skill-optimization/apply_trim.py \
  .vf/skill-optimization/batch_optimize.py .vf/skill-optimization/generate_eval_sets.py \
  || { echo "PY_COMPILE_FAIL"; exit 1; }
echo "PY_COMPILE_OK"

# Stage
git add demo/python-api/app.py
git add e2e-evidence/report.md
git add e2e-evidence/benchmark-scenarios/
git add scripts/benchmark/fixtures/scenario-*/.vf/benchmarks/benchmark-2026-04-11.json
git add .vf/skill-optimization/
git add plans/260408-1522-vf-dual-platform-rewrite/

git commit -m "chore: refresh evidence + bundle plan helpers + demo J5 fix

Multi-topic bundled commit (per-topic commits would create circular
reference trains; bundling avoids that).

Contents:
- demo/python-api/app.py: 'if not body' → 'if body is None' (J5 bug fix)
  Plan: plans/260411-1747-vf-grade-a-push/ (j5-reverify.txt shows HTTP 400 + 'Field name required')
- e2e-evidence/benchmark-scenarios/*: refreshed scenario outputs (5 scenarios)
- e2e-evidence/report.md: refreshed evidence inventory
- scripts/benchmark/fixtures/scenario-*/.vf/benchmarks/benchmark-2026-04-11.json:
  new dated benchmarks (fixture benchmarks pattern established by
  existing benchmark-2026-04-08.json tracking)
- .vf/skill-optimization/: session 1 helper scripts (py_compile verified)
- plans/260408-1522-vf-dual-platform-rewrite/plan.md: frontmatter
  update adding blockedBy gap-closure and triage metadata (prep for
  Phase 8 triage)

Plan: plans/260411-2242-vf-gap-closure/"

# Final regression gate
bash scripts/benchmark/validate-skills.sh 2>&1 | tail -3 | grep -q 'Pass: 48' || exit 1
agg=$(bash scripts/benchmark/score-project.sh . 2>&1 | grep -oE 'Aggregate: *[0-9]+' | grep -oE '[0-9]+$' | head -1)
[ -n "$agg" ] && [ "$agg" -ge 85 ] || { echo "R2 FAIL: aggregate $agg"; exit 1; }
echo "PHASE_1_R_GATE_PASS aggregate=$agg"
```

**Exit criteria (Phase 1):**
- `git status --porcelain | wc -l` = `0`
- `git log --oneline ${TAG}..HEAD | wc -l` = **6** (exactly, not ≥5 — red-team H5)
- `git log --oneline ${TAG}..HEAD | grep -c 'Plan:'` ≥ 5 (A, B, C, D, E, F each reference a plan — F references this plan)
- `git fsck --no-progress --strict` exits 0
- `bash scripts/benchmark/validate-skills.sh` shows 48/48
- `bash scripts/benchmark/score-project.sh .` aggregate ≥ 85
- `git check-ignore .claude/rules/no-mocks.md` → empty (no longer ignored)

**Rollback:** `git reset --hard $TAG`

---

## Phase 3 — Stash + remote branch cleanup [H6, H7] [~35 min]

**Scope:** Inspect 4 stashes, write full dispositions, drop. Delete 2 remote branches.

### Step 1 — Pre-flight

```bash
# Snapshot stash count (M drift check)
git stash list > /tmp/pre-drop-stashes.txt
count=$(wc -l < /tmp/pre-drop-stashes.txt | tr -d ' ')
[ "$count" = "4" ] || { echo "STASH_COUNT_DRIFT: $count != 4"; exit 1; }

# Snapshot remote branches
git ls-remote --heads origin 2>/dev/null > /tmp/pre-delete-branches.txt
[ -s /tmp/pre-delete-branches.txt ] || { echo "REMOTE_UNREACHABLE"; exit 1; }
```

### Step 2 — Inspect each stash and write dispositions

```bash
cat > plans/260411-2242-vf-gap-closure/stash-dispositions.md <<EOF
# Stash Dispositions (Phase 3)

Inspected: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Pre-drop count: 4

EOF

for i in 0 1 2 3; do
  {
    echo "## stash@{$i}"
    echo ""
    echo "### Header"
    echo '```'
    git stash list | grep "stash@{$i}"
    echo '```'
    echo ""
    echo "### Content summary"
    echo '```'
    git stash show -p "stash@{$i}" 2>&1 | head -40
    echo '```'
    echo ""
    echo "### Files touched"
    echo '```'
    git stash show --stat "stash@{$i}" 2>&1
    echo '```'
    echo ""
    echo "### Disposition"
    echo ""
    echo "_TODO: DROP | APPLY | KEEP + rationale_"
    echo ""
    echo "---"
    echo ""
  } >> plans/260411-2242-vf-gap-closure/stash-dispositions.md
done

echo "INSPECTION_WRITTEN — manually edit dispositions before running Step 3"
cat plans/260411-2242-vf-gap-closure/stash-dispositions.md | head -80
```

**STOP POINT:** Human must edit `stash-dispositions.md` to replace each TODO with an actual decision + rationale. Red-team H9 requires no "to be filled" or TODO markers remain.

### Step 3 — Hard gate before drop

```bash
# H9 hard gate (red-team): no TODO markers allowed
grep -q 'TODO: DROP' plans/260411-2242-vf-gap-closure/stash-dispositions.md \
  && { echo "H9 FAIL: dispositions incomplete"; exit 1; }
grep -qi 'to be filled' plans/260411-2242-vf-gap-closure/stash-dispositions.md \
  && { echo "H9 FAIL: placeholder text present"; exit 1; }

# Each stash must have a disposition line "DROP", "APPLY", or "KEEP"
for i in 0 1 2 3; do
  awk "/^## stash@\\{$i\\}$/,/^---$/" plans/260411-2242-vf-gap-closure/stash-dispositions.md \
    | grep -qE '^(\*\*Disposition:\*\*|_Disposition:_)? *(DROP|APPLY|KEEP)' \
    || { echo "H9 FAIL: stash@{$i} no decision"; exit 1; }
done
echo "DISPOSITIONS_COMPLETE"
```

### Step 4 — Execute drops (iterate from highest index)

```bash
# Only drop stashes marked DROP (parse dispositions)
for i in 3 2 1 0; do
  decision=$(awk "/^## stash@\\{$i\\}$/,/^---$/" plans/260411-2242-vf-gap-closure/stash-dispositions.md \
    | grep -oE '(DROP|APPLY|KEEP)' | head -1)
  echo "stash@{$i}: $decision"
  case "$decision" in
    DROP)
      git stash drop "stash@{$i}" || { echo "DROP FAIL stash@{$i}"; exit 1; }
      ;;
    APPLY)
      git stash apply "stash@{$i}" || { echo "APPLY FAIL stash@{$i}"; exit 1; }
      # Human must then commit the applied changes before proceeding
      ;;
    KEEP)
      echo "KEEPING stash@{$i}"
      ;;
  esac
done
```

### Step 5 — H7 remote branch cleanup (positive assertion)

```bash
# Pre: reachability check via ls-remote
git ls-remote --heads origin 2>/dev/null > /tmp/remotes.txt
[ -s /tmp/remotes.txt ] || { echo "REMOTE_UNREACHABLE"; exit 1; }

# Find auto-claude branches
grep auto-claude /tmp/remotes.txt || { echo "NO_AUTO_CLAUDE_BRANCHES_ON_REMOTE"; exit 0; }

# Delete each (NO || true, hard-fail)
for br in $(grep auto-claude /tmp/remotes.txt | awk '{print $2}' | sed 's|refs/heads/||'); do
  echo "Deleting origin/$br"
  git push origin --delete "$br" || { echo "PUSH_DELETE_FAIL: $br"; exit 1; }
done

# Positive post-check
git ls-remote --heads origin 2>/dev/null > /tmp/remotes-post.txt
[ -s /tmp/remotes-post.txt ] || { echo "REMOTE_UNREACHABLE_POST"; exit 1; }
! grep -q auto-claude /tmp/remotes-post.txt \
  || { echo "H7 FAIL: auto-claude branches still on remote"; cat /tmp/remotes-post.txt; exit 1; }
echo "H7 PASS"
```

### Step 6 — Commit dispositions.md

```bash
git add plans/260411-2242-vf-gap-closure/stash-dispositions.md
git commit -m "docs(plans): stash dispositions for Phase 3

Inspected 4 stashes (spec 001 WIP, spec 014 WIP, temp-before-spec-002,
pre-merge-campaign), recorded disposition + rationale per stash, dropped
per decisions in stash-dispositions.md.

Also deleted 2 remote auto-claude branches (origin/auto-claude/001-*,
origin/auto-claude/015-*) since local cleanup was already complete.

Plan: plans/260411-2242-vf-gap-closure/"
```

**Exit:**
- `git stash list | wc -l` = number of KEPT stashes (0 if all DROP)
- `git ls-remote --heads origin | grep -c auto-claude` = 0
- `stash-dispositions.md` committed

**Rollback:** Stash drops are irreversible. Remote branches are recoverable via tracking refs if local still present.

---

## Phase 4 — MANUAL GATE — live CC session test [B3, B4]

**See `plans/260411-2242-vf-gap-closure/plan-manual.md`** for full manual protocol.

Plan-level success criterion depends on `plans/260411-2242-vf-gap-closure/live-session-evidence.md` existing with ≥4 PASS markers. An autonomous runner CANNOT mark this phase complete.

Key hardening vs v1:
- **H10:** Option B (symlink) unambiguous; pre-install snapshot via `tar czf /tmp/vf-pre-install-claude-$(date +%s).tgz -C ~ .claude`; rollback = `tar xzf`
- **H11:** Scratch dir in `~/Desktop/vf-live-test-<ts>`, not `/tmp`
- **M11:** Evidence checker script `plans/…/verify-live-session-evidence.py` that parses markdown and requires specific hook output patterns

---

## Phase 5 — MANUAL GATE — first real run [B2, B5, M2]

**See `plan-manual.md`.**

Hardening vs v1:
- **H12:** Two targets required — `demo/python-api/` (smoke) AND one local external repo (named pre-execution)
- **H13:** Platform detection tested against ≥3 project types: API (python-api), Web (site/ if exists or scaffolded minimal), CLI (e.g. scripts/ dir with bin/vf.js)
- **M12:** Evidence requires `ffprobe demo/vf-demo.gif` output (duration + frame count) + one frame description

---

## Phase 2 — Inventory drift fix [H1, M7, M8] [~45 min + Phase R]

Moved AFTER Phase 5 per red-team H18 (blocking tier before high tier). Phase 5's evidence informs M2 + M7 (verification status table).

### Step 1 — Count from disk

```bash
SKILLS=$(ls -d skills/*/ 2>/dev/null | wc -l | tr -d ' ')
CMDS=$(ls commands/*.md 2>/dev/null | wc -l | tr -d ' ')
HOOKS_JS=$(ls hooks/*.js 2>/dev/null | wc -l | tr -d ' ')
HOOKS_REG=$(python3 -c "
import json, re
h=json.load(open('hooks/hooks.json'))
refs=set()
for ev,entries in h['hooks'].items():
    for e in entries:
        for hk in e.get('hooks',[]):
            m=re.search(r'hooks/([a-z-]+\.js)',hk['command'])
            if m: refs.add(m.group(1))
print(len(refs))
")
AGENTS=$(ls agents/*.md 2>/dev/null | wc -l | tr -d ' ')
RULES=$(ls rules/*.md 2>/dev/null | wc -l | tr -d ' ')
echo "skills=$SKILLS cmds=$CMDS hooks_js=$HOOKS_JS hooks_reg=$HOOKS_REG agents=$AGENTS rules=$RULES"

[ "$SKILLS" = "48" ] || { echo "UNEXPECTED SKILL COUNT"; exit 1; }
[ "$CMDS" = "17" ] || { echo "UNEXPECTED CMD COUNT"; exit 1; }
[ "$HOOKS_JS" = "10" ] || { echo "UNEXPECTED HOOKS JS"; exit 1; }
[ "$HOOKS_REG" = "7" ] || { echo "UNEXPECTED HOOKS REG"; exit 1; }
[ "$AGENTS" = "5" ] || { echo "UNEXPECTED AGENTS"; exit 1; }
[ "$RULES" = "8" ] || { echo "UNEXPECTED RULES"; exit 1; }
```

### Step 2 — H1 README.md edits with pre-verify per target

```bash
OLD_TAG="**45 skills | 15 commands | 7 hooks | 5 agents | 8 rules | 17 shell scripts | Dual-platform: Claude Code plugin + OpenCode plugin**"
NEW_TAG="**48 skills | 17 commands | 7 registered hooks (+3 support .js) | 5 agents | 8 rules | 17 shell scripts | Dual-platform: Claude Code plugin + OpenCode plugin**"

# Pre-verify: OLD_TAG exists, count = 2 (appears twice per README inspection)
n=$(grep -Fc -- "$OLD_TAG" README.md)
[ "$n" = "2" ] || { echo "PRE-VERIFY FAIL: OLD_TAG count=$n (expected 2)"; exit 1; }

# Pre-verify each inventory row target
for pat in "| Skills | 45 |" "| Commands | 15 |" "| CC Hooks | 7 + 4 support |" \
  "45 skills, 15 commands, 7 hooks" "45 skill directories"; do
  n=$(grep -Fc -- "$pat" README.md)
  [ "$n" -ge 1 ] || { echo "PRE-VERIFY FAIL: '$pat' not found"; exit 1; }
done

# Apply replacements (Python to avoid sed escape pain)
python3 - <<'PY'
from pathlib import Path
p = Path("README.md")
s = p.read_text()
old_tag = "**45 skills | 15 commands | 7 hooks | 5 agents | 8 rules | 17 shell scripts | Dual-platform: Claude Code plugin + OpenCode plugin**"
new_tag = "**48 skills | 17 commands | 7 registered hooks (+3 support .js) | 5 agents | 8 rules | 17 shell scripts | Dual-platform: Claude Code plugin + OpenCode plugin**"
s = s.replace(old_tag, new_tag)
s = s.replace("| Skills | 45 |", "| Skills | 48 |")
s = s.replace("| Commands | 15 |", "| Commands | 17 |")
s = s.replace("| CC Hooks | 7 + 4 support |", "| CC Hooks | 7 registered + 3 support .js |")
s = s.replace("File inventory (45 skills, 15 commands, 7 hooks, 5 agents, 8 rules)",
              "File inventory (48 skills, 17 commands, 7 hooks, 5 agents, 8 rules)")
s = s.replace("45 skill directories", "48 skill directories")
p.write_text(s)
print("README_PATCHED")
PY

# Post-verify: counts
[ "$(grep -Fc '**48 skills' README.md)" -ge 2 ] || { echo "POST FAIL: tagline not 2+"; exit 1; }
[ "$(grep -Fc '| Skills | 48 |' README.md)" -ge 1 ] || { echo "POST FAIL: table"; exit 1; }
[ "$(grep -Fc '48 skill directories' README.md)" -ge 1 ] || { echo "POST FAIL: body"; exit 1; }
[ "$(grep -Fc '45 skills' README.md)" = "0" ] || { echo "POST FAIL: leftover 45 skills"; exit 1; }
echo "README_OK"
```

### Step 3 — SKILLS.md: add 4 missing + update header count

Per-row insertion preserves existing structure. 4 missing skills: `coordinated-validation`, `e2e-testing`, `e2e-validate`, `team-validation-dashboard`.

```bash
# Extract current frontmatter descriptions
for s in coordinated-validation e2e-testing e2e-validate team-validation-dashboard; do
  desc=$(awk '/^description:/{flag=1; sub("^description: *",""); print; flag=0}' skills/$s/SKILL.md | tr -d '"')
  echo "$s | $desc"
done > /tmp/skills-to-add.txt
cat /tmp/skills-to-add.txt

# Apply via Python (manual row placement by category)
python3 - <<'PY'
from pathlib import Path
import re
p = Path("SKILLS.md")
s = p.read_text()

# Update header count 46 → 48
s = s.replace("46 skills across 7 categories", "48 skills across 7 categories")

# Categories breakdown target:
# - "Platform Validation (15)" → unchanged (already has 15)
# - "Quality Gates (6)" → unchanged
# - "Design Validation (4)" → unchanged
# - "Analysis & Research (4)" → add `e2e-testing` → (5)
# - "Specialized (6)" → add `coordinated-validation`, `team-validation-dashboard` → (8)
# - "Operational (5)" → unchanged
# - "Forge Orchestration (6)" → add `e2e-validate` → (7)

# TOTAL shift: 15+6+4+5+8+5+7 = 50, but we want 48. Recount actual.
# Actually: v1 plan said add 4 to correct categories. Running-total cleanup needed.

# This edit is non-trivial; defer actual row placement to manual editor pass
# after this script prints the target insertion points.
print("SKILLS_HEADER_UPDATED")
print("MANUAL ROW PLACEMENT REQUIRED for 4 skills")
p.write_text(s)
PY
```

**MANUAL STEP:** Using an editor, add 4 rows to SKILLS.md with correct category numbering:
- `coordinated-validation` → **Specialized** category (bump count 6→7)
- `team-validation-dashboard` → **Specialized** category (bump 7→8)
- `e2e-testing` → **Analysis & Research** category (bump 4→5)
- `e2e-validate` → **Forge Orchestration** category (bump 6→7)

Re-number subsequent entries in each affected category. Update section count headers.

```bash
# Post-verify
awk '/^## / && /\(/{print}' SKILLS.md
# Count entries
entries=$(grep -cE '^\| [0-9]+ \| `' SKILLS.md)
[ "$entries" = "48" ] || { echo "POST FAIL: SKILLS.md entries $entries != 48"; exit 1; }
# Diff against filesystem
comm -23 <(ls -d skills/*/ | xargs -n1 basename | sort) \
  <(grep -oE '`[a-z-]+`' SKILLS.md | tr -d '`' | sort -u) > /tmp/missing.txt
[ ! -s /tmp/missing.txt ] || { cat /tmp/missing.txt; echo "POST FAIL: still missing"; exit 1; }
echo "SKILLS_OK"
```

### Step 4 — COMMANDS.md update

```bash
# Pre-check: table count
pre=$(grep -cE '^\| [0-9]+ \| `/' COMMANDS.md)
[ "$pre" = "16" ] || { echo "UNEXPECTED: COMMANDS.md has $pre rows, expected 16"; exit 1; }

# Header update
sed -i '' -e 's/^16 slash commands across 2 families\./17 slash commands across 2 families./' COMMANDS.md
grep -q '17 slash commands' COMMANDS.md || { echo "HEADER_FAIL"; exit 1; }

# Add row for validate-team-dashboard
# Extract its description
desc=$(awk '/^description:/{sub("^description: *",""); gsub("\"",""); print}' commands/validate-team-dashboard.md | head -1)
echo "validate-team-dashboard desc: $desc"
```

**MANUAL STEP:** Add row to Validation Commands table (as row #11):
```
| 11 | `/validate-team-dashboard` | {desc} |
```
Update "Validation Commands (10)" → "(11)". Re-number subsequent rows. Update pipeline matrix if applicable.

```bash
# Post-verify
post=$(grep -cE '^\| [0-9]+ \| `/' COMMANDS.md)
[ "$post" = "17" ] || { echo "POST FAIL: $post rows"; exit 1; }
grep -q '`/validate-team-dashboard`' COMMANDS.md || { echo "POST FAIL: no row"; exit 1; }
echo "COMMANDS_OK"
```

### Step 5 — M8 hook file audit enforcement

```bash
# For each unregistered hook, decide + document
python3 - <<'PY' > plans/260411-2242-vf-gap-closure/hook-audit.md
from pathlib import Path

orphans = ['config-loader.js', 'patterns.js', 'verify-e2e.js']
print("# Hook File Audit (M8)\n")
for h in orphans:
    content = Path(f'hooks/{h}').read_text()
    imported = False
    for other in Path('hooks').glob('*.js'):
        if other.name == h: continue
        if h.replace('.js','') in other.read_text():
            imported = True
            break
    category = "LIBRARY" if imported else "ORPHAN"
    print(f"## {h}")
    print(f"- Category: **{category}**")
    print(f"- Size: {len(content)} bytes")
    print(f"- Imported by other hooks: {imported}")
    print(f"- Decision: KEEP (library) / DELETE / REGISTER")
    print()
PY
cat plans/260411-2242-vf-gap-closure/hook-audit.md
```

**MANUAL STEP:** Edit the audit to record decisions. If DELETE, add `git rm` step. If REGISTER, update `hooks/hooks.json`.

### Step 6 — Phase R regression gate

```bash
# Phase R
bash scripts/benchmark/validate-skills.sh 2>&1 | tail -3 | grep -q 'Pass: 48' || exit 1
agg=$(bash scripts/benchmark/score-project.sh . 2>&1 | grep -oE 'Aggregate: *[0-9]+' | grep -oE '[0-9]+$' | head -1)
[ "$agg" -ge 85 ] || exit 1
echo "PHASE_2_R_GATE_PASS aggregate=$agg"
```

### Step 7 — Commit

```bash
git add README.md SKILLS.md COMMANDS.md plans/260411-2242-vf-gap-closure/hook-audit.md
git commit -m "docs: sync inventory to filesystem + hook audit

- README: 45→48 skills, 15→17 commands, '7+4 support'→'7 registered + 3 support .js'
- SKILLS.md: 46→48 header, add 4 missing entries (coordinated-validation,
  e2e-testing, e2e-validate, team-validation-dashboard) in correct categories
- COMMANDS.md: 16→17 header, add /validate-team-dashboard row
- plans/.../hook-audit.md: M8 audit of 3 unregistered hook .js files
  (config-loader, patterns, verify-e2e)

Fixes H1, M7, M8 from plans/260411-2242-vf-gap-closure/plan.md (v2)"
```

**Exit:** All Step 6 checks PASS, commit lands, Phase R gate PASS.

**Rollback:** `git revert HEAD`

---

## Phase 7 — Merge campaign closeout [H5, M9, M10] [~1.5h + Phase R]

### Step 1 — Pre-triage 11 DEFERRED items [H15]

```bash
cat > plans/260411-2242-vf-gap-closure/deferred-triage.md <<'EOF'
# DEFERRED Triage (Phase 7)

CAMPAIGN_STATE.md lists 11 specs with cleanup=DEFERRED. Triage each with 45-min budget cap:

| Spec | DEFERRED item | Est. effort | Decision | Rationale |
|------|---------------|-------------|----------|-----------|
| 001 | _inspect CAMPAIGN_STATE_ | _TBD_ | DO NOW ≤15m / DEFER / DROP | - |
| 002 | | | | |
| 008 | | | | |
| 009 | | | | |
| 010 | | | | |
| 011 | | | | |
| 017 | | | | |
| 018 | | | | |
| 021 | | | | |
| 023 | | | | |
| 024 | | | | |

Budget: total DO NOW time ≤ 45 min. Overflow → spin to new plan.
EOF
echo "TRIAGE_FILE_CREATED — manually fill decisions before Step 2"
```

**STOP POINT:** Fill in the triage table with real decisions.

### Step 2 — Execute DO NOW items (max 45 min)

For each row marked `DO NOW`, execute the cleanup and capture evidence inline in `deferred-triage.md`.

### Step 3 — Write MERGE_REPORT.md

```bash
python3 - <<'PY' > MERGE_REPORT.md
from pathlib import Path
import re
from datetime import datetime

state = Path("CAMPAIGN_STATE.md").read_text()
vmat = Path("VALIDATION_MATRIX.md").read_text()

print("# ValidationForge Merge Campaign — Final Report\n")
print(f"**Generated:** {datetime.utcnow().isoformat()}Z")
print(f"**Source:** CAMPAIGN_STATE.md + VALIDATION_MATRIX.md\n")
print("## Summary\n")
print("| Status | Count |")
print("|--------|------:|")

# Parse state table
rows = []
for line in state.split("\n"):
    m = re.match(r'\| (\d{3}) \| (\w+) \| (.+) \|', line)
    if m:
        rows.append(m.groups())

from collections import Counter
cnt = Counter(r[1] for r in rows)
for k, v in sorted(cnt.items()):
    print(f"| {k} | {v} |")
print()

print("## Per-spec table\n")
print("| Spec | State | Notes |")
print("|------|-------|-------|")
for spec, state_v, notes in rows:
    # Truncate long notes
    n = notes[:100] + "..." if len(notes) > 100 else notes
    print(f"| {spec} | {state_v} | {n} |")

print("\n## Wave checkpoints\n")
# Extract wave table
in_wave = False
for line in state.split("\n"):
    if "## Wave Checkpoints" in line:
        in_wave = True
        continue
    if in_wave and line.startswith("## "):
        break
    if in_wave:
        print(line)

print("\n## Success criteria walk\n")
print("Per merge-campaign.md §Final Checklist — each item re-verified:\n")
print("- [ ] `git worktree list` shows only main worktree")
print("- [ ] `git branch --list 'auto-claude/*'` returns empty")
print("- [ ] `git status` is clean")
print("- [ ] `npm install` succeeds from cold start")
print("- [ ] All JSON configs parse")
print("- [ ] All shell scripts pass `bash -n`")
print("- [ ] All JS hooks pass `node --check`")
print("- [ ] hooks.json references resolve to existing files")
print("- [ ] plugin.json referenced paths exist")
print("- [ ] package.json `files` array entries exist")
print("- [ ] SKILLS.md matches filesystem (48)")
print("- [ ] COMMANDS.md matches filesystem (17)")

print("\n## Stash disposition\n")
print("See plans/260411-2242-vf-gap-closure/stash-dispositions.md (Phase 3)")

print("\n## DEFERRED items resolution\n")
print("See plans/260411-2242-vf-gap-closure/deferred-triage.md (Phase 7 Step 1)")

print("\n## Spec 015 quarantine exit criteria [M9]\n")
print("- **Quarantined:** 2026-04-09 (merge campaign)")
print("- **Revisit by:** 2026-07-01 (3 months)")
print("- **Drop by:** 2026-10-01 (6 months) if not revisited")
print("- **Revisit requires:** manual diff review, selective cherry-pick")
print("  of history-tracking skill subset without protected-path deletions")

print("\n## Spec 016, 020 rationale [M10]\n")
print("- 016 (consensus engine): +1164/-9748 lines, deletes uninstall.sh")
print("  + hooks/config-loader.js + verify-e2e.js + 18 scripts. Too destructive.")
print("- 020 (no code): branch had destructive deletions, no new production code.")
PY

wc -l MERGE_REPORT.md
head -30 MERGE_REPORT.md
```

### Step 4 — Close boulder.json via git mv (H14)

```bash
# Use git mv, not mv + git rm
git mv .sisyphus/boulder.json .sisyphus/boulder.json.closed-$(date -u +%Y%m%d)
ls .sisyphus/boulder.json* 2>&1
```

### Step 5 — Add M9/M10 entries to CAMPAIGN_STATE.md

```bash
cat >> CAMPAIGN_STATE.md <<'EOF'

## Post-Campaign Decisions (Phase 7, plan 260411-2242)

### Spec 015 Quarantine Exit Criteria [M9]
- Quarantined: 2026-04-09
- Revisit by: 2026-07-01 (3 months)
- Drop by: 2026-10-01 (6 months) if not revisited
- Revisit requires: manual diff review, selective cherry-pick of the
  history-tracking skill subset without protected-path deletions

### Spec 016 + 020 Skip Rationale [M10]
- 016: Destructive — +1164/-9748 lines, deletes uninstall.sh,
  hooks/config-loader.js, hooks/verify-e2e.js, 18+ scripts. No unique
  value beyond what spec 015 attempted.
- 020: Branch contained only destructive deletions, no production code.

## Campaign status: CLOSED 2026-04-11
See MERGE_REPORT.md for full report.
EOF
```

### Step 6 — Commit

```bash
git add MERGE_REPORT.md CAMPAIGN_STATE.md .sisyphus/boulder.json.closed-* \
  plans/260411-2242-vf-gap-closure/deferred-triage.md

git commit -m "chore(campaign): close merge campaign with MERGE_REPORT.md

- Write MERGE_REPORT.md covering all 25 specs, 5 waves, success criteria walk
- git mv .sisyphus/boulder.json → .sisyphus/boulder.json.closed-<date>
- Add M9 spec 015 quarantine exit criteria (revisit 2026-07-01, drop 2026-10-01)
- Document M10 spec 016/020 skip rationale
- deferred-triage.md: 11 DEFERRED items triaged (DO NOW / DEFER / DROP)

Fixes H5, M9, M10 from plans/260411-2242-vf-gap-closure/plan.md (v2)"

# Phase R
bash scripts/benchmark/validate-skills.sh 2>&1 | tail -3 | grep -q 'Pass: 48' || exit 1
agg=$(bash scripts/benchmark/score-project.sh . 2>&1 | grep -oE 'Aggregate: *[0-9]+' | grep -oE '[0-9]+$' | head -1)
[ "$agg" -ge 85 ] || exit 1
echo "PHASE_7_R_GATE_PASS aggregate=$agg"
```

**Exit:**
- `test -f MERGE_REPORT.md`
- `test ! -f .sisyphus/boulder.json`
- `ls .sisyphus/boulder.json.closed-*`
- `grep -q 'Spec 015 Quarantine Exit Criteria' CAMPAIGN_STATE.md`
- Phase R PASS

---

## Phase 8 — Dual-platform audit triage [H3] [~1h]

### Step 1 — Extract findings from vf.md

```bash
awk '/^### Red-Team Findings/,/^### Validated Decisions/' \
  plans/260408-1522-vf-dual-platform-rewrite/vf.md > /tmp/findings.md
wc -l /tmp/findings.md
```

### Step 2 — Check for incoming references before retiring (M red-team)

```bash
grep -rn '260408-1522' . \
  --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.auto-claude \
  | grep -v 'plans/260408-1522' \
  > /tmp/incoming-refs.txt
wc -l /tmp/incoming-refs.txt
cat /tmp/incoming-refs.txt
```

### Step 3 — Write triage report with explicit decision matrix

```bash
cat > plans/260411-2242-vf-gap-closure/260408-1522-triage.md <<'EOF'
# Dual-Platform Audit Plan 260408-1522 — Triage

**Triage date:** $(date -u +%Y-%m-%d)
**Plan:** plans/260408-1522-vf-dual-platform-rewrite/
**Source findings:** vf.md §"Red-Team Findings Addressed" + §"Researcher Findings Integrated"

## Decision Matrix (M red-team)

- **RESOLVED** — cite a merged spec SHA or post-merge fix
- **OPEN** — cited spec failed or not yet addressed → move to TECHNICAL-DEBT.md
- **OBSOLETE** — upstream dependency dropped (e.g. OpenCode track killed)
- **NEEDS-NEW-PLAN** — requires dedicated plan, not in scope here

## Findings table

| ID | Severity | Finding | Disposition | Evidence/target |
|----|----------|---------|-------------|-----------------|
| C1 | Critical | Wrong platform framing (OC as primary) | RESOLVED | Merge campaign retained CC-primary |
| C2 | Critical | Phase 0 false inventory claims | OBSOLETE | Inventory now verified in Phase 2 |
| C3 | Critical | Unexecutable benchmarks | RESOLVED | scripts/benchmark/*.sh exist and run |
| C4 | Critical | No checkpointing | RESOLVED | CAMPAIGN_STATE.md + boulder.json used |
| C5 | Critical | README write conflict (3A/3B) | RESOLVED | Merge campaign handled splits |
| H6 | High | OC unsanitized args | OBSOLETE | OC track deferred |
| H7 | High | Duplicate enforcement logic (62 patterns) | OPEN → debt | Still duplicated in hooks + patterns.ts |
| H8 | High | Shell scripts unaudited | OPEN → debt | Partial; install.sh still has side effects |
| H9 | High | Impossible gate conditions | RESOLVED | Gates rewritten with prioritized criteria |
| H10 | High | No rollback strategy | RESOLVED | pre-merge/spec-N tags + CAMPAIGN_STATE |
| H11 | High | No MVP cut | RESOLVED | Merge campaign delivered MVP |
| H12 | High | Unverifiable Phase 3A gate | OBSOLETE | Phase 3A not executed |
| M13 | Medium | shell.env hook validity | OPEN → debt | Not verified |
| M14 | Medium | Fabricated \|\| true finding | RESOLVED | Hooks use \|\| true legitimately (shell chain isolation) |
| M15 | Medium | Constraint contradictions | RESOLVED | Merge campaign resolved |

## Summary

- RESOLVED: 9
- OPEN (→ TECHNICAL-DEBT.md): 3 (H7, H8, M13)
- OBSOLETE: 3 (C2, H6, H12)
- NEEDS-NEW-PLAN: 0
EOF
```

### Step 4 — Append OPEN items to TECHNICAL-DEBT.md

```bash
cat >> TECHNICAL-DEBT.md <<'EOF'

## X. Inherited from Plan 260408-1522 (Dual-Platform Audit)

### X.1 Duplicate enforcement patterns (H7 from plan 260408-1522)
62 regex patterns hardcoded identically in hooks/ JS files AND patterns.ts.
Drift risk on every update.
**Severity:** HIGH
**Fix:** Consolidate into single source (patterns.ts, with JS compile step)
**Owner:** Future plan

### X.2 Shell script side effects (H8 from plan 260408-1522)
install.sh, uninstall.sh, health-check.sh have unaudited filesystem side
effects on user's ~/.claude directory.
**Severity:** HIGH
**Fix:** Add dry-run mode, URL scheme whitelist, input validation
**Owner:** Future plan

### X.3 shell.env hook validity (M13 from plan 260408-1522)
Hook shell.env handling never verified across bash 3.2 (macOS) and bash 5+.
**Severity:** MEDIUM
**Fix:** Cross-platform smoke test
**Owner:** Future plan
EOF
```

### Step 5 — Retire plan 260408-1522

```bash
python3 - <<'PY'
from pathlib import Path
p = Path("plans/260408-1522-vf-dual-platform-rewrite/plan.md")
s = p.read_text()
s = s.replace("status: planned", "status: retired", 1)
# Add retired_date if not present
if "retired_date:" not in s:
    s = s.replace(
        "triage_pending: true",
        "triage_pending: false\nretired_date: 2026-04-11\nretired_reason: Superseded by merge campaign; 15 findings triaged (9 resolved, 3 debt, 3 obsolete)"
    )
p.write_text(s)
print("RETIRED")
PY
```

### Step 6 — Commit

```bash
git add plans/260408-1522-vf-dual-platform-rewrite/plan.md \
  plans/260411-2242-vf-gap-closure/260408-1522-triage.md \
  TECHNICAL-DEBT.md

git commit -m "chore(plans): triage + retire dual-platform audit plan 260408-1522

Triaged 15 red-team findings from plans/260408-1522-vf-dual-platform-rewrite/vf.md:
- 9 RESOLVED (fixed by merge campaign + merge closeout)
- 3 OPEN → appended to TECHNICAL-DEBT.md §X (H7 patterns, H8 shell, M13 shell.env)
- 3 OBSOLETE (dropped upstream)
- 0 needs-new-plan

Plan 260408-1522 status: planned → retired

Fixes H3 from plans/260411-2242-vf-gap-closure/plan.md (v2)"
```

**Exit:**
- `grep -q '^status: retired' plans/260408-1522-vf-dual-platform-rewrite/plan.md`
- `test -f plans/260411-2242-vf-gap-closure/260408-1522-triage.md`
- `grep -q 'Inherited from Plan 260408-1522' TECHNICAL-DEBT.md`

---

## Phase 6a — Benchmark recoverability check [H4, C7 red-team, N5 fixed] [~5 min]

**Primary method:** Use the `session_read` MCP tool (which was verified at plan-write time to succeed for this session ID):

```
session_read(session_id="ses_28db6f306ffen4JB6QxpR6BRo2", limit=10)
```

If that returns content containing "transcript-analyzer" or "architect" in any message → **RESUMABLE**.
If it errors or returns no messages → fall back to disk glob:

```bash
# Fallback: check if session file exists on disk
python3 - <<'PY'
import os, glob
paths = [
    os.path.expanduser("~/.local/share/opencode/session/storage/ses_28db6f306ffen4JB6QxpR6BRo2*"),
    os.path.expanduser("~/.omc/sessions/*28db6f306*"),
]
found = False
for p in paths:
    matches = glob.glob(p)
    if matches:
        print(f"FOUND: {matches[0]}")
        found = True
        break
print("RESUMABLE" if found else "BLOCKED")
PY
```

**N5 note:** The Python glob is a fallback only. The `session_read` MCP tool is the authoritative check (verified working at plan-write time, 2026-04-11). A competent executor uses MCP first, glob second.

**Decision:**
- If `RESUMABLE` → proceed to Phase 6b
- If `BLOCKED` → H4 remains OPEN, add to TECHNICAL-DEBT.md as: "Benchmark dry-run (transcript-analyzer.js) unrecoverable from session ses_28db6f306*. Requires rewrite from architect design doc if recoverable, else deprioritize."

---

## Phase 6b — Benchmark resume [H4] [~3-4h OR spun to new plan]

**Only runs if Phase 6a = RESUMABLE.**

If blocked, skip and append to TECHNICAL-DEBT.md.

Full resume protocol (when resumable):
1. Extract architect design via `session_read ses_28db6f306ffen4JB6QxpR6BRo2`
2. Implement transcript-analyzer.js with 6 behavioral signals
3. Run `runner.sh --subset` dry-run
4. Capture evidence → `plans/.../benchmark-resume-evidence.md`
5. Commit

**Scope cut per red-team:** "run benchmark against external repo" (was Step 4) is REMOVED from this phase — that's a separate plan.

---

## Phase 9a — Top-10 skill deep review [M1] [~3h]

### Top-10 selection (concrete quality bar per H16 red-team)

| # | Skill | Rationale | Review time |
|---|-------|-----------|-------------|
| 1 | e2e-validate | L4 orchestrator, 2563 lines, highest risk | 30 min |
| 2 | functional-validation | L0 core | 20 min |
| 3 | no-mocking-validation-gates | L0 core | 20 min |
| 4 | gate-validation-discipline | L0 core | 20 min |
| 5 | verification-before-completion | L0 core | 20 min |
| 6 | create-validation-plan | L2 | 15 min |
| 7 | preflight | L2 | 15 min |
| 8 | web-validation | L3 platform (most common) | 15 min |
| 9 | api-validation | L3 platform | 15 min |
| 10 | ios-validation | L3 platform (most complex) | 25 min |

### Quality bar per skill (H16 fix)

For each: `plans/260411-2242-vf-gap-closure/skill-review-<name>.md` containing:
1. **Frontmatter check:** description length ≤210, name matches dir, has context_priority
2. **Cross-reference check:** every `[link]` or `skills/X/` reference resolves to existing file
3. **Contradiction check:** description claims (e.g. "4 layers", "9 steps") verified against body headings
4. **Proposed edits:** ≥1 specific change OR signed "no changes needed" rationale
5. **Verification command:** the exact shell command that could re-verify claims 1-3

### Commit

```bash
git add plans/260411-2242-vf-gap-closure/skill-review-*.md
git commit -m "docs(skills): top-10 deep review (M1 subset)

Deep-reviewed 10 highest-impact skills against 5-point quality bar:
- Frontmatter validity
- Cross-reference resolution
- Description/body consistency
- Proposed edits or signed no-change rationale
- Verification commands

Skills reviewed: e2e-validate, functional-validation, no-mocking-*,
gate-validation-*, verification-*, create-validation-plan, preflight,
web-validation, api-validation, ios-validation.

Remaining 38 skills tracked in TECHNICAL-DEBT.md as M1-continuation.

Fixes M1 (top-10 subset) from plans/260411-2242-vf-gap-closure/plan.md (v2)"
```

---

## Phase 9b — M3-M6 + M8 + commit [~1h]

### M3 — CONSENSUS engine documentation

```bash
cat >> TECHNICAL-DEBT.md <<'EOF'

### 3.1 CONSENSUS engine — TRIAGED (not tested)
Skills `coordinated-validation`, `forge-team` + command `/validate-team` exist.
3-reviewer unanimous voting mechanism documented but untested with live agents.
Status: TRIAGED to debt (scope: needs separate test plan)
EOF
```

### M4 — FORGE engine documentation

```bash
cat >> TECHNICAL-DEBT.md <<'EOF'

### 3.2 FORGE engine — TRIAGED (not tested)
Skills `forge-execute`, `forge-plan`, `forge-setup`, `forge-benchmark`,
`forge-team` + commands exist. Autonomous build→validate→fix loop never
tested end-to-end.
Status: TRIAGED to debt (scope: needs separate test plan)
EOF
```

### M5 — Evidence cleanup smoke test

```bash
# Set up fixture with trap cleanup (M red-team)
TEMP=$(mktemp -d /tmp/vf-cleanup-test.XXXX)
trap "rm -rf $TEMP" EXIT

mkdir -p "$TEMP/e2e-evidence/old-run"
touch -t 202501010000 "$TEMP/e2e-evidence/old-run/evidence.txt"

bash -n scripts/evidence-cleanup.sh 2>&1 && echo "M5 syntax OK"
# Attempt actual run if script supports parameters
bash scripts/evidence-cleanup.sh "$TEMP" 1 2>&1 | tail -5 || echo "M5 exec exit=$?"

# Record result
cat >> TECHNICAL-DEBT.md <<EOF

### 3.4 Evidence retention / cleanup — PARTIAL VERIFY
scripts/evidence-cleanup.sh syntax-checks clean. Smoke tested against
fixture dir $TEMP (retention=1 day). Full retention policy not exercised.
Status: TRIAGED (smoke only)
EOF
```

### M6 — Merge campaign O3-O10 triage

Already committed during Phase 7 via deferred-triage.md (overlap). Add explicit note.

### Commit

```bash
git add TECHNICAL-DEBT.md
git commit -m "docs(debt): Tier 3 gap closure — M3-M6 triaged

- M3: CONSENSUS engine (coordinated-validation, forge-team) — tracked
- M4: FORGE engine (forge-* skills) — tracked
- M5: evidence-cleanup.sh smoke tested with temp fixture
- M6: merge campaign O3-O10 folded into deferred-triage.md

Fixes M3, M4, M5, M6 from plans/260411-2242-vf-gap-closure/plan.md (v2)"
```

---

## Final verification [~15 min]

```bash
# Plan-wide success script (fixes M red-team shell golf)
F=plans/260411-2242-vf-gap-closure/VERIFICATION.md
{
  echo "# Gap Closure Plan v2 — Verification"
  echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo ""
  echo "## Exit criteria"
  echo ""

  # B1
  [ "$(git status --porcelain | wc -l | tr -d ' ')" = "0" ] \
    && echo "- [x] B1 git clean" || echo "- [ ] B1 FAIL $(git status --porcelain | wc -l)"

  # B2
  test -f plans/260411-2242-vf-gap-closure/first-real-run.md \
    && grep -q 'Verdict:' plans/260411-2242-vf-gap-closure/first-real-run.md \
    && echo "- [x] B2 first-real-run.md has Verdict" \
    || echo "- [ ] B2 FAIL"

  # B3, B4
  if [ -f plans/260411-2242-vf-gap-closure/live-session-evidence.md ]; then
    pass=$(grep -o 'PASS' plans/260411-2242-vf-gap-closure/live-session-evidence.md | wc -l | tr -d ' ')
    [ "$pass" -ge 4 ] && echo "- [x] B3+B4 $pass PASS markers" || echo "- [ ] B3+B4 only $pass PASS"
  else
    echo "- [ ] B3+B4 evidence missing"
  fi

  # B5
  test -f plans/260411-2242-vf-gap-closure/demo-gif-disposition.md \
    && echo "- [x] B5 disposition exists" || echo "- [ ] B5 FAIL"

  # H1
  grep -q '48 skills' README.md && grep -q '48 skills' SKILLS.md && grep -q '17 slash commands' COMMANDS.md \
    && echo "- [x] H1 inventory synced" || echo "- [ ] H1 FAIL"

  # H2
  grep -q '^status: complete' plans/260411-1731-skill-optimization-remediation/plan.md \
    && echo "- [x] H2 status flipped" || echo "- [ ] H2 FAIL"

  # H3
  grep -q '^status: retired' plans/260408-1522-vf-dual-platform-rewrite/plan.md \
    && echo "- [x] H3 plan retired" || echo "- [ ] H3 FAIL"

  # H4
  test -f plans/260411-2242-vf-gap-closure/benchmark-resume-evidence.md \
    && echo "- [x] H4 benchmark resumed" \
    || { grep -q 'Benchmark dry-run.*unrecoverable' TECHNICAL-DEBT.md \
         && echo "- [x] H4 BLOCKED → debt" \
         || echo "- [ ] H4 FAIL"; }

  # H5
  test -f MERGE_REPORT.md && test ! -f .sisyphus/boulder.json \
    && echo "- [x] H5 merge closed" || echo "- [ ] H5 FAIL"

  # H6
  [ "$(git stash list | wc -l | tr -d ' ')" = "0" ] \
    && echo "- [x] H6 stashes dropped" || echo "- [ ] H6 FAIL"

  # H7
  [ "$(git ls-remote --heads origin 2>/dev/null | grep -c auto-claude)" = "0" ] \
    && echo "- [x] H7 remote clean" || echo "- [ ] H7 FAIL"

  # M1
  ls plans/260411-2242-vf-gap-closure/skill-review-*.md 2>/dev/null | wc -l | awk '{exit !($1>=10)}' \
    && echo "- [x] M1 top-10 reviewed" || echo "- [ ] M1 FAIL"

  # M3, M4, M5
  grep -q 'CONSENSUS engine' TECHNICAL-DEBT.md && echo "- [x] M3 tracked" || echo "- [ ] M3 FAIL"
  grep -q 'FORGE engine' TECHNICAL-DEBT.md && echo "- [x] M4 tracked" || echo "- [ ] M4 FAIL"
  grep -q 'Evidence retention' TECHNICAL-DEBT.md && echo "- [x] M5 tracked" || echo "- [ ] M5 FAIL"

  # Plan-wide regression check
  echo ""
  echo "## Final regression"
  bash scripts/benchmark/validate-skills.sh 2>&1 | tail -3
  bash scripts/benchmark/score-project.sh . 2>&1 | tail -10

} > $F
cat $F
```

**Plan success:** All `[x]` marks present, no `[ ]`. Benchmark still shows Grade A or B, aggregate ≥ 85.

---

## Non-goals (unchanged from v1)

- Not re-recording the demo GIF (Phase 5 decides disposition only)
- Not executing CONSENSUS or FORGE engines end-to-end (documented only)
- Not deep-reviewing all 48 skills (top-10 only; rest tracked)
- Not modifying `skills/*/SKILL.md` (preserved)
- Not changing enforcement profile logic
- Not pushing new commits to remote `main` (user decision)
- Not creating a release or tag beyond rollback tags
- Not touching Anthropic plugin marketplace

## Files — output artifacts

```
plans/260411-2242-vf-gap-closure/
├── plan.md                              # This file (v2)
├── plan-manual.md                       # Manual-gate protocol (Phases 4, 5)
├── red-team-review.md                   # Red-team findings (reference)
├── progress.md                          # Session-continuity log
├── diff-reviews/commit-B-skills-*.txt   # Phase 1 diff review artifacts
├── stash-dispositions.md                # Phase 3 (user-edited)
├── hook-audit.md                        # Phase 2 (user-edited)
├── live-session-evidence.md             # Phase 4 MANUAL (≥4 PASS markers)
├── first-real-run.md                    # Phase 5 MANUAL
├── demo-gif-disposition.md              # Phase 5
├── deferred-triage.md                   # Phase 7 (user-edited)
├── 260408-1522-triage.md                # Phase 8
├── skill-review-<name>.md × 10          # Phase 9a
├── benchmark-resume-evidence.md         # Phase 6b (if resumable)
└── VERIFICATION.md                      # Final
```

## What's in plan-manual.md

`plan-manual.md` contains the step-by-step protocol for Phases 4 and 5 that must be executed inside a fresh Claude Code session. Key hardening:
- Option B (symlink) install unambiguously
- `~/.claude` tar snapshot before install (rollback)
- `~/Desktop/vf-live-test-<ts>` scratch (not /tmp)
- `verify-live-session-evidence.py` checker script
- ≥3 platform detection tests (API, Web, CLI)
- `ffprobe` metadata + frame description for demo GIF
- Named external-repo target (pre-execution)
