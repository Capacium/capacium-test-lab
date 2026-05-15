#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"
log "Verifying Codex CLI installation..."
if command -v codex &>/dev/null; then
    codex --version 2>/dev/null || true
    log_ok "Codex CLI found"
    python3 -c "import openai_codex" 2>/dev/null && log_ok "Python module importable" || log_warn "Python module not importable"
    exit 0
fi
log_warn "Codex CLI not found"
exit 0
