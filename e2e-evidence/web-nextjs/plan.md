# Validation Plan — Next.js Web Platform

**Platform:** Web (Next.js 15, App Router, TypeScript, Tailwind v4)
**Target:** blog-series/site
**Total Journeys:** 7
**Estimated Duration:** 25–35 minutes
**Generated:** 2026-04-08
**Inputs from:** e2e-evidence/web-nextjs/analysis.md (Phase 0 Research)

---

## Prerequisites

- [ ] Node.js available (`node --version`)
- [ ] pnpm available (`pnpm --version`)
- [ ] Project builds successfully (`pnpm build` exit code 0)
- [ ] Dev/production server starts and responds (`curl http://localhost:PORT` → HTTP 200)
- [ ] Playwright MCP server active in Claude Code session
- [ ] Evidence directory exists (`e2e-evidence/web-nextjs/`)
- [ ] No test fixtures — validation uses real build output and live server

---

## Journey Validation Sequence

---

### J1: Build Compilation [P0]

**Entry Point:** Project root of blog-series/site
**Skill:** build-quality-gates

**Steps:**
1. Run `pnpm build` in blog-series/site directory
2. Wait for build to complete
3. Capture final build output lines

**PASS Criteria:**
- [ ] `pnpm build` exits with code 0 (not non-zero)
- [ ] Build output contains line matching `"Generating static pages (N/N)"` where N ≥ 18
- [ ] No `Error:` or `Failed to compile` lines in build output
- [ ] `.next/` directory exists after build completes

**Evidence:** Build log captured to `e2e-evidence/web-nextjs/step-01-build-output.txt`

---

### J2: Server Health Check [P0]

**Entry Point:** Running production server (`npx next start -p <PORT>`)
**Skill:** preflight

**Steps:**
1. Start server on a free port (e.g., 3847)
2. Run `curl -s -o /dev/null -w "%{http_code}" http://localhost:3847/`
3. Capture HTTP status code and response headers
4. Run `curl -s -o /dev/null -w "%{http_code}" http://localhost:3847/posts/post-01-intro-to-agentic-development`

**PASS Criteria:**
- [ ] `GET /` returns HTTP 200 (not 404, 500, or connection refused)
- [ ] `GET /posts/post-01-intro-to-agentic-development` returns HTTP 200
- [ ] Response `Content-Type` header contains `text/html`
- [ ] Response body is non-empty (Content-Length > 0 or chunked encoding)

**Evidence:** curl responses captured to `e2e-evidence/web-nextjs/step-02-health-check.txt`

---

### J3: Homepage Render — All Posts Visible [P0]

**Entry Point:** `http://localhost:3847/`
**Skill:** playwright-validation

**Steps:**
1. Navigate Playwright to `http://localhost:3847/`
2. Wait for page to fully load
3. Capture full-page screenshot
4. Capture accessibility snapshot (heading list, link list)
5. Read console errors

**PASS Criteria:**
- [ ] Screenshot shows hero section with main site title visible
- [ ] Screenshot shows at least 18 post cards rendered (not blank, not error page)
- [ ] Screenshot shows aggregate stats section (post count, reading time)
- [ ] Accessibility snapshot contains at least 18 article links in the post listing
- [ ] No `Error` or `TypeError` entries in browser console

**Evidence:** Screenshot saved to `e2e-evidence/web-nextjs/step-03-homepage-full.png`

---

### J4: Individual Post Detail Rendering [P0]

**Entry Point:** `http://localhost:3847/posts/post-03-functional-validation`
**Skill:** playwright-validation

**Steps:**
1. Navigate Playwright to `http://localhost:3847/posts/post-03-functional-validation`
2. Wait for full page load
3. Capture viewport screenshot
4. Capture full-page screenshot
5. Inspect DOM for key elements: title, article body, code blocks, tags, navigation links

**PASS Criteria:**
- [ ] Page title in browser tab matches expected article title
- [ ] Screenshot shows article heading (H1) rendered and visible
- [ ] Screenshot shows article body text (paragraphs) — not blank
- [ ] At least one code block is rendered with syntax formatting (not raw text)
- [ ] "Previous" and/or "Next" navigation links are visible in screenshot
- [ ] Tags section is visible (at least 1 tag rendered)
- [ ] No `TypeError` or `ReferenceError` in browser console

**Evidence:**
- Viewport screenshot: `e2e-evidence/web-nextjs/step-04-post-detail-viewport.png`
- Full-page screenshot: `e2e-evidence/web-nextjs/step-04-post-detail-full.png`

---

### J5: Post-to-Post Navigation [P1]

**Entry Point:** `http://localhost:3847/posts/post-03-functional-validation` (already loaded from J4)
**Skill:** playwright-validation

**Steps:**
1. From Post 03 page, locate the "Next" navigation link
2. Click the "Next" link
3. Wait for navigation to complete
4. Verify URL changed to the expected next post
5. Capture screenshot of newly loaded page

**PASS Criteria:**
- [ ] Clicking "Next" changes URL to `/posts/post-04-ios-streaming-bridge` (or equivalent next post)
- [ ] New page loads with HTTP 200 (no 404 or 500 error page)
- [ ] Screenshot of new page shows a different article title than Post 03
- [ ] Screenshot shows "PART 4 OF 18" badge (or equivalent part indicator)
- [ ] Navigation was client-side (no full page reload observable — Next.js `<Link>` behavior)
- [ ] No console errors after navigation

**Evidence:** Screenshot saved to `e2e-evidence/web-nextjs/step-05-post-navigation.png`

---

### J6: Console Error Audit [P1]

**Entry Point:** Full session (accumulates across J3–J5)
**Skill:** playwright-validation

**Steps:**
1. Review console logs collected during J3, J4, J5
2. Classify each console entry: Error / Warning / Info / External (Vercel analytics)
3. Distinguish application errors from expected external-script failures

**PASS Criteria:**
- [ ] Zero `TypeError` entries in console (application code must not throw)
- [ ] Zero `ReferenceError` entries in console
- [ ] Zero `SyntaxError` entries in console
- [ ] Any Vercel analytics/speed-insights script failures are classified as EXPECTED (external, localhost-only)
- [ ] No React hydration warning: "Warning: Text content did not match"
- [ ] No uncaught promise rejections from application code

**Evidence:** Console log summary captured to `e2e-evidence/web-nextjs/step-06-console-audit.txt`

---

### J7: Mobile Responsive Layout [P2]

**Entry Point:** `http://localhost:3847/` at 375×812 viewport (iPhone SE dimensions)
**Skill:** playwright-validation

**Steps:**
1. Set Playwright viewport to 375×812
2. Navigate to `http://localhost:3847/`
3. Capture mobile viewport screenshot
4. Navigate to a post detail page
5. Capture mobile post screenshot

**PASS Criteria:**
- [ ] Mobile screenshot shows site content (not a blank page or broken layout)
- [ ] Navigation is accessible at 375px width (hamburger menu or visible nav links)
- [ ] Post cards are readable at mobile width (text not overflowing viewport)
- [ ] Post detail page is readable at 375px width (no horizontal scroll on article content)
- [ ] No content overlap or z-index stacking issues visible in screenshot

**Evidence:**
- Mobile homepage: `e2e-evidence/web-nextjs/step-07-mobile-homepage.png`
- Mobile post detail: `e2e-evidence/web-nextjs/step-07-mobile-post.png`

---

## Execution Order Summary

| Order | Journey | Priority | Dependency | Estimated Time |
|-------|---------|----------|------------|----------------|
| 1 | J1: Build Compilation | P0 | None | 3–5 min |
| 2 | J2: Server Health Check | P0 | J1 complete | 1 min |
| 3 | J3: Homepage Render | P0 | J2 PASS | 3 min |
| 4 | J4: Post Detail Rendering | P0 | J2 PASS | 3 min |
| 5 | J5: Post-to-Post Navigation | P1 | J4 complete | 2 min |
| 6 | J6: Console Error Audit | P1 | J3–J5 complete | 2 min |
| 7 | J7: Mobile Responsive | P2 | J2 PASS | 3 min |

**Stop rule:** If J1 (Build) or J2 (Server Health) FAIL, stop pipeline immediately. Do not proceed to browser journeys. Report specific error with actionable fix instructions.

---

## Evidence Directory Structure

```
e2e-evidence/web-nextjs/
  analysis.md                      ← Phase 0 Research (this directory)
  plan.md                          ← This file (Phase 1 Plan)
  preflight-report.md              ← Phase 2 Preflight results
  step-01-build-output.txt         ← J1: pnpm build log
  step-02-health-check.txt         ← J2: curl responses
  step-03-homepage-full.png        ← J3: Homepage screenshot
  step-04-post-detail-viewport.png ← J4: Post viewport screenshot
  step-04-post-detail-full.png     ← J4: Post full-page screenshot
  step-05-post-navigation.png      ← J5: Navigation result screenshot
  step-06-console-audit.txt        ← J6: Console error log
  step-07-mobile-homepage.png      ← J7: Mobile homepage screenshot
  step-07-mobile-post.png          ← J7: Mobile post screenshot
  evidence-inventory.txt           ← Index of all evidence files
  VERDICT.md                       ← Phase 5 Verdict + Phase 6 Ship
```

---

## Phase Gate: Plan Approval

**Plan Status:** READY FOR EXECUTION

All 7 journeys have:
- Specific, binary PASS criteria (no "partially works")
- Observable evidence types (screenshots, curl output, console logs)
- Clear dependencies and execution order
- Stop rules for P0 failures

**Next Phase:** Preflight (Phase 2) → `e2e-evidence/web-nextjs/preflight-report.md`
