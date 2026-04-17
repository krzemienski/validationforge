# Web Validation Reference

Platform-specific commands, tools, and patterns for validating web applications through browsers.

## Build and Start

```bash
# Detect package manager
if [ -f pnpm-lock.yaml ]; then PM="pnpm"
elif [ -f yarn.lock ]; then PM="yarn"
elif [ -f bun.lockb ]; then PM="bun"
else PM="npm"; fi

# Install dependencies
$PM install

# Build for production
$PM run build

# Start dev server (background)
$PM run dev &
DEV_PID=$!

# Wait for server to be ready
for i in $(seq 1 30); do
  curl -sf http://localhost:3000 > /dev/null 2>&1 && break
  sleep 1
done
```

## Browser Tools

Two MCP browser options are available. Use whichever is configured:

### Playwright MCP

```
browser_navigate url="http://localhost:3000"
browser_snapshot                              # Accessibility tree (preferred over screenshot)
browser_take_screenshot type="png"            # Visual capture
browser_click ref="button-submit"             # Click element by ref
browser_type ref="input-email" text="user@example.com"
browser_console_messages level="error"        # Check for JS errors
browser_network_requests static=false  # Check API calls
browser_snapshot                              # Get refs for form fields
browser_fill  ref="FIELD_REF"  value="value" # Fill each field individually
```

### Chrome DevTools MCP

```
navigate_page type="url" url="http://localhost:3000"
take_snapshot                                 # Accessibility tree
take_screenshot                               # Visual capture
click uid="e5"                                # Click by snapshot uid
fill uid="e3" value="user@example.com"        # Fill input
list_console_messages                         # JS console
list_network_requests                         # Network activity
```

## Evidence Capture

### Screenshots

```
# Full page (Playwright)
browser_take_screenshot type="png" fullPage=true filename="e2e-evidence/j1-homepage.png"

# Element only (Playwright)
browser_take_screenshot ref="main-content" element="Main content area" type="png"

# Full page (Chrome DevTools)
take_screenshot fullPage=true filePath="e2e-evidence/j1-homepage.png"

# Element only (Chrome DevTools)
take_screenshot uid="e10" filePath="e2e-evidence/j1-header.png"
```

### Console Errors

```
# Playwright — check for errors
browser_console_messages level="error"

# Chrome DevTools — check for errors
list_console_messages types=["error", "warn"]

# Expected result for PASS: zero errors
# If errors exist, read each one and assess impact
```

### Network Requests

```
# Playwright — check API calls
browser_network_requests static=false

# Chrome DevTools — check API calls
list_network_requests resourceTypes=["fetch", "xhr"]

# For detailed request/response:
get_network_request reqid=5
```

## Responsive Testing

Test at these breakpoints:

| Device | Viewport | How to Set |
|--------|----------|-----------|
| Desktop | 1920x1080 | `browser_resize width=1920 height=1080` or `resize_page width=1920 height=1080` |
| Laptop | 1280x720 | `browser_resize width=1280 height=720` |
| Tablet | 768x1024 | `browser_resize width=768 height=1024` |
| Mobile | 375x667 | `browser_resize width=375 height=667` |

For each breakpoint:
1. Resize viewport
2. Take screenshot
3. Verify layout adapts (no horizontal scroll, readable text, accessible navigation)

## Form Validation

```
# Fill form fields (Playwright)
browser_snapshot                                                         # Get accessibility tree refs
browser_fill  ref="input-email"       value="user@test.com"
browser_fill  ref="input-password"    value="SecurePass123"
browser_fill  ref="checkbox-remember" value="true"

# Submit
browser_click ref="button-submit" element="Submit button"

# Verify result
browser_snapshot  # Check for success message or redirect
```

Test form error states:
- Empty required fields → error messages appear
- Invalid email format → validation message
- Short password → strength indicator
- Successful submit → redirect or success state

## Navigation Testing

For each route in the application:

1. Navigate directly via URL
2. Take snapshot (accessibility tree)
3. Verify page content matches expectations
4. Check for broken links (404 responses in network tab)
5. Verify back/forward browser navigation works

```
# Navigate and verify
browser_navigate url="http://localhost:3000/dashboard"
browser_snapshot
# Read snapshot — verify expected elements are present

browser_navigate url="http://localhost:3000/settings"
browser_snapshot
# Read snapshot — verify settings form appears
```

## Evidence Quality Examples

**GOOD screenshot review:**
> "Screenshot j2-dashboard.png shows: header with 'Welcome, Nick' greeting,
> sidebar with 5 navigation items (Dashboard highlighted), main area with
> 3 metric cards (Total: 1,247, Active: 89, Rate: 94.2%), bar chart with
> 12 monthly columns, table below with 10 rows of session data"

**BAD screenshot review:**
> "Dashboard page loaded successfully"

**GOOD console check:**
> "Console messages: 2 info-level logs (`[Router] Navigated to /dashboard`,
> `[API] Fetched 41 sessions in 234ms`), zero warnings, zero errors"

**BAD console check:**
> "No console errors"

**GOOD network check:**
> "Network: GET /api/sessions returned 200 (234ms, 41 items in body),
> GET /api/metrics returned 200 (89ms, 3 metric objects),
> no failed requests (zero 4xx/5xx)"

**BAD network check:**
> "All API calls succeeded"

## Common Web Validation Journeys

| Journey | Entry | Key Evidence |
|---------|-------|-------------|
| Page Load | Navigate to root URL | Screenshot, load time, zero console errors |
| Authentication | Login form | Post-login screenshot, auth cookie set |
| Navigation | Click through all routes | Screenshot per route, no 404s |
| Data Display | Page with dynamic content | Screenshot showing real data from API |
| Form Submission | Fill and submit form | Success state, network request with response |
| Responsive | Resize to mobile viewport | Screenshot showing adapted layout |
| Error Handling | Navigate to invalid route | 404 page screenshot, graceful error |
