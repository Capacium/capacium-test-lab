#!/usr/bin/env bash

# BATS helper — shared setup for all test-lab CLI tests
# Usage: load '../helpers' in setup()

# Resolve test-lab root directory (stable across BATS versions)
TEST_LAB_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
FIXTURES_DIR="$TEST_LAB_ROOT/fixtures"

export TEST_LAB_ROOT FIXTURES_DIR

# All capability kinds with existing fixtures — auto-discovered from fixtures.json
# when available, falling back to hardcoded list
_resolve_kinds() {
    if [ -f "$TEST_LAB_ROOT/fixtures.json" ]; then
        python3 -c "import json; d=json.load(open('$TEST_LAB_ROOT/fixtures.json')); print(' '.join(k['name'] for k in d))" 2>/dev/null
    else
        echo "test-skill test-mcp-server test-tool test-prompt test-template test-workflow test-connector-pack test-runtimes-skill test-broken-manifest test-dependency test-bundle test-signed-cap"
    fi
}
ALL_CAP_KINDS="$(_resolve_kinds)"

if [ -d "$HOME/.opencode/skills" ]; then
    SKILLS_DIR="$HOME/.opencode/skills"
elif [ -d "$HOME/.claude/skills" ]; then
    SKILLS_DIR="$HOME/.claude/skills"
else
    SKILLS_DIR="$HOME/.opencode/skills"
fi
export SKILLS_DIR

cap_cleanup() {
    for name in $ALL_CAP_KINDS; do
        "$CAP" remove "cap/$name" --force &>/dev/null || true
    done
    "$CAP" remove cap/test-signed-cap --force &>/dev/null || true
    "$CAP" remove cap/nonexistent --force &>/dev/null || true
}

cap_install() {
    local name="$1"
    local extra_args="${2:-}"
    "$CAP" install "cap/$name" --source "$FIXTURES_DIR/$name" --yes $extra_args
}

cap_remove() {
    local name="$1"
    "$CAP" remove "cap/$name" --force &>/dev/null || true
}
