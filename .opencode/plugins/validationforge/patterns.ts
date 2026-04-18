// Shared validation patterns used by both Claude Code hooks and OpenCode plugin.
// Single source of truth — CC hooks require() this, OC plugin imports it.

export const TEST_PATTERNS = [
  /\.test\.[jt]sx?$/,
  /\.spec\.[jt]sx?$/,
  /_test\.go$/,
  /test_[^/]+\.py$/,
  /Tests?\.swift$/,
  /\.test\.py$/,
  /\/__tests__\//,
  /\/test\/.*\.(ts|js|tsx|jsx|py|go|swift)$/,
  /\.mock\.[jt]sx?$/,
  /\.stub\.[jt]sx?$/,
  /\/mocks\//,
  /\/stubs\//,
  /\/fixtures\//,
  /\/test-utils\//,
  /\.stories\.[jt]sx?$/,
];

export const ALLOWLIST = [
  /e2e-evidence/,
  /validation-evidence/,
  /\.claude\//,
  /validationforge\//,
];

export const MOCK_PATTERNS = [
  /jest\.mock\(/,
  /jest\.spyOn\(/,
  /jest\.fn\(/,
  /jest\.createMockFromModule\(/,
  /sinon\.stub\(/,
  /sinon\.spy\(/,
  /sinon\.fake\(/,
  /unittest\.mock/,
  /from unittest\.mock import/,
  /mockImplementation/,
  /\.mockReturnValue/,
  /\.mockResolvedValue/,
  /\.mockRejectedValue/,
  /vi\.mock\(/,
  /vi\.spyOn\(/,
  /vi\.fn\(/,
  /cy\.intercept\(/,
  /cy\.stub\(/,
  /nock\(/,
  /httptest\.NewRecorder/,
  /gomock\.NewController/,
  /XCTestCase/,
  /@testable import/,
  // Bounded quantifiers prevent ReDoS on adversarial long lines (review finding M3).
  /class[^\n]{0,200}Tests[^\n]{0,200}XCTestCase/,
  /func test[^\n]{0,120}\(\)/,
  /describe\(['"][^'"]{0,200}['"],\s*\(\)\s*=>/,
  /it\(['"][^'"]{0,200}['"],\s*\(\)\s*=>/,
  /expect\([^)]{0,500}\)\.(to|not)/,
  /assert\.\w+\(/,
];

export const BUILD_PATTERNS = [
  /build succeeded/i,
  /compiled successfully/i,
  /compilation succeeded/i,
  /webpack.*compiled/i,
  /next.*build/i,
  /tsc.*--noEmit/i,
  /cargo build/i,
  /go build/i,
  /xcodebuild.*succeeded/i,
  // L11: /BUILD SUCCEEDED/ literal dropped — /build succeeded/i above
  // already matches case-insensitively.
];

export const COMPLETION_PATTERNS = [
  /all.*pass/i,
  /tests.*pass/i,
  /successfully deployed/i,
  /implementation complete/i,
];

export const VALIDATION_COMMAND_PATTERNS = [
  /playwright/i,
  /lighthouse/i,
  /simctl/i,
  /xcrun/i,
  /curl.*localhost/i,
  // L10: `npm run build` intentionally not duplicated here — BUILD_PATTERNS
  // already fires validation-not-compilation on build output. Adding it in
  // both sets produced two overlapping exit-2 reminders per `npm run build`.
  /xcodebuild/i,
  /idb /i,
];

// Helper: check if a file path matches test/mock patterns but not allowlist
export function isBlockedTestFile(filePath: string): string | null {
  for (const allow of ALLOWLIST) {
    if (allow.test(filePath)) return null;
  }
  for (const pattern of TEST_PATTERNS) {
    if (pattern.test(filePath)) {
      return `"${filePath}" matches test/mock/stub pattern. ValidationForge Iron Rule: never create test files.`;
    }
  }
  return null;
}

// Helper: check if content contains mock patterns
export function detectMockPatterns(content: string): boolean {
  return MOCK_PATTERNS.some(p => p.test(content));
}

// Helper: check if output looks like a build success
export function isBuildSuccess(output: string): boolean {
  return BUILD_PATTERNS.some(p => p.test(output));
}

// Helper: check if output looks like a completion claim
export function isCompletionClaim(output: string): boolean {
  return COMPLETION_PATTERNS.some(p => p.test(output));
}

// Helper: check if command is validation-related
export function isValidationCommand(command: string): boolean {
  return VALIDATION_COMMAND_PATTERNS.some(p => p.test(command));
}
