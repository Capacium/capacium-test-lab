"""
Scaffold test — verifies the unit test infrastructure is wired up correctly.

This is the first test in tests/unit/. It passes as long as:
- pytest can collect from this directory
- conftest.py is loadable
- capacium is importable (via pip install -e /path/to/capacium)
- fake_home fixture works (Path.home() is patched)
"""

import pytest
from pathlib import Path


def test_pytest_infrastructure_loads():
    """pytest + conftest.py + importlib mode all working."""
    assert True


def test_fake_home_isolates_from_real_home(fake_home):
    """fake_home fixture patches Path.home() before this test runs."""
    # The patch is active — Path.home() must point at the tmp dir, not the real home
    assert Path.home() == fake_home
    assert Path.home() != Path("/Users") / Path.home().name  # not real home prefix
    assert fake_home.exists()


def test_fake_home_is_empty(fake_home):
    """Fresh fake_home starts empty — no leftover config files."""
    children = list(fake_home.iterdir())
    assert children == [], f"fake_home not empty: {children}"


def test_capacium_importable():
    """capacium package is reachable (pip install -e needed in CI)."""
    import capacium  # noqa: F401


def test_adapter_base_importable():
    """capacium.adapters.base can be imported without side-effects."""
    from capacium.adapters.base import FrameworkAdapter, _cap_id
    assert _cap_id("my-cap") == "my-cap"
    assert _cap_id("my-cap", "alice") == "alice/my-cap"
    assert _cap_id("my-cap", "global") == "my-cap"
