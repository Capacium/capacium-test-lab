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
| `tests/cli/` | 68 BATS tests for all `cap` commands |
| `tests/integration/` | Capacium-specific checks (test-runner, verify scripts) |
| `tests/smoke/` | Fixture YAML + volume validation |
| `fixtures/` | Capacium-branded test capabilities |
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

### CLI Test Suite

Functional tests against the `cap` binary. Covers:

- `test_cli_meta.bats` — `--version`, `--help`, no-args, invalid commands, required arg validation
- `test_search.bats` — All `--kind`, `--trust`, `--category`, `--sort`, `--json`, `--limit`, `--framework`, `--tag` flags
- `test_info.bats` — `cap info <name>` with `--json`, owner/name and bare name formats
- `test_compare.bats` — `cap compare <a> <b>` with `--json`, schema field
- `test_update_index.bats` — `cap update-index` with `--full`, `--registry`
- `test_browse.bats` — `cap browse` smoke tests (TUI can't be fully scripted)
- `test_other_commands.bats` — `cap list`, `cap doctor`, `cap runtimes`, `cap verify`, `cap lock`, `cap package`, `cap publish`, `cap marketplace`, `cap config`, `cap init`, `cap registry`, `cap mcp`, `cap submit`
- `test_e2e.bats` — End-to-end workflows: local index validation, JSON structure, info→compare chain

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

- **Help output:** `run "$CAP" <cmd> --help` → `[ "$status" -eq 0 ]` + grep for expected flags
- **Missing args:** `run "$CAP" <cmd>` → `[ "$status" -ne 0 ]`
- **JSON validation:** `echo "$output" | python3 -c "import json,sys; json.load(sys.stdin)"`
- **Schema check:** `'$schema' in d` and `d['$schema'].startswith('https://')`
- **Graceful skip:** `skip "Exchange not reachable"` when remote API unavailable

## Adding New `cap` Functionality

REQUIRED: Every new CLI command, subcommand, flag, or significant behavior change in `Capacium/capacium` core MUST include corresponding BATS tests in `tests/cli/`.

1. Create or extend `tests/cli/test_*.bats`
2. Follow existing patterns
3. Add test in the same PR/commit as the feature

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
