// resolve-profile.js — canonical profile resolver for ValidationForge hooks.
//
// Precedence (highest to lowest):
//   1. VF_PROFILE env var  (strict | standard | permissive)
//   2. ~/.claude/.vf-config.json  `strictness` or `enforcement` field
//   3. config/standard.json fallback
//
// Performance notes:
//   • Fast path: when the resolved profile name is "standard" AND the
//     profile file isn't present, we hand back STANDARD_DEFAULTS without
//     touching the filesystem at all.
//   • VF_PROFILE=standard with no user config short-circuits to the
//     in-memory defaults on the very first call.
//   • Review finding M3: the former module-level memoization cache was
//     removed — hooks are one-shot processes that call resolveProfile()
//     exactly once, so the cache had zero observable effect in production
//     and risked mutation-across-calls if a consumer ever mutated the
//     returned profile.data.
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

function readProfileFile(name) {
  const p = path.join(CONFIG_DIR, `${name}.json`);
  // Missing file is the common case (fall-through to defaults) — silent.
  if (!fs.existsSync(p)) return null;
  // Present but unreadable/malformed is an operator error — emit a one-
  // liner to stderr so the user knows their config edit didn't take
  // effect (review finding M4 — previously swallowed silently).
  try {
    return JSON.parse(fs.readFileSync(p, 'utf8'));
  } catch (e) {
    process.stderr.write(
      `[VF] WARN: ${p} present but unreadable (${e.message}); using standard defaults.\n`
    );
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
  // ── Fast path: VF_PROFILE env var
  const envVal = (process.env.VF_PROFILE || '').trim().toLowerCase();
  if (VALID.includes(envVal)) {
    if (envVal === 'standard') {
      return { name: 'standard', data: STANDARD_DEFAULTS, source: 'env:VF_PROFILE:fast-path' };
    }
    const data = readProfileFile(envVal) || STANDARD_DEFAULTS;
    return { name: envVal, data, source: 'env:VF_PROFILE' };
  }

  // ── User config file
  const userLevel = userConfigStrictness();
  if (userLevel) {
    const data = readProfileFile(userLevel) || STANDARD_DEFAULTS;
    const cfgPath = process.env.VF_CONFIG_PATH ||
      path.join(os.homedir(), '.claude', '.vf-config.json');
    return { name: userLevel, data, source: `user-config:${cfgPath}` };
  }

  // ── Nothing set — return the frozen defaults without touching fs.
  return { name: 'standard', data: STANDARD_DEFAULTS, source: 'fallback:defaults' };
}

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

module.exports = {
  resolveProfile,
  hookState,
  ruleEnabled,
  STANDARD_DEFAULTS,
};
