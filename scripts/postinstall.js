#!/usr/bin/env node
// ValidationForge post-install script
// Runs automatically after: npm install -g validationforge
//
// Responsibilities:
//   1. Install rules to ~/.claude/rules/vf-*.md
//   2. Write/update ~/.claude/.vf-config.json (preserving user settings on upgrade)
//   3. Register plugin by symlinking ~/.claude/plugins/validationforge -> npm install dir
//
// Flags:
//   --dry-run   Print what would happen without writing any files

'use strict';

const fs   = require('fs');
const path = require('path');
const os   = require('os');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function info(msg)  { process.stdout.write(`[VF] ${msg}\n`); }
function warn(msg)  { process.stderr.write(`[VF] WARNING: ${msg}\n`); }
function ok(msg)    { process.stdout.write(`[VF] OK: ${msg}\n`); }

// ---------------------------------------------------------------------------
// Parse flags
// ---------------------------------------------------------------------------

const DRY_RUN = process.argv.includes('--dry-run');

if (DRY_RUN) {
  info('Dry-run mode — no files will be written');
}

// ---------------------------------------------------------------------------
// Paths
// ---------------------------------------------------------------------------

// __dirname resolves to <npm-install-root>/scripts — step one level up to get
// the package root regardless of how npm resolves the global prefix.
const INSTALL_DIR   = path.resolve(__dirname, '..');
const HOME          = os.homedir();
const CLAUDE_DIR    = path.join(HOME, '.claude');
const RULES_DIR     = path.join(CLAUDE_DIR, 'rules');
const PLUGINS_DIR   = path.join(CLAUDE_DIR, 'plugins');
const PLUGIN_LINK   = path.join(PLUGINS_DIR, 'validationforge');
const CONFIG_FILE   = path.join(CLAUDE_DIR, '.vf-config.json');
const RULES_SOURCE  = path.join(INSTALL_DIR, 'rules');

// ---------------------------------------------------------------------------
// Guard: rules directory must exist in the package
// ---------------------------------------------------------------------------

if (!fs.existsSync(RULES_SOURCE)) {
  warn(`Rules source directory not found: ${RULES_SOURCE}`);
  warn('The npm package may be incomplete. Try reinstalling: npm install -g validationforge');
  process.exit(1);
}

// ---------------------------------------------------------------------------
// 1. Install rules to ~/.claude/rules/vf-*.md
// ---------------------------------------------------------------------------

info(`Installing rules to ${RULES_DIR} ...`);

if (!DRY_RUN) {
  fs.mkdirSync(RULES_DIR, { recursive: true });
}

const ruleFiles = fs.readdirSync(RULES_SOURCE).filter(f => f.endsWith('.md'));
let rulesInstalled = 0;

for (const ruleFile of ruleFiles) {
  const src    = path.join(RULES_SOURCE, ruleFile);
  const name   = path.basename(ruleFile, '.md');
  const target = path.join(RULES_DIR, `vf-${name}.md`);

  if (DRY_RUN) {
    info(`  would copy ${src} -> ${target}`);
  } else {
    fs.copyFileSync(src, target);
    rulesInstalled++;
  }
}

if (!DRY_RUN) {
  ok(`${rulesInstalled} rule(s) installed to ${RULES_DIR}`);
}

// ---------------------------------------------------------------------------
// 2. Write/update ~/.claude/.vf-config.json (upgrade-safe)
// ---------------------------------------------------------------------------

info(`Updating config at ${CONFIG_FILE} ...`);

// Load existing config so we can preserve user-set fields (enforcement, platform, projectPath, etc.)
let existing = {};
if (fs.existsSync(CONFIG_FILE)) {
  try {
    existing = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
    info('  Existing config found — preserving user settings');
  } catch (err) {
    warn(`Could not parse existing config (will overwrite): ${err.message}`);
    existing = {};
  }
}

// Merge: keep all existing fields, overwrite/add the fields we manage
const config = Object.assign({}, existing, {
  setupCompleted : new Date().toISOString(),
  setupVersion   : (function () {
    try {
      return require(path.join(INSTALL_DIR, 'package.json')).version;
    } catch (_) {
      return '1.0.0';
    }
  })(),
  installDir : INSTALL_DIR,
  scope      : existing.scope || 'global',
});

if (DRY_RUN) {
  info(`  would write config: ${JSON.stringify(config, null, 2)}`);
} else {
  fs.mkdirSync(path.dirname(CONFIG_FILE), { recursive: true });
  fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2) + '\n', 'utf8');
  ok(`Config saved to ${CONFIG_FILE}`);
}

// ---------------------------------------------------------------------------
// 3. Register plugin — symlink ~/.claude/plugins/validationforge -> INSTALL_DIR
// ---------------------------------------------------------------------------

info(`Registering plugin at ${PLUGIN_LINK} ...`);

if (!DRY_RUN) {
  fs.mkdirSync(PLUGINS_DIR, { recursive: true });

  // Remove any existing entry (old symlink, broken link, or directory copy).
  // Use lstatSync (not existsSync) so we can detect broken symlinks.
  let existingStat = null;
  try { existingStat = fs.lstatSync(PLUGIN_LINK); } catch (_) { /* does not exist */ }

  if (existingStat) {
    if (existingStat.isSymbolicLink() || existingStat.isFile()) {
      fs.unlinkSync(PLUGIN_LINK);
    } else if (existingStat.isDirectory()) {
      fs.rmSync(PLUGIN_LINK, { recursive: true, force: true });
    }
  }

  try {
    fs.symlinkSync(INSTALL_DIR, PLUGIN_LINK, 'dir');
    ok(`Plugin symlink created: ${PLUGIN_LINK} -> ${INSTALL_DIR}`);
  } catch (err) {
    // Symlink creation can fail on some systems (e.g. Windows without admin rights).
    // Fall back to writing a JSON pointer file Claude Code can read.
    warn(`Could not create symlink (${err.message}); falling back to pointer file`);
    fs.writeFileSync(
      PLUGIN_LINK + '.json',
      JSON.stringify({ pluginPath: INSTALL_DIR }, null, 2) + '\n',
      'utf8'
    );
    ok(`Plugin pointer written: ${PLUGIN_LINK}.json`);
  }
} else {
  info(`  would symlink ${PLUGIN_LINK} -> ${INSTALL_DIR}`);
}

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------

info('');
info('=== ValidationForge Installed ===');
info('');
info(`  Plugin:  ${INSTALL_DIR}`);
info(`  Rules:   ${RULES_DIR}/vf-*.md`);
info(`  Config:  ${CONFIG_FILE}`);
info('');
info('  Commands:');
info('    /validate          Full validation pipeline');
info('    /validate-plan     Plan validation journeys');
info('    /validate-audit    Read-only audit');
info('    /validate-fix      Fix and re-validate');
info('    /validate-ci       CI/CD mode');
info('    /vf-setup          Project-level setup wizard');
info('');
info('  Start with: /vf-setup in your project directory');
info('');
