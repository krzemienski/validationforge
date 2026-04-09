# Rust CLI Validation Reference

Platform-specific commands, tools, and patterns for validating Rust command-line tools and utilities.

## Build

```bash
# Check code compiles without producing binary (fast)
cargo check 2>&1 | tee e2e-evidence/preflight-cargo-check.txt
echo "EXIT: $?" >> e2e-evidence/preflight-cargo-check.txt

# Build release binary (optimized, production-equivalent)
cargo build --release 2>&1 | tee e2e-evidence/preflight-cargo-build.txt
echo "EXIT: $?" >> e2e-evidence/preflight-cargo-build.txt

# Set binary path from Cargo.toml package name
BINARY="./target/release/mytool"

# Verify binary exists and is executable
ls -la $BINARY >> e2e-evidence/preflight-cargo-build.txt
file $BINARY >> e2e-evidence/preflight-cargo-build.txt
```

### Cargo Check vs Cargo Build

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `cargo check` | Verify code compiles, no binary output | Preflight fast check |
| `cargo build` | Debug binary with symbols | Development iteration |
| `cargo build --release` | Optimized production binary | Validation of release behavior |

## Basic Execution

```bash
# Run with no args (should show help or usage error)
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

## Cargo Test Output Capture

Capture `cargo test` output with structured evidence:

```bash
# Run all tests and capture output
cargo test 2>&1 | tee e2e-evidence/preflight-cargo-test.txt
echo "EXIT: $?" >> e2e-evidence/preflight-cargo-test.txt

# Run tests with output visible (no capture by default)
cargo test -- --nocapture 2>&1 | tee e2e-evidence/preflight-cargo-test-verbose.txt
echo "EXIT: $?" >> e2e-evidence/preflight-cargo-test-verbose.txt

# Run a specific test by name
cargo test test_process_valid_input -- --nocapture 2>&1 \
  | tee e2e-evidence/preflight-specific-test.txt
echo "EXIT: $?" >> e2e-evidence/preflight-specific-test.txt

# Run tests for a specific module
cargo test integration:: -- --nocapture 2>&1 \
  | tee e2e-evidence/preflight-integration-tests.txt
echo "EXIT: $?" >> e2e-evidence/preflight-integration-tests.txt

# Parse test summary line from output
grep -E "^test result:" e2e-evidence/preflight-cargo-test.txt \
  >> e2e-evidence/preflight-test-summary.txt
```

### Interpreting Cargo Test Output

```
test result: ok. 42 passed; 0 failed; 1 ignored; 0 measured; 0 filtered out
```

Evidence must quote this exact line. A passing test run must show `0 failed`.

## Clippy Linting

```bash
# Run clippy for lint warnings and errors
cargo clippy 2>&1 | tee e2e-evidence/preflight-clippy.txt
echo "EXIT: $?" >> e2e-evidence/preflight-clippy.txt

# Treat all warnings as errors (CI-equivalent strictness)
cargo clippy -- -D warnings 2>&1 | tee e2e-evidence/preflight-clippy-strict.txt
echo "EXIT: $?" >> e2e-evidence/preflight-clippy-strict.txt

# Clippy with all targets (tests, examples, benches)
cargo clippy --all-targets -- -D warnings 2>&1 \
  | tee e2e-evidence/preflight-clippy-all.txt
echo "EXIT: $?" >> e2e-evidence/preflight-clippy-all.txt
```

### Clippy Evidence Requirements

A passing clippy run should contain:
```
warning: 0 warnings emitted
```
or simply exit code 0 with no warning lines. Quote the exact clippy output line in evidence.

## Exit Code Verification

| Exit Code | Meaning | When to Expect |
|-----------|---------|---------------|
| 0 | Success | Normal operation completed |
| 1 | General error | Runtime failure, invalid input, logic error |
| 2 | Usage error | Wrong arguments, missing required flags (clap default) |
| 101 | Panic / unrecoverable error | Rust panic!, assert! failure |
| 126 | Permission denied | Can't execute binary |
| 127 | Command not found | Binary path incorrect |

Always verify exit codes explicitly:

```bash
$BINARY process input.json
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
  echo "PASS: exit code 0" >> e2e-evidence/j2-exit-code.txt
else
  echo "FAIL: expected exit code 0, got $EXIT_CODE" >> e2e-evidence/j2-exit-code.txt
fi
```

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

## Subcommand Testing (clap pattern)

Rust CLIs commonly use `clap` with subcommands:

```bash
# List available subcommands via help
$BINARY --help 2>&1 | tee e2e-evidence/j3-subcommands.txt

# Test each subcommand
$BINARY init --name myproject 2>&1 | tee e2e-evidence/j3-init.txt
echo "EXIT: $?" >> e2e-evidence/j3-init.txt

$BINARY list 2>&1 | tee e2e-evidence/j3-list.txt
echo "EXIT: $?" >> e2e-evidence/j3-list.txt

$BINARY run --config config.yaml 2>&1 | tee e2e-evidence/j3-run.txt
echo "EXIT: $?" >> e2e-evidence/j3-run.txt

# Subcommand-specific help
$BINARY init --help 2>&1 | tee e2e-evidence/j3-init-help.txt
echo "EXIT: $?" >> e2e-evidence/j3-init-help.txt
```

## Error Case Testing

```bash
# Invalid flag (clap returns exit code 2)
$BINARY --nonexistent-flag 2>&1 | tee e2e-evidence/j4-bad-flag.txt
echo "EXIT: $?" >> e2e-evidence/j4-bad-flag.txt
# Expected: exit code 2, clap error message with usage hint

# Missing required argument
$BINARY process 2>&1 | tee e2e-evidence/j4-missing-arg.txt
echo "EXIT: $?" >> e2e-evidence/j4-missing-arg.txt
# Expected: exit code 2, "required arguments were not provided"

# Non-existent input file
$BINARY process /nonexistent/file.json 2>&1 | tee e2e-evidence/j4-no-file.txt
echo "EXIT: $?" >> e2e-evidence/j4-no-file.txt
# Expected: exit code 1, "No such file or directory (os error 2)"

# Invalid input format
echo "not json" > /tmp/bad-input.txt
$BINARY process /tmp/bad-input.txt 2>&1 | tee e2e-evidence/j4-bad-input.txt
echo "EXIT: $?" >> e2e-evidence/j4-bad-input.txt
# Expected: exit code 1, parse/deserialization error message

# Permission denied
chmod 000 /tmp/locked-file.txt 2>/dev/null || true
$BINARY process /tmp/locked-file.txt 2>&1 | tee e2e-evidence/j4-permission.txt
echo "EXIT: $?" >> e2e-evidence/j4-permission.txt
chmod 644 /tmp/locked-file.txt 2>/dev/null || true  # cleanup
# Expected: exit code 1, "Permission denied (os error 13)"
```

## Stdin/Pipe Testing

```bash
# Pipe input via stdin
echo '{"name": "test"}' | $BINARY process 2>&1 | tee e2e-evidence/j5-stdin.txt
echo "EXIT: $?" >> e2e-evidence/j5-stdin.txt

# File redirect
$BINARY process < input.json 2>&1 | tee e2e-evidence/j5-redirect.txt
echo "EXIT: $?" >> e2e-evidence/j5-redirect.txt

# Chain with other tools
cat data.json | $BINARY transform | jq '.count' 2>&1 | tee e2e-evidence/j5-pipe.txt
echo "EXIT: $?" >> e2e-evidence/j5-pipe.txt
```

## File I/O Verification

```bash
# Run command that produces output file
$BINARY export --format csv --output result.csv data.json 2>&1 \
  | tee e2e-evidence/j6-export.txt
echo "EXIT: $?" >> e2e-evidence/j6-export.txt

# Verify output file content
if [ -f result.csv ]; then
  echo "Output file exists: $(wc -l < result.csv) lines" >> e2e-evidence/j6-export.txt
  head -5 result.csv >> e2e-evidence/j6-export.txt
else
  echo "FAIL: output file result.csv not created" >> e2e-evidence/j6-export.txt
fi
```

## Evidence Quality Examples

**GOOD build evidence:**
> "`cargo build --release` completed with: `Compiling mytool v1.2.3`. Final line:
> `Finished release [optimized] target(s) in 4.82s`. Exit code: 0.
> Binary confirmed at `./target/release/mytool` (2.1MB, ELF 64-bit executable)."

**BAD build evidence:**
> "cargo build succeeded"

---

**GOOD test evidence:**
> "`cargo test` output: `running 42 tests` ... `test result: ok. 42 passed; 0 failed;
> 1 ignored; 0 measured; 0 filtered out; finished in 0.34s`. Exit code: 0."

**BAD test evidence:**
> "Tests passed"

---

**GOOD --help evidence:**
> "`mytool --help` output: `mytool 1.2.3 - A fast data processing tool\n\nUSAGE:\n
> mytool [OPTIONS] <SUBCOMMAND>\n\nSUBCOMMANDS:\n  process  Process input files\n
> list     List available items\n  help     Print this message or the help of the
> given subcommand(s)`. Exit code: 0."

**BAD --help evidence:**
> "Help text displayed correctly"

---

**GOOD error evidence:**
> "`mytool process --bad-flag` stderr: `error: Found argument '--bad-flag' which wasn't
> expected, or isn't valid in this context\n\nUSAGE:\n    mytool process <FILE>\n\nFor
> more information try --help`. Exit code: 2."

**BAD error evidence:**
> "Error handling works correctly"

---

**GOOD clippy evidence:**
> "`cargo clippy -- -D warnings` output: `Checking mytool v1.2.3\nFinished dev
> [unoptimized + debuginfo] target(s) in 0.47s`. No warning lines in output.
> Exit code: 0."

**BAD clippy evidence:**
> "Clippy passed"

## Common Rust CLI Validation Journeys

| Journey | Command | Key Evidence |
|---------|---------|-------------|
| Cargo Check | `cargo check` | `Finished` line, exit code 0, no compiler errors |
| Release Build | `cargo build --release` | `Finished release [optimized]` line, binary exists with correct size |
| Unit Tests | `cargo test` | `test result: ok. N passed; 0 failed` line, exit code 0 |
| Clippy Lint | `cargo clippy -- -D warnings` | No warning lines, exit code 0 |
| Help Text | `$BINARY --help` | All subcommands and flags listed, version shown, exit code 0 |
| Version Flag | `$BINARY --version` | Version string matches `Cargo.toml` version, exit code 0 |
| Happy Path | `$BINARY process input.json` | Expected output quoted, exit code 0 |
| File Output | `$BINARY export --output out.csv` | Output file exists, line count and sample content quoted |
| Bad Flag | `$BINARY --nonexistent-flag` | clap error message quoted, exit code 2 |
| Missing Arg | `$BINARY process` (no input) | "required arguments" error quoted, exit code 2 |
| Missing File | `$BINARY process /nonexistent` | "os error 2" / "No such file" error quoted, exit code 1 |
| Panic Safety | Invalid data causing panic | Exit code 101, panic message captured |
| Pipe Support | `echo data \| $BINARY process` | Processes stdin, expected output, exit code 0 |
