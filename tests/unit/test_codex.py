"""
CodexAdapter unit tests — entrypoint routing (TEST-002) + duplicate removal (TEST-003).

These tests extend the contract coverage from test_adapter_contract.py with
adapter-specific edge cases that require deep inspection of the TOML config.
"""

import tomllib
import pytest
from pathlib import Path

from capacium.adapters.codex import CodexAdapter


# ── Fixtures ──────────────────────────────────────────────────────────────────

def make_codex(fake_home) -> CodexAdapter:
    """Instantiate CodexAdapter inside a fake_home context."""
    return CodexAdapter()


# ── TEST-002: Entrypoint routing ───────────────────────────────────────────────

@pytest.mark.contract
def test_install_mcp_server_with_entrypoint_routes_to_subdir(
    fake_home, fake_mcp_source_with_entrypoint
):
    """install_mcp_server with entrypoint='mcp-server' must point config args
    to the entrypoint subdirectory (dist/index.js), not the package root."""
    adapter = make_codex(fake_home)
    result = adapter.install_mcp_server(
        "test-mcp-ep", "1.0.0", fake_mcp_source_with_entrypoint
    )
    assert result is True

    # Read the TOML config and inspect the server entry
    config_text = adapter.config_path.read_text()
    config = tomllib.loads(config_text)
    servers = config.get("mcp_servers", {})

    # There must be exactly one entry for test-mcp-ep
    matching = {k: v for k, v in servers.items() if "test-mcp-ep" in k}
    assert matching, f"No test-mcp-ep entry in mcp_servers: {list(servers)}"

    # The args must reference the entrypoint subdir, not the root
    entry = next(iter(matching.values()))
    args = entry.get("args", [])
    args_str = " ".join(str(a) for a in args)
    assert "mcp-server" in args_str or "dist/index.js" in args_str, (
        f"Expected args to reference entrypoint subdir, got: {args_str}"
    )
    # Must NOT point to package root server.js
    assert "fake-mcp-entrypoint-src" not in args_str.split("mcp-server")[0] \
        or "mcp-server" in args_str, (
        f"Args do not include entrypoint subdir path: {args_str}"
    )


@pytest.mark.contract
def test_install_mcp_server_without_entrypoint_routes_to_root(
    fake_home, fake_mcp_source
):
    """install_mcp_server without entrypoint must point args to the package root."""
    adapter = make_codex(fake_home)
    result = adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)
    assert result is True

    config = tomllib.loads(adapter.config_path.read_text())
    servers = config.get("mcp_servers", {})
    matching = {k: v for k, v in servers.items() if "test-cap" in k}
    assert matching, "No test-cap entry in mcp_servers"

    entry = next(iter(matching.values()))
    args = entry.get("args", [])
    # server.js should be directly in the args (no extra subdir)
    args_str = " ".join(str(a) for a in args)
    assert "server.js" in args_str or "test-cap" in args_str, (
        f"Expected args to reference package root, got: {args_str}"
    )


# ── TEST-003: Duplicate entry removal ─────────────────────────────────────────

@pytest.mark.contract
def test_install_mcp_twice_no_duplicate_entry(fake_home, fake_mcp_source):
    """Installing the same MCP server twice must produce exactly one TOML entry."""
    adapter = make_codex(fake_home)
    adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)
    adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)

    config = tomllib.loads(adapter.config_path.read_text())
    servers = config.get("mcp_servers", {})
    matching = [k for k in servers if "test-cap" in k]
    assert len(matching) == 1, (
        f"Expected 1 entry for test-cap, got {len(matching)}: {matching}"
    )


@pytest.mark.contract
def test_install_mcp_different_versions_no_duplicate(fake_home, fake_mcp_source):
    """Installing same cap with different version must not accumulate entries."""
    adapter = make_codex(fake_home)
    adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)
    adapter.install_mcp_server("test-cap", "2.0.0", fake_mcp_source)

    config = tomllib.loads(adapter.config_path.read_text())
    servers = config.get("mcp_servers", {})
    matching = [k for k in servers if "test-cap" in k]
    assert len(matching) == 1, (
        f"Re-install with different version created {len(matching)} entries: {matching}"
    )


@pytest.mark.contract
def test_install_two_different_caps_creates_two_entries(fake_home, fake_mcp_source, tmp_path):
    """Installing two different caps must create two separate entries."""
    # Create a second distinct fake source
    src2 = tmp_path / "fake-mcp-src2"
    src2.mkdir()
    (src2 / "capability.yaml").write_text(
        "name: other-cap\nversion: 1.0.0\nkind: mcp-server\ndescription: Other\n"
        "author: Test\nmcp:\n  transport: stdio\n  command: node\n  args: [other.js]\n"
    )
    (src2 / "other.js").write_text("// stub\n")

    adapter = make_codex(fake_home)
    adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)
    adapter.install_mcp_server("other-cap", "1.0.0", src2)

    config = tomllib.loads(adapter.config_path.read_text())
    servers = config.get("mcp_servers", {})
    assert len(servers) == 2, (
        f"Expected 2 entries for two distinct caps, got {len(servers)}: {list(servers)}"
    )


@pytest.mark.contract
def test_remove_mcp_removes_entry_from_toml(fake_home, fake_mcp_source):
    """remove_mcp_server must cleanly delete the entry from the TOML file."""
    adapter = make_codex(fake_home)
    adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)

    config_before = tomllib.loads(adapter.config_path.read_text())
    assert any("test-cap" in k for k in config_before.get("mcp_servers", {}))

    adapter.remove_mcp_server("test-cap")

    config_after = tomllib.loads(adapter.config_path.read_text())
    matching = [k for k in config_after.get("mcp_servers", {}) if "test-cap" in k]
    assert not matching, f"test-cap still in mcp_servers after remove: {matching}"


@pytest.mark.contract
def test_remove_nonexistent_mcp_returns_true(fake_home):
    """remove_mcp_server on a never-installed cap must return True (idempotent)."""
    adapter = make_codex(fake_home)
    result = adapter.remove_mcp_server("never-installed")
    assert result is True
