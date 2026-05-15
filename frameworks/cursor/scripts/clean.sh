#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"
log "Cleaning Cursor MCP config..."
rm -f "$HOME/.cursor/mcp.json"
log_ok "Cursor clean complete"
