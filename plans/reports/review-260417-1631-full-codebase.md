# ValidationForge — Full Codebase Review

**Date:** 2026-04-17 16:31
**Target:** Entire codebase, staged + working tree (8 modified files staged)
**Branch:** `main` at `a92e3b9` (pre-review HEAD)
**Repo:** `/Users/nick/Desktop/validationforge` · 2,708 tracked files
**Reviewers (parallel):** Security · Compatibility · Quality · Performance · Accessibility
**Mode:** Standard (fire-and-forget subagents, non-overlapping scopes)

**Authoritative specs fetched live:**
- Claude Code plugin spec — `code.claude.com/docs/en/plugins` (post-redirect)
- OpenCode plugin spec — `opencode.ai/docs/plugins`

---

## Verdict: REQUEST CHANGES

1 CRITICAL · 10 HIGH · 8 MEDIUM · 6 LOW (24 surfaced; 9 additional noted in reviewer transcripts trimmed for signal)

| Severity | Count | Must fix before |
|---|---|---|
| 🔴 CRITICAL | 1 | merge / publish |
| 🟠 HIGH | 10 | next release |
| 🟡 MEDIUM | 8 | 30-day hardening sprint |
| ⚪ LOW | 6 | backlog |

The plugin **loads cleanly on Claude Code** (Compatibility reviewer confirmed `.claude-plugin/` structure, `plugin.json` fields, `hooks/hooks.json` schema are all spec-correct). The **OpenCode half is silently broken** (C1, H1) — test-file blocking and custom tools both no-op. Significant **doc rot** in README/ARCHITECTURE around the hook bridge architecture. Perf hot path has room for a measurable 1-2s/session reduction.

---

## Executive Summary

### What's working
- **Claude Code plugin manifest + hook schema are spec-compliant.** `.claude-plugin/` contains only `plugin.json` (no anti-pattern nesting). `hooks/hooks.json` uses valid `PreToolUse`/`PostToolUse` events with correct `{matcher, hooks:[{type,command}]}` shape and `${CLAUDE_PLUGIN_ROOT}` path references.
- **Inventory matches reality.** 52 skills · 19 commands · 7 agents · 9 rules — all four counts verified on disk.
- **No shell injection in hook stdin handling.** All hooks are pure `stdin → regex → stdout/stderr`, no `eval`, no `child_process.exec` on user input, no network I/O.
- **Fail-open hook design** — hooks catch their own exceptions and exit 0, so a bad payload cannot wedge Claude Code.
- **Primary contrast is excellent** on both HTML artifacts — 17.8:1 and 16.3:1 body text, well above WCAG AAA.

### What's broken
- **OpenCode plugin is silently dead** for its headline feature (test-file blocking via `permission.ask`) and its custom tools (wrong `tool()` helper shape).
- **README and ARCHITECTURE describe a hook architecture that doesn't match the code** — the "CommonJS bridge via `vm.runInNewContext`" narrative is fiction; actual file is `hooks/lib/patterns.js` (plain CJS, no sandbox).
- **Two redundant config loaders** (`resolve-profile.js`, `config-loader.js`) run synchronous fs on every tool call.
- **No keyboard focus indicators** on either marketing HTML artifact — screen-shared deck is keyboard-inaccessible.

---

## Findings Summary Table

| ID | Sev · Conf | Perspective | Finding | Location |
|---|---|---|---|---|
| **C1** | CRIT · HIGH | Compat | Invalid OpenCode event `permission.ask` | `.opencode/plugins/validationforge/index.ts:70` |
| **H1** | HIGH · HIGH | Compat | `tool()` helper signature / import path wrong | `.opencode/plugins/validationforge/index.ts:2,19-66` |
| **H2** | HIGH · HIGH | Quality | README+ARCHITECTURE describe phantom `hooks/patterns.js` | `README.md:207,335,409-411`; `ARCHITECTURE.md:43,204-213` |
| **H3** | HIGH · HIGH | Security | Curl-pipe install with no checksum / tag pinning | `install.sh:1-3,32` |
| **H4** | HIGH · MED | Security | Symlink TOCTOU in cache-dir relink | `install.sh:39-42` |
| **H5** | HIGH · HIGH | Perf | Every hook re-reads config JSON synchronously | `hooks/lib/resolve-profile.js:46,59`; `config-loader.js:60,79` |
| **H6** | HIGH · HIGH | Perf | Two parallel config-resolution systems loaded | `hooks/lib/config-loader.js` vs `resolve-profile.js` |
| **H7** | HIGH · HIGH | Quality | `forge-execute` marked "[planned V2.0]" but ships | `README.md` + `commands/forge-execute.md` + `skills/forge-execute/SKILL.md` |
| **H8** | HIGH · HIGH | Quality | Duplicate phase-gate rules | `rules/execution-workflow.md` vs `rules/forge-execution.md` |
| **H9** | HIGH · HIGH | Quality | Weak trigger on `consensus-engine` skill | `skills/consensus-engine/SKILL.md:2` |
| **H10** | HIGH · HIGH | A11y | `--text-dimmer` fails 4.5:1 body contrast (3.4:1) | `validationforge-hyper-marketing.html:30` |
| **H11** | HIGH · HIGH | A11y | No `:focus-visible` styles anywhere | both HTML artifacts |
| **M1** | MED · HIGH | Compat | Empty `event` handler is dead code | `.opencode/plugins/validationforge/index.ts:154-157` |
| **M2** | MED · MED | Compat | `PreToolUse` matcher `TaskUpdate` unverified | `hooks/hooks.json:14` |
| **M3** | MED · HIGH | Security | ReDoS risk in `MOCK_PATTERNS` greedy regex | `hooks/lib/patterns.js:57-62` |
| **M4** | MED · HIGH | Security | Evidence check uses CWD-relative path | `hooks/completion-claim-validator.js:14,39` |
| **M5** | MED · MED | Security | Unvalidated `VF_SOURCE` / `/tmp` install path | `install.sh:7-8,20-23` |
| **M6** | MED · HIGH | Security | Non-atomic JSON write to `installed_plugins.json` | `install.sh:89-110` |
| **M7** | MED · HIGH | Perf | `mock-detection` uses `.filter` instead of `.some` | `hooks/mock-detection.js:42` |
| **M8** | MED · MED | A11y | Reduced-motion overrides miss infinite animations | marketing `:274,710`; deck `:276` |
| **L1** | LOW · HIGH | Compat | Agent frontmatter missing `name` | `agents/*.md` |
| **L2** | LOW · HIGH | Security | `uninstall.sh` glob removes user-authored `vf-*.md` | `uninstall.sh:76-81` |
| **L3** | LOW · MED | Security | OpenCode `readdirSync` no path-traversal guard | `.opencode/plugins/validationforge/index.ts:48-64` |
| **L4** | LOW · HIGH | Perf | Allowlist regex not pre-compiled | `hooks/block-test-files.js:45-47` |
| **L5** | LOW · HIGH | A11y | Deck dot-nav buttons lack `aria-label` | `validationforge-hyper-deck.html:1686` (runtime) |
| **L6** | LOW · MED | A11y | Links rely on color-only differentiation | marketing `:83` |

---

## Detail — Findings Requiring Code

### C1 · [CRITICAL · HIGH] Invalid OpenCode hook event `permission.ask`

**Location:** `.opencode/plugins/validationforge/index.ts:70`

**Issue:** OpenCode's documented event surface is `permission.asked` / `permission.replied` (past tense). The plugin registers `"permission.ask"` — the handler never fires, and test-file blocking (VF's headline feature) silently no-ops on OpenCode.

**Fix:** Move the gate to `tool.execute.before`, which is the correct enforcement point regardless of permission flow:

```diff
- "permission.ask": async (input, output) => {
-   const toolName = input.tool?.toLowerCase() || "";
-   if (!["write", "edit", "multiedit"].includes(toolName)) return;
-   const filePath = input.args?.file_path || "";
-   if (isBlockedTestFile(filePath)) { /* deny */ }
- }
+ "tool.execute.before": async (input, output) => {
+   const toolName = (input as any).tool?.toLowerCase() || "";
+   if (!["write", "edit", "multiedit"].includes(toolName)) return;
+   const filePath = (input as any).args?.file_path || "";
+   if (isBlockedTestFile(filePath)) {
+     throw new Error("ValidationForge: test/mock files are blocked under src/ or lib/.");
+   }
+ }
```

---

### H1 · [HIGH · HIGH] `tool.schema.string()` / `@opencode-ai/plugin/tool` import shape wrong

**Location:** `.opencode/plugins/validationforge/index.ts:2,19-66`

**Issue:** Uses `tool.schema.string()` and imports from `"@opencode-ai/plugin/tool"`. OpenCode's documented API takes `zod` schemas directly; `tool.schema.*` is not part of the public surface. Registered custom tools (`vf_validate`, `vf_check_evidence`) will fail to register, producing a silent degradation alongside C1.

**Fix:**

```diff
- import { tool } from "@opencode-ai/plugin/tool"
+ import { type Plugin, tool } from "@opencode-ai/plugin"
+ import { z } from "zod"

  vf_validate: tool({
    description: "...",
-   args: {
-     platform: tool.schema.string(),
-     scope: tool.schema.string(),
-   },
+   args: z.object({
+     platform: z.string().optional(),
+     scope: z.string().optional(),
+   }),
    async execute(args, ctx) { /* ... */ }
  })
```

---

### H2 · [HIGH · HIGH] Architecture docs describe a hook bridge that does not exist

**Location:** `README.md:207,335,409-411`; `ARCHITECTURE.md:43,204-213`

**Issue:** Both documents repeatedly describe `hooks/patterns.js` as "CommonJS bridge: loads `patterns.ts` for CC hooks via `vm` sandbox" and give troubleshooting guidance for "patterns.js bridge failure" with `vm.runInNewContext`. The actual file lives at `hooks/lib/patterns.js` (plain pre-compiled CJS — verified by `ls hooks/lib/`). No `vm.runInNewContext` call exists anywhere in the repo. Two independent reviewers (Security and Performance) initially wasted scope investigating a sandbox-escape that cannot occur.

**Fix:** Correct all three narratives:
1. `README.md:207` — remove the bridge table row or rewrite: `lib/patterns.js · Shared pattern library · require()'d by all 7 hooks.`
2. `README.md:335` — file-structure tree should show `hooks/lib/patterns.js`, not `hooks/patterns.js`.
3. `README.md:409-411` + `ARCHITECTURE.md:43,204-213` — delete the entire "patterns.js bridge failure" troubleshooting section and "CommonJS bridge using vm.runInNewContext()" narrative. Replace with: "Patterns are defined once in `hooks/lib/patterns.js` and imported by CC hooks; the OpenCode plugin imports from `.opencode/plugins/validationforge/patterns.ts` as a parallel source of truth. The two are hand-kept-in-sync."

---

### H3 · [HIGH · HIGH] Curl-pipe install with no checksum or tag pinning

**Location:** `install.sh:1-3,32`

**Issue:** README documents `curl -fsSL ... | bash` with `git clone` against a mutable `main` branch. Any repo compromise (or MITM of a user who pre-seeds `VF_SOURCE`) yields arbitrary code execution under the user's account — rules are copied to `~/.claude/rules/`, symlink lands in plugin cache, and Claude Code loads the plugin on next start.

**Fix:** (a) Publish release tarballs with SHA256 sums. (b) Pin clone to a tag: `git clone --branch v1.0.0 --depth 1`. (c) Document `curl ... | sha256sum -c - && bash` verification. (d) Reject `VF_SOURCE` unless it matches an allowlist or require explicit `--trusted-source` flag.

---

### H5 · [HIGH · HIGH] Every hook re-reads config JSON synchronously

**Location:** `hooks/lib/resolve-profile.js:46,59`; `hooks/lib/config-loader.js:60,79`

**Issue:** Each hook startup does two `readFileSync` calls (user `~/.claude/.vf-config.json` + profile JSON). Seven hooks are wired to `Write`/`Edit`/`Bash`/`TaskUpdate`. Every one of those tool calls spawns a Node process (cold-start ~40-80ms on Darwin) + this I/O. No memoization, no env-var fast path.

**Estimated cost:** ~2-5ms × 7 hooks × 50 tool calls/session ≈ 700ms-1.7s/session of avoidable I/O.

**Fix:**
1. Skip disk entirely when `VF_PROFILE=standard` matches in-code `STANDARD_DEFAULTS`.
2. Accept `VF_PROFILE_JSON` env var with pre-resolved config injected by Claude Code once per session.
3. Move `DISABLE_OMC` / `VF_SKIP_HOOKS` kill-switch check to line 1 of each hook, before any `require()`.

---

### H11 · [HIGH · HIGH] No `:focus-visible` styles on any interactive element

**Location:** `validationforge-hyper-marketing.html` (zoom buttons :1309-1312, TOC links, footer buttons); `validationforge-hyper-deck.html` (dot nav :1686, code blocks)

**Issue:** Zero `:focus` / `:focus-visible` rules in either file. Keyboard users get the UA default ring, which is often invisible on the near-black Hyper palette or stripped by implicit resets. Fails WCAG 2.4.7.

**Fix (one line per file):**

```css
a:focus-visible, button:focus-visible {
  outline: 2px solid var(--green);   /* marketing: var(--pink) */
  outline-offset: 2px;
  border-radius: 4px;
}
```

---

## Cross-reviewer strengths (what VF does well)

1. **No arbitrary-code-execution surface in hooks.** Every one of the 7 CC hooks is pure stdin→regex→stdout. No `eval`, no `exec`, no network, no `vm`. The earlier `vm.runInNewContext` concern was only a doc artifact (see H2).
2. **Hook contract is spec-correct on the Claude Code side.** Correct event names, `{matcher, hooks:[{type:"command", command:"..."}]}` shape, `${CLAUDE_PLUGIN_ROOT}` referenced properly, `|| true` failsafes in place.
3. **Inventory integrity.** 52 skills / 19 commands / 7 agents / 9 rules all verified on disk; every command's "primary skill" cross-reference resolves; no broken doc references found in `rules/` or `skills/`.
4. **Primary text contrast is AAA-grade** on both HTML artifacts (17.8:1 marketing, 16.3:1 deck).
5. **Semantic landmarks used correctly** on marketing: `<nav aria-label>`, `<main>`, `<section>`, `<article>`, `<footer>`.
6. **Defense-in-depth in installer:** `INSTALL_DIR` allowlist check against `$HOME`/tmp, rules copied to user-scoped `~/.claude/rules/`, no root required.
7. **Fail-open hook design** — catch-and-exit-0 on exception means a malformed tool payload cannot brick Claude Code.
8. **Env kill switches** (`DISABLE_OMC`, `VF_SKIP_HOOKS`) provide a clean emergency-disable path.
9. **Shared `patterns.js` / `patterns.ts`** as a single source of truth between CC hooks and OpenCode plugin — excellent architecture, even if the docs mis-describe it.
10. **Trigger-rich skill descriptions** on the most-used skills (`e2e-validate`, `preflight`, `create-validation-plan`, `forge-setup`, `functional-validation`) — these follow the "Use when ... reach for it on phrases ..." pattern that drives reliable auto-invocation.

---

## Unresolved questions

- **`forge-execute` runtime state** — is the command a functional implementation or a stub? Needed to resolve H7 (remove the "planned" marker vs delete the files).
- **OpenCode `tool()` subpath import** — is `"@opencode-ai/plugin/tool"` valid in the installed package version, or only `"@opencode-ai/plugin"`? Local `npm ls` in `.opencode/plugins/validationforge/` would settle it.
- **`TaskUpdate` as a Claude Code tool name** — does a PreToolUse matcher of `TaskUpdate` fire in current CC? Needs live probe.
- **Marketplace `source: "./"` pattern** — is this the valid shape for a self-contained git-root marketplace, or does it require the object form `{source:"git", url:...}`? Compatibility reviewer flagged it MEDIUM with HIGH confidence; live test is the only resolver.
- **`docs/case-studies/` cardinality** — README uses plural phrasing; directory appears to contain only `self-validation.md`. Minor copy fix.

---

## Methodology notes

- **Git hygiene:** Before review, working tree was staged (`git add -A`), producing 8 modified files (+126/-58). No untracked files existed, so no secret-leak risk from blind staging.
- **Specs pulled live**, not relied on from training data, for both Claude Code (`code.claude.com/docs/en/plugins` after 301 redirect) and OpenCode (`opencode.ai/docs/plugins`).
- **Reviewer scoping** — the 5 perspectives had non-overlapping file scopes, so no dedup pass was needed. Two cross-cutting findings (patterns.js doc rot, `permission.ask` typo) surfaced because two reviewers each performed independent verification — both verified in the final grep pass (see "Verified claims" below).
- **Evidence-examined citations:** file:line pairs in the findings table were either (a) read directly by me prior to reviewer dispatch, (b) quoted verbatim from reviewer output, or (c) verified by my own final grep pass (C1, H1, H2, marketplace.json shape). Any reviewer claim I could not verify myself is marked with MED confidence.
