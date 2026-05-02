# Shared helpers for framework lifecycle scripts

log()       { echo "[$(date +%H:%M:%S)] $*"; }
log_ok()    { echo "[$(date +%H:%M:%S)] ✓ $*"; }
log_warn()  { echo "[$(date +%H:%M:%S)] ⚠ $*" >&2; }
log_error() { echo "[$(date +%H:%M:%S)] ✗ $*" >&2; }
