// CommonJS bridge for shared ValidationForge patterns.
// Single source of truth: .opencode/plugins/validationforge/patterns.ts
// Strips TypeScript export syntax and evaluates as JS — no build step needed.

const fs = require('fs');
const path = require('path');

const PATTERNS_TS = path.resolve(__dirname, '..', '.opencode', 'plugins', 'validationforge', 'patterns.ts');

let exported;
try {
  const source = fs.readFileSync(PATTERNS_TS, 'utf8');
  // Strip TypeScript: remove export keywords, type annotations, and function definitions
  const jsSource = source
    .replace(/^export\s+/gm, '')               // remove 'export' keyword
    .replace(/^\/\/.*$/gm, '')                  // remove single-line comments
    .replace(/: string\b/g, '')                 // remove type annotations
    .replace(/: boolean\b/g, '')
    .replace(/: string \| null\b/g, '')
    .replace(/^function\s+\w+[\s\S]*?^}/gm, '') // remove function definitions
    .replace(/^\s*$/gm, '');                     // remove blank lines

  // Evaluate in a sandbox to extract the const arrays
  const vm = require('vm');
  const sandbox = {};
  vm.runInNewContext(jsSource, sandbox);

  exported = {
    TEST_PATTERNS: sandbox.TEST_PATTERNS || [],
    ALLOWLIST: sandbox.ALLOWLIST || [],
    MOCK_PATTERNS: sandbox.MOCK_PATTERNS || [],
    BUILD_PATTERNS: sandbox.BUILD_PATTERNS || [],
    COMPLETION_PATTERNS: sandbox.COMPLETION_PATTERNS || [],
    VALIDATION_COMMAND_PATTERNS: sandbox.VALIDATION_COMMAND_PATTERNS || [],
  };
} catch (e) {
  process.stderr.write(`[ValidationForge] patterns.js: Could not load ${PATTERNS_TS}: ${e.message}. Using inline fallback.\n`);
  exported = null;
}

if (exported && exported.TEST_PATTERNS.length > 0) {
  module.exports = exported;
} else {
  // Inline fallback — kept in sync manually if patterns.ts is unavailable
  module.exports = {
    TEST_PATTERNS: [/\.test\.[jt]sx?$/, /\.spec\.[jt]sx?$/, /_test\.go$/, /test_[^/]+\.py$/, /Tests?\.swift$/, /\.test\.py$/, /\/__tests__\//, /\/test\/.*\.(ts|js|tsx|jsx|py|go|swift)$/, /\.mock\.[jt]sx?$/, /\.stub\.[jt]sx?$/, /\/mocks\//, /\/stubs\//, /\/fixtures\//, /\/test-utils\//, /\.stories\.[jt]sx?$/],
    ALLOWLIST: [/e2e-evidence/, /validation-evidence/, /\.claude\//, /validationforge\//],
    MOCK_PATTERNS: [/jest\.mock\(/, /sinon\.stub\(/, /unittest\.mock/, /from unittest\.mock import/, /mockImplementation/, /\.mockReturnValue/, /\.mockResolvedValue/, /vi\.mock\(/, /cy\.intercept\(/, /nock\(/, /httptest\.NewRecorder/, /gomock\.NewController/, /XCTestCase/, /@testable import/, /class.*Tests.*XCTestCase/, /func test.*\(\)/, /describe\(['"].*['"],\s*\(\)\s*=>/, /it\(['"].*['"],\s*\(\)\s*=>/, /expect\(.*\)\.(to|not)/, /assert\.\w+\(/],
    BUILD_PATTERNS: [/build succeeded/i, /compiled successfully/i, /compilation succeeded/i, /webpack.*compiled/i, /next.*build/i, /tsc.*--noEmit/i, /cargo build/i, /go build/i, /xcodebuild.*succeeded/i, /BUILD SUCCEEDED/],
    COMPLETION_PATTERNS: [/all.*pass/i, /tests.*pass/i, /successfully deployed/i, /implementation complete/i],
    VALIDATION_COMMAND_PATTERNS: [/playwright/i, /lighthouse/i, /simctl/i, /xcrun/i, /curl.*localhost/i, /npm run (dev|start|build)/i, /xcodebuild/i, /idb /i],
  };
}
