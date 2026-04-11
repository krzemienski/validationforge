# ValidationForge + Superpowers

**Positioning**: Superpowers enforces TDD methodology at the unit level. ValidationForge enforces real-system validation at the journey level. Used together, they catch both "tests are wrong" and "tests don't cover the real system" failure modes.

## Why This Combination

Superpowers encourages developers to write failing tests first, make them pass, and refactor. This produces high-quality, well-tested unit code — but unit tests almost always use mocks. A test suite can be 100% green while the running application is broken in production because the mocks disagree with reality.

ValidationForge never touches unit tests. It validates the **running system** through the same interfaces real users hit (browsers, APIs, simulators, CLIs). Used together:

- **Superpowers** ensures each function is tested in isolation
- **ValidationForge** ensures the composed system actually works end-to-end

## Resolving the Apparent Tension

Superpowers says "write tests first". VF says "never create test files".

**This is not a conflict.** VF's `block-test-files` hook blocks **validation test files** — files that try to substitute for real-system validation by mocking external systems. It does not block:

- Unit tests that test pure functions in isolation (these don't mock the real system)
- Integration tests that exercise real internal modules without external mocks
- Superpowers' TDD cycle for individual components

The block pattern is specifically for files like `api.validation.test.ts` or `e2e-mocked.spec.ts` — files that pretend to validate the system but actually run against stubs.

To make this explicit, configure VF's block-test-files hook to only scan your e2e or validation directories:

```json
{
  "validationforge": {
    "profile": "standard",
    "hook_overrides": {
      "block-test-files": {
        "scan_dirs": ["validation/", "e2e/", "system-tests/"],
        "exclude_dirs": ["src/**/*.test.ts", "test/unit/"]
      }
    }
  }
}
```

## Workflow Example

Developer wants to add a `calculateDiscount` function to the checkout flow.

1. **Superpowers' brainstorming skill** explores approaches for the discount logic
2. **Superpowers' test-driven-development skill** guides writing a failing unit test first:
   ```ts
   // src/checkout/discount.test.ts — unit test, VF does NOT block
   test("10% off for orders > $100", () => {
     expect(calculateDiscount(150)).toBe(15);
   });
   ```
3. Developer implements `calculateDiscount` until the test passes
4. Superpowers' refactor cycle cleans up the implementation
5. After the unit is done, developer runs `/validate` (VF's pipeline)
6. **VF's execute phase** hits the real `/api/checkout` endpoint with a $150 order, confirms the response includes `{discount: 15}`, and captures evidence
7. **VF's verdict** confirms the unit tests and the real system agree

Without VF, step 6 would be skipped. The unit tests would pass but a bug in the `POST /checkout` handler that forgets to call `calculateDiscount` would ship undetected.

## Configuration Snippet

Enable both plugins:

```json
{
  "plugins": [
    {
      "name": "superpowers",
      "path": "~/.claude/plugins/superpowers",
      "enabled": true
    },
    {
      "name": "validationforge",
      "path": "~/.claude/plugins/validationforge",
      "enabled": true
    }
  ]
}
```

Per-project `.claude/settings.json`:

```json
{
  "plugins": {
    "superpowers": {
      "skills": ["brainstorming", "test-driven-development", "systematic-debugging"]
    },
    "validationforge": {
      "profile": "standard",
      "hook_overrides": {
        "block-test-files": {
          "scan_dirs": ["e2e/", "validation/"]
        }
      }
    }
  }
}
```

## Sample Output (Illustrative)

```
[Superpowers: brainstorming] Exploring discount calculation approaches
  Option A: Flat percentage
  Option B: Tiered thresholds
  Selected: Option A

[Superpowers: test-driven-development] RED phase
  Writing src/checkout/discount.test.ts
  Running test: FAIL (expected)

[Superpowers: test-driven-development] GREEN phase
  Writing src/checkout/discount.ts
  Running test: PASS

[Superpowers: test-driven-development] REFACTOR phase
  Extracted threshold constant
  Running test: PASS

[User] /validate

[VF phase 3: Execute]
  journey-1-checkout-with-discount
    step-01-add-to-cart.json: items=[{id:42,price:150}]
    step-02-apply-discount.json: cart.total=135, discount=15
    step-03-checkout.json: status=200, order_id=ord_xyz
[VF phase 5: Verdict]
  journey-1-checkout-with-discount: PASS
  Unit tests: 1 passed (Superpowers-driven)
  E2E journeys: 1 passed (VF-validated)
  Combined confidence: HIGH
```

## Caveats

- **Superpowers' "test files" are NOT VF's "test files"**: Be explicit about what you want blocked. Configure `scan_dirs` to exclude the Superpowers TDD workflow.
- **The two plugins have different skill trigger patterns**: If both fire on the same user prompt, context budget doubles. Use platform-aware skill loading where possible.
- **Systematic-debugging and VF verdicts are complementary**: When VF verdicts FAIL, Superpowers' systematic-debugging skill can be invoked to trace the failure back to the unit level.

## Runtime Verification

This integration has not been verified in a live session. To verify:

1. Install both plugins
2. Configure the `hook_overrides.block-test-files.scan_dirs` above
3. Attempt TDD on a simple function — Superpowers should guide you through red/green/refactor
4. Run `/validate` and confirm VF's pipeline runs without blocking your TDD unit tests
5. Record findings in `e2e-evidence/vf-with-superpowers-integration/`
