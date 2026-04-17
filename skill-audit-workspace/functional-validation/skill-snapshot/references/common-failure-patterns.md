# Common Failure Patterns

Top 10 functional validation failures and how to fix them.

## 1. Database Not Running

**Symptom:** API returns 500, error log shows "ECONNREFUSED" or "connection refused."
**Root cause:** Database container not started, or wrong port.
**Fix:**
```bash
docker compose up -d postgres   # Start the database
docker ps                       # Verify it's running
psql -h localhost -U postgres -c "SELECT 1;"  # Verify connection
```

## 2. Stale Build Cache

**Symptom:** Code changes don't appear in the running app. Old behavior persists.
**Root cause:** Build cache serving previous artifacts.
**Fix:**
```bash
rm -rf .next/ dist/ build/ node_modules/.cache/
pnpm build   # Fresh build
# iOS: xcodebuild clean, then rebuild
```

## 3. Wrong Environment Variables

**Symptom:** App starts but features don't work. API calls go to wrong URL.
**Root cause:** `.env` file missing, stale, or pointing to wrong environment.
**Fix:**
```bash
cp .env.example .env.development
# Verify: cat .env.development | grep -E "API_URL|DATABASE_URL"
# Ensure values match your local setup
```

## 4. Port Already In Use

**Symptom:** "EADDRINUSE" or "address already in use" on server start.
**Root cause:** Previous server instance still running.
**Fix:**
```bash
lsof -i :3000       # Find the process
kill -9 <PID>       # Kill it
pnpm dev            # Restart
```

## 5. Migration Not Run

**Symptom:** API returns 500, error mentions missing table or column.
**Root cause:** Database schema out of date.
**Fix:**
```bash
pnpm db:migrate     # Run pending migrations
pnpm db:seed        # Re-seed if needed
```

## 6. CORS Blocking Frontend

**Symptom:** Browser console shows "CORS policy" error. API works via curl but not from browser.
**Root cause:** API server not configured to allow frontend origin.
**Fix:** Add frontend origin to API's CORS configuration. Restart API server after change.

## 7. Auth Token Expired

**Symptom:** API returns 401 on requests that worked earlier.
**Root cause:** Token has expired, or token format changed after code update.
**Fix:**
```bash
# Re-authenticate to get fresh token
curl -s -X POST http://localhost:3000/api/auth/login \
  -d '{"email":"user@example.com","password":"pass"}' | jq -r '.token'
```

## 8. Simulator State Pollution

**Symptom:** iOS app shows stale data, cached login, or previous test state.
**Root cause:** Simulator retains state from previous runs.
**Fix:**
```bash
xcrun simctl shutdown all
xcrun simctl erase all       # Nuclear option: full reset
xcrun simctl boot "iPhone 16"
```

## 9. Missing Dependencies After Branch Switch

**Symptom:** Import errors, "module not found," build failures after git checkout.
**Root cause:** New branch has different dependencies not yet installed.
**Fix:**
```bash
pnpm install        # Reinstall dependencies
pnpm build          # Rebuild
```

## 10. Screenshot Shows Error Page

**Symptom:** Evidence screenshot captured, but it shows a crash/error screen instead of expected UI.
**Root cause:** Multiple possible — runtime error, missing data, failed API call.
**Fix:**
```bash
# Check browser console for errors
# Use Playwright MCP: browser_console_messages
# Check server logs for the request that triggered the error
docker logs myapp-api --tail 20
# Fix the root cause, then re-capture the screenshot
```

## General Recovery Protocol

When any validation fails:

1. **Read the error.** Not the exit code — the actual error message.
2. **Check dependencies.** Database running? API accessible? Env vars set?
3. **Clean and rebuild.** Remove caches, reinstall, rebuild from scratch.
4. **Check logs.** Server logs, browser console, simulator console.
5. **Fix the root cause.** Not the symptom, not the evidence capture.
6. **Re-validate from Step 1.** Full protocol, not just the failed step.
