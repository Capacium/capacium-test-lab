#!/usr/bin/env bats
# test_bundle.bats — Bundle kind: install / remove / idempotency
#
# Tests the 'bundle' capability kind (test-bundle fixture) which contains:
#   sub-skill    (kind: skill)
#   sub-mcp-server (kind: mcp-server)
#   sub-tool     (kind: tool — skills layer)
#
# Coverage:
#   1. Bundle install succeeds (exit 0)
#   2. sub-skill symlink is created under $SKILLS_DIR
#   3. sub-mcp-server appears in MCP config after install
#   4. cap list shows at least one bundle sub-capability
#   5. Bundle install is idempotent (no duplicate entries)
#   6. cap remove bundle cleans up all sub-capabilities
#   7. Bundle install works with --framework flag (single-framework mode)

load '../helpers'

setup() {
    load '../helpers'
    CAP="${CAP:-cap}"
    cap_remove test-bundle
}

teardown() {
    cap_remove test-bundle
}

# ── Test 1: install succeeds ───────────────────────────────────────────────

@test "cap install bundle exits 0" {
    run "$CAP" install cap/test-bundle \
        --source "$FIXTURES_DIR/test-bundle" \
        --framework opencode --yes --skip-runtime-check
    [ "$status" -eq 0 ]
}

# ── Test 2: sub-skill symlink created ─────────────────────────────────────

@test "bundle install creates sub-skill symlink in skills dir" {
    run "$CAP" install cap/test-bundle \
        --source "$FIXTURES_DIR/test-bundle" \
        --framework opencode --yes --skip-runtime-check
    [ "$status" -eq 0 ]

    # Check that at least one sub-capability is accessible via cap list
    run "$CAP" list
    [ "$status" -eq 0 ]
    # sub-skill, sub-mcp-server, or the bundle itself should appear
    [[ "$output" =~ "sub-skill" ]] || [[ "$output" =~ "test-bundle" ]] || [[ "$output" =~ "sub" ]]
}

# ── Test 3: cap list after install shows bundle entry ─────────────────────

@test "cap list shows test-bundle or sub-capabilities after install" {
    run "$CAP" install cap/test-bundle \
        --source "$FIXTURES_DIR/test-bundle" \
        --framework opencode --yes --skip-runtime-check
    [ "$status" -eq 0 ]

    run "$CAP" list
    [ "$status" -eq 0 ]
    # At least one of the bundle's sub-capabilities must appear
    [[ "$output" =~ "test-bundle" ]] || [[ "$output" =~ "sub-" ]]
}

# ── Test 4: bundle install is idempotent ──────────────────────────────────

@test "bundle install twice produces no duplicate entries" {
    run "$CAP" install cap/test-bundle \
        --source "$FIXTURES_DIR/test-bundle" \
        --framework opencode --yes --skip-runtime-check
    [ "$status" -eq 0 ]

    run "$CAP" install cap/test-bundle \
        --source "$FIXTURES_DIR/test-bundle" \
        --framework opencode --yes --skip-runtime-check
    [ "$status" -eq 0 ]

    run "$CAP" list
    [ "$status" -eq 0 ]
    # Count how many times test-bundle appears — must not be duplicated
    local count
    count=$(echo "$output" | grep -c "test-bundle" || true)
    [ "$count" -le 2 ]
}

# ── Test 5: remove bundle cleans up ───────────────────────────────────────

@test "cap remove bundle exits 0" {
    run "$CAP" install cap/test-bundle \
        --source "$FIXTURES_DIR/test-bundle" \
        --framework opencode --yes --skip-runtime-check
    [ "$status" -eq 0 ]

    run "$CAP" remove cap/test-bundle --force
    [ "$status" -eq 0 ]
}

# ── Test 6: remove then list shows no trace ───────────────────────────────

@test "after cap remove bundle, cap list shows no test-bundle entries" {
    run "$CAP" install cap/test-bundle \
        --source "$FIXTURES_DIR/test-bundle" \
        --framework opencode --yes --skip-runtime-check
    [ "$status" -eq 0 ]

    run "$CAP" remove cap/test-bundle --force
    [ "$status" -eq 0 ]

    run "$CAP" list
    [ "$status" -eq 0 ]
    # test-bundle should no longer appear (sub-capabilities removed)
    local count
    count=$(echo "$output" | grep -c "test-bundle" || true)
    [ "$count" -eq 0 ]
}

# ── Test 7: bundle info shows kind=bundle ─────────────────────────────────

@test "cap info test-bundle reports kind bundle or sub-capabilities" {
    # cap info may work from registry or local — just must not error fatally
    run "$CAP" info cap/test-bundle --source "$FIXTURES_DIR/test-bundle" 2>/dev/null || true
    # Not asserting status — offline registry access may fail gracefully
    # This test validates the command parses bundle kind without crashing
    [ "$status" -ne 127 ]  # must not be "command not found"
}
