#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"
log "Verifying Claude Code installation..."
if command -v claude &>/dev/null; then
    claude --version 2>/dev/null || true
    log_ok "Claude Code found"
    exit 0
fi
log_warn "Claude Code not found (CLI-only mode, verification skipped)"
exit 0  # Non-fatal — Claude Code may require API key for full verification
