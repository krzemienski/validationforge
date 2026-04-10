---
name: vf-telemetry
description: Manage ValidationForge usage telemetry — enable, disable, inspect, or check status
triggers:
  - "vf telemetry"
  - "telemetry enable"
  - "telemetry disable"
  - "telemetry show"
  - "telemetry status"
  - "enable telemetry"
  - "disable telemetry"
  - "manage telemetry"
---

# /vf-telemetry

Manage opt-in usage telemetry for ValidationForge. Telemetry is **disabled by default** and must be explicitly enabled. All data is anonymized — no PII is ever collected.

**When this command is invoked, read the subcommand and immediately execute the matching workflow below.**

## Usage

```
/vf-telemetry enable     # Opt in to usage telemetry with full disclosure
/vf-telemetry disable    # Opt out and stop sending telemetry
/vf-telemetry show       # Print the exact JSON payload that would be sent
/vf-telemetry status     # Show current telemetry state and anonymous ID
```

## Subcommands

| Subcommand | Description |
|------------|-------------|
| `enable`   | Opt in — generates anonymous ID, updates config, prints full disclosure |
| `disable`  | Opt out — sets `telemetry.enabled=false` in config, confirms |
| `show`     | Print the exact JSON payload for a sample `command.invoked` event |
| `status`   | Show enabled/disabled state and the first 8 chars of the anonymous ID |

---

## `vf telemetry enable`

Opt in to anonymized usage telemetry. Generates a random UUID as your anonymous identifier, writes telemetry settings to `~/.claude/.vf-config.json`, prints a full disclosure of what will be collected, then confirms activation.

### Step 1: Read Existing Config

```bash
CONFIG_FILE="$HOME/.claude/.vf-config.json"

# Ensure the config directory exists
mkdir -p "$HOME/.claude"

# Check if already enabled
if [ -f "$CONFIG_FILE" ]; then
  ALREADY_ENABLED=$(jq -r '.telemetry.enabled // false' "$CONFIG_FILE" 2>/dev/null)
  if [ "$ALREADY_ENABLED" = "true" ]; then
    EXISTING_ID=$(jq -r '.telemetry.anonymousId // ""' "$CONFIG_FILE" 2>/dev/null)
    ID_PREVIEW="${EXISTING_ID:0:8}"
    echo "[vf] Telemetry is already enabled (ID: ${ID_PREVIEW}...)."
    echo "     Run 'vf telemetry status' to see current state."
    echo "     Run 'vf telemetry disable' to opt out."
    exit 0
  fi
fi
```

### Step 2: Generate Anonymous ID

```bash
# Generate a UUID — uuidgen is preferred; fall back to python3
ANON_ID=""

if command -v uuidgen &>/dev/null; then
  ANON_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
else
  ANON_ID=$(python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || echo "")
fi

if [ -z "$ANON_ID" ]; then
  echo "[vf] ERROR: Could not generate a UUID. Install uuidgen or python3."
  exit 1
fi

echo "[vf] Generated anonymous ID: ${ANON_ID:0:8}... (truncated for display)"
```

### Step 3: Print Disclosure Statement

Print the following disclosure verbatim before writing any config:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ValidationForge Telemetry — Full Disclosure
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  By enabling telemetry you agree that the following
  anonymized data will be sent to:
  https://telemetry.validationforge.dev/events

  WHAT IS COLLECTED:
  ─────────────────────────────────────────────────────────
  Field          Example              Purpose
  ─────────────────────────────────────────────────────────
  event          command.invoked      Which event occurred
  command        validate             Which VF command ran
  platform       web                  Detected platform type
  phase          execute              Pipeline phase completed
  verdict        pass                 Validation outcome
  vf_version     1.0.0                VF version in use
  anonymousId    a3f7c2d1-...         Random UUID (no identity link)
  timestamp      2026-04-10T19:00:00Z UTC time of event
  ─────────────────────────────────────────────────────────

  WHAT IS NEVER COLLECTED:
  ✗ File paths, filenames, or directory names
  ✗ Usernames, email addresses, or any PII
  ✗ Project names or repository names
  ✗ Environment variables or shell config
  ✗ Source code, test output, or error messages
  ✗ IP addresses (endpoint does not log IPs)

  DATA TRANSMISSION:
  • HTTPS only — no plaintext transmission
  • 5-second timeout — never blocks your workflow
  • Failures are silent — telemetry never causes errors

  You can disable at any time with: vf telemetry disable
  Full privacy policy: PRIVACY.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 4: Write Telemetry Config

```bash
# Read the current config (or start with an empty object)
if [ -f "$CONFIG_FILE" ]; then
  CURRENT_CONFIG=$(cat "$CONFIG_FILE")
else
  CURRENT_CONFIG="{}"
fi

# Merge telemetry block into config using jq
UPDATED_CONFIG=$(echo "$CURRENT_CONFIG" | jq \
  --arg id "$ANON_ID" \
  --arg endpoint "https://telemetry.validationforge.dev/events" \
  '.telemetry = {
    "enabled": true,
    "anonymousId": $id,
    "endpoint": $endpoint,
    "enabledAt": (now | todate)
  }' 2>/dev/null)

if [ -z "$UPDATED_CONFIG" ]; then
  echo "[vf] ERROR: Failed to update config with jq. Is jq installed?"
  exit 1
fi

echo "$UPDATED_CONFIG" > "$CONFIG_FILE"
```

### Step 5: Confirm Activation

```
[vf] ✓ Telemetry enabled.

  Anonymous ID : {ANON_ID:0:8}... (stored in ~/.claude/.vf-config.json)
  Endpoint     : https://telemetry.validationforge.dev/events
  Enabled at   : {ISO_TIMESTAMP}

  To see exactly what data is sent: vf telemetry show
  To opt out at any time:           vf telemetry disable
```

---

## `vf telemetry disable`

Opt out of telemetry. Sets `telemetry.enabled=false` in `~/.claude/.vf-config.json` and confirms. Your anonymous ID is retained in the config (for re-enable) but no data will be sent.

### Step 1: Read Config

```bash
CONFIG_FILE="$HOME/.claude/.vf-config.json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "[vf] No config found at $CONFIG_FILE — telemetry is already off (default)."
  exit 0
fi

CURRENTLY_ENABLED=$(jq -r '.telemetry.enabled // false' "$CONFIG_FILE" 2>/dev/null)

if [ "$CURRENTLY_ENABLED" != "true" ]; then
  echo "[vf] Telemetry is already disabled."
  exit 0
fi
```

### Step 2: Set `telemetry.enabled=false`

```bash
# Disable telemetry — preserve anonymousId and endpoint for future re-enable
UPDATED_CONFIG=$(jq '.telemetry.enabled = false' "$CONFIG_FILE" 2>/dev/null)

if [ -z "$UPDATED_CONFIG" ]; then
  echo "[vf] ERROR: Failed to update config with jq. Is jq installed?"
  exit 1
fi

echo "$UPDATED_CONFIG" > "$CONFIG_FILE"
```

### Step 3: Confirm Deactivation

```
[vf] ✓ Telemetry disabled.

  No usage data will be sent from this point forward.
  Your anonymous ID is retained locally in case you re-enable.

  To re-enable: vf telemetry enable
  To check state: vf telemetry status
```

---

## `vf telemetry show`

Print the exact JSON payload that would be sent to the telemetry endpoint for a sample `command.invoked` event. This lets you see every field before deciding to opt in.

### Read Config and Construct Sample Payload

```bash
CONFIG_FILE="$HOME/.claude/.vf-config.json"

# Read values from config if present; use placeholders when not configured
if [ -f "$CONFIG_FILE" ]; then
  ANON_ID=$(jq -r '.telemetry.anonymousId // ""' "$CONFIG_FILE" 2>/dev/null)
  ENDPOINT=$(jq -r '.telemetry.endpoint // "https://telemetry.validationforge.dev/events"' "$CONFIG_FILE" 2>/dev/null)
else
  ANON_ID=""
  ENDPOINT="https://telemetry.validationforge.dev/events"
fi

# Use placeholder if no ID exists yet (telemetry not yet enabled)
if [ -z "$ANON_ID" ] || [ "$ANON_ID" = "null" ]; then
  ANON_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  ← generated at opt-in"
fi

# Use a fixed sample timestamp for reproducibility
SAMPLE_TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo '2026-04-10T19:00:00Z')"
VF_VERSION="1.0.0"
```

### Print Payload

Print the following to stdout, substituting the real values:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Sample telemetry payload (event: command.invoked)
  Destination: {ENDPOINT}
  Method: POST  Content-Type: application/json
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{
  "event":       "command.invoked",
  "command":     "validate",
  "platform":    "web",
  "phase":       "execute",
  "verdict":     "pass",
  "vf_version":  "1.0.0",
  "anonymousId": "{ANON_ID}",
  "timestamp":   "{SAMPLE_TIMESTAMP}"
}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Field Definitions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  event       — Event type. One of: command.invoked,
                platform.detected, pipeline.phase.completed,
                validation.verdict
  command     — VF command that triggered the event
                (validate, vf-setup, vf-telemetry, etc.)
  platform    — Platform detected for this project
                (web, api, ios, cli, fullstack)
  phase       — Pipeline phase (plan, preflight, execute,
                analyze, verdict) — omitted for command.invoked
  verdict     — pass or fail — only on validation.verdict events
  vf_version  — ValidationForge version string
  anonymousId — Random UUID generated at opt-in time.
                Has NO connection to your identity.
  timestamp   — UTC ISO-8601 timestamp of the event

  Nothing else is ever included in the payload.
  No headers contain identity or session information.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## `vf telemetry status`

Show the current telemetry state: enabled or disabled, plus the first 8 characters of the anonymous ID (truncated for privacy).

### Read Config and Print Status

```bash
CONFIG_FILE="$HOME/.claude/.vf-config.json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "[vf] Telemetry status: DISABLED (no config found — default)"
  echo "     Run 'vf telemetry enable' to opt in."
  exit 0
fi

ENABLED=$(jq -r '.telemetry.enabled // false' "$CONFIG_FILE" 2>/dev/null)
ANON_ID=$(jq -r '.telemetry.anonymousId // ""' "$CONFIG_FILE" 2>/dev/null)
ENDPOINT=$(jq -r '.telemetry.endpoint // "https://telemetry.validationforge.dev/events"' "$CONFIG_FILE" 2>/dev/null)
ENABLED_AT=$(jq -r '.telemetry.enabledAt // ""' "$CONFIG_FILE" 2>/dev/null)

# Truncate anonymous ID to first 8 characters for display
if [ -n "$ANON_ID" ] && [ "$ANON_ID" != "null" ]; then
  ID_PREVIEW="${ANON_ID:0:8}..."
else
  ID_PREVIEW="(none — not yet generated)"
fi

if [ "$ENABLED" = "true" ]; then
  STATUS_LABEL="ENABLED"
else
  STATUS_LABEL="DISABLED"
fi
```

Print the status block:

```
[vf] Telemetry Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Status       : {STATUS_LABEL}
  Anonymous ID : {ID_PREVIEW}  (first 8 chars shown)
  Endpoint     : {ENDPOINT}
  Enabled at   : {ENABLED_AT or "n/a"}
  Config file  : ~/.claude/.vf-config.json
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  vf telemetry enable   — opt in
  vf telemetry disable  — opt out
  vf telemetry show     — inspect the exact payload
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Privacy Guarantee

Telemetry in ValidationForge is built around three commitments:

1. **Opt-in only** — Disabled by default. You must explicitly run `vf telemetry enable`.
2. **Zero PII** — Only anonymous metrics are collected. No file names, user names, project names, or environment data.
3. **Transparent** — Run `vf telemetry show` at any time to see the exact JSON payload that would be sent.

Full privacy policy: `PRIVACY.md`

## Config Structure

After enabling, the telemetry block in `~/.claude/.vf-config.json` looks like:

```json
{
  "telemetry": {
    "enabled": true,
    "anonymousId": "a3f7c2d1-84b9-4e2f-91c3-7d5e6f8a0b1c",
    "endpoint": "https://telemetry.validationforge.dev/events",
    "enabledAt": "2026-04-10T19:00:00Z"
  }
}
```

After disabling:

```json
{
  "telemetry": {
    "enabled": false,
    "anonymousId": "a3f7c2d1-84b9-4e2f-91c3-7d5e6f8a0b1c",
    "endpoint": "https://telemetry.validationforge.dev/events",
    "enabledAt": "2026-04-10T19:00:00Z"
  }
}
```
