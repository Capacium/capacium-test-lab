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
├── fixtures/                ← Capacium-branded test capabilities
├── tests/cli/               ← 68 CLI tests for all cap commands (BATS)
│   tests/unit/              ← ❌ Provided by agent-test-env base
│   tests/integration/       ← Capacium-specific checks (Dockerfile.runner, etc.)
│   tests/smoke/             ← Fixture + volume validation
└── scripts/
    ├── test-framework.sh    ← Adapted from base with Capacium branding
    ├── test-mcp-live.sh     ← Capacium-specific MCP handshake test
    ├── provision.sh         ← Fixture provisioning
    └── ci-entrypoint.sh     ← CI matrix orchestrator
```

## Test Suites

```bash
bash tests/run_tests.sh cli         # Capacium CLI tests (~68 tests)
bash tests/run_tests.sh all         # All suites
```

| Suite | Tests | Description |
|-------|-------|-------------|
| `tests/cli/` | 68 | `cap` command tests (install, search, browse, info, compare, etc.) |
| `tests/unit/` | 12 | Framework adapter structure checks (from agent-test-env) |
| `tests/integration/` | 8 | Docker Compose, test-runner, fixture validation |
| `tests/smoke/` | 5 | Fixture YAML, server.js, volume checks |

## Overlay Pattern

capacium-test-lab is a **project overlay** on [agent-test-env](https://github.com/LangeVC/agent-test-env). The agent-test-env base provides:

- Framework Dockerfiles and lifecycle scripts (`_lib.sh`, `install.sh`, `verify.sh`, `clean.sh`)
- Unit test suites
- Docker Compose network topology

capacium-test-lab overlays:

- `frameworks/*/scripts/test.sh` — calls `cap install` with `--skip-runtime-check` instead of simple symlinks
- `Dockerfile.runner` + `docker-compose.yml` — adds a test-runner service with the `cap` CLI
- `tests/cli/` — full Capacium CLI test suite
- Capacium-branded fixtures

## CI

Two workflows:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `test.yml` | push/PR to main | Framework × capability matrix (agent-test-env + cap install) |
| `cli-test.yml` | push/PR to main | CLI tests against cap binary (Python 3.10/3.11/3.12) |

## Post-Release Verification

After a Capacium release:
```bash
bash tests/run_tests.sh cli
```
Expected: **63+/68 CLI tests passing**.

## Adding Tests

Every new `cap` CLI feature requires corresponding BATS tests in `tests/cli/`. Follow the patterns in the existing test files:

- `${CAP}` env var for the cap binary (defaults to `cap`)
- `run "$CAP" <command>` for assertions
- `python3 -c "import json,sys; json.load(sys.stdin)"` for JSON validation

## License

Apache 2.0 — see [LICENSE](LICENSE)

Part of the [Capacium](https://github.com/Capacium/capacium) ecosystem. Uses [agent-test-env](https://github.com/LangeVC/agent-test-env) as base infrastructure.
