#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

FIXTURE="${1:-test-mcp-server}"
MCP_CONFIG="$HOME/.cursor/mcp.json"

log "Configuring $FIXTURE for Cursor..."
mkdir -p "$(dirname "$MCP_CONFIG")"

cat > "$MCP_CONFIG" << 'MCPEOF'
{
  "mcpServers": {
    "test-mcp-server": {
      "command": "node",
      "args": ["/fixtures/test-mcp-server/server.js"]
    }
  }
}
MCPEOF

if [ -f "$MCP_CONFIG" ]; then
    log_ok "MCP config written to $MCP_CONFIG"
    exit 0
fi
log_error "Failed to write MCP config"
exit 1
