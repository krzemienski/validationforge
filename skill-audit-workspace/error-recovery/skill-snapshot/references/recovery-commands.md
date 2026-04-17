# Recovery Commands by Error Type

## Build Failures
```bash
# Read the full error (not just the first line)
pnpm build 2>&1 | tail -50

# TypeScript errors — check the specific file
cat -n src/components/Widget.tsx | head -60

# After fixing, rebuild and verify
pnpm build 2>&1 | tail -5
```

## Runtime Crashes
```bash
# Start with log output visible
pnpm dev 2>&1 &
sleep 3

# Check if process is still alive
pgrep -f "next dev" || echo "CRASHED — check output above"

# For Node.js — check for unhandled rejections
NODE_OPTIONS="--unhandled-rejections=throw" pnpm dev 2>&1 | head -30
```

## Network / Connection Errors
```bash
# Is the target server running?
curl -sf http://localhost:3000/api/health && echo "UP" || echo "DOWN"

# What's listening on the expected port?
lsof -i :3000 | head -5

# Check server logs
tail -50 /tmp/server.log 2>/dev/null || echo "No log file found"
```

## Auth Failures
```bash
# Check if token is expired
echo "$AUTH_TOKEN" | cut -d. -f2 | base64 -d 2>/dev/null | jq .exp

# Re-authenticate
curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password"}' | jq .

# Verify the token works
curl -s http://localhost:3000/api/me \
  -H "Authorization: Bearer $AUTH_TOKEN" | jq .status
```

## Database Errors
```bash
# Is the database running?
pg_isready -h localhost -p 5432 && echo "RUNNING" || echo "NOT RUNNING"

# Start it
brew services start postgresql@16 2>/dev/null || sudo systemctl start postgresql

# Check migrations
npx prisma migrate status 2>&1 || npx drizzle-kit check 2>&1

# Re-run migrations
npx prisma migrate deploy 2>&1

# Re-seed
npx prisma db seed 2>&1 || npm run seed 2>&1
```

## Port Already in Use
```bash
# Find and kill what's using the port
lsof -ti :3000 | xargs kill -9 2>/dev/null

# Verify port is free
lsof -ti :3000 && echo "STILL IN USE" || echo "PORT FREE"
```

## Dependency Missing
```bash
# Node.js
pnpm install 2>&1 | tail -5

# Python
pip install -r requirements.txt 2>&1 | tail -5

# System tools
which curl || brew install curl
which jq || brew install jq
```

## Configuration Errors
```bash
# Check for .env file
ls -la .env .env.local .env.development 2>/dev/null

# Check required vars
env | grep -E "DATABASE_URL|API_KEY|SECRET" | head -10

# Copy from example
cp .env.example .env 2>/dev/null && echo "Copied .env.example"

# Validate JSON config
node -e "require('./config.json')" 2>&1 || echo "Invalid JSON"
```

## iOS Simulator Issues
```bash
# Check simulator status
xcrun simctl list devices | grep -E "Booted|iPhone"

# Boot a simulator
xcrun simctl boot "iPhone 16" 2>/dev/null || xcrun simctl boot "iPhone 15"

# Reset if corrupted
xcrun simctl erase booted

# Rebuild
xcodebuild -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -10
```
