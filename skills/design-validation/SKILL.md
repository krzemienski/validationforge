---
name: design-validation
description: "Use after implementing a UI from a design spec to measure how closely the built version matches the reference. Compares a browser/device screenshot against the design source (Stitch MCP export, Figma image, or inline DESIGN.md mockup) across five categories: colors, typography, spacing, layout, interactions. Produces a weighted fidelity score and flags the specific mismatches. Pairs with design-token-audit (which checks the code-level tokens) — this skill checks the rendered output. Reach for it on phrases like 'does it match the design', 'design fidelity', 'visual regression', 'compare to mockup', 'design QA', or before shipping anything where the visual match is part of the acceptance criteria."
triggers:
  - "design validation"
  - "validate design"
  - "design fidelity"
  - "compare design to implementation"
  - "does it match the design"
  - "visual regression"
  - "design QA"
  - "compare to mockup"
context_priority: reference
---

# Design Validation

Validate that an implementation visually and structurally matches its design specification. Compares reference designs (from Stitch MCP, Figma exports, or DESIGN.md) against actual browser/device renders. Produces a fidelity score across five categories.

## When to Use

- After implementing a UI component or page from a design spec
- Before release to verify design fidelity hasn't drifted
- During design review to compare implementation against mockups
- When a designer reports "this doesn't look right"
- After CSS/Tailwind refactoring to catch visual regressions

## Three-Phase Process

```
Phase 1: REFERENCE          Phase 2: CAPTURE           Phase 3: COMPARE
Gather design specs         Screenshot implementation   Score fidelity
Stitch screens / DESIGN.md  Computed styles             per category
Color palette / tokens      Accessibility tree          PASS/FAIL verdict
```

## Phase 1: Gather Reference

### From Stitch MCP (preferred)

```
1. list_projects → find project
2. list_screens → enumerate all screens
3. get_screen → capture each screen's design
4. Save references to e2e-evidence/design-validation/reference/
```

### From DESIGN.md

```
1. Read DESIGN.md for color tokens, typography, spacing
2. Extract token values into structured format
3. Save to e2e-evidence/design-validation/reference/design-tokens.md
```

### From External Source (Figma, screenshots)

```
1. User provides reference images
2. Save to e2e-evidence/design-validation/reference/
3. Document source and version
```

## Phase 2: Capture Implementation

Using Playwright MCP or Chrome DevTools MCP:

```
1. Navigate to each page/component
2. Capture full-page screenshot at design viewport size
3. Capture accessibility tree snapshot
4. Extract computed styles for key elements:
   - Background colors, text colors
   - Font family, size, weight, line-height
   - Padding, margin, gap values
   - Border radius, box shadow
   - Layout direction, alignment
5. Save all captures to e2e-evidence/design-validation/implementation/
```

### Viewport Matching

Always capture at the SAME viewport as the design reference:
- If design is mobile (375px): `browser_resize(375, 812)`
- If design is desktop (1440px): `browser_resize(1440, 900)`
- If design is tablet (768px): `browser_resize(768, 1024)`

## Phase 3: Compare and Score

### Fidelity Categories

| Category | Weight | What to Compare |
|----------|--------|----------------|
| Colors | 25% | Background, text, accent, border colors vs palette |
| Typography | 20% | Font family, size, weight, line-height, letter-spacing |
| Spacing | 20% | Margins, paddings, gaps match design grid |
| Layout | 25% | Element positioning, alignment, hierarchy, flow |
| Interactions | 10% | Hover states, focus indicators, transitions |

### Scoring Rubric

For each category, score 0-100:

| Score | Meaning |
|-------|---------|
| 90-100 | Pixel-perfect match |
| 75-89 | Minor deviations, acceptable |
| 60-74 | Noticeable differences, needs attention |
| 40-59 | Significant drift from design |
| 0-39 | Does not resemble the design |

### Comparison Checklist

```markdown
## Color Comparison
- [ ] Primary background matches design palette
- [ ] Text colors use correct token values
- [ ] Accent/CTA colors match brand palette
- [ ] No hardcoded hex values outside the design system
- [ ] Dark mode colors (if applicable) match dark palette

## Typography Comparison
- [ ] Heading fonts match spec (family, size, weight)
- [ ] Body text matches spec (family, size, line-height)
- [ ] Code/monospace font matches spec
- [ ] Font sizes scale correctly across hierarchy (h1 > h2 > h3)

## Spacing Comparison
- [ ] Page margins match design grid
- [ ] Component padding is consistent
- [ ] Vertical rhythm between sections is uniform
- [ ] Card/container internal spacing matches spec

## Layout Comparison
- [ ] Element order matches design
- [ ] Alignment (left/center/right) matches design
- [ ] Grid/flex layout matches column structure
- [ ] Content width constraints match spec
- [ ] Visual hierarchy matches design intent

## Interaction Comparison
- [ ] Hover states exist where design shows them
- [ ] Focus indicators are visible and styled
- [ ] Button states (default/hover/active/disabled) match
- [ ] Transitions/animations match design intent
```

## Verdict

### Overall Score Calculation

```
Overall = (Colors × 0.25) + (Typography × 0.20) + (Spacing × 0.20) + (Layout × 0.25) + (Interactions × 0.10)
```

### Verdict Rules

| Overall Score | Verdict | Action |
|--------------|---------|--------|
| >85 | PASS | Design fidelity is acceptable |
| 70-85 | CONDITIONAL | Document deviations, get designer approval |
| <70 | FAIL | Significant design drift — fix before shipping |
| Any category <50 | FAIL | One category severely off — fix that category |

## Evidence Structure

```
e2e-evidence/design-validation/
  reference/
    screen-01-homepage.png          # Design reference
    screen-02-dashboard.png
    design-tokens.md                # Extracted token values
  implementation/
    screen-01-homepage.png          # Browser capture
    screen-02-dashboard.png
    computed-styles.json            # Extracted CSS values
    accessibility-tree.txt          # A11y snapshot
  comparison/
    step-01-color-analysis.md       # Category comparison
    step-02-typography-analysis.md
    step-03-spacing-analysis.md
    step-04-layout-analysis.md
    step-05-interaction-analysis.md
  report.md                         # Fidelity scores + verdict
```

## Report Template

```markdown
# Design Validation Report

**Design source:** {Stitch project / DESIGN.md / Figma}
**Pages validated:** N
**Date:** YYYY-MM-DD

## Fidelity Scores

| Category | Score | Weight | Weighted |
|----------|-------|--------|----------|
| Colors | XX/100 | 25% | XX |
| Typography | XX/100 | 20% | XX |
| Spacing | XX/100 | 20% | XX |
| Layout | XX/100 | 25% | XX |
| Interactions | XX/100 | 10% | XX |
| **Overall** | | | **XX/100** |

## Verdict: PASS / CONDITIONAL / FAIL

## Deviations Found
1. {deviation with evidence reference}

## Evidence Files
[list all files in e2e-evidence/design-validation/]
```

## Integration with ValidationForge

- Uses `stitch-integration` skill for Stitch MCP design references
- Uses `design-token-audit` skill for token compliance checking
- Complements `visual-inspection` (defect detection) — this skill checks design FIDELITY
- Evidence consumed by `verdict-writer` agent for overall validation report
- Pairs with `responsive-validation` for multi-viewport design checking
