// Verify which paths the block-test-files hook actually blocks.
const { TEST_PATTERNS, ALLOWLIST, MOCK_PATTERNS } = require('../../../hooks/patterns');

const testPaths = [
  // Dirs claimed blocked in SKILL.md / catalog
  '__mocks__/api.ts',
  '__mocks__/api.js',
  '/project/__mocks__/api.ts',
  'testing/helpers.ts',
  '/project/testing/helpers.ts',
  'factories/user.ts',
  '/project/factories/user.ts',
  // Filenames claimed blocked
  'conftest.py',
  '/project/conftest.py',
  'my_module_test.py', // *_test.py claim
  '/project/my_module_test.py',
  '_test.rs', // Rust test files — catalog says blocked
  '/project/src/lib_test.rs',
  'SomeTest.java',
  'SomeTest.kt',
  '/project/SomeTest.java',
  // Filenames that ARE blocked (sanity)
  'handler_test.go',
  'profile.test.tsx',
  '__tests__/profile.test.tsx',
  'test_foo.py',
  'MyTests.swift',
  'MyTest.swift',
  'foo.spec.ts',
  'foo.stories.tsx',
  // Allowlist sanity
  'e2e-evidence/api/response.json',
  'validation-evidence/report.md',
  '.claude/skills/x/SKILL.md',
  'validationforge/config.json',
];

console.log('\n=== File-path block check ===');
for (const p of testPaths) {
  let result = 'NOT-BLOCKED';
  for (const a of ALLOWLIST) { if (a.test(p)) { result = 'ALLOWLIST: ' + a; break; } }
  if (!result.startsWith('ALLOWLIST')) {
    for (const t of TEST_PATTERNS) { if (t.test(p)) { result = 'BLOCK: ' + t; break; } }
  }
  console.log(p.padEnd(45), '->', result);
}

// Now code-pattern detection
const snippets = {
  // Claimed blocked in catalog JavaScript/TypeScript section
  'jest.mock': "jest.mock('../api/client')",
  'jest.fn': "const f = jest.fn()",
  'jest.spyOn': "jest.spyOn(obj, 'method')",
  'vi.mock': "vi.mock('../x')",
  'vi.fn': "const f = vi.fn()",
  'vi.spyOn': "vi.spyOn(obj, 'm')",
  'sinon.stub': "sinon.stub(obj, 'method')",
  'sinon.mock': "sinon.mock(obj)",
  'sinon.fake': "sinon.fake()",
  'nock': "nock('http://api.local').get('/x').reply(200)",
  'MSW setupServer': "const server = setupServer(rest.get('/api/users', handler))",
  'MSW http.get': "http.get('/api/users', handler)",
  '@testing-library import': "import { render } from '@testing-library/react'",

  // Python
  'from unittest.mock import': "from unittest.mock import Mock, MagicMock, patch",
  'from unittest import mock': "from unittest import mock",
  'import mock': "import mock",
  '@patch class': "@patch('module.Class')",
  '@patch.object': "@patch.object(MyClass, 'method')",
  'with patch': "with patch('module.function'):",
  'monkeypatch': "monkeypatch.setattr(mod, 'attr', value)",
  '@pytest.fixture': "@pytest.fixture\ndef client():\n    return x",
  'pytest.mark.parametrize': "pytest.mark.parametrize('n', [1, 2, 3])",

  // Swift
  'import XCTest': "import XCTest",
  'class Tests: XCTestCase': "class MyTests: XCTestCase { }",
  'XCTAssertEqual': "XCTAssertEqual(a, b)",
  'XCTAssertTrue': "XCTAssertTrue(cond)",
  'XCTAssertNil': "XCTAssertNil(value)",
  '@testable import': "@testable import MyModule",
  'XCTestExpectation': 'let e = XCTestExpectation(description: "x")',

  // Go
  'import testing': 'import "testing"',
  'func Test caps': 'func TestMyFunction(t *testing.T) { }',
  'func test lower': 'func test_foo() { }',
  'httptest.NewServer': 'httptest.NewServer(handler)',
  'httptest.NewRecorder': 'httptest.NewRecorder()',
  'gomock.NewController': 'gomock.NewController(t)',
  'mock.NewMockClient': 'mock.NewMockClient(ctrl)',

  // Rust
  '#[cfg(test)]': '#[cfg(test)]',
  'mod tests': 'mod tests { }',
  '#[test]': '#[test]',
  'fn test_something': 'fn test_something() { }',
  'mock! macro': 'mock! { Client {} }',
  'automock': '#[automock]',
};

console.log('\n=== Code-pattern detect (mock-detection.js / MOCK_PATTERNS) ===');
for (const label of Object.keys(snippets)) {
  const snip = snippets[label];
  let hits = MOCK_PATTERNS.filter(p => p.test(snip));
  console.log(label.padEnd(30), '->', hits.length === 0 ? 'NOT-DETECTED' : 'DETECTED by ' + hits.map(String).join(', '));
}
