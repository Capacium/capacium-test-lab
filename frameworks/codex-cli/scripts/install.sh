#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

log "Installing Codex CLI..."
pip install --no-cache-dir openai-codex 2>/dev/null || {
    log_error "Could not install Codex CLI"
    exit 1
}
log "Codex CLI installed"
