# Evidence Capture Commands

Platform-specific commands for capturing validation evidence. All evidence
should be saved to `e2e-evidence/` in the project root.

```bash
mkdir -p e2e-evidence
```

## iOS / macOS

```bash
# Screenshot (simulator)
xcrun simctl io booted screenshot e2e-evidence/screen-name.png

# Screenshot (specific device)
xcrun simctl io <UDID> screenshot e2e-evidence/screen-name.png

# Video recording
xcrun simctl io booted recordVideo e2e-evidence/flow-name.mp4
# Press Ctrl+C to stop recording

# App container (for inspecting local data)
xcrun simctl get_app_container booted com.example.MyApp data

# System log capture
xcrun simctl spawn booted log show --last 5m --predicate \
  'subsystem == "com.example.MyApp"' > e2e-evidence/app-logs.txt

# Accessibility tree (via idb)
UDID=$(xcrun simctl list devices booted | grep -Eo '[0-9A-F-]{36}' | head -1)
idb ui describe-all --udid "$UDID" > e2e-evidence/accessibility-tree.txt

# Launch app and capture
xcrun simctl launch booted com.example.MyApp
sleep 2
xcrun simctl io booted screenshot e2e-evidence/after-launch.png
```

## Web Frontend

```bash
# Using Playwright MCP (preferred)
# browser_navigate → browser_snapshot → browser_take_screenshot

# Using curl for static content
curl -s http://localhost:3000 | head -50 > e2e-evidence/homepage-html.txt

# Page title verification
curl -s http://localhost:3000 | grep -o '<title>.*</title>' > e2e-evidence/page-title.txt

# Network waterfall (browser DevTools export)
# Chrome: Network tab → Right-click → Save all as HAR
# Save to: e2e-evidence/network-waterfall.har

# Console errors capture
# Use Playwright MCP: browser_console_messages

# Full page screenshot via Playwright
# browser_take_screenshot with fullPage: true, filename: "e2e-evidence/full-page.png"
```

## Backend API

```bash
# GET request with full response
curl -s -w "\nHTTP_CODE:%{http_code}\nTIME:%{time_total}s\n" \
  http://localhost:3000/api/users | jq . > e2e-evidence/users-get.json

# POST with JSON body
curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"pass123"}' \
  | jq . > e2e-evidence/login-response.json

# Authenticated request
TOKEN=$(jq -r '.token' e2e-evidence/login-response.json)
curl -s http://localhost:3000/api/users/me \
  -H "Authorization: Bearer $TOKEN" \
  | jq . > e2e-evidence/profile-response.json

# Health check with timing
curl -s -o e2e-evidence/health.json -w "%{http_code} %{time_total}s\n" \
  http://localhost:3000/api/health

# Response headers
curl -s -I http://localhost:3000/api/users \
  > e2e-evidence/users-headers.txt

# Error response capture
curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"wrong@example.com","password":"wrong"}' \
  | jq . > e2e-evidence/login-error.json
```

## CLI Tools

```bash
# Basic execution with stdout/stderr capture
./bin/mytool process --input data.csv > e2e-evidence/process-stdout.txt 2>&1

# Version info
./bin/mytool --version > e2e-evidence/version.txt 2>&1

# Help output
./bin/mytool --help > e2e-evidence/help-output.txt 2>&1

# Timed execution
time ./bin/mytool process --input data.csv > e2e-evidence/timed-output.txt 2>&1

# Exit code capture
./bin/mytool validate --config config.yaml; echo "EXIT_CODE: $?" \
  >> e2e-evidence/validate-output.txt

# Large output with truncation
./bin/mytool analyze --verbose 2>&1 | head -100 > e2e-evidence/analyze-head.txt
./bin/mytool analyze --verbose 2>&1 | tail -50 > e2e-evidence/analyze-tail.txt
```

## Database

```bash
# PostgreSQL — verify connection and data
psql -h localhost -U postgres -d myapp_dev \
  -c "SELECT count(*) as user_count FROM users;" \
  > e2e-evidence/db-user-count.txt

# PostgreSQL — schema verification
psql -h localhost -U postgres -d myapp_dev \
  -c "\dt" > e2e-evidence/db-tables.txt

# PostgreSQL — recent data
psql -h localhost -U postgres -d myapp_dev \
  -c "SELECT id, email, created_at FROM users ORDER BY created_at DESC LIMIT 5;" \
  > e2e-evidence/db-recent-users.txt

# SQLite
sqlite3 data/app.db ".tables" > e2e-evidence/sqlite-tables.txt
sqlite3 data/app.db "SELECT count(*) FROM observations;" \
  > e2e-evidence/sqlite-count.txt

# Docker container logs (for containerized databases)
docker logs myapp-postgres --tail 20 > e2e-evidence/postgres-logs.txt
```

## Build Output

```bash
# Xcode build with log capture
xcodebuild -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | tail -30 > e2e-evidence/xcode-build.txt

# Next.js / Node build
pnpm build 2>&1 | tee e2e-evidence/nextjs-build.txt

# Go build
go build -v ./... 2>&1 > e2e-evidence/go-build.txt

# Rust build
cargo build --release 2>&1 | tee e2e-evidence/cargo-build.txt

# Docker build
docker build -t myapp:latest . 2>&1 | tail -20 > e2e-evidence/docker-build.txt
```

## Server Logs

```bash
# Docker container logs
docker logs myapp-api --tail 50 > e2e-evidence/api-server-logs.txt
docker logs myapp-api --since 5m > e2e-evidence/recent-server-logs.txt

# Process logs (backgrounded server)
# If server was started with: pnpm start > server.log 2>&1 &
tail -50 server.log > e2e-evidence/server-tail.txt

# systemd service logs
journalctl -u myapp --since "5 minutes ago" > e2e-evidence/service-logs.txt

# Filter for errors only
docker logs myapp-api 2>&1 | grep -i "error\|warn\|fatal" \
  > e2e-evidence/error-logs.txt
```
