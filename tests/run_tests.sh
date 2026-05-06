#!/usr/bin/env bash
set -euo pipefail

SUITE="${1:-all}"
BATS_DIR="/tmp/bats-core"
PASS=0
FAIL=0

# Auto-install BATS if not found
setup_bats() {
    if ! command -v bats &>/dev/null; then
        echo "→ Installing BATS..."
        if [ -d "$BATS_DIR" ]; then
            export PATH="$BATS_DIR/bin:$PATH"
        else
            git clone --depth 1 https://github.com/bats-core/bats-core.git "$BATS_DIR" 2>/dev/null
            export PATH="$BATS_DIR/bin:$PATH"
        fi
    fi
}

run_suite() {
    local dir="$1"
    echo ""
    echo "=== $dir Tests ==="
    if bats --recursive "$dir" 2>&1; then
        let ++PASS
    else
        let ++FAIL
    fi
}

setup_bats

cd "$(dirname "$0")/.."

case "$SUITE" in
    unit)
        run_suite "tests/unit"
        ;;
    integration)
        run_suite "tests/integration"
        ;;
    smoke)
        run_suite "tests/smoke"
        ;;
    cli)
        run_suite "tests/cli"
        ;;
    all)
        for suite in unit integration smoke cli; do
            run_suite "tests/$suite"
        done
        ;;
    *)
        echo "Usage: run_tests.sh [unit|integration|smoke|cli|all]"
        exit 1
        ;;
esac

echo ""
echo "=== Summary ==="
echo "Pass: $PASS  Fail: $FAIL"
echo ""

[ "$FAIL" -eq 0 ] || exit 1
