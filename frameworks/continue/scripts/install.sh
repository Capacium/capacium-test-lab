#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

log "Installing Continue.dev..."
npm install -g @continuedev/continue 2>/dev/null || {
    log_warn "npm install failed — Continue.dev may require VS Code extension"
}
log "Continue.dev install attempted"
