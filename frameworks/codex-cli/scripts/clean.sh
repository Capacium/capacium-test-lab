#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"
log "Cleaning Codex CLI skills..."
rm -rf /root/.codex/skills/*
log_ok "Codex CLI clean complete"
