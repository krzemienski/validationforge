# ADR 001: `patterns.js` is a pre-compiled CJS file, not a runtime bridge

**Status:** Accepted
**Date:** 2026-04-17
**Decision driver:** Full-codebase review finding H2 (review ID
`plans/reports/review-260417-1631-full-codebase.md`)

## Context

From an early point in ValidationForge's life, the README and ARCHITECTURE
documents described the pattern-sharing mechanism between the Claude Code
hooks (Node CJS) and the OpenCode plugin (TypeScript) as a runtime bridge:

> "`patterns.js` | (bridge) | (none) | CommonJS bridge: loads `patterns.ts` for
> CC hooks via `vm` sandbox"

and:

> "CC hooks (hooks/patterns.js) — CommonJS bridge using `vm.runInNewContext()`:
> 1. Reads patterns.ts from disk
> 2. Strips TypeScript syntax
> 3. Evaluates in vm sandbox
> 4. Falls back to inline copy if patterns.ts is unavailable"

**None of that is true.** The file that actually exists is
`hooks/lib/patterns.js`, it is plain pre-compiled TypeScript output
(`Object.defineProperty(exports, "__esModule", ...)`), and no hook references
`vm.runInNewContext` anywhere.

Two independent reviewers (Security + Performance) during the 2026-04-17
full-codebase review independently spent investigation budget looking for
a sandbox-escape path that cannot exist. The fiction had to go.

## Decision

**Patterns are shared via two parallel source-of-truth files, hand-kept-in-sync
via `tsc`.**

```
.opencode/plugins/validationforge/patterns.ts   — source of truth (TypeScript)
  │
  │   tsc --module commonjs --target es2019 --outDir hooks/lib
  ▼
hooks/lib/patterns.js                            — pre-compiled CJS
```

- **Claude Code hooks** (`hooks/*.js`) `require('./lib/patterns')` — no
  sandbox, no bridge, just `Object.prototype`. This is cheap (~1ms load),
  obvious, and fails loudly if missing.
- **OpenCode plugin** (`.opencode/plugins/validationforge/index.ts`)
  `import { ... } from './patterns'` — Bun's native TypeScript loader handles
  the import directly.
- **Regen workflow**: if `patterns.ts` is edited, run the `tsc` command above
  to refresh `hooks/lib/patterns.js`, then commit both files together.

## Rejected alternatives

1. **Actual `vm.runInNewContext` bridge** — the fiction the docs described.
   Rejected because (a) it's pure overhead for a file that changes monthly at
   most, (b) sandbox semantics depend on Node version, (c) the TypeScript-strip
   step is fragile (comments, template literals, type annotations interacting
   with generics), (d) runtime fallback to an "inline copy" means the
   sandbox path is never actually exercised in production.

2. **Publish `@validationforge/patterns` as an npm dep** — rejected because
   ValidationForge is distributed as a Claude Code plugin via marketplace /
   install script, not as an npm consumer. Adding an npm dependency for 100
   lines of regex is YAGNI.

3. **Duplicate patterns.js by hand** — rejected because hand-copying drifts.
   `tsc` from one source is the correct primitive.

## Consequences

### Positive

- One source of truth in the TypeScript file.
- Zero runtime overhead — the CJS file is `require()`'d once per hook
  invocation with standard Node resolution.
- The file structure is now documented honestly. Future reviewers don't burn
  time investigating a non-existent sandbox.

### Negative

- A developer who edits only `patterns.ts` and forgets to run `tsc` will leave
  Claude Code hooks on stale patterns until the next release build. Mitigation:
  the regen command is now documented in the README troubleshooting section,
  and `hooks/lib/patterns.js` starts with a header comment pointing at the TS
  source.

### Neutral

- The OpenCode plugin continues to `import` from `./patterns` (TypeScript),
  not from the CJS artifact. The two files are structurally identical; either
  could be treated as the source of truth, but TypeScript wins on ergonomics.

## References

- Review finding H2: `plans/reports/review-260417-1631-full-codebase.md`
- Fix commit: `3db4e6e docs: correct patterns.js architecture and permission.ask references`
- Authoritative file: `hooks/lib/patterns.js` (verify with `head -5 hooks/lib/patterns.js`
  — should show the `"use strict"; Object.defineProperty(exports, "__esModule", ...)` TS-emit header)
