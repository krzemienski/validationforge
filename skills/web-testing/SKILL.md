---
name: web-testing
description: "5-layer web validation: integration (APIs), E2E (journeys), accessibility (WCAG), performance (Core Web Vitals), security (OWASP). Decide which layers a feature needs. Real systems only—no mocks."
triggers:
  - "web testing strategy"
  - "web validation strategy"
  - "how to validate web app"
  - "web quality strategy"
context_priority: reference
---

# Web Testing Strategy

Comprehensive web validation strategy covering integration, end-to-end, accessibility, performance, and security validation. All validation is performed against real running systems — no mocks.

## When to Use

- When planning comprehensive validation for a web application
- When determining what types of validation a web feature needs
- When building a validation plan for `create-validation-plan`
- As a reference for which validation techniques apply to your feature

## Validation Layers

```
Layer 5: Security Validation      ─── OWASP checks, auth flows, input sanitization
Layer 4: Performance Validation   ─── Core Web Vitals, load times, network waterfall
Layer 3: Accessibility Validation ─── WCAG 2.1 AA, screen reader, keyboard navigation
Layer 2: E2E Flow Validation      ─── User journeys through real browser (Playwright)
Layer 1: Integration Validation   ─── API responses, data flow, component interaction
```

Not every feature needs all 5 layers. Use the decision matrix below.

## Decision Matrix

| Feature Type | Layer 1 | Layer 2 | Layer 3 | Layer 4 | Layer 5 |
|-------------|---------|---------|---------|---------|---------|
| New page/route | YES | YES | YES | YES | - |
| Form with user input | YES | YES | YES | - | YES |
| Authentication flow | YES | YES | - | - | YES |
| Data display (list/table) | YES | YES | YES | YES | - |
| API integration | YES | YES | - | - | YES |
| Style/layout change | - | YES | YES | - | - |
| Performance optimization | - | - | - | YES | - |

## Layer 1: Integration Validation

Verify that components communicate correctly with real backends.

### API Response Validation

```bash
mkdir -p e2e-evidence/web-integration

# Test each API endpoint the feature uses
curl -s "$API_URL/endpoint" | tee e2e-evidence/web-integration/step-01-api-response.json | jq .

# Verify response structure
# - Status code is expected (200, 201, etc.)
# - Response body has expected fields
# - Data types are correct
# - Pagination works if applicable
```

### Data Flow Verification

Using browser network tab:
```
browser_navigate → feature page
browser_network_requests → includeStatic=false
```

Check:
- Correct API endpoints called
- Request payloads match expected format
- Response data renders correctly in UI

## Layer 2: E2E Flow Validation

Use `playwright-validation` skill for full browser-based flows. Key journeys:

### Critical User Journeys

Define and validate these journeys:

1. **First-time user flow** — landing → signup → onboarding → first action
2. **Returning user flow** — login → dashboard → primary task
3. **Error recovery flow** — trigger error → see feedback → recover
4. **Data lifecycle** — create → read → update → delete

Each journey produces evidence in `e2e-evidence/`.

## Layer 3: Accessibility Validation

### Automated Checks

Using browser tools:
```
browser_snapshot → check heading hierarchy, ARIA labels, form labels
browser_evaluate → document.querySelectorAll('img:not([alt])').length  // images without alt
browser_evaluate → document.querySelectorAll('a:not([href])').length   // links without href
```

### Keyboard Navigation

```
browser_press_key → "Tab"     // Navigate forward
browser_press_key → "Enter"   // Activate element
browser_press_key → "Escape"  // Close modals/dropdowns
browser_snapshot → check which element has focus
```

Verify:
- [ ] All interactive elements reachable via Tab
- [ ] Focus indicator visible on focused element
- [ ] Enter/Space activates buttons and links
- [ ] Escape closes modals and dropdowns
- [ ] Tab order follows visual layout

### Color Contrast

Check critical text elements:
- Body text on background
- Button text on button background
- Error message text
- Link text on background

Minimum ratios (WCAG 2.1 AA):
- Normal text: 4.5:1
- Large text (18px+ or 14px bold): 3:1

## Layer 4: Performance Validation

### Core Web Vitals

Using Chrome DevTools MCP:
```
performance_start_trace → reload=true, autoStop=true
```

Or using Lighthouse:
```
lighthouse_audit → device="desktop", mode="navigation"
lighthouse_audit → device="mobile", mode="navigation"
```

Key metrics:
| Metric | Good | Needs Work | Poor |
|--------|------|------------|------|
| LCP (Largest Contentful Paint) | <2.5s | 2.5-4.0s | >4.0s |
| INP (Interaction to Next Paint) | <200ms | 200-500ms | >500ms |
| CLS (Cumulative Layout Shift) | <0.1 | 0.1-0.25 | >0.25 |

### Network Waterfall

```
browser_network_requests → includeStatic=true
```

Check for:
- Total page weight
- Number of requests
- Render-blocking resources
- Unoptimized images

## Layer 5: Security Validation

### Input Sanitization

Test form fields with:
```
<script>alert('xss')</script>
' OR '1'='1
javascript:alert(1)
../../../etc/passwd
```

Verify: input is sanitized or rejected, never executed.

### Authentication

- [ ] Protected routes redirect to login when unauthenticated
- [ ] Session expires after inactivity
- [ ] Logout clears session/tokens
- [ ] CSRF tokens present on state-changing forms

### Headers

```bash
curl -I "$APP_URL" | tee e2e-evidence/web-security/headers.txt
```

Check for:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY` or `SAMEORIGIN`
- `Strict-Transport-Security` (HTTPS)
- `Content-Security-Policy`

## Evidence Organization

```
e2e-evidence/
  web-integration/     # Layer 1
  web-playwright/      # Layer 2 (via playwright-validation skill)
  web-accessibility/   # Layer 3
  web-performance/     # Layer 4
  web-security/        # Layer 5
```

## Integration with ValidationForge

- Each layer produces evidence in its own subdirectory under `e2e-evidence/`
- The `verdict-writer` agent reviews evidence across all layers
- Use this skill alongside `create-validation-plan` to build comprehensive validation plans
- Layer 2 delegates to `playwright-validation` skill for browser automation
- Layer 3 complements `visual-inspection` skill
