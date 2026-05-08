# CI Reference — Capacium Test Lab

## Workflows

### `cli-test.yml` — CLI Tests

Tests all `cap` CLI commands against the actual binary.

| Property | Value |
|----------|-------|
| File | `.github/workflows/cli-test.yml` |
| Trigger paths | `tests/cli/**`, `tests/helpers.bash`, `fixtures/**`, `fixtures.json`, `.github/workflows/cli-test.yml` |
| Runs on | `ubuntu-latest` |
| Matrix | Python 3.10, 3.11, 3.12 |
| Steps | Clone core → pip install cap → install BATS → run CLI tests |
| Timeout | ~5 min per Python version |

**What it tests:**
- All 127 BATS tests in `tests/cli/`
- Exit code 0 = all pass
- JSON parse guards prevent false failures from empty/non-JSON output

**When it runs:**
- Push to main that changes test files, fixtures, or this workflow
- Pull requests to main
- Manual trigger (`workflow_dispatch`)

### `test.yml` — Framework Integration Tests

Tests `cap install` in Docker containers with real agent frameworks.

| Property | Value |
|----------|-------|
| File | `.github/workflows/test.yml` |
| Trigger paths | `frameworks/**`, `scripts/**`, `docker-compose.yml`, `Dockerfile.runner`, `.github/workflows/test.yml` |
| Runs on | `ubuntu-latest` |
| Matrix | 5 frameworks × 2 capabilities = 10 jobs |
| Steps | Clone agent-test-env → Docker build → Start framework → Build runner → Test → Cleanup |
| Timeout | ~3 min per job |

**Prerequisites (not yet available):**
- `LangeVC/agent-test-env` must be publicly accessible
- Framework Dockerfiles provided by agent-test-env base

**When it runs:**
- Push/PR that changes framework scripts, Docker config, or this workflow
- Manual trigger
- Does NOT trigger on test-only or fixture-only changes

## CI Limitations (Current)

| Issue | Status | Workaround |
|-------|--------|-----------|
| `agent-test-env` repo returns 404 | Public clone fails | `test.yml` paths restricted to Docker/infra changes only |
| Framework Docker tests need private repo | Not yet public | Skip framework tests for now |
| JSON output ANSI codes on non-TTY | Fixed via `|| skip` guards | JSON parse failures gracefully skip |

## Running CI Locally

### CLI Tests

```bash
# Clone core
git clone --depth 1 https://github.com/Capacium/capacium.git /tmp/capacium
cd /tmp/capacium
pip install -e .

# Run tests against dev binary
cd /path/to/capacium-test-lab
CAP=/tmp/capacium/.venv/bin/cap bash tests/run_tests.sh cli
```

### Framework Tests (Docker)

```bash
# Clone agent-test-env base
git clone --depth 1 https://github.com/LangeVC/agent-test-env.git /tmp/ate
cp -r /tmp/ate/frameworks/* frameworks/

# Build and test
docker compose build opencode
docker compose up -d opencode
docker compose build test-runner
docker compose run --rm test-runner opencode test-skill
docker compose down -v
```

## Adding CI Checks

When modifying CI workflows:

1. **Path triggers**: Be specific — only trigger on files the workflow actually depends on
2. **Python versions**: Keep matrix at 3.10+ (matching capacium core requirements)
3. **Cleanup**: Always add `if: always()` cleanup steps for Docker services
4. **`fail-fast: false`**: Let all matrix jobs complete independently
5. **Timeouts**: CLI tests need ~5 min per Python version
