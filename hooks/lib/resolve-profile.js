// resolve-profile.js — canonical profile resolver for ValidationForge hooks.
//
// Precedence (highest to lowest):
//   1. VF_PROFILE env var  (strict | standard | permissive)
//   2. ~/.claude/.vf-config.json  `strictness` or `enforcement` field
//   3. config/standard.json fallback
//
// Performance notes (review finding H5):
//   • A module-level cache memoizes the first resolve() call so any
//     downstream lookups in the same hook process skip fs entirely.
//   • Fast path: when the resolved profile name is "standard" AND the
//     profile file isn't present, we hand back STANDARD_DEFAULTS without
//     touching the filesystem at all.
//   • VF_PROFILE=standard with no user config short-circuits to the
//     in-memory defaults on the very first call.
//
// Exports:
//   resolveProfile()             → { name, data, source }
//   hookState(profile, hookName) → "enabled" | "warn" | "disabled"
//   ruleEnabled(profile, rule)   → boolean
//   loadConfig()                 → compat shim (same shape as config-loader.js)

'use strict';

const fs   = require('fs');
const path = require('path');
const os   = require('os');

const VALID = ['strict', 'standard', 'permissive'];

const PLUGIN_ROOT = process.env.CLAUDE_PLUGIN_ROOT ||
  path.resolve(__dirname, '..', '..');
const CONFIG_DIR  = path.join(PLUGIN_ROOT, 'config');

// ────────────────────────────────────────────────────────────
// Safe defaults used when a profile file is unreadable OR
// returned directly on the fast path (no fs read at all).
// ────────────────────────────────────────────────────────────
const STANDARD_DEFAULTS = Object.freeze({
  enforcement: 'standard',
  hooks: Object.freeze({
    'block-test-files':           'enabled',
    'evidence-gate-reminder':     'enabled',
    'validation-not-compilation': 'enabled',
    'completion-claim-validator': 'enabled',
    'mock-detection':             'enabled',
    'validation-state-tracker':   'enabled',
    'evidence-quality-check':     'enabled',
  }),
  rules: Object.freeze({
    block_test_files:              true,
    block_mock_patterns:           true,
    require_evidence_on_completion: true,
    reject_empty_evidence:         true,
    require_validation_plan:        false,
    require_preflight:              false,
    require_baseline:               false,
    max_recovery_attempts:          3,
    fail_on_missing_evidence:       false,
    require_screenshot_review:      false,
  }),
});

// ────────────────────────────────────────────────────────────
// Module-level cache. Hooks run as one-shot processes, but the
// resolver can be called several times per hook — cache saves
// each subsequent lookup the double-fs cost.
// ────────────────────────────────────────────────────────────
let _cache = null;

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
 * Resolve the active profile. Memoized after the first call in-process.
 * @returns {{ name: string, data: object, source: string }}
 */
function resolveProfile() {
  if (_cache) return _cache;

  // ── Fast path: VF_PROFILE env var
  const envVal = (process.env.VF_PROFILE || '').trim().toLowerCase();
  if (VALID.includes(envVal)) {
    // Skip fs entirely when the env requests plain "standard"
    if (envVal === 'standard') {
      _cache = { name: 'standard', data: STANDARD_DEFAULTS, source: 'env:VF_PROFILE:fast-path' };
      return _cache;
    }
    const data = readProfileFile(envVal) || STANDARD_DEFAULTS;
    _cache = { name: envVal, data, source: 'env:VF_PROFILE' };
    return _cache;
  }

  // ── User config file
  const userLevel = userConfigStrictness();
  if (userLevel) {
    const data = readProfileFile(userLevel) || STANDARD_DEFAULTS;
    const cfgPath = process.env.VF_CONFIG_PATH ||
      path.join(os.homedir(), '.claude', '.vf-config.json');
    _cache = { name: userLevel, data, source: `user-config:${cfgPath}` };
    return _cache;
  }

  // ── Nothing set — return the frozen defaults without touching fs.
  _cache = { name: 'standard', data: STANDARD_DEFAULTS, source: 'fallback:defaults' };
  return _cache;
}

/**
 * Clear the cache. Intended for tests only.
 */
function _resetCacheForTests() { _cache = null; }

function hookState(profile, hookName) {
  const hooks = (profile && profile.data && profile.data.hooks) || STANDARD_DEFAULTS.hooks;
  const val   = hooks[hookName];
  if (val === 'disabled' || val === 'warn' || val === 'enabled') return val;
  return 'enabled';
}

function ruleEnabled(profile, ruleName) {
  const rules = (profile && profile.data && profile.data.rules) || STANDARD_DEFAULTS.rules;
  return rules[ruleName] !== false;
}

// ────────────────────────────────────────────────────────────
// Back-compat shim — same shape as the old config-loader.js.
// Lets legacy hooks keep their `loadConfig()` import while we
// consolidate to a single resolver (review findings H5 + H6).
// ────────────────────────────────────────────────────────────
function loadConfig() {
  const profile = resolveProfile();
  const hooks   = (profile.data && profile.data.hooks) || STANDARD_DEFAULTS.hooks;
  const rules   = (profile.data && profile.data.rules) || STANDARD_DEFAULTS.rules;
  return {
    enforcement: profile.name,
    rules,
    getHookConfig(hookName) {
      const value = hooks[hookName];
      if (value === 'disabled' || value === 'warn' || value === 'enabled') {
        return value;
      }
      return 'enabled';
    },
  };
}

module.exports = {
  resolveProfile,
  hookState,
  ruleEnabled,
  loadConfig,
  STANDARD_DEFAULTS,
  _resetCacheForTests,
};
