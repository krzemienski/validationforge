---
name: design-token-audit
description: "Audit CSS/Tailwind/inline styles against design system spec (DESIGN.md, tailwind.config, CSS vars). Detects hardcoded values, off-palette colors, non-standard spacing, typography drift."
triggers:
  - "design token audit"
  - "token compliance"
  - "design system drift"
  - "color audit"
  - "typography audit"
context_priority: reference
---

# Design Token Audit

Verify that implementation CSS, Tailwind classes, and inline styles match the project's design system specification. Detects hardcoded values, off-palette colors, non-standard spacing, and typography drift.

## When to Use

- After implementing or modifying CSS/Tailwind styles
- Before release to catch design system drift
- During design system migration (old tokens → new tokens)
- When onboarding a new codebase to a design system
- After dependency updates that might affect styles

## Audit Process

```
Phase 1: EXTRACT     Phase 2: SCAN         Phase 3: COMPARE      Phase 4: REPORT
Design spec tokens   Implementation tokens  Find mismatches       Compliance score
from DESIGN.md /     from CSS / Tailwind /  Flag violations       + recommendations
tailwind.config      inline styles
```

## Phase 1: Extract Design Tokens

### From DESIGN.md

```bash
# Search for color definitions
grep -n "color\|Color\|#[0-9a-fA-F]\{3,8\}\|rgb\|hsl" DESIGN.md

# Search for typography
grep -n "font\|Font\|px\|rem\|weight\|line-height" DESIGN.md

# Search for spacing
grep -n "spacing\|padding\|margin\|gap\|rem\|px" DESIGN.md
```

### From Tailwind Config

```bash
# Read tailwind.config.{js,ts,mjs}
# Extract theme.extend.colors, theme.extend.spacing, theme.extend.fontSize
```

### From CSS Variables

```bash
# Search for CSS custom properties
grep -rn "^--\|var(--" src/ --include="*.css" --include="*.scss"
```

### Token Catalog Output

```markdown
## Extracted Design Tokens

### Colors
| Token | Value | Usage |
|-------|-------|-------|
| --primary-bg | #0f172a | Page background |
| --card-bg | #1e293b | Cards, elevated surfaces |
| --accent | #6366f1 | CTAs, links |
| --text-primary | #f1f5f9 | Headings |
| --text-body | #cbd5e1 | Body text |

### Typography
| Token | Value |
|-------|-------|
| --font-body | Inter, system-ui, sans-serif |
| --font-mono | JetBrains Mono, monospace |
| --text-base | 16px / 1.5 |
| --text-lg | 18px / 1.75 |

### Spacing
| Token | Value |
|-------|-------|
| --space-1 | 4px |
| --space-2 | 8px |
| --space-4 | 16px |
| --space-8 | 32px |
```

Save to `e2e-evidence/design-tokens/step-01-spec-tokens.md`.

## Phase 2: Scan Implementation

### Color Scan

```bash
# Find hardcoded hex colors
grep -rn "#[0-9a-fA-F]\{3,8\}" src/ --include="*.{css,scss,tsx,jsx,html,svelte,vue}"

# Find hardcoded rgb/hsl
grep -rn "rgb\|rgba\|hsl\|hsla" src/ --include="*.{css,scss,tsx,jsx}"

# Find inline color styles
grep -rn "color:\|background:\|border-color:\|fill:\|stroke:" src/ --include="*.{tsx,jsx,html}"
```

### Typography Scan

```bash
# Find font declarations
grep -rn "font-family\|font-size\|font-weight\|line-height" src/ --include="*.{css,scss}"

# Find Tailwind font classes
grep -rn "text-\[.*\]\|font-\[.*\]" src/ --include="*.{tsx,jsx,html}"
```

### Spacing Scan

```bash
# Find hardcoded pixel values in styles
grep -rn "[0-9]\+px" src/ --include="*.{css,scss}"

# Find arbitrary Tailwind values
grep -rn "\(p\|m\|gap\|space\)-\[.*\]" src/ --include="*.{tsx,jsx,html}"
```

Save to `e2e-evidence/design-tokens/step-02-implementation-scan.md`.

## Phase 3: Compare

### Violation Types

| Type | Severity | Example |
|------|----------|---------|
| **Off-palette color** | HIGH | Using `#FF0000` when palette has no red |
| **Hardcoded value** | MEDIUM | Using `color: #6366f1` instead of `var(--accent)` |
| **Non-standard spacing** | MEDIUM | Using `padding: 13px` when grid is 4px-based |
| **Wrong font** | HIGH | Using Arial when spec says Inter |
| **Arbitrary Tailwind** | LOW | Using `p-[13px]` instead of `p-3` or `p-4` |
| **Missing token** | INFO | Design spec has token not used anywhere |

### Compliance Calculation

```
Compliance = (Compliant declarations / Total declarations) × 100

For each category:
  Color compliance = color matches / total color uses
  Typography compliance = font matches / total font uses
  Spacing compliance = spacing matches / total spacing uses
```

## Phase 4: Report

### Verdict Rules

| Compliance | Verdict | Action |
|-----------|---------|--------|
| >95% | PASS | Design system well-maintained |
| 80-95% | CONDITIONAL | Document drift, schedule fixes |
| <80% | FAIL | Significant design system violation |

### Evidence Structure

```
e2e-evidence/design-tokens/
  step-01-spec-tokens.md            # Design system token catalog
  step-02-implementation-scan.md    # Tokens found in code
  step-03-violations.md             # Specific mismatches
  step-04-compliance-score.md       # Per-category scores
  report.md                         # Overall verdict
```

### Report Template

```markdown
# Design Token Audit Report

**Design spec:** {DESIGN.md / tailwind.config.ts / CSS vars}
**Files scanned:** N
**Date:** YYYY-MM-DD

## Compliance Scores

| Category | Compliant | Total | Score |
|----------|-----------|-------|-------|
| Colors | N | N | XX% |
| Typography | N | N | XX% |
| Spacing | N | N | XX% |
| **Overall** | N | N | **XX%** |

## Verdict: PASS / CONDITIONAL / FAIL

## Violations

### HIGH Severity
| File:Line | Found | Expected | Type |
|-----------|-------|----------|------|
| src/page.tsx:42 | #FF0000 | Not in palette | Off-palette |

### MEDIUM Severity
...

### LOW Severity
...

## Recommendations
1. {specific fix with file reference}
```

## Integration with ValidationForge

- Pairs with `design-validation` for visual + token compliance
- Uses tokens from `stitch-integration` Stitch projects
- Pure code analysis — no mocking, no test files
- Evidence consumed by `verdict-writer` agent
- Feeds into `production-readiness-audit` Phase 1 (Code Quality)
