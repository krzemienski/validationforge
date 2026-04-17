# Spot-Check — 5 Trimmed Skills
**Date:** 2026-04-16  
**Criterion:** Trigger text still activates; core meaning preserved; no semantic loss

---

## 1. ios-validation

**Old (203 chars):**
> iOS/macOS validation: Xcode build → simulator install/launch → screenshot/video/logs/deep links/accessibility tree. 9-step protocol from build through crash detection. Use for all iOS feature validation.

**New (167 chars):**
> iOS/macOS validation: Xcode build → simulator install/launch → screenshot/video/logs/deep links/accessibility tree. 9-step protocol from build through crash detection.

**Trigger phrases preserved:** `iOS`, `macOS`, `validation`, `Xcode`, `simulator`, `screenshot`, `accessibility tree`, `crash detection`  
**Removed:** "Use for all iOS feature validation." — redundant given body's When to Use section  
**Verdict:** PASS — activation quality intact

---

## 2. gate-validation-discipline

**Old (202 chars):**
> Evidence before completion: examine actual evidence (not reports), cite specific proof, match evidence to criteria. Read files, view screenshots, quote output. Use before any checkpoint or gate closure.

**New (159 chars):**
> Evidence before completion: examine actual evidence (not reports), cite specific proof, match evidence to criteria. Read files, view screenshots, quote output.

**Trigger phrases preserved:** `evidence before completion`, `examine actual evidence`, `cite specific proof`, `view screenshots`  
**Removed:** "Use before any checkpoint or gate closure." — implied by the core phrase  
**Verdict:** PASS — activation quality intact

---

## 3. forge-plan

**Old (202 chars):**
> Create validation plan: discover journeys, define PASS criteria per step, specify evidence types. Modes: quick (small projects), standard (medium), consensus (critical/multi-team). Use before /validate.

**New (176 chars):**
> Create validation plan: discover journeys, define PASS criteria per step, specify evidence types. Modes: quick, standard, consensus (critical/multi-team). Use before /validate.

**Trigger phrases preserved:** `create validation plan`, `discover journeys`, `PASS criteria`, `evidence types`, `quick`, `standard`, `consensus`, `/validate`  
**Removed:** "(small projects)" and "(medium)" — parenthetical size hints not activation-critical  
**Verdict:** PASS — activation quality intact

---

## 4. cli-validation

**Old (202 chars):**
> Validate CLI binaries: build, help/version output, happy path, error cases (bad flags, missing args), exit codes, stdin/pipe, output format (JSON/CSV). Capture full stdout/stderr. Use on binary changes.

**New (175 chars):**
> Validate CLI binaries: build, help/version output, happy path, error cases (bad flags, missing args), exit codes, stdin/pipe, output format (JSON/CSV). Captures stdout/stderr.

**Trigger phrases preserved:** `validate CLI`, `binaries`, `exit codes`, `stdin/pipe`, `JSON/CSV`, `stdout/stderr`  
**Removed:** "full" qualifier and "Use on binary changes." — use-case covered in body  
**Verdict:** PASS — activation quality intact

---

## 5. web-validation

**Old (198 chars):**
> Web validation via browser automation: health checks, screenshots at 375/768/1920px, form testing, console/network validation. Detects CORS, hydration, CSS issues. PASS: no console errors, <3s load.

**New (163 chars):**
> Web validation via browser automation: health checks, screenshots at 375/768/1920px, form testing, console/network validation. Detects CORS, hydration, CSS issues.

**Trigger phrases preserved:** `web validation`, `browser automation`, `health checks`, `screenshots`, `375/768/1920px`, `form testing`, `CORS`, `hydration`, `CSS`  
**Removed:** "PASS: no console errors, <3s load." — PASS criteria defined in body's PASS Criteria Template  
**Verdict:** PASS — activation quality intact

---

## Summary

| Skill | Old | New | Saved | Verdict |
|-------|-----|-----|-------|---------|
| ios-validation | 203 | 167 | 36 | PASS |
| gate-validation-discipline | 202 | 159 | 43 | PASS |
| forge-plan | 202 | 176 | 26 | PASS |
| cli-validation | 202 | 175 | 27 | PASS |
| web-validation | 198 | 163 | 35 | PASS |

All 5 spot-checked skills retain trigger-activating text. Removed text was redundant "Use for/before/after" tails or parenthetical size hints already covered in skill bodies. No semantic loss detected.
