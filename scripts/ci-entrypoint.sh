#!/usr/bin/env bash
set -euo pipefail

# CI entrypoint — runs test-framework.sh for each framework+capability combination
# Called from GitHub Actions matrix or locally with --local flag

FRAMEWORKS="${FRAMEWORKS:-opencode claude-code codex-cli}"
CAPABILITIES="${CAPABILITIES:-test-skill test-mcp-server}"

PASS=0
FAIL=0
RESULTS=""

log_result() {
    local fw="$1" cap="$2" result="$3"
    local line="$fw + $cap → $result"
    RESULTS="$RESULTS
$line"
    if [ "$result" = "PASS" ]; then
        let ++PASS
    else
        let ++FAIL
    fi
}

echo "=== Capacium Test Lab — CI Entrypoint ==="
echo ""

for fw in $FRAMEWORKS; do
    for cap in $CAPABILITIES; do
        echo "--- Testing $fw with $cap ---"
        if bash "$(dirname "$0")/test-framework.sh" "$fw" "$cap" 2>&1; then
            log_result "$fw" "$cap" "PASS"
        else
            log_result "$fw" "$cap" "FAIL"
        fi
        echo ""
    done
done

echo "=== Results ==="
echo "$RESULTS"
echo ""
echo "Pass: $PASS  Fail: $FAIL"
echo ""

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
