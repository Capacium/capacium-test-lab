# Capacium Test Lab — Agents Guide

## Language

**English is REQUIRED for ALL Capacium content.**
README files, documentation, inline code comments, commit messages, PR descriptions, release notes — everything is English. No exceptions for published content.

## Quick Start

```bash
# Start all P0 frameworks
docker compose up -d opencode claude-code codex-cli

# Test a capability
bash scripts/test-framework.sh opencode test-skill

# Run BATS suite
bash tests/run_tests.sh all
```

## Architecture

### Test Suites

| Suite | Path | Purpose | Test Framework |
|-------|------|---------|---------------|
| unit | `tests/unit/` | Framework adapter unit tests | BATS |
| integration | `tests/integration/` | `cap install` + symlink integration | BATS |
| smoke | `tests/smoke/` | Fixture validation (capability.yaml, MCP server) | BATS |
| cli | `tests/cli/` | CLI command functional tests for ALL `cap` commands | BATS |

6 frameworks (3 P0 + 3 P1). Universal lifecycle API (`install/verify/test/clean.sh`). GitHub Actions CI matrix: 5 frameworks × 2 capabilities = 10 jobs.

### CLI Test Suite (`tests/cli/`)

Functional tests against the `cap` binary. Covers:
- **`test_cli_meta.bats`** — `--version`, `--help`, `cap` no-args, invalid commands, required arg validation
- **`test_search.bats`** — All `--kind`, `--trust`, `--category`, `--sort`, `--json`, `--limit`, `--framework`, `--tag` flags, JSON validation, schema field
- **`test_info.bats`** — `cap info <name>` with `--json`, owner/name and bare name formats
- **`test_compare.bats`** — `cap compare <a> <b>` with `--json`, schema field, missing arg validation
- **`test_update_index.bats`** — `cap update-index` with `--full`, `--registry`
- **`test_browse.bats`** — `cap browse` smoke tests (TUI can't be fully scripted)
- **`test_other_commands.bats`** — `cap list`, `cap doctor`, `cap runtimes`, `cap verify`, `cap lock`, `cap package`, `cap publish`, `cap marketplace`, `cap config`, `cap init`, `cap registry`, `cap mcp`, `cap submit`
- **`test_e2e.bats`** — End-to-end workflows: local index validation, JSON structure, info→compare chain, piped JSON integrity

All CLI tests use `${CAP}` env var (defaults to `cap`) for flexibility in CI.

## Fixtures

- `test-skill` — validates `cap install` + symlink creation
- `test-mcp-server` — minimal stdio JSON-RPC MCP server

## Development Workflow

### When Adding New `cap` Functionality

**REQUIRED:** Every new CLI command, subcommand, flag, or significant behavior change in `Capacium/capacium` core MUST include corresponding BATS tests in `tests/cli/`.

1. Create or extend the relevant `tests/cli/test_*.bats` file
2. Follow existing patterns: `run "$CAP" <command>`, assert `[ "$status" -eq 0 ]`, validate output
3. For JSON output: pipe through `python3 -c "import json,sys; json.load(sys.stdin)"` to validate
4. For TUI/interactive commands: smoke-test flag parsing only (TUI can't be scripted)
5. Add new behavior + test in the same PR/commit

### Running CLI Tests Locally

```bash
# Run all CLI tests
CAP=/path/to/dev/cap bash tests/run_tests.sh cli

# Run a specific file
CAP=/path/to/dev/cap bats tests/cli/test_search.bats

# With custom cap binary
CAP=.venv/bin/cap bats tests/cli/
```

### Test Patterns

- **Help output:** `run "$CAP" <cmd> --help` → assert `[ "$status" -eq 0 ]` + grep for expected flags
- **Missing args:** `run "$CAP" <cmd>` without required positional → assert `[ "$status" -ne 0 ]`
- **JSON validation:** `echo "$output" | python3 -c "import json,sys; json.load(sys.stdin)"`
- **Schema check:** assert `'$schema' in d` and `d['$schema'].startswith('https://')`
- **Graceful skip:** `skip "Exchange not reachable"` when remote API unavailable
- **TUI commands:** `run "$CAP" browse <<< "q"` — test flag parsing, not full TUI interaction
