# Capacium Test Lab

Cross-framework Docker-based test environment for the Capacium ecosystem.

## Frameworks Tested

**P0:** opencode, claude-code, codex-cli  
**P1:** gemini-cli, continue, cursor

## Test Suites

```bash
bash tests/run_tests.sh
```

| Suite | Tests | Description |
|-------|-------|-------------|
| `tests/cli/` | 68 | CLI command tests (install, search, browse, info, compare, etc.) |
| `tests/unit/` | 12 | Framework adapter structure checks |
| `tests/integration/` | 8 | Docker Compose and fixture validation |
| `tests/smoke/` | 5 | Fixture YAML, server.js presence |

## Post-Release Verification

After a Capacium release:
```bash
bash tests/run_tests.sh
```
Expected: **63+/68 CLI tests passing**. Unit/integration/smoke tests require Docker framework stubs (WIP).

## Adding Tests

Every new `cap` CLI feature requires corresponding BATS tests in `tests/cli/`. Add test files in:
- `tests/cli/test_search.bats`
- `tests/cli/test_install.bats`
- `tests/cli/test_other_commands.bats`
