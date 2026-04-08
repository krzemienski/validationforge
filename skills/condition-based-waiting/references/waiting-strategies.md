# 8 Waiting Strategies

## 1. HTTP Health Poll

Wait for a server to respond to health checks.

```bash
wait_for_health() {
  local url="$1"
  local timeout="${2:-30}"
  local elapsed=0
  echo "Waiting for $url ..."
  until curl -sf -o /dev/null "$url" || [ $elapsed -ge $timeout ]; do
    sleep 1
    elapsed=$((elapsed + 1))
  done
  if [ $elapsed -ge $timeout ]; then
    echo "TIMEOUT: $url not ready after ${timeout}s"
    return 1
  fi
  echo "Ready: $url responded after ${elapsed}s"
}

# Usage: wait_for_health "http://localhost:3000/health" 30
```

**When to use:** Any server with a health endpoint. Prefer over port polling because a process can bind a port before it is ready to serve.

## 2. Port Availability

```bash
wait_for_port() {
  local host="${1:-localhost}" port="$2" timeout="${3:-30}" elapsed=0
  until nc -z "$host" "$port" 2>/dev/null || [ $elapsed -ge $timeout ]; do
    sleep 0.5; elapsed=$((elapsed + 1))
  done
  [ $elapsed -lt $timeout ] && echo "Ready: ${host}:${port}" || { echo "TIMEOUT"; return 1; }
}

# Usage: wait_for_port localhost 5432 15
```

**When to use:** Database servers, dev servers without health endpoints, any TCP service.

## 3. File Existence

```bash
wait_for_file() {
  local filepath="$1" timeout="${2:-60}" elapsed=0
  until [ -f "$filepath" ] || [ $elapsed -ge $timeout ]; do
    sleep 1; elapsed=$((elapsed + 1))
  done
  [ $elapsed -lt $timeout ] && echo "Ready: $filepath ($(wc -c < "$filepath") bytes)" || { echo "TIMEOUT"; return 1; }
}

# Usage: wait_for_file "./dist/index.js" 60
```

**When to use:** Build processes, code generation, file downloads.

## 4. Process Ready

```bash
wait_for_process() {
  local pattern="$1" timeout="${2:-30}" elapsed=0
  until pgrep -f "$pattern" > /dev/null || [ $elapsed -ge $timeout ]; do
    sleep 1; elapsed=$((elapsed + 1))
  done
  [ $elapsed -lt $timeout ] && echo "Ready: PID $(pgrep -f "$pattern" | head -1)" || { echo "TIMEOUT"; return 1; }
}

# Usage: wait_for_process "next-server" 30
```

**When to use:** Background services, daemon processes. Combine with health poll when possible.

## 5. Browser Content (Playwright MCP)

```
# Wait for text to appear
browser_wait_for(text: "Dashboard loaded")

# Wait for text to disappear (loading states)
browser_wait_for(textGone: "Loading...")

# Time-based (ONLY when no condition available)
browser_wait_for(time: 2)
```

**When to use:** SPA content, AJAX updates, dynamic DOM changes. Always prefer text/element over time-based.

## 6. iOS Simulator Boot

```bash
wait_for_simulator() {
  local device="${1:-iPhone 16}" timeout="${2:-60}" elapsed=0
  until xcrun simctl list devices | grep "$device" | grep -q "Booted" || [ $elapsed -ge $timeout ]; do
    sleep 2; elapsed=$((elapsed + 2))
  done
  [ $elapsed -lt $timeout ] && echo "Ready: $device booted" || { echo "TIMEOUT"; return 1; }
}

# Usage: xcrun simctl boot "iPhone 16" && wait_for_simulator "iPhone 16" 60
```

**When to use:** iOS validation. Boot takes 10-40s. Always wait before installing/launching apps.

## 7. Database Ready

```bash
wait_for_database() {
  local db_url="${1:-postgres://localhost:5432/mydb}" timeout="${2:-30}" elapsed=0
  until psql "$db_url" -c 'SELECT 1' > /dev/null 2>&1 || [ $elapsed -ge $timeout ]; do
    sleep 1; elapsed=$((elapsed + 1))
  done
  [ $elapsed -lt $timeout ] && echo "Ready: database accepting queries" || { echo "TIMEOUT"; return 1; }
}

# Usage: docker compose up -d postgres && wait_for_database "postgres://..." 30
```

**When to use:** Docker databases, migrations. `SELECT 1` verifies full readiness, not just port.

## 8. Log Pattern

```bash
wait_for_log_pattern() {
  local logfile="$1" pattern="$2" timeout="${3:-60}" elapsed=0
  until grep -q "$pattern" "$logfile" 2>/dev/null || [ $elapsed -ge $timeout ]; do
    sleep 1; elapsed=$((elapsed + 1))
  done
  [ $elapsed -lt $timeout ] && echo "Ready: $(grep "$pattern" "$logfile" | tail -1)" || { echo "TIMEOUT"; return 1; }
}

# Usage: npm run dev > server.log 2>&1 & && wait_for_log_pattern "server.log" "ready on" 30
```

**When to use:** Services that log readiness but don't expose health endpoints.
