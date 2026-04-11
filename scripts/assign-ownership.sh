#!/usr/bin/env bash
# Assign a team member as the owner of a specific project+journey.
# Reads/writes .vf/team/ownership.json mapping project+journey to owner name.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OWNERSHIP_DIR="$PROJECT_ROOT/.vf/team"
OWNERSHIP_FILE="$OWNERSHIP_DIR/ownership.json"

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Assign or list validation ownership for project journeys.

Options:
  --project <name>   Project identifier (required for assign/remove)
  --journey <name>   Journey identifier (required for assign/remove)
  --owner <name>     Owner name to assign (required for --assign)
  --assign           Assign owner to the project+journey (default action)
  --remove           Remove ownership assignment for project+journey
  --list             List all current ownership assignments
  --list-project <name>  List assignments for a specific project
  -h, --help         Show this help message

Examples:
  $(basename "$0") --project my-app --journey login-flow --owner alice
  $(basename "$0") --assign --project my-app --journey checkout --owner bob
  $(basename "$0") --remove --project my-app --journey login-flow
  $(basename "$0") --list
  $(basename "$0") --list-project my-app
EOF
}

# Ensure ownership directory and file exist
ensure_file() {
  mkdir -p "$OWNERSHIP_DIR"
  if [ ! -f "$OWNERSHIP_FILE" ]; then
    echo '{"assignments":[]}' > "$OWNERSHIP_FILE"
  fi
}

# List all assignments
list_all() {
  ensure_file
  local count
  count=$(python3 -c "import json,sys; d=json.load(open('$OWNERSHIP_FILE')); print(len(d.get('assignments',[])))" 2>/dev/null || echo "0")

  if [ "$count" -eq 0 ]; then
    echo "No ownership assignments found."
    return 0
  fi

  echo "=== Ownership Assignments ==="
  python3 - "$OWNERSHIP_FILE" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
assignments = data.get("assignments", [])
fmt = "  {:<30} {:<30} {}"
print(fmt.format("PROJECT", "JOURNEY", "OWNER"))
print("  " + "-"*80)
for a in sorted(assignments, key=lambda x: (x["project"], x["journey"])):
    print(fmt.format(a["project"], a["journey"], a["owner"]))
print()
print(f"Total: {len(assignments)} assignment(s)")
PYEOF
}

# List assignments for a specific project
list_project() {
  local project="$1"
  ensure_file
  echo "=== Assignments for project: $project ==="
  python3 - "$OWNERSHIP_FILE" "$project" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
project = sys.argv[2]
assignments = [a for a in data.get("assignments", []) if a["project"] == project]
if not assignments:
    print(f"  No assignments found for project '{project}'.")
else:
    fmt = "  {:<30} {}"
    print(fmt.format("JOURNEY", "OWNER"))
    print("  " + "-"*50)
    for a in sorted(assignments, key=lambda x: x["journey"]):
        print(fmt.format(a["journey"], a["owner"]))
    print()
    print(f"Total: {len(assignments)} assignment(s)")
PYEOF
}

# Assign owner to project+journey
assign_owner() {
  local project="$1"
  local journey="$2"
  local owner="$3"
  ensure_file

  python3 - "$OWNERSHIP_FILE" "$project" "$journey" "$owner" <<'PYEOF'
import json, sys
from datetime import datetime, timezone

filepath, project, journey, owner = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

with open(filepath) as f:
    data = json.load(f)

assignments = data.get("assignments", [])
timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

# Update existing or add new
found = False
for a in assignments:
    if a["project"] == project and a["journey"] == journey:
        old_owner = a["owner"]
        a["owner"] = owner
        a["assigned_at"] = timestamp
        print(f"Updated: {project}/{journey} owner changed from '{old_owner}' to '{owner}'")
        found = True
        break

if not found:
    assignments.append({
        "project": project,
        "journey": journey,
        "owner": owner,
        "assigned_at": timestamp
    })
    print(f"Assigned: {project}/{journey} → {owner}")

data["assignments"] = assignments
with open(filepath, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PYEOF
}

# Remove assignment for project+journey
remove_owner() {
  local project="$1"
  local journey="$2"
  ensure_file

  python3 - "$OWNERSHIP_FILE" "$project" "$journey" <<'PYEOF'
import json, sys

filepath, project, journey = sys.argv[1], sys.argv[2], sys.argv[3]

with open(filepath) as f:
    data = json.load(f)

assignments = data.get("assignments", [])
before = len(assignments)
assignments = [a for a in assignments if not (a["project"] == project and a["journey"] == journey)]
after = len(assignments)

if before == after:
    print(f"No assignment found for {project}/{journey}")
    sys.exit(1)

data["assignments"] = assignments
with open(filepath, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")

print(f"Removed: ownership assignment for {project}/{journey}")
PYEOF
}

# Parse arguments
action="assign"
project=""
journey=""
owner=""
list_proj=""

if [ $# -eq 0 ]; then
  usage
  exit 0
fi

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --assign)
      action="assign"
      shift
      ;;
    --remove)
      action="remove"
      shift
      ;;
    --list)
      action="list"
      shift
      ;;
    --list-project)
      action="list-project"
      list_proj="${2:-}"
      if [ -z "$list_proj" ]; then
        echo "Error: --list-project requires a project name" >&2
        exit 1
      fi
      shift 2
      ;;
    --project)
      project="${2:-}"
      if [ -z "$project" ]; then
        echo "Error: --project requires a value" >&2
        exit 1
      fi
      shift 2
      ;;
    --journey)
      journey="${2:-}"
      if [ -z "$journey" ]; then
        echo "Error: --journey requires a value" >&2
        exit 1
      fi
      shift 2
      ;;
    --owner)
      owner="${2:-}"
      if [ -z "$owner" ]; then
        echo "Error: --owner requires a value" >&2
        exit 1
      fi
      shift 2
      ;;
    *)
      echo "Error: Unknown option '$1'" >&2
      usage >&2
      exit 1
      ;;
  esac
done

# Execute action
case "$action" in
  list)
    list_all
    ;;
  list-project)
    list_project "$list_proj"
    ;;
  assign)
    if [ -z "$project" ] || [ -z "$journey" ] || [ -z "$owner" ]; then
      echo "Error: --assign requires --project, --journey, and --owner" >&2
      usage >&2
      exit 1
    fi
    assign_owner "$project" "$journey" "$owner"
    ;;
  remove)
    if [ -z "$project" ] || [ -z "$journey" ]; then
      echo "Error: --remove requires --project and --journey" >&2
      usage >&2
      exit 1
    fi
    remove_owner "$project" "$journey"
    ;;
  *)
    echo "Error: Unknown action '$action'" >&2
    exit 1
    ;;
esac
