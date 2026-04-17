# CLI Validation Reference

Platform-specific commands, tools, and patterns for validating command-line tools and utilities.

## Build

```bash
# Rust
cargo build --release
BINARY="./target/release/mytool"

# Go
go build -o ./bin/mytool ./cmd/mytool
BINARY="./bin/mytool"

# Node.js (compiled)
npm run build
BINARY="./dist/mytool"

# Node.js (interpreted)
BINARY="node ./src/index.js"

# Python
pip install -e .
BINARY="mytool"  # or "python -m mytool"

# Verify binary exists
ls -la $BINARY
file $BINARY
```

## Basic Execution

```bash
# Run with no args (should show help or default behavior)
$BINARY 2>&1 | tee e2e-evidence/j1-no-args.txt
echo "EXIT: $?" >> e2e-evidence/j1-no-args.txt

# Run with --help
$BINARY --help 2>&1 | tee e2e-evidence/j1-help.txt
echo "EXIT: $?" >> e2e-evidence/j1-help.txt

# Run with --version
$BINARY --version 2>&1 | tee e2e-evidence/j1-version.txt
echo "EXIT: $?" >> e2e-evidence/j1-version.txt
```

## Evidence Capture Pattern

Every CLI command uses this pattern:

```bash
$BINARY [args] 2>&1 | tee e2e-evidence/j{N}-{slug}.txt
echo "EXIT: $?" >> e2e-evidence/j{N}-{slug}.txt
```

This captures:
- stdout and stderr combined (`2>&1`)
- Full output saved to file (`tee`)
- Exit code appended at the end

## Core Functionality Testing

```bash
# Standard operation
$BINARY process input.json 2>&1 | tee e2e-evidence/j2-process.txt
echo "EXIT: $?" >> e2e-evidence/j2-process.txt

# With flags
$BINARY process input.json --output result.json --verbose 2>&1 \
  | tee e2e-evidence/j2-process-verbose.txt
echo "EXIT: $?" >> e2e-evidence/j2-process-verbose.txt

# Verify output file was created
ls -la result.json >> e2e-evidence/j2-process-verbose.txt
cat result.json | head -20 >> e2e-evidence/j2-process-verbose.txt
```

## Subcommand Testing

For CLI tools with subcommands:

```bash
# List subcommands
$BINARY help 2>&1 | tee e2e-evidence/j3-subcommands.txt

# Test each subcommand
$BINARY init --name myproject 2>&1 | tee e2e-evidence/j3-init.txt
echo "EXIT: $?" >> e2e-evidence/j3-init.txt

$BINARY list 2>&1 | tee e2e-evidence/j3-list.txt
echo "EXIT: $?" >> e2e-evidence/j3-list.txt

$BINARY run --config config.yaml 2>&1 | tee e2e-evidence/j3-run.txt
echo "EXIT: $?" >> e2e-evidence/j3-run.txt
```

## Error Case Testing

```bash
# Invalid flag
$BINARY --nonexistent-flag 2>&1 | tee e2e-evidence/j4-bad-flag.txt
echo "EXIT: $?" >> e2e-evidence/j4-bad-flag.txt
# Expected: Non-zero exit code, helpful error message

# Missing required argument
$BINARY process 2>&1 | tee e2e-evidence/j4-missing-arg.txt
echo "EXIT: $?" >> e2e-evidence/j4-missing-arg.txt
# Expected: Non-zero exit code, message about missing argument

# Non-existent input file
$BINARY process /nonexistent/file.json 2>&1 | tee e2e-evidence/j4-no-file.txt
echo "EXIT: $?" >> e2e-evidence/j4-no-file.txt
# Expected: Non-zero exit code, "file not found" message

# Invalid input format
echo "not json" > /tmp/bad-input.txt
$BINARY process /tmp/bad-input.txt 2>&1 | tee e2e-evidence/j4-bad-input.txt
echo "EXIT: $?" >> e2e-evidence/j4-bad-input.txt
# Expected: Non-zero exit code, parse error message

# Permission denied
chmod 000 /tmp/locked-file.txt
$BINARY process /tmp/locked-file.txt 2>&1 | tee e2e-evidence/j4-permission.txt
echo "EXIT: $?" >> e2e-evidence/j4-permission.txt
chmod 644 /tmp/locked-file.txt  # cleanup
# Expected: Non-zero exit code, permission error message
```

## Exit Code Validation

| Exit Code | Meaning | When to Expect |
|-----------|---------|---------------|
| 0 | Success | Normal operation completed |
| 1 | General error | Runtime failure, invalid input |
| 2 | Usage error | Wrong arguments, missing flags |
| 126 | Permission denied | Can't execute target file |
| 127 | Command not found | Binary doesn't exist at path |

Always verify exit codes explicitly:

```bash
$BINARY process input.json
if [ $? -eq 0 ]; then
  echo "PASS: exit code 0"
else
  echo "FAIL: expected exit code 0, got $?"
fi
```

## File I/O Verification

When the CLI generates output files:

```bash
# Run command that produces output
$BINARY export --format csv --output result.csv data.json 2>&1 \
  | tee e2e-evidence/j5-export.txt
echo "EXIT: $?" >> e2e-evidence/j5-export.txt

# Verify output file
if [ -f result.csv ]; then
  echo "Output file exists: $(wc -l < result.csv) lines" >> e2e-evidence/j5-export.txt
  head -5 result.csv >> e2e-evidence/j5-export.txt
else
  echo "FAIL: output file result.csv not created" >> e2e-evidence/j5-export.txt
fi
```

## Stdin/Pipe Testing

```bash
# Pipe input
echo '{"name": "test"}' | $BINARY process 2>&1 | tee e2e-evidence/j6-stdin.txt
echo "EXIT: $?" >> e2e-evidence/j6-stdin.txt

# File redirect
$BINARY process < input.json 2>&1 | tee e2e-evidence/j6-redirect.txt
echo "EXIT: $?" >> e2e-evidence/j6-redirect.txt

# Chain with other tools
cat data.json | $BINARY transform | jq '.count' 2>&1 | tee e2e-evidence/j6-pipe.txt
echo "EXIT: $?" >> e2e-evidence/j6-pipe.txt
```

## Evidence Quality Examples

**GOOD output review:**
> "Command `mytool process data.json` output: `Processed 150 records in 2.3s.
> Output written to result.json (45.2KB)`. Exit code: 0.
> result.json contains 150 objects, each with id, name, and timestamp fields."

**BAD output review:**
> "Command ran successfully"

**GOOD error review:**
> "Command `mytool process --bad-flag` output on stderr:
> `Error: unknown flag '--bad-flag'. Run 'mytool --help' for usage.`
> Exit code: 2. Error message is clear and suggests help command."

**BAD error review:**
> "Error handling works correctly"

## Common CLI Validation Journeys

| Journey | Command | Key Evidence |
|---------|---------|-------------|
| Help Text | `--help` | Readable help with all subcommands/flags listed |
| Version | `--version` | Version string matches expected format |
| Happy Path | Main command with valid input | Expected output, exit code 0 |
| File Output | Command producing files | Output file exists with correct content |
| Bad Input | Invalid arguments | Helpful error message, non-zero exit code |
| Missing File | Non-existent input path | "File not found" error, non-zero exit code |
| Pipe Support | `echo data \| tool` | Processes stdin correctly |
