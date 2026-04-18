#!/usr/bin/env node
// ValidationForge CLI — exposed as `vf` after npm install -g validationforge
//
// Commands:
//   vf --version / vf -v     Print package version
//   vf status                Show plugin registration and rules status
//   vf install-rules         Copy rules into the current project or global ~/.claude/rules/
//   vf help                  List available commands
//
// The bin entry in package.json maps "vf" -> "bin/vf.js".
// npm sets the executable bit automatically; chmod +x on this file also works.

'use strict';

const fs   = require('fs');
const path = require('path');
const os   = require('os');

// ---------------------------------------------------------------------------
// Paths
// ---------------------------------------------------------------------------

// __dirname == <package-root>/bin, so step up once for the package root
const PKG_ROOT     = path.resolve(__dirname, '..');
const PKG_JSON     = path.join(PKG_ROOT, 'package.json');
const RULES_SOURCE = path.join(PKG_ROOT, 'rules');
const HOME         = os.homedir();
const CLAUDE_DIR   = path.join(HOME, '.claude');
const CONFIG_FILE  = path.join(CLAUDE_DIR, '.vf-config.json');
const GLOBAL_RULES = path.join(CLAUDE_DIR, 'rules');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function print(msg)  { process.stdout.write(msg + '\n'); }
function err(msg)    { process.stderr.write('[vf] ' + msg + '\n'); }

function readPkg() {
  try {
    return JSON.parse(fs.readFileSync(PKG_JSON, 'utf8'));
  } catch (_) {
    return { version: 'unknown', name: 'validationforge' };
  }
}

function readConfig() {
  if (!fs.existsSync(CONFIG_FILE)) return null;
  try {
    return JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
  } catch (_) {
    return null;
  }
}

// The core rules expected to be installed. Derived from the filesystem at
// require-time so a new rule added to rules/ is picked up automatically —
// no hand-maintained mirror to drift. Falls back to [] on fs error so the
// CLI still runs if the rules/ dir is missing (npm package may be incomplete).
const REQUIRED_RULES = (() => {
  try {
    return fs.readdirSync(RULES_SOURCE)
      .filter(f => f.endsWith('.md'))
      .map(f => path.basename(f, '.md'))
      .sort();
  } catch (_) {
    return [];
  }
})();

// ---------------------------------------------------------------------------
// Command: --version / -v
// ---------------------------------------------------------------------------

function cmdVersion() {
  const pkg = readPkg();
  print(pkg.version);
}

// ---------------------------------------------------------------------------
// Command: status
// ---------------------------------------------------------------------------

function cmdStatus() {
  const pkg    = readPkg();
  const config = readConfig();

  print('');
  print('=== ValidationForge Status ===');
  print('');
  print(`  Package version : ${pkg.version}`);
  print(`  Install dir     : ${PKG_ROOT}`);
  print('');

  // --- Config ---
  print('  Config (~/.claude/.vf-config.json):');
  if (!config) {
    print('    [MISSING] Not found — run `npm install -g validationforge` to set up,');
    print('              or run /vf-setup inside Claude Code.');
  } else {
    print(`    [OK] Found`);
    const fields = ['setupCompleted', 'enforcement', 'platform', 'projectPath'];
    for (const field of fields) {
      if (config[field] !== undefined && config[field] !== null) {
        print(`    [OK] ${field} = ${config[field]}`);
      } else {
        print(`    [--] ${field} (not set)`);
      }
    }
  }

  print('');

  // --- Rules ---
  print('  Rules:');
  let rulesOk = 0;
  let rulesMissing = 0;

  const localRulesDir = path.join(process.cwd(), '.claude', 'rules');

  for (const rule of REQUIRED_RULES) {
    const localPath  = path.join(localRulesDir, `${rule}.md`);
    const globalPath = path.join(GLOBAL_RULES, `vf-${rule}.md`);

    if (fs.existsSync(localPath)) {
      print(`    [OK] ${rule} (local)`);
      rulesOk++;
    } else if (fs.existsSync(globalPath)) {
      print(`    [OK] ${rule} (global)`);
      rulesOk++;
    } else {
      print(`    [MISSING] ${rule}`);
      rulesMissing++;
    }
  }

  print('');
  print(`  Rules: ${rulesOk}/${REQUIRED_RULES.length} installed`);

  if (rulesMissing > 0) {
    print('');
    print('  To install missing rules, run:');
    print('    vf install-rules          # install to current project');
    print('    vf install-rules --global # install globally');
  }

  print('');
}

// ---------------------------------------------------------------------------
// Command: install-rules [--global | --local]
// ---------------------------------------------------------------------------

function cmdInstallRules(args) {
  const useGlobal = args.includes('--global');
  // Default to local unless --global is specified
  const targetDir = useGlobal
    ? GLOBAL_RULES
    : path.join(process.cwd(), '.claude', 'rules');

  if (!fs.existsSync(RULES_SOURCE)) {
    err(`Rules source not found: ${RULES_SOURCE}`);
    err('The npm package may be incomplete. Try: npm install -g validationforge');
    process.exit(1);
  }

  fs.mkdirSync(targetDir, { recursive: true });

  const ruleFiles = fs.readdirSync(RULES_SOURCE).filter(f => f.endsWith('.md'));

  if (ruleFiles.length === 0) {
    err('No rule files found in the package.');
    process.exit(1);
  }

  let installed = 0;

  for (const ruleFile of ruleFiles) {
    const src    = path.join(RULES_SOURCE, ruleFile);
    const name   = path.basename(ruleFile, '.md');
    // Global: vf-<name>.md  |  Local: <name>.md (no prefix, per verify-setup.sh)
    const destName = useGlobal ? `vf-${name}.md` : `${name}.md`;
    const dest   = path.join(targetDir, destName);

    try {
      fs.copyFileSync(src, dest);
      print(`  [copied] ${destName} -> ${targetDir}`);
      installed++;
    } catch (e) {
      err(`Failed to copy ${ruleFile}: ${e.message}`);
    }
  }

  print('');
  print(`  ${installed} rule(s) installed to ${targetDir}`);

  if (!useGlobal) {
    print('');
    print('  Tip: commit .claude/rules/ to share rules with your team.');
  }

  print('');
}

// ---------------------------------------------------------------------------
// Command: help
// ---------------------------------------------------------------------------

function cmdHelp() {
  const pkg = readPkg();
  print('');
  print(`ValidationForge v${pkg.version} — No-mock validation for Claude Code`);
  print('');
  print('Usage: vf <command> [options]');
  print('');
  print('Commands:');
  print('  vf --version, -v              Print the installed version');
  print('  vf status                     Show plugin registration and rules status');
  print('  vf install-rules              Install rules to .claude/rules/ (current project)');
  print('  vf install-rules --global     Install rules to ~/.claude/rules/ (all projects)');
  print('  vf install-rules --local      Install rules to .claude/rules/ (current project)');
  print('  vf help                       Show this help message');
  print('');
  print('Claude Code slash commands (run inside Claude Code):');
  // L8: derive the list from commands/*.md at runtime so adding a new
  // slash command automatically surfaces in `vf help` without having
  // to update this file. Drift class eliminated.
  const COMMANDS_DIR = path.join(PKG_ROOT, 'commands');
  try {
    const cmdFiles = fs.readdirSync(COMMANDS_DIR)
      .filter(f => f.endsWith('.md'))
      .sort();
    for (const file of cmdFiles) {
      print('  /' + path.basename(file, '.md'));
    }
  } catch (_) {
    print('  (commands/ directory unavailable — did the package install cleanly?)');
  }
  print('');
  print('Documentation: https://validationforge.dev');
  print('Repository:    https://github.com/krzemienski/validationforge');
  print('');
}

// ---------------------------------------------------------------------------
// CLI entry point
// ---------------------------------------------------------------------------

const args = process.argv.slice(2);
const cmd  = args[0];

switch (cmd) {
  case '--version':
  case '-v':
    cmdVersion();
    break;

  case 'status':
    cmdStatus();
    break;

  case 'install-rules':
    cmdInstallRules(args.slice(1));
    break;

  case 'help':
  case '--help':
  case '-h':
    cmdHelp();
    break;

  case undefined:
    // No command: show help
    cmdHelp();
    break;

  default:
    err(`Unknown command: ${cmd}`);
    err('Run `vf help` to see available commands.');
    process.exit(1);
}
