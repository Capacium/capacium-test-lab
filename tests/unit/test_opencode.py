"""
OpenCodeAdapter unit tests — entrypoint routing (TEST-002) + duplicate removal (TEST-003).

OpenCode uses JSON config at ~/.config/opencode/opencode.json under the "mcp" key.
"""

import json
import pytest
from pathlib import Path

from capacium.adapters.opencode import OpenCodeAdapter


# ── Helpers ───────────────────────────────────────────────────────────────────

def make_opencode(fake_home) -> OpenCodeAdapter:
    return OpenCodeAdapter()


def _read_mcp_config(fake_home) -> dict:
    config_path = fake_home / ".config" / "opencode" / "opencode.json"
    if not config_path.exists():
        return {}
    return json.loads(config_path.read_text())


# ── TEST-002: Entrypoint routing ───────────────────────────────────────────────

@pytest.mark.contract
def test_install_mcp_server_with_entrypoint_routes_to_subdir(
    fake_home, fake_mcp_source_with_entrypoint
):
    """install_mcp_server with entrypoint='mcp-server' must point config args
    to the entrypoint subdirectory, not the package root."""
    adapter = make_opencode(fake_home)
    result = adapter.install_mcp_server(
        "test-mcp-ep", "1.0.0", fake_mcp_source_with_entrypoint
    )
    assert result is True

    config = _read_mcp_config(fake_home)
    servers = config.get("mcp", {})

    matching = {k: v for k, v in servers.items() if "test-mcp-ep" in k}
    assert matching, f"No test-mcp-ep in mcp section. Keys: {list(servers)}"

    entry = next(iter(matching.values()))
    # OpenCode stores command as a list: ["node", "/path/to/script"]
    # or as separate command + args depending on version
    cmd_parts = entry.get("command", [])
    if isinstance(cmd_parts, list):
        cmd_str = " ".join(str(p) for p in cmd_parts)
    else:
        cmd_str = str(cmd_parts) + " " + " ".join(str(a) for a in entry.get("args", []))
    # Must reference the entrypoint subdir (mcp-server/dist/index.js)
    assert "mcp-server" in cmd_str or "dist/index.js" in cmd_str, (
        f"Expected command to reference entrypoint subdir, got: {cmd_str}\nFull entry: {entry}"
    )


@pytest.mark.contract
def test_install_mcp_server_without_entrypoint_routes_to_root(
    fake_home, fake_mcp_source
):
    """install_mcp_server without entrypoint must use the package root path."""
    adapter = make_opencode(fake_home)
    result = adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)
    assert result is True

    config = _read_mcp_config(fake_home)
    servers = config.get("mcp", {})
    assert any("test-cap" in k for k in servers), (
        f"No test-cap in mcp section: {list(servers)}"
    )


# ── TEST-003: Duplicate entry removal ─────────────────────────────────────────

@pytest.mark.contract
def test_install_mcp_twice_no_duplicate_entry(fake_home, fake_mcp_source):
    """Installing the same MCP server twice must not create duplicate JSON entries."""
    adapter = make_opencode(fake_home)
    adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)
    adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)

    config = _read_mcp_config(fake_home)
    servers = config.get("mcp", {})
    matching = [k for k in servers if "test-cap" in k]
    assert len(matching) == 1, (
        f"Expected 1 entry for test-cap, got {len(matching)}: {matching}"
    )


@pytest.mark.contract
def test_install_mcp_no_legacy_mcpservers_pollution(fake_home, fake_mcp_source):
    """After install, the legacy 'mcpServers' key must not contain a duplicate entry."""
    adapter = make_opencode(fake_home)
    adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)

    config = _read_mcp_config(fake_home)
    legacy = config.get("mcpServers", {})
    matching = [k for k in legacy if "test-cap" in k]
    assert not matching, (
        f"test-cap appeared in legacy mcpServers: {matching}"
    )


@pytest.mark.contract
def test_install_two_different_caps_creates_two_entries(
    fake_home, fake_mcp_source, tmp_path
):
    """Two distinct caps must each get their own entry in 'mcp'."""
    src2 = tmp_path / "fake-mcp-src2"
    src2.mkdir()
    (src2 / "capability.yaml").write_text(
        "name: other-cap\nversion: 1.0.0\nkind: mcp-server\ndescription: Other\n"
        "author: Test\nmcp:\n  transport: stdio\n  command: python\n  args: [server.py]\n"
    )
    (src2 / "server.py").write_text("# stub\n")

    adapter = make_opencode(fake_home)
    adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)
    adapter.install_mcp_server("other-cap", "1.0.0", src2)

    config = _read_mcp_config(fake_home)
    servers = config.get("mcp", {})
    assert len(servers) >= 2, (
        f"Expected ≥2 entries for two distinct caps, got {len(servers)}: {list(servers)}"
    )


@pytest.mark.contract
def test_remove_mcp_cleans_json_entry(fake_home, fake_mcp_source):
    """remove_mcp_server must remove the entry from the JSON config."""
    adapter = make_opencode(fake_home)
    adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)

    config_before = _read_mcp_config(fake_home)
    assert any("test-cap" in k for k in config_before.get("mcp", {}))

    adapter.remove_mcp_server("test-cap")

    config_after = _read_mcp_config(fake_home)
    servers = config_after.get("mcp", {})
    matching = [k for k in servers if "test-cap" in k]
    assert not matching, f"test-cap still present after remove: {matching}"
