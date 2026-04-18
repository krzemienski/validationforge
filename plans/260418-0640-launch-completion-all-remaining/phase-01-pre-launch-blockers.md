# Phase 1 — Pre-Launch Blockers

## 1. Context Links

- Parent plan: [plan.md](plan.md)
- Readiness dashboard: `assets/campaigns/260418-validationforge-launch/READINESS-DASHBOARD.md`
- Visual spec: `assets/campaigns/260418-validationforge-launch/creatives/visual-content-spec.md` §Production Priority
- Repo prep: `assets/campaigns/260418-validationforge-launch/execution/companion-repo-prep-checklist.md`
- Staged README patches: `assets/campaigns/260418-validationforge-launch/staged-readme-patches/`
- Capture script: `assets/campaigns/260418-validationforge-launch/creatives/scripts/capture-terminal.sh`

## 2. Overview

- **Date range:** 2026-04-18 (Sat) → 2026-04-20 08:30 ET (Mon soft-launch gate)
- **Priority:** P0 — blocks every downstream phase
- **Status:** pending
- **Description:** Clear the 5 Day-1 blockers: produce `vf-demo-hero.gif`, resolve ai-dev-operating-system factual conflict, decide orphaned-repo fate, push 11 staged README patches to GitHub, final voice-edit pass on 12 posts. No downstream phase starts until every item here cites evidence.
- **Estimated effort:** 8 hours total (single-owner, can run Sat-Sun)

## 3. Key Insights

- GIF is the single largest blocker — referenced by soft-launch post, Show HN README, X T1, Reddit r/ClaudeAI cover, Discord drops. Missing → entire 10-week calendar slips Day 1.
- 11 README patches are STAGED (file on disk at `staged-readme-patches/`) but NOT PUSHED. GitHub still shows 60-day-dormant repos until patches land.
- ai-dev-operating-system conflict is real: repo exists at 1 star, but Post 11 was corrected to use `validationforge` as capstone companion. Calendar line 141 and prep-checklist Repo #11 disagree on which repo ships Jun 22.
- Voice consistency is already PASS (3/3 sampled in readiness audit). Final-edit pass is about hook-truncation verification at 210 chars + no-emoji sweep, not rewrites.
- Soft-launch post references `vf-demo-hero.gif` by filename only — the GIF must exist at both `creatives/gifs/vf-demo-hero.gif` AND `demo/vf-demo.gif` in the VF repo (Show HN README dependency for Day 11).

## 4. Requirements

### Functional
- `vf-demo-hero.gif` exists at 800×450, 10-15s loop, real `/validate` run, no music, no text overlay, <8 MB, committed to both `creatives/gifs/` and VF repo's `demo/` directory.
- ai-dev-operating-system decision (Option A keep / Option B revert) is documented in `READINESS-DASHBOARD.md §7 Open Decisions #2` and applied to prep-checklist + calendar line 141.
- All 11 staged README patches pushed to respective GitHub repos with commit message "docs: feature-badge + related-post section for blog-series launch".
- All 11 repos verified: last commit within 60 days, topic tags applied, LICENSE MIT present.
- Install command verified on fresh terminal for all 5 highest-traffic repos: validationforge, multi-agent-consensus, claude-code-skills-factory, code-tales, auto-claude-worktrees.
- 8 VF/personal-brand posts + 4 Week 1-2 blog-series hero adaptations pass a manual voice-edit pass: no emojis, hook lands in first 210 chars, no forbidden buzzwords.

### Non-Functional
- GIF file size < 8 MB (GitHub inline render limit).
- README patches must not introduce Markdown syntax errors (lint via `markdownlint-cli` or visual preview in GitHub).
- Gate: every item closed BEFORE Mon 2026-04-20 08:30 ET (soft-launch send time).

## 5. Architecture — Order of Operations

```
Sat 04-18 morning:    GIF production (2-3h) ──────────────┐
Sat 04-18 afternoon:  ai-dev-operating-system decision ──┐│
                      Orphaned repos decision ───────────┐││
Sat 04-18 evening:    Push 11 README patches (30 min) ──┐│││
Sun 04-19 morning:    Install-verify 5 repos (90 min) ──┐││││
Sun 04-19 afternoon:  Voice-edit pass (2h) ────────────┐ ││││
Sun 04-19 evening:    Soft-launch dry-render in LI ───┐│ ││││
                                                      ↓↓ ↓↓↓↓
Mon 04-20 08:30 ET:   SOFT-LAUNCH GATE  ←──────────────────────
```

Each item is independent except: install-verify requires README patches pushed first (otherwise badge+link land after live post).

## 6. Related Code/Artifact Files

- `assets/campaigns/260418-validationforge-launch/creatives/scripts/capture-terminal.sh` (capture helper)
- `assets/campaigns/260418-validationforge-launch/creatives/gifs/vf-demo-hero.gif` (TO PRODUCE)
- `demo/vf-demo.gif` in github.com/krzemienski/validationforge (TO COMMIT)
- `assets/campaigns/260418-validationforge-launch/staged-readme-patches/{repo}-README.md` × 11
- `assets/campaigns/260418-validationforge-launch/copy/linkedin-soft-launch-mon-apr20.md`
- `assets/campaigns/260418-validationforge-launch/copy/linkedin-blog-series.md` (Parts 1/2/3)
- `assets/campaigns/260418-validationforge-launch/copy/personal-brand-launch-post.md`
- `assets/campaigns/260418-validationforge-launch/copy/x-thread-launch-hero.md`
- `assets/campaigns/260418-validationforge-launch/copy/linkedin-week3-reflection.md`
- `assets/campaigns/260418-validationforge-launch/copy/linkedin-week3-deepdive-no-mock-hook.md`
- `assets/campaigns/260418-validationforge-launch/copy/linkedin-week4-five-questions.md`
- `assets/campaigns/260418-validationforge-launch/copy/linkedin-week4-spotlight.md`
- `assets/campaigns/260418-validationforge-launch/copy/blog-series-adapted/post-{01,02,03,07}-linkedin.md`
- `assets/campaigns/260418-validationforge-launch/READINESS-DASHBOARD.md` (update Open Decisions on resolution)
- `assets/campaigns/260418-validationforge-launch/execution/10-week-master-calendar.md` (fix line 141 if Option B)

## 7. Implementation Steps

1. **[Sat 04-18 09:00 ET]** Open Terminal.app/iTerm2, set JetBrains Mono 14pt, bg `#0a0a0a`, fg `#e5e5e5`, resize to ~120 cols.
2. **[Sat 04-18 09:15 ET]** Start asciinema: `asciinema rec /tmp/vf-demo.cast`.
3. **[Sat 04-18 09:20 ET]** Run real `/validate` against VF itself. Let it capture command, spinner, 6-journey progress, final PASS verdict. Stop rec (Ctrl+D).
4. **[Sat 04-18 09:35 ET]** Convert: `agg --theme one-dark --font-family "JetBrains Mono" --speed 1.2 /tmp/vf-demo.cast creatives/gifs/vf-demo-hero.gif`. Verify 800×450, <8 MB. Iterate with gifski if oversized.
5. **[Sat 04-18 10:30 ET]** Commit GIF to VF repo: `cp creatives/gifs/vf-demo-hero.gif ~/validationforge/demo/vf-demo.gif && cd ~/validationforge && git add demo/vf-demo.gif && git commit -m "docs(demo): add launch-day hero GIF" && git push`.
6. **[Sat 04-18 11:00 ET]** Decision already made 2026-04-18 validation: **Option A** (archive `ai-dev-operating-system`, use `validationforge` as Post 11 capstone). Document in `READINESS-DASHBOARD.md §7 row 2`: "A — validated 2026-04-18".
7. **[Sat 04-18 11:30 ET]** Archive both orphans + verify. **User-confirmed destructive op — run only with explicit go-ahead:**
    ```
    gh repo archive krzemienski/ai-dev-operating-system --yes
    gh repo archive krzemienski/functional-validation-framework --yes
    # Verify:
    gh api repos/krzemienski/ai-dev-operating-system --jq '.archived'        # expect: true
    gh api repos/krzemienski/functional-validation-framework --jq '.archived' # expect: true
    ```
    Log both verify outputs to `reports/phase-01-archive-verify.txt`.
8. **[Sat 04-18 14:00 ET]** Push 11 staged README patches. For each repo in prep-checklist: `cd ~/repos/{repo} && git checkout main || git checkout master && cp /path/to/staged-readme-patches/{repo}-README.md README.md && git add README.md && git commit -m "docs: feature-badge + related-post for blog-series launch" && git push`. Evidence: 11 commit SHAs logged to `plans/260418-0640-launch-completion-all-remaining/reports/phase-01-pushed-commits.txt`.
9. **[Sun 04-19 09:00 ET]** Fresh terminal install-verify: validationforge, multi-agent-consensus, claude-code-skills-factory, code-tales, auto-claude-worktrees. For each: `rm -rf /tmp/verify && mkdir /tmp/verify && cd /tmp/verify && <clone + install command from README> 2>&1 | tee /tmp/{repo}-install.log`. Evidence: 5 logs ending in success.
10. **[Sun 04-19 13:00 ET]** Voice-edit pass — grep for emoji characters in all 12 copy files: `grep -rP '[\x{1F300}-\x{1FAFF}]|[\x{2600}-\x{27BF}]' copy/`. Fix any hits. Verify hook-truncation: first 210 chars of each post must end on a sentence boundary (no "see more" cut mid-word).
11. **[Sun 04-19 16:00 ET]** Preview soft-launch post in LinkedIn draft (paste into create-post, do NOT publish). Confirm: 75-word body renders, GIF attachment uploads, preview card shows repo URL correctly. Screenshot to `reports/phase-01-linkedin-preview.png`. Close draft without publishing.
12. **[Sun 04-19 18:00 ET]** Final Phase-1 checklist review. If any item red, escalate. If all green, Phase 2 can start Mon 04-20 post-launch (parallel with Phase 3 Day 1).
13. **[Mon 04-20 08:30 ET]** SOFT-LAUNCH GATE — Phase 1 done when soft-launch post is live on LinkedIn AND GIF renders inline.

## 8. Todo List

- [ ] Owner: Nick | Deadline: Sat 04-18 12:00 ET | Effort: 3h | Deps: none | Evidence: `creatives/gifs/vf-demo-hero.gif` on disk, `file --mime-type` = image/gif, `du -h` < 8 MB, 800x450 via `identify`
- [ ] Owner: Nick | Deadline: Sat 04-18 12:30 ET | Effort: 0.5h | Deps: GIF exists | Evidence: `gh repo view krzemienski/validationforge --json defaultBranchRef` + commit SHA for demo/vf-demo.gif
- [ ] Owner: Nick | Deadline: Sat 04-18 12:00 ET | Effort: 15min | Deps: none | Evidence: decision recorded in READINESS-DASHBOARD.md §7 row 2 with rationale paragraph
- [ ] Owner: Nick | Deadline: Sat 04-18 12:30 ET | Effort: 15min | Deps: #3 decision | Evidence: `gh api repos/krzemienski/ai-dev-operating-system --jq '.archived'` returns expected state
- [ ] Owner: Nick | Deadline: Sat 04-18 18:00 ET | Effort: 1h | Deps: repos exist | Evidence: 11 commit SHAs in `reports/phase-01-pushed-commits.txt`, each reachable via `gh browse`
- [ ] Owner: Nick | Deadline: Sun 04-19 12:00 ET | Effort: 1.5h | Deps: READMEs pushed | Evidence: 5 install logs in `reports/install-verify-*.log` ending with exit-code 0
- [ ] Owner: Nick | Deadline: Sun 04-19 15:00 ET | Effort: 2h | Deps: none | Evidence: `grep -c emoji` returns 0 for each of 12 files; hook-truncation spot-check PNG in `reports/hook-preview-*.png`
- [ ] Owner: Nick | Deadline: Sun 04-19 17:00 ET | Effort: 0.5h | Deps: GIF, post-body | Evidence: `reports/phase-01-linkedin-preview.png` screenshot of LinkedIn draft
- [ ] Owner: Nick | Deadline: Sun 04-19 18:00 ET | Effort: 0.25h | Deps: all above | Evidence: `reports/phase-01-gate-checklist.md` with 8 checkboxes all [x]

## 9. Success Criteria

- `creatives/gifs/vf-demo-hero.gif` exists, 800×450, <8 MB, real `/validate` content (verified by `ffprobe` metadata + visual diff against spec).
- `github.com/krzemienski/validationforge/blob/main/demo/vf-demo.gif` renders in browser (HTTP 200 + image bytes).
- All 11 companion repos show commits dated within 2 days when `gh api repos/krzemienski/{repo} --jq '.pushed_at'`.
- ai-dev-operating-system decision documented in dashboard; calendar line 141 matches decision.
- 5/5 install-verify logs pass.
- 12/12 copy files pass emoji grep.
- LinkedIn draft preview screenshot archived.
- Mon 04-20 08:30 ET soft-launch post goes live with inline GIF.

## 10. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| `/validate` fails during GIF recording → no clean capture | M | H | Pre-run dry `/validate` 3× to confirm clean 6/6 PASS; if fails, use VF self-validation recording from existing `e2e-evidence/self-validation/` session |
| GIF exceeds 8 MB even after gifski | M | M | Fallback: reduce to 600×400 (still within spec range for Discord/Reddit) or cut to 8s tight loop |
| `gh repo archive` of ai-dev-operating-system triggers follower notification storm | L | L | 1 star = 1 follower = no notable signal |
| README patch causes rendering break on GitHub | L | M | Preview each patch in staged file; visual-inspect in GitHub after push via `gh repo view --web` |
| Install-verify fails on a repo → can't fix before Day 1 | L | H | Install-verify only blocks Week 5-10 (repo-specific posts); Day 1 is VF-only so this is Phase 5 pre-work, not Phase 1 blocker. Record fail + defer to repo polish deadline |
| Voice-edit pass surfaces deeper issue (factual error, tone drift) | L | H | Budget 2h includes 30min headroom; if deeper, escalate and delay soft-launch 24h to Tue 04-21 |
| LinkedIn preview shows broken card | L | M | Fallback: attach PNG hero instead of GIF (spec permits hero.png for Day 1) |

## 11. Security Considerations

- No secrets created in this phase. All commits are public README updates.
- GIF recording must not capture: `.env` files, API keys, `$HOME` path with username > "nick", unreleased product names. Screen the recording before commit.
- GitHub push uses existing HTTPS credentials — verify `git remote get-url origin` points to `https://github.com/...` (not SSH, per git.md rules).
- No force-push. All commits are additive.

## 12. Next Steps

Phase 2 (LinkedIn Publisher Setup) and Phase 3 (Wave 1 Execution Day 1) both start Mon Apr 20 after soft-launch gate clears. Phase 5 repo-prep deadlines are all ≥3 weeks out, so nothing else depends on Phase 1 beyond the Day 1 gate.

## 13. Functional Validation

Every Phase-1 completion claim cites evidence. No "done" without a file path, log line, or screenshot.

- **GIF verification:** `ffprobe creatives/gifs/vf-demo-hero.gif 2>&1 | grep -E "Duration|Stream"` — output must show 10-15s duration, 800×450 resolution. Log saved to `reports/phase-01-gif-verify.txt`.
- **Repo-patch push verification:** `for repo in agentic-development-guide multi-agent-consensus claude-code-skills-factory claude-ios-streaming-bridge claude-sdk-bridge auto-claude-worktrees claude-prompt-stack ralph-orchestrator-guide code-tales stitch-design-to-code validationforge; do gh api repos/krzemienski/$repo --jq '{repo: .name, pushed: .pushed_at}'; done > reports/phase-01-pushed-commits.txt`. All 11 must show `pushed_at` within past 48h.
- **Install-verify evidence:** each log file ends with exit-code 0 line; grep for `Error|Failed|fatal` returns zero matches in all 5 logs.
- **Voice-edit evidence:** `grep -rP '[\x{1F300}-\x{1FAFF}]|[\x{2600}-\x{27BF}]' assets/campaigns/260418-validationforge-launch/copy/ | tee reports/phase-01-emoji-sweep.txt` — file must be empty.
- **Soft-launch gate evidence:** Mon Apr 20 09:00 ET screenshot of live LinkedIn post showing: body text, GIF rendering, repo link preview, time stamp = 08:30 ET. Saved to `reports/phase-01-soft-launch-live.png`.
- **Phase complete claim:** must cite all 5 evidence artifacts above. Prose-only completion ("looks good", "should work") is rejected per `evidence-before-completion.md` rule.
