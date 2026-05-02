#!/usr/bin/env bash
set -euo pipefail

FRAMEWORK="${1:-all}"

log() { echo "[provision] $*"; }

provision_fixtures() {
    local fw="$1"
    log "Provisioning fixtures for $fw..."
    docker compose exec -T "$fw" mkdir -p "/root/.${fw##*-}/skills" 2>/dev/null || true
}

up_framework() {
    local fw="$1"
    log "Starting $fw..."
    docker compose up -d "$fw" 2>/dev/null || {
        log "⚠ Failed to start $fw via compose, trying docker-compose..."
        docker-compose up -d "$fw" 2>/dev/null || {
            echo "ERROR: Cannot start $fw"
            return 1
        }
        return 0
    }
}

if [ "$FRAMEWORK" = "all" ]; then
    for fw in opencode claude-code codex-cli; do
        up_framework "$fw"
    done
else
    up_framework "$FRAMEWORK"
fi

log "Provision complete"
