# Install-time Security Posture

**Scope:** ValidationForge is primarily distributed by (a) the official Claude
Code marketplace path (`/plugin marketplace add krzemienski/validationforge`),
and (b) a secondary curl-pipe installer (`bash install.sh`). This document
enumerates the security controls present in option (b) — the more audit-relevant
surface — so administrators and auditors can review them in one place.

**Last-verified:** 2026-04-17 against `install.sh` + `uninstall.sh` at commit
`3a796d6` (`v1.0.0`).

---

## Threat model

The installer is invoked via `curl | bash`, runs under the current user (no root
privileges), and performs:

1. A `git clone` of a remote repository.
2. A symlink creation under `~/.claude/plugins/cache/`.
3. Copies of rule markdown files into `~/.claude/rules/`.
4. A write to `~/.claude/installed_plugins.json`.
5. Optional: creation of `e2e-evidence/` in the current git repo.

Primary threats considered:

| # | Threat | Control |
|---|---|---|
| T1 | Source repository compromise (hostile `main` branch) | Tag-pinned clone (`T2`) |
| T2 | Mutable ref attack (clone of `main` when a specific release was expected) | **Tag pin** — clone resolves `v$VF_VERSION` by default |
| T3 | MITM on curl — attacker-controlled `VF_SOURCE` pre-seeded in shell profile | **Source allowlist** — `https://github.com/*` only by default |
| T4 | TOCTOU on plugin-cache symlink (attacker pre-plants a symlink at cache path) | **Atomic `ln -sfn` + ownership check** |
| T5 | Race-condition corruption of `installed_plugins.json` during concurrent installers | **tempfile + `os.replace` + `fcntl.flock`** |
| T6 | World-writable `/tmp` race on install directory | `/tmp` requires explicit opt-in |
| T7 | Uninstall destroying user-authored rule files named `vf-*.md` | **Rules manifest** — uninstall only removes files `install.sh` tracked |

---

## Controls

### 1. Tag-pinned clone (T1, T2)

`install.sh` resolves the clone target via `$VF_REF` (default `v$VF_VERSION`,
which defaults to `v1.0.0`):

```bash
VF_VERSION="${VF_VERSION:-1.0.0}"
VF_REF="${VF_REF:-v${VF_VERSION}}"

git clone --depth 1 --branch "$VF_REF" "$REPO" "$INSTALL_DIR"
# fallback to default branch only if the tag is missing
```

If the published tag is absent (e.g., during development), the installer
warns and falls back to the default branch — but the warn-and-fallback is
observable in the script output, not silent.

**Override:** `VF_REF=feature-branch bash install.sh` for dev installs.

### 2. Source URL allowlist (T3)

`$VF_SOURCE` must be an `https://github.com/` URL. Otherwise install refuses:

```bash
case "$REPO" in
  https://github.com/*) ;;
  *) die "VF_SOURCE must be an https://github.com/ URL. Got: $REPO. Set VF_ALLOW_ALT_SOURCE=1 to override." ;;
esac
```

**Override:** `VF_ALLOW_ALT_SOURCE=1 VF_SOURCE=https://gitlab.corp/... bash install.sh`
(explicit opt-in required).

### 3. Install-directory allowlist (T6)

`$INSTALL_DIR` must be under `$HOME/`. Shared temp paths are refused unless
explicitly allowed:

```bash
case "$INSTALL_DIR" in
  "$HOME"/*) ;;
  /tmp/*|/private/tmp/*|…)
    [ "${VF_ALLOW_TMP_INSTALL:-0}" = "1" ] || die "..."
    ;;
  *) die "INSTALL_DIR must be under \$HOME ..." ;;
esac
```

### 4. Atomic plugin-cache symlink (T4)

Prior implementation used `rm + ln -s`, which has a TOCTOU window between the
two operations. Current implementation uses `ln -sfn` (atomic replace) and
refuses to proceed if an existing path at the cache location is not a symlink
or is owned by a different user:

```bash
if [ -e "$PLUGIN_CACHE_DIR" ] || [ -L "$PLUGIN_CACHE_DIR" ]; then
  [ -L "$PLUGIN_CACHE_DIR" ] || die "not a symlink — manual cleanup required"
  owner=$(python3 -c '…lstat.st_uid → getpwuid.pw_name' "$PLUGIN_CACHE_DIR")
  [ "$owner" = "$USER" ] || die "existing symlink owned by '$owner'"
fi
ln -sfn "$INSTALL_DIR" "$PLUGIN_CACHE_DIR"
```

### 5. Atomic registry write (T5)

`~/.claude/installed_plugins.json` is written via a Python heredoc that:

1. Acquires `fcntl.LOCK_EX` on `installed_plugins.json.lock`.
2. Reads the current registry (or `{}` on absence/corruption).
3. Writes the updated registry to a `tempfile.mkstemp()` in the same directory,
   `fsync`s the fd, then `os.replace()`s it over the real file.
4. Releases the lock on context exit.

This protects against concurrent `install.sh`/`uninstall.sh` runs truncating
each other's output.

### 6. Rules manifest (T7)

`install.sh` records every rule file it copies into `~/.claude/.vf-rules-manifest.txt`:

```bash
for rule_file in "$INSTALL_DIR"/rules/*.md; do
  target="${RULES_DIR}/vf-${rule_name}.md"
  cp "$rule_file" "$target"
  echo "$target" >> "$RULES_MANIFEST"
done
```

`uninstall.sh` reads that manifest and removes only files it finds in the
list, with a path-prefix check (`case "$rule_target" in "${RULES_DIR}/"*)`)
to reject manifest tampering. Falls back to the `vf-*.md` glob with a loud
warning if the manifest is missing.

---

## What this doc does *not* cover

- **Supply-chain integrity of the `git clone`** — the installer trusts that
  whoever pushed `v$VF_VERSION` to GitHub is legitimate. A full SLSA-level
  attestation pipeline is future work.
- **Marketplace path** — the `/plugin marketplace add …` path runs inside
  Claude Code's plugin sandbox, not the shell. Its threat model is distinct
  and is the responsibility of Claude Code, not this document.
- **Runtime hook safety** — covered by the hook design (pure stdin/stdout, no
  `eval`, no `child_process.exec` on tool input). See `ARCHITECTURE.md`.
- **Secrets** — none in tree. Installed config (`~/.claude/.vf-config.json`)
  does not contain credentials.

## How to re-verify

```bash
# Syntax check
bash -n install.sh && bash -n uninstall.sh

# Python heredoc validity
python3 -c "import ast; open('install.sh').read()"   # (extract + parse block)

# Dry-run the allowlists
VF_SOURCE=http://evil.corp bash install.sh       # expect: die
VF_ALLOW_ALT_SOURCE=1 VF_SOURCE=https://corp.git/fork bash install.sh  # expect: proceed
VF_INSTALL_DIR=/tmp/vf bash install.sh           # expect: die
VF_ALLOW_TMP_INSTALL=1 VF_INSTALL_DIR=/tmp/vf bash install.sh          # expect: proceed
```

## Related

- Review finding set addressing these: H3, H4, M5, M6, L2 in
  `plans/reports/review-260417-1631-full-codebase.md`.
- Fix commit: `4b2dc6d security(install): pin ref, allowlist source, atomic symlink and JSON writes`.
