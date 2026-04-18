# Implementation Kickoff Prompt — ValidationForge Launch, Phase 1

**Generated:** 2026-04-18 07:01 ET (deepened 07:40 ET)
**Source plan:** `/Users/nick/Desktop/validationforge/plans/260418-0640-launch-completion-all-remaining/`
**Validation:** 8 questions answered, 7 decisions confirmed (see plan.md §Validation Summary)
**Gate:** Mon Apr 20 08:30 ET soft-launch post MUST be live.
**Risk profile:** HIGH — time-critical, OAuth secrets, destructive gh ops on 2 public repos, 11 public README pushes.

<mock_detection_protocol>
Before executing any task, check intent:
- Creating `.test.*`, `_test.*`, `*Tests.*`, `test_*` files → STOP
- Importing mock libraries (jest.mock, sinon, testdouble) → STOP
- Creating in-memory databases or fake HTTP clients → STOP
- Adding TEST_MODE or NODE_ENV=test flags to production paths → STOP
Fix the REAL system instead. Iron rule: if the real system does not work, fix the real system.
The only allowed "test" invocation is `./bin/lp test` which is a dry-run of the real publisher — not a test framework.
</mock_detection_protocol>

---

## Paste-Ready Prompt

> Copy everything between the `===` markers into a fresh Claude Code session at CWD `/Users/nick/Desktop/validationforge`.

```
===

You are resuming the ValidationForge launch campaign. The 10-week content calendar,
11 companion repo patches, and 60K words of copy are already drafted. Your job is
Phase 1: clear all pre-launch blockers so the Mon Apr 20 08:30 ET soft-launch post
ships on time.

<authoritative_sources>
  <plan>plans/260418-0640-launch-completion-all-remaining/plan.md</plan>
  <phase_spec>plans/260418-0640-launch-completion-all-remaining/phase-01-pre-launch-blockers.md</phase_spec>
  <readiness>assets/campaigns/260418-validationforge-launch/READINESS-DASHBOARD.md</readiness>
  <calendar>assets/campaigns/260418-validationforge-launch/execution/10-week-master-calendar.md</calendar>
  <repo_checklist>assets/campaigns/260418-validationforge-launch/execution/companion-repo-prep-checklist.md</repo_checklist>
  <visual_spec>assets/campaigns/260418-validationforge-launch/creatives/visual-content-spec.md</visual_spec>
</authoritative_sources>

<confirmed_decisions date="2026-04-18" source="validation-interview">
  <d id="1">Post 11 repo = validationforge (archive ai-dev-operating-system).</d>
  <d id="2">Orphaned repos: archive both ai-dev-operating-system AND functional-validation-framework.</d>
  <d id="3">LinkedIn posting target = personal profile (urn:li:person:{sub}).
    NOTE: Developer Portal STILL requires a Company Page association at app-creation
    (placeholder page acceptable). Post authorship is personal; app ownership is Company.</d>
  <d id="4">Cron host = Local Mac launchd (not GH Actions, not VPS).</d>
  <d id="5">Brand strategy Weeks 3-4 = coupled.</d>
  <d id="6">Canonical blog domain = ai.hack.ski.</d>
  <d id="7">V1.5 CONSENSUS = launch inside Phase 6 if ≤3 readiness gaps on Sat Jul 12.</d>
</confirmed_decisions>

<phase_file_revisions batch="first-30min">
  <rev phase="2">Keep Company Page creation step (it's mandatory for app, placeholder OK).
    Change author from urn:li:organization to urn:li:person (auth.js already does this).
    Replace GH Actions cron with launchd plist at
    ~/Library/LaunchAgents/com.validationforge.linkedin-publisher.plist.
    Reference: integrations/linkedin-publisher/src/auth.js:17,128-135.</rev>
  <rev phase="1">Add orphaned-repo archive todo (commands in VG-2 below).</rev>
  <rev phase="5">Replace agentic.dev / {CANONICAL_URL} placeholders with
    https://ai.hack.ski/blog/{slug} in all 11 staged README patches.</rev>
  <rev phase="6">Add Sat Jul 12 (Day 85) V1.5 readiness checkpoint, ≤3-gap threshold.</rev>
</phase_file_revisions>

=========================================================================
BLOCK 1 — vf-demo-hero.gif Production (Sat AM, 2-3h)
=========================================================================

<task id="B1" priority="critical" deadline="2026-04-19T17:00-04:00">
  <description>Produce vf-demo-hero.gif for soft-launch + all Wave 1 T1 content.</description>

  <source_input>
    Existing VF self-validation recording. Locate with:
      find assets/campaigns/260418-validationforge-launch/creatives -type f \
        \( -iname '*demo*' -o -iname '*validation*' -o -iname '*.mov' -o -iname '*.mp4' \) 2>/dev/null
    Fallback if no recording: re-record from scratch via asciinema
    (visual-content-spec.md §3 covers the flow).
  </source_input>

  <target_spec>
    <path>assets/campaigns/260418-validationforge-launch/creatives/vf-demo-hero.gif</path>
    <resolution>1200x627 (LinkedIn native hero aspect)</resolution>
    <duration>≤30s</duration>
    <size>≤5MB</size>
  </target_spec>

  <production_commands tool="ffmpeg">
    # Primary path (ffmpeg with palette — gifski NOT installed on this box):
    SRC=path/to/source.mov
    DST=assets/campaigns/260418-validationforge-launch/creatives/vf-demo-hero.gif
    ffmpeg -i "$SRC" -vf "fps=15,scale=1200:627:flags=lanczos,palettegen" -y /tmp/palette.png
    ffmpeg -i "$SRC" -i /tmp/palette.png -lavfi "fps=15,scale=1200:627:flags=lanczos [v]; [v][1:v] paletteuse" -y "$DST"

    # Fallback if output &gt;5MB: drop fps to 10, or install gifski
    # (brew install gifski; gifski --width 1200 --fps 15 --quality 80 -o "$DST" "$SRC")
  </production_commands>

  <validation_gate id="VG-1" blocking="true">
    <prerequisites>Source video identified, ffmpeg available (verified: /opt/homebrew/bin/ffmpeg).</prerequisites>
    <execute>Run production_commands above.</execute>
    <capture>
      ffprobe -v error -show_entries stream=width,height:format=duration,size \
        -of json "$DST" | tee plans/260418-0640-launch-completion-all-remaining/reports/vg1-gif-meta.json
      ls -lh "$DST" | tee -a plans/260418-0640-launch-completion-all-remaining/reports/vg1-gif-meta.json
    </capture>
    <pass_criteria>
      width==1200 AND height==627 AND duration≤30 AND size_bytes≤5242880
      AND file exists at target path.
    </pass_criteria>
    <review>
      cat plans/260418-0640-launch-completion-all-remaining/reports/vg1-gif-meta.json
      Read tool on the .gif itself — visually confirm the demo shows VF catching a FAIL verdict.
    </review>
    <verdict>PASS → proceed to VG-2 | FAIL → retry with fps=10 or install gifski</verdict>
    <mock_guard>Never substitute a screenshot or placeholder "coming soon" image. Real demo only.</mock_guard>
  </validation_gate>
</task>

=========================================================================
BLOCK 2 — Archive Orphans + Push 11 README Patches (Sat PM, 1h)
=========================================================================

<task id="B2" priority="critical" deadline="2026-04-19T18:00-04:00" depends_on="B1">
  <description>Archive 2 orphaned repos, push 11 staged READMEs to target repos.</description>

  <archive_commands>
    gh repo archive krzemienski/ai-dev-operating-system --yes
    gh repo archive krzemienski/functional-validation-framework --yes
    # Verify both archived:
    gh api repos/krzemienski/ai-dev-operating-system --jq '.archived'  # must print: true
    gh api repos/krzemienski/functional-validation-framework --jq '.archived'  # must print: true
  </archive_commands>

  <patch_push_loop>
    # Staged patches are FULL README.md files (not diffs). Push = cp + commit + push.
    PATCHES=assets/campaigns/260418-validationforge-launch/execution/staged-readme-patches
    LOG=plans/260418-0640-launch-completion-all-remaining/reports/vg2-push-log.md
    : &gt; "$LOG"
    for f in "$PATCHES"/*.md; do
      base=$(basename "$f" -README.md)
      # Map file basename → repo (e.g., multi-agent-consensus-README.md → krzemienski/multi-agent-consensus)
      REPO=krzemienski/$base
      WORK=/tmp/$base
      rm -rf "$WORK"
      gh repo clone "$REPO" "$WORK" -- --depth=1 || { echo "CLONE FAIL $REPO" &gt;&gt; "$LOG"; continue; }
      cp "$f" "$WORK/README.md"
      ( cd "$WORK" &amp;&amp; git add README.md &amp;&amp; git commit -m "docs: pre-launch README refresh" &amp;&amp; git push ) \
        &amp;&amp; ( cd "$WORK" &amp;&amp; echo "OK $REPO $(git rev-parse HEAD)" &gt;&gt; "$LOG" ) \
        || echo "PUSH FAIL $REPO" &gt;&gt; "$LOG"
    done
    cat "$LOG"
  </patch_push_loop>

  <rollback_plan>
    If a push fails mid-loop:
    1. Log captures which repos succeeded (OK lines have SHA).
    2. Fix the failing repo manually (branch-protection rules, auth issues).
    3. Re-run the loop — idempotent iff commit message changes or README unchanged (git detects no-op).
    4. If a push goes wrong (bad content pushed): `git revert HEAD &amp;&amp; git push` on that repo.
  </rollback_plan>

  <validation_gate id="VG-2" blocking="true">
    <prerequisites>VG-1 PASS. gh CLI authenticated (`gh auth status`).</prerequisites>
    <execute>Run archive_commands, then patch_push_loop.</execute>
    <capture>vg2-push-log.md (written by the loop).</capture>
    <pass_criteria>
      Both `archived` api calls return true AND
      vg2-push-log.md contains exactly 11 OK lines with 11 SHAs AND 0 FAIL lines.
    </pass_criteria>
    <review>
      grep -c '^OK ' vg2-push-log.md   # must return 11
      grep -c 'FAIL' vg2-push-log.md   # must return 0
    </review>
    <verdict>PASS → VG-3 | FAIL → investigate specific repo(s), fix, re-run loop</verdict>
    <mock_guard>Never simulate pushes or skip "noisy" repos. All 11 real or fix the blocker.</mock_guard>
  </validation_gate>
</task>

=========================================================================
BLOCK 3 — LinkedIn OAuth + Publisher Dry-Run (Sun AM, 2h)
=========================================================================

<task id="B3" priority="critical" deadline="2026-04-19T14:00-04:00" depends_on="B2">
  <description>Register Developer App, complete OAuth, verify publish path works.</description>

  <dev_portal_steps>
    1. https://www.linkedin.com/developers/apps → Create app.
    2. ASSOCIATE a Company Page (placeholder page OK — app ownership, not post authorship).
       If no page exists: linkedin.com/company/setup/new — 2 min to create placeholder.
    3. Products tab → request: "Sign In with LinkedIn using OpenID Connect" (auto-approve)
       AND "Share on LinkedIn" (auto-approve, grants w_member_social).
    4. Auth tab → copy Client ID + Client Secret → paste into integrations/linkedin-publisher/.env
       (template at .env.example).
    5. Auth tab → add Authorized Redirect URL: http://localhost:3000/callback (exact match).
  </dev_portal_steps>

  <oauth_run>
    cd integrations/linkedin-publisher
    npm install
    ./bin/lp auth
    # Browser opens to LinkedIn consent → approve → callback to localhost:3000 →
    # auth.js auto-writes: LINKEDIN_ACCESS_TOKEN, LINKEDIN_REFRESH_TOKEN,
    # LINKEDIN_ACCESS_TOKEN_EXPIRES_AT, LINKEDIN_PERSON_URN.
    # Reference: src/auth.js:137-142.
  </oauth_run>

  <dry_run>
    ./bin/lp test --md ../../assets/campaigns/260418-validationforge-launch/copy/linkedin-soft-launch-mon-apr20.md \
      2&gt;&amp;1 | tee ../../plans/260418-0640-launch-completion-all-remaining/reports/vg3-dry-run.log
  </dry_run>

  <launchd_plist_prep>
    # Create but do NOT load yet — loading fires the cron. Phase 2 loads it later.
    PLIST=~/Library/LaunchAgents/com.validationforge.linkedin-publisher.plist
    # Template: runs Mon+Thu 08:30 America/New_York via `lp run`.
    # See phase-02 for the full plist XML (to be revised in the first-30min batch).
  </launchd_plist_prep>

  <validation_gate id="VG-3" blocking="true">
    <prerequisites>VG-2 PASS. npm &gt;=10. Node &gt;=22 (use /opt/homebrew/opt/node@22/bin if needed).</prerequisites>
    <execute>dev_portal_steps → oauth_run → dry_run.</execute>
    <capture>
      grep -E '^(LINKEDIN_ACCESS_TOKEN|LINKEDIN_PERSON_URN)=' integrations/linkedin-publisher/.env \
        | sed 's/=.*/=REDACTED/' &gt; plans/260418-0640-launch-completion-all-remaining/reports/vg3-env-keys.txt
      vg3-dry-run.log (from dry_run above)
    </capture>
    <pass_criteria>
      .env contains LINKEDIN_ACCESS_TOKEN, LINKEDIN_REFRESH_TOKEN, LINKEDIN_PERSON_URN (non-empty) AND
      vg3-dry-run.log shows the rendered post body + author URN + no error stack.
    </pass_criteria>
    <review>
      cat vg3-env-keys.txt           # 3 REDACTED lines
      cat vg3-dry-run.log | head -50 # post preview, no 401/403
    </review>
    <verdict>PASS → VG-4 | FAIL → check app scopes (w_member_social), redirect URI exact match</verdict>
    <mock_guard>Never commit .env. Never paste tokens into chat/logs. REDACTED only.</mock_guard>
  </validation_gate>
</task>

=========================================================================
BLOCK 4 — Voice-Edit Pass on 12 Posts (Sun PM, 1-2h)
=========================================================================

<task id="B4" priority="high" deadline="2026-04-19T19:00-04:00" depends_on="B3">
  <description>Final voice review on 8 Wave-1/2 + 4 blog-series posts. No rewrites; only trims.</description>

  <target_files>
    # 8 VF + personal-brand posts:
    assets/campaigns/260418-validationforge-launch/copy/linkedin-soft-launch-mon-apr20.md
    assets/campaigns/260418-validationforge-launch/copy/personal-brand-launch-post.md
    assets/campaigns/260418-validationforge-launch/copy/linkedin-blog-series.md          # Parts 1, 2, 3
    assets/campaigns/260418-validationforge-launch/copy/linkedin-week3-reflection.md      # (placeholders stay — filled Phase 4)
    assets/campaigns/260418-validationforge-launch/copy/linkedin-week3-deepdive-no-mock-hook.md
    assets/campaigns/260418-validationforge-launch/copy/linkedin-week4-five-questions.md
    assets/campaigns/260418-validationforge-launch/copy/linkedin-week4-spotlight.md
    # 4 blog-series adaptations most-at-risk of drift (Posts 3, 5, 6, 9 per prior notes):
    assets/campaigns/260418-validationforge-launch/copy/blog-series-adapted/post-03-*.md
    assets/campaigns/260418-validationforge-launch/copy/blog-series-adapted/post-05-*.md
    assets/campaigns/260418-validationforge-launch/copy/blog-series-adapted/post-06-*.md
    assets/campaigns/260418-validationforge-launch/copy/blog-series-adapted/post-09-*.md
  </target_files>

  <checks_per_file>
    <c id="c1">Hook in first 210 chars (LinkedIn mobile truncation).
      Verify: head -c 210 file.md | grep -oE '[.!?]' | head -1
      (must have sentence-break inside 210 chars).</c>
    <c id="c2">No buzzwords. grep -inE '\b(leverage|synergy|democratize|revolutionize|game-changer|unlock|empower)\b' — expect 0 hits.</c>
    <c id="c3">No unfilled placeholders (EXCEPT linkedin-week3-reflection.md which is filled Phase 4).
      grep -n '{[A-Z_]{2,}}' file.md — expect 0 hits (or only {NUMBER} in week3-reflection).</c>
    <c id="c4">Every factual claim has adjacent evidence. grep -nE '\b(we|our|I) (shipped|caught|found|measured)\b' — manual review each hit.</c>
  </checks_per_file>

  <validation_gate id="VG-4" blocking="true">
    <prerequisites>VG-3 PASS. All 12 target files exist.</prerequisites>
    <execute>Run checks_per_file for each target. Log hits to vg4-voice-edit.log.</execute>
    <capture>
      BASE=assets/campaigns/260418-validationforge-launch/copy
      LOG=plans/260418-0640-launch-completion-all-remaining/reports/vg4-voice-edit.log
      : &gt; "$LOG"
      for f in $TARGET_FILES; do
        echo "=== $f ===" &gt;&gt; "$LOG"
        grep -inE '\b(leverage|synergy|democratize|revolutionize|game-changer|unlock|empower)\b' "$f" &gt;&gt; "$LOG" || echo "OK buzzwords" &gt;&gt; "$LOG"
        grep -nE '\{[A-Z_]{2,}\}' "$f" &gt;&gt; "$LOG" || echo "OK placeholders" &gt;&gt; "$LOG"
      done
      git diff --stat assets/campaigns/260418-validationforge-launch/copy/ &gt;&gt; "$LOG"
    </capture>
    <pass_criteria>
      vg4-voice-edit.log shows:
      - 0 buzzword hits in any file
      - 0 unfilled placeholders (except allowed list in linkedin-week3-reflection.md)
      - git diff shows edits applied (or no edits if already clean).
    </pass_criteria>
    <review>cat vg4-voice-edit.log | less</review>
    <verdict>PASS → VG-5 | FAIL → edit specific lines, re-run VG-4</verdict>
    <mock_guard>Never "edit for completeness." This pass only trims/fixes — no new claims, no new anecdotes.</mock_guard>
  </validation_gate>
</task>

=========================================================================
BLOCK 5 + GATE — Soft-Launch Dress Rehearsal + Live Post
=========================================================================

<task id="B5-G" priority="critical" deadline="2026-04-20T08:30-04:00" depends_on="B4">
  <description>Final preview Mon 07:30 ET. Publish Mon 08:30 ET.</description>

  <dress_rehearsal time="Mon 07:30 ET">
    1. Open linkedin.com → Start a post → paste linkedin-soft-launch-mon-apr20.md body.
    2. Attach vf-demo-hero.gif → verify it previews inline.
    3. Confirm first 210 chars render above "...more" truncation.
    4. Do NOT publish. Screenshot the preview → save to
       plans/260418-0640-launch-completion-all-remaining/reports/softlaunch-preview-mon.png
    5. Close the composer (LinkedIn preserves draft).
  </dress_rehearsal>

  <live_publish time="Mon 08:30 ET">
    Option A (if VG-3 PASS + launchd loaded): launchd fires ./bin/lp run automatically.
    Option B (manual fallback): reopen LinkedIn draft, click Post.
    Verify: post URL returns HTTP 200; screenshot shows live post with view counter.
  </live_publish>

  <validation_gate id="VG-5" blocking="true">
    <prerequisites>VG-4 PASS. It is Mon Apr 20 08:30 ET or later.</prerequisites>
    <capture>
      POST_URL=&lt;paste-from-linkedin&gt;
      curl -sI "$POST_URL" | head -1 &gt; plans/260418-0640-launch-completion-all-remaining/reports/vg5-post-http.txt
      # Screenshot live post →
      plans/260418-0640-launch-completion-all-remaining/reports/vg5-live-post.png
    </capture>
    <pass_criteria>
      vg5-post-http.txt contains "200" AND vg5-live-post.png exists AND shows view counter.
    </pass_criteria>
    <review>Read tool on vg5-live-post.png — confirm headline, GIF rendered, timestamp ≈08:30 ET.</review>
    <verdict>PASS → Phase 1 COMPLETE → begin phase-03-wave-1-execution.md Day 1 engagement window
      | FAIL → identify blocker, manual-post immediately, log deviation to reports/</verdict>
  </validation_gate>
</task>

=========================================================================
GATE MANIFEST
=========================================================================

<gate_manifest>
  <total_gates>5</total_gates>
  <sequence>VG-1 (GIF) → VG-2 (archive+pushes) → VG-3 (OAuth+dry-run) → VG-4 (voice-edit) → VG-5 (live post)</sequence>
  <policy>All gates BLOCKING. No advancement on FAIL.</policy>
  <evidence_dir>plans/260418-0640-launch-completion-all-remaining/reports/</evidence_dir>
  <regression>If ANY gate FAILS: fix the real system → re-run from failed gate → do NOT skip.
    If VG-5 fails after 08:30 ET, manual-post fallback activates immediately (LinkedIn UI, not publisher).</regression>
  <hard_gate>Mon Apr 20 08:30 ET — VG-5 PASS. Every downstream phase depends on this.</hard_gate>
</gate_manifest>

<iron_rules>
  - NEVER create mock/stub/test files. Hooks/block-test-files.js enforces.
  - NEVER claim "done" without cited evidence at the evidence_dir path above.
  - NEVER modify copy files mid-execution beyond VG-4 trim pass.
  - NEVER push to main without verifying staged patch matches target repo name.
  - Fallbacks: GIF → ffmpeg 10fps or install gifski; OAuth → manual-post (15min/post).
</iron_rules>

START: read plan.md + phase-01-pre-launch-blockers.md + READINESS-DASHBOARD.md IN
PARALLEL, then execute the first-30min phase-file revisions, then Block 1. Log
evidence per VG spec as you go. Do not ask permission between blocks — execute.

===
```

---

## How to Use This Prompt

**Option A — Fresh session continuation (Recommended):**
Start a new Claude Code session at VF repo root. Paste the block between `===` markers.

**Option B — Hand to an execution agent:**
Spawn Agent with subagent_type=general-purpose. Prompt is self-contained.

**Option C — Continue this session:**
Type "execute Block 1" and I begin GIF production using the ffmpeg palette pipeline above.

---

## Success Criteria for Phase 1

| # | Checkpoint | Evidence |
|---|-----------|----------|
| 1 | vf-demo-hero.gif: 1200×627, ≤30s, ≤5MB | `vg1-gif-meta.json` |
| 2 | 2 orphaned repos archived | `gh api ... --jq '.archived'` = true |
| 3 | 11 README patches pushed | `vg2-push-log.md` 11 OK lines + SHAs |
| 4 | LinkedIn OAuth + dry-run | `vg3-env-keys.txt` + `vg3-dry-run.log` |
| 5 | 12 posts voice-clean | `vg4-voice-edit.log` 0 buzzwords, 0 placeholders |
| 6 | Dress rehearsal screenshot Mon 07:30 | `softlaunch-preview-mon.png` |
| 7 | Soft-launch LIVE Mon 08:30 ET | `vg5-post-http.txt` 200 + `vg5-live-post.png` |

---

## Unresolved (non-blocking for Phase 1)

<open_questions>
  <q id="1">ai.hack.ski deployment status — live now or needs first deploy before Phase 5 (Sat May 16)?</q>
  <q id="2">stitch-hero.png 1200×627 on-disk verification — defer until Post 2 repo polish Mon May 11.</q>
  <q id="3">Does the Developer Portal require 5-business-day review for w_member_social currently?
    README claims auto-approve; verify by running VG-3 Sat rather than Sun to leave buffer.</q>
</open_questions>

---

## Changelog

<changelog>
  <v date="2026-04-18T07:40-04:00" action="deepen">
    Rewrote Blocks 1-4 with semantic XML validation gates. Added mock-detection protocol.
    Corrected Company Page requirement (mandatory at app level even with personal-URN posting).
    Added concrete ffmpeg palette pipeline (gifski absent). Added rollback plan for B2.
    Added launchd plist prep stub. Added per-file voice-check greps for B4.
    Gate manifest added. 5 VGs total. Size: ~280 lines (1.4× growth vs 200-line baseline).
  </v>
  <v date="2026-04-18T07:01-04:00" action="initial">Transform from validation answers to kickoff prompt.</v>
</changelog>
