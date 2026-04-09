// CommonJS utility: reads the active ValidationForge enforcement level and
// returns a config object that hooks use to decide whether to block, warn, or skip.
//
// Resolution order:
//   1. Read VF_CONFIG_PATH env var (or ~/.claude/.vf-config.json) → get 'enforcement' field
//   2. Load config/{enforcement}.json from the plugin root
//   3. On any error → fall back to 'standard' profile (fail-open, not fail-closed)
//
// Env vars:
//   CLAUDE_PLUGIN_ROOT  — override plugin root for locating config/ directory
//   VF_CONFIG_PATH      — override the user config file path (useful in CI/CD)
//
// Follows the same synchronous pattern as hooks/patterns.js.

const fs = require('fs');
const path = require('path');
const os = require('os');

// Locate the config/ directory via CLAUDE_PLUGIN_ROOT or relative to this file.
const PLUGIN_ROOT = process.env.CLAUDE_PLUGIN_ROOT || path.resolve(__dirname, '..');
const CONFIG_DIR = path.join(PLUGIN_ROOT, 'config');

// Path to the user-level active config file written by /vf-setup.
// Can be overridden via VF_CONFIG_PATH env var (useful in CI/CD environments).
const VF_CONFIG_PATH = process.env.VF_CONFIG_PATH || path.join(os.homedir(), '.claude', '.vf-config.json');

const VALID_LEVELS = ['strict', 'standard', 'permissive'];

// Default 'standard' profile used whenever anything goes wrong.
const STANDARD_DEFAULTS = {
  enforcement: 'standard',
  rules: {
    block_test_files: true,
    block_mock_patterns: true,
    require_evidence_on_completion: true,
    require_validation_plan: false,
    require_preflight: false,
    require_baseline: false,
    max_recovery_attempts: 3,
    fail_on_missing_evidence: false,
    require_screenshot_review: false,
  },
  hooks: {
    'block-test-files': 'enabled',
    'evidence-gate-reminder': 'enabled',
    'validation-not-compilation': 'enabled',
    'completion-claim-validator': 'enabled',
    'mock-detection': 'enabled',
    'validation-state-tracker': 'enabled',
    'evidence-quality-check': 'enabled',
  },
};

/**
 * Read the active enforcement level from ~/.claude/.vf-config.json.
 * Returns 'standard' when the file is absent or the field is missing/invalid.
 */
function readEnforcementLevel() {
  try {
    const raw = fs.readFileSync(VF_CONFIG_PATH, 'utf8');
    const parsed = JSON.parse(raw);
    const level = parsed && parsed.enforcement;
    if (typeof level === 'string' && VALID_LEVELS.includes(level)) {
      return level;
    }
  } catch (_) {
    // File absent or unreadable — use default
  }
  return 'standard';
}

/**
 * Load the named enforcement profile from config/{level}.json.
 * Returns the parsed JSON object, or null on failure.
 */
function loadProfile(level) {
  try {
    const profilePath = path.join(CONFIG_DIR, `${level}.json`);
    const raw = fs.readFileSync(profilePath, 'utf8');
    return JSON.parse(raw);
  } catch (_) {
    return null;
  }
}

/**
 * Load the active config and return a hook-friendly object.
 *
 * Returns:
 *   {
 *     enforcement: string,          // 'strict' | 'standard' | 'permissive'
 *     getHookConfig(name): string,  // 'enabled' | 'warn' | 'disabled'
 *     rules: object,                // full rules map from the profile
 *   }
 */
function loadConfig() {
  try {
    const enforcement = readEnforcementLevel();
    const profile = loadProfile(enforcement);

    if (!profile) {
      // Profile file unreadable — fall back to standard defaults
      return buildResult('standard', STANDARD_DEFAULTS);
    }

    return buildResult(enforcement, profile);
  } catch (_) {
    // Catch-all: never let config loading crash a hook
    return buildResult('standard', STANDARD_DEFAULTS);
  }
}

/**
 * Build the returned config result from an enforcement level and profile data.
 */
function buildResult(enforcement, profile) {
  const hooks = (profile && profile.hooks) || STANDARD_DEFAULTS.hooks;
  const rules = (profile && profile.rules) || STANDARD_DEFAULTS.rules;

  return {
    enforcement,
    rules,
    /**
     * Returns the hook configuration string for the named hook.
     * Falls back to 'enabled' if the hook is not listed in the profile.
     *
     * @param {string} hookName  e.g. 'block-test-files'
     * @returns {'enabled'|'warn'|'disabled'}
     */
    getHookConfig(hookName) {
      const value = hooks[hookName];
      if (value === 'disabled' || value === 'warn' || value === 'enabled') {
        return value;
      }
      return 'enabled';
    },
  };
}

module.exports = { loadConfig };
