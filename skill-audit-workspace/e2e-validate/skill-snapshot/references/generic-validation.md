# Generic Validation Reference

Fallback validation approach for projects that don't match iOS, web, API, CLI, or fullstack patterns. This guide provides an adaptive framework for validating any software system.

## When This Applies

This reference is used when the project doesn't clearly match any platform:
- Desktop applications (Electron, Tauri, native)
- Data pipelines and ETL scripts
- Libraries and SDKs (validate through their example/demo apps)
- Infrastructure tools (Terraform, Ansible)
- Machine learning models and notebooks
- Game engines and simulations
- Embedded systems with host-side tools

## Adaptive Validation Process

### Step 1: Find the Entry Point

Every project has a way to run it. Find it:

```bash
# Check for standard entry points
cat Makefile 2>/dev/null | grep -E "^[a-zA-Z].*:" | head -10     # Make targets
cat package.json 2>/dev/null | jq '.scripts' 2>/dev/null          # npm scripts
cat Cargo.toml 2>/dev/null | grep -A2 '\[package\]'              # Rust crate
cat setup.py 2>/dev/null | head -20                               # Python package
cat pyproject.toml 2>/dev/null | grep -A5 '\[project.scripts\]'  # Python CLI
ls *.sh run.* start.* main.* 2>/dev/null                          # Script entry points
cat README.md 2>/dev/null | grep -A3 -i "usage\|getting started\|run"  # Docs
```

### Step 2: Determine What "Working" Means

Ask these questions about the project:

| Question | How to Answer | Evidence Type |
|----------|--------------|---------------|
| What does it produce? | Run it and observe output | stdout, files, UI |
| Who uses it? | Read README, docs | User story mapping |
| What input does it need? | Check args, config files, stdin | Input/output pairs |
| What does success look like? | Run with known-good input | Expected output comparison |
| What does failure look like? | Run with bad input | Error messages, exit codes |

### Step 3: Build and Run

```bash
# Try common build patterns
make build 2>&1 || \
  npm run build 2>&1 || \
  cargo build 2>&1 || \
  go build ./... 2>&1 || \
  python setup.py build 2>&1 || \
  echo "No standard build found — check README"

# Capture build output
# Redirect to e2e-evidence/j0-build.txt
```

### Step 4: Exercise Core Functionality

Run the primary operation and capture ALL output:

```bash
# Whatever the main command is:
{COMMAND} {ARGS} 2>&1 | tee e2e-evidence/j1-main-operation.txt
echo "EXIT: $?" >> e2e-evidence/j1-main-operation.txt

# If it produces files:
ls -la {output_path} >> e2e-evidence/j1-main-operation.txt
head -20 {output_file} >> e2e-evidence/j1-main-operation.txt

# If it has a UI:
# Take screenshot via appropriate tool
```

### Step 5: Verify Output

Compare actual output against expected behavior:

```bash
# For deterministic output: compare against known-good
diff expected_output.txt actual_output.txt 2>&1 | tee e2e-evidence/j1-diff.txt

# For non-deterministic output: check structural properties
# - File exists and has content
# - Output contains expected keywords
# - Exit code is 0
# - No error messages in stderr
```

## Library/SDK Validation

Libraries can't be validated directly — validate through their consumer:

1. Find the `examples/` or `demo/` directory
2. Build and run an example application
3. Verify the example works correctly
4. If no examples exist, write a minimal script that imports the library and calls its primary function

```bash
# Check for examples
ls examples/ demo/ sample/ 2>/dev/null

# Run an example
cd examples/basic && {build_and_run_command} 2>&1 \
  | tee e2e-evidence/j1-example.txt
echo "EXIT: $?" >> e2e-evidence/j1-example.txt
```

## Data Pipeline Validation

```bash
# Verify input data exists
ls -la input/ | tee e2e-evidence/j0-input.txt
wc -l input/*.csv >> e2e-evidence/j0-input.txt

# Run pipeline
{pipeline_command} 2>&1 | tee e2e-evidence/j1-pipeline.txt
echo "EXIT: $?" >> e2e-evidence/j1-pipeline.txt

# Verify output
ls -la output/ | tee e2e-evidence/j1-output.txt
wc -l output/*.csv >> e2e-evidence/j1-output.txt
head -5 output/*.csv >> e2e-evidence/j1-output.txt

# Check: row counts make sense, no empty outputs, no error lines
```

## Evidence Quality Examples

**GOOD generic review:**
> "Ran `make process INPUT=data/sample.csv`. Exit code 0.
> Output: `Processed 1,247 rows, wrote 3 output files (summary.json, details.csv, errors.log)`.
> summary.json has 1,247 entries with id, score, and category fields.
> details.csv has 1,248 lines (header + 1,247 rows).
> errors.log is empty (no processing errors)."

**BAD generic review:**
> "Pipeline ran successfully"

## Common Generic Validation Journeys

| Journey | What to Check | Key Evidence |
|---------|--------------|-------------|
| Build | Project compiles without errors | Build output with success message |
| Run | Primary operation executes | stdout/stderr + exit code |
| Output | Produces expected artifacts | File listing + content sample |
| Error Handling | Handles bad input gracefully | Error message + non-zero exit code |
| Documentation | README matches reality | Commands in README actually work |
