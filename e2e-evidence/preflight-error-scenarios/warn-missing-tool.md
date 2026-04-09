PREFLIGHT CHECK: blog-series/site (Error Scenario — Missing Browser Tool)
Platform: Web (Next.js)
Time: 2026-04-08 23:07
Status: WARN

---
## Scenario

**Purpose:** Verify preflight correctly detects and reports a WARN state when
a browser automation tool (Playwright) is installed but its required browser
binaries are missing for the current version. This documents the degraded-tool
path so developers know exactly what to expect when browser-based validation
journeys cannot run.

**Test target:** Playwright v1.59.1 (installed at `/Users/nick/node_modules/playwright/`)
**Missing dependency:** `chromium_headless_shell-1217` browser binary (required by v1.59.1)
**Confirmation:** `ls ~/Library/Caches/ms-playwright/chromium_headless_shell-1217` →
  `No such file or directory` (directory does not exist)
**Installed (stale) version:** `chromium_headless_shell-1208` (for Playwright ≤ 1.58.x)

---
## Results

[PASS] Node.js available
       Command: `node --version` → `v25.9.0`

[PASS] pnpm available
       Command: `which pnpm` → `/opt/homebrew/bin/pnpm`

[PASS] Project dependencies installed
       Verification: `blog-series/site/node_modules/` directory exists (646 packages)

[PASS] Build artifacts present
       Verification: `blog-series/site/.next/BUILD_ID` → `y2GKmmQwpyTxYG5q2OZsF`

[WARN] Playwright CLI not in system PATH — browser-based journeys will be degraded
       Severity: HIGH
       Command: `which playwright`
       Output: `playwright not found`
       Exit code: 1

       Secondary check: `npx playwright --version`
       Output: `Version 1.59.1`
       Package location: `/Users/nick/node_modules/playwright/package.json`
       Conclusion: Playwright package IS available via npx, but NOT as a global binary.

[WARN] Playwright browser binaries not installed for current version
       Severity: HIGH
       Browser required: `chromium_headless_shell-1217` (Playwright 1.59.1)
       Expected path: `/Users/nick/Library/Caches/ms-playwright/chromium_headless_shell-1217/`
       Check: `ls ~/Library/Caches/ms-playwright/chromium_headless_shell-1217` →
         `ls: No such file or directory`

       Launch test:
         Command: `node -e "const { chromium } = require('playwright'); chromium.launch()"`
         Output:
           LAUNCH FAILED: browserType.launch: Executable doesn't exist at
           /Users/nick/Library/Caches/ms-playwright/chromium_headless_shell-1217/
           chrome-headless-shell-mac-arm64/chrome-headless-shell
           ╔════════════════════════════════════════════════════════════╗
           ║ Looks like Playwright was just installed or updated.       ║
           ║ Please run the following command to download new browsers: ║
           ║                                                            ║
           ║     npx playwright install                                 ║
           ║                                                            ║
           ║ <3 Playwright Team                                         ║
           ╚════════════════════════════════════════════════════════════╝

       Stale cache found: `~/Library/Caches/ms-playwright/chromium_headless_shell-1208/`
         → Contains `chrome-headless-shell-mac-arm64` binary (for Playwright ≤ 1.58.x)
         → CANNOT be used: version mismatch with installed Playwright 1.59.1

       Auto-fix NOT attempted: installing browser binaries (multi-hundred MB download)
         is a major operation requiring user consent. Escalating to WARN — manual
         install required before browser-based journeys can execute.

---
## Summary

- Checks run: 6
- Passed: 4
- Auto-fixed: 0 (browser binary install requires user consent)
- Warnings: 2 (playwright not in PATH, browser binaries missing)
- Blocked: 0

## Status: WARN

⚠️ **Pipeline can proceed with reduced coverage. Browser-based journeys will be
SKIPPED. Non-browser journeys (build check, server health, API calls) will execute
normally.**

---
## Missing Tool Detail

```
WARN: Playwright browser binaries not installed for current version

Tool:     playwright v1.59.1
Check:    node -e "const { chromium } = require('playwright'); chromium.launch()"
Result:   Executable doesn't exist at:
          /Users/nick/Library/Caches/ms-playwright/chromium_headless_shell-1217/
          chrome-headless-shell-mac-arm64/chrome-headless-shell
Meaning:  Playwright package is installed but its required Chromium browser has
          not been downloaded for this version. The stale chromium_headless_shell-1208
          binary cannot be used with Playwright 1.59.1 (version mismatch).
```

---
## Fix Instructions

The Playwright browser binaries are missing. Follow these steps to resolve:

**Option A — Install all Playwright browsers (recommended):**
```bash
npx playwright install
```
This downloads Chromium, Firefox, and WebKit for the current Playwright version.
Expected output: `Downloading browsers...` then `✓ Chromium 147.0 (playwright build v1217) installed`

**Option B — Install Chromium only (faster, ~150 MB):**
```bash
npx playwright install chromium
```
Sufficient for most web validation journeys. Expected output:
`✓ Chromium 147.0 (playwright build v1217) installed`

**Option C — Install with system dependencies (if on Linux/CI):**
```bash
npx playwright install --with-deps chromium
```
Installs both the browser binary and its OS-level shared library dependencies.

**After installing**, verify the browser launches:
```bash
node -e "const { chromium } = require('playwright'); chromium.launch().then(b => { console.log('OK - browser launched'); b.close(); })"
```
Expected: `OK - browser launched`

**If Playwright itself is not installed at all** (fresh environment):
```bash
npm install -g playwright
npx playwright install chromium
```
or add to your project's package.json:
```json
{
  "devDependencies": {
    "playwright": "^1.59.1"
  }
}
```
Then run: `npm install && npx playwright install chromium`

---
## Validation Pipeline Impact

This WARN status allows the pipeline to **continue with reduced coverage**.
Browser-dependent journeys are skipped; curl and filesystem journeys proceed.

| Phase | Status | Reason |
|-------|--------|--------|
| 0 - Research | PASS | No browser required |
| 1 - Plan | PASS | No browser required |
| 2 - Preflight | **WARN** | Playwright browser binaries missing |
| 3 - Execute | PARTIAL | Browser journeys SKIPPED; curl journeys proceed |
| 4 - Analyze | PARTIAL | Analysis limited to non-browser evidence |
| 5 - Verdict | PARTIAL | Browser journeys marked WARN-SKIPPED (not FAIL) |
| 6 - Ship | CONDITIONAL | Coverage gap noted; ship decision deferred to human |

**Journeys affected for blog-series/site (Next.js):**

| Journey | Requires Browser | Status Under WARN |
|---------|-----------------|-------------------|
| J1: Build Compiles | No | ✅ Will execute normally |
| J2: Server Health | No (curl) | ✅ Will execute normally |
| J3: Homepage Renders | **Yes** | ⚠️ SKIPPED — browser unavailable |
| J4: Post Detail Page | **Yes** | ⚠️ SKIPPED — browser unavailable |
| J5: Navigation Links | **Yes** | ⚠️ SKIPPED — browser unavailable |
| J6: Console Audit | **Yes** | ⚠️ SKIPPED — browser unavailable |
| J7: Mobile Responsive | **Yes** | ⚠️ SKIPPED — browser unavailable |

**Coverage under WARN: 2/7 journeys (29%).** Human sign-off required before
proceeding past Phase 5 Verdict. The pipeline does NOT halt — it degrades
gracefully and marks skipped journeys as WARN-SKIPPED in the verdict file.

This is the correct behavior: non-browser validation (build, server health)
provides partial confidence. A full PASS verdict requires browser evidence.

---
## Evidence Provenance

This WARN scenario was tested and verified on 2026-04-08 at 23:07 local time.
All commands were run against the actual system state — Playwright 1.59.1 is
genuinely installed at `/Users/nick/node_modules/playwright/` but `chromium_headless_shell-1217`
is genuinely absent from `~/Library/Caches/ms-playwright/`. The launch failure
output above is real output from Node.js, not simulated.

Test commands executed:
1. `which playwright` → `playwright not found` (exit 1)
2. `npx playwright --version` → `Version 1.59.1`
3. `node -e "require.resolve('playwright/package.json')"` → `/Users/nick/node_modules/playwright/package.json`
4. `ls ~/Library/Caches/ms-playwright/chromium_headless_shell-1217` → `No such file or directory`
5. `ls ~/Library/Caches/ms-playwright/chromium_headless_shell-1208` → `INSTALLATION_COMPLETE` (stale, present)
6. `node -e "const { chromium } = require('playwright'); chromium.launch().catch(e => console.error('LAUNCH FAILED:', e.message))"` → LAUNCH FAILED with executable-not-found error
7. `npx playwright install --dry-run chromium` → confirms download URL for chromium_headless_shell-1217
