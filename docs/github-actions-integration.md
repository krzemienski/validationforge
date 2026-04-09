# GitHub Actions Integration Guide

Run ValidationForge on every pull request — automatically. This guide walks you from zero to a working CI check that produces PASS/FAIL results with downloadable evidence artifacts.

---

## Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start (3 Steps)](#quick-start-3-steps)
3. [Workflow Breakdown](#workflow-breakdown)
4. [Platform-Specific Examples](#platform-specific-examples)
   - [Web (React / Next.js / Vite)](#web-react--nextjs--vite)
   - [API (Express / FastAPI / Rails)](#api-express--fastapi--rails)
   - [CLI Tools](#cli-tools)
   - [iOS / macOS Apps](#ios--macos-apps)
5. [Caching Strategy](#caching-strategy)
6. [Evidence Artifact Review](#evidence-artifact-review)
7. [Troubleshooting](#troubleshooting)
8. [FAQ](#faq)

---

## Prerequisites

Before the workflow runs successfully, you need:

### 1. ANTHROPIC_API_KEY Secret

ValidationForge drives Claude Code, which requires an Anthropic API key at runtime.

**Add the secret:**
1. Open your repository on GitHub
2. Go to **Settings → Secrets and variables → Actions**
3. Click **New repository secret**
4. Name: `ANTHROPIC_API_KEY`
5. Value: your key from [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys)
6. Click **Add secret**

The workflow references it as `${{ secrets.ANTHROPIC_API_KEY }}`. The value is never printed in logs.

### 2. Claude Code Billing

Claude Code calls the Anthropic API, which is a paid service. Each `/validate-ci` run makes multiple API calls. Ensure your Anthropic account has:

- An active payment method at [console.anthropic.com](https://console.anthropic.com)
- Sufficient credits or a usage limit set high enough for your team's PR volume
- API access enabled (not restricted to Claude.ai web only)

**Estimated cost per run:** Roughly $0.05–$0.30 for a typical web project validation, depending on the number of journeys and evidence captured.

### 3. GitHub Actions Enabled

GitHub Actions is on by default for public repositories. For private repositories:

- Go to **Settings → Actions → General**
- Ensure **Allow all actions and reusable workflows** (or a permissive policy) is selected

---

## Quick Start (3 Steps)

### Step 1 — Copy the template

```bash
mkdir -p .github/workflows
cp node_modules/validationforge/templates/github-actions-validate.yml \
   .github/workflows/validate.yml
```

Or download it directly:

```bash
curl -fsSL \
  https://raw.githubusercontent.com/krzemienski/validationforge/main/templates/github-actions-validate.yml \
  -o .github/workflows/validate.yml
```

Open the file and work through the `# TODO:` comments to set your platform, server command, and health URL. At minimum, set:

```yaml
env:
  VF_PLATFORM: "web"          # web | api | cli | ios
  SERVER_CMD: "npm run dev"   # how to start your server
  HEALTH_URL: "http://localhost:3000"  # URL to poll before validating
```

### Step 2 — Add the secret

```
GitHub → Your Repo → Settings → Secrets and variables → Actions → New repository secret

Name:  ANTHROPIC_API_KEY
Value: sk-ant-...
```

### Step 3 — Push and open a PR

```bash
git add .github/workflows/validate.yml
git commit -m "ci: add ValidationForge starter workflow"
git push origin my-branch
```

Open a pull request targeting `main` or `master`. Within a minute you will see a **ValidationForge** check appear on the PR. When the check completes, the result is either:

- ✅ **PASS** — all journeys passed, evidence archived
- ❌ **FAIL** — one or more journeys failed, download the evidence artifact and open `e2e-evidence/report.md` for full diagnosis

---

## Workflow Breakdown

The full workflow (`templates/github-actions-validate.yml`) runs eleven steps. Here is what each one does and why.

### Step 1 — Checkout

```yaml
- name: Checkout
  uses: actions/checkout@v4
  with:
    fetch-depth: 0
```

`fetch-depth: 0` pulls the full git history, which lets ValidationForge scope journey discovery to the files changed in this PR — making runs faster on large repositories.

### Step 2 — Set up Node.js

```yaml
- name: Set up Node.js
  uses: actions/setup-node@v4
  with:
    node-version: "20"
    cache: "npm"
    cache-dependency-path: "**/package-lock.json"
```

Installs Node.js and enables the built-in npm cache. The Claude Code CLI is a Node.js package, so Node.js is required even for non-JavaScript projects. Change `cache` to `"yarn"` or `"pnpm"` as appropriate; remove the `cache` lines entirely for projects with no `package.json`.

### Step 3 — Cache Claude Code CLI

```yaml
- name: Cache Claude Code CLI
  id: cache-claude
  uses: actions/cache@v4
  with:
    path: ~/.npm-global
    key: claude-code-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      claude-code-${{ runner.os }}-
```

The Claude CLI binary is installed into `~/.npm-global`. Caching this directory saves approximately 30 seconds on every run after the first. The cache key includes the OS and lock file hash — it invalidates when your dependencies change, which also updates Claude Code to its latest version.

See [Caching Strategy](#caching-strategy) for details.

### Step 4 — Install Claude Code CLI

```yaml
- name: Install Claude Code CLI
  run: |
    mkdir -p ~/.npm-global
    npm config set prefix ~/.npm-global
    echo "$HOME/.npm-global/bin" >> "$GITHUB_PATH"
    npm install -g @anthropic-ai/claude-code
    claude --version
```

Installs `@anthropic-ai/claude-code` globally into a user-writable prefix (avoids `sudo`). Adds the binary directory to `GITHUB_PATH` so subsequent steps can run `claude` directly. Prints the installed version to make debugging easier.

### Step 5 — Install ValidationForge

```yaml
- name: Install ValidationForge
  run: |
    curl -fsSL \
      https://raw.githubusercontent.com/krzemienski/validationforge/main/install.sh \
      | bash
```

Downloads and runs the ValidationForge installer. The script:
- Clones the ValidationForge repository to `~/.claude/plugins/validationforge`
- Copies rules to `~/.claude/rules/` with a `vf-` prefix
- Creates an `e2e-evidence/` directory in the workspace
- Writes `~/.claude/.vf-config.json` with default settings

The script is idempotent — running it multiple times is safe.

### Step 6 — Install project dependencies

```yaml
- name: Install project dependencies
  run: |
    if [ -f "package-lock.json" ]; then
      npm ci
    elif [ -f "yarn.lock" ]; then
      yarn install --frozen-lockfile
    elif [ -f "pnpm-lock.yaml" ]; then
      pnpm install --frozen-lockfile
    else
      echo "[VF] No Node.js lock file found — skipping JS dependency install"
    fi
```

Auto-detects your Node.js package manager and runs a frozen install. Replace this block with a single explicit command if you know which manager you use (e.g., `npm ci`). For Python, Ruby, or Go projects, add the language-specific install command here (e.g., `pip install -r requirements.txt`).

### Step 7 — Start dev server

```yaml
- name: Start dev server
  if: env.SERVER_CMD != ''
  run: |
    echo "[VF] Starting server: $SERVER_CMD"
    eval "$SERVER_CMD" &
    echo "SERVER_PID=$!" >> "$GITHUB_ENV"
```

Launches your server in the background using `eval` so that shell variables in `SERVER_CMD` expand correctly. The PID is saved to `GITHUB_ENV` for reference. This step is skipped entirely when `SERVER_CMD` is empty (e.g., CLI tool projects).

### Step 8 — Wait for server to be healthy

```yaml
- name: Wait for server to be healthy
  if: env.SERVER_CMD != '' && env.HEALTH_URL != ''
  run: |
    attempt=0
    max=${{ env.HEALTH_TIMEOUT }}
    while [ "$attempt" -lt "$max" ]; do
      status=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" 2>/dev/null || echo "000")
      if [ "$status" = "200" ]; then
        echo "[VF] Server healthy after ${attempt}s (HTTP $status)"
        exit 0
      fi
      sleep 1
      attempt=$((attempt + 1))
    done
    echo "::error title=Server Health Check Failed::..."
    exit 1
```

Polls `HEALTH_URL` once per second until it returns HTTP 200 or `HEALTH_TIMEOUT` seconds elapse. On timeout, emits a GitHub Actions error annotation with a clear message and exits 1. This prevents the validation step from running against a server that is not ready.

### Step 9 — Run ValidationForge

```yaml
- name: Run ValidationForge
  id: vf_run
  env:
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
  run: |
    VF_CMD="/validate-ci"
    if [ -n "$VF_PLATFORM" ]; then VF_CMD="$VF_CMD --platform $VF_PLATFORM"; fi
    if [ -n "$VF_SCOPE" ]; then VF_CMD="$VF_CMD --scope $VF_SCOPE"; fi
    echo "[VF] Running: claude --print \"$VF_CMD\""
    claude --print "$VF_CMD"
  continue-on-error: true
```

The core step. Runs `/validate-ci` non-interactively via `claude --print`. The command:
1. Auto-detects (or uses `--platform`) the project type
2. Discovers user journeys and auto-approves the plan
3. Runs each journey against the live system, capturing evidence
4. Writes `e2e-evidence/report.md`
5. Exits `0` (all PASS) or `1` (any FAIL)

`continue-on-error: true` allows the upload step to run even when validation fails.

### Step 10 — Upload validation evidence

```yaml
- name: Upload validation evidence
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: validation-evidence-${{ github.run_number }}
    path: e2e-evidence/
    retention-days: 30
    if-no-files-found: warn
```

Uploads all files in `e2e-evidence/` as a GitHub Actions artifact. The `if: always()` condition ensures evidence is uploaded even when the validation step failed — the evidence is most valuable precisely when things go wrong. `if-no-files-found: warn` prevents a false failure if evidence capture started but produced nothing (e.g., a very early preflight failure).

### Step 11 — Annotate failure

```yaml
- name: Annotate failure
  if: steps.vf_run.outcome == 'failure'
  run: |
    echo "::error title=ValidationForge FAIL::One or more validation journeys failed. ..."
    exit 1
```

When Step 9 fails, writes a visible error annotation on the PR that names the artifact to download, then exits 1 to mark the GitHub Check as failed. Engineers see the diagnosis instruction directly in the PR without having to open raw logs.

---

## Platform-Specific Examples

### Web (React / Next.js / Vite)

For single-page applications and server-rendered web apps.

```yaml
env:
  VF_PLATFORM: "web"
  VF_SCOPE: ""
  SERVER_CMD: "npm run dev"
  HEALTH_URL: "http://localhost:3000"
  HEALTH_TIMEOUT: "60"

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Cache Claude Code CLI
        uses: actions/cache@v4
        with:
          path: ~/.npm-global
          key: claude-code-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
          restore-keys: claude-code-${{ runner.os }}-

      - name: Install Claude Code CLI
        run: |
          mkdir -p ~/.npm-global && npm config set prefix ~/.npm-global
          echo "$HOME/.npm-global/bin" >> "$GITHUB_PATH"
          npm install -g @anthropic-ai/claude-code

      - name: Install ValidationForge
        run: curl -fsSL https://raw.githubusercontent.com/krzemienski/validationforge/main/install.sh | bash

      - name: Install dependencies
        run: npm ci

      - name: Start dev server
        run: npm run dev &

      - name: Wait for server
        run: |
          for i in $(seq 1 60); do
            curl -sf http://localhost:3000 > /dev/null && exit 0
            sleep 1
          done
          echo "Server did not start" && exit 1

      - name: Run ValidationForge
        id: vf_run
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: claude --print "/validate-ci --platform web"
        continue-on-error: true

      - name: Upload evidence
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: validation-evidence-${{ github.run_number }}
          path: e2e-evidence/
          retention-days: 30
          if-no-files-found: warn

      - name: Fail on ValidationForge error
        if: steps.vf_run.outcome == 'failure'
        run: exit 1
```

**Vite port:** Change `HEALTH_URL` to `http://localhost:5173`. Vite's default port is 5173.

**pnpm:** Add `uses: pnpm/action-setup@v4` before `setup-node` and change `cache: "pnpm"` with `cache-dependency-path: "**/pnpm-lock.yaml"`.

### API (Express / FastAPI / Rails)

For backend services and REST/GraphQL APIs.

```yaml
env:
  VF_PLATFORM: "api"
  SERVER_CMD: "node src/server.js"
  HEALTH_URL: "http://localhost:8000/health"
  HEALTH_TIMEOUT: "60"

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Cache Claude Code CLI
        uses: actions/cache@v4
        with:
          path: ~/.npm-global
          key: claude-code-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
          restore-keys: claude-code-${{ runner.os }}-

      - name: Install Claude Code CLI
        run: |
          mkdir -p ~/.npm-global && npm config set prefix ~/.npm-global
          echo "$HOME/.npm-global/bin" >> "$GITHUB_PATH"
          npm install -g @anthropic-ai/claude-code

      - name: Install ValidationForge
        run: curl -fsSL https://raw.githubusercontent.com/krzemienski/validationforge/main/install.sh | bash

      - name: Install dependencies
        run: npm ci

      - name: Start API server
        run: node src/server.js &

      - name: Wait for API to be healthy
        run: |
          for i in $(seq 1 60); do
            curl -sf http://localhost:8000/health > /dev/null && exit 0
            sleep 1
          done
          echo "API did not start" && exit 1

      - name: Run ValidationForge
        id: vf_run
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: claude --print "/validate-ci --platform api"
        continue-on-error: true

      - name: Upload evidence
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: validation-evidence-${{ github.run_number }}
          path: e2e-evidence/
          retention-days: 30
          if-no-files-found: warn

      - name: Fail on ValidationForge error
        if: steps.vf_run.outcome == 'failure'
        run: exit 1
```

**FastAPI (Python):** Replace the install and server steps:

```yaml
      - uses: actions/setup-python@v5
        with: { python-version: "3.12" }

      - name: Install Python dependencies
        run: pip install -r requirements.txt

      - name: Start FastAPI server
        run: uvicorn app.main:app --host 0.0.0.0 --port 8000 &
```

**Ruby on Rails:** Replace server start with:

```yaml
      - name: Install Ruby dependencies
        run: bundle install

      - name: Start Rails server
        run: bundle exec rails server -p 3000 &

      # Then set HEALTH_URL: "http://localhost:3000/up"
```

### CLI Tools

For command-line tools that require no running server.

```yaml
env:
  VF_PLATFORM: "cli"
  SERVER_CMD: ""    # no server needed
  HEALTH_URL: ""    # no health check needed

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Cache Claude Code CLI
        uses: actions/cache@v4
        with:
          path: ~/.npm-global
          key: claude-code-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
          restore-keys: claude-code-${{ runner.os }}-

      - name: Install Claude Code CLI
        run: |
          mkdir -p ~/.npm-global && npm config set prefix ~/.npm-global
          echo "$HOME/.npm-global/bin" >> "$GITHUB_PATH"
          npm install -g @anthropic-ai/claude-code

      - name: Install ValidationForge
        run: curl -fsSL https://raw.githubusercontent.com/krzemienski/validationforge/main/install.sh | bash

      - name: Install dependencies
        run: npm ci

      # No "Start server" or "Wait for server" steps needed for CLI tools

      - name: Run ValidationForge
        id: vf_run
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: claude --print "/validate-ci --platform cli"
        continue-on-error: true

      - name: Upload evidence
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: validation-evidence-${{ github.run_number }}
          path: e2e-evidence/
          retention-days: 30
          if-no-files-found: warn

      - name: Fail on ValidationForge error
        if: steps.vf_run.outcome == 'failure'
        run: exit 1
```

ValidationForge validates CLI tools by invoking the binary directly and inspecting `stdout`, `stderr`, and exit codes as evidence. No browser or HTTP server is involved.

### iOS / macOS Apps

For iOS and macOS apps built with Xcode. Requires a `macos-latest` runner so the iOS Simulator is available.

```yaml
env:
  VF_PLATFORM: "ios"
  SERVER_CMD: ""    # VF drives the Simulator directly
  HEALTH_URL: ""

jobs:
  validate:
    runs-on: macos-latest   # REQUIRED — Ubuntu cannot run iOS Simulator
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          # No npm cache needed unless your iOS project has a JS layer

      - name: Cache Claude Code CLI
        uses: actions/cache@v4
        with:
          path: ~/.npm-global
          key: claude-code-${{ runner.os }}-v1
          restore-keys: claude-code-${{ runner.os }}-

      - name: Install Claude Code CLI
        run: |
          mkdir -p ~/.npm-global && npm config set prefix ~/.npm-global
          echo "$HOME/.npm-global/bin" >> "$GITHUB_PATH"
          npm install -g @anthropic-ai/claude-code

      - name: Install ValidationForge
        run: curl -fsSL https://raw.githubusercontent.com/krzemienski/validationforge/main/install.sh | bash

      - name: Boot iOS Simulator
        run: |
          DEVICE_ID=$(xcrun simctl list devices available -j \
            | jq -r '.devices | to_entries[] | .value[] | select(.name | contains("iPhone 15")) | .udid' \
            | head -1)
          xcrun simctl boot "$DEVICE_ID"
          echo "SIMULATOR_ID=$DEVICE_ID" >> "$GITHUB_ENV"

      - name: Run ValidationForge
        id: vf_run
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: claude --print "/validate-ci --platform ios"
        continue-on-error: true

      - name: Upload evidence
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: validation-evidence-${{ github.run_number }}
          path: e2e-evidence/
          retention-days: 30
          if-no-files-found: warn

      - name: Fail on ValidationForge error
        if: steps.vf_run.outcome == 'failure'
        run: exit 1
```

> **Important:** `macos-latest` runners are billed at approximately 10× the rate of `ubuntu-latest`. For cost efficiency, trigger iOS validation only on PRs targeting `main`, not on every push.

---

## Caching Strategy

The workflow uses two levels of caching to minimize run time.

### Node.js dependency cache (actions/setup-node)

```yaml
- uses: actions/setup-node@v4
  with:
    cache: "npm"
    cache-dependency-path: "**/package-lock.json"
```

Caches the npm module cache (`~/.npm`). On a cache hit, `npm ci` skips re-downloading packages and reads from disk instead. Saves 30–120 seconds depending on your `node_modules` size. The cache invalidates when any `package-lock.json` in the repository changes.

### Claude Code CLI cache (actions/cache)

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.npm-global
    key: claude-code-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      claude-code-${{ runner.os }}-
```

Caches the globally-installed Claude Code CLI binary in `~/.npm-global`. On a cache hit, the `npm install -g @anthropic-ai/claude-code` step completes in under a second instead of 20–30 seconds.

**Cache key design:**

| Key component | Purpose |
|---------------|---------|
| `claude-code-` | Namespace — prevents collision with other caches |
| `${{ runner.os }}` | Linux vs macOS binaries are different |
| `${{ hashFiles('**/package-lock.json') }}` | Invalidates the cache when dependencies change, pulling the latest Claude version |

**Restore keys:** The fallback `claude-code-${{ runner.os }}-` matches any previous run's cache for the same OS. Even a partial cache hit is useful — `npm install -g` will only download what has changed.

**Cache lifetime:** GitHub retains caches for 7 days after last use, or until the total cache size exceeds the repository limit (10 GB on GitHub Free). The Claude CLI binary is approximately 50 MB.

---

## Evidence Artifact Review

When a validation run completes (pass or fail), ValidationForge uploads everything in `e2e-evidence/` as a GitHub Actions artifact named `validation-evidence-<run-number>`.

### Downloading artifacts

1. Open the **Actions** tab on your repository
2. Click the workflow run you want to inspect
3. Scroll to the **Artifacts** section at the bottom of the summary page
4. Click **validation-evidence-\<number\>** to download a `.zip` file

### Evidence directory structure

After extracting, you will find:

```
e2e-evidence/
  validation-plan.md            ← what ValidationForge planned to validate
  report.md                     ← PASS/FAIL verdict per journey with citations
  {journey-slug}/
    step-01-{description}.png   ← screenshot of the live UI
    step-02-{description}.json  ← API response body + headers
    step-03-{description}.txt   ← CLI output or log excerpt
    evidence-inventory.txt      ← list of all captured evidence for this journey
```

### Reading the report

Open `e2e-evidence/report.md` first. It contains a structured verdict for each journey:

```
## Journey: User Login
Status: FAIL
Root Cause: POST /api/login returned 500 Internal Server Error
Evidence: step-02-login-response.json — body: {"error":"DB connection refused"}
Fix: Database connection string missing from environment
```

Each FAIL verdict includes:
- **Root Cause** — the specific failure point
- **Evidence** — the file name and the exact text that proves the failure
- **Fix** — the recommended remediation (when determinable)

### Reading individual evidence files

| File type | What to look for |
|-----------|-----------------|
| `.png` screenshots | Visible UI state — form errors, blank pages, wrong content |
| `.json` API responses | Status code, response body, error messages in the payload |
| `.txt` CLI output | Exit codes, error lines, missing expected output |
| `evidence-inventory.txt` | List of all files captured; gaps here indicate evidence capture failures |

> **Empty files are invalid evidence.** The `evidence-quality-check` hook catches 0-byte files during local development. If you see an empty file in the artifact, the evidence capture step failed silently — treat the associated journey verdict as inconclusive.

---

## Troubleshooting

### ANTHROPIC_API_KEY is not set

**Symptom:** `claude --print` exits immediately with:
```
Error: ANTHROPIC_API_KEY environment variable is not set
```

**Fix:**
1. Confirm the secret exists: **Settings → Secrets and variables → Actions** — you should see `ANTHROPIC_API_KEY` listed
2. Confirm the workflow references it correctly:
   ```yaml
   env:
     ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
   ```
3. If you recently rotated the key, update the secret value
4. Secrets are not available to pull requests from forks by default — check **Settings → Actions → General → Fork pull request workflows**

---

### Server did not start in time

**Symptom:** The "Wait for server to be healthy" step exits with:
```
[VF] ERROR: Server did not respond 200 after 60s at http://localhost:3000
```

**Diagnosis steps:**
1. Check the "Start dev server" step logs — look for startup errors (missing env vars, port conflicts)
2. Increase `HEALTH_TIMEOUT` (e.g., `120` or `180` for slow Java/Ruby builds)
3. Verify `HEALTH_URL` is the exact URL your server responds to — some servers return 200 only on a specific path (e.g., `/health`, not `/`)
4. Confirm `SERVER_CMD` starts the correct process:
   ```yaml
   SERVER_CMD: "npm run dev"   # ← must match your package.json "scripts.dev"
   ```
5. Add debug output to narrow down the failure:
   ```yaml
   - name: Debug server startup
     run: |
       curl -v http://localhost:3000 || true
       ps aux | grep node || true
   ```

---

### Validation times out (GitHub Actions 6-hour job limit)

**Symptom:** The job is cancelled after 6 hours with no verdict.

**Cause:** `/validate-ci` discovered many journeys and is taking too long.

**Fix options:**

1. **Scope validation** to the changed files only:
   ```yaml
   VF_SCOPE: "src/api/"
   ```

2. **Force a specific platform** instead of auto-detecting (detection adds time):
   ```yaml
   VF_PLATFORM: "web"
   ```

3. **Set a job timeout** to fail fast with a clear message instead of waiting 6 hours:
   ```yaml
   jobs:
     validate:
       timeout-minutes: 30
   ```

4. **Run validation only on PRs** (not on every push to main):
   ```yaml
   on:
     pull_request:
       branches: ["main"]
   # Remove the 'push' trigger
   ```

---

### Missing ANTHROPIC_API_KEY on fork PRs

**Symptom:** Validation fails on PRs opened from forks with a missing API key error.

**Cause:** GitHub Actions does not share secrets with fork workflows by default.

**Fix options (choose one):**

- **Require approvals for fork PRs:** In **Settings → Actions → General**, set "Fork pull request workflows from outside collaborators" to "Require approval for all outside collaborators". Approved PRs get access to secrets.
- **Skip validation on forks:** Add a condition to the validation step:
  ```yaml
  - name: Run ValidationForge
    if: github.event.pull_request.head.repo.full_name == github.repository
    ...
  ```
- **Use environment secrets:** Create a GitHub Environment named `validation` with the API key secret, and require approval for that environment before the job can access it.

---

### `claude` command not found

**Symptom:** Step 9 fails with `claude: command not found`.

**Cause:** The `GITHUB_PATH` modification in Step 4 did not propagate.

**Fix:** Confirm Step 4 runs before Step 9 and contains:
```bash
echo "$HOME/.npm-global/bin" >> "$GITHUB_PATH"
```
This is required because GitHub Actions reads `GITHUB_PATH` between steps, not within the same step. If you moved or merged steps, split them back out.

---

### Evidence directory is empty

**Symptom:** The artifact uploads successfully but the zip contains no files, or only `validation-plan.md`.

**Cause:** ValidationForge failed during preflight before evidence capture began.

**Fix:** Check the "Run ValidationForge" step logs for preflight errors such as:
- Server unreachable (even though health check passed — check for port mismatches)
- Claude Code configuration missing (`~/.claude/.vf-config.json` not written by install)
- ValidationForge install step failed silently (check for curl errors)

---

## FAQ

**Q: Do I need to commit `e2e-evidence/` to my repository?**

No. The evidence directory is populated at CI runtime and uploaded as a GitHub Actions artifact. Add it to `.gitignore`:
```
e2e-evidence/
```

**Q: Can I run ValidationForge locally before pushing?**

Yes. Install Claude Code and ValidationForge locally, then run:
```bash
ANTHROPIC_API_KEY=sk-ant-... claude --print "/validate-ci --platform web"
```
This uses the same pipeline as CI. Evidence goes to `./e2e-evidence/` in your project directory.

**Q: Can I run multiple platform validators in parallel?**

Yes. Use a matrix strategy:
```yaml
strategy:
  fail-fast: false
  matrix:
    include:
      - platform: web
        server_cmd: "npm run dev"
        health_url: "http://localhost:3000"
      - platform: api
        server_cmd: "node src/server.js"
        health_url: "http://localhost:8000/health"

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      ...
      - name: Run ValidationForge
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: claude --print "/validate-ci --platform ${{ matrix.platform }}"
```

Each matrix job uploads its evidence as a separate artifact named `validation-evidence-web-<run>` and `validation-evidence-api-<run>`.

**Q: How long does a typical run take?**

| Platform | Typical duration |
|----------|-----------------|
| CLI tool | 2–4 minutes |
| API (5–10 endpoints) | 4–7 minutes |
| Web app (5–8 journeys) | 5–9 minutes |
| iOS app | 8–15 minutes |

These figures assume a warm Claude Code CLI cache. Cold runs (first run after cache expiry) add 30–60 seconds.

**Q: Can I use this with GitHub Enterprise Server (GHES)?**

Yes, with two adjustments:
1. The `install.sh` script fetches from `github.com` — ensure your GHES runners have outbound internet access, or mirror the ValidationForge repository internally
2. Set `retention-days` to a value within your GHES artifact retention policy

**Q: What happens if my project has no `package.json`?**

The Node.js setup step still runs (Claude Code requires Node.js), but the cache lines and the auto-detect install block are skipped without error. For Python or Ruby projects, simply add your language's setup action after the Node.js step and before the ValidationForge install step.

**Q: Can I fail the PR check on specific journeys only?**

Not directly — `/validate-ci` exits 1 if any journey fails. To selectively ignore known-failing journeys during a rollout period, use the `--scope` flag to limit which parts of the codebase are validated, and expand the scope as each area is stabilized.

**Q: How do I update ValidationForge in CI?**

The install step always fetches `install.sh` from the `main` branch, so CI automatically picks up the latest ValidationForge version on every run. No version pinning is required. If you want to pin a specific version, replace the `install.sh` URL with a tagged release:
```bash
curl -fsSL \
  https://raw.githubusercontent.com/krzemienski/validationforge/v1.2.0/install.sh \
  | bash
```

**Q: Is there a way to skip validation on documentation-only PRs?**

Yes. Use path filters in the trigger:
```yaml
on:
  pull_request:
    branches: ["main"]
    paths-ignore:
      - "docs/**"
      - "*.md"
      - ".github/CODEOWNERS"
```

PRs that only touch ignored paths will not trigger the validation workflow, saving API costs.
