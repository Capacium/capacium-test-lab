#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

log "Installing Claude Code CLI..."
npm install -g @anthropic-ai/claude-code 2>/dev/null || {
    log_warn "npm install failed, trying alternative..."
    npm install -g claude-code 2>/dev/null || log_error "Could not install Claude Code"
}
log "Claude Code installed"
