---
name: accessibility-audit
description: Deep WCAG 2.1 AA accessibility audit with Lighthouse, keyboard navigation, and screen reader validation
triggers:
  - "accessibility audit"
  - "a11y audit"
  - "wcag compliance"
  - "accessibility check"
  - "screen reader validation"
context_priority: reference
---

# Accessibility Audit

Deep accessibility audit against WCAG 2.1 AA standards. Goes beyond automated scans to include keyboard navigation testing, screen reader simulation, and manual contrast verification. Produces scored findings with severity ratings.

## When to Use

- Before any public-facing release
- When accessibility complaints or legal requirements arise
- After significant UI changes
- As part of `production-readiness-audit` Phase 2
- When targeting WCAG 2.1 AA compliance

## Audit Layers

```
Layer 1: AUTOMATED     Layer 2: KEYBOARD     Layer 3: SCREEN READER    Layer 4: VISUAL
Lighthouse + axe       Tab navigation        A11y tree structure       Contrast + color
   |                      |                      |                        |
   v                      v                      v                        v
 Score + issues        Reachability           Hierarchy + labels        Ratios + modes
```

## Layer 1: Automated Scan

Run Lighthouse accessibility audit via Chrome DevTools MCP.

```
# Navigate to page
navigate_page → url="http://localhost:3000"

# Desktop audit
lighthouse_audit → device="desktop", mode="navigation",
  outputDirPath="e2e-evidence/accessibility/lighthouse-desktop"

# Mobile audit
lighthouse_audit → device="mobile", mode="navigation",
  outputDirPath="e2e-evidence/accessibility/lighthouse-mobile"
```

### Interpret Lighthouse Results

| Score | Rating | Action |
|-------|--------|--------|
| 90-100 | Good | Minor fixes only |
| 70-89 | Needs improvement | Address all issues before launch |
| <70 | Poor | Significant remediation required |

Save Lighthouse HTML reports as evidence.

## Layer 2: Keyboard Navigation

Test that all interactive elements are reachable and usable via keyboard only.

### Keyboard Test Protocol

```
Step 1: Tab through entire page from top
Step 2: Document tab order (is it logical?)
Step 3: Verify focus indicators are visible
Step 4: Test Enter/Space on all buttons and links
Step 5: Test Escape on modals and dropdowns
Step 6: Test arrow keys in menus and tabs
Step 7: Check for keyboard traps (can't tab out)
Step 8: Verify skip navigation link exists and works
```

### Evidence Capture

For each step, capture:
1. **Snapshot** — `take_snapshot` to see focused element in a11y tree
2. **Screenshot** — `take_screenshot` showing focus indicator
3. **Finding** — Document in findings table

```bash
mkdir -p e2e-evidence/accessibility/keyboard
```

### Keyboard Findings Template

```markdown
## Keyboard Navigation Findings

| # | Element | Reachable? | Focus Visible? | Operable? | Issue |
|---|---------|-----------|---------------|-----------|-------|
| 1 | Main nav links | YES | YES | YES | — |
| 2 | Search button | YES | NO | YES | Missing focus ring |
| 3 | Modal close | NO | — | — | Keyboard trap in modal |
```

Save to `e2e-evidence/accessibility/step-02-keyboard.md`.

## Layer 3: Screen Reader Simulation

Use accessibility tree snapshots to verify screen reader experience.

### A11y Tree Checks

```
# Get full accessibility tree
take_snapshot → (from Chrome DevTools or Playwright MCP)
```

### Checklist

| # | Check | How to Verify | Severity |
|---|-------|--------------|----------|
| 3.1 | Page has exactly one h1 | Count h1 in a11y tree | HIGH |
| 3.2 | Heading hierarchy is sequential | h1→h2→h3 (no skips) | HIGH |
| 3.3 | Images have alt text | Check img elements in tree | HIGH |
| 3.4 | Decorative images have alt="" | Empty alt, not missing | MEDIUM |
| 3.5 | Form inputs have labels | label elements or aria-label | HIGH |
| 3.6 | Links have descriptive text | No "click here" or "read more" | MEDIUM |
| 3.7 | ARIA roles are correct | role attributes match behavior | HIGH |
| 3.8 | ARIA states update dynamically | aria-expanded, aria-selected | MEDIUM |
| 3.9 | Live regions for dynamic content | aria-live on notifications | MEDIUM |
| 3.10 | Language attribute on html | lang="en" or appropriate | LOW |

Save findings to `e2e-evidence/accessibility/step-03-screen-reader.md`.

## Layer 4: Visual Accessibility

### Color Contrast Checks

WCAG 2.1 AA requirements:

| Element Type | Minimum Ratio | How to Check |
|-------------|--------------|-------------|
| Normal text (<18px) | 4.5:1 | Lighthouse or manual calculation |
| Large text (≥18px bold or ≥24px) | 3:1 | Lighthouse or manual calculation |
| UI components (borders, icons) | 3:1 | Manual inspection |
| Focus indicators | 3:1 against adjacent | Manual inspection |

### Additional Visual Checks

| # | Check | Severity |
|---|-------|----------|
| 4.1 | Information not conveyed by color alone | HIGH |
| 4.2 | Text readable at 200% zoom | HIGH |
| 4.3 | No horizontal scroll at 320px width | HIGH |
| 4.4 | Touch targets ≥ 44x44 CSS pixels | HIGH (mobile) |
| 4.5 | Animations respect prefers-reduced-motion | MEDIUM |
| 4.6 | Dark mode maintains contrast ratios | MEDIUM |
| 4.7 | Error states have non-color indicators | HIGH |

### Dark Mode Audit

```
# Switch to dark mode
emulate → colorScheme="dark"
take_screenshot → filePath="e2e-evidence/accessibility/dark-mode.png"

# Check contrast in dark mode
lighthouse_audit → device="desktop", mode="snapshot",
  outputDirPath="e2e-evidence/accessibility/lighthouse-dark"

# Reset
emulate → colorScheme="auto"
```

Save to `e2e-evidence/accessibility/step-04-visual.md`.

## Scoring and Verdict

### Category Scores

| Category | Weight | Score Method |
|----------|--------|-------------|
| Automated (Lighthouse) | 30% | Lighthouse score / 100 |
| Keyboard navigation | 25% | Pass rate of keyboard checks |
| Screen reader | 25% | Pass rate of a11y tree checks |
| Visual accessibility | 20% | Pass rate of visual checks |

### Verdict Rules

| Weighted Score | Verdict | Condition |
|---------------|---------|-----------|
| >85 | PASS | No HIGH-severity issues remaining |
| 70-85 | CONDITIONAL | HIGH issues documented with remediation plan |
| <70 | FAIL | Significant accessibility barriers exist |

**Override:** ANY keyboard trap = automatic FAIL regardless of score.

## Final Report

```markdown
# Accessibility Audit Report

**URL:** {page URL}
**Standard:** WCAG 2.1 AA
**Date:** YYYY-MM-DD

## Summary
| Layer | Score | Issues |
|-------|-------|--------|
| 1. Automated (Lighthouse) | X/100 | N issues |
| 2. Keyboard Navigation | X% pass | N failures |
| 3. Screen Reader | X% pass | N failures |
| 4. Visual Accessibility | X% pass | N failures |
| **Weighted Total** | **X/100** | |

## Verdict: PASS / CONDITIONAL / FAIL

## Critical Issues (must fix)
1. {issue with evidence reference}

## Important Issues (should fix)
1. {issue with evidence reference}

## Minor Issues (nice to fix)
1. {issue with evidence reference}

## Evidence Files
{list all files in e2e-evidence/accessibility/}
```

Save to `e2e-evidence/accessibility/report.md`.

## Integration with ValidationForge

- Deeper than `web-testing` Layer 3 (which is a checklist item, this is a FULL audit)
- Complements `visual-inspection` (accessibility is structural, inspection is visual)
- Uses Chrome DevTools MCP for Lighthouse and a11y tree
- Uses Playwright MCP for keyboard navigation testing
- Can be dispatched in parallel via `parallel-validation`
- Evidence goes to `e2e-evidence/accessibility/`
- Findings feed into `production-readiness-audit` Phase 2 (Security covers a11y)
