# Journey Discovery Patterns

Platform-specific patterns for finding all user journeys in a codebase.

## Web Applications

### Route-Based Discovery
```bash
# Next.js App Router — every page.tsx is a route
find . -path "*/app/*/page.tsx" -o -path "*/app/*/page.jsx" | sort

# Next.js Pages Router
find . -path "*/pages/*.tsx" -o -path "*/pages/*.jsx" | grep -v _app | grep -v _document | sort

# React Router definitions
grep -rn "path=" src/ --include="*.tsx" --include="*.jsx" | grep -i route

# Vue Router
grep -rn "path:" src/router/ --include="*.ts" --include="*.js"

# SvelteKit — file-based routing
find src/routes -name "+page.svelte" | sort
```

### Interaction Discovery
```bash
# Forms (each form = a submit journey)
grep -rn "onSubmit\|handleSubmit\|action=" src/ --include="*.tsx" --include="*.jsx" -l

# Buttons with handlers (each = potential journey trigger)
grep -rn "onClick\|onPress" src/ --include="*.tsx" --include="*.jsx" -l

# Modals and dialogs (each = an interaction journey)
grep -rn "Modal\|Dialog\|Drawer\|Sheet" src/ --include="*.tsx" --include="*.jsx" -l

# Navigation links (map the user's traversal paths)
grep -rn "href=\|Link " src/ --include="*.tsx" --include="*.jsx" | grep -v node_modules
```

### Data Flow Discovery
```bash
# API calls from frontend (each = a data journey)
grep -rn "fetch(\|axios\.\|useSWR\|useQuery\|useMutation" src/ --include="*.ts" --include="*.tsx" -l

# Server actions (Next.js 14+)
grep -rn "'use server'" src/ --include="*.ts" --include="*.tsx" -l

# WebSocket connections
grep -rn "WebSocket\|socket\.io\|ws://" src/ --include="*.ts" --include="*.tsx" -l
```

## API Services

### Endpoint Discovery
```bash
# Express.js
grep -rn "app\.\(get\|post\|put\|patch\|delete\)\|router\.\(get\|post\|put\|patch\|delete\)" src/ --include="*.ts" --include="*.js"

# FastAPI
grep -rn "@app\.\(get\|post\|put\|delete\)\|@router\.\(get\|post\|put\|delete\)" . --include="*.py"

# Django REST Framework
grep -rn "class.*ViewSet\|class.*APIView\|urlpatterns" . --include="*.py"

# Go (net/http, Gin, Echo)
grep -rn "HandleFunc\|\.GET\|\.POST\|\.PUT\|\.DELETE" . --include="*.go"

# OpenAPI / Swagger spec
find . -name "openapi.*" -o -name "swagger.*" | head -5
```

### Middleware & Auth Discovery
```bash
# Auth middleware (each protected route = an auth journey)
grep -rn "authenticate\|authorize\|requireAuth\|isAuthenticated" src/ --include="*.ts" --include="*.js" -l

# Rate limiting
grep -rn "rateLimit\|throttle" src/ --include="*.ts" --include="*.js" -l

# Validation middleware (each = an input validation journey)
grep -rn "validate\|schema\|zod\|joi\|yup" src/ --include="*.ts" --include="*.js" -l
```

## iOS Applications

### View Discovery
```bash
# SwiftUI views (each = a screen journey)
find . -name "*.swift" | xargs grep -l "struct.*:.*View" | sort

# UIKit view controllers
find . -name "*.swift" | xargs grep -l "class.*ViewController" | sort

# Storyboard scenes
find . -name "*.storyboard" | xargs grep -c "viewController" 2>/dev/null
```

### Navigation Discovery
```bash
# SwiftUI navigation
grep -rn "NavigationLink\|NavigationStack\|NavigationSplitView\|sheet(\|fullScreenCover(" . --include="*.swift"

# UIKit navigation
grep -rn "pushViewController\|present(\|performSegue" . --include="*.swift"

# Tab bar items (each tab = a journey entry point)
grep -rn "TabView\|UITabBarController\|tabBarItem" . --include="*.swift"
```

### User Action Discovery
```bash
# Button actions
grep -rn "Button(\|@IBAction\|addTarget\|onTapGesture" . --include="*.swift" -l

# Form inputs
grep -rn "TextField\|SecureField\|TextEditor\|Picker\|Toggle\|Slider" . --include="*.swift" -l

# Network calls (each = a data journey)
grep -rn "URLSession\|Alamofire\|URLRequest\|async let" . --include="*.swift" -l
```

## CLI Applications

### Command Discovery
```bash
# Python Click
grep -rn "@click\.command\|@click\.group\|add_command" . --include="*.py"

# Python argparse
grep -rn "add_subparser\|add_argument\|add_parser" . --include="*.py"

# Rust Clap
grep -rn "#\[command\]\|#\[arg\]\|Subcommand" . --include="*.rs"

# Go Cobra
grep -rn "cobra\.Command\|AddCommand\|RunE:" . --include="*.go"

# Node.js Commander
grep -rn "\.command(\|\.option(\|\.argument(" . --include="*.ts" --include="*.js"

# Shell scripts
grep -rn "case.*in\|getopts\|OPTARG" . --include="*.sh"
```

### IO Discovery
```bash
# File operations (each = a file journey)
grep -rn "open(\|read_to_string\|write_all\|fs\.\|os\.path" . --include="*.py" --include="*.rs" -l

# Stdin/stdout patterns
grep -rn "stdin\|stdout\|input(\|print(\|println!" . --include="*.py" --include="*.rs" -l

# Exit codes
grep -rn "exit(\|process\.exit\|sys\.exit\|std::process::exit" . --include="*.py" --include="*.rs" --include="*.ts" -l
```

## General Patterns

Every project has these implicit journeys regardless of platform:

1. **First-run / setup** — What happens on first launch?
2. **Happy path** — The primary use case working correctly
3. **Invalid input** — What happens with bad data?
4. **Auth boundary** — What happens without credentials?
5. **Empty state** — What happens with no data?
6. **Error state** — What happens when a dependency is down?
