---
name: responsive-validation
description: "Use for systematic responsive layout validation across 8 device viewports (iPhone SE 375px up through desktop 1920px). Goes beyond screenshot-at-each-width: checks layout integrity at breakpoints, touch target sizing (44px minimum per Apple HIG, 48dp per Material), typography scaling, content parity across widths (no desktop-only content hidden on mobile), orientation handling, and horizontal overflow detection. Reach for it on phrases like 'responsive validation', 'check all breakpoints', 'mobile responsive test', 'touch target audit', 'does this overflow on mobile', after any responsive redesign or CSS refactor, or when a mobile launch needs proof."
triggers:
  - "responsive validation"
  - "responsive testing"
  - "viewport testing"
  - "mobile responsive"
  - "breakpoint validation"
  - "touch target audit"
  - "horizontal overflow"
  - "does this look right on mobile"
context_priority: reference
---

# Responsive Validation

Systematic validation across a device viewport matrix. Goes beyond basic screenshot comparison — validates layout behavior, touch targets, content parity, overflow, and responsive-specific interactions at every breakpoint.

## When to Use

- After implementing responsive layouts
- Before mobile launch or responsive redesign
- When users report layout issues on specific devices
- During cross-device QA for web applications
- After CSS grid/flexbox refactoring

## Device Matrix

### Standard Viewports

| Device | Width | Height | DPR | Flags |
|--------|-------|--------|-----|-------|
| iPhone SE | 375 | 667 | 2 | mobile, touch |
| iPhone 15 | 393 | 852 | 3 | mobile, touch |
| iPhone 15 Pro Max | 430 | 932 | 3 | mobile, touch |
| iPad Mini | 768 | 1024 | 2 | mobile, touch |
| iPad Pro 12.9 | 1024 | 1366 | 2 | mobile, touch |
| Laptop | 1280 | 800 | 1 | — |
| Desktop | 1440 | 900 | 1 | — |
| Wide Desktop | 1920 | 1080 | 1 | — |

### Breakpoint Categories

| Category | Widths | Purpose |
|----------|--------|---------|
| Mobile | 375, 393, 430 | Phone layouts |
| Tablet | 768, 1024 | Tablet layouts |
| Desktop | 1280, 1440, 1920 | Desktop layouts |

## Validation Protocol

### Phase 1: Configure Viewports

Using Playwright MCP:
```
browser_resize(width, height) for each viewport
```

Using Chrome DevTools MCP:
```
emulate(viewport="{width}x{height}x{dpr},{flags}")
```

### Phase 2: Per-Viewport Checks

For EACH viewport in the matrix:

#### 2a. Visual Capture
```
1. Navigate to page
2. Wait for full render (condition-based-waiting)
3. Capture full-page screenshot
4. Capture accessibility tree snapshot
```

#### 2b. Layout Validation
```
- [ ] No horizontal overflow (no scrollbar at bottom)
- [ ] Content fits within viewport width
- [ ] Navigation adapts correctly (hamburger on mobile, full on desktop)
- [ ] Grid columns collapse appropriately
- [ ] Sidebar transforms (drawer on mobile, visible on desktop)
- [ ] Images scale without distortion
- [ ] Text doesn't overflow containers
```

#### 2c. Touch Target Validation (mobile/tablet only)
```
- [ ] All interactive elements ≥ 44x44 CSS pixels
- [ ] Adequate spacing between touch targets (≥ 8px gap)
- [ ] No overlapping clickable areas
- [ ] Dropdown/select elements are finger-friendly
```

#### 2d. Typography Validation
```
- [ ] Body text ≥ 16px on mobile (prevents iOS zoom)
- [ ] Headings scale appropriately across breakpoints
- [ ] Line length stays readable (45-75 characters ideal)
- [ ] No text truncation that hides essential content
```

#### 2e. Content Parity
```
- [ ] All content visible at desktop is accessible on mobile
- [ ] If content is hidden on mobile, it's accessible via menu/accordion
- [ ] CTAs and critical actions are visible at all sizes
- [ ] Form fields are all reachable and usable
```

### Phase 3: Cross-Breakpoint Analysis

Compare screenshots across the full matrix:

```
- [ ] Layout transitions are smooth between breakpoints
- [ ] No "broken" intermediate states (e.g., at 769px)
- [ ] Content reflow is logical (desktop order → mobile stack)
- [ ] Navigation state is consistent across transitions
```

### Phase 4: Orientation Testing (mobile/tablet)

```
# Portrait
emulate(viewport="375x667x2,mobile,touch")
→ capture screenshot

# Landscape
emulate(viewport="667x375x2,mobile,touch,landscape")
→ capture screenshot

Verify:
- [ ] Content adapts to landscape orientation
- [ ] No critical content cut off in landscape
- [ ] Navigation still accessible in both orientations
```

## Evidence Structure

```
e2e-evidence/responsive-validation/
  mobile-375/
    step-01-full-page.png
    step-02-accessibility-tree.txt
    step-03-touch-targets.md
  mobile-393/
    ...
  tablet-768/
    ...
  desktop-1440/
    ...
  landscape-667x375/
    ...
  step-final-cross-breakpoint-analysis.md
  report.md
```

## Verdict Rules

| Result | Verdict |
|--------|---------|
| All viewports pass all checks | PASS |
| Minor issues (cosmetic only, no functional impact) | CONDITIONAL |
| Touch targets too small on mobile | FAIL |
| Content inaccessible at any viewport | FAIL |
| Horizontal overflow at any viewport | FAIL |
| Text below 16px on mobile | FAIL (iOS will zoom) |

## Report Template

```markdown
# Responsive Validation Report

**Pages validated:** N
**Viewports tested:** 8
**Date:** YYYY-MM-DD

## Viewport Results

| Viewport | Layout | Touch | Typography | Content | Verdict |
|----------|--------|-------|------------|---------|---------|
| 375px | OK | OK | OK | OK | PASS |
| 393px | OK | OK | OK | OK | PASS |
| 768px | ISSUE | OK | OK | OK | CONDITIONAL |
| 1440px | OK | N/A | OK | OK | PASS |

## Issues Found
1. {issue at viewport with evidence reference}

## Overall Verdict: PASS / CONDITIONAL / FAIL
```

## Integration with ValidationForge

- Complements `playwright-validation` (which has basic responsive) — this is the DEEP responsive audit
- Uses `chrome-devtools` for emulation with device flags (mobile, touch, DPR)
- Pairs with `design-validation` for multi-viewport design fidelity
- Evidence consumed by `verdict-writer` agent
- Informs `accessibility-audit` touch target findings
