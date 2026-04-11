#!/usr/bin/env node
// ValidationForge plugin structure verification script.
// Validates the complete plugin component inventory:
//   - plugin.json directory declarations (commands, skills, agents, rules, hooks)
//   - 45 skill directories each containing SKILL.md
//   - 15 command .md files in commands/
//   - 5 agent .md files in agents/
//   - 8 rule .md files in rules/
//   - 9 hook .js files in hooks/ + hooks.json
//
// Usage:
//   node ./scripts/verify-plugin-structure.js
//   node ./scripts/verify-plugin-structure.js --path /path/to/plugin/root
//
// Expected: All components verified: PASS

'use strict';

const path = require('path');
const fs = require('fs');

// ---------------------------------------------------------------------------
// CLI argument handling
// ---------------------------------------------------------------------------

/**
 * Parse --path <value> from process.argv.
 * Falls back to the project root (one level above scripts/).
 */
function resolvePluginRoot() {
  const args = process.argv.slice(2);
  const flagIdx = args.indexOf('--path');
  if (flagIdx !== -1 && args[flagIdx + 1]) {
    return path.resolve(args[flagIdx + 1]);
  }
  return path.resolve(__dirname, '..');
}

// ---------------------------------------------------------------------------
// Check helpers
// ---------------------------------------------------------------------------

/**
 * Count files in a directory that satisfy a predicate.
 * @param {string} dir
 * @param {function(string): boolean} predicate
 * @returns {string[]} matching filenames
 */
function listMatching(dir, predicate) {
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir).filter(predicate);
}

/**
 * List direct subdirectories of a directory.
 * @param {string} dir
 * @returns {string[]} subdirectory names
 */
function listSubdirs(dir) {
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir).filter(name => {
    return fs.statSync(path.join(dir, name)).isDirectory();
  });
}

// ---------------------------------------------------------------------------
// Check definitions
// ---------------------------------------------------------------------------
// Each check: { label, run(root) → { passed, detail } }

const EXPECTED = {
  SKILLS: 45,
  COMMANDS: 15,
  AGENTS: 5,
  RULES: 8,
  HOOKS_JS: 9,
  PLUGIN_JSON_KEYS: ['commands', 'skills', 'agents', 'rules', 'hooks'],
};

const EXPECTED_HOOK_FILES = [
  'block-test-files.js',
  'completion-claim-validator.js',
  'config-loader.js',
  'evidence-gate-reminder.js',
  'evidence-quality-check.js',
  'mock-detection.js',
  'validation-not-compilation.js',
  'validation-state-tracker.js',
  'verify-e2e.js',
];

const checks = [
  // 1. plugin.json has all 5 required directory declarations
  {
    label: 'plugin.json declarations',
    run(root) {
      const pluginJsonPath = path.join(root, '.claude-plugin', 'plugin.json');
      if (!fs.existsSync(pluginJsonPath)) {
        return { passed: false, detail: `.claude-plugin/plugin.json not found at ${pluginJsonPath}` };
      }
      let manifest;
      try {
        manifest = JSON.parse(fs.readFileSync(pluginJsonPath, 'utf8'));
      } catch (e) {
        return { passed: false, detail: `failed to parse plugin.json: ${e.message}` };
      }
      const missing = EXPECTED.PLUGIN_JSON_KEYS.filter(k => !(k in manifest));
      if (missing.length > 0) {
        return { passed: false, detail: `missing keys: ${missing.join(', ')}` };
      }
      return {
        passed: true,
        detail: `all ${EXPECTED.PLUGIN_JSON_KEYS.length} declarations present (${EXPECTED.PLUGIN_JSON_KEYS.join(', ')})`,
      };
    },
  },

  // 2. skills/ — 45 directories each containing SKILL.md
  {
    label: 'skills/ (45 dirs with SKILL.md)',
    run(root) {
      const skillsDir = path.join(root, 'skills');
      const subdirs = listSubdirs(skillsDir);
      if (subdirs.length !== EXPECTED.SKILLS) {
        return {
          passed: false,
          detail: `expected ${EXPECTED.SKILLS} skill dirs, found ${subdirs.length}`,
        };
      }
      const missingSkillMd = subdirs.filter(
        name => !fs.existsSync(path.join(skillsDir, name, 'SKILL.md'))
      );
      if (missingSkillMd.length > 0) {
        return {
          passed: false,
          detail: `${missingSkillMd.length} skill(s) missing SKILL.md: ${missingSkillMd.join(', ')}`,
        };
      }
      return {
        passed: true,
        detail: `${subdirs.length} skills found, all have SKILL.md`,
      };
    },
  },

  // 3. commands/ — 15 .md files
  {
    label: 'commands/ (15 .md files)',
    run(root) {
      const commandsDir = path.join(root, 'commands');
      const files = listMatching(commandsDir, f => f.endsWith('.md'));
      if (files.length !== EXPECTED.COMMANDS) {
        return {
          passed: false,
          detail: `expected ${EXPECTED.COMMANDS} command .md files, found ${files.length}: ${files.join(', ')}`,
        };
      }
      return {
        passed: true,
        detail: `${files.length} command files found`,
      };
    },
  },

  // 4. agents/ — 5 .md files
  {
    label: 'agents/ (5 .md files)',
    run(root) {
      const agentsDir = path.join(root, 'agents');
      const files = listMatching(agentsDir, f => f.endsWith('.md'));
      if (files.length !== EXPECTED.AGENTS) {
        return {
          passed: false,
          detail: `expected ${EXPECTED.AGENTS} agent .md files, found ${files.length}: ${files.join(', ')}`,
        };
      }
      return {
        passed: true,
        detail: `${files.length} agent files found`,
      };
    },
  },

  // 5. rules/ — 8 .md files
  {
    label: 'rules/ (8 .md files)',
    run(root) {
      const rulesDir = path.join(root, 'rules');
      const files = listMatching(rulesDir, f => f.endsWith('.md'));
      if (files.length !== EXPECTED.RULES) {
        return {
          passed: false,
          detail: `expected ${EXPECTED.RULES} rule .md files, found ${files.length}: ${files.join(', ')}`,
        };
      }
      return {
        passed: true,
        detail: `${files.length} rule files found`,
      };
    },
  },

  // 6. hooks/ — exactly the 9 expected .js files + hooks.json
  {
    label: 'hooks/ (9 .js files + hooks.json)',
    run(root) {
      const hooksDir = path.join(root, 'hooks');
      if (!fs.existsSync(hooksDir)) {
        return { passed: false, detail: 'hooks/ directory not found' };
      }

      // Check hooks.json
      if (!fs.existsSync(path.join(hooksDir, 'hooks.json'))) {
        return { passed: false, detail: 'hooks/hooks.json not found' };
      }

      // Check each expected hook .js file is present
      const missing = EXPECTED_HOOK_FILES.filter(
        f => !fs.existsSync(path.join(hooksDir, f))
      );
      if (missing.length > 0) {
        return {
          passed: false,
          detail: `missing hook files: ${missing.join(', ')}`,
        };
      }

      // Count actual .js files (excluding patterns.js helper)
      const jsFiles = listMatching(
        hooksDir,
        f => f.endsWith('.js') && f !== 'patterns.js'
      );
      if (jsFiles.length !== EXPECTED.HOOKS_JS) {
        return {
          passed: false,
          detail: `expected ${EXPECTED.HOOKS_JS} hook .js files (excl patterns.js), found ${jsFiles.length}: ${jsFiles.join(', ')}`,
        };
      }

      return {
        passed: true,
        detail: `${jsFiles.length} hook scripts + hooks.json verified`,
      };
    },
  },
];

// ---------------------------------------------------------------------------
// Runner
// ---------------------------------------------------------------------------

function main() {
  const root = resolvePluginRoot();
  process.stdout.write(`Checking plugin root: ${root}\n\n`);

  const total = checks.length;
  let passed = 0;
  const results = [];

  for (const check of checks) {
    let outcome;
    try {
      outcome = check.run(root);
    } catch (err) {
      outcome = { passed: false, detail: `threw: ${err.message}` };
    }

    const status = outcome.passed ? 'PASS' : 'FAIL';
    process.stdout.write(`${status}: ${check.label}\n`);
    process.stdout.write(`      ${outcome.detail}\n`);

    if (outcome.passed) passed += 1;
    results.push({ label: check.label, ...outcome });
  }

  process.stdout.write(`\n${passed}/${total} checks passed\n`);

  if (passed === total) {
    process.stdout.write('\nAll components verified: PASS\n');
  } else {
    const failed = results.filter(r => !r.passed).map(r => r.label);
    process.stdout.write(`\nFAILED checks (${failed.length}): ${failed.join(', ')}\n`);
    process.exit(1);
  }
}

main();
