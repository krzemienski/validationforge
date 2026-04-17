# Specimen 1: ccbios-enhanced

**Expected Class:** iOS
**Source:** /Users/nick/Desktop/ccbios-enhanced
**HEAD SHA:** c492fa428dba744e2d01a24591aabf63eca0a68c

## File Evidence

### Primary Indicators Found

| Indicator | Status | Path | Detector Rule |
|-----------|--------|------|---------------|
| `*.xcodeproj` directory | ✓ FOUND | ./ccb.xcodeproj | iOS Priority #1 |
| `*.xcworkspace` directory | ✓ FOUND | ./ccb.xcworkspace | iOS Priority #1 |
| `Package.swift` with iOS/macOS targets | ✓ FOUND | ./ccbPackage/Package.swift | iOS Priority #1 |

### Secondary Indicators Found

| Indicator | Status | Path |
|-----------|--------|------|
| `*.swift` files | ✓ FOUND | ./ccb/ccbApp.swift |
| `@main struct *App` pattern | ✓ FOUND | ccbApp.swift |

## Detector Logic Trace

**Detector Algorithm (from agents/platform-detector.md):**
1. Scan iOS indicators (Priority #1) → Found 3 primary indicators
2. "First confident match wins" → HIGH confidence match on iOS
3. Stop scanning (no need for subsequent priorities)

**Confidence Scoring:**
- 1+ primary indicator found → HIGH confidence
- Decision: iOS (HIGH)

## Classification Result

| Property | Value |
|----------|-------|
| **Expected Class** | iOS |
| **Actual Class** | iOS |
| **Confidence** | HIGH |
| **Verdict** | TRUE ✓ |

---
**Accuracy:** 100% (expected=actual)
