#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"
log "Cleaning Continue.dev skills..."
rm -rf /root/.continue/skills/*
log_ok "Continue.dev clean complete"
