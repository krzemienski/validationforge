# Specimen 3: bore

**Expected Class:** CLI (Rust)
**Source:** /Users/nick/Desktop/bore
**HEAD SHA:** 00a735a89917642df62d84336a90d9476fa175b5

## File Evidence

### CLI Indicators (Priority #4 in detector.md)

| Indicator | Status | Path | Evidence |
|-----------|--------|------|----------|
| `Cargo.toml` with `[[bin]]` section | ✓ FOUND | ./Cargo.toml | `[[bin]]` with name="bore", path="src/main.rs" |
| No web framework dependencies | ✓ CONFIRMED | Cargo.toml | No react, axum, actix, or web deps |
| `src/main.rs` entry point | ✓ INFERRED | src/main.rs (from [[bin]] config) | Standard Rust CLI pattern |

### File Structure

| Item | Status | Evidence |
|------|--------|----------|
| `Cargo.toml` | ✓ FOUND | Project config, [[bin]] defined |
| `src/` directory | ✓ FOUND | Standard Rust project layout |
| No `Cargo.toml` with non-CLI targets | ✓ CONFIRMED | No lib, wasm, or web targets |

## Detector Logic Trace

**Detection Path:** iOS → React Native → Flutter → **CLI #4 (MATCH)**

**CLI Detection (Priority #4):**
- Rust CLI primary indicator: Cargo.toml with `[[bin]]` section
- Rust CLI secondary: No web framework dependencies
- Decision: CLI / Rust (HIGH confidence)

## Classification Result

| Property | Value |
|----------|-------|
| **Expected Class** | CLI (Rust) |
| **Actual Class** | CLI |
| **Detector Specificity** | Rust CLI |
| **Confidence** | HIGH |
| **Verdict** | TRUE ✓ |

---
**Accuracy:** 100%
