# Fixture Guide — Capacium Test Lab

## Overview

Fixtures are minimal, self-contained capability packages used as test subjects for all `cap` commands. Each fixture lives in `fixtures/<name>/` and is registered in `fixtures.json`.

## Fixture Registry (`fixtures.json`)

The central registry at the repo root:

```json
[
  {"name": "test-skill", "kind": "skill", "version": "1.0.0"},
  {"name": "test-mcp-server", "kind": "mcp-server", "version": "1.0.0"},
  ...
]
```

Tests auto-discover fixture names via `python3 -c "import json; ..."` in `helpers.bash`. No test file modifications needed when adding a new fixture.

## Current Fixture Inventory (12)

| Fixture | Kind | Purpose | Content Files |
|---------|------|---------|--------------|
| `test-skill` | skill | Basic install/verify lifecycle | capability.yaml, SKILL.md |
| `test-mcp-server` | mcp-server | MCP server install + discovery | capability.yaml, server.js |
| `test-tool` | tool | Tool capability install | capability.yaml, tool.sh |
| `test-prompt` | prompt | Prompt capability install | capability.yaml, prompt.md |
| `test-template` | template | Template capability install | capability.yaml, template.md |
| `test-workflow` | workflow | Workflow capability install | capability.yaml, workflow.md |
| `test-connector-pack` | connector-pack | Connector-pack install | capability.yaml, connectors.json |
| `test-runtimes-skill` | skill | Runtime pre-flight checks | capability.yaml, SKILL.md |
| `test-broken-manifest` | skill | Error path testing (invalid manifest) | capability.yaml, SKILL.md |
| `test-dependency` | skill | Lock file / dependency testing | capability.yaml, SKILL.md |
| `test-bundle` | bundle | Bundle with sub-capabilities | capability.yaml, SKILL.md, sub-skill/, sub-tool/ |
| `test-signed-cap` | skill | Sign/verify cryptographic tests | capability.yaml, SKILL.md |

## Adding a New Fixture

### Step 1: Create Directory Structure

```bash
mkdir -p fixtures/test-new-cap
```

### Step 2: Create `capability.yaml`

Minimal valid manifest:

```yaml
name: test-new-cap
version: 1.0.0
kind: skill
description: Test capability for Capacium Test Lab
author: Capacium Test Lab
```

For specific kinds, add required fields:

```yaml
# MCP server
kind: mcp-server
runtimes:
  node: ">=18"
mcp:
  transport: stdio
  command: node
  args: ["server.js"]

# With dependencies
kind: skill
dependencies:
  - name: test-skill
    version: ">=1.0.0"

# With runtimes
kind: skill
runtimes:
  uv: ">=0.4.0"
  node: ">=20"

# Bundle
kind: bundle
capabilities:
  - name: sub-skill
    source: ./sub-skill
  - name: sub-tool
    source: ./sub-tool
```

### Step 3: Add Content Files

At minimum, one content file matching the kind convention:

| Kind | Content file |
|------|-------------|
| skill | SKILL.md |
| tool | tool.sh (executable) |
| prompt | prompt.md |
| template | template.md |
| workflow | workflow.md |
| connector-pack | connectors.json |
| mcp-server | server.js (or equivalent command file) |
| bundle | SKILL.md + sub-capability directories |

### Step 4: Register in `fixtures.json`

Add an entry:

```json
{"name": "test-new-cap", "kind": "skill", "version": "1.0.0"}
```

### Step 5: Done

No test file modifications needed. `cap_cleanup()` in `helpers.bash` auto-discovers the new fixture name from `fixtures.json` and cleans it up before/after tests.

## Fixture Naming Convention

- Namespace: `cap/<fixture-name>` (equivalent to `owner/name` in registry)
- Fixture directory name: `test-<description>` (kebab-case)
- All fixture names start with `test-` to avoid namespace pollution
- `capability.yaml` name matches directory name

## Cleanup Contract

The `cap_cleanup()` function in `helpers.bash` runs in every test file's `setup()`:

```bash
cap_cleanup() {
    for name in $ALL_CAP_KINDS; do
        "$CAP" remove "cap/$name" --force &>/dev/null || true
    done
}
```

This ensures:
- **Before each test**: No residual installs from previous test runs
- **Cross-test isolation**: Installing in test A doesn't break test B
- **Auto-discovery**: Adding a fixture to `fixtures.json` automatically includes it in cleanup

## Broken/Error Fixtures

`test-broken-manifest` deliberately violates manifest requirements:

```yaml
name: broken manifest        # Spaces in name
version: 1.0.0
description: Broken manifest # No 'kind' field
author: Capacium Test Lab
```

Used for error path testing:
- `cap install` from invalid manifest
- `cap verify` on invalid capability
- `cap package` from invalid manifest

## Bundle Fixtures

`test-bundle` is a bundle with two sub-capabilities:

```
test-bundle/
├── capability.yaml          # kind: bundle, capabilities: [sub-skill, sub-tool]
├── SKILL.md
├── sub-skill/
│   ├── capability.yaml      # kind: skill
│   └── SKILL.md
└── sub-tool/
    ├── capability.yaml      # kind: tool
    └── tool.sh
```

Used for:
- Bundle fingerprint computation
- Bundle install with sub-cap reference tracking
- Bundle remove with reference counting
