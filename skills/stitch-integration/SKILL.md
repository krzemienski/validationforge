---
name: stitch-integration
description: "Use for the design-to-code pipeline via Stitch MCP — generating reference designs from text prompts before implementation, iterating variants, and persisting the design + tokens as the reference that design-validation later compares against. Most useful at the START of a UI feature (explore options visually before writing code) or when you want to lock in a reference for later validation. Pairs with design-validation (compares built UI vs Stitch output) and design-token-audit (checks token compliance). Reach for it on phrases like 'design before code', 'stitch design', 'explore UI options', 'generate UI mockup', 'create design reference', 'design-to-code'."
triggers:
  - "stitch integration"
  - "stitch design"
  - "generate design"
  - "design to code"
  - "stitch project"
  - "explore UI options"
  - "generate UI mockup"
  - "create design reference"
context_priority: reference
---

# Stitch Integration

Manage the design-to-code pipeline using Stitch MCP. Generate reference designs from text prompts, iterate with variants, and produce design references for `design-validation` to compare against implementation.

## When to Use

- When starting a new UI feature and need a design reference
- When validating implementation against AI-generated designs
- When exploring design variants before committing to an approach
- When the project uses Stitch MCP for design management

## Prerequisites

- Stitch MCP server must be configured and available
- Design system spec (DESIGN.md or equivalent) should exist for prompt context
- Project may have existing `stitch.json` with persisted project ID

## Workflow

```
1. PROJECT    → Create or load Stitch project
2. GENERATE   → Create screens from text prompts
3. ITERATE    → Edit screens or generate variants
4. CAPTURE    → Save screen references as evidence
5. BRIDGE     → Feed references to design-validation
```

## Phase 1: Project Management

### Create New Project

```
mcp: create_project(title="Project Name - Validation Reference")
→ Save returned project ID to stitch.json
```

### Load Existing Project

```
1. Read stitch.json for project ID
2. mcp: get_project(name="projects/{id}")
3. mcp: list_screens(projectId="{id}")
```

### Persist Project ID (CRITICAL)

After EVERY `create_project` call, save the ID:
```json
// stitch.json
{
  "projectId": "5577890677756270199",
  "created": "2026-03-07",
  "title": "Project Name"
}
```

## Phase 2: Generate Screens

### Design System Prompt Template

Always include the design system context in generation prompts:

```
Generate a {component/page description}.

Design System:
- Background: {primary background color}
- Cards: {card/surface color}
- Primary accent: {accent color}
- Text: {heading color} for headings, {body color} for body
- Font: {font family}
- Border radius: {radius value}
- Spacing: {spacing scale}

Style: {additional style guidance}
```

### Generation Call

```
mcp: generate_screen_from_text(
  projectId="{id}",
  prompt="Design system prompt + component description",
  deviceType="DESKTOP" | "MOBILE" | "TABLET"
)
```

### Handle Output Components

The response may include `output_components` with suggestions. If present:
- Present suggestions to the user
- If user accepts a suggestion, call `generate_screen_from_text` again with the accepted suggestion as the prompt

## Phase 3: Iterate

### Edit Existing Screens

```
mcp: edit_screens(
  projectId="{id}",
  selectedScreenIds=["screen-id-1", "screen-id-2"],
  prompt="Make the header more prominent, increase padding",
  deviceType="DESKTOP"
)
```

### Generate Variants

```
mcp: generate_variants(
  projectId="{id}",
  selectedScreenIds=["screen-id"],
  prompt="Explore different color schemes for this layout",
  variantOptions={
    variantCount: 3,
    creativeRange: "EXPLORE",
    aspects: ["COLOR_SCHEME", "LAYOUT"]
  }
)
```

### Creative Range Guide

| Range | Use When |
|-------|----------|
| REFINE | Small tweaks — spacing, font size, color shade |
| EXPLORE | Moderate changes — layout variations, different color palettes |
| REIMAGINE | Radical alternatives — completely different approaches |

### Variant Aspects

| Aspect | What Changes |
|--------|-------------|
| LAYOUT | Element arrangement and structure |
| COLOR_SCHEME | Color palette and contrast |
| IMAGES | Image selection and placement |
| TEXT_FONT | Typography choices |
| TEXT_CONTENT | Copy and label text |

## Phase 4: Capture References

```
1. mcp: list_screens(projectId="{id}")
2. For each screen:
   a. mcp: get_screen(name="projects/{id}/screens/{screenId}", ...)
   b. Save screen metadata and image URL
   c. Document in evidence directory
```

### Evidence Output

```
e2e-evidence/design-validation/reference/
  stitch-screen-01-{name}.png
  stitch-screen-02-{name}.png
  stitch-project-metadata.json
```

## Phase 5: Bridge to Design Validation

The captured Stitch screens become the REFERENCE for `design-validation`:

```
stitch-integration produces → reference screenshots
design-validation consumes  → reference screenshots
                            → compares with implementation screenshots
                            → produces fidelity score
```

## Rules

1. **ALWAYS** persist project ID after `create_project`
2. **ALWAYS** include design system context in generation prompts
3. **ALWAYS** specify `deviceType` — never leave it unspecified
4. **NEVER** retry immediately on generation failure — wait, then check if it completed
5. **ALWAYS** handle `output_components` suggestions in response
6. **ALWAYS** capture screen references as evidence files

## Integration with ValidationForge

- Produces design references consumed by `design-validation` skill
- Design system tokens from Stitch inform `design-token-audit`
- Evidence goes to `e2e-evidence/design-validation/reference/`
- Stitch project IDs persisted in `stitch.json` at project root
- The `verdict-writer` agent can reference Stitch fidelity scores in verdicts
