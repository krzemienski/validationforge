# Validation Plan: API Rename

**Scenario:** API endpoint renamed from `/api/v1/users` to `/api/v2/users`
**Date:** 2026-04-01
**Planner:** ValidationForge api-validation protocol

## Context

The backend team renamed the users endpoint as part of a v2 API migration.
All clients must be validated against the new endpoint before the old one is
decommissioned. This plan covers the API-level validation journeys.

## Journeys to Validate

### Journey 1: Renamed Endpoint Reachability
**PASS Criteria:**
- GET `/api/v2/users` returns HTTP 200
- Response body contains `users` array (not empty)
- Each user object has `id` (integer), `name` (string), `email` (string)
- Old endpoint `/api/v1/users` returns HTTP 404

**Evidence Required:**
- `step-01-api-response.json` — raw HTTP request/response with full headers and body
- `step-02-field-check.json` — schema validation results for each required field

### Journey 2: Authentication Flow
**PASS Criteria:**
- Authenticated GET `/api/v2/users` with valid JWT returns 200
- Unauthenticated GET `/api/v2/users` returns 401
- Expired JWT returns 401 with `{"error":"token_expired"}`

**Evidence Required:**
- `step-03-auth-valid.json` — authenticated request response
- `step-04-auth-invalid.json` — unauthenticated request response
- `step-05-auth-expired.json` — expired token response

## Pre-flight Checks

1. Backend service running on `localhost:3000`
2. Test user account available with valid JWT
3. Old endpoint still accessible for 404 check

## Execution Order

1. Run pre-flight (service health check)
2. Execute Journey 1 (reachability)
3. Execute Journey 2 (auth flow)
4. Write verdict to `e2e-evidence/report.md`
