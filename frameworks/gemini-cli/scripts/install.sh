#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

log "Installing Gemini CLI..."
npm install -g @google/gemini-cli 2>/dev/null || {
    log_warn "npm install failed — Gemini CLI may not be publicly available yet"
}
log "Gemini CLI install attempted"
