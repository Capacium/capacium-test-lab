"""
ClaudeDesktopAdapter unit tests — skill install + MCP config duplicate removal (TEST-003).

Claude Desktop exposes skills via the capacium-skills MCP wrapper:
  install_skill() → copies files to package cache + registers 'capacium-skills' MCP entry
Config: ~/Library/Application Support/Claude/claude_desktop_config.json (macOS)
        ~/.config/Claude/claude_desktop_config.json (Linux)
"""

import json
import platform
import pytest
from pathlib import Path

from capacium.adapters.claude_desktop import ClaudeDesktopAdapter


# ── Helpers ───────────────────────────────────────────────────────────────────

def make_claude_desktop(fake_home) -> ClaudeDesktopAdapter:
    return ClaudeDesktopAdapter()


def _config_path(fake_home) -> Path:
    system = platform.system()
    if system == "Darwin":
        return fake_home / "Library" / "Application Support" / "Claude" / "claude_desktop_config.json"
    elif system == "Windows":
        return fake_home / "AppData" / "Roaming" / "Claude" / "claude_desktop_config.json"
    else:
        return fake_home / ".config" / "Claude" / "claude_desktop_config.json"


def _read_config(fake_home) -> dict:
    cp = _config_path(fake_home)
    if not cp.exists():
        return {}
    return json.loads(cp.read_text())


# ── Contract: install_skill via capacium-skills MCP wrapper (P1-001) ─────────

@pytest.mark.contract
def test_install_skill_returns_true(fake_home, fake_skill_source):
    """install_skill must return True — skills are exposed via capacium-skills MCP wrapper."""
    adapter = make_claude_desktop(fake_home)
    result = adapter.install_skill("test-skill", "1.0.0", fake_skill_source)
    assert result is True, f"Expected True, got {result!r}"


@pytest.mark.contract
def test_install_skill_registers_capacium_skills_mcp_entry(fake_home, fake_skill_source):
    """install_skill must add 'capacium-skills' to mcpServers in claude_desktop_config.json."""
    adapter = make_claude_desktop(fake_home)
    adapter.install_skill("test-skill", "1.0.0", fake_skill_source)

    config = _read_config(fake_home)
    mcp_servers = config.get("mcpServers", {})
    assert "capacium-skills" in mcp_servers, (
        f"Expected 'capacium-skills' in mcpServers, got: {list(mcp_servers)}"
    )
    entry = mcp_servers["capacium-skills"]
    args = entry.get("args", [])
    assert "--cap-home" in args, f"Expected '--cap-home' in args, got {args}"


@pytest.mark.contract
def test_install_skill_capacium_skills_entry_is_idempotent(fake_home, fake_skill_source):
    """Calling install_skill twice must not duplicate the 'capacium-skills' MCP entry."""
    adapter = make_claude_desktop(fake_home)
    adapter.install_skill("test-skill", "1.0.0", fake_skill_source)
    adapter.install_skill("test-skill2", "1.0.0", fake_skill_source)

    config = _read_config(fake_home)
    mcp_servers = config.get("mcpServers", {})
    matching = [k for k in mcp_servers if k == "capacium-skills"]
    assert len(matching) == 1, f"Expected exactly 1 'capacium-skills' entry, got {len(matching)}"


@pytest.mark.contract
def test_remove_skill_does_not_raise(fake_home):
    """remove_skill must not raise an exception."""
    adapter = make_claude_desktop(fake_home)
    result = adapter.remove_skill("nonexistent")
    assert result is True


# ── TEST-003: Duplicate entry removal ─────────────────────────────────────────

@pytest.mark.contract
def test_install_mcp_twice_no_duplicate_entry(fake_home, fake_mcp_source):
    """Installing the same MCP server twice must produce exactly one mcpServers entry."""
    adapter = make_claude_desktop(fake_home)
    adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)
    adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)

    config = _read_config(fake_home)
    servers = config.get("mcpServers", {})
    matching = [k for k in servers if "test-cap" in k]
    assert len(matching) == 1, (
        f"Expected 1 entry for test-cap, got {len(matching)}: {matching}"
    )


@pytest.mark.contract
def test_install_mcp_creates_config_dir(fake_home, fake_mcp_source):
    """install_mcp_server must create the config directory if it doesn't exist."""
    adapter = make_claude_desktop(fake_home)
    cp = _config_path(fake_home)
    assert not cp.exists(), f"Config already exists at {cp}"

    adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)
    assert cp.exists(), f"Config not created at {cp}"


@pytest.mark.contract
def test_install_mcp_config_is_valid_json(fake_home, fake_mcp_source):
    """The config written by install_mcp_server must be valid JSON."""
    adapter = make_claude_desktop(fake_home)
    adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)

    cp = _config_path(fake_home)
    text = cp.read_text()
    try:
        json.loads(text)
    except json.JSONDecodeError as e:
        pytest.fail(f"Config is not valid JSON after install: {e}\nContent:\n{text}")


@pytest.mark.contract
def test_capability_exists_after_install(fake_home, fake_mcp_source):
    """capability_exists returns True after install_mcp_server."""
    adapter = make_claude_desktop(fake_home)
    adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)
    assert adapter.capability_exists("test-cap")


@pytest.mark.contract
def test_capability_exists_false_after_remove(fake_home, fake_mcp_source):
    """capability_exists returns False after remove_mcp_server."""
    adapter = make_claude_desktop(fake_home)
    adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)
    adapter.remove_mcp_server("test-cap")
    assert not adapter.capability_exists("test-cap")


@pytest.mark.contract
def test_remove_nonexistent_mcp_returns_true(fake_home):
    """remove_mcp_server on a non-installed cap must return True."""
    adapter = make_claude_desktop(fake_home)
    result = adapter.remove_mcp_server("nonexistent-cap")
    assert result is True


@pytest.mark.contract
def test_install_two_distinct_caps(fake_home, fake_mcp_source, tmp_path):
    """Two distinct MCP servers must each appear in mcpServers."""
    src2 = tmp_path / "fake-mcp2"
    src2.mkdir()
    (src2 / "capability.yaml").write_text(
        "name: other-cap\nversion: 1.0.0\nkind: mcp-server\ndescription: Other\n"
        "author: Test\nmcp:\n  transport: stdio\n  command: python\n  args: [server.py]\n"
    )
    (src2 / "server.py").write_text("# stub\n")

    adapter = make_claude_desktop(fake_home)
    adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)
    adapter.install_mcp_server("other-cap", "1.0.0", src2)

    config = _read_config(fake_home)
    servers = config.get("mcpServers", {})
    assert len(servers) >= 2, f"Expected ≥2 entries, got {len(servers)}: {list(servers)}"
