---
skill: build-quality-gates
reviewer: R1
date: 2026-04-16
verdict: PASS
---

# build-quality-gates review

## Frontmatter check
- name: `build-quality-gates`
- description: `"4-stage pipeline: compile, lint, type-check, bundle. Each gate PASS required before next. Build gates are necessary NOT sufficient—functional validation still required. Use pre-deploy, pre-PR."` (197 chars)
- description_well_formed: yes
- yaml_parses: yes

## Trigger realism
Would invoke on: `"build quality"`, `"quality gates"`, `"pre-deploy checks"`, `"build verification"`.
Realism score: 5/5. Developer workflows use this terminology constantly. Triggers match reality.

## Body-description alignment
PASS. Body delivers all 4 gates:
- Gate 1 (Compile): npm run build / xcodebuild / cargo build ✓
- Gate 2 (Lint): eslint / ruff / go vet / swiftlint ✓
- Gate 3 (Type-check): tsc / mypy / go vet ✓
- Gate 4 (Bundle): ANALYZE=true, bundle size, dependency check ✓

Critical callout: "Build gates passing does NOT mean the feature works." ✓ This is emphasized twice to prevent false completion claims.

## MCP tool existence
None. All gates use standard CLI tools (npm, cargo, tsc, eslint, etc.) that are always available in projects using them.

## Example invocation proof
User: `"Run pre-deploy build quality checks"`
Would execute 4-stage pipeline per architecture diagram, capturing output to e2e-evidence/build-gates/.

## Verdict
**PASS**

Well-structured skill with clear stage dependencies. Critical callout about sufficiency is explicit and repeated. Report template is clear. Platform detection table aids setup.
