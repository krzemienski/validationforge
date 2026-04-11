---
name: cli-validation
description: "Validate CLI binaries: build, help/version output, happy path, error cases (bad flags, missing args), exit codes, stdin/pipe, output format (JSON/CSV). Capture full stdout/stderr. Use on binary changes."
triggers:
  - "binary validation"
  - "CLI testing"
  - "exit code verification"
  - "command-line tool"
  - "stderr/stdout capture"
context_priority: standard
---

# CLI Validation

## Prerequisites

| Requirement | How to verify |
|-------------|---------------|
| Source code compiles | Run language-specific build command |
| Runtime dependencies available | Check PATH, shared libraries |
| Test input data prepared | Files, directories, or stdin content ready |
| Evidence directory exists | `mkdir -p e2e-evidence` |

## Step 1: Build

Use the appropriate build command for the project language:

```bash
# Rust
cargo build --release 2>&1 | tee e2e-evidence/cli-build.txt
BINARY="target/release/TOOL_NAME"

# Go
go build -o ./bin/tool ./cmd/tool 2>&1 | tee e2e-evidence/cli-build.txt
BINARY="./bin/tool"

# Node.js
npm run build 2>&1 | tee e2e-evidence/cli-build.txt
BINARY="node dist/index.js"
# Or if package.json has "bin": BINARY="npx TOOL_NAME"

# Python
pip install -e . 2>&1 | tee e2e-evidence/cli-build.txt
# Find the installed binary name from project config:
#   pyproject.toml  → [project.scripts] section:          TOOL_NAME = "package.module:function"
#   setup.py        → entry_points console_scripts list:  'TOOL_NAME=package.module:function'
#   setup.cfg       → [options.entry_points]:              TOOL_NAME = package.module:function
grep -A10 "\[project\.scripts\]" pyproject.toml 2>/dev/null \
  || grep -A10 "console_scripts" setup.py setup.cfg 2>/dev/null \
  | tee -a e2e-evidence/cli-build.txt
BINARY="TOOL_NAME"   # replace with the name found in the config above
# Or: BINARY="python -m PACKAGE_NAME"
```

Verify the binary exists and is executable:
```bash
# For file-path binaries (Rust, Go, Node.js compiled output):
ls -la $BINARY | tee -a e2e-evidence/cli-build.txt

# For PATH-installed binaries (Python console_scripts, npx wrappers):
which $BINARY | tee -a e2e-evidence/cli-build.txt
```

## Step 2: Help Output

```bash
$BINARY --help 2>&1 | tee e2e-evidence/cli-help.txt
echo "Exit code: $?" >> e2e-evidence/cli-help.txt
```

Verify help output includes:
- Usage syntax
- Available commands or subcommands
- Option descriptions
- At least one example (good CLIs include this)

## Step 3: Version Check

```bash
$BINARY --version 2>&1 | tee e2e-evidence/cli-version.txt
echo "Exit code: $?" >> e2e-evidence/cli-version.txt
```

## Step 4: Happy Path Execution

Run the primary command with valid arguments:
```bash
$BINARY COMMAND ARG1 ARG2 --flag value 2>&1 | tee e2e-evidence/cli-happy-path.txt
echo "Exit code: $?" >> e2e-evidence/cli-happy-path.txt
```

If the tool produces output files:
```bash
$BINARY COMMAND --output output.json ARG1 2>&1 | tee e2e-evidence/cli-happy-path.txt
echo "Exit code: $?" >> e2e-evidence/cli-happy-path.txt
cp output.json e2e-evidence/cli-output-file.json
```

## Step 5: Error Cases

### Invalid flag
```bash
$BINARY --nonexistent-flag 2>&1 | tee e2e-evidence/cli-error-invalid-flag.txt
echo "Exit code: $?" >> e2e-evidence/cli-error-invalid-flag.txt
```
Expected: non-zero exit code, helpful error message on stderr.

### Missing required argument
```bash
$BINARY COMMAND 2>&1 | tee e2e-evidence/cli-error-missing-arg.txt
echo "Exit code: $?" >> e2e-evidence/cli-error-missing-arg.txt
```
Expected: non-zero exit code, message indicating which argument is missing.

### File not found
```bash
$BINARY COMMAND /path/to/nonexistent/file.txt 2>&1 | tee e2e-evidence/cli-error-no-file.txt
echo "Exit code: $?" >> e2e-evidence/cli-error-no-file.txt
```
Expected: non-zero exit code, clear "file not found" message (not a stack trace).

### Permission denied (if applicable)
```bash
chmod 000 /tmp/test-readonly-file
$BINARY COMMAND /tmp/test-readonly-file 2>&1 | tee e2e-evidence/cli-error-permission.txt
echo "Exit code: $?" >> e2e-evidence/cli-error-permission.txt
chmod 644 /tmp/test-readonly-file
```

## Step 6: Exit Code Verification

Exit codes must follow conventions:
```bash
# Success should exit 0
$BINARY COMMAND valid_args > /dev/null 2>&1
echo "Happy path exit code: $?" | tee e2e-evidence/cli-exit-codes.txt

# Errors should exit non-zero
$BINARY --bad-flag > /dev/null 2>&1
echo "Bad flag exit code: $?" | tee -a e2e-evidence/cli-exit-codes.txt

$BINARY COMMAND missing_file.txt > /dev/null 2>&1
echo "Missing file exit code: $?" | tee -a e2e-evidence/cli-exit-codes.txt
```

Standard exit codes: 0 = success, 1 = general error, 2 = usage error.

## Step 7: Stdin / Pipe Input

If the tool accepts stdin:
```bash
echo "input data line 1" | $BINARY COMMAND 2>&1 | tee e2e-evidence/cli-stdin.txt
echo "Exit code: $?" >> e2e-evidence/cli-stdin.txt

cat input-file.txt | $BINARY COMMAND 2>&1 | tee e2e-evidence/cli-pipe.txt
echo "Exit code: $?" >> e2e-evidence/cli-pipe.txt
```

Test empty stdin:
```bash
echo "" | $BINARY COMMAND 2>&1 | tee e2e-evidence/cli-empty-stdin.txt
echo "Exit code: $?" >> e2e-evidence/cli-empty-stdin.txt
```

## Step 8: Output Format Verification

If the tool outputs structured data (JSON, CSV, table):
```bash
# JSON output — verify it parses
$BINARY COMMAND --format json ARG 2>&1 | tee e2e-evidence/cli-json-output.txt
jq . e2e-evidence/cli-json-output.txt > /dev/null 2>&1 && echo "Valid JSON" || echo "INVALID JSON"

# CSV output — verify header and row count
$BINARY COMMAND --format csv ARG 2>&1 | tee e2e-evidence/cli-csv-output.txt
head -1 e2e-evidence/cli-csv-output.txt  # Check header
wc -l e2e-evidence/cli-csv-output.txt    # Check row count
```

## Evidence Standards

**GOOD:** Full stdout/stderr saved to file, exit code captured, output describes what the command actually produced.

**BAD:** "Command ran successfully" or "Output looked correct" without saving the actual output.

Every evidence file must contain the FULL command output — exit code alone is not evidence.

## Common Failures

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Command not found | Binary not in PATH or not built | Verify build step, use absolute path |
| Segfault / panic | Null pointer, out-of-bounds, unhandled error | Check error handling in code path |
| Exit code 0 on error | Error path does not set exit code | Add `process.exit(1)` / `os.Exit(1)` / `std::process::exit(1)` |
| Garbled output | Binary output mixed with stderr | Separate stdout and stderr in evidence capture |
| Hangs on stdin | Tool expects stdin but none provided | Pass `< /dev/null` or provide input |
| JSON parse error in output | Extra text (warnings, logs) mixed with JSON | Ensure structured output goes to stdout, logs to stderr |

## PASS Criteria Template

- [ ] Binary builds without errors
- [ ] `--help` produces readable, complete usage information (exit code 0)
- [ ] `--version` outputs version string (exit code 0)
- [ ] Happy path produces expected output (exit code 0)
- [ ] Invalid flag produces helpful error (exit code non-zero)
- [ ] Missing argument produces helpful error (exit code non-zero)
- [ ] File-not-found produces clear message (exit code non-zero, no stack trace)
- [ ] Stdin/pipe input works correctly (if applicable)
- [ ] Output format (JSON/CSV) is valid and parseable (if applicable)
