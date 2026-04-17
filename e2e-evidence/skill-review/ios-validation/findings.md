# ios-validation Skill — Deep Review Findings

**Skill file:** `./skills/ios-validation/SKILL.md` (214 lines, single-file skill — no `references/` or `workflows/` directory)
**Reviewer:** auto-claude (phase-2-subtask-1)
**Date:** 2026-04-17
**Commit baseline:** see `git log -1` at time of review

## Summary

Verified all 9 Steps, Prerequisites table, Evidence Quality section, Common
Failures table, and PASS Criteria Template against:
- Apple's official `simctl` / `log` / `xcodebuild` documentation (via external
  agent research — transcripts saved in `command-verification-transcript.txt`)
- The three sibling iOS skills: `ios-validation-gate`, `ios-validation-runner`,
  `ios-simulator-control`
- The repo-wide CLAUDE.md evidence-path convention
- The `condition-based-waiting` skill (for hardcoded-sleep policy)

Cannot execute `xcodebuild`/`xcrun` in the sandbox (both blocked by the hooks
allowlist — see transcript). All command verification is document-based, not
empirical.

### Severity roll-up

| Severity | Count |
|----------|-------|
| CRITICAL | 0     |
| HIGH     | 3     |
| MEDIUM   | 7     |
| LOW      | 5     |

**No CRITICAL defects.** No finding in ios-validation/SKILL.md would cause a
validator to return a false PASS verdict. The HIGH issues can cause journeys
to silently skip automation (idb syntax) or mis-link evidence (path convention
vs. sibling skills). MEDIUM/LOW are clarity / discipline drift issues.

---

## Accuracy Issues

### F1 [HIGH] — `idb ui` commands use unconfirmed flag syntax and "booted" pseudonym

**Location:** SKILL.md lines 140–156 (Step 8: UI Automation — idb).

```bash
idb ui describe-all --udid booted ...
idb ui tap --x 200 --y 400 --udid booted
idb ui swipe --x 200 --y 600 --delta-x 0 --delta-y -300 --udid booted
idb ui text "hello world" --udid booted
idb ui button HOME --udid booted
```

**Problem 1 — `--udid booted`:** Per fbidb.io/docs/commands, `idb`'s `--udid`
parameter is documented as accepting a real UDID. The "booted" pseudonym is a
simctl feature, not an idb feature. `idb` typically connects to whatever target
the companion daemon has selected; if no target is selected or the user hasn't
run `idb connect`, commands fail with a companion-not-found error rather than
falling back to "the booted simulator".

**Problem 2 — `--x` / `--y` flags:** Per fbidb.io and the facebook/idb GitHub
README, the canonical form is **positional**: `idb ui tap X Y` (e.g.
`idb ui tap 200 400`). No first-party documentation shows `--x 200 --y 400`.
Running the form in SKILL.md will likely produce "unexpected argument" errors.

**Impact:** A validator following ios-validation/SKILL.md literally will see
their UI automation commands fail silently (exit code ≠ 0, but after any
background screenshots have been captured), producing screenshots-only evidence
that *appears* to prove the flow when it doesn't.

**Suggested fix:** Replace the idb block with positional syntax and a real
UDID, e.g.

```bash
UDID=$(xcrun simctl list devices booted -j \
  | python3 -c "import json,sys; print(next(d['udid'] for rs in json.load(sys.stdin)['devices'].values() for d in rs if d['state']=='Booted'))")

idb ui describe-all --udid "$UDID"
idb ui tap --udid "$UDID" 200 400
idb ui swipe --udid "$UDID" 200 600 200 300
idb ui text --udid "$UDID" "hello world"
idb ui button --udid "$UDID" HOME
```

Also add a note that `idb connect "$UDID"` may be required first.

---

### F2 [HIGH] — "Xcode MCP tools" section names are unverified / unattributed

**Location:** SKILL.md lines 158–164.

```
If using Xcode MCP tools instead:
idb_tap x=200 y=400
idb_input text="search query"
idb_gesture gesture_type=swipe start_x=200 start_y=600 end_x=200 end_y=300
idb_find_element query="Submit"
```

**Problem:** There is no first-party "Xcode MCP server". These tool names
(`idb_tap`, `idb_input`, `idb_gesture`, `idb_find_element`) are not attributed
to a specific MCP server, vendor, or package. Compare the web-validation skill,
which explicitly names "Playwright MCP" and "Chrome DevTools MCP" and cites
their tool names (e.g. `browser_navigate`, `browser_snapshot`). A reader given
this block has no way to install or locate the MCP server being referenced.

**Impact:** Validators who lack `idb` will read this section, fail to locate
the MCP server, and fall back to screenshot-only evidence. Confusion, not a
false PASS.

**Suggested fix:** Either remove the section, or replace it with a citation of
the specific MCP server (e.g. "via the idb-mcp community package at URL X,
these tool names are available") plus a link. If the section exists because
an agent-authored draft hallucinated tool names, delete it.

---

### F3 [HIGH] — Evidence path convention violates CLAUDE.md + sibling skills

**Location:** SKILL.md lines 35, 57, 63, 77–79, 87, 104, 112, 120, 134, 143,
175. Every `tee`/`screenshot`/`-exec cp` writes to `e2e-evidence/ios-*.png`
with a flat prefix, e.g.

```
e2e-evidence/ios-01-launch-screen.png
e2e-evidence/ios-02-main-view.png
e2e-evidence/ios-flow-recording.mp4
e2e-evidence/ios-build-output.txt
```

**Problem:** CLAUDE.md's "Evidence Rules" section (lines 73-82 of the project
root) mandates:

```
e2e-evidence/
  {journey-slug}/
    step-01-{description}.png
    step-02-{description}.json
    evidence-inventory.txt
```

The sibling iOS skills already follow this: `ios-validation-gate` writes to
`e2e-evidence/ios-gate-1-simulator/step-NN-*.png`; `ios-validation-runner`
writes to `e2e-evidence/$JOURNEY/step-NN-*.png` where `$JOURNEY` is derived
from a timestamp. Only `ios-validation/SKILL.md` uses the flat prefix pattern.

**Impact:** When `ios-validation` is used as a validator alongside other
platform validators on the same project, its evidence collides at
`e2e-evidence/ios-*.png` rather than being namespaced under a journey slug.
This makes multi-validator teams (rules/team-validation.md) hard to reconcile
and breaks the evidence-capturer agent's inventory assumptions. Also breaks
the e2e-validate orchestrator's own naming (documented as F5 in the
e2e-validate review, findings.md line ~90).

**Suggested fix:** Thread a `JOURNEY="ios-validation"` (or accept from caller)
and rewrite every evidence path to `e2e-evidence/$JOURNEY/step-NN-*.{ext}`.
Preserve the descriptive step name suffix.

---

### F4 [MEDIUM] — `BUNDLE_ID`, `SCHEME`, `SCHEME://PATH` used as literal placeholders without disambiguation

**Location:** SKILL.md lines 63, 70, 101–103, 111–112, 117–118, and Common
Failures row 4.

```bash
xcrun simctl launch --console-pty booted BUNDLE_ID
xcrun simctl listapps booted 2>/dev/null | grep BUNDLE_ID
--predicate 'subsystem == "BUNDLE_ID"'
xcrun simctl openurl booted "SCHEME://PATH?param=value"
```

**Problem:** The skill mixes three conventions for user-supplied values:
1. Shell-variable form (`"$APP_PATH"` on line 57) — clearly a variable.
2. Literal uppercase placeholder (`BUNDLE_ID`, `SCHEME` on lines 63/70/101/117)
   — reads like a shell variable WITHOUT the `$` prefix.
3. Metavariable placeholder (`SCHEME://PATH` on line 117) — ambiguous.

The sibling skills `ios-validation-gate` (line 42/95/156) and
`ios-validation-runner` (lines 89/116) consistently use `"$BUNDLE_ID"` shell
variables. ios-validation is the outlier.

**Impact:** A validator who literally copies `xcrun simctl launch --console-pty
booted BUNDLE_ID` will hit "No such bundle ID" errors. A validator who assumes
"$BUNDLE_ID" will wonder where the variable is set. Either way, first-try
execution fails.

**Suggested fix:** Normalize to shell variables: `"$BUNDLE_ID"`, `"$SCHEME"`,
`"$DEEP_LINK_URL"`. Add a "Parameters" table at the top (mirroring
ios-validation-gate lines 38–45) that documents how to source each:

```
| Parameter | How to source |
| SCHEME | from `xcodebuild -list` |
| BUNDLE_ID | from `Info.plist` → `CFBundleIdentifier` |
| UDID | from `xcrun simctl list devices booted` |
```

---

### F5 [MEDIUM] — Missing "Related Skills" / "Integration with ValidationForge" section

**Location:** End of SKILL.md (after line 213).

**Problem:** The skill has no outbound cross-links. Compare:
- `ios-validation-gate/SKILL.md` links to ios-validation skill implicitly via
  "iOS platform validator in e2e-validate journeys"
- `ios-validation-runner/SKILL.md` has "Integration with ValidationForge"
  section at line 241 naming evidence-capturer and verdict-writer agents
- `ios-simulator-control/SKILL.md` has "Integration with ValidationForge" at
  line 266 linking ios-validation, ios-validation-gate, ios-validation-runner,
  evidence-capturer

ios-validation (the "primary iOS validation skill" per
ios-simulator-control line 270) is missing its outbound edges. The phase-2
subtask step 4 asks us to "Cross-check Related Skills section against ./skills/
listing" — there is no such section to check.

**Impact:** The `e2e-validate` orchestrator and `validation-lead` agent may
not discover the richer iOS skills when dispatching iOS journeys. Users
reading ios-validation cannot follow the trail to ios-validation-runner's
video-recording protocol or ios-simulator-control's deeper simctl reference.

**Suggested fix:** Add at end of file:

```markdown
## Related Skills

- `ios-simulator-control` — deeper simctl reference (boot, permissions,
  location, push notifications, status bar)
- `ios-validation-gate` — three-gate enforcement (Simulator / Backend /
  Analysis) wrapping this skill's steps
- `ios-validation-runner` — five-phase protocol (SETUP / RECORD / ACT /
  COLLECT / VERIFY) with video recording
- `condition-based-waiting` — replace hardcoded `sleep 3` with polling
- `functional-validation` — platform-agnostic validation loop
- `e2e-validate` — orchestrator that dispatches iOS journeys to this skill
- `no-mocking-validation-gates` — Iron Rule enforcement
```

---

### F6 [MEDIUM] — Hardcoded `sleep 3` contradicts condition-based-waiting skill

**Location:** SKILL.md lines 65–66 (Step 3), 119 (Step 7), 132 (Step 7 loop),
200 (Common Failures row 6).

```bash
xcrun simctl launch --console-pty booted BUNDLE_ID 2>&1 | tee ... &
LAUNCH_PID=$!
sleep 3
```

**Problem:** The `condition-based-waiting` skill exists at
`./skills/condition-based-waiting/SKILL.md` explicitly to replace hardcoded
sleeps with polling. `ios-validation` uses `sleep 3` four times without even
acknowledging the pattern or linking the skill. When the device is slow (CI,
cold simulator, Intel Mac), 3 seconds is too short; when the device is fast,
it wastes time.

**Impact:** Flaky validation on slow hardware. Wasted time on fast hardware.
Precedent for other skill authors to copy the anti-pattern.

**Suggested fix:** Replace every `sleep 3` with a poll, e.g.:

```bash
# Poll for app to be running (max 10s)
for i in $(seq 1 10); do
  if xcrun simctl listapps booted 2>/dev/null | grep -q "\"$BUNDLE_ID\""; then
    break
  fi
  sleep 1
done
```

Or cite `condition-based-waiting` and link to it.

---

### F7 [MEDIUM] — Step 6 log-stream predicate assumes `subsystem == bundle-id`

**Location:** SKILL.md lines 101–105.

```bash
xcrun simctl spawn booted log stream \
  --predicate 'subsystem == "BUNDLE_ID"' \
  --level debug \
  --timeout 10 2>&1 | tee e2e-evidence/ios-app-logs.txt
```

**Problem:** Apps only log with `subsystem == bundleID` if they use
`os.Logger(subsystem: Bundle.main.bundleIdentifier!, ...)` deliberately. Many
SwiftUI / UIKit apps log via `print()` (routed to the default subsystem) or
a custom subsystem. Predicate `subsystem == "com.example.myapp"` will produce
an EMPTY log stream for any app not using that convention, and the validator
will conclude "no error logs → PASS" when in reality there were print-level
crashes not captured.

**Impact:** False PASS risk IF the validator trusts "empty log file" as
"clean run". The skill's Evidence Quality section (line 189) says "Every
screenshot MUST be accompanied by a description of what is VISIBLE", but does
NOT apply the same rigor to empty log files.

**Suggested fix:** Recommend a fallback predicate that captures *something*
even for naive apps:

```bash
# Primary predicate (app-scoped)
xcrun simctl spawn booted log stream \
  --predicate 'subsystem == "'"$BUNDLE_ID"'" OR processImagePath CONTAINS "'"$APP_NAME"'"' \
  --level debug --timeout 15 ...
```

Plus add a note: "If the log file is empty after 15s, the app is not using
os.Logger with a matching subsystem. Fall back to capturing by process name."

---

### F8 [MEDIUM] — Step 9 crash-file timeline is wrong on fresh checkouts

**Location:** SKILL.md lines 170–175.

```bash
RECENT_CRASHES=$(find "$CRASH_DIR" -name "*.ips" -newer e2e-evidence/ios-build-output.txt 2>/dev/null)
```

**Problem:** The anchor file `e2e-evidence/ios-build-output.txt` is written
in Step 1 (line 35). By Step 9, any crash that happened BEFORE the current
validation run but on the same day would still be `-newer` the anchor? No —
`-newer` compares mtime, and the anchor's mtime is when Step 1 ran, so this is
actually fine for the happy path. BUT: if Step 1 reuses a cached build (some
CI flows), `ios-build-output.txt` may already exist with an older mtime,
causing Step 9 to report crashes from a previous run as "current".

Also `.ips` is correct for modern macOS (verified via Apple docs), but the
sibling `ios-validation-runner/SKILL.md` line 162 uses `*.crash`, producing an
INTER-SKILL inconsistency.

**Impact:** On the happy path, Step 9 works. On a cached-build CI path, false
FAIL from stale crashes. Between sibling skills, crash detection drifts.

**Suggested fix:** Either anchor to a fresh timestamp file created at the
start of Step 3:

```bash
touch /tmp/ios-val-launch-timestamp.$$
# ... later, in Step 9:
RECENT_CRASHES=$(find "$CRASH_DIR" -name "*.ips" -o -name "*.crash" \
  -newer /tmp/ios-val-launch-timestamp.$$ 2>/dev/null)
```

And include BOTH `*.ips` and `*.crash` globs for compatibility.
Flag ios-validation-runner's `*.crash`-only filter to be updated to match in
phase-4 (OUT OF SCOPE for this subtask — just note the inconsistency).

---

### F9 [MEDIUM] — `brew install idb-companion` in Common Failures is incomplete

**Location:** SKILL.md line 201 (Common Failures row 7).

```
| idb not found | idb not installed | brew install idb-companion or use simctl/Xcode MCP instead |
```

**Problem:** Per fbidb.io/docs/installation, installing the CLI requires TWO
steps:

```
brew tap facebook/fb
brew install idb-companion
pip3 install fb-idb
```

`brew install idb-companion` alone installs only the native companion daemon;
the `idb` CLI is the Python `fb-idb` package. Users who run only the brew
command will still see `idb: command not found` and conclude the fix is
wrong.

**Impact:** Users abandon idb automation and regress to screenshot-only
evidence. No false PASS risk, but eroded trust in the skill.

**Suggested fix:** Replace with:

```
| idb not found | idb-companion daemon or fb-idb CLI missing | `brew tap facebook/fb && brew install idb-companion && pip3 install fb-idb` (see https://fbidb.io/docs/installation) or fall back to simctl for what it covers |
```

---

### F10 [MEDIUM] — PASS Criteria missing accessibility + log-empty check + backend correlation

**Location:** SKILL.md lines 203–213 (PASS Criteria Template).

**Problem:** The 9-bullet checklist does NOT include:
1. **Accessibility tree captured** — Step 8 mentions `idb ui describe-all`
   and ios-validation-gate's Gate 1 PASS criterion is "Accessibility tree has
   interactive elements" (line 91 of that skill). ios-validation omits it.
2. **Log file is non-empty or explicitly N/A** — as flagged in F7, an empty
   log file is treated as "no errors". Should be "non-empty AND no error
   entries" OR "documented reason for being empty".
3. **Backend correlation (if app has backend dep)** — ios-validation-gate
   has an entire Gate 2 for backend validation. ios-validation's PASS
   criteria omits any mention of API/network. A feature that fetches data and
   silently fails on a 500 would PASS every listed criterion (no error dialog
   visible, no crash, screenshots render a blank list view = "renders with
   expected content").
4. **Performance threshold "launch < 3s, transitions < 0.5s" is unsourced** —
   no justification for the numbers. Some apps legitimately take 5s on cold
   launch for warm caches. Should be project-configurable.

**Impact:** PASS criteria currently allow a broken app to pass if it
doesn't CRASH. The most dangerous false-PASS path for iOS journeys.

**Suggested fix:** Add:
```
- [ ] Accessibility tree captured and shows interactive elements (cite
      e2e-evidence/{journey}/step-NN-accessibility-tree.txt)
- [ ] App logs file captured and either (a) contains expected debug entries
      for the exercised flow, OR (b) contains a documented reason for emptiness
      (e.g., app uses NSLog without os.Logger)
- [ ] If app has backend dependency: all critical API calls returned 2xx
      (cross-validate via api-validation skill; cite API response evidence)
- [ ] Performance within project-configured thresholds (document them; not
      hardcoded)
```

---

## Stale References

### F11 [LOW] — Prerequisites "mkdir -p e2e-evidence" is a creation command, not a verification

**Location:** SKILL.md line 20.

```
| Evidence directory exists | `mkdir -p e2e-evidence` |
```

**Problem:** The "How to verify" column says `mkdir -p`, which CREATES the
directory rather than VERIFYING it exists. Minor semantic nit.

**Suggested fix:** Either move the `mkdir -p` into a "Setup" section or change
the verification to `test -d e2e-evidence || mkdir -p e2e-evidence`.

---

### F12 [LOW] — Hardcoded "iPhone 16" simulator name

**Location:** SKILL.md lines 25, 33.

```bash
xcrun simctl boot "iPhone 16"
```

**Problem:** iPhone 16 requires iOS 18+ Simulator runtime installed. On a
dev machine with only iOS 17, the boot command will fail with "Invalid device
state" or "Device type not available". Users on older Xcode hit this first.

**Impact:** Preflight fails for anyone not on bleeding-edge Xcode.

**Suggested fix:** Add fallback logic:

```bash
# Pick first available iPhone simulator
DEVICE=$(xcrun simctl list devices available -j \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if 'iPhone' in d['name']:
            print(d['name']); sys.exit()
")
xcrun simctl boot "$DEVICE"
```

Or just say "pick any booted or available iPhone simulator — the name below
is an example."

---

### F13 [LOW] — `--timeout 10` may be too short for an interactive flow

**Location:** SKILL.md lines 104, 112.

```bash
xcrun simctl spawn booted log stream ... --timeout 10
```

**Problem:** 10s is long enough for a single screenshot but not long enough
for a multi-step flow (Step 7 loops 4 deep links with `sleep 2` each → 8s of
sleeps alone). The sibling ios-validation-runner uses `--timeout 15` (line
157 of that skill) and backgrounds the stream so it runs for the full flow
duration.

**Impact:** Log file ends before the flow does; later crash events aren't
captured.

**Suggested fix:** Either background the log stream (runner pattern) or bump
`--timeout` to 30 with a note that timeout should exceed the total flow
duration.

---

### F14 [LOW] — Step 5 video recording uses a single filename; no multi-clip support

**Location:** SKILL.md lines 86–95.

```bash
xcrun simctl io booted recordVideo --codec=h264 e2e-evidence/ios-flow-recording.mp4 &
```

**Problem:** Only one video per run. If the flow has multiple chapters (e.g.,
login → dashboard → settings), a single continuous MP4 is fine but hard to
reference in the report. ios-validation-runner uses `step-02-recording.mp4`
inside a journey subdir (line 78 of runner), which is also single-file but
scoped.

**Impact:** Minor reporting / multi-run collision risk (two validation runs
overwrite the same file).

**Suggested fix:** Include a timestamp or journey slug in the filename, e.g.
`e2e-evidence/${JOURNEY}/step-05-recording.mp4`, consistent with F3's
evidence-path fix.

---

### F15 [LOW] — No SIGKILL warning on video recording

**Location:** SKILL.md lines 92–94.

```bash
# Stop recording
kill -INT $VIDEO_PID
wait $VIDEO_PID 2>/dev/null
```

**Problem:** The command is correct (`kill -INT` = SIGINT). But the sibling
`ios-validation-runner` skill has a BOLD warning (line 83 of runner):

> **CRITICAL:** Stop video with `kill -INT $VIDEO_PID` (SIGINT), NEVER
> `kill -9`. SIGKILL corrupts the video file.

ios-validation has no such warning. A user who customizes the script (e.g.,
adds a cleanup `kill -9 $VIDEO_PID` for "safety") will corrupt their video
without understanding why.

**Impact:** Lost video evidence on customized flows.

**Suggested fix:** Copy the runner's CRITICAL warning into Step 5.

---

## Missing Content

### F16 [MEDIUM] — No "When to Use" section

Sibling skills (ios-validation-gate lines 15–19; ios-validation-runner lines
16–21; ios-simulator-control lines 17–23) all have a "When to Use" section.
ios-validation does not. A reader cannot quickly determine when to pick THIS
skill vs. ios-validation-gate vs. ios-validation-runner.

**Suggested fix:** Add after the first paragraph:

```markdown
## When to Use

- As the primary iOS validator for standard feature verification (build +
  install + launch + screenshot + log check)
- When you need a flat, single-file skill (no orchestration)
- When the three-gate discipline (see ios-validation-gate) is overkill
- Delegated to by e2e-validate / functional-validation for iOS journeys

For deeper protocols, use instead:
- ios-validation-gate (three-gate enforcement)
- ios-validation-runner (five-phase with video)
```

---

## Broken Cross-Links

None found. The skill has NO outbound cross-links to verify — but see F5
(missing section).

Inbound references verified:
- `./skills/ios-simulator-control/SKILL.md` line 270 mentions ios-validation
  as "the primary iOS validation skill". ✓ (accurate characterisation)
- `./skills/e2e-validate/references/ios.md` (not re-checked in this subtask,
  per phase-2 scope; the e2e-validate review covered this in its own findings
  — F10 of that review notes the ios-validate reference file vs. platform
  skill alignment.)

---

## Recommendations (priority-ordered)

1. **[HIGH] Fix the idb block (F1):** Switch to positional tap/swipe syntax,
   require a real UDID, add `idb connect "$UDID"`. Without this the UI
   automation half of the skill is a lie.
2. **[HIGH] Remove or cite the "Xcode MCP tools" block (F2):** Current form
   is unattributed.
3. **[HIGH] Adopt the journey-slug evidence path convention (F3):** Every
   `e2e-evidence/ios-*.png` becomes `e2e-evidence/${JOURNEY}/step-NN-*.png`.
4. **[MEDIUM] Add Related Skills + When to Use sections (F5, F16).**
5. **[MEDIUM] Normalize placeholders to shell variables + add Parameters
   table (F4).**
6. **[MEDIUM] Replace hardcoded sleeps with condition-based-waiting (F6).**
7. **[MEDIUM] Strengthen log-capture + PASS criteria (F7, F10).**
8. **[MEDIUM] Fix the idb-companion Common Failures row (F9).**
9. **[LOW] Clean up F8 (crash-file timeline), F11 (prereq verification),
   F12 (iPhone 16 hardcoded), F13 (log timeout), F14 (video filename), F15
   (SIGKILL warning).**

All CRITICAL: none. None of the above, applied or unapplied, causes a false
PASS on the happy path. The F1/F7/F10 combination is the single largest
false-PASS risk — empty log + broken idb + PASS criteria that only checks
for crashes → an app with a silent backend 500 passes.

---

## Evidence

- `./e2e-evidence/skill-review/ios-validation/command-verification-transcript.txt`
  — environment + external research summary
- `./e2e-evidence/skill-review/ios-validation/skills-directory-listing.txt`
  — directory listing confirming ios-validation-{gate,runner}, ios-simulator-control exist
- Note: `xcodebuild`/`xcrun` execution blocked by sandbox allowlist; all
  command-correctness findings are documentation-based, not empirical.
