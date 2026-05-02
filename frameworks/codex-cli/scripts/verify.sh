#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"
log "Verifying Codex CLI installation..."
if command -v codex &>/dev/null; then
    codex --version 2>/dev/null || true
    log_ok "Codex CLI found"
    exit 0
fi
# Codex may install as `openai-codex`
if python -c "import codex" 2>/dev/null; then
    log_ok "Codex Python module found"
    exit 0
fi
log_error "Codex CLI not found"
exit 1
