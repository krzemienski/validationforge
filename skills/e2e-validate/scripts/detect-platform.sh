#!/usr/bin/env bash
# detect-platform.sh — machine-readable platform detection for e2e-validate.
# Mirrors the priority table in skills/e2e-validate/SKILL.md (Platform Detection).
# First match wins. Prints one line by default; pass --json for JSON output.

set -euo pipefail

PROJECT_DIR="."
JSON=0

for arg in "$@"; do
  case "$arg" in
    --project-dir=*) PROJECT_DIR="${arg#*=}" ;;
    --json)          JSON=1 ;;
    -h|--help)
      cat <<EOF
Usage: detect-platform.sh [--project-dir=.] [--json]
Prints: platform=<name> confidence=high|medium|low signals=<semicolon-list>
EOF
      exit 0 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "project dir not found: $PROJECT_DIR" >&2
  exit 2
fi

cd "$PROJECT_DIR"

signals=()
add() { signals+=("$1"); }

has_glob() { compgen -G "$1" >/dev/null 2>&1; }
file_has()  { [[ -f "$1" ]] && grep -q "$2" "$1" 2>/dev/null; }

# Priority 1: ios
ios_sigs=()
has_glob "*.xcodeproj"  && ios_sigs+=("xcodeproj")
has_glob "*.xcworkspace" && ios_sigs+=("xcworkspace")
[[ -f "Package.swift" ]] && ios_sigs+=("Package.swift")

# Priority 2: react-native
rn_sigs=()
file_has "package.json" '"react-native"' && rn_sigs+=("package.json:react-native")
[[ -f "metro.config.js" ]] && rn_sigs+=("metro.config.js")
file_has "app.json" '"expo"'             && rn_sigs+=("app.json:expo")

# Priority 3: flutter
fl_sigs=()
[[ -f "pubspec.yaml" ]]   && fl_sigs+=("pubspec.yaml")
[[ -f "lib/main.dart" ]]  && fl_sigs+=("lib/main.dart")
if has_glob "*.dart" || has_glob "lib/*.dart"; then fl_sigs+=("*.dart"); fi

# Priority 4: cli
cli_sigs=()
file_has "Cargo.toml" "\[\[bin\]\]"                    && cli_sigs+=("Cargo.toml:[[bin]]")
{ [[ -f "go.mod" ]] && [[ -f "main.go" ]]; }           && cli_sigs+=("go.mod+main.go")
file_has "package.json" '"bin"'                        && cli_sigs+=("package.json:bin")

# Priority 5/6/8 helpers: backend/frontend signals
backend_sigs=()
[[ -d "routes" ]]      && backend_sigs+=("routes/")
[[ -d "controllers" ]] && backend_sigs+=("controllers/")
[[ -f "server.js" ]]   && backend_sigs+=("server.js")
[[ -f "app.js" ]]      && backend_sigs+=("app.js")
has_glob "api/*.ts" || has_glob "api/*.js" && backend_sigs+=("api/")

frontend_sigs=()
[[ -d "public" ]]      && frontend_sigs+=("public/")
[[ -d "src/pages" ]]   && frontend_sigs+=("src/pages/")
[[ -d "src/app" ]]     && frontend_sigs+=("src/app/")
has_glob "next.config.*"    && frontend_sigs+=("next.config")
has_glob "vite.config.*"    && frontend_sigs+=("vite.config")
has_glob "svelte.config.*"  && frontend_sigs+=("svelte.config")
has_glob "astro.config.*"   && frontend_sigs+=("astro.config")

# Priority 7: django
dj_sigs=()
if [[ -f "requirements.txt" ]]; then
  dj_sigs+=("requirements.txt")
  [[ -f "manage.py" ]] && dj_sigs+=("manage.py")
  [[ -f "wsgi.py" ]]   && dj_sigs+=("wsgi.py")
  file_has "requirements.txt" "^django" && dj_sigs+=("requirements:django")
fi
# Require at least one strong django marker besides requirements.txt
dj_ok=0
if [[ ${#dj_sigs[@]} -gt 0 ]]; then
  for s in "${dj_sigs[@]}"; do
    case "$s" in manage.py|wsgi.py|requirements:django) dj_ok=1 ;; esac
  done
fi

# Resolve: first match wins per priority table
platform=""
matched=()

if [[ ${#ios_sigs[@]} -gt 0 ]]; then
  platform="ios"; matched=("${ios_sigs[@]}")
elif [[ ${#rn_sigs[@]} -gt 0 ]]; then
  platform="react-native"; matched=("${rn_sigs[@]}")
elif [[ ${#fl_sigs[@]} -gt 0 ]]; then
  platform="flutter"; matched=("${fl_sigs[@]}")
elif [[ ${#cli_sigs[@]} -gt 0 ]]; then
  platform="cli"; matched=("${cli_sigs[@]}")
elif [[ ${#backend_sigs[@]} -gt 0 && ${#frontend_sigs[@]} -eq 0 ]]; then
  platform="api"; matched=("${backend_sigs[@]}")
elif [[ ${#frontend_sigs[@]} -gt 0 && ${#backend_sigs[@]} -eq 0 ]]; then
  platform="web"; matched=("${frontend_sigs[@]}")
elif [[ $dj_ok -eq 1 ]]; then
  platform="django"; matched=("${dj_sigs[@]}")
elif [[ ${#frontend_sigs[@]} -gt 0 && ${#backend_sigs[@]} -gt 0 ]]; then
  platform="fullstack"
  matched=("${frontend_sigs[@]}" "${backend_sigs[@]}")
else
  platform="generic"; matched=()
fi

# Confidence
n=${#matched[@]}
if [[ "$platform" == "generic" ]]; then
  confidence="low"
elif [[ $n -ge 2 ]]; then
  confidence="high"
else
  confidence="medium"
fi

# Emit
join() { local IFS="$1"; shift; echo "$*"; }
sig_list="$(join ';' "${matched[@]:-}")"

if [[ $JSON -eq 1 ]]; then
  json_signals=""
  if [[ $n -gt 0 ]]; then
    for s in "${matched[@]}"; do
      json_signals+="\"${s//\"/\\\"}\","
    done
    json_signals="${json_signals%,}"
  fi
  printf '{"platform":"%s","confidence":"%s","signals":[%s]}\n' \
    "$platform" "$confidence" "$json_signals"
else
  printf 'platform=%s confidence=%s signals=%s\n' \
    "$platform" "$confidence" "$sig_list"
fi
