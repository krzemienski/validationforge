# Specimen 5: LocalAI

**Expected Class:** API (Go)
**Source:** /Users/nick/LocalAI
**HEAD SHA:** b4cb22f4449cbc587bc9038a3b6a1f78f84fb8f5

## File Evidence

### API Indicators (Go)

| Indicator | Status | Path | Evidence |
|-----------|--------|------|----------|
| `go.mod` in project root | ✓ FOUND | ./go.mod | Go module: `module github.com/go-skynet/LocalAI` |
| `main.go` entry point | ✓ FOUND | ./main.go | Go API entry point (from root find) |
| No web framework (Gin/Actix/etc) | ✓ INFERRED | go.mod analysis | Standard Go API (net/http likely) |

### Monorepo Structure

| Item | Status | Evidence |
|------|--------|----------|
| Multiple top-level dirs | ✓ FOUND | aio/, backend/, core/, internal/, docs/ |
| `docs/package.json` (nested) | ✓ FOUND | ./docs/package.json | Documentation (secondary platform, not main) |
| Primary platform: Go API | ✓ CONFIRMED | go.mod at root, main.go at root |

## Detector Logic Trace

**Detection Path:** iOS → React Native → Flutter → CLI → API #5 (MATCH)**

**API Detection (Priority #5):**
- Go API primary indicator: `go.mod` + `main.go` in project root
- No web framework dependencies in main module
- Monorepo structure with Go as primary (go.mod at root)
- Decision: API / Go (HIGH confidence)

**Monorepo Handling:**
- Primary platform is Go API (root go.mod + main.go)
- Secondary `docs/package.json` is documentation build, not application platform
- Per detector rule "Prefer specificity": API (Go) over Generic

## Classification Result

| Property | Value |
|----------|-------|
| **Expected Class** | API (Go) |
| **Actual Class** | API |
| **Detector Specificity** | Go API |
| **Monorepo Type** | Go API with doc site |
| **Confidence** | HIGH |
| **Verdict** | TRUE ✓ |

---
**Accuracy:** 100%
