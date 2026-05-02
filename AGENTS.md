# Capacium Test Lab — Agents Guide

## Language

**English is REQUIRED for ALL Capacium content.**
READ.ME files, documentation, inline code comments, commit messages, PR descriptions, release notes — everything is English. No exceptions for published content.

## Quick Start

```bash
# Start all P0 frameworks
docker compose up -d opencode claude-code codex-cli

# Test a capability
bash scripts/test-framework.sh opencode test-skill

# Run BATS suite
bash tests/run_tests.sh all
```

## Architecture

6 frameworks (3 P0 + 3 P1). Universal lifecycle API (`install/verify/test/clean.sh`). 25 BATS tests (unit/integration/smoke). GitHub Actions CI matrix: 5 frameworks × 2 capabilities = 10 jobs.

## Fixtures

- `test-skill` — validates `cap install` + symlink creation
- `test-mcp-server` — minimal stdio JSON-RPC MCP server
