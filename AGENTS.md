# Capacium Test Lab — Agents Guide

## Language

English is REQUIRED for ALL Capacium content.

## Architecture

capacium-test-lab is a **project overlay** on [agent-test-env](https://github.com/LangeVC/agent-test-env). The agent-test-env base provides framework Dockerfiles and lifecycle scripts. This repo overlays Capacium-specific test logic.

### What Comes From agent-test-env Base

- Framework Dockerfiles (`frameworks/*/Dockerfile`)
- Lifecycle scripts: `_lib.sh`, `install.sh`, `verify.sh`, `clean.sh`
- Docker Compose network topology (shared bridge, fixture mounts)

### What capacium-test-lab Overlays

| Asset | Description |
|-------|-------------|
| `frameworks/*/scripts/test.sh` | Calls `cap install --skip-runtime-check` instead of simple symlinks |
| `Dockerfile.runner` | Python 3.12 + Node.js 22 LTS + MCP Inspector 0.21.2 |
| `docker-compose.yml` | Adds test-runner service, named volumes for skills |
| `tests/cli/` | BATS tests for all `cap` commands |
| `tests/unit/` | pytest adapter contract tests (see below) |
| `fixtures/` | Capacium-branded test capabilities (skill, mcp-server, bundle, tool, etc.) |
| `fixtures.json` | Central fixture registry — auto-discovered by tests |
| `scripts/probe_mcp_server.sh` | MCP Inspector CLI wrapper for E2E server verification |
| `scripts/test-mcp-live.sh` | Direct MCP JSON-RPC handshake test |
| `scripts/ci-entrypoint.sh` | CI matrix orchestrator |

## Quick Start

```bash
git clone https://github.com/Capacium/capacium-test-lab.git
cd capacium-test-lab

# Pull agent-test-env base
git clone --depth 1 https://github.com/LangeVC/agent-test-env.git /tmp/ate
cp -r /tmp/ate/frameworks/* frameworks/
rm -rf /tmp/ate

# Install capacium for unit tests
pip install -e /path/to/capacium

# Run unit tests (no Docker needed)
pytest tests/unit/ -v

# Test a framework (Docker)
docker compose up -d opencode
docker compose run --rm test-runner opencode test-skill
```

## Test Suites

| Suite | Path | Framework | Purpose |
|-------|------|-----------|---------|
| **unit** | `tests/unit/` | pytest | Adapter contract tests — isolated with fake_home |
| **cli** | `tests/cli/` | BATS | `cap` command functional tests |
| **integration** | `tests/integration/` | BATS | Docker Compose + test-runner validation |
| **smoke** | `tests/smoke/` | BATS | Fixture YAML + volume validation |

---

## Unit Tests (pytest + tmp_path)

### Design

All unit tests run **without Docker** against the real capacium adapter Python code. Each test uses an isolated fake home directory — no real `~/.config`, `~/Library`, or `~/.capacium` paths are ever touched.

### fake_home Fixture

```python
@pytest.fixture
def fake_home(tmp_path, monkeypatch):
    home = tmp_path / "home"
    home.mkdir()
    monkeypatch.setenv("HOME", str(home))    # for os.path.expanduser
    monkeypatch.chdir(home)                  # for CursorAdapter (Path.cwd())
    with patch.object(Path, "home", return_value=home):
        yield home
```

**Why two patches?** macOS `Path.home()` uses `pwd.getpwuid()` which ignores `HOME` env var. The `patch.object` ensures all code paths land in the tmp dir. The `chdir(home)` handles CursorAdapter which uses `Path.cwd() / ".cursor"` instead of `Path.home()`.

### Adapter Contract Tests

`tests/unit/test_adapter_contract.py` defines 8 contract tests parametrized over **all 25 adapters**:

| # | Test | What it verifies |
|---|------|-----------------|
| 1 | `test_install_mcp_server_returns_true` | `install_mcp_server` returns `True` |
| 2 | `test_capability_exists_after_install_mcp` | `capability_exists` returns `True` after install |
| 3 | `test_remove_mcp_server_clears_entry` | `remove_mcp_server` removes config entry |
| 4 | `test_install_mcp_server_idempotent` | No duplicate config entries on second install |
| 5 | `test_install_creates_config_if_missing` | Creates config file if not present |
| 6 | `test_remove_mcp_from_missing_config_is_idempotent` | `remove_mcp_server` never crashes |
| 7 | `test_install_skill_contract` | Skills return `True`; MCP-only adapters return `False` |
| 8 | `test_remove_skill_idempotent` | `remove_skill` never raises an exception |

**Sprint 1 adapters (5):** `ClaudeDesktopAdapter`, `CodexAdapter`, `OpenCodeAdapter`, `CursorAdapter`, `GeminiCLIAdapter`

**Sprint 2 adapters (20):** `ClaudeCodeAdapter`, `ContinueDevAdapter`, `RooCodeAdapter`, `WindsurfAdapter`, `ZedAdapter`, `QwenAdapter`, `AiderAdapter`, `AntigravityAdapter`, `ChainlitAdapter`, `CherryStudioAdapter`, `ClineAdapter`, `CopilotAdapter`, `DesktopCommanderAdapter`, `GooseAdapter`, `HermesAdapter`, `JunieAdapter`, `LibreChatAdapter`, `NextChatAdapter`, `OpenClawAdapter`, `SourcegraphCodyAdapter`

### Adding a New Adapter Test

1. Add the adapter to `ADAPTERS` list in `test_adapter_contract.py`:
   ```python
   ("my_adapter", "MyAdapter", True),  # True = supports install_skill
   ```
2. Run `pytest tests/unit/test_adapter_contract.py -k MyAdapter -v` to verify all 8 contracts pass
3. If `capability_exists` only checks skill symlinks (not MCP config), add the MCP config check — see `GeminiCLIAdapter` fix as the reference pattern

### Running Unit Tests

```bash
# All unit tests
pytest tests/unit/ -v

# Contract tests only (all 25 adapters)
pytest tests/unit/test_adapter_contract.py -v

# Specific adapter
pytest tests/unit/test_adapter_contract.py -k "CodexAdapter" -v

# Duplicate removal tests
pytest tests/unit/ -k "duplicate" -v

# Entrypoint routing tests
pytest tests/unit/ -k "entrypoint" -v
```

---

## MCP E2E Tests

### Architecture: Two-Speed Testing

| Speed | File | When | Scope |
|-------|------|------|-------|
| **Smoke** | `test_mcp_e2e_smoke.bats` | Every PR | install → probe → remove in 3 frameworks |
| **Deep** | `test_mcp_e2e_deep.bats` | Nightly | tools/call, timeout, all 6 frameworks |

### probe_mcp_server.sh

`scripts/probe_mcp_server.sh` wraps MCP Inspector CLI for headless E2E verification:

```bash
# Probe a running MCP server (Node.js server)
bash scripts/probe_mcp_server.sh node fixtures/test-mcp-stub/server.js

# Probe with custom timeout
PROBE_TIMEOUT=60000 bash scripts/probe_mcp_server.sh python my_server.py

# Verbose output
PROBE_VERBOSE=1 bash scripts/probe_mcp_server.sh node server.js
```

**Requirements:** Node.js 22.7.5+ (MCP Inspector 0.21.2 minimum). The `Dockerfile.runner` installs Node.js 22 LTS automatically.

### test-mcp-stub Fixture

`fixtures/test-mcp-stub/server.js` is a zero-dependency Node.js MCP stub:
- Handles `initialize`, `notifications/initialized`, `tools/list`, `tools/call`
- Returns `cap_test` tool from `tools/list`
- Handles `SIGTERM`, `SIGHUP`, and stdin EOF cleanly

Test it manually:
```bash
echo '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
  | timeout 5 node fixtures/test-mcp-stub/server.js
```

---

## Conflict and Idempotency Tests

`tests/cli/test_conflict.bats` covers cross-framework conflict scenarios:

| Test | Scenario |
|------|----------|
| 1 | Double install → exactly 1 config entry (no duplicates) |
| 2 | `--force` on already-installed → reinstalls cleanly |
| 3 | Non-interactive without `--force` → exits 0, prints hint |
| 4 | Remove + reinstall cycle → clean state |
| 5 | Install skill + mcp-server → remove one → other unaffected |

---

## Bundle Kind Tests

`tests/cli/test_bundle.bats` covers the `bundle` capability kind:
- `test-bundle` fixture contains: `sub-skill` + `sub-mcp-server` + `sub-tool`
- Tests: install, list, idempotency, remove, clean state

---

## CLI Test Suite

BATS tests in `tests/cli/` cover all `cap` commands. Key files:

| File | Tests | Coverage |
|------|-------|----------|
| `test_install.bats` | 18 | Install from all kinds, all flags |
| `test_signing.bats` | 10 | `cap key`, `cap sign`, `cap verify` |
| `test_other_commands.bats` | 40 | `cap remove`, `cap init`, `cap lock`, `cap package`, etc. |
| `test_search.bats` | 23 | All search flags |
| `test_info.bats` | 8 | `cap info` |
| `test_compare.bats` | 9 | `cap compare` |
| `test_init_compare_info.bats` | 13 | `cap init` (all kinds), `cap compare` bundle, `cap info` bundle |
| `test_conflict.bats` | 5 | Conflict + idempotency |
| `test_bundle.bats` | 7 | Bundle kind install/remove |
| `test_mcp_e2e_smoke.bats` | 5 | MCP E2E smoke (PR) |
| `test_cli_meta.bats` | 7 | `--version`, `--help`, error paths |

### Test Patterns

- **Shared helpers:** All tests `load '../helpers'` — exports `FIXTURES_DIR`, `cap_cleanup()`, `cap_install()`, `cap_remove()`
- **Auto-cleanup:** `cap_cleanup()` in every `setup()` ensures no residual installs
- **JSON validation:** `echo "$output" | python3 -c "import json,sys; json.load(sys.stdin)"`
- **Graceful skip:** `skip "reason"` when runtime unavailable

### Fixture Registry (`fixtures.json`)

All test fixtures are declared in `fixtures.json`. When adding new fixtures:
1. Create `fixtures/<name>/` with `capability.yaml` and content files
2. Add `{"name": "test-<name>", "kind": "<kind>", "version": "1.0.0"}` to `fixtures.json`
3. Tests auto-discover — `cap_cleanup()` iterates `ALL_CAP_KINDS`

---

## Adding New `cap` Functionality

Every new CLI command, flag, or significant behavior change MUST include corresponding tests.

**For CLI changes:** Add BATS tests to `tests/cli/test_*.bats`

**For new adapters:**
1. Add to `ADAPTERS` list in `tests/unit/test_adapter_contract.py`
2. Run `pytest tests/unit/test_adapter_contract.py -k NewAdapter` — all 8 contracts must pass
3. Check `capability_exists` covers both skill symlinks AND MCP config lookup

---

## CI Workflows

| Workflow | Runner | Purpose |
|----------|--------|---------|
| `test.yml` | `ubuntu-latest` | Framework × capability Docker matrix + pytest unit tests |
| `ci-macos.yml` | `macos-latest` | macOS adapter unit tests (Darwin config paths) + Homebrew cap smoke |
| `cli-test.yml` | `ubuntu-latest` | CLI test matrix (Python 3.10/3.11/3.12) |

---

## Gotchas and Known Patterns

- **macOS `Path.home()` bypass:** `Path.home()` on macOS uses `pwd.getpwuid()`, ignoring `HOME` env var. Always use `patch.object(Path, "home", ...)` in tests, not just `monkeypatch.setenv("HOME", ...)`.
- **TOML parsing:** Python 3.11+ has `tomllib` (stdlib). Python 3.10 needs `tomli`. Use `try: import tomllib except ImportError: import tomli as tomllib`.
- **MCP Inspector version:** Pin to `@modelcontextprotocol/inspector@0.21.2`. Requires Node.js ≥ 22.7.5. The inspector runs headless via `--cli` flag.
- **CursorAdapter uses `Path.cwd()`:** `_skills_dir` and `project_mcp_path` use `cwd()`, not `home()`. The `fake_home` fixture calls `monkeypatch.chdir(home)` to isolate this.
- **capability_exists must check both:** Adapters supporting both skill and MCP kinds must check BOTH the skill symlink AND the MCP config entry. See `CodexAdapter.capability_exists` as the reference implementation.
- **import-mode=importlib:** pytest is configured with `--import-mode=importlib` to avoid `conftest` module name collisions. Never use `from conftest import ...` in test files — conftest fixtures are available automatically.
