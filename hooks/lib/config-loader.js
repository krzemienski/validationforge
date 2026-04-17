// config-loader.js — DEPRECATED. Retained only as a thin compat shim.
//
// The canonical profile resolver lives in ./resolve-profile.js. This file
// previously duplicated that logic with slightly different field names
// (strictness vs enforcement) and its own STANDARD_DEFAULTS — a review
// finding (H6) identified the double source of truth as a maintenance
// hazard and perf wart (every hook that imports this paid double fs I/O).
//
// New hooks should `require('./lib/resolve-profile')` directly and use
// `resolveProfile()` / `hookState()` / `ruleEnabled()`. The 4 existing
// hooks that call `loadConfig()` continue to work through this re-export
// unchanged.

'use strict';

const { loadConfig } = require('./resolve-profile');

module.exports = { loadConfig };
