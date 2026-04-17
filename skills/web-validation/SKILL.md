---
name: web-validation
description: "Use whenever validating a web app (React, Vue, Next.js, Django, Rails, static site) end-to-end through a real browser — not just 'it builds' or 'dev server starts'. Covers health check, screenshot-based navigation, console error detection, network request inspection, form submission, responsive layout at mobile/tablet/desktop widths, and route coverage. Reach for it on phrases like 'validate the site', 'take screenshots', 'check the console', 'responsive testing', 'does the page load', or when a frontend change needs proof that real users won't see errors."
triggers:
  - "web validation"
  - "browser automation"
  - "playwright validation"
  - "web testing"
  - "validate web app"
  - "screenshot test"
  - "check console errors"
  - "responsive testing"
context_priority: standard
---

# Web Validation

## Choosing your browser tool

You have two options; they do similar things via different MCPs.

| Tool | Best when | Strength |
|------|-----------|----------|
| **Playwright MCP** | You need cross-browser testing, robust selector semantics, or headless CI runs | Mature, battle-tested, runs against Chromium/Firefox/WebKit |
| **Chrome DevTools MCP** | You're debugging real Chrome behavior, need live DevTools features (network timing, performance), or want to inspect what a real user sees | Tied to actual Chrome — no cross-browser |

If only one is connected, use that one. Examples below show both.

## Prerequisites

| Requirement | How to verify |
|-------------|---------------|
| Dev server running on a known port | `curl -s http://localhost:$PORT -o /dev/null -w "%{http_code}"` |
| Browser automation available | Playwright MCP or Chrome DevTools MCP connected |
| Evidence directory exists | `mkdir -p e2e-evidence` |

## Step 1: Start Dev Server

**Automated port+health**: `bash scripts/web-validation-harness.sh --project-dir=. --dev-log=dev.log --health-path=/ --evidence-dir=e2e-evidence/web` reads the dev-server log, extracts the listening port, and hits the health endpoint — replacing the 3-step sequence below with one command. Add `--tool=playwright|chrome-devtools` to pin the recommended follow-up MCP; omit it and the harness picks one.

Detect the framework and start its dev server. Capture the port the server actually binds to — different frameworks default to different ports (Next.js 3000, Django 8000, Rails 3000, Flask 5000, Vite 5173). Don't hardcode.

```bash
# Pick one start command based on lockfile / project markers
if [ -f pnpm-lock.yaml ]; then
  pnpm dev 2>&1 | tee /tmp/dev-server.log &
elif [ -f yarn.lock ]; then
  yarn dev 2>&1 | tee /tmp/dev-server.log &
elif [ -f package-lock.json ] || [ -f package.json ]; then
  npm run dev 2>&1 | tee /tmp/dev-server.log &
elif [ -f manage.py ]; then
  python manage.py runserver 2>&1 | tee /tmp/dev-server.log &
elif [ -f Gemfile ]; then
  bundle exec rails server 2>&1 | tee /tmp/dev-server.log &
fi
DEV_PID=$!

# Discover the port the server actually printed. Works for most frameworks.
sleep 2
PORT=$(grep -Eo 'localhost:[0-9]+|127\.0\.0\.1:[0-9]+|:[0-9]{4,}' /tmp/dev-server.log | head -1 | grep -Eo '[0-9]+$')
echo "Detected PORT=$PORT"
```

If the detection can't find a port (e.g., server logs to a pipe that didn't flush yet), read the framework's docs — or just ask the user — and set `PORT=...` manually before proceeding.

**If the `dev` script name is different** (some repos use `start`, `dev:local`, `serve`, `develop`), open `package.json` and check the `scripts` section first.

Wait for server ready:
```bash
for i in $(seq 1 30); do
  if curl -s "http://localhost:$PORT" -o /dev/null -w "%{http_code}" 2>/dev/null | grep -q "200"; then
    echo "Server ready on port $PORT"
    break
  fi
  sleep 1
done
```

## Step 2: Health Check

```bash
curl -s "http://localhost:$PORT" | head -20 | tee e2e-evidence/web-health-check.txt
curl -s -o /dev/null -w "Status: %{http_code}\nTime: %{time_total}s\n" "http://localhost:$PORT" \
  | tee e2e-evidence/web-health-status.txt
```

## Step 3: Page Navigation and Screenshots

Using Playwright MCP:
```
browser_navigate  url="http://localhost:PORT"
browser_snapshot                                    # Get accessibility tree
browser_take_screenshot  filename="e2e-evidence/web-01-homepage.png"

browser_click  ref="LINK_REF"                       # Navigate via link
browser_take_screenshot  filename="e2e-evidence/web-02-next-page.png"
```

Using Chrome DevTools MCP:
```
navigate_page  url="http://localhost:PORT"
take_snapshot                                       # Get page structure
take_screenshot  filePath="e2e-evidence/web-01-homepage.png"

click  uid="ELEMENT_UID"
take_screenshot  filePath="e2e-evidence/web-02-next-page.png"
```

## Step 4: Console Error Check

```
browser_console_messages  level="error"
```

Save results. If errors found:
```
browser_console_messages  level="error"  filename="e2e-evidence/web-console-errors.txt"
```

Any JavaScript error in the console is a FAIL unless it is a known, documented, non-blocking issue.

## Step 5: Network Request Validation

```
browser_network_requests  includeStatic=false
```

Check for failed requests (4xx/5xx). Save evidence:
```
browser_network_requests  includeStatic=false  filename="e2e-evidence/web-network-requests.txt"
```

## Step 6: Form Validation

**Before you pick test values:** inspect the form to know what counts as valid/invalid. Options, in order of preference:

1. Read the HTML — `<input type=...>`, `required`, `minlength`, `pattern`, `min`/`max` attributes tell you the client-side rules.
2. Trigger a bad submit first and read the error messages — they often spell out the rule.
3. Check the API endpoint the form posts to (OpenAPI schema, Django serializer, Zod schema) for server-side rules.

Use values that actually exercise the rules. `SecurePass123!` passes most rules, but if this form requires 16+ chars or a specific character class, your "valid" submit will fail and you'll misattribute the failure.

Test with valid data:
```
browser_snapshot                                    # Get refs for form fields
browser_fill_form  fields=[{ref: "EMAIL_REF", value: "user@example.com"}, {ref: "PASS_REF", value: "SecurePass123!"}]
browser_click  ref="SUBMIT_REF"
browser_take_screenshot  filename="e2e-evidence/web-form-valid-submit.png"
```

Test with invalid data:
```
browser_snapshot                                    # Get refs for form fields
browser_fill_form  fields=[{ref: "EMAIL_REF", value: "not-an-email"}, {ref: "PASS_REF", value: ""}]
browser_click  ref="SUBMIT_REF"
browser_take_screenshot  filename="e2e-evidence/web-form-invalid-submit.png"
```

## Step 7: Responsive Testing

Test at standard viewport sizes:

| Device | Width | Height | Screenshot |
|--------|-------|--------|------------|
| Desktop | 1920 | 1080 | `web-responsive-desktop.png` |
| Laptop | 1280 | 720 | `web-responsive-laptop.png` |
| Tablet | 768 | 1024 | `web-responsive-tablet.png` |
| Mobile | 375 | 667 | `web-responsive-mobile.png` |

```
browser_resize  width=375  height=667
browser_take_screenshot  filename="e2e-evidence/web-responsive-mobile.png"

browser_resize  width=768  height=1024
browser_take_screenshot  filename="e2e-evidence/web-responsive-tablet.png"

browser_resize  width=1920  height=1080
browser_take_screenshot  filename="e2e-evidence/web-responsive-desktop.png"
```

## Step 8: Route Coverage

Navigate to every known route and verify no 404s. Don't maintain the route list by hand — pull it from the source of truth:

- **React Router / Next.js app router**: extract from `pages/`, `app/`, or `routes.tsx`
- **Django**: `python manage.py show_urls` (needs `django-extensions`) or parse `urls.py`
- **Rails**: `bin/rails routes | awk '{print $3}'`
- **Sitemap**: check `sitemap.xml` if one exists
- **OpenAPI / Swagger**: parse the spec for documented paths

```bash
# Example: after you've populated ROUTES from one of the sources above
ROUTES=("/" "/about" "/dashboard" "/settings" "/login")
for route in "${ROUTES[@]}"; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT$route")
  echo "$route -> $STATUS" | tee -a e2e-evidence/web-route-check.txt
done
```

Any non-200 response (except expected redirects — document which ones are expected) is a finding.

## Evidence Quality

**GOOD:** "Homepage screenshot shows navigation bar with 5 links, hero section with headline 'Welcome to AppName', and a grid of 6 feature cards below the fold."

**BAD:** "Homepage loads correctly."

## Common Failures

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Port already in use | Previous server still running | `lsof -ti:PORT \| xargs kill -9` |
| CORS errors in console | API on different origin, missing headers | Add CORS headers to API server or use proxy |
| 404 on page refresh (SPA) | Server not configured for client-side routing | Configure server to serve index.html for all routes |
| Hydration mismatch | Server/client HTML mismatch (SSR frameworks) | Check for browser-only APIs used during SSR |
| Blank page, no errors | JavaScript bundle failed to load | Check network tab for failed script requests |
| Styles missing | CSS not loading or Tailwind not compiling | Check for CSS 404s in network, verify build process |

## PASS Criteria Template

- [ ] All routes render without console errors
- [ ] No failed network requests (4xx/5xx) for API calls
- [ ] Forms submit with valid data and produce expected responses
- [ ] Forms reject invalid data with visible error messages
- [ ] Navigation between all pages works without 404s
- [ ] Responsive layout correct at mobile (375px), tablet (768px), desktop (1920px)
- [ ] No JavaScript errors in browser console
- [ ] Page load time under 3 seconds
