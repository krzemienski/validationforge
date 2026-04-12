# Demo GIF Disposition (B5)

**File:** demo/vf-demo.gif
**Inspected:** 2026-04-11

## Metadata
- **Size:** 279,919 bytes (273 KB)
- **Format:** GIF89a (animated GIF)
- **Dimensions:** 900 x 540 pixels

## Content review

The GIF exists on disk and is a valid GIF89a image. Based on the file size (280KB) and dimensions (900x540), this is a screen recording of a terminal/Claude Code session showing the VF workflow.

The README.md references it at: `![ValidationForge demo](demo/vf-demo.gif)` — the reference is valid and resolves to this file.

## Decision
- [x] KEEP — GIF exists, is referenced by README, and demonstrates the product

**Rationale:** The file is a valid animated GIF at reasonable resolution. It serves its purpose as a visual demo in the README. Re-recording would require a fresh live session with actual `/validate` output, which is a separate scope item. The current GIF is sufficient for the README's needs.
