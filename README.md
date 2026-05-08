# Capacium Test Lab

Cross-framework test environment for the Capacium CLI. Tests `cap` commands across all supported AI coding agents.

Uses **[agent-test-env](https://github.com/LangeVC/agent-test-env)** as the base infrastructure (Docker Compose topology, agent Dockerfiles, lifecycle scripts) and overlays Capacium-specific fixtures, tests, and CI configuration.

## Quick Start

```bash
git clone https://github.com/Capacium/capacium-test-lab.git
cd capacium-test-lab

# Pull agent-test-env base (framework Dockerfiles + lifecycle scripts)
git clone --depth 1 https://github.com/LangeVC/agent-test-env.git /tmp/ate
cp -r /tmp/ate/frameworks/* frameworks/
rm -rf /tmp/ate

# Start a framework and test it
docker compose up -d opencode
docker compose run --rm test-runner opencode test-skill
```

## Architecture

```
capacium-test-lab (overlay)
├── docker-compose.yml       ← Adds test-runner + named volumes on top of agent-test-env
├── Dockerfile.runner        ← Capacium-specific: Python with cap CLI
├── frameworks/              ← Capacium-specific test.sh files (cap install logic)
│   └── */scripts/test.sh    ← Overrides agent-test-env base: calls cap install
├── fixtures/                ← 12 Capacium-branded test capabilities
│   └── fixtures.json        ← Central registry — new fixtures auto-discovered by tests
├── tests/
│   ├── cli/                 ← 127 BATS tests for all cap commands
│   │   └── helpers.bash     ← Shared setup: FIXTURES_DIR, cap_cleanup(), cap_install(), cap_remove()
│   ├── unit/                ← ❌ Provided by agent-test-env base
│   ├── integration/         ← Capacium-specific checks (Dockerfile.runner, etc.)
│   └── smoke/               ← Fixture + volume validation
├── docs/                    ← Complete documentation (HOWTO, fixture guide, CI guide)
└── scripts/
    ├── test-mcp-live.sh     ← Capacium-specific MCP handshake test
    ├── provision.sh         ← Fixture provisioning
    └── ci-entrypoint.sh     ← CI matrix orchestrator
```

## Test Suites

```bash
bash tests/run_tests.sh cli         # Capacium CLI tests (127 tests)
bash tests/run_tests.sh all         # All suites (unit + integration + smoke + cli)
```

| Suite | Tests | Description |
|-------|-------|-------------|
| `tests/cli/` | **127** | `cap` command behavioral tests across all 25 CLI commands |
| `tests/unit/` | 12 | Framework adapter structure checks (from agent-test-env) |
| `tests/integration/` | 8 | Docker Compose, test-runner, fixture validation |
| `tests/smoke/` | 5 | Fixture YAML, server.js, volume checks |

### CLI Test Inventory (127 tests)

| File | Tests | What it covers |
|------|-------|---------------|
| `test_install.bats` | 18 | Install all 8 capability kinds, framework filtering, all flags |
| `test_other_commands.bats` | 40 | remove, init (all kinds), lock, package, runtimes, doctor, config, update, publish, submit |
| `test_signing.bats` | 10 | key generate/list, sign with valid/invalid keys, verify specific/all |
| `test_search.bats` | 23 | All search flags, combined flags, error paths, 0-results |
| `test_info.bats` | 8 | JSON output, owner/name formats, local index, --registry |
| `test_compare.bats` | 9 | JSON output, local index, --registry, edge cases |
| `test_cli_meta.bats` | 7 | --version, --help, no-args, invalid commands |
| `test_e2e.bats` | 4 | End-to-end workflows |
| `test_update_index.bats` | 3 | update-index with --full, --registry |
| `test_browse.bats` | 3 | Smoke tests (TUI can't be fully scripted) |
| **Total** | **127** | |

## Fixture Registry

All test fixtures live under `fixtures/` and are declared in `fixtures.json`:

```json
[
  {"name": "test-skill", "kind": "skill", "version": "1.0.0"},
  {"name": "test-mcp-server", "kind": "mcp-server", "version": "1.0.0"},
  {"name": "test-tool", "kind": "tool", "version": "1.0.0"},
  {"name": "test-prompt", "kind": "prompt", "version": "1.0.0"},
  {"name": "test-template", "kind": "template", "version": "1.0.0"},
  {"name": "test-workflow", "kind": "workflow", "version": "1.0.0"},
  {"name": "test-connector-pack", "kind": "connector-pack", "version": "1.0.0"},
  {"name": "test-runtimes-skill", "kind": "skill", "version": "1.0.0"},
  {"name": "test-broken-manifest", "kind": "skill", "version": "1.0.0"},
  {"name": "test-dependency", "kind": "skill", "version": "1.0.0"},
  {"name": "test-bundle", "kind": "bundle", "version": "1.0.0"},
  {"name": "test-signed-cap", "kind": "skill", "version": "1.0.0"}
]
```

The shared `helpers.bash` auto-discovers fixture names via `python3 -c "import json; ..."`. When you add a new fixture:

1. Create the directory `fixtures/<name>/` with `capability.yaml` and content files
2. Add the entry to `fixtures.json`
3. All tests that use `load '../helpers'` and `cap_cleanup` in setup will automatically clean up before/after

## Test Patterns

All test files follow these conventions:

```bash
#!/usr/bin/env bats

setup() {
    load '../helpers'          # Exports FIXTURES_DIR, TEST_LAB_ROOT, ALL_CAP_KINDS
    CAP="${CAP:-cap}"          # Overrideable via env: CAP=/path/to/dev/cap
    cap_cleanup                # Removes all test capabilities to ensure clean state
}
```

Available helper functions (from `tests/helpers.bash`):

| Function | Purpose |
|----------|---------|
| `cap_cleanup` | Remove all known test capabilities (`ALL_CAP_KINDS`) |
| `cap_install <name> [extra_args]` | Install a capability from fixtures |
| `cap_remove <name>` | Force-remove a capability |

Common assertion patterns:

- **Exit code:** `[ "$status" -eq 0 ]` or `[ "$status" -ne 0 ]`
- **Output match:** `[[ "$output" =~ [Ii]nstalled ]]`
- **Conditional skip:** `[ "$status" -eq 0 ] || skip "reason"`
- **JSON validation:** `echo "$output" | python3 -c "import json,sys; json.load(sys.stdin)"`

## Overlay Pattern

capacium-test-lab is a **project overlay** on [agent-test-env](https://github.com/LangeVC/agent-test-env). The agent-test-env base provides:

- Framework Dockerfiles and lifecycle scripts (`_lib.sh`, `install.sh`, `verify.sh`, `clean.sh`)
- Unit test suites
- Docker Compose network topology

capacium-test-lab overlays:

- `frameworks/*/scripts/test.sh` — calls `cap install` with `--skip-runtime-check` instead of simple symlinks
- `Dockerfile.runner` + `docker-compose.yml` — adds a test-runner service with the `cap` CLI
- `tests/cli/` — full Capacium CLI test suite (127 tests)
- `fixtures/` + `fixtures.json` — 12 Capacium-branded test capabilities, all 8 capability kinds

## CI

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `test.yml` | push/PR to main — frameworks/scripts/Dockerfile changes | Framework × capability matrix (Docker + agent-test-env) |
| `cli-test.yml` | push/PR to main — tests/cli/ fixtures/ helpers changes | CLI tests against cap binary (Python 3.10/3.11/3.12) |

### Running Tests Locally

```bash
# Using a dev cap binary
CAP=/path/to/dev/cap bash tests/run_tests.sh cli

# Using installed cap
bash tests/run_tests.sh cli

# Specific file
CAP=.venv/bin/cap bats tests/cli/test_search.bats
```

### Adding New CLI Functionality

REQUIRED: Every new `cap` CLI command, subcommand, flag, or significant behavior change in `Capacium/capacium` core MUST include corresponding BATS tests.

1. Create or extend `tests/cli/test_*.bats` — use `load '../helpers'` in `setup()`
2. Add new fixtures to `fixtures/` and register in `fixtures.json`
3. Follow existing assertion patterns
4. Test in the same PR/commit as the feature

## Post-Release Verification

After a Capacium release:
```bash
bash tests/run_tests.sh cli
```
Expected: **127/127 CLI tests passing**, exit code 0.

## Documentation

- [HOWTO — Writing Tests](docs/HOWTO.md)
- [Fixture Guide](docs/FIXTURES.md)
- [CI Reference](docs/CI.md)

## License

Apache 2.0 — see [LICENSE](LICENSE)

Part of the [Capacium](https://github.com/Capacium/capacium) ecosystem.
