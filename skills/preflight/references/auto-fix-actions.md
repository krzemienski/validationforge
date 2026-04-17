# Auto-Fix Actions

When a preflight check fails, attempt automatic resolution before reporting BLOCKED.

## Auto-Fix Table

| Failed Check | Auto-Fix Command | Manual Fix Instructions |
|---|---|---|
| Port in use | `lsof -ti:PORT \| xargs kill -9` | Find and stop the process using the port |
| Dev server not running | `pnpm dev > /tmp/dev-server.log 2>&1 &` then `sleep 3` | Start the dev server manually |
| Database not running | `brew services start postgresql@16` or `sudo systemctl start postgresql` | Start your database service |
| Database not seeded | `npx prisma db seed \|\| npm run seed` | Run your project's seed script |
| Dependencies not installed | `pnpm install \|\| npm install` | Run your package manager's install |
| Simulator not booted | `xcrun simctl boot "iPhone 16" \|\| xcrun simctl boot "iPhone 15"` | Open Simulator.app and boot a device |
| Evidence dir missing | `mkdir -p e2e-evidence/` | Create the directory manually |
| .env file missing | `cp .env.example .env` | Copy and fill in the example env file |
| jq not installed | `brew install jq` | Install jq via your package manager |
| Binary not built | `pnpm build \|\| cargo build \|\| go build` | Run the project's build command |
| Xcode CLI tools missing | `xcode-select --install` | Install via Xcode preferences |
| Migrations pending | `npx prisma migrate deploy \|\| npx drizzle-kit push` | Run your migration tool |

## Auto-Fix Rules

- Attempt auto-fix **once** per failed check
- If auto-fix fails, report as BLOCKED with manual instructions
- Never auto-fix by installing major tools (Xcode, Docker) — report as BLOCKED
- Always re-check after auto-fix to confirm resolution

## Platform Detection Script

```bash
# Enable nullglob so unmatched *.xcodeproj / *.xcworkspace globs expand to
# nothing instead of the literal pattern. Without this, quoted globs like
# `[ -d "*.xcodeproj" ]` test for a directory literally named "*.xcodeproj"
# and iOS projects go undetected.
shopt -s nullglob
xcode_projs=( *.xcodeproj *.xcworkspace )
shopt -u nullglob

if [ -f "Package.swift" ] || [ ${#xcode_projs[@]} -gt 0 ]; then
  PLATFORM="ios"
elif [ -f "next.config.js" ] || [ -f "next.config.ts" ] || [ -f "next.config.mjs" ]; then
  PLATFORM="web"
elif [ -f "package.json" ] && grep -q '"express"\|"fastify"\|"hono"\|"koa"' package.json 2>/dev/null; then
  PLATFORM="api"
elif [ -f "Cargo.toml" ] || [ -f "setup.py" ] || [ -f "pyproject.toml" ] || [ -f "go.mod" ]; then
  PLATFORM="cli"
elif [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
  PLATFORM="fullstack"
else
  PLATFORM="unknown"
fi
echo "Detected platform: $PLATFORM"
```

Note: this bash must run as `bash` (not `sh`/`dash`) because `shopt` is a
bash builtin and array syntax `( ... )` requires bash. The reference script
for programmatic detection is `./scripts/detect-platform.sh`, which uses
`find -maxdepth` for POSIX-compatible platform discovery.

## Evidence Directory Setup

```bash
mkdir -p e2e-evidence/baseline/
mkdir -p e2e-evidence/screenshots/
mkdir -p e2e-evidence/api-responses/
```

Subdirectory purposes:
- `baseline/` — Used by `baseline-quality-assessment` for immutable "before" evidence
- `screenshots/` — Used by `e2e-validate` for UI capture
- `api-responses/` — Used by `e2e-validate` for API response capture
- Root `e2e-evidence/` — Used by `gate-validation-discipline` for post-change evidence
