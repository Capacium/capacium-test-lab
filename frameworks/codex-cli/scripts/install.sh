#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

log "Installing Codex CLI..."
pip install openai-codex 2>/dev/null || {
    log_warn "pip install failed, trying pipx..."
    pipx install openai-codex 2>/dev/null || log_error "Could not install Codex CLI"
}
log "Codex CLI installed"
