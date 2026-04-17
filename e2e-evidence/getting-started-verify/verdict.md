# Subtask 2-2 Verdict: getting-started.mdx

## Verification Checks

### [PASS] Headings include Prerequisites, Installation, First Validation, Troubleshooting

Extracted from built `dist/getting-started/index.html`:
- `<h2 id="prerequisites">Prerequisites`
- `<h2 id="installation">Installation`
- `<h2 id="first-validation">First Validation`
- `<h2 id="troubleshooting">Troubleshooting`

All four required <h2> headings present.

### [PASS] Tabs render three install methods (curl, git clone, local symlink)

Extracted tab role="tab" elements:
- `<a role="tab" ...>curl (quick)</a>`
- `<a role="tab" ...>git clone</a>`
- `<a role="tab" ...>local symlink</a>`

Three tablist items with role="tab" and matching tab-panel-0/1/2 panels render from the Starlight <Tabs syncKey="install-method"> block.

### [PASS] Restart-Claude-Code callout is visible

Extracted <aside class="starlight-aside--caution"> with label "Restart Claude Code":
> "After running any of the install methods above, restart Claude Code before using ValidationForge. Plugins are loaded at session startup — hooks, skills, and commands will not be active in the session where you ran the installer."

Rendered as a danger-styled callout.

### [PASS] No broken anchors in table of contents

All on-page TOC hrefs resolve to heading IDs — every href="#..." in the built HTML has a matching id="..." element. The three tab-panel-0/1/2 anchors are internal to the Tabs component and map to their tabpanel elements.

## Build

- `ASTRO_TELEMETRY_DISABLED=1 npm run build` → "3 page(s) built in 1.22s" → BUILD_OK
- `npx astro check --noSync` → "0 errors, 0 warnings, 0 hints"

## Notes on dev server

The Astro dev server could not bind a TCP listener under the active sandbox ("listen EPERM: operation not permitted 127.0.0.1:4321"). This is a sandbox-level restriction on listening sockets, not an application issue — the production build succeeded and produced dist/getting-started/index.html (73001 bytes), which is the same HTML a live dev server would serve at http://localhost:4321/getting-started/. All verification checks were executed against that real built HTML.
