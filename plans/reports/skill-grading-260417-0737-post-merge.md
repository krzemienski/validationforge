=== consensus-engine ===
  name: consensus-engine
  desc_len: 146 chars
  desc_head: Orchestrate N independent validator agents assessing the same feature; synthesize verdicts into a single consensus repor...
  total_lines:      204
  broken_refs: 0
  mock_mention: present (check context)

=== consensus-synthesis ===
  name: consensus-synthesis
  desc_len: 117 chars
  desc: Synthesize N per-validator verdicts into a single consensus verdict with confidence scoring based on agreement level.
  total_lines:      258
  broken_refs: 0
  mock_mention: none

=== consensus-disagreement-analysis ===
  name: consensus-disagreement-analysis
  desc_len: 114 chars
  desc: When validators disagree on a consensus verdict, run root cause analysis to determine whose evidence is stronger.

  total_lines:      241
  broken_refs: 0
  mock_mention: none

=== evidence-dashboard ===
  name: evidence-dashboard
  desc_len: 279 chars
  desc_head: Generates and interprets the evidence summary dashboard — a structured visualization of captured validation evidence, pe...
  total_lines:      172
  broken_refs: 0
  mock_mention: none

=== functional-validation ===
  name: functional-validation
  desc_len: 461 chars
  desc_head: Use whenever you need to prove a real system actually works — not just that it compiles or that mocks return the expecte...
  total_lines:      102
  references/: 4 file(s)
  broken_refs: 0
  mock_mention: present (check context)

=== no-mocking-validation-gates ===
  name: no-mocking-validation-gates
  desc_len: 525 chars
  desc_head: Use whenever someone is about to write a mock, stub, test double, or test file — or is already tempted to. This skill ex...
  total_lines:      126
  scripts/: 1 file(s)
  references/: 2 file(s)
  broken_refs: 0
  mock_mention: present (check context)

=== playwright-validation ===
  name: playwright-validation
  desc_len: 624 chars
  desc_head: Use for web feature validation via Playwright MCP — real browser interactions, cross-browser support (Chromium/Firefox/W...
  total_lines:      217
  broken_refs: 0
  mock_mention: none

