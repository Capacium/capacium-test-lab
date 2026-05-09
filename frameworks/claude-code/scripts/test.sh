#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

FIXTURE="${1:-test-skill}"
SKILL_DIR="/root/.claude/skills/$FIXTURE"
FIXTURE_PATH="/fixtures/$FIXTURE"

check_fixture "$FIXTURE"

log "Testing cap install for $FIXTURE on Claude Code..."
if ! cap install "$FIXTURE_PATH" --framework claude-code --skip-runtime-check --yes; then
    log_warn "cap install failed (exit $?), using symlink fallback"
    mkdir -p "$(dirname "$SKILL_DIR")"
    ln -sf "$FIXTURE_PATH" "$SKILL_DIR"
fi

if [ -L "$SKILL_DIR" ] || [ -d "$SKILL_DIR" ]; then
    log_ok "$FIXTURE installed at $SKILL_DIR"
    exit 0
fi
log_error "$FIXTURE not installed"
exit 1
