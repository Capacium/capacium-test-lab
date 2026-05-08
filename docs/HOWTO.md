# HOWTO — Writing Tests for Capacium Test Lab

## Test Framework

All tests use [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core). BATS is auto-installed to `/tmp/bats-core` by `tests/run_tests.sh`.

## File Structure

```
tests/cli/
├── helpers.bash              ← Shared setup loaded by all test files
├── test_install.bats         ← cap install tests
├── test_other_commands.bats  ← remove, init, lock, package, runtimes, doctor, config
├── test_signing.bats         ← key generate, sign, verify
├── test_search.bats          ← search flags, JSON output, combined flags
├── test_info.bats            ← info with JSON, formats, registry
├── test_compare.bats         ← compare with JSON, local/remote
├── test_cli_meta.bats        ← --version, --help, no-args
├── test_e2e.bats             ← End-to-end workflows
├── test_browse.bats          ← browse smoke tests
└── test_update_index.bats    ← update-index
```

## Creating a New Test File

```bash
#!/usr/bin/env bats

setup() {
    load '../helpers'          # MUST be first — exports FIXTURES_DIR, cap_cleanup, etc.
    CAP="${CAP:-cap}"          # Overrideable cap binary
    cap_cleanup                # Clean any residual installs from prior runs
}

@test "cap <command> does something" {
    run "$CAP" <command> <args>
    [ "$status" -eq 0 ]
    [[ "$output" =~ "expected text" ]]
}

@test "cap <command> errors on invalid input" {
    run "$CAP" <command> --invalid
    [ "$status" -ne 0 ]
}
```

## Available Helper Functions

All exported by `tests/helpers.bash`:

```bash
# Clean all known test capabilities
cap_cleanup

# Install a fixture by name (name = fixture directory name without path)
cap_install test-skill
# Or with extra args:
cap_install test-mcp-server "--skip-runtime-check"

# Force-remove a capability
cap_remove test-skill

# Pre-resolved paths
echo "$FIXTURES_DIR"      # /path/to/capacium-test-lab/fixtures
echo "$TEST_LAB_ROOT"     # /path/to/capacium-test-lab
echo "$ALL_CAP_KINDS"     # Space-separated fixture names from fixtures.json
```

## Test Patterns

### Exit Code Assertions

```bash
# Success
[ "$status" -eq 0 ]

# Failure
[ "$status" -ne 0 ]

# Either OK
[ "$status" -eq 0 ] || [ "$status" -eq 1 ]
```

### Output Assertions

```bash
# Text in output
[[ "$output" =~ "Installed" ]]

# Case-insensitive
[[ "$output" =~ [Ii]nstalled ]]

# Output contains non-empty text
[[ "$output" =~ [A-Za-z0-9] ]]
```

### JSON Validation

```bash
# Simple: valid JSON?
echo "$output" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null || skip "not JSON"

# Structured: check fields
echo "$output" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert 'name' in d, 'missing name'
assert 'kind' in d, 'missing kind'
assert isinstance(d['results'], list), 'results not a list'
" 2>/dev/null || skip "validation failed"
```

### Graceful Skips

```bash
# Skip when feature not available
[ "$status" -eq 0 ] || skip "feature not available"

# Skip when remote dependency missing
if [ "$status" -eq 0 ]; then
    echo "$output" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null || skip "JSON parse failed"
else
    skip "Exchange not reachable"
fi
```

### Fixture-Based Tests (install/remove/verify)

```bash
@test "cap install and verify lifecycle" {
    # Install from fixture
    run "$CAP" install cap/test-skill --source "$FIXTURES_DIR/test-skill" --yes
    [ "$status" -eq 0 ]

    # Verify it shows in list
    run "$CAP" list
    [[ "$output" =~ "test-skill" ]]

    # Verify fingerprint
    run "$CAP" verify cap/test-skill
    [ "$status" -eq 0 ]
    [[ "$output" =~ [Vv]erif ]]

    # Cleanup
    cap_remove test-skill
}
```

### Error Path Tests

```bash
@test "cap <command> without required args fails" {
    run "$CAP" <command>
    [ "$status" -ne 0 ]
}

@test "cap <command> invalid input fails" {
    run "$CAP" <command> nonexistent-cap-xyz
    [ "$status" -ne 0 ]
}
```

## Adding New Fixtures

1. Create the fixture directory under `fixtures/<name>/`:

```bash
fixtures/test-new-kind/
├── capability.yaml    # Required: name, version, kind, description
└── content-file       # At least one content file
```

2. Register in `fixtures.json`:

```json
{"name": "test-new-kind", "kind": "tool", "version": "1.0.0"}
```

3. That's it — `cap_cleanup()` automatically discovers and cleans the new fixture. No test file changes needed.

## Adding a New Test to an Existing File

1. Add a new `@test` block after the last existing one
2. Follow the file's section header convention (comment lines like `# ── section name ──`)
3. If the test does `cap install`, always add `cap_remove` in cleanup or rely on `cap_cleanup` in next `setup()`

## Running Tests

```bash
# Full CLI suite
CAP=/path/to/cap bash tests/run_tests.sh cli

# Single file
CAP=/path/to/cap bats tests/cli/test_signing.bats

# Single test by name filter
CAP=/path/to/cap bats tests/cli/test_install.bats -f "framework opencode"

# All suites
bash tests/run_tests.sh all
```

## Debugging Tests

```bash
# Verbose output (BATS prints full output on failure)
CAP=/path/to/cap bats --print-output-on-failure tests/cli/test_search.bats

# Add debug output in test
@test "debugging" {
    run "$CAP" some-command
    echo "STATUS=$status" >&3      # stderr in BATS goes to terminal
    echo "OUTPUT=$output" >&3
    [ "$status" -eq 0 ]
}

# Check fixture content
ls "$FIXTURES_DIR/test-skill/"
cat "$FIXTURES_DIR/test-skill/capability.yaml"
```
