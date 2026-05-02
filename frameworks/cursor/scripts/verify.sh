#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"
log "Verifying Cursor MCP configuration..."

# Cursor reads from ~/.cursor/mcp.json or project .cursor/mcp.json
CONFIG_DIR="${HOME}/.cursor"
if [ -d "$CONFIG_DIR" ]; then
    log_ok "Cursor config directory exists"
    exit 0
fi

log_warn "Cursor config directory not found (GUI-only, config-file test)"
exit 0  # Non-fatal
