# Specimen 2: acoustid-server

**Expected Class:** Python API (Flask)
**Source:** /Users/nick/Desktop/acoustid-server
**HEAD SHA:** 8a540df24b32fd5554378660c2e5e7dfbd3fbbb9

## File Evidence

### API Indicators (Priority #6 in detector.md)

| Indicator | Status | Path | Evidence |
|-----------|--------|------|----------|
| `manage.py` in project root | ✓ FOUND | ./manage.py | Flask-like Python API |
| Flask decorator patterns | ✓ FOUND | ./acoustid/web/app.py | `from flask import Flask`, `@app.route()` |
| `flask` in requirements.txt | ✓ FOUND | requirements.txt (line: flask==2.3.2) | Flask framework confirmed |
| Flask imports | ✓ FOUND | ./acoustid/web/utils.py, ./acoustid/web/app.py | Multiple Flask imports |

### Frontend Absence

| Indicator | Status | Evidence |
|-----------|--------|----------|
| No `react` in dependencies | ✓ CONFIRMED | Not in requirements.txt |
| No `package.json` with frontend | ✓ CONFIRMED | No package.json found |

## Detector Logic Trace

**Detection Path:** iOS → React Native → Flutter → CLI → (skip to) API #6

**API Detection (Priority #6):**
- Flask indicator set: 3+ indicators found (app.py, @app.route, flask in requirements)
- Confirmed API-only (no frontend files)
- Decision: API / Flask (HIGH confidence)

## Classification Result

| Property | Value |
|----------|-------|
| **Expected Class** | Python API (Flask) |
| **Actual Class** | API |
| **Confidence** | HIGH |
| **Verdict** | TRUE ✓ |

---
**Accuracy:** 100%
