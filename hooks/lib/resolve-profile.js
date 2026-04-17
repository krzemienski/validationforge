// resolve-profile.js — shared profile resolver for ValidationForge hooks.
//
// Precedence (highest to lowest):
//   1. VF_PROFILE env var  (strict | standard | permissive)       [precedence-1] line 36
//   2. ~/.claude/.vf-config.json  `strictness` field              [precedence-2] line 44
//   3. config/standard.json fallback                              [precedence-3] line 53
//
// Exports:
//   resolveProfile()             → { name, data, source }
//   hookState(profile, hookName) → "enabled" | "warn" | "disabled"
//   ruleEnabled(profile, rule)   → boolean

'use strict';

const fs   = require('fs');
const path = require('path');
const os   = require('os');

const VALID = ['strict', 'standard', 'permissive'];

const PLUGIN_ROOT = process.env.CLAUDE_PLUGIN_ROOT ||
  path.resolve(__dirname, '..', '..');
const CONFIG_DIR  = path.join(PLUGIN_ROOT, 'config');

// Safe defaults used when a profile file is unreadable.
const STANDARD_DEFAULTS = {
  hooks: {
    'block-test-files':           'enabled',
    'evidence-gate-reminder':     'enabled',
    'validation-not-compilation': 'enabled',
    'completion-claim-validator': 'enabled',
    'mock-detection':             'enabled',
    'validation-state-tracker':   'enabled',
    'evidence-quality-check':     'enabled',
  },
  rules: {
    block_test_files:              true,
    block_mock_patterns:           true,
    require_evidence_on_completion: true,
    reject_empty_evidence:         true,
  },
};

function readProfileFile(name) {
  try {
    const raw = fs.readFileSync(path.join(CONFIG_DIR, `${name}.json`), 'utf8');
    return JSON.parse(raw);
  } catch (_) {
    return null;
  }
}

function userConfigStrictness() {
  // Reads ~/.claude/.vf-config.json.
  // Accepts `strictness` (current) and `enforcement` (legacy /vf-setup field).
  const cfgPath = process.env.VF_CONFIG_PATH ||
    path.join(os.homedir(), '.claude', '.vf-config.json');
  try {
    const obj = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
    const val = obj.strictness || obj.enforcement;
    if (typeof val === 'string' && VALID.includes(val)) return val;
  } catch (_) { /* absent or unreadable */ }
  return null;
}

/**
 * Resolve the active profile.
 * @returns {{ name: string, data: object, source: string }}
 */
function resolveProfile() {
  // [precedence-1] VF_PROFILE env var — highest priority
  const envVal = (process.env.VF_PROFILE || '').trim().toLowerCase();
  if (VALID.includes(envVal)) {
    const data = readProfileFile(envVal) || STANDARD_DEFAULTS;
    return { name: envVal, data, source: 'env:VF_PROFILE' };
  }

  // [precedence-2] ~/.claude/.vf-config.json `strictness` field
  const userLevel = userConfigStrictness();
  if (userLevel) {
    const data = readProfileFile(userLevel) || STANDARD_DEFAULTS;
    const cfgPath = process.env.VF_CONFIG_PATH ||
      path.join(os.homedir(), '.claude', '.vf-config.json');
    return { name: userLevel, data, source: `user-config:${cfgPath}` };
  }

  // [precedence-3] Fallback to standard
  const data = readProfileFile('standard') || STANDARD_DEFAULTS;
  return { name: 'standard', data, source: 'fallback:standard' };
}

/**
 * Return the hook state string for a named hook given a resolved profile.
 * @param {{ name: string, data: object }} profile
 * @param {string} hookName
 * @returns {"enabled"|"warn"|"disabled"}
 */
function hookState(profile, hookName) {
  const hooks = (profile.data && profile.data.hooks) || STANDARD_DEFAULTS.hooks;
  const val   = hooks[hookName];
  if (val === 'disabled' || val === 'warn' || val === 'enabled') return val;
  return 'enabled';
}

/**
 * Return whether a named rule is enabled for a resolved profile.
 * Absent rules default to true (fail-safe for strict/standard).
 * @param {{ name: string, data: object }} profile
 * @param {string} ruleName  e.g. "block_mock_patterns"
 * @returns {boolean}
 */
function ruleEnabled(profile, ruleName) {
  const rules = (profile.data && profile.data.rules) || STANDARD_DEFAULTS.rules;
  return rules[ruleName] !== false;
}

module.exports = { resolveProfile, hookState, ruleEnabled };
