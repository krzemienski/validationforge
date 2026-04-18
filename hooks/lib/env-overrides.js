// env-overrides.js — centralized kill-switches for VF hooks.
//
// Two env vars short-circuit a hook to exit(0) silently before any
// profile resolution, JSON parsing, or pattern matching runs:
//
//   DISABLE_OMC=1                 → disable ALL hooks (OMC-ecosystem bridge)
//   VF_SKIP_HOOKS=hook-a,hook-b   → disable named hooks (comma-separated)
//
// Centralized (review findings L9 + L13) so every hook honors both
// consistently. Before this helper existed, only 3 of 7 hooks checked
// these env vars — the 4 legacy hooks (evidence-gate-reminder,
// completion-claim-validator, validation-not-compilation,
// validation-state-tracker) silently ignored them.
//
// Usage:
//   const { shouldSkip } = require('./lib/env-overrides');
//   if (shouldSkip('block-test-files')) process.exit(0);

'use strict';

function shouldSkip(hookName) {
  if (process.env.DISABLE_OMC === '1') return true;
  const list = (process.env.VF_SKIP_HOOKS || '')
    .split(',')
    .map(s => s.trim())
    .filter(Boolean);
  return list.includes(hookName);
}

module.exports = { shouldSkip };
