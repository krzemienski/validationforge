# Platform-Specific Preflight Checklists

## Web Applications

| Check | Command | Expected | Severity |
|-------|---------|----------|----------|
| Node.js installed | `node --version` | `v18+` or `v20+` | CRITICAL |
| Package manager available | `pnpm --version \|\| npm --version` | Version number | CRITICAL |
| Dependencies installed | `ls node_modules/.package-lock.json 2>/dev/null` | File exists | CRITICAL |
| Dev server running | `curl -sf http://localhost:3000 >/dev/null` | Exit code 0 | CRITICAL |
| Dev server port available | `lsof -ti :3000` | PID or empty | HIGH |
| Browser automation available | `which playwright 2>/dev/null` | Available | HIGH |
| Environment variables set | `cat .env \| grep -c "="` | Non-zero count | HIGH |
| Evidence directory exists | `ls -d e2e-evidence/ 2>/dev/null` | Directory exists | LOW |

## API Services

| Check | Command | Expected | Severity |
|-------|---------|----------|----------|
| Server running | `curl -sf http://localhost:3000/api/health` | 200 response | CRITICAL |
| Database running | `pg_isready -h localhost 2>/dev/null \|\| mysql -e "SELECT 1"` | Ready | CRITICAL |
| Database seeded | `curl -sf http://localhost:3000/api/users \| jq length` | Non-zero | HIGH |
| Auth tokens available | `echo $AUTH_TOKEN \| wc -c` | > 10 characters | HIGH |
| curl available | `which curl` | Path to binary | CRITICAL |
| jq available | `which jq` | Path to binary | HIGH |
| Health endpoint responding | `curl -sf http://localhost:3000/api/health \| jq .status` | `"ok"` | CRITICAL |
| Evidence directory exists | `ls -d e2e-evidence/ 2>/dev/null` | Directory exists | LOW |

## iOS Applications

| Check | Command | Expected | Severity |
|-------|---------|----------|----------|
| Xcode installed | `xcodebuild -version` | Version number | CRITICAL |
| Xcode CLI tools | `xcode-select -p` | Path to tools | CRITICAL |
| Simulator runtime | `xcrun simctl list runtimes \| grep -i ios` | Runtime listed | CRITICAL |
| Simulator booted | `xcrun simctl list devices \| grep Booted` | One booted | CRITICAL |
| Scheme exists | `xcodebuild -list 2>/dev/null \| grep -A 20 Schemes` | Scheme listed | HIGH |
| Build succeeds | `xcodebuild build -scheme [Scheme] ...` | `BUILD SUCCEEDED` | CRITICAL |
| CocoaPods / SPM resolved | `ls Pods/ 2>/dev/null \|\| ls .build/` | Present | HIGH |
| Evidence directory exists | `ls -d e2e-evidence/ 2>/dev/null` | Directory exists | LOW |

## CLI Applications

| Check | Command | Expected | Severity |
|-------|---------|----------|----------|
| Build tool installed | `which cargo \|\| which go \|\| which python3` | Path | CRITICAL |
| Binary compiles | `cargo build \|\| go build \|\| python3 -c "import main"` | Exit 0 | CRITICAL |
| Runtime available | `./target/debug/cli --version` | Version output | HIGH |
| Help text works | `./cli --help 2>&1 \| head -5` | Usage info | HIGH |
| Input test files | `ls test-data/ 2>/dev/null` | Files present | MEDIUM |
| Evidence directory exists | `ls -d e2e-evidence/ 2>/dev/null` | Directory exists | LOW |

## Fullstack (bottom-up order)

Run checks in dependency order — each layer depends on the one below:

1. **Database layer** — Database running, migrations applied, data seeded
2. **API layer** — Server running, health endpoint responding, auth available
3. **Frontend layer** — Dev server running, pages rendering, browser automation ready
4. **Evidence layer** — Evidence directory created

If a lower layer fails, do not check higher layers — fix bottom-up.
