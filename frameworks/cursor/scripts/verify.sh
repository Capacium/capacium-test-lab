#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"
log "Verifying Cursor..."
if [ -d ~/.cursor ]; then
    log_ok "~/.cursor directory exists"
    exit 0
fi
log_warn "~/.cursor not found (Cursor may not be installed on host)"
exit 0
