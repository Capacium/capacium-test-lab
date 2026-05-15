#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"
log "Verifying Gemini CLI installation..."
if command -v gemini &>/dev/null; then
    gemini --version 2>/dev/null || true
    log_ok "Gemini CLI found"
    exit 0
fi
log_warn "Gemini CLI not found (may require authentication)"
exit 0
