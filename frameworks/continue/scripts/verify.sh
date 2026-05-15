#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"
log "Verifying Continue.dev installation..."
if command -v continue &>/dev/null; then
    continue --version 2>/dev/null || true
    log_ok "Continue.dev found"
    exit 0
fi
log_warn "Continue.dev not found (may require VS Code environment)"
exit 0
