# Timeout Patterns & Anti-Patterns

## Standard Timeout Template

Every wait MUST include a timeout. Infinite waits are a critical defect.

```bash
TIMEOUT=30
ELAPSED=0
until CONDITION || [ $ELAPSED -ge $TIMEOUT ]; do
  sleep 1
  ELAPSED=$((ELAPSED + 1))
done
if [ $ELAPSED -ge $TIMEOUT ]; then
  echo "TIMEOUT after ${TIMEOUT}s waiting for: DESCRIPTION"
  # Capture diagnostic state
  ps aux | grep PROCESS_NAME
  lsof -i :PORT
  tail -20 LOGFILE
  exit 1
fi
```

## Recommended Timeouts

| Resource | Timeout | Rationale |
|----------|---------|-----------|
| HTTP health check | 30s | Most servers start in <10s |
| Port availability | 30s | TCP bind is fast once process starts |
| File creation | 60s | Builds can be slow |
| iOS Simulator boot | 90s | First boot is slow; warm boot is fast |
| Database ready | 30s | Docker containers need initialization |
| Browser content | 15s | SPA rendering should be fast |
| Process start | 30s | Process spawn is usually quick |
| Log pattern | 60s | Depends on service startup complexity |

## Anti-Patterns

| # | Bad Pattern | Why It Fails | Correct Pattern |
|---|------------|--------------|-----------------|
| 1 | `sleep 10` | Arbitrary; wastes time or is insufficient | `until CONDITION; do sleep 1; done` |
| 2 | `sleep 60 && curl ...` | Server may be ready in 2s, wasting 58s | `wait_for_health URL 60` |
| 3 | No timeout on wait loop | Could block forever | Always include `$ELAPSED -ge $TIMEOUT` |
| 4 | `sleep 5` between unrelated steps | May not need any wait | Only wait for async dependencies |
| 5 | Fixed `sleep 30` between retries | Wastes time on fast recoveries | Exponential backoff: 1, 2, 4, 8 |
| 6 | `sleep 2` after `kill` | Process may take longer | `until ! pgrep -f PROCESS; do sleep 0.5; done` |
| 7 | `sleep 10` after migration | May finish in 1s or take 30s | Check migration status or log pattern |
| 8 | Hardcoded sleep in CI | CI machines vary in speed | Condition-based waits adapt automatically |

## Platform-Specific Wait Patterns

| Platform | Scenario | Implementation |
|----------|---------|----------------|
| **iOS** | Simulator boot | `wait_for_simulator "iPhone 16" 90` |
| **iOS** | App launch | `wait_for_process "MyApp" && wait_for_log_pattern` |
| **Web** | Dev server ready | `wait_for_health "http://localhost:3000" 30` |
| **Web** | SPA content rendered | `browser_wait_for(text: "Dashboard")` |
| **API** | Server ready | `wait_for_health "http://localhost:8080/health" 30` |
| **API** | Database seeded | `wait_for_log_pattern "seed.log" "Seeding complete"` |
| **CLI** | Build artifact | `wait_for_file "./dist/cli" 60` |
| **Docker** | Container healthy | `docker inspect --format='{{.State.Health.Status}}'` |
| **Fullstack** | All services | Chain: database -> API -> web (sequential waits) |

## Chaining Waits for Fullstack

```bash
docker compose up -d
wait_for_port localhost 5432 30          # Database first
wait_for_database "postgres://..." 15   # Verify queries work
wait_for_health "http://localhost:8080/health" 30  # API depends on DB
wait_for_health "http://localhost:3000" 30          # Frontend depends on API
echo "All services ready. Starting validation."
```
