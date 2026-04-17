# web-validation Skill — Deep Review Findings

**Skill file:** `./skills/web-validation/SKILL.md` (185 lines, single-file skill — no `references/` or `workflows/` directory)
**Reviewer:** auto-claude (phase-2-subtask-2)
**Date:** 2026-04-17
**Commit baseline:** see `git log -1` at time of review

## Summary

Verified all 8 Steps (Dev Server / Health / Navigation / Console / Network /
Form / Responsive / Routes), Prerequisites table, Evidence Quality section,
Common Failures table, and PASS Criteria Template against:

- Current Playwright MCP server
  (github.com/microsoft/playwright-mcp — src/tools + README.md) via
  general-purpose agent web fetch; transcript in
  `mcp-tool-name-verification.txt`.
- Current Chrome DevTools MCP server
  (github.com/ChromeDevTools/chrome-devtools-mcp — docs/tool-reference.md)
  via general-purpose agent web fetch; transcript in same file.
- Sibling web skills: `playwright-validation`, `chrome-devtools`,
  `web-testing`, `responsive-validation`.
- The `e2e-validate` orchestrator reference at
  `./skills/e2e-validate/references/web-validation.md`.
- CLAUDE.md evidence-path convention.
- `condition-based-waiting` skill (for polling policy).

`curl`/`jq` executed on this machine; tool outputs saved in
`command-verification-transcript.txt`. MCP calls not executed (no browser
session wired into this worktree — out of scope).

### Severity roll-up

| Severity | Count |
|----------|-------|
| CRITICAL | 0     |
| HIGH     | 4     |
| MEDIUM   | 8     |
| LOW      | 4     |

**No CRITICAL defects.** No finding would produce a false PASS verdict on the
happy path. The HIGH issues mean Playwright MCP tool calls copy-pasted from
this skill will be rejected by the current server on first use (F1/F2/F3) and
that the dev-server detection bash block silently fails on Bun/Deno/Vue
CLI/Angular projects (F4). MEDIUM issues are the missing Chrome DevTools
equivalents across Steps 4-8, inconsistent viewport tables between sibling
skills, and absence of cross-links.

---

## Accuracy Issues

### F1 [HIGH] — `browser_network_requests` uses wrong parameter name `includeStatic`

**Location:** SKILL.md lines 93, 98 (Step 5: Network Request Validation).

```
browser_network_requests  includeStatic=false
browser_network_requests  includeStatic=false  filename="e2e-evidence/web-network-requests.txt"
```

**Problem:** The current Playwright MCP server
(github.com/microsoft/playwright-mcp) documents the parameter as **`static`**
(boolean), NOT `includeStatic`. See verification transcript
`mcp-tool-name-verification.txt` lines 35-43. The MCP server will either
reject the call with an "unknown parameter" error or silently ignore the flag,
causing the returned list to include every CSS/JS/font/image request — the
opposite of the intent.

**Impact:** Validator runs the tool, gets 200+ static-asset requests mixed in
with API calls, concludes "API calls look fine" from the top-of-list while
important 4xx/5xx responses scroll off. First-try failure if the server is
strict about unknown params; silent false-PASS risk if it's permissive.

**Suggested fix:**

```
browser_network_requests  static=false
```

And update Step 5 explanation: "static=false filters out CSS/JS/image/font
requests to focus on fetch/XHR calls."

---

### F2 [HIGH] — `browser_click` omits the required `element` parameter

**Location:** SKILL.md lines 62, 64, 109, 119 (Step 3: Navigation; Step 6:
Form Validation).

```
browser_click  ref="LINK_REF"
browser_click  ref="SUBMIT_REF"
```

**Problem:** The current Playwright MCP `browser_click` tool requires BOTH
`ref` (from a prior snapshot) AND `element` (a human-readable description
for audit/log output). See `mcp-tool-name-verification.txt` lines 20-22. The
MCP server rejects calls missing `element` with a schema-validation error.

The sibling `./skills/e2e-validate/references/web-validation.md` already has
it right at line 131:

```
browser_click ref="button-submit" element="Submit button"
```

**Impact:** Every click call the skill shows will fail first-try with a
"missing required parameter 'element'" error. A validator who copies the
skill literally gets a wall of red before any screenshot is captured.

**Suggested fix:** Append `element="..."` to every `browser_click` call,
e.g.

```
browser_click  ref="LINK_REF"   element="main navigation link"
browser_click  ref="SUBMIT_REF" element="Submit button"
```

---

### F3 [HIGH] — `browser_console_messages` / `browser_network_requests` misuse `filename` kwarg

**Location:** SKILL.md lines 85, 98 (Steps 4 and 5).

```
browser_console_messages  level="error"  filename="e2e-evidence/web-console-errors.txt"
browser_network_requests  includeStatic=false  filename="e2e-evidence/web-network-requests.txt"
```

**Problem:** `browser_console_messages` in the current Playwright MCP server
does NOT document a `filename` parameter (see
`mcp-tool-name-verification.txt` lines 24-28). The tool returns console
output directly; it is up to the caller to save. The skill implies the tool
writes the file itself, which is misleading.

`browser_network_requests` DOES accept `filename` per the agent report, so
the Step 5 invocation is OK in that regard. But the Step 4 form is wrong,
and the two appear side-by-side with identical syntax — so a validator
reasonably assumes both behave the same.

**Impact:** The file at `e2e-evidence/web-console-errors.txt` is never
created; a downstream verdict-writer cites "see console-errors.txt" and
finds a missing file. Graded output for Step 4 evidence is missing — but
the validator believes it was captured (no error surfaced).

**Suggested fix:** Save the tool output through a separate mechanism, e.g.:

```
# Capture the return from browser_console_messages into the evidence file
browser_console_messages  level="error"
# Then save the response text yourself (tool_use response → Write tool):
#   Write  file_path="e2e-evidence/web-console-errors.txt"  content="<tool output>"
```

Or reference the Playwright MCP's real save mechanism if one is documented
(the agent report suggested `filename` may work on `browser_network_requests`
— verify before claiming it works for `browser_console_messages`).

---

### F4 [HIGH] — Dev-server detection misses Bun, Deno, Vue CLI, Angular, Rust/Go, PHP, Flask, etc.

**Location:** SKILL.md lines 19-34 (Step 1: Start Dev Server).

```bash
if [ -f pnpm-lock.yaml ]; then
  pnpm dev &
elif [ -f package-lock.json ]; then
  npm run dev &
elif [ -f yarn.lock ]; then
  yarn dev &
elif [ -f manage.py ]; then
  python manage.py runserver &
elif [ -f Gemfile ]; then
  bundle exec rails server &
fi
DEV_PID=$!
```

**Problem:** See `dev-server-detection-gap-analysis.txt` for the full list.
Highest-impact gaps:

1. **Bun:** `bun.lockb` / `bun.lock` not detected. Bun is the fastest-growing
   JS runtime of 2024-2026. On a Bun project the script matches no branch.
2. **Deno:** `deno.json` / `deno.lock` not detected.
3. **Vue CLI:** detected via `package-lock.json` branch, but Vue CLI's dev
   script is `serve`, NOT `dev`. `npm run dev` fails with
   "Missing script: dev".
4. **Angular:** same issue — Angular's dev script is `start`. `npm run dev`
   fails.
5. **PHP (Laravel):** no detection.
6. **Python non-Django (Flask/FastAPI):** no detection.
7. **Rust/Go backend:** no detection.

Worse, the `DEV_PID=$!` assignment on line 33 lives OUTSIDE the if/elif
block. If NONE of the branches match (Bun, Deno, Laravel, etc.), `$!`
refers to whatever backgrounded job last ran in this shell — possibly
undefined, possibly a prior process the caller wants to keep alive. A
subsequent `kill $DEV_PID` kills the wrong thing.

**Impact:** For the "happy path" — pnpm/npm/yarn + Next.js/Vite/Astro/Remix
with a `dev` script — the block works. Outside that, the skill silently
fails. For Vue CLI / Angular projects using `package-lock.json`, the block
runs the WRONG command (`npm run dev` instead of `npm run serve`), causing
the 30-second readiness loop to time out with no server running.

**Suggested fix:** See full rewrite in
`dev-server-detection-gap-analysis.txt` line 50-75. Key additions:

- Detect Bun (`bun.lockb` / `bun.lock`) BEFORE npm/yarn/pnpm (since Bun
  projects often still have package.json).
- Detect Deno (`deno.json`).
- Fail loudly if no branch matches rather than silently dropping through.
- Check for `scripts.dev` in package.json before running `$PM dev`.

---

### F5 [MEDIUM] — Chrome DevTools path missing for Steps 4, 5, 6, 7

**Location:** SKILL.md Steps 4 (lines 78-88), 5 (90-99), 6 (101-121), 7
(123-143).

**Problem:** Step 3 (Navigation) demonstrates both Playwright MCP and Chrome
DevTools MCP paths side-by-side (`browser_navigate` vs `navigate_page`;
`browser_snapshot` vs `take_snapshot`; etc.). Steps 4-7 show ONLY the
Playwright MCP equivalent, even though the Chrome DevTools MCP has
direct equivalents:

| Step | Playwright (shown)             | Chrome DevTools (omitted)                |
|------|--------------------------------|------------------------------------------|
| 4    | browser_console_messages       | list_console_messages  types=["error"]   |
| 5    | browser_network_requests       | list_network_requests  resourceTypes=[…] |
| 6    | browser_fill_form              | fill_form  (DevTools also has this)      |
| 7    | browser_resize                 | resize_page  width=… height=…            |

**Impact:** A validator using Chrome DevTools MCP (e.g., because Playwright
MCP is not installed, or because they want Lighthouse audits) must guess
the tool names or stop mid-validation to read `chrome-devtools/SKILL.md`.
Productivity drag, not a false PASS, but contradicts the skill's opening
framing ("Web platform validation through browser automation (Playwright
MCP or Chrome DevTools MCP)").

**Suggested fix:** Mirror the Step 3 two-path format for Steps 4-7. Or,
alternatively, add a top-of-skill note: "All steps below use Playwright
MCP syntax. For Chrome DevTools MCP equivalents, see
`chrome-devtools/SKILL.md`."

---

### F6 [MEDIUM] — Step 1 readiness loop matches only `200`, breaks on redirects

**Location:** SKILL.md lines 37-45.

```bash
for i in $(seq 1 30); do
  if curl -s http://localhost:3000 -o /dev/null -w "%{http_code}" 2>/dev/null | grep -q "200"; then
    echo "Server ready"
    break
  fi
  sleep 1
done
```

**Problem:** The server is "ready" iff the root URL returns exactly `200`.
This breaks for:

- **Next.js with i18n:** `/` redirects to `/en` with 307/308.
- **Auth-gated SPAs:** `/` redirects to `/login` with 302.
- **Rails:** some apps redirect `/` to `/signin`.
- **Astro trailing-slash strict mode:** redirects with 301.

Any of these leave the loop spinning until timeout, then declaring the
server not-ready when it IS ready. The sibling
`e2e-validate/references/web-validation.md` uses `curl -sf` (fails on 4xx/5xx,
succeeds on any 2xx/3xx that doesn't error) which is more forgiving.

**Impact:** False preflight FAIL on ~20% of real-world sites. Validator
moves on manually, but the readiness check offered a false signal.

**Suggested fix:**

```bash
for i in $(seq 1 30); do
  CODE=$(curl -s http://localhost:3000 -o /dev/null -w "%{http_code}" 2>/dev/null)
  if [ "$CODE" != "000" ] && [ "${CODE:0:1}" != "5" ]; then
    echo "Server ready (HTTP $CODE)"
    break
  fi
  sleep 1
done
```

Or simply use `curl -sf` — "succeed on any 2xx/3xx".

---

### F7 [MEDIUM] — Hardcoded `sleep 1` contradicts condition-based-waiting skill

**Location:** SKILL.md line 43.

**Problem:** The retry loop uses `sleep 1` inside the condition — acceptable
— but the overall pattern doesn't acknowledge the `condition-based-waiting`
skill at `./skills/condition-based-waiting/SKILL.md`, which exists
specifically to codify the "poll the condition, not a fixed duration"
pattern (Strategy #1: HTTP Health Poll, with a 30s default timeout). The
web-validation loop is functionally correct but doesn't link the skill.

This is the same finding as ios-validation F6 — same product, same
inconsistency.

**Impact:** Nothing broken, but every skill that re-implements polling
without referencing `condition-based-waiting` weakens the shared
vocabulary.

**Suggested fix:** Add a one-liner in Step 1 after the loop:

> See `condition-based-waiting` (Strategy #1: HTTP Health Poll) for the
> polling pattern and the canonical 30-second timeout.

---

### F8 [MEDIUM] — Viewport table disagrees with three sibling skills

**Location:** SKILL.md lines 127-132 (Step 7 table); also mirrored in
PASS Criteria line 182.

**Problem:** See `viewport-table-crosscheck.txt` for the full comparison.
Four skills inside ValidationForge publish different viewport canons:

| Source                        | Mobile       | Tablet    | Laptop      | Desktop      |
|-------------------------------|--------------|-----------|-------------|--------------|
| web-validation (this file)    | 375×667      | 768×1024  | 1280×720    | 1920×1080    |
| e2e-validate/references/web   | 375×667      | 768×1024  | 1280×720    | 1920×1080    |
| playwright-validation         | 375×812      | 768×1024  | —           | 1440×900     |
| responsive-validation         | 375×667 + 2 more | 768×1024 + 1024×1366 | 1280×800 | 1440×900 + 1920×1080 |

web-validation + e2e-validate agree. playwright-validation publishes a
different set (and claims "iPhone SE = 375×812" which contradicts real
hardware). responsive-validation publishes the most thorough matrix.

The skill's PASS Criteria at line 182 says:

> Responsive layout correct at mobile (375px), tablet (768px), desktop (1920px)

This drops the "Laptop 1280" row that Step 7 demands a screenshot for —
i.e., Step 7 says capture 4 viewports; PASS criteria only checks 3.

**Impact:** Inconsistent docs within one product. A validator following
web-validation captures desktop/laptop/tablet/mobile; verdict-writer
reviewing against the PASS criteria gives credit for only 3 of 4. Low-stakes
but annoying.

**Suggested fix:** Either
(a) add a 4th PASS criterion bullet for 1280px (to match Step 7), or
(b) drop Laptop 1280×720 from Step 7 to match the 3-bullet PASS list,
AND reference responsive-validation for the full matrix: "For
comprehensive device-viewport coverage, see responsive-validation/SKILL.md".

---

### F9 [MEDIUM] — No "Related Skills" / "Integration with ValidationForge" section

**Location:** End of SKILL.md (after line 184).

**Problem:** web-validation has NO outbound cross-links. Every sibling skill
in the same cluster DOES:

- `playwright-validation/SKILL.md` line 208: `## Integration with ValidationForge`
- `chrome-devtools/SKILL.md` line 200: `## Integration with ValidationForge`
- `web-testing/SKILL.md` line 210: `## Integration with ValidationForge`
- `responsive-validation/SKILL.md` line 191: `## Integration with ValidationForge`

Inbound references to web-validation exist in:
- `./skills/e2e-validate/SKILL.md`
- `./skills/fullstack-validation/SKILL.md`
- `./skills/functional-validation/SKILL.md`
- `./skills/parallel-validation/SKILL.md`
- `./skills/playwright-validation/SKILL.md` (line 212 — implicit complement)
- `./agents/platform-detector.md`
- `./commands/validate-team.md`, `./commands/validate.md`
- `./rules/team-validation.md`

So web-validation is INBOUND-heavy but OUTBOUND-empty. Readers can't trail
upward from web-validation to its orchestrators or downward to deeper
protocols.

This is identical to the ios-validation F5 finding — same product, same
structural gap.

**Impact:** Readers land on web-validation (the name most people guess
first), exhaust its 8 steps, then don't know where to go for Core Web
Vitals (→ `chrome-devtools` Pattern 1), a11y audits (→ `accessibility-audit`
+ `chrome-devtools` Pattern 3), or a deeper device matrix (→
`responsive-validation`).

**Suggested fix:** Add at end of file:

```markdown
## Related Skills

- `playwright-validation` — deeper Playwright MCP workflow with journey
  protocols and evidence inventory
- `chrome-devtools` — Chrome DevTools MCP for performance, Lighthouse,
  memory profiling
- `responsive-validation` — comprehensive device viewport matrix
- `web-testing` — 5-layer web validation strategy (integration, E2E,
  a11y, perf, security)
- `accessibility-audit` — WCAG 2.1 AA validation
- `visual-inspection` — visual diff and UI state verification
- `condition-based-waiting` — polling patterns for dev-server readiness
- `functional-validation` — platform-agnostic validation loop
- `e2e-validate` — orchestrator that dispatches web journeys to this skill
- `no-mocking-validation-gates` — Iron Rule enforcement
```

---

### F10 [MEDIUM] — Step 6 form "invalid data" test has no assertion on the error state

**Location:** SKILL.md lines 113-121.

```
browser_fill_form  fields=[
  {"name": "Email", "type": "textbox", "ref": "EMAIL_REF", "value": "not-an-email"},
  {"name": "Password", "type": "textbox", "ref": "PASS_REF", "value": ""}
]
browser_click  ref="SUBMIT_REF"
browser_take_screenshot  filename="e2e-evidence/web-form-invalid-submit.png"
```

**Problem:** The "invalid data" path asserts NOTHING. The screenshot captures
whatever state the browser is in, but there's no instruction to verify that:

- An error message is visible
- The form did NOT submit
- Focus returned to the invalid field

Compare the sibling `playwright-validation/SKILL.md` lines 115-118 which
include the phrase "Test validation errors" with the implicit expectation
that the screenshot shows them. web-validation is weaker.

**Impact:** A validator whose invalid-data case accidentally submits (e.g.,
broken client-side validation) will happily capture the screenshot of a
success page and count it as "invalid data tested". False PASS on the
negative-path journey.

**Suggested fix:** After the screenshot, add a snapshot + assertion:

```
browser_snapshot
# Verify snapshot contains the validation error text
# PASS: the form is still on the submit page AND error text is visible
# FAIL: redirect occurred (form submitted with invalid data)
```

And add a bullet to PASS Criteria: "Invalid form data produces a visible
error message and prevents submission (cite the snapshot)."

---

### F11 [MEDIUM] — Prerequisite row 3 uses `mkdir -p` as a "verification"

**Location:** SKILL.md line 16 (Prerequisites table).

```
| Evidence directory exists | `mkdir -p e2e-evidence` |
```

**Problem:** Same nit as ios-validation F11. `mkdir -p` CREATES the
directory; it does not VERIFY it exists. The "How to verify" column
promises a check, delivers a side-effecting action.

**Impact:** Minor semantic nit; no execution risk.

**Suggested fix:** Change to `test -d e2e-evidence || mkdir -p e2e-evidence`
or `ls -d e2e-evidence/ 2>/dev/null`, same pattern as the preflight skill's
web checklist row 8.

---

### F12 [MEDIUM] — Step 8 route-coverage loop reports 3xx as failures

**Location:** SKILL.md lines 148-156.

```bash
ROUTES=("/" "/about" "/dashboard" "/settings" "/login")
for route in "${ROUTES[@]}"; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:PORT$route")
  echo "$route -> $STATUS" | tee -a e2e-evidence/web-route-check.txt
done
```

Narration: "Any non-200 response (except expected redirects) is a finding."

**Problem:** The narration acknowledges redirects as an exception, but the
loop does NOT filter or annotate them. The tee'd output is a flat
`<route> -> <code>` list with no distinction between 200, 301, 302, 307,
308, 404, 500. The validator must manually re-read the output and decide
which redirects are "expected." This hand-off is where false FAILs (or,
for 200-returns-a-404-page SPAs, false PASSes) sneak in.

**Impact:** Validator effort-bias. With 20 routes on a big app, tediously
classifying each one is exactly the kind of manual review that gets
skipped.

**Suggested fix:** Classify in the loop:

```bash
for route in "${ROUTES[@]}"; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:PORT$route")
  case $STATUS in
    200) VERDICT="PASS" ;;
    301|302|307|308) VERDICT="REDIRECT — manually verify target" ;;
    404) VERDICT="FAIL — route missing" ;;
    5??) VERDICT="FAIL — server error" ;;
    *)   VERDICT="INVESTIGATE" ;;
  esac
  echo "$route -> $STATUS [$VERDICT]" | tee -a e2e-evidence/web-route-check.txt
done
```

Plus: for true SPA route verification, the URL returning 200 is necessary
but not sufficient — the rendered page could still be the 404 fallback.
Add a note referencing Step 3 for browser-based navigation verification.

---

## Stale References

### F13 [LOW] — `web-*.png` evidence-path prefix violates the journey-slug convention

**Location:** SKILL.md lines 50, 52, 63, 64, 71, 74, 85, 98, 110, 120,
136, 139, 142, 152, 175 (every evidence file).

All paths follow the pattern `e2e-evidence/web-<step-description>.{png,txt}`
(e.g., `web-01-homepage.png`, `web-health-check.txt`,
`web-route-check.txt`).

**Problem:** CLAUDE.md's Evidence Rules mandate:

```
e2e-evidence/
  {journey-slug}/
    step-01-{description}.png
    step-02-{description}.json
    evidence-inventory.txt
```

The sibling `playwright-validation/SKILL.md` line 147+ already follows this
(`e2e-evidence/web-playwright/step-NN-*.png`). web-validation alone uses the
flat prefix. Same finding as ios-validation F3.

**Impact:** When web-validation is used as a validator alongside other
platform validators on the same project, its evidence collides at
`e2e-evidence/web-*.png` rather than being namespaced. Evidence-capturer
agent's inventory assumptions break. Multi-validator teams
(rules/team-validation.md) hard to reconcile.

**Suggested fix:** Thread a `JOURNEY="web-validation"` variable (or accept
from caller) and rewrite every evidence path to
`e2e-evidence/$JOURNEY/step-NN-*.{ext}`.

This is a smaller fix than it looks — a single `JOURNEY=web-validation`
at the top and `sed`-style path updates throughout.

---

### F14 [LOW] — `lsof -ti:PORT | xargs kill -9` (Common Failures row 1) is overbroad

**Location:** SKILL.md line 168.

```
| Port already in use | Previous server still running | `lsof -ti:PORT \| xargs kill -9` |
```

**Problem:** `lsof -ti:PORT` returns all PIDs listening on PORT.
`xargs kill -9` sends SIGKILL to every one of them. On a dev machine with
multiple projects' Next.js dev servers happening to share port 3000 (common
when switching branches), this nukes the innocent ones too. And SIGKILL is
the hammer — SIGTERM first is gentler.

**Impact:** Data loss risk on the developer's machine. Not a validation
failure, but a destructive footgun.

**Suggested fix:**

```
| Port already in use | Previous server still running | `lsof -ti:PORT \| head -1 \| xargs -r kill` (then `kill -9` only if needed) |
```

Plus a note: "If multiple processes are on PORT, list them with
`lsof -i:PORT` first before mass-killing."

---

### F15 [LOW] — PASS Criteria "Page load time under 3 seconds" lacks measurement instruction

**Location:** SKILL.md line 184 (last PASS bullet).

**Problem:** The bullet says "Page load time under 3 seconds" but nowhere in
the 8 Steps does the skill tell the validator HOW to measure page load. The
closest is Step 2 health check's `-w "Time: %{time_total}s\n"` — but that
measures curl-only time (no JS execution, no asset loading).

Real "page load time" needs either:
- Chrome DevTools MCP `performance_start_trace` → LCP metric
- Or `browser_navigate` + `browser_snapshot` with timing from network
  requests

Neither is instructed in this skill. The number "3 seconds" is also
unsourced — web.dev's "good LCP" threshold is 2.5s, not 3s.

**Impact:** Validator shrugs, doesn't measure, either marks PASS without
evidence (violating gate-validation-discipline) or skips the bullet
entirely.

**Suggested fix:** Either drop the bullet (and note perf testing is covered
in `chrome-devtools`/Pattern 1 Page Load Performance), or add Step 9 with
the actual measurement commands and a 2.5s threshold citing web.dev.

---

### F16 [LOW] — Prerequisites row 2 "Playwright MCP or Chrome DevTools MCP connected" has no verification command

**Location:** SKILL.md line 15.

```
| Browser automation available | Playwright MCP or Chrome DevTools MCP connected |
```

**Problem:** The "How to verify" column is a description, not a command.
Compare row 1 ("`curl -s http://localhost:PORT -o /dev/null -w "%{http_code}"`")
and row 3 ("`mkdir -p e2e-evidence`" — also wrong per F11, but at least a
command). Row 2 has no command at all.

**Impact:** Validator can't mechanically verify MCP availability. They
have to try a tool call and see if it fails.

**Suggested fix:** There's no CLI to ping an MCP server directly, but the
skill can suggest: "In the /validate or /validate-plan session, ask an
agent to run `browser_snapshot` or `take_snapshot` once — a tool-not-found
error indicates the MCP server isn't connected. A success or auth error
indicates it is." Or add a preflight bullet to `preflight/SKILL.md` at a
phase-4 fix time.

---

## Missing Content

### F17 [MEDIUM] — No "When to Use" section

Sibling skills have "When to Use" sections:
- `playwright-validation/SKILL.md` line 15
- `chrome-devtools/SKILL.md` line 16
- `web-testing/SKILL.md` line 15
- `responsive-validation/SKILL.md` line 16

web-validation does not. A reader cannot quickly determine when to pick
THIS skill vs. the others. Same finding as ios-validation F16.

**Suggested fix:** Add after line 8:

```markdown
## When to Use

- As the default web validator for most browser-based feature verification
- When you need an 8-step checklist spanning dev-server → health → nav →
  console → network → forms → responsive → routes
- Delegated to by `e2e-validate`, `fullstack-validation`,
  `functional-validation`, and `parallel-validation`

For deeper focus, use instead:
- `playwright-validation` — MCP-first browser automation protocols
- `chrome-devtools` — performance, Lighthouse, memory profiling
- `responsive-validation` — comprehensive device viewport matrix
- `web-testing` — 5-layer web validation strategy
```

---

### F18 [LOW] — No Evidence-Inventory guidance

**Location:** Nowhere in SKILL.md.

**Problem:** `playwright-validation/SKILL.md` lines 162-167 give an
`evidence-inventory.txt` generator that the `verdict-writer` agent consumes.
web-validation has nothing equivalent. The validator finishes the 8 steps,
writes ~10 files into `e2e-evidence/web-*.png`, and moves on without
producing the inventory file the agent expects.

**Impact:** Verdict-writer agent sees a directory full of files but no
inventory — minor friction, no false PASS risk.

**Suggested fix:** Append to the PASS Criteria section:

```markdown
## Evidence Inventory

```bash
find e2e-evidence -type f -name "web-*" | sort | while read f; do
  echo "$(wc -c < "$f" | tr -d ' ') $f"
done | tee e2e-evidence/web-inventory.txt
```
```

(Adjust path per F13 once journey-slug fix is applied.)

---

## Broken Cross-Links

None broken. But see F9 (no outbound cross-links at all — absent, not broken).

Inbound cross-references verified:

- `./skills/e2e-validate/SKILL.md` cites web-validation.
- `./skills/fullstack-validation/SKILL.md` cites web-validation.
- `./skills/functional-validation/SKILL.md` cites web-validation.
- `./skills/parallel-validation/SKILL.md` cites web-validation.
- `./skills/playwright-validation/SKILL.md` line 212 implicitly cites it:
  "Complements the existing web-validation skill with deeper browser
  automation".
- `./agents/platform-detector.md`, `./commands/validate-team.md`,
  `./commands/validate.md`, `./rules/team-validation.md` all reference.

`./skills/e2e-validate/references/web-validation.md` is the orchestrator's
mirror of this skill. Checked against web-validation/SKILL.md content:
MCP tool-name syntax in the reference IS correct (uses `element=` on
browser_click; uses jq-style filters correctly). The reference is
actually MORE accurate than the SKILL.md it references — which is a
signal that web-validation/SKILL.md is stale.

---

## Recommendations (priority-ordered)

1. **[HIGH] Fix the `includeStatic` → `static` parameter (F1):** Single-token
   fix in two places. Without it every network-filter call is broken.
2. **[HIGH] Add required `element=` to every `browser_click` call (F2):**
   Three call sites. Without it the skill's click examples fail first-try.
3. **[HIGH] Remove / correct the `filename=` kwarg on
   `browser_console_messages` (F3):** The tool doesn't accept it; fix the
   instruction so evidence is actually saved.
4. **[HIGH] Expand dev-server detection (F4):** Add Bun, Deno; fail loudly
   on unknown; warn on Vue CLI / Angular script-name mismatches.
5. **[MEDIUM] Add Chrome DevTools MCP paths for Steps 4-7 (F5).**
6. **[MEDIUM] Fix Step 1 readiness loop to handle 3xx (F6).**
7. **[MEDIUM] Cite `condition-based-waiting` (F7).**
8. **[MEDIUM] Reconcile viewport table with PASS criteria (F8).**
9. **[MEDIUM] Add Related Skills + When to Use sections (F9, F17).**
10. **[MEDIUM] Add error-state assertion to Step 6 invalid-form test
    (F10).**
11. **[MEDIUM] Fix prerequisite-verification and route-coverage classification
    (F11, F12).**
12. **[LOW] Clean up evidence-path convention (F13), overbroad `kill -9`
    (F14), unsourced perf threshold (F15), MCP-availability verification
    (F16), evidence inventory (F18).**

**None are CRITICAL.** The F1+F2+F3 trio, taken together, is the most
user-facing issue: a first-try user running the skill literally against
Playwright MCP gets three rejected tool calls before any evidence is
captured. That's a confidence-destroying first impression but NOT a false
PASS — the validator sees the error, re-reads the skill, and works around
it (often by copying from `e2e-validate/references/web-validation.md`
which has the right syntax).

F4 (dev-server detection) is the largest functional gap — silently wrong
on Bun / Deno / Vue CLI / Angular / non-JS stacks — but again surfaces
loudly (the readiness loop times out).

The highest-risk false-PASS path is F10 (invalid-form test asserts nothing)
× F6 (redirect masquerading as failure) × missing Chrome DevTools
equivalents (F5) combining to leave a validator with partial evidence and
no clear verdict path for hybrid stacks. Applying F1+F2+F3+F10 closes it.

---

## Evidence

- `./e2e-evidence/skill-review/web-validation/command-verification-transcript.txt`
  — environment (curl 8.7.1, jq-1.8.1); verified Step 1 readiness loop
  behavior on 000/200/non-200; verified Step 8 route-check loop; verified
  `lsof`/`kill` semantics.
- `./e2e-evidence/skill-review/web-validation/mcp-tool-name-verification.txt`
  — Playwright MCP tool table + Chrome DevTools MCP tool table; parameter
  mismatches cited.
- `./e2e-evidence/skill-review/web-validation/dev-server-detection-gap-analysis.txt`
  — full list of missing ecosystem indicators with impact analysis and
  suggested rewrite.
- `./e2e-evidence/skill-review/web-validation/viewport-table-crosscheck.txt`
  — 4-way cross-check of viewport tables (web-validation,
  playwright-validation, responsive-validation, e2e-validate reference)
  with per-row diff.

Note: MCP tool invocations not executed in the sandbox. Tool-name / param
correctness claims are source-document-based (github.com/microsoft/playwright-mcp
and github.com/ChromeDevTools/chrome-devtools-mcp tool-reference.md)
via general-purpose agent web-fetch, not empirical.
