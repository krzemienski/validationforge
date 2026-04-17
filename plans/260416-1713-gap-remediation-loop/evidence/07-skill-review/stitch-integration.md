---
skill: stitch-integration
reviewed_at: 2026-04-16T20:15:00Z
reviewer: R4
---

## Frontmatter Check
- **name:** stitch-integration ✓
- **description:** "Generate reference designs via Stitch MCP, iterate variants, persist projects and design tokens. Use when starting UI features, exploring options before code, or validating implementation fidelity." (178 chars) ✓
- **yaml_parses:** Yes ✓

## Trigger Realism
5 triggers: "stitch integration", "stitch design", "generate design", "design to code", "stitch project"
**Realism:** 5/5 — All align with design-to-code workflows

## Body-Description Alignment
**Verdict:** PASS — Phase 2 generates designs. Phase 3 iterates variants. Phase 1 persists projects/tokens to stitch.json. Phase 5 bridges to design-validation. All claims verified.

## MCP Tool Existence
Stitch MCP methods: create_project, get_project, list_screens, generate_screen_from_text, edit_screens, generate_variants, get_screen ✓

## Example Invocation Proof
**Prompt:** "generate design for user profile page" (6 words, viable)

## Verdict
**Status:** PASS

5-phase workflow. Project persistence via stitch.json critical for multi-session continuity. Design System Prompt Template well-structured. Creative Range guide (REFINE/EXPLORE/REIMAGINE) provides scoping. Variant Aspects matrix comprehensive.

## Notes
- 6 critical rules enforce best practices
- output_components handling suggests AI suggestions need user approval
- Design system context is non-optional (rules enforce)
- Assumes Stitch MCP available (critical prerequisite)
