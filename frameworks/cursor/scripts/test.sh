#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

# Cursor uses MCP JSON config, not skill directories
MCP_CONFIG="$HOME/.cursor/mcp.json"

log "Testing Cursor MCP configuration..."
mkdir -p "$(dirname "$MCP_CONFIG")"

# Write test MCP config
cat > "$MCP_CONFIG" << 'EOF'
{
  "mcpServers": {
    "test-mcp-server": {
      "command": "node",
      "args": ["/fixtures/test-mcp-server/server.js"]
    }
  }
}
EOF

if [ -f "$MCP_CONFIG" ]; then
    log_ok "Cursor MCP config created at $MCP_CONFIG"
    exit 0
fi
log_error "Failed to create Cursor MCP config"
exit 1
