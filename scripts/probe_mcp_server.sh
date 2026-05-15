#!/usr/bin/env bash
# probe_mcp_server.sh — MCP Inspector CLI wrapper for E2E server verification
#
# Usage:
#   probe_mcp_server.sh <command> [args...]
#   probe_mcp_server.sh node server.js
#   probe_mcp_server.sh python -m my_server
#
# Requires: Node.js 22.7.5+ (for MCP Inspector 0.21.2)
# Uses: npx @modelcontextprotocol/inspector@0.21.2 --cli
#
# Exit codes:
#   0 — tools/list succeeded and returned ≥1 tool
#   1 — command failed or returned 0 tools
#   2 — Node.js version too old / npx unavailable
#   3 — timeout (server did not respond within PROBE_TIMEOUT seconds)
#
# Environment:
#   PROBE_TIMEOUT    timeout in ms (default: 30000)
#   PROBE_MIN_TOOLS  minimum tools expected (default: 1)
#   PROBE_VERBOSE    set to 1 for verbose output

set -euo pipefail

PROBE_TIMEOUT="${PROBE_TIMEOUT:-30000}"
PROBE_MIN_TOOLS="${PROBE_MIN_TOOLS:-1}"
PROBE_VERBOSE="${PROBE_VERBOSE:-0}"
MCP_INSPECTOR_VERSION="0.21.2"

# ── Helpers ──────────────────────────────────────────────────────────────

log() {
    [ "$PROBE_VERBOSE" = "1" ] && echo "$@" >&2 || true
}

fail() {
    echo "✗ $*" >&2
    exit "${2:-1}"
}

# ── Validate Node.js version ─────────────────────────────────────────────

if ! command -v node >/dev/null 2>&1; then
    fail "Node.js not found in PATH. Install Node.js 22.7.5+ to use MCP Inspector." 2
fi

NODE_VERSION="$(node --version | sed 's/v//')"
NODE_MAJOR="$(echo "$NODE_VERSION" | cut -d. -f1)"

if [ "$NODE_MAJOR" -lt 22 ]; then
    fail "Node.js $NODE_VERSION too old. MCP Inspector requires Node.js 22.7.5+. Install Node.js 22 LTS." 2
fi

log "→ Node.js $NODE_VERSION OK"

if ! command -v npx >/dev/null 2>&1; then
    fail "npx not found. Install Node.js 22 LTS with npm." 2
fi

# ── Build command string from args ───────────────────────────────────────

if [ "$#" -lt 1 ]; then
    echo "Usage: probe_mcp_server.sh <command> [args...]" >&2
    echo "Example: probe_mcp_server.sh node server.js" >&2
    exit 1
fi

SERVER_CMD="$*"
log "→ Probing MCP server: $SERVER_CMD"
log "→ Timeout: ${PROBE_TIMEOUT}ms"
log "→ Minimum tools expected: $PROBE_MIN_TOOLS"
log "→ Using MCP Inspector $MCP_INSPECTOR_VERSION"

# ── Run MCP Inspector CLI ─────────────────────────────────────────────────
# MCP Inspector CLI syntax (0.21.2):
#   npx @modelcontextprotocol/inspector@VERSION --cli <cmd> [args] \
#       --method tools/list --timeout <ms>
#
# The --cli flag suppresses the browser UI and runs headless.
# Output is JSON on stdout.

INSPECTOR_OUTPUT=""
INSPECTOR_EXIT=0

INSPECTOR_OUTPUT="$(
    npx --yes "@modelcontextprotocol/inspector@${MCP_INSPECTOR_VERSION}" \
        --cli $SERVER_CMD \
        --method tools/list \
        --timeout "$PROBE_TIMEOUT" \
        2>&1
)" || INSPECTOR_EXIT=$?

log "→ Inspector exit code: $INSPECTOR_EXIT"
log "→ Raw output:"
log "$INSPECTOR_OUTPUT"

# ── Parse output ─────────────────────────────────────────────────────────
# Inspector outputs tool names/count. We look for JSON or tool count lines.

if [ "$INSPECTOR_EXIT" -ne 0 ]; then
    # Distinguish timeout from other failures
    if echo "$INSPECTOR_OUTPUT" | grep -qi "timeout\|timed out"; then
        fail "MCP server timed out after ${PROBE_TIMEOUT}ms" 3
    fi
    fail "MCP Inspector exited $INSPECTOR_EXIT: $INSPECTOR_OUTPUT"
fi

# Count tools — look for JSON result or tool listing
TOOL_COUNT=0

# Try JSON parsing first
if echo "$INSPECTOR_OUTPUT" | python3 -c "
import json, sys
data = sys.stdin.read()
# Find last JSON object in output
for line in reversed(data.strip().splitlines()):
    line = line.strip()
    if not line.startswith('{'):
        continue
    try:
        obj = json.loads(line)
        tools = obj.get('result', {}).get('tools', obj.get('tools', []))
        if isinstance(tools, list):
            print(len(tools))
            sys.exit(0)
    except Exception:
        pass
sys.exit(1)
" 2>/dev/null; then
    TOOL_COUNT="$(echo "$INSPECTOR_OUTPUT" | python3 -c "
import json, sys
data = sys.stdin.read()
for line in reversed(data.strip().splitlines()):
    line = line.strip()
    if not line.startswith('{'):
        continue
    try:
        obj = json.loads(line)
        tools = obj.get('result', {}).get('tools', obj.get('tools', []))
        if isinstance(tools, list):
            print(len(tools))
            sys.exit(0)
    except Exception:
        pass
print(0)
" 2>/dev/null)"
else
    # Fall back to line counting (Inspector may print one tool per line)
    TOOL_COUNT="$(echo "$INSPECTOR_OUTPUT" | grep -c "\"name\"" 2>/dev/null || echo 0)"
fi

log "→ Tools found: $TOOL_COUNT"

if [ "$TOOL_COUNT" -lt "$PROBE_MIN_TOOLS" ]; then
    fail "MCP server returned $TOOL_COUNT tools (expected ≥$PROBE_MIN_TOOLS). Output:\n$INSPECTOR_OUTPUT"
fi

echo "✓ MCP probe passed: $TOOL_COUNT tool(s) returned by $SERVER_CMD"
exit 0
