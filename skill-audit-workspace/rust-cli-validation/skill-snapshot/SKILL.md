---
name: rust-cli-validation
description: "Validate Rust CLI apps via cargo: check, clippy, release build, binary execution. Detects panics, exit codes, error messages. Tests help, version, happy path, error cases."
context_priority: standard
---

# Rust CLI Validation

## Prerequisites

| Requirement | How to verify |
|-------------|---------------|
| Rust toolchain installed | `rustc --version` |
| cargo available | `cargo --version` |
| clippy installed | `cargo clippy --version` or `rustup component list --installed \| grep clippy` |
| Cargo.toml present | `ls Cargo.toml` |
| Evidence directory exists | `mkdir -p e2e-evidence` |

## Step 1: Cargo Check

Verify the project compiles without errors (fast, no binary produced):

```bash
cargo check 2>&1 | tee e2e-evidence/rust-cargo-check.txt
echo "Exit code: $?" >> e2e-evidence/rust-cargo-check.txt
```

Expected: exit code 0, no `error[E...]` lines in output.

## Step 2: Cargo Clippy

Run the Rust linter to catch common mistakes and non-idiomatic code:

```bash
cargo clippy -- -D warnings 2>&1 | tee e2e-evidence/rust-clippy.txt
echo "Exit code: $?" >> e2e-evidence/rust-clippy.txt
```

Expected: exit code 0, no `warning:` or `error:` lines.  
If warnings exist and `-D warnings` is too strict for the project, run without the flag and document any warnings:

```bash
cargo clippy 2>&1 | tee e2e-evidence/rust-clippy.txt
echo "Exit code: $?" >> e2e-evidence/rust-clippy.txt
grep -c '^warning' e2e-evidence/rust-clippy.txt >> e2e-evidence/rust-clippy.txt || true
```

## Step 3: Cargo Build (Release)

Produce the optimized release binary:

```bash
cargo build --release 2>&1 | tee e2e-evidence/rust-build-release.txt
echo "Exit code: $?" >> e2e-evidence/rust-build-release.txt
```

Verify the binary exists and is executable:

```bash
# Replace TOOL_NAME with the actual binary name from Cargo.toml [[bin]] name
BINARY="target/release/TOOL_NAME"
ls -la $BINARY | tee -a e2e-evidence/rust-build-release.txt
file $BINARY | tee -a e2e-evidence/rust-build-release.txt
```

Expected: exit code 0, binary present, `file` reports an ELF/Mach-O executable.

## Step 4: Binary Execution

### Help output

```bash
$BINARY --help 2>&1 | tee e2e-evidence/rust-cli-help.txt
echo "Exit code: $?" >> e2e-evidence/rust-cli-help.txt
```

Verify help output includes:
- Usage syntax
- Available subcommands or flags
- Option descriptions

### Version check

```bash
$BINARY --version 2>&1 | tee e2e-evidence/rust-cli-version.txt
echo "Exit code: $?" >> e2e-evidence/rust-cli-version.txt
```

Expected: version string matching `Cargo.toml` version field (exit code 0).

### Happy path execution

Run the primary command with valid arguments:

```bash
$BINARY COMMAND ARG1 ARG2 --flag value 2>&1 | tee e2e-evidence/rust-cli-happy-path.txt
echo "Exit code: $?" >> e2e-evidence/rust-cli-happy-path.txt
```

If the tool produces output files:

```bash
$BINARY COMMAND --output output.json ARG1 2>&1 | tee e2e-evidence/rust-cli-happy-path.txt
echo "Exit code: $?" >> e2e-evidence/rust-cli-happy-path.txt
cp output.json e2e-evidence/rust-cli-output-file.json
```

### Error cases

**Invalid flag:**
```bash
$BINARY --nonexistent-flag 2>&1 | tee e2e-evidence/rust-cli-error-invalid-flag.txt
echo "Exit code: $?" >> e2e-evidence/rust-cli-error-invalid-flag.txt
```
Expected: non-zero exit code, helpful error message, no Rust panic/backtrace.

**Missing required argument:**
```bash
$BINARY COMMAND 2>&1 | tee e2e-evidence/rust-cli-error-missing-arg.txt
echo "Exit code: $?" >> e2e-evidence/rust-cli-error-missing-arg.txt
```
Expected: non-zero exit code, message indicating which argument is missing.

**File not found:**
```bash
$BINARY COMMAND /path/to/nonexistent/file.txt 2>&1 | tee e2e-evidence/rust-cli-error-no-file.txt
echo "Exit code: $?" >> e2e-evidence/rust-cli-error-no-file.txt
```
Expected: non-zero exit code, clear "file not found" or "No such file" message — not a panic.

## Step 5: Cargo Test

Run the project's unit and integration tests:

```bash
cargo test 2>&1 | tee e2e-evidence/rust-cargo-test.txt
echo "Exit code: $?" >> e2e-evidence/rust-cargo-test.txt
```

Check the summary line:

```bash
grep -E 'test result:' e2e-evidence/rust-cargo-test.txt | tee -a e2e-evidence/rust-cargo-test.txt
```

Expected: `test result: ok. N passed; 0 failed` (exit code 0).  
If tests fail, quote the failing test names and error output as evidence.

## Step 6: Exit Code Verification

Exit codes must follow Unix conventions:

```bash
# Success should exit 0
$BINARY COMMAND valid_args > /dev/null 2>&1
echo "Happy path exit code: $?" | tee e2e-evidence/rust-exit-codes.txt

# Errors should exit non-zero
$BINARY --bad-flag > /dev/null 2>&1
echo "Bad flag exit code: $?" | tee -a e2e-evidence/rust-exit-codes.txt

$BINARY COMMAND missing_file.txt > /dev/null 2>&1
echo "Missing file exit code: $?" | tee -a e2e-evidence/rust-exit-codes.txt
```

Standard exit codes: 0 = success, 1 = general error, 2 = usage/argument error.  
Rust programs that `panic!` exit with code 101 — this is **always a FAIL**.

## Common Failures

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| `error[E...]` in cargo check | Compilation error in source | Fix the Rust compiler error cited in output |
| clippy `warning: unused import` | Dead code or import | Remove unused imports; add `#[allow(unused_imports)]` only if intentional |
| Binary not found after build | Wrong binary name or workspace path | Check `[[bin]] name` in `Cargo.toml`; use `cargo build --release -p PKG` for workspaces |
| `thread 'main' panicked` | Unhandled `unwrap()`/`expect()` on `None`/`Err` | Replace with proper error handling (`?`, `match`, or `if let`) |
| Exit code 101 | Rust panic reached at runtime | Eliminate all `.unwrap()` / `.expect()` on user-controlled input paths |
| Exit code 0 on error | Error path returns `Ok(())` incorrectly | Return `Err(...)` or call `std::process::exit(1)` |
| Garbled output | Mixing `println!` and `eprintln!` on same stream | Use `eprintln!` for diagnostics, `println!` for structured output |
| Hangs on stdin | Tool reads stdin but none provided | Pass `< /dev/null` or supply input via pipe |
| `cargo test` failures | Logic bug exposed by tests | Fix the underlying logic; do not disable tests |

## PASS Criteria Template

- [ ] `cargo check` exits 0 with no compiler errors
- [ ] `cargo clippy` exits 0 with no warnings (or documented acceptable warnings)
- [ ] `cargo build --release` exits 0; release binary present and executable
- [ ] `--help` produces readable, complete usage information (exit code 0)
- [ ] `--version` outputs version string matching `Cargo.toml` (exit code 0)
- [ ] Happy path produces expected output (exit code 0, no panic)
- [ ] Invalid flag produces helpful error (exit code non-zero, no panic)
- [ ] Missing argument produces helpful error (exit code non-zero, no panic)
- [ ] File-not-found produces clear message (exit code non-zero, no stack trace)
- [ ] `cargo test` exits 0 with 0 failed tests
- [ ] No exit code 101 (panic) in any execution path
