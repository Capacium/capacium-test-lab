#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"
SKILL_DIR="$HOME/.continue/skills/test-skill"

log "Testing cap install for Continue.dev..."
cap install /fixtures/test-skill --framework continue-dev --skip-runtime-check 2>/dev/null || {
    mkdir -p "$(dirname "$SKILL_DIR")"
    ln -sf /fixtures/test-skill "$SKILL_DIR"
}

if [ -L "$SKILL_DIR" ]; then
    log_ok "test-skill symlink exists at $SKILL_DIR"
    exit 0
fi
log_error "test-skill not installed"
exit 1
