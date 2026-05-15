#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

log "Installing Continue.dev..."
npm install -g @continuedev/continue 2>/dev/null || {
    log_error "Could not install Continue.dev"
    exit 1
}
log "Continue.dev installed"
