#!/usr/bin/env node
// Helper for subtask-1-3 evidence: emit a stat table for every hook file
// referenced by hooks/hooks.json, resolved against the INSTALLED plugin root
// from ~/.claude/installed_plugins.json. Writes JSON to stdout.
const fs = require('fs');
const path = require('path');

const manifest = JSON.parse(fs.readFileSync('hooks/hooks.json', 'utf8'));
const reg = JSON.parse(
  fs.readFileSync(path.join(process.env.HOME, '.claude', 'installed_plugins.json'), 'utf8')
);
const installedRoot = reg['validationforge@validationforge'].path;
const worktreeRoot = process.cwd();

const refs = [];
for (const ev of Object.keys(manifest.hooks || {})) {
  for (const group of manifest.hooks[ev]) {
    for (const h of group.hooks || []) {
      refs.push({ event: ev, matcher: group.matcher, type: h.type, command: h.command });
    }
  }
}

const out = refs.map((r) => {
  const installedPath = r.command.replace('${CLAUDE_PLUGIN_ROOT}', installedRoot);
  const worktreePath = r.command.replace('${CLAUDE_PLUGIN_ROOT}', worktreeRoot);
  const row = {
    event: r.event,
    matcher: r.matcher,
    type: r.type,
    command_template: r.command,
    hook_basename: path.basename(installedPath),
    installed_path: installedPath,
    worktree_path: worktreePath,
  };
  try {
    const s = fs.statSync(installedPath);
    row.installed = {
      exists: true,
      is_file: s.isFile(),
      size_bytes: s.size,
      mode_octal: '0' + (s.mode & 0o777).toString(8),
      executable_by_owner: (s.mode & 0o100) !== 0,
      mtime: s.mtime.toISOString(),
    };
  } catch (e) {
    row.installed = { exists: false, error: e.message };
  }
  try {
    const s = fs.statSync(worktreePath);
    row.worktree = {
      exists: true,
      is_file: s.isFile(),
      size_bytes: s.size,
      mode_octal: '0' + (s.mode & 0o777).toString(8),
      executable_by_owner: (s.mode & 0o100) !== 0,
      mtime: s.mtime.toISOString(),
    };
  } catch (e) {
    row.worktree = { exists: false, error: e.message };
  }
  row.installed_and_worktree_size_match =
    row.installed.exists && row.worktree.exists && row.installed.size_bytes === row.worktree.size_bytes;
  return row;
});

process.stdout.write(JSON.stringify({ installed_root: installedRoot, worktree_root: worktreeRoot, refs: out }, null, 2));
