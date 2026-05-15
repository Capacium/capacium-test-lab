#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

log "Installing Gemini CLI..."
npm install -g @google/gemini-cli 2>/dev/null || {
    log_warn "npm install failed, trying alternative..."
    npm install -g gemini-cli 2>/dev/null || log_error "Could not install Gemini CLI"
}
log "Gemini CLI installed"
