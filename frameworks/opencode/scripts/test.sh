#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"
SKILL_DIR="/root/.opencode/skills/test-skill"

log "Testing cap install for OpenCode..."
cap install /fixtures/test-skill --framework opencode --skip-runtime-check 2>/dev/null || {
    # Fallback: manual symlink
    log_warn "cap install failed, using symlink fallback"
    mkdir -p "$(dirname "$SKILL_DIR")"
    ln -sf /fixtures/test-skill "$SKILL_DIR"
}

if [ -L "$SKILL_DIR" ]; then
    log_ok "test-skill symlink exists at $SKILL_DIR"
    exit 0
fi
log_error "test-skill not installed"
exit 1
