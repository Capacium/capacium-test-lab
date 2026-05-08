# Capacium Test Lab — Agents Guide

## Language

English is REQUIRED for ALL Capacium content.

## Architecture

capacium-test-lab is a **project overlay** on [agent-test-env](https://github.com/LangeVC/agent-test-env). The agent-test-env base provides framework Dockerfiles and lifecycle scripts. This repo overlays Capacium-specific test logic.

### What Comes From agent-test-env Base

- Framework Dockerfiles (`frameworks/*/Dockerfile`)
- Lifecycle scripts: `_lib.sh`, `install.sh`, `verify.sh`, `clean.sh`
- Unit test suites (`tests/unit/`)
- Docker Compose network topology (shared bridge, fixture mounts)

### What capacium-test-lab Overlays

| Asset | Description |
|-------|-------------|
| `frameworks/*/scripts/test.sh` | Calls `cap install --skip-runtime-check` instead of simple symlinks |
| `Dockerfile.runner` | Python 3.12 with cap CLI installed from source |
| `docker-compose.yml` | Adds test-runner service, named volumes for skills |
| `tests/cli/` | 127 BATS tests for all `cap` commands |
| `tests/integration/` | Capacium-specific checks (test-runner, verify scripts) |
| `tests/smoke/` | Fixture YAML + volume validation |
| `fixtures/` | 12 Capacium-branded test capabilities, all 8 capability kinds |
| `fixtures.json` | Central fixture registry — new fixtures are auto-discovered by tests |
| `scripts/test-mcp-live.sh` | MCP JSON-RPC handshake test |
| `scripts/ci-entrypoint.sh` | CI matrix orchestrator |
| `scripts/provision.sh` | Fixture provisioning |

## Quick Start

```bash
git clone https://github.com/Capacium/capacium-test-lab.git
cd capacium-test-lab

# Pull agent-test-env base
git clone --depth 1 https://github.com/LangeVC/agent-test-env.git /tmp/ate
cp -r /tmp/ate/frameworks/* frameworks/
rm -rf /tmp/ate

# Test a capability
docker compose up -d opencode
docker compose run --rm test-runner opencode test-skill
```

## Test Suites

| Suite | Path | Purpose | Test Framework |
|-------|------|---------|---------------|
| cli | `tests/cli/` | `cap` command functional tests | BATS |
| unit | `tests/unit/` | Framework adapter structural tests (from agent-test-env) | BATS |
| integration | `tests/integration/` | Docker Compose + test-runner validation | BATS |
| smoke | `tests/smoke/` | Fixture YAML + volume validation | BATS |

### CLI Test Suite (127 tests)

Functional tests against the `cap` binary. Covers all 25 CLI commands with actual behavior testing.

| File | Tests | Coverage |
|------|-------|----------|
| `test_install.bats` | 18 | Install from all 7 kinds, all flags (`--framework`, `--all-frameworks`, `--skip-runtime-check`, `--no-lock`, `--yes`), error paths |
| `test_signing.bats` | 10 | `cap key generate/list`, `cap sign` with valid/invalid keys, `cap verify` specific/all |
| `test_other_commands.bats` | 40 | `cap remove`, `cap init` (non-interactive + all kinds), `cap lock`, `cap package`, `cap runtimes install`, `cap doctor`, `cap config` edge cases, `cap update`, `cap publish`, `cap submit` |
| `test_search.bats` | 23 | All flags (`--kind`, `--trust`, `--category`, `--sort`, `--json`, `--limit`, `--framework`, `--tag`, `--mcp-client`, `--publisher`, `--min-trust`, `--registry`), combined flags, 0-results |
| `test_info.bats` | 8 | `cap info` with JSON, owner/name formats, local index, `--registry` |
| `test_compare.bats` | 9 | `cap compare` with JSON, local index, `--registry`, edge cases |
| `test_cli_meta.bats` | 7 | `--version`, `--help`, no-args, invalid commands, required arg validation |
| `test_browse.bats` | 3 | `cap browse` smoke tests |
| `test_update_index.bats` | 3 | `cap update-index` with `--full`, `--registry` |
| `test_e2e.bats` | 4 | End-to-end workflows |

### Running Tests

```bash
# All suites
bash tests/run_tests.sh all

# CLI only
CAP=/path/to/dev/cap bash tests/run_tests.sh cli

# Specific file
CAP=.venv/bin/cap bats tests/cli/test_search.bats
```

### Test Patterns

- **Shared helpers:** All tests `load '../helpers'` which exports `FIXTURES_DIR`, `TEST_LAB_ROOT`, `ALL_CAP_KINDS`, `cap_cleanup()`, `cap_install()`, `cap_remove()`
- **Auto-cleanup:** `cap_cleanup` in every `setup()` ensures no residual installs from prior test runs
- **Help output:** `run "$CAP" <cmd> --help` → `[ "$status" -eq 0 ]` + grep for expected flags
- **Missing args:** `run "$CAP" <cmd>` → `[ "$status" -ne 0 ]`
- **JSON validation:** `echo "$output" | python3 -c "import json,sys; json.load(sys.stdin)"`
- **Schema check:** `'$schema' in d` and `d['$schema'].startswith('https://')`
- **Graceful skip:** `skip "Exchange not reachable"` when remote API unavailable

### Fixture Registry (`fixtures.json`)

All test fixtures are declared in `fixtures.json` at the repo root. The shared `helpers.bash` auto-discovers fixture names via `python3 -c "import json; ..."`. When adding new fixture capabilities:

1. Create the fixture directory under `fixtures/<name>/` with `capability.yaml` and content files
2. Add an entry to `fixtures.json`: `{"name": "test-<name>", "kind": "<kind>", "version": "1.0.0"}`
3. Tests that use `load '../helpers'` will auto-discover and clean up the new fixture
4. No test file modifications needed for cleanup — `cap_cleanup()` iterates `ALL_CAP_KINDS`

## Adding New `cap` Functionality

REQUIRED: Every new CLI command, subcommand, flag, or significant behavior change in `Capacium/capacium` core MUST include corresponding BATS tests in `tests/cli/`.

1. Create or extend `tests/cli/test_*.bats`
2. Follow existing patterns — use `load '../helpers'` in `setup()`, call `cap_cleanup` for fixture safety
3. Add new fixtures to `fixtures/` and register them in `fixtures.json`
4. Add test in the same PR/commit as the feature

## Updating agent-test-env Base

When agent-test-env adds new agent support or updates framework Dockerfiles:

```bash
# Pull latest base
git clone --depth 1 https://github.com/LangeVC/agent-test-env.git /tmp/ate
cp -r /tmp/ate/frameworks/* frameworks/
rm -rf /tmp/ate

# Verify nothing broke
bash tests/run_tests.sh unit
```

## CI

| Workflow | Purpose |
|----------|---------|
| `test.yml` | Framework × capability matrix (agent-test-env base + cap install) |
| `cli-test.yml` | CLI test matrix (Python 3.10/3.11/3.12) against cap binary |
