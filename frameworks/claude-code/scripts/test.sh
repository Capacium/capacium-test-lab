#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

FIXTURE="${1:-test-skill}"
SKILL_DIR="/root/.claude/skills/$FIXTURE"

log "Testing $FIXTURE for Claude Code..."
mkdir -p "$(dirname "$SKILL_DIR")"
ln -sf "/fixtures/$FIXTURE" "$SKILL_DIR"

if [ -L "$SKILL_DIR" ]; then
    log_ok "$FIXTURE symlink exists at $SKILL_DIR"
    exit 0
fi
log_error "$FIXTURE not installed"
exit 1
