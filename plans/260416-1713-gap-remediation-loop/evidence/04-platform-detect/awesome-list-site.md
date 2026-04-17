# Specimen 4: awesome-list-site

**Expected Class:** Fullstack
**Source:** /Users/nick/Desktop/awesome-list-site
**HEAD SHA:** 65eba6ab2e2158ce6b5bf5164b6b1276430dd0bc

## File Evidence

### Frontend Indicators

| Indicator | Status | Path | Evidence |
|-----------|--------|------|----------|
| React framework | ✓ FOUND | package.json (root) | `@radix-ui/react-*` deps, React UI components |
| Frontend build config | ✓ FOUND | components.json | Radix/shadcn UI config |
| `package.json` with `react` deps | ✓ FOUND | package.json | React framework dependency |

### Backend Indicators

| Indicator | Status | Path | Evidence |
|-----------|--------|------|----------|
| Express API server | ✓ FOUND | package.json | `"express": "^4.21.2"` |
| Express routes | ✓ FOUND | server/ directory | Backend API code |
| API framework | ✓ FOUND | package.json | `express-rate-limit`, `swagger-ui-express` |

## Detector Logic Trace

**Detection Path:** iOS → React Native → Flutter → CLI → API → Web → **FULLSTACK (Priority #7)**

**Fullstack Detection (Priority #7):**
- Frontend indicators: React framework + build config (PRIMARY)
- Backend indicators: Express server + routes (PRIMARY)
- **BOTH** frontend AND backend indicators present
- Decision: Fullstack (HIGH confidence)

## Classification Result

| Property | Value |
|----------|-------|
| **Expected Class** | Fullstack |
| **Actual Class** | Fullstack |
| **Frontend** | React + Radix UI |
| **Backend** | Express.js |
| **Confidence** | HIGH |
| **Verdict** | TRUE ✓ |

---
**Accuracy:** 100%
