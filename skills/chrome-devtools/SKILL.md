---
name: chrome-devtools
description: "Deep browser inspection via Chrome DevTools MCP: performance profiling (Core Web Vitals), Lighthouse audits, network inspection, console monitoring, memory snapshots. Use for debugging, perf, a11y."
triggers:
  - "chrome devtools"
  - "devtools inspection"
  - "browser devtools"
  - "inspect element"
  - "network inspector"
context_priority: reference
---

# Chrome DevTools

Deep browser inspection using the Chrome DevTools MCP server. Complements Playwright MCP with DevTools-specific capabilities: performance traces, network inspection, console monitoring, Lighthouse audits, and element inspection.

## When to Use

- When you need performance profiling (Core Web Vitals, traces)
- When debugging network requests in detail (headers, payloads, timing)
- When running Lighthouse audits for accessibility/SEO/best practices
- When you need to inspect specific DOM elements or computed styles
- When Playwright MCP doesn't provide enough debugging depth

## Available Tools

### Page Management

```
list_pages            → See all open pages
select_page           → Switch active page
new_page              → Open URL in new tab
navigate_page         → Navigate, back, forward, reload
close_page            → Close a tab
resize_page           → Change viewport dimensions
```

### Snapshots & Screenshots

```
take_snapshot         → Accessibility tree (text-based, preferred)
take_screenshot       → Visual screenshot (PNG/JPEG/WebP)
```

**Rule:** Always prefer `take_snapshot` over `take_screenshot` for element identification. Use screenshots for visual evidence.

### Element Interaction

```
click                 → Click element by uid from snapshot
hover                 → Hover over element
fill                  → Type into input/select option
fill_form             → Fill multiple form elements
press_key             → Keyboard input
type_text             → Type into focused input
drag                  → Drag and drop
upload_file           → File upload
```

### Network Inspection

```
list_network_requests → All requests since last navigation
get_network_request   → Detailed request/response for specific request
```

### Console Monitoring

```
list_console_messages → All console output
get_console_message   → Detailed message by ID
```

### Performance

```
performance_start_trace    → Start recording performance trace
performance_stop_trace     → Stop and get results
performance_analyze_insight → Deep-dive into specific insight
lighthouse_audit           → Accessibility, SEO, best practices audit
```

### Memory

```
take_memory_snapshot  → Heap snapshot for memory leak debugging
```

### Emulation

```
emulate → Dark/light mode, viewport, CPU throttling, network throttling, geolocation
```

## Evidence Capture Patterns

### Pattern 1: Page Load Performance

```bash
mkdir -p e2e-evidence/devtools-perf
```

```
# Navigate to page first
navigate_page → url="http://localhost:3000"

# Start trace (auto-reloads and auto-stops)
performance_start_trace → reload=true, autoStop=true,
  filePath="e2e-evidence/devtools-perf/step-01-trace.json.gz"

# Analyze insights from trace
performance_analyze_insight → insightSetId="...", insightName="LCPBreakdown"
```

### Pattern 2: Network Debugging

```
# Navigate to feature page
navigate_page → url="http://localhost:3000/feature"

# List all API requests
list_network_requests → resourceTypes=["fetch", "xhr"]

# Inspect specific request
get_network_request → reqid=N,
  requestFilePath="e2e-evidence/devtools-network/step-01-request.txt",
  responseFilePath="e2e-evidence/devtools-network/step-01-response.json"
```

### Pattern 3: Accessibility Audit

```
# Navigate to page
navigate_page → url="http://localhost:3000"

# Run Lighthouse
lighthouse_audit → device="desktop", mode="navigation",
  outputDirPath="e2e-evidence/devtools-a11y"

# Also run mobile
lighthouse_audit → device="mobile", mode="navigation",
  outputDirPath="e2e-evidence/devtools-a11y"
```

### Pattern 4: Console Error Collection

```
# Navigate and interact with feature
navigate_page → url="http://localhost:3000/feature"

# Collect errors
list_console_messages → types=["error", "warn"]

# Save detailed error
get_console_message → msgid=N
```

### Pattern 5: Responsive Testing via Emulation

```
# Mobile emulation
emulate → viewport="375x812x3,mobile,touch"
take_screenshot → filePath="e2e-evidence/devtools-responsive/mobile.png"

# Tablet
emulate → viewport="768x1024x2,mobile,touch"
take_screenshot → filePath="e2e-evidence/devtools-responsive/tablet.png"

# Desktop (reset)
emulate → viewport="1440x900x1"
take_screenshot → filePath="e2e-evidence/devtools-responsive/desktop.png"

# Dark mode
emulate → colorScheme="dark"
take_screenshot → filePath="e2e-evidence/devtools-responsive/dark-mode.png"
```

### Pattern 6: Memory Leak Detection

```
# Take initial heap snapshot
take_memory_snapshot → filePath="e2e-evidence/devtools-memory/heap-before.heapsnapshot"

# Exercise the feature (navigate, interact, repeat)
# ...

# Take final heap snapshot
take_memory_snapshot → filePath="e2e-evidence/devtools-memory/heap-after.heapsnapshot"

# Compare sizes — significant growth suggests leak
```

## Element Discovery Workflow

1. **Snapshot** the page: `take_snapshot` → get uid-annotated accessibility tree
2. **Identify** target element by uid
3. **Interact** using uid: `click(uid="...")`, `fill(uid="...", value="...")`
4. **Verify** result: `take_snapshot` again to check state change
5. **Screenshot** for visual evidence: `take_screenshot`

## Integration with ValidationForge

- Evidence goes to `e2e-evidence/devtools-{category}/`
- Use alongside `playwright-validation` — DevTools for debugging depth, Playwright for user journey flow
- Lighthouse reports provide structured scoring for accessibility, SEO, best practices
- Performance traces provide LCP, INP, CLS measurements
- The `verdict-writer` agent can reference Lighthouse scores and trace metrics in verdicts
- Network request evidence proves API integration works at the transport level

## When to Use DevTools vs Playwright

| Need | Use |
|------|-----|
| User journey flow (navigate, click, fill) | Playwright MCP |
| Performance profiling (Core Web Vitals) | Chrome DevTools MCP |
| Lighthouse audit (a11y, SEO) | Chrome DevTools MCP |
| Network request inspection (headers, payload) | Chrome DevTools MCP |
| Form filling and submission | Either (Playwright preferred) |
| Screenshots for visual evidence | Either |
| DOM snapshot / accessibility tree | Either |
| Memory profiling | Chrome DevTools MCP |
| CPU/network throttling | Chrome DevTools MCP |
