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

# Step 1: Ensure framework is running and healthy
echo "→ Waiting for $FRAMEWORK to be healthy..."
docker compose up -d "$FRAMEWORK" 2>/dev/null
docker compose wait "$FRAMEWORK" 2>/dev/null || {
    echo "✗ $FRAMEWORK container not healthy"
    docker compose logs "$FRAMEWORK" 2>/dev/null | tail -20
    exit 1
}
echo "✓ $FRAMEWORK healthy"

# Step 2: Verify agent CLI is installed (skip if container health covers this)
echo "→ Running verify.sh..."
docker compose exec -T "$FRAMEWORK" /scripts/verify.sh 2>/dev/null && echo "✓ verify.sh OK" || echo "⚠ verify.sh non-fatal"

# Step 3: Run capability test (passes fixture name as $1)
echo "→ Testing capability installation..."
if docker compose exec -T "$FRAMEWORK" /scripts/test.sh "$CAPABILITY" 2>/dev/null; then
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
