#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"
log "Verifying OpenCode installation..."
if command -v opencode &>/dev/null; then
    opencode --version 2>/dev/null || true
    log_ok "OpenCode found"
    exit 0
fi
log_error "OpenCode not found"
exit 1
