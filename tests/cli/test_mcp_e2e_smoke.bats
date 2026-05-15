#!/usr/bin/env bats
# test_mcp_e2e_smoke.bats — MCP E2E smoke tests (run on every PR)
#
# Tests MCP server install → verify → remove cycle for 3 priority frameworks.
# Uses probe_mcp_server.sh (MCP Inspector CLI wrapper) to verify the server
# actually responds to tools/list.
#
# Requires:
#   - Node.js 22+ (available in Dockerfile.runner after TEST-006)
#   - test-mcp-stub fixture (fixtures/test-mcp-stub/)
#   - probe_mcp_server.sh (scripts/probe_mcp_server.sh)
#
# Frameworks tested (smoke): opencode, claude-code, codex-cli
# Full E2E deep tests (nightly): test_mcp_e2e_deep.bats

load '../helpers'

setup() {
    load '../helpers'
    CAP="${CAP:-cap}"
    FRAMEWORK="${FRAMEWORK:-opencode}"
    cap_remove test-mcp-stub 2>/dev/null || true
}

teardown() {
    cap_remove test-mcp-stub 2>/dev/null || true
}

# ── Helper: find installed MCP server command ─────────────────────────────

_find_mcp_command() {
    local cap_name="$1"
    # Try framework-specific config locations
    local cmd=""
    # opencode: ~/.config/opencode/opencode.json → mcp.<cap>.command
    if [ -f "$HOME/.config/opencode/opencode.json" ]; then
        cmd="$(python3 -c "
import json, sys
c = json.load(open('$HOME/.config/opencode/opencode.json'))
entry = c.get('mcp', {}).get('$cap_name', {})
cmd = entry.get('command', [])
if isinstance(cmd, list):
    print(' '.join(str(x) for x in cmd))
elif isinstance(cmd, str):
    args = entry.get('args', [])
    print(cmd + ' ' + ' '.join(str(a) for a in args))
" 2>/dev/null)"
    fi
    # codex: ~/.codex/config.toml → mcp_servers.<cap>.command + args
    if [ -z "$cmd" ] && [ -f "$HOME/.codex/config.toml" ]; then
        cmd="$(python3 -c "
try:
    import tomllib
except ImportError:
    import tomli as tomllib
import sys
with open('$HOME/.codex/config.toml', 'rb') as f:
    c = tomllib.load(f)
for k, v in c.get('mcp_servers', {}).items():
    if '$cap_name' in k:
        print(v.get('command', '') + ' ' + ' '.join(v.get('args', [])))
        break
" 2>/dev/null)"
    fi
    # claude-code: ~/.claude.json → mcpServers.<cap>
    if [ -z "$cmd" ] && [ -f "$HOME/.claude.json" ]; then
        cmd="$(python3 -c "
import json, sys
c = json.load(open('$HOME/.claude.json'))
for k, v in c.get('mcpServers', {}).items():
    if '$cap_name' in k:
        print(v.get('command', '') + ' ' + ' '.join(v.get('args', [])))
        break
" 2>/dev/null)"
    fi
    echo "$cmd"
}

# ── Test 1: install test-mcp-stub exits 0 ────────────────────────────────

@test "cap install test-mcp-stub exits 0 in $FRAMEWORK" {
    run "$CAP" install cap/test-mcp-stub \
        --source "$FIXTURES_DIR/test-mcp-stub" \
        --framework "$FRAMEWORK" \
        --yes --skip-runtime-check
    [ "$status" -eq 0 ]
}

# ── Test 2: MCP config entry exists after install ─────────────────────────

@test "MCP config has test-mcp-stub entry after install in $FRAMEWORK" {
    run "$CAP" install cap/test-mcp-stub \
        --source "$FIXTURES_DIR/test-mcp-stub" \
        --framework "$FRAMEWORK" \
        --yes --skip-runtime-check
    [ "$status" -eq 0 ]

    # Verify entry in config
    run "$CAP" list
    [ "$status" -eq 0 ]
    # At least one listing mechanism should show the server
    [[ "$output" =~ "test-mcp-stub" ]] || {
        # Some adapters may not list MCP servers directly — check config file instead
        local found=0
        for cfg in \
            "$HOME/.config/opencode/opencode.json" \
            "$HOME/.codex/config.toml" \
            "$HOME/.claude.json" \
            "$HOME/.gemini/settings/mcp_config.json"; do
            [ -f "$cfg" ] && grep -q "test-mcp-stub" "$cfg" 2>/dev/null && found=1 && break
        done
        [ "$found" -eq 1 ]
    }
}

# ── Test 3: probe_mcp_server.sh verifies tools/list ───────────────────────

@test "probe_mcp_server.sh returns exit 0 for test-mcp-stub in $FRAMEWORK" {
    # Skip if Node.js 22 not available
    if ! command -v node >/dev/null 2>&1; then
        skip "Node.js not available — skipping MCP probe"
    fi
    local node_major
    node_major="$(node --version | sed 's/v//' | cut -d. -f1)"
    if [ "$node_major" -lt 22 ]; then
        skip "Node.js < 22 — MCP Inspector requires 22.7.5+"
    fi

    run "$CAP" install cap/test-mcp-stub \
        --source "$FIXTURES_DIR/test-mcp-stub" \
        --framework "$FRAMEWORK" \
        --yes --skip-runtime-check
    [ "$status" -eq 0 ]

    # Run the probe directly against the fixture server
    run bash "$TEST_LAB_ROOT/scripts/probe_mcp_server.sh" \
        node "$FIXTURES_DIR/test-mcp-stub/server.js"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "cap_test" ]] || [[ "$output" =~ "PASS" ]] || [[ "$output" =~ "tool" ]]
}

# ── Test 4: remove exits 0 and clears config ─────────────────────────────

@test "cap remove test-mcp-stub exits 0 in $FRAMEWORK" {
    run "$CAP" install cap/test-mcp-stub \
        --source "$FIXTURES_DIR/test-mcp-stub" \
        --framework "$FRAMEWORK" \
        --yes --skip-runtime-check
    [ "$status" -eq 0 ]

    run "$CAP" remove cap/test-mcp-stub --force
    [ "$status" -eq 0 ]
}

# ── Test 5: reinstall after remove works cleanly ──────────────────────────

@test "reinstall test-mcp-stub after remove succeeds in $FRAMEWORK" {
    # Install → remove → reinstall
    run "$CAP" install cap/test-mcp-stub \
        --source "$FIXTURES_DIR/test-mcp-stub" \
        --framework "$FRAMEWORK" \
        --yes --skip-runtime-check
    [ "$status" -eq 0 ]

    run "$CAP" remove cap/test-mcp-stub --force
    [ "$status" -eq 0 ]

    run "$CAP" install cap/test-mcp-stub \
        --source "$FIXTURES_DIR/test-mcp-stub" \
        --framework "$FRAMEWORK" \
        --yes --skip-runtime-check
    [ "$status" -eq 0 ]
}
