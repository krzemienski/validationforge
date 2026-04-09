---
name: web-validation
description: >
  Web platform validation through browser automation (Playwright MCP or Chrome DevTools MCP).
  Captures screenshots, console logs, network responses, and DOM snapshots as evidence.
context_priority: standard
---

# Web Validation

## Prerequisites

| Requirement | How to verify |
|-------------|---------------|
| Dev server running | `curl -s http://localhost:PORT -o /dev/null -w "%{http_code}"` |
| Browser automation available | Playwright MCP or Chrome DevTools MCP connected |
| Evidence directory exists | `mkdir -p e2e-evidence` |

## Step 1: Start Dev Server

```bash
# Detect and start the appropriate dev server
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

Wait for server ready:
```bash
for i in $(seq 1 30); do
  if curl -s http://localhost:3000 -o /dev/null -w "%{http_code}" 2>/dev/null | grep -q "200"; then
    echo "Server ready"
    break
  fi
  sleep 1
done
```

## Step 2: Health Check

```bash
curl -s http://localhost:PORT | head -20 | tee e2e-evidence/web-health-check.txt
curl -s -o /dev/null -w "Status: %{http_code}\nTime: %{time_total}s\n" http://localhost:PORT \
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

Test with valid data:
```
browser_fill_form  fields=[
  {"name": "Email", "type": "textbox", "ref": "EMAIL_REF", "value": "user@example.com"},
  {"name": "Password", "type": "textbox", "ref": "PASS_REF", "value": "SecurePass123!"}
]
browser_click  ref="SUBMIT_REF"
browser_take_screenshot  filename="e2e-evidence/web-form-valid-submit.png"
```

Test with invalid data:
```
browser_fill_form  fields=[
  {"name": "Email", "type": "textbox", "ref": "EMAIL_REF", "value": "not-an-email"},
  {"name": "Password", "type": "textbox", "ref": "PASS_REF", "value": ""}
]
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

Navigate to every known route and verify no 404s:
```bash
ROUTES=("/" "/about" "/dashboard" "/settings" "/login")
for route in "${ROUTES[@]}"; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:PORT$route")
  echo "$route -> $STATUS" | tee -a e2e-evidence/web-route-check.txt
done
```

Any non-200 response (except expected redirects) is a finding.

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
