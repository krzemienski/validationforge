# Analysis Protocol

*Loaded by `ai-evidence-analysis` when executing Steps 1-3 of an analysis run and you need the evidence-discovery `find` snippet, the extension + magic-byte classification logic, and the per-type model prompts (screenshot / api-response / cli-output).*

## Step 1: Discover Evidence

```bash
find e2e-evidence/ -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.json" -o -name "*.txt" -o -name "*.log" \) \
  | sort > e2e-evidence/evidence-inventory.txt
cat e2e-evidence/evidence-inventory.txt
```

Skip files that are 0 bytes — empty evidence files are invalid and should be noted as failures.

**Pre-classify with**: `bash scripts/detect-evidence-type.sh --evidence-dir=e2e-evidence --write-tsv` produces `e2e-evidence/_classified.tsv` that subsequent steps can read to skip the extension-based classification logic inline. The TSV columns are `file_path\tcategory\tbytes\tnon_empty` where `category` ∈ {screenshot, api_response, dom_snapshot, cli_output, log, network_trace, verdict, notes, unknown} and `non_empty=1` when size > 10 bytes. Downstream steps only need to filter by category; the heuristics below remain as a reference / fallback when the script is unavailable.

## Step 2: Classify Evidence Types

Determine evidence type using **both file extension and content inspection**:

### By File Extension (primary detection)

| Extension | Evidence Type | Analysis Model |
|-----------|--------------|----------------|
| `.png`, `.jpg`, `.jpeg`, `.webp` | `screenshot` | Vision (claude-sonnet with vision) |
| `.json` | `api-response` | LLM text analysis |
| `.txt`, `.log` | `cli-output` | LLM text analysis |

### By Content (fallback when extension is ambiguous)

When the extension is missing or generic (e.g., no extension, `.out`, `.data`), inspect the first 512 bytes of the file:

```bash
file_head=$(head -c 512 "$evidence_file")

# Detect JSON
if echo "$file_head" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
  evidence_type="api-response"
# Detect image magic bytes (PNG: \x89PNG, JPEG: \xFF\xD8)
elif xxd -l 4 "$evidence_file" | grep -qE "8950 4e47|ffd8 ffe"; then
  evidence_type="screenshot"
# Default to CLI output for readable text
else
  evidence_type="cli-output"
fi
```

Skip analysis (and flag as invalid) for:
- Files that are 0 bytes
- Files that cannot be read (permissions error)
- Binary files with no detected image magic bytes

## Step 3: Analyze by Type

### Screenshot Analysis (Vision Model)

Provide the screenshot to the vision model with a structured prompt:

```
Analyze this screenshot as validation evidence. Answer the following:
1. Is the page fully rendered (no blank areas, spinners, or loading states)?
2. Are there any visible error messages or error states?
3. What key UI elements are visible? List them specifically.
4. Are there any layout defects (overlapping elements, cut-off text, broken images)?
5. Overall: does this screenshot constitute positive evidence that the feature is working?

Respond in JSON matching the AnalysisResult schema.
```

### API Response Analysis (LLM)

Provide the JSON response body with this prompt:

```
Analyze this API response as validation evidence. Check:
1. Is the HTTP response a success status (2xx)?
2. Are all expected fields present and non-null?
3. Do field values match expected types and formats?
4. Are there any error objects, empty required arrays, or null required fields?
5. Overall: does this response confirm the API is functioning correctly?

Respond in JSON matching the AnalysisResult schema.
```

### CLI Output Analysis (LLM)

Provide the CLI output text with this prompt:

```
Analyze this CLI output as validation evidence. Check:
1. Are there any ERROR, FATAL, or PANIC lines?
2. Are there unexpected WARNING lines that indicate problems?
3. Is there a success indicator (exit 0, "Done", "Success", "Passed")?
4. Are there any stack traces or exception messages?
5. Overall: does this output indicate successful execution?

Respond in JSON matching the AnalysisResult schema.
```
