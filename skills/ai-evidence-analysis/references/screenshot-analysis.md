# Screenshot Analysis Reference

*Loaded by `ai-evidence-analysis` when analyzing screenshot evidence (`.png`/`.jpg`/`.webp`) and you need the vision-model prompt template, the `ScreenshotAnalysisResult` schema (PageLoadResult, ElementCheck, Finding), and PASS/WARN/FAIL example outputs.*

Vision model prompt templates, output schema definitions, and example analysis
output for AI-powered screenshot evidence analysis.

## Overview

Screenshot evidence is analyzed using a vision-capable model (Claude with vision).
The model receives the screenshot image alongside a structured prompt that targets
the three core questions validation needs to answer:

1. **Page load completeness** — Is the page fully rendered?
2. **Expected element presence** — Are key UI elements visible?
3. **Visual regressions** — Are there layout defects or unexpected states?

Every analysis produces a structured `ScreenshotAnalysisResult` with a `confidence`
score (0–100) and specific `findings` per observation category.

---

## Vision Model Prompt Template

Use this exact prompt structure when submitting a screenshot to the vision model.
Replace `{journey_name}` and `{expected_elements}` with the values from the active
validation plan.

```
You are a UI validation expert analyzing a screenshot captured as validation evidence.

Journey: {journey_name}
Expected elements: {expected_elements}

Analyze this screenshot and answer the following questions precisely:

### 1. Page Load Complete
Is the page fully rendered? Look for:
- Blank or white sections that should contain content
- Spinning loaders, skeleton screens, or progress indicators still visible
- Partially loaded images (broken image icons or blurred placeholders)
- "Loading..." text or shimmer animations

### 2. Expected Elements
For each element listed in "Expected elements" above, state whether it is:
- VISIBLE: clearly present and readable in the screenshot
- ABSENT: not found anywhere in the screenshot
- PARTIAL: present but obscured, truncated, or in an error state

### 3. Visual Regressions
Check for layout or rendering defects:
- Overlapping elements (two UI components occupying the same space)
- Text cut off mid-word or overflowing container boundaries
- Broken images (missing src, 404 placeholder icons)
- Misaligned columns, grids, or flex containers
- Unexpected error banners, toast messages, or modal dialogs
- Content outside safe area (mobile) or viewport clipping

### 4. Confidence Assessment
Based on observations 1–3, assign a confidence score (0–100):
- 90–100: Page is fully loaded, all expected elements visible, no layout defects
- 70–89: Page is mostly loaded, most expected elements visible, minor defects only
- 50–69: Page has notable issues — missing elements or visible but non-critical defects
- 30–49: Page has significant problems — multiple missing elements or layout breaks
- 0–29:  Page clearly failed to load, shows error state, or is blank

Respond ONLY with a JSON object matching the ScreenshotAnalysisResult schema below.
Do not include markdown fences or explanatory text outside the JSON.
```

---

## Output Schema

### `ScreenshotAnalysisResult`

```json
{
  "evidence_file": "e2e-evidence/journey-slug/step-03-dashboard.png",
  "evidence_type": "screenshot",
  "confidence": 85,
  "verdict_label": "PASS",
  "page_load_complete": {
    "complete": true,
    "indicators_found": [],
    "notes": "Page fully rendered. No loading states visible."
  },
  "expected_elements": [
    {
      "element": "navigation bar",
      "status": "VISIBLE",
      "notes": "Horizontal nav bar at top with 4 links visible"
    },
    {
      "element": "dashboard summary card",
      "status": "VISIBLE",
      "notes": "Card present with numeric metrics displayed"
    },
    {
      "element": "user avatar",
      "status": "ABSENT",
      "notes": "Top-right corner shows default icon; no user avatar loaded"
    }
  ],
  "visual_regressions": [
    {
      "severity": "LOW",
      "finding": "Sidebar navigation link text appears slightly truncated at 1280px width",
      "recommendation": "Check sidebar width and text-overflow CSS for long link labels"
    }
  ],
  "findings": [
    {
      "severity": "LOW",
      "finding": "User avatar did not load; displays fallback icon",
      "recommendation": "Verify avatar image URL and CDN availability in test environment"
    }
  ],
  "summary": "Dashboard page is fully rendered with core layout intact. Navigation, summary cards, and data table all visible. User avatar absent (fallback icon shown). One minor text truncation in sidebar.",
  "analyzed_at": "2025-01-15T14:32:00Z"
}
```

### Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `evidence_file` | string | yes | Relative path to the screenshot file analyzed |
| `evidence_type` | `"screenshot"` | yes | Always `"screenshot"` for this analysis type |
| `confidence` | integer 0–100 | yes | Overall confidence that the screenshot supports a PASS verdict |
| `verdict_label` | `"PASS"` \| `"WARN"` \| `"FAIL"` | yes | Recommended verdict derived from confidence and findings |
| `page_load_complete` | PageLoadResult | yes | Structured assessment of rendering completeness |
| `expected_elements` | ElementCheck[] | yes | Per-element visibility check results |
| `visual_regressions` | Finding[] | yes | Layout defects detected (empty array if none) |
| `findings` | Finding[] | yes | Consolidated finding list (all severities combined) |
| `summary` | string | yes | 1–3 sentence human-readable synthesis of the analysis |
| `analyzed_at` | ISO 8601 string | yes | Timestamp of when analysis was performed |

### `PageLoadResult` Schema

```json
{
  "complete": true,
  "indicators_found": ["spinner", "skeleton-screen"],
  "notes": "Spinner visible in top-right corner; page may not be fully settled"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `complete` | boolean | `true` if page appears fully rendered; `false` if loading indicators are present |
| `indicators_found` | string[] | List of loading state indicators observed (e.g. `"spinner"`, `"skeleton-screen"`, `"loading-text"`, `"blurred-image"`) |
| `notes` | string | Free-text description of the page load state |

### `ElementCheck` Schema

```json
{
  "element": "submit button",
  "status": "VISIBLE",
  "notes": "Blue 'Submit' button present below form fields"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `element` | string | The element name from the expected elements list |
| `status` | `"VISIBLE"` \| `"ABSENT"` \| `"PARTIAL"` | Visibility assessment |
| `notes` | string | Specific observation about the element's appearance or location |

**Status definitions:**

| Status | Meaning |
|--------|---------|
| `VISIBLE` | Element is clearly present, readable, and in expected location |
| `ABSENT` | Element is not found anywhere in the screenshot |
| `PARTIAL` | Element is present but truncated, obscured, error state, or wrong position |

### `Finding` Schema

```json
{
  "severity": "HIGH",
  "finding": "Error banner visible: '500 Internal Server Error'",
  "recommendation": "Investigate server-side error; check application logs for root cause"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `severity` | `"CRITICAL"` \| `"HIGH"` \| `"MEDIUM"` \| `"LOW"` | Impact level of the finding |
| `finding` | string | Specific factual observation — describe what IS visible, not what should be |
| `recommendation` | string | Actionable next step to investigate or remediate |

### Severity Definitions

| Severity | Definition | Screenshot Examples |
|----------|-----------|---------------------|
| `CRITICAL` | Feature is completely broken or invisible | Blank page, full error screen, core CTA missing |
| `HIGH` | Major functional concern visible | Error banner present, form submit button absent |
| `MEDIUM` | Noticeable defect, feature still usable | Element in wrong position, unexpected empty state |
| `LOW` | Polish issue only | Minor alignment drift, text slightly truncated |

### Verdict Label Rules

Derived automatically from `confidence` and `findings`:

| Condition | Verdict |
|-----------|---------|
| `confidence >= 70` AND no CRITICAL findings | `PASS` |
| `confidence >= 50` AND no CRITICAL findings AND MEDIUM or HIGH findings present | `WARN` |
| `confidence < 50` OR any CRITICAL finding | `FAIL` |

---

## Example Analysis Output

### Example 1: Full PASS — Login Page Loaded Correctly

**Screenshot:** `e2e-evidence/auth-journey/step-02-login-page.png`
**Journey:** User Authentication
**Expected elements:** `["login form", "email input", "password input", "Sign In button", "Forgot password link"]`

```json
{
  "evidence_file": "e2e-evidence/auth-journey/step-02-login-page.png",
  "evidence_type": "screenshot",
  "confidence": 96,
  "verdict_label": "PASS",
  "page_load_complete": {
    "complete": true,
    "indicators_found": [],
    "notes": "Page fully rendered. No loading indicators visible. Background image loaded."
  },
  "expected_elements": [
    {
      "element": "login form",
      "status": "VISIBLE",
      "notes": "White card centered on page containing all form fields"
    },
    {
      "element": "email input",
      "status": "VISIBLE",
      "notes": "Labeled 'Email address', placeholder text visible"
    },
    {
      "element": "password input",
      "status": "VISIBLE",
      "notes": "Labeled 'Password', shows masked input field"
    },
    {
      "element": "Sign In button",
      "status": "VISIBLE",
      "notes": "Blue button with white 'Sign In' text at bottom of form"
    },
    {
      "element": "Forgot password link",
      "status": "VISIBLE",
      "notes": "Underlined link below password field reading 'Forgot your password?'"
    }
  ],
  "visual_regressions": [],
  "findings": [],
  "summary": "Login page is fully loaded and renders correctly. All expected form elements are visible and properly labeled. No layout defects or unexpected states detected.",
  "analyzed_at": "2025-01-15T14:32:00Z"
}
```

---

### Example 2: WARN — Dashboard Missing Avatar, Minor Truncation

**Screenshot:** `e2e-evidence/dashboard-journey/step-05-dashboard-loaded.png`
**Journey:** Dashboard Rendering
**Expected elements:** `["navigation bar", "dashboard summary card", "user avatar", "activity feed"]`

```json
{
  "evidence_file": "e2e-evidence/dashboard-journey/step-05-dashboard-loaded.png",
  "evidence_type": "screenshot",
  "confidence": 72,
  "verdict_label": "WARN",
  "page_load_complete": {
    "complete": true,
    "indicators_found": [],
    "notes": "Main content area fully rendered. No loading states."
  },
  "expected_elements": [
    {
      "element": "navigation bar",
      "status": "VISIBLE",
      "notes": "Top nav bar with logo left and 4 links right, all readable"
    },
    {
      "element": "dashboard summary card",
      "status": "VISIBLE",
      "notes": "Three metric cards visible: Users (1,204), Revenue ($48,320), Sessions (9,871)"
    },
    {
      "element": "user avatar",
      "status": "ABSENT",
      "notes": "Top-right shows generic gray silhouette icon; user photo not loaded"
    },
    {
      "element": "activity feed",
      "status": "VISIBLE",
      "notes": "Feed shows 10 rows of activity items with timestamps"
    }
  ],
  "visual_regressions": [
    {
      "severity": "LOW",
      "finding": "Navigation link 'Account Settings' text truncated to 'Account Setti…' at current viewport width",
      "recommendation": "Increase nav container width or reduce font size for longer link labels"
    }
  ],
  "findings": [
    {
      "severity": "MEDIUM",
      "finding": "User avatar image did not load; fallback silhouette icon displayed",
      "recommendation": "Verify avatar CDN URL is accessible from test environment and image fetch is not blocked by CORS"
    },
    {
      "severity": "LOW",
      "finding": "Navigation link text truncated at current viewport width",
      "recommendation": "Check nav overflow CSS; ensure text-overflow: ellipsis or dynamic width is applied"
    }
  ],
  "summary": "Dashboard page is rendered with core metrics and activity feed visible. User avatar failed to load, showing fallback. Minor nav link truncation detected. Human review recommended for avatar load failure.",
  "analyzed_at": "2025-01-15T14:33:15Z"
}
```

---

### Example 3: FAIL — Error Page Rendered Instead of Expected Content

**Screenshot:** `e2e-evidence/checkout-journey/step-08-order-confirmation.png`
**Journey:** Checkout Flow
**Expected elements:** `["order confirmation number", "order summary table", "Continue Shopping button"]`

```json
{
  "evidence_file": "e2e-evidence/checkout-journey/step-08-order-confirmation.png",
  "evidence_type": "screenshot",
  "confidence": 8,
  "verdict_label": "FAIL",
  "page_load_complete": {
    "complete": false,
    "indicators_found": [],
    "notes": "Page rendered but shows error state, not confirmation content"
  },
  "expected_elements": [
    {
      "element": "order confirmation number",
      "status": "ABSENT",
      "notes": "No order number visible anywhere on screen"
    },
    {
      "element": "order summary table",
      "status": "ABSENT",
      "notes": "No table or list of order items present"
    },
    {
      "element": "Continue Shopping button",
      "status": "ABSENT",
      "notes": "No buttons matching this label found"
    }
  ],
  "visual_regressions": [
    {
      "severity": "CRITICAL",
      "finding": "Full-page error screen displayed: '500 — Something went wrong. Please try again.'",
      "recommendation": "Check server logs for unhandled exception during order confirmation processing"
    }
  ],
  "findings": [
    {
      "severity": "CRITICAL",
      "finding": "Server error page rendered instead of order confirmation; all expected elements absent",
      "recommendation": "Investigate checkout API endpoint for 500 errors; review server logs at time of capture"
    }
  ],
  "summary": "Order confirmation page failed to render. A 500 server error page is displayed instead of expected confirmation content. All three expected elements are absent. This is a FAIL — the checkout flow is broken.",
  "analyzed_at": "2025-01-15T14:41:02Z"
}
```

---

## Usage Notes

### Providing Expected Elements

The `{expected_elements}` placeholder in the prompt template should be populated
from the validation plan's journey definition. Use plain English element names that
map directly to visible UI components:

```
Good: "navigation bar", "Submit button", "error message", "product price"
Avoid: "nav[aria-label='main']", ".btn-primary", "#price-display"
```

CSS selectors and DOM identifiers are for automated testing — vision models work
with visual descriptions.

### When Page Load Complete is `false`

If `page_load_complete.complete` is `false`, the analysis result should be treated
as a **deferred FAIL** rather than a permanent FAIL. The correct remediation is:

1. Wait for the page to fully render (use `condition-based-waiting` skill)
2. Re-capture the screenshot
3. Re-run analysis on the fresh screenshot

Do not mark a journey FAIL solely because the screenshot was captured mid-load.

### Sidecar File Naming

Analysis results are saved as sidecar files alongside the original screenshot:

```
e2e-evidence/journey-slug/step-03-dashboard.png                ← original screenshot
e2e-evidence/journey-slug/ai-analysis-step-03-dashboard.json   ← this analysis result
```

The `verdict-writer` agent reads `ai-analysis-*.json` sidecar files when present to
incorporate AI findings into its PASS/FAIL verdict reasoning.

### Empty or Zero-Byte Screenshots

Screenshots that are 0 bytes are **invalid evidence**. Do not submit them to the
vision model. Instead, flag them immediately:

```json
{
  "evidence_file": "e2e-evidence/journey-slug/step-03-blank.png",
  "evidence_type": "screenshot",
  "confidence": 0,
  "verdict_label": "FAIL",
  "page_load_complete": { "complete": false, "indicators_found": [], "notes": "File is 0 bytes — invalid evidence" },
  "expected_elements": [],
  "visual_regressions": [],
  "findings": [
    {
      "severity": "CRITICAL",
      "finding": "Screenshot file is 0 bytes; no image data captured",
      "recommendation": "Re-capture screenshot using correct capture command; verify capture tool is functioning"
    }
  ],
  "summary": "Invalid evidence: screenshot file is empty (0 bytes). This evidence cannot support any verdict.",
  "analyzed_at": "2025-01-15T14:42:00Z"
}
```

---

## Related References

- `skills/visual-inspection/SKILL.md` — Manual visual checklist for human-led UI review
- `skills/ai-evidence-analysis/SKILL.md` — Full skill documentation including all three analysis types
- `skills/functional-validation/references/evidence-capture-commands.md` — How to capture screenshot evidence
- `skills/condition-based-waiting/` — Waiting for page load before screenshot capture
