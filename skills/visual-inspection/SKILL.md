---
name: visual-inspection
description: "Use before claiming any frontend work is done to capture the states that often break silently — not just the happy path. Covers: all responsive breakpoints, dark/light mode switching, empty states (no data), error states (API failed), loading states (skeleton / spinner), disabled states, focus states, long-content overflow. Reach for it on phrases like 'is the UI right', 'check the frontend before I ship', 'visual review', 'did I handle all states', 'empty state check', 'loading spinner verification', or whenever a frontend change could affect visual behavior beyond the happy path."
triggers:
  - "visual inspection"
  - "check the UI"
  - "does it look right"
  - "visual review"
  - "UI inspection"
  - "screenshot review"
  - "empty state check"
  - "did I handle all states"
  - "loading state check"
context_priority: reference
---

# Visual Inspection

Systematic visual inspection of running application UIs. Captures screenshots, describes what is ACTUALLY visible, and produces structured PASS/FAIL verdicts per checklist item with evidence files.

## When to Use

- After implementing UI changes — verify the real rendered output
- Before claiming a frontend task is complete
- When validating responsive layouts across breakpoints
- When checking dark/light mode rendering
- As part of any `e2e-validate` journey that includes UI

## Philosophy

**You are a camera, not an optimist.** Describe exactly what you see in screenshots. Never assume something "probably looks fine" — capture it and describe it. Every observation goes into `e2e-evidence/`.

## Inspection Checklist

Run through ALL categories. Skip only if the category is provably irrelevant (e.g., no forms = skip Form Controls).

### 1. Layout & Overflow

| # | Check | How to Verify |
|---|-------|---------------|
| 1.1 | No horizontal scrollbar on viewport-width pages | Screenshot at 375px, 768px, 1440px — check for overflow |
| 1.2 | No text truncation hiding content | Read all visible text — is anything cut off mid-word? |
| 1.3 | No overlapping elements | Describe spatial relationships of adjacent elements |
| 1.4 | Consistent spacing between sections | Measure visual gaps — are they uniform? |
| 1.5 | Content fits within containers | No content bleeding outside card/section boundaries |

### 2. Typography & Readability

| # | Check | How to Verify |
|---|-------|---------------|
| 2.1 | Body text is readable (14px+ equivalent) | Describe font size relative to viewport |
| 2.2 | Headings have clear hierarchy | H1 > H2 > H3 visually distinguishable |
| 2.3 | Line length is comfortable (45-75 chars) | Count approximate characters per line |
| 2.4 | Sufficient contrast (text vs background) | Describe color pairing — is text easily readable? |
| 2.5 | No orphaned headings at page bottom | Heading has at least 2 lines of content below it |

### 3. Interactive Elements

| # | Check | How to Verify |
|---|-------|---------------|
| 3.1 | Buttons have visible boundaries | Can you distinguish buttons from plain text? |
| 3.2 | Links are visually distinct | Color, underline, or other affordance present |
| 3.3 | Hover/focus states exist | Capture screenshot during hover (web only) |
| 3.4 | Form inputs have labels | Every input field has associated label text |
| 3.5 | Error states are visible | Trigger a validation error — is feedback shown? |

### 4. Visual Hierarchy

| # | Check | How to Verify |
|---|-------|---------------|
| 4.1 | Primary CTA is most prominent element | Describe what draws the eye first |
| 4.2 | Navigation is findable | Can you locate nav within 2 seconds? |
| 4.3 | Content sections are visually separated | Cards, dividers, spacing, or color changes |
| 4.4 | Empty states have content | Navigate to a page with no data — what renders? |

### 5. Platform-Specific

#### iOS (HIG Compliance)
| # | Check | How to Verify |
|---|-------|---------------|
| 5.1 | Safe area respected | Content not hidden behind notch/home indicator |
| 5.2 | Touch targets >= 44pt | Buttons/links are large enough to tap |
| 5.3 | System font used or custom font renders correctly | Describe the typeface |
| 5.4 | Tab bar icons are clear | Icons are recognizable without labels |

#### Web (WCAG Basics)
| # | Check | How to Verify |
|---|-------|---------------|
| 5.1 | Focus indicators visible | Tab through page — can you see focus ring? |
| 5.2 | Images have alt text (check DOM) | Inspect `<img>` elements for alt attributes |
| 5.3 | Color is not the only differentiator | Can you distinguish states without color? |
| 5.4 | Page has logical heading structure | Check heading levels in DOM snapshot |

### 6. Dark/Light Mode

| # | Check | How to Verify |
|---|-------|---------------|
| 6.1 | Both modes render without invisible text | Switch modes — is all text readable? |
| 6.2 | Images/icons adapt to mode | No white-bg images on dark backgrounds |
| 6.3 | Borders/dividers visible in both modes | Check subtle UI elements |

### 7. Edge Cases

| # | Check | How to Verify |
|---|-------|---------------|
| 7.1 | Long text content doesn't break layout | Enter a 200-char string — does it wrap? |
| 7.2 | Empty lists show placeholder | Navigate to list with 0 items |
| 7.3 | Loading states exist | Capture during data fetch if possible |
| 7.4 | Error states render gracefully | Trigger a network error or invalid input |

## Severity Classification

| Severity | Definition | Example |
|----------|-----------|---------|
| **CRITICAL** | Feature is unusable or data is hidden | Button overlaps content, text invisible |
| **HIGH** | Major usability problem | Touch targets too small, no error feedback |
| **MEDIUM** | Noticeable but functional | Inconsistent spacing, minor alignment issues |
| **LOW** | Polish issue | Subtle color mismatch, minor typography |

## Evidence Capture Protocol

### Web
```bash
mkdir -p e2e-evidence/visual-inspection
```

Use Playwright MCP or Chrome DevTools MCP:
- `browser_take_screenshot` at each breakpoint (375px, 768px, 1440px)
- `browser_snapshot` for DOM structure verification
- `browser_console_messages` for rendering errors

Save to: `e2e-evidence/visual-inspection/step-NN-{breakpoint}-{description}.png`

### iOS
```bash
mkdir -p e2e-evidence/visual-inspection
xcrun simctl io booted screenshot e2e-evidence/visual-inspection/step-NN-{description}.png
```

Use idb for accessibility tree:
```bash
UDID=$(xcrun simctl list devices booted | grep -Eo '[0-9A-F-]{36}' | head -1)
idb ui describe-all --udid "$UDID" > e2e-evidence/visual-inspection/step-NN-accessibility-tree.txt
```

## Output Format

Produce a structured report saved to `e2e-evidence/visual-inspection/report.md`:

```markdown
# Visual Inspection Report

**Platform:** iOS | Web | Both
**Breakpoints tested:** [list]
**Screenshots captured:** N
**Date:** YYYY-MM-DD

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | N |
| HIGH | N |
| MEDIUM | N |
| LOW | N |

## Findings

### [CRITICAL] Finding Title
**Checklist item:** 1.3 — No overlapping elements
**Screenshot:** `e2e-evidence/visual-inspection/step-03-375px-header.png`
**Observed:** Navigation hamburger icon overlaps page title at 375px width
**Expected:** Elements should not overlap
**Remediation:** Adjust header flex layout to prevent collision

### [HIGH] Finding Title
...
```

## Integration with ValidationForge

- Evidence files go to `e2e-evidence/visual-inspection/`
- The `verdict-writer` agent reads these files to produce journey verdicts
- Visual inspection findings can FAIL a validation journey if CRITICAL severity issues are found
- Always capture BEFORE and AFTER screenshots when fixing visual issues

## Anti-Patterns

| Anti-pattern | Correct approach |
|-------------|-----------------|
| "Screenshot looks fine" | Describe WHAT you see: "Header shows logo left-aligned, nav links right-aligned, no overlap" |
| "UI renders correctly" | List specific elements observed and their states |
| Checking only one breakpoint | Test at minimum 375px, 768px, 1440px |
| Skipping dark mode | Always check if the app supports dark mode |
| Only checking happy path | Test empty states, error states, loading states |
