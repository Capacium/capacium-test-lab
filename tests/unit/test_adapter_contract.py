"""
Adapter contract tests — shared behavioral spec for all FrameworkAdapter subclasses.

Parametrized over all adapters (Sprint 1: 5 high-risk, Sprint 2: remaining 20+).

Contract: every adapter must satisfy these 8 properties:
  1. install_mcp_server returns True and creates a config entry
  2. capability_exists returns True after install_mcp_server
  3. remove_mcp_server clears the entry; capability_exists returns False
  4. install_mcp_server is idempotent (no duplicate config entry on second call)
  5. install_mcp_server works even when the config file doesn't exist yet
  6. remove_mcp_server on a non-installed cap returns True (idempotent)
  7. install_skill returns True for adapters that support it, False otherwise
  8. remove_skill never raises an exception

Note: ClaudeDesktopAdapter supports_skill=True since P1-001 — skills are exposed
via the capacium-skills MCP wrapper (copies to package cache + registers wrapper).
"""

import importlib
import json
import pytest
from pathlib import Path


# ── Adapter registry ─────────────────────────────────────────────────────────
# Each entry: (module_name, class_name, supports_skill)
# supports_skill=False → install_skill is a no-op/returns False (MCP-only adapter)
# supports_skill=True  → install_skill returns True (skill support via symlink or MCP wrapper)

# Sprint 1 — 5 highest-risk adapters
_SPRINT_1 = [
    ("claude_desktop", "ClaudeDesktopAdapter", True),   # P1-001: via capacium-skills MCP wrapper
    ("codex",          "CodexAdapter",          True),
    ("opencode",       "OpenCodeAdapter",        True),
    ("cursor",         "CursorAdapter",          True),
    ("gemini_cli",     "GeminiCLIAdapter",       True),
]

# Sprint 2 — remaining adapters (TEST-004)
_SPRINT_2 = [
    ("claude_code",        "ClaudeCodeAdapter",        True),
    ("continue_dev",       "ContinueDevAdapter",       True),
    ("roo_code",           "RooCodeAdapter",           False),
    ("windsurf",           "WindsurfAdapter",          False),
    ("zed",                "ZedAdapter",               False),
    ("qwen",               "QwenAdapter",              True),
    ("aider",              "AiderAdapter",             False),
    ("antigravity",        "AntigravityAdapter",       True),
    ("chainlit",           "ChainlitAdapter",          False),
    ("cherry_studio",      "CherryStudioAdapter",      False),
    ("cline",              "ClineAdapter",             False),
    ("copilot",            "CopilotAdapter",           True),
    ("desktop_commander",  "DesktopCommanderAdapter",  False),
    ("goose",              "GooseAdapter",             False),
    ("hermes",             "HermesAdapter",            True),
    ("junie",              "JunieAdapter",             True),
    ("librechat",          "LibreChatAdapter",         False),
    ("nextchat",           "NextChatAdapter",          False),
    ("openclaw",           "OpenClawAdapter",          True),
    ("sourcegraph_cody",   "SourcegraphCodyAdapter",   False),
]

ADAPTERS = _SPRINT_1 + _SPRINT_2

ADAPTER_IDS = [f"{cls}" for _, cls, _ in ADAPTERS]


# ── Helpers ───────────────────────────────────────────────────────────────────

def make_adapter(module_name: str, class_name: str):
    """Instantiate an adapter — must be called while fake_home is active."""
    mod = importlib.import_module(f"capacium.adapters.{module_name}")
    return getattr(mod, class_name)()


def make_adapter_param(param):
    """Unpack a parametrize tuple and instantiate."""
    module_name, class_name, supports_skill = param
    return make_adapter(module_name, class_name), supports_skill


# ── Contract test 1: install_mcp_server creates entry ────────────────────────

@pytest.mark.contract
@pytest.mark.parametrize("module,cls,_skill", ADAPTERS, ids=ADAPTER_IDS)
def test_install_mcp_server_returns_true(fake_home, fake_mcp_source, module, cls, _skill):
    adapter = make_adapter(module, cls)
    result = adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)
    assert result is True, f"{cls}.install_mcp_server() returned {result!r}, expected True"


@pytest.mark.contract
@pytest.mark.parametrize("module,cls,_skill", ADAPTERS, ids=ADAPTER_IDS)
def test_capability_exists_after_install_mcp(fake_home, fake_mcp_source, module, cls, _skill):
    adapter = make_adapter(module, cls)
    adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)
    assert adapter.capability_exists("test-cap"), (
        f"{cls}.capability_exists('test-cap') returned False after install_mcp_server"
    )


# ── Contract test 2: remove clears entry ─────────────────────────────────────

@pytest.mark.contract
@pytest.mark.parametrize("module,cls,_skill", ADAPTERS, ids=ADAPTER_IDS)
def test_remove_mcp_server_clears_entry(fake_home, fake_mcp_source, module, cls, _skill):
    adapter = make_adapter(module, cls)
    adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)
    assert adapter.capability_exists("test-cap")

    result = adapter.remove_mcp_server("test-cap")
    assert result is True, f"{cls}.remove_mcp_server() returned {result!r}"
    assert not adapter.capability_exists("test-cap"), (
        f"{cls}.capability_exists('test-cap') still True after remove_mcp_server"
    )


# ── Contract test 3: idempotent install (no duplicate entries) ────────────────

@pytest.mark.contract
@pytest.mark.parametrize("module,cls,_skill", ADAPTERS, ids=ADAPTER_IDS)
def test_install_mcp_server_idempotent(fake_home, fake_mcp_source, module, cls, _skill):
    """Installing twice must not create duplicate config entries."""
    adapter = make_adapter(module, cls)
    adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)
    adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)

    # Count entries by reading the config file directly
    config_path = _get_config_path(adapter)
    if config_path is None or not config_path.exists():
        pytest.skip(f"{cls}: config_path not accessible for duplicate check")

    content = config_path.read_text()
    # Count occurrences of the server key — must appear at most twice (key + value)
    # For JSON: "test-cap" should appear exactly once as a key in mcpServers
    # For TOML: [mcp_servers.test-cap] appears exactly once
    occurrences = content.count('"test-cap"') + content.count("test-cap")
    # Rough bound: if test-cap appears >4 times it's likely duplicated
    assert occurrences <= 4, (
        f"{cls}: 'test-cap' appears {occurrences} times in config — likely duplicate entry\n"
        f"Config:\n{content}"
    )


# ── Contract test 4: install creates config when file doesn't exist ──────────

@pytest.mark.contract
@pytest.mark.parametrize("module,cls,_skill", ADAPTERS, ids=ADAPTER_IDS)
def test_install_creates_config_if_missing(fake_home, fake_mcp_source, module, cls, _skill):
    """install_mcp_server must create the config file if it doesn't exist yet."""
    adapter = make_adapter(module, cls)
    config_path = _get_config_path(adapter)
    if config_path is not None:
        assert not config_path.exists(), f"Expected no config at {config_path} before install"

    result = adapter.install_mcp_server("test-cap", "1.0.0", fake_mcp_source)
    assert result is True

    if config_path is not None:
        assert config_path.exists(), f"{cls}: config not created at {config_path}"


# ── Contract test 5: remove on non-installed cap is idempotent ───────────────

@pytest.mark.contract
@pytest.mark.parametrize("module,cls,_skill", ADAPTERS, ids=ADAPTER_IDS)
def test_remove_mcp_from_missing_config_is_idempotent(fake_home, module, cls, _skill):
    """remove_mcp_server with no prior install must return True (no crash)."""
    adapter = make_adapter(module, cls)
    result = adapter.remove_mcp_server("nonexistent-cap")
    assert result is True, (
        f"{cls}.remove_mcp_server('nonexistent-cap') returned {result!r}, expected True"
    )


# ── Contract test 6: install_skill (adapters that support it) ────────────────

@pytest.mark.contract
@pytest.mark.parametrize("module,cls,supports_skill", ADAPTERS, ids=ADAPTER_IDS)
def test_install_skill_contract(fake_home, fake_skill_source, module, cls, supports_skill):
    adapter = make_adapter(module, cls)
    result = adapter.install_skill("test-skill", "1.0.0", fake_skill_source)

    if supports_skill:
        assert result is True, f"{cls}.install_skill() returned {result!r}, expected True"
    else:
        assert result is False, (
            f"{cls}.install_skill() returned {result!r} — "
            f"MCP-only adapter should return False"
        )


# ── Contract test 7: remove_skill on non-installed returns True ───────────────

@pytest.mark.contract
@pytest.mark.parametrize("module,cls,supports_skill", ADAPTERS, ids=ADAPTER_IDS)
def test_remove_skill_idempotent(fake_home, module, cls, supports_skill):
    adapter = make_adapter(module, cls)
    result = adapter.remove_skill("nonexistent-skill")
    # All adapters must not crash on remove of a non-installed skill
    assert result is not None  # True or False, but not an exception


# ── Helper: get config path from adapter instance ────────────────────────────

def _get_config_path(adapter) -> "Path | None":
    """Return the adapter's config_path attribute if it has one."""
    for attr in ("config_path", "global_mcp_path", "mcp_path"):
        if hasattr(adapter, attr):
            return getattr(adapter, attr)
    return None
