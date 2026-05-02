#!/usr/bin/env bash
set -euo pipefail

FRAMEWORK="${1:-}"
CAPABILITY="${2:-}"
EXIT_CODE=0

usage() {
    echo "Usage: test-framework.sh <framework> <capability>"
    echo "  framework: opencode | claude-code | codex-cli | gemini-cli | continue"
    echo "  capability: test-skill | test-mcp-server | test-tool | test-bundle"
    echo ""
    echo "Runs a capability test against a framework in Docker Compose."
    echo "Exit 0 = PASS, Exit 1 = FAIL"
    exit 1
}

[ -z "$FRAMEWORK" ] && usage
[ -z "$CAPABILITY" ] && usage

FW_DIR="frameworks/$FRAMEWORK"
[ ! -d "$FW_DIR" ] && echo "ERROR: Framework '$FRAMEWORK' not found at $FW_DIR" && exit 1

echo "=== Capacium Test Lab ==="
echo "Framework:  $FRAMEWORK"
echo "Capability: $CAPABILITY"
echo "========================="

# Step 1: Verify framework is running
if docker compose ps --status running "$FRAMEWORK" 2>/dev/null | grep -q "$FRAMEWORK"; then
    echo "✓ $FRAMEWORK container running"
else
    echo "→ Starting $FRAMEWORK container..."
    docker compose up -d "$FRAMEWORK" 2>/dev/null || {
        echo "✗ Failed to start $FRAMEWORK"
        exit 1
    }
fi

# Step 2: Run framework verify script
echo "→ Running verify.sh..."
docker compose exec -T "$FRAMEWORK" /scripts/verify.sh 2>/dev/null || {
    echo "⚠ verify.sh failed (non-fatal for framework validation)"
}

# Step 3: Run capability test
echo "→ Testing capability installation..."
if docker compose exec -T "$FRAMEWORK" /scripts/test.sh 2>/dev/null; then
    echo "✓ Capability test PASSED"
else
    echo "✗ Capability test FAILED"
    EXIT_CODE=1
fi

# Step 4: Clean up
echo "→ Cleaning up..."
docker compose exec -T "$FRAMEWORK" /scripts/clean.sh 2>/dev/null || true

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "=== RESULT: PASS ==="
else
    echo ""
    echo "=== RESULT: FAIL ==="
fi

exit $EXIT_CODE
