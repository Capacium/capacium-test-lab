#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"
log "Cleaning Claude Code skills..."
rm -rf /root/.claude/skills/*
log_ok "Claude Code clean complete"
