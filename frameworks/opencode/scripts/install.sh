#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

log "Installing OpenCode CLI..."
npm install -g @opencodeai/cli 2>/dev/null || {
    log_warn "npm install failed, trying alternative..."
    npm install -g opencode 2>/dev/null || log_error "Could not install OpenCode"
}
log "OpenCode installed"
