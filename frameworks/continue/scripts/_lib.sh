log()       { echo "[$(date +%H:%M:%S)] $*"; }
log_ok()    { echo "[$(date +%H:%M:%S)] ✓ $*"; }
log_warn()  { echo "[$(date +%H:%M:%S)] ⚠ $*" >&2; }
log_error() { echo "[$(date +%H:%M:%S)] ✗ $*" >&2; }

die() {
    log_error "$@"
    exit 1
}

check_fixture() {
    local fixture="${1:-}"
    [ -z "$fixture" ] && die "check_fixture: no fixture name provided"
    [ ! -d "/fixtures/$fixture" ] && die "Fixture '$fixture' not found at /fixtures/$fixture"
    [ ! -f "/fixtures/$fixture/capability.yaml" ] && die "Fixture '$fixture' missing capability.yaml"
}
