# Capacium Test Lab

Cross-framework test environment for the Capacium CLI. Tests `cap` commands across all supported AI coding agents using a four-layer test architecture.

Uses **[agent-test-env](https://github.com/LangeVC/agent-test-env)** as the base infrastructure (Docker Compose topology, agent Dockerfiles, lifecycle scripts) and overlays Capacium-specific fixtures, tests, and CI configuration.

[![Linux CI](https://github.com/Capacium/capacium-test-lab/actions/workflows/test.yml/badge.svg)](https://github.com/Capacium/capacium-test-lab/actions/workflows/test.yml)
[![macOS CI](https://github.com/Capacium/capacium-test-lab/actions/workflows/ci-macos.yml/badge.svg)](https://github.com/Capacium/capacium-test-lab/actions/workflows/ci-macos.yml)

## Quick Start

```bash
git clone https://github.com/Capacium/capacium-test-lab.git
cd capacium-test-lab

# Pull agent-test-env base (framework Dockerfiles + lifecycle scripts)
git clone --depth 1 https://github.com/LangeVC/agent-test-env.git /tmp/ate
cp -r /tmp/ate/frameworks/* frameworks/
rm -rf /tmp/ate

# Unit tests (no Docker needed)
pip install -e /path/to/capacium
pytest tests/unit/ -v

# Framework integration tests (Docker)
docker compose up -d opencode
docker compose run --rm test-runner opencode test-skill
```

## Architecture

```
capacium-test-lab (overlay)
├── docker-compose.yml       ← test-runner + named volumes
├── Dockerfile.runner        ← Python 3.12 + Node.js 22 LTS + cap CLI
├── frameworks/              ← test.sh files (cap install logic)
├── fixtures/                ← 13 Capacium test capabilities (skill, mcp-server, bundle, …)
│   └── fixtures.json        ← Central registry — auto-discovered by tests
├── tests/
│   ├── unit/                ← pytest adapter contract tests (223 tests, no Docker)
│   │   ├── conftest.py      ← fake_home fixture (monkeypatches Path.home + HOME + cwd)
│   │   ├── test_adapter_contract.py  ← 8 contracts × 25 adapters
│   │   ├── test_codex.py             ← Codex edge cases
│   │   ├── test_opencode.py          ← OpenCode edge cases
│   │   └── test_claude_desktop.py    ← ClaudeDesktop MCP-only tests
│   ├── cli/                 ← BATS functional tests for all cap commands
│   │   └── helpers.bash     ← FIXTURES_DIR, cap_cleanup(), cap_install(), cap_remove()
│   ├── integration/         ← Docker Compose + test-runner validation
│   └── smoke/               ← Fixture YAML + volume checks
├── scripts/
│   ├── probe_mcp_server.sh  ← MCP Inspector CLI wrapper (E2E verification)
│   ├── test-mcp-live.sh     ← Direct MCP JSON-RPC handshake test
│   └── ci-entrypoint.sh     ← CI matrix orchestrator
└── .github/workflows/
    ├── test.yml             ← Linux: pytest unit tests + Docker framework matrix
    └── ci-macos.yml         ← macOS: pytest unit tests + Homebrew cap smoke
```

## Test Layers

### What "tested" means per capability kind

| Kind | Unit Test | CLI/BATS Test | MCP E2E |
|------|-----------|---------------|---------|
| `skill` | Symlink in fake skills dir | Install → symlink in Docker container | n/a |
| `mcp-server` | Config entry in fake config file | Install → config entry + probe smoke | tools/list returns ≥1 tool |
| `bundle` | Sub-capabilities installed | Install/remove all sub-caps | n/a |

### Client Priority Tiers

| Tier | Clients | Test Method |
|------|---------|-------------|
| **Tier 1 — Docker** | opencode, claude-code, codex-cli, gemini-cli, continue, cursor | Full Docker container + BATS |
| **Tier 2 — Config file** | claude-desktop, roo-code, windsurf, zed, qwen, + 15 more | pytest unit tests (config file inspection) |

### Layer 1 — Adapter Unit Tests (pytest)

**223 tests, runs in ~1s, no Docker, no network.**

All 25 adapters covered by `tests/unit/test_adapter_contract.py`:

```bash
pytest tests/unit/ -v               # All 223 tests
pytest tests/unit/ -k "duplicate"   # Duplicate removal tests
pytest tests/unit/ -k "entrypoint"  # Entrypoint routing tests
```

8 contract properties verified per adapter:

1. `install_mcp_server` returns `True` and creates a config entry
2. `capability_exists` returns `True` after install
3. `remove_mcp_server` clears the entry; `capability_exists` returns `False`
4. `install_mcp_server` is idempotent (no duplicate config entry)
5. `install_mcp_server` creates config file if it doesn't exist
6. `remove_mcp_server` on a non-installed cap returns `True`
7. `install_skill` returns `True` for skill-supporting adapters, `False` for MCP-only
8. `remove_skill` never raises an exception

### Layer 2 — Bundle BATS Tests

```bash
bats tests/cli/test_bundle.bats
```

7 tests covering the `bundle` kind: install, list, idempotency, remove, clean state.

### Layer 3 — MCP E2E Smoke Tests

```bash
FRAMEWORK=opencode bats tests/cli/test_mcp_e2e_smoke.bats
```

5 tests per framework: install → probe → verify tools/list → remove → reinstall.
Uses `scripts/probe_mcp_server.sh` (MCP Inspector CLI 0.21.2, requires Node.js 22).

### Layer 4 — macOS CI Runner

`.github/workflows/ci-macos.yml` runs on `macos-latest` to validate:
- `ClaudeDesktopAdapter` uses `~/Library/Application Support/Claude/` (Darwin path)
- `cap` CLI installs via Homebrew tap
- All 25 adapter unit tests pass with macOS-native `Path.home()`

## CLI Test Suite

| File | Tests | Coverage |
|------|-------|----------|
| `test_install.bats` | 18 | Install all kinds, all flags |
| `test_other_commands.bats` | 40 | remove, init, lock, package, runtimes, doctor, config, update, publish |
| `test_signing.bats` | 10 | key generate/list, sign, verify |
| `test_search.bats` | 23 | All search flags + combinations |
| `test_info.bats` | 8 | JSON output, formats, --registry |
| `test_compare.bats` | 9 | JSON, local index, edge cases |
| `test_init_compare_info.bats` | 13 | init all kinds, compare bundle, info bundle |
| `test_conflict.bats` | 5 | Double install, --force, non-interactive, remove+reinstall |
| `test_bundle.bats` | 7 | Bundle kind end-to-end |
| `test_mcp_e2e_smoke.bats` | 5 | MCP E2E smoke (install → probe → remove) |
| `test_cli_meta.bats` | 7 | --version, --help, error paths |
| `test_e2e.bats` | 4 | End-to-end workflows |

## Fixture Registry

All test fixtures live under `fixtures/` and are declared in `fixtures.json`:

```json
[
  {"name": "test-skill",       "kind": "skill",      "version": "1.0.0"},
  {"name": "test-mcp-server",  "kind": "mcp-server", "version": "1.0.0"},
  {"name": "test-mcp-stub",    "kind": "mcp-server", "version": "1.0.0"},
  {"name": "test-bundle",      "kind": "bundle",     "version": "1.0.0"},
  {"name": "test-tool",        "kind": "tool",       "version": "1.0.0"},
  {"name": "test-prompt",      "kind": "prompt",     "version": "1.0.0"},
  {"name": "test-template",    "kind": "template",   "version": "1.0.0"},
  {"name": "test-workflow",    "kind": "workflow",   "version": "1.0.0"},
  …
]
```

Adding a new fixture: create `fixtures/<name>/capability.yaml`, add to `fixtures.json`, done — tests auto-discover via `helpers.bash`.

## CI

| Workflow | Runner | Purpose |
|----------|--------|---------|
| `test.yml` | `ubuntu-latest` | pytest unit tests + Docker framework × capability matrix |
| `ci-macos.yml` | `macos-latest` | pytest unit tests (Darwin paths) + Homebrew cap smoke |
| `cli-test.yml` | `ubuntu-latest` | CLI tests against cap binary (Python 3.10/3.11/3.12) |

```bash
# Run unit tests locally (no Docker)
pytest tests/unit/ -v --tb=short

# Run a specific framework
docker compose up -d opencode && docker compose run --rm test-runner opencode test-skill

# MCP E2E smoke (needs Node.js 22)
FRAMEWORK=opencode bats tests/cli/test_mcp_e2e_smoke.bats
```

## Adding New Adapter Support

1. Add `("module_name", "ClassName", supports_skill)` to `ADAPTERS` in `test_adapter_contract.py`
2. Run `pytest tests/unit/test_adapter_contract.py -k ClassName -v` — all 8 contracts must pass
3. If `capability_exists` fails: add MCP config lookup (see `GeminiCLIAdapter` as reference)
4. Submit fixes to `Capacium/capacium` alongside test additions

## Post-Release Verification

```bash
pytest tests/unit/ -v && echo "Unit: OK"
bats tests/cli/test_install.bats && echo "Install: OK"
```

## Documentation

- [AGENTS.md](AGENTS.md) — Full test patterns, gotchas, and fixture guide
- [docs/HOWTO.md](docs/HOWTO.md) — Writing tests
- [docs/FIXTURES.md](docs/FIXTURES.md) — Fixture reference

## License

Apache 2.0 — see [LICENSE](LICENSE)

Part of the [Capacium](https://github.com/Capacium/capacium) ecosystem.
