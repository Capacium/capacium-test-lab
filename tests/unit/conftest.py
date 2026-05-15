"""
Shared pytest fixtures for Capacium CLI adapter unit tests.

All tests run against a fake home directory — no real ~/.config, ~/Library,
or ~/.capacium paths are ever touched.

Usage in tests:
    def test_something(fake_home, fake_cap_source):
        # Path.home() returns fake_home during this test
        adapter = CodexAdapter()          # uses fake_home
        adapter.install_skill(...)
        assert (fake_home / ".codex" / "skills" / "my-cap").exists()
"""

import json
import pytest
from pathlib import Path
from unittest.mock import patch


# ── Core isolation fixture ────────────────────────────────────────────────────

@pytest.fixture
def fake_home(tmp_path, monkeypatch):
    """Isolated home directory for a single test.

    Patches both os.environ["HOME"] and Path.home() so every code path
    that resolves the user's home directory lands in tmp_path/home.

    The fixture asserts the patch is active before yielding — if this
    assertion fails, the test would silently write to the real home dir.
    """
    home = tmp_path / "home"
    home.mkdir()

    # Patch 1: env var (used by os.path.expanduser on POSIX)
    monkeypatch.setenv("HOME", str(home))

    # Patch 2: Path.home() directly (belt + suspenders for macOS pwd.getpwuid bypass)
    # Patch 3: cwd → fake_home so CursorAdapter (Path.cwd() / ".cursor" / ...) stays isolated
    monkeypatch.chdir(home)

    with patch.object(Path, "home", return_value=home):
        # Safety assertion — must hold before any adapter is instantiated
        assert Path.home() == home, (
            f"Path.home() monkeypatch failed: got {Path.home()}, expected {home}"
        )
        yield home


# ── Fake capability source directory ─────────────────────────────────────────

@pytest.fixture
def fake_skill_source(tmp_path):
    """Minimal skill source directory with a valid capability.yaml."""
    src = tmp_path / "fake-skill-src"
    src.mkdir()
    (src / "capability.yaml").write_text(
        "name: test-cap\nversion: 1.0.0\nkind: skill\ndescription: Test\nauthor: Test\n"
    )
    (src / "skill.md").write_text("# Test skill\n")
    return src


@pytest.fixture
def fake_mcp_source(tmp_path):
    """Minimal mcp-server source directory with a valid capability.yaml."""
    src = tmp_path / "fake-mcp-src"
    src.mkdir()
    (src / "capability.yaml").write_text(
        "name: test-mcp\nversion: 1.0.0\nkind: mcp-server\ndescription: Test MCP\n"
        "author: Test\nmcp:\n  transport: stdio\n  command: node\n  args: [server.js]\n"
    )
    (src / "server.js").write_text("// stub\n")
    return src


@pytest.fixture
def fake_mcp_source_with_entrypoint(tmp_path):
    """MCP source with entrypoint subdirectory (e.g. entrypoint: mcp-server)."""
    src = tmp_path / "fake-mcp-entrypoint-src"
    src.mkdir()
    # Root capability.yaml references entrypoint subdirectory
    (src / "capability.yaml").write_text(
        "name: test-mcp-ep\nversion: 1.0.0\nkind: mcp-server\ndescription: Test\n"
        "author: Test\nentrypoint: mcp-server\n"
        "mcp:\n  transport: stdio\n  command: node\n  args: [dist/index.js]\n"
    )
    # Entrypoint subdirectory
    ep = src / "mcp-server"
    ep.mkdir()
    (ep / "capability.yaml").write_text(
        "name: test-mcp-ep\nversion: 1.0.0\nkind: mcp-server\ndescription: Test\n"
        "author: Test\nmcp:\n  transport: stdio\n  command: node\n  args: [dist/index.js]\n"
    )
    dist = ep / "dist"
    dist.mkdir()
    (dist / "index.js").write_text("// stub entry\n")
    return src


# ── Adapter loader helper ─────────────────────────────────────────────────────

def load_adapter(module_name: str, class_name: str):
    """Import and instantiate an adapter class by module + class name.

    Must be called INSIDE a test where fake_home is active, so that
    Path.home() is already patched when __init__ runs.
    """
    import importlib
    mod = importlib.import_module(f"capacium.adapters.{module_name}")
    cls = getattr(mod, class_name)
    return cls()
