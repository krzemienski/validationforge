# Contributing to ValidationForge

Thank you for contributing to ValidationForge — a no-mock functional validation platform for Claude Code and OpenCode.

## Table of Contents

- [Version Compatibility Matrix](#version-compatibility-matrix)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [OpenCode Plugin Setup](#opencode-plugin-setup)
- [Updating Pinned Versions](#updating-pinned-versions)
- [Why We Pin Versions](#why-we-pin-versions)
- [Development Workflow](#development-workflow)
- [Iron Rules for Contributors](#iron-rules-for-contributors)

---

## Version Compatibility Matrix

The OpenCode plugin depends on `@opencode-ai/plugin` and `@opencode-ai/sdk`. Both are pinned to exact versions to ensure every contributor installs the same tested release.

| ValidationForge | @opencode-ai/plugin | @opencode-ai/sdk | Node.js | TypeScript |
|:--------------:|:-------------------:|:----------------:|:-------:|:----------:|
| ≥ 1.0.0        | 1.4.0               | 1.4.0            | ≥ 18    | ≥ 5.5     |

> **Note:** Do not replace pinned versions with `latest`. See [Why We Pin Versions](#why-we-pin-versions).

---

## Prerequisites

- **git** ≥ 2.30
- **Node.js** ≥ 18 (with `npm` ≥ 9)
- **Claude Code** (for the Claude Code plugin)
- **OpenCode** (for the OpenCode plugin)

Verify your environment:

```bash
git --version
node --version
npm --version
```

---

## Getting Started

### Clone the Repository

```bash
git clone https://github.com/krzemienski/validationforge
cd validationforge
```

### Install Claude Code Plugin Dependencies

The Claude Code plugin has no separate `package.json` — hooks are pure JavaScript and rules are plain Markdown. No `npm install` is required for this side.

### Install the OpenCode Plugin Dependencies

The OpenCode plugin lives in `.opencode/plugins/validationforge/` and has its own `package.json` with pinned versions.

```bash
cd .opencode/plugins/validationforge
npm ci           # Installs exact versions from package-lock.json
```

`npm ci` (not `npm install`) is required because it respects the lockfile and refuses to install if `package-lock.json` is out of sync with `package.json`.

---

## OpenCode Plugin Setup

After installing dependencies, build the TypeScript plugin:

```bash
cd .opencode/plugins/validationforge
npm run build    # Compiles index.ts -> dist/
```

Then register the plugin in your project's `opencode.json`:

```json
{
  "plugins": [
    ".opencode/plugins/validationforge"
  ]
}
```

Verify the plugin registers correctly by starting OpenCode and checking that `vf_validate` and `vf_check_evidence` tools appear in the session.

---

## Updating Pinned Versions

When the OpenCode SDK publishes a new release and you have verified it does not break ValidationForge:

1. **Check the changelog** at the `@opencode-ai/plugin` and `@opencode-ai/sdk` release pages before upgrading.

2. **Update `package.json`** in `.opencode/plugins/validationforge/`:

   ```bash
   cd .opencode/plugins/validationforge
   npm install @opencode-ai/plugin@<new-version> @opencode-ai/sdk@<new-version>
   ```

   This rewrites both `package.json` and `package-lock.json`.

3. **Update the compatibility matrix** in this file (`CONTRIBUTING.md`) to reflect the new tested versions.

4. **Run the full validation suite** to confirm nothing broke:

   ```bash
   /validate-ci
   ```

5. **Open a pull request** that includes both the dependency change and the updated matrix. PRs that update pinned versions without updating the matrix will not be merged.

---

## Why We Pin Versions

ValidationForge depends on `@opencode-ai/plugin` and `@opencode-ai/sdk` at the boundary between our code and OpenCode's runtime. A silent breaking change in those packages could:

- Change the hook API signatures our plugin registers (`permission.ask`, `tool.execute.after`, `shell.env`)
- Rename or remove fields our code reads from tool-call events
- Alter TypeScript types in ways that produce runtime errors not caught at compile time

Using `"latest"` means `npm install` in a fresh clone could pull a version we have never tested. Pinning to an exact version string (e.g., `1.4.0`) guarantees every contributor, CI run, and production deploy uses the same code.

This is standard practice for production software with upstream dependencies that ship breaking changes between minor or patch releases.

---

## Development Workflow

### Branch Strategy

```
main          Production-ready releases
feature/*     New features — branch from main
fix/*         Bug fixes — branch from main
```

### Making Changes

1. Fork the repository and create a branch:

   ```bash
   git checkout -b feature/my-change
   ```

2. Make your changes following the patterns in existing files.

3. Verify hook functionality:

   ```bash
   node scripts/verify-hooks.js
   ```

4. Verify the OpenCode plugin still builds:

   ```bash
   cd .opencode/plugins/validationforge && npm run build
   ```

5. Verify the dependency pins are intact:

   ```bash
   node -e "const p=require('./.opencode/plugins/validationforge/package.json'); \
     const ok=p.dependencies['@opencode-ai/plugin']==='1.4.0' && \
              p.dependencies['@opencode-ai/sdk']==='1.4.0'; \
     console.log(ok ? 'PINNED' : 'FAIL')"
   ```

6. Commit and open a pull request.

### Commit Style

Use a short imperative subject line:

```
pin @opencode-ai/plugin and @opencode-ai/sdk to 1.4.0
add version compatibility matrix to CONTRIBUTING.md
fix hook registration for tool.execute.after events
```

---

## Iron Rules for Contributors

These mirror ValidationForge's own validation philosophy:

1. **No mocks** — Do not add `jest.mock`, `sinon.stub`, `unittest.mock`, or any test double.
2. **No test files** — Do not create `*.test.*`, `*.spec.*`, `__tests__/`, or `__mocks__/` directories.
3. **Evidence-backed PRs** — If your PR changes validation behavior, include real output (build logs, CLI output, screenshots) in the PR description.
4. **Pin, don't float** — Never change a pinned dependency to `latest` or a range (`^`, `~`).
5. **Update the matrix** — Any dependency version change must be accompanied by an update to the [Version Compatibility Matrix](#version-compatibility-matrix).
