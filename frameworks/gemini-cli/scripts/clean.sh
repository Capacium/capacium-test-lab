#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"
log "Cleaning Gemini CLI skills..."
rm -rf /root/.gemini/skills/*
log_ok "Gemini CLI clean complete"
