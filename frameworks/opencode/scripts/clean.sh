#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"
log "Cleaning OpenCode skills..."
rm -rf /root/.opencode/skills/*
log_ok "OpenCode clean complete"
