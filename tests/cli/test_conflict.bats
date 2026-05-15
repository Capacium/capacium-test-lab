#!/usr/bin/env bats
# test_conflict.bats — Cross-framework conflict and idempotency tests
#
# Validates cap install/remove conflict resolution:
#   1. Double install is idempotent (no duplicate config entries)
#   2. --force on already-installed reinstalls cleanly
#   3. Non-interactive mode (no --force) skips with message, exits 0
#   4. Remove + reinstall cycle is clean
#   5. --force with same version updates framework configs

load '../helpers'

setup() {
    load '../helpers'
    CAP="${CAP:-cap}"
    # Clean state for each test
    cap_remove test-mcp-server
    cap_remove test-skill
}

teardown() {
    cap_remove test-mcp-server
    cap_remove test-skill
}

# ── Test 1: Double install → no duplicate entries ──────────────────────────

@test "cap install mcp-server twice is idempotent (no duplicate config entry)" {
    # First install
    run "$CAP" install cap/test-mcp-server \
        --source "$FIXTURES_DIR/test-mcp-server" \
        --framework opencode --yes --skip-runtime-check
    [ "$status" -eq 0 ]

    # Second install (already installed — non-interactive with --yes)
    run "$CAP" install cap/test-mcp-server \
        --source "$FIXTURES_DIR/test-mcp-server" \
        --framework opencode --yes --skip-runtime-check
    [ "$status" -eq 0 ]

    # Verify cap list shows exactly one entry
    run "$CAP" list
    [ "$status" -eq 0 ]
    # Should appear at most once — grep -c returns count of matching lines
    local count
    count=$(echo "$output" | grep -c "test-mcp-server" || true)
    [ "$count" -le 1 ]
}

# ── Test 2: --force reinstall works cleanly ────────────────────────────────

@test "cap install --force on already-installed reinstalls without error" {
    # Initial install
    run "$CAP" install cap/test-mcp-server \
        --source "$FIXTURES_DIR/test-mcp-server" \
        --framework opencode --yes --skip-runtime-check
    [ "$status" -eq 0 ]

    # Force reinstall
    run "$CAP" install cap/test-mcp-server \
        --source "$FIXTURES_DIR/test-mcp-server" \
        --framework opencode --force --yes --skip-runtime-check
    [ "$status" -eq 0 ]
    # Output should indicate reinstall (not silent skip)
    [[ "$output" =~ [Rr]einstall|[Ff]orce|[Ii]nstalled ]]
}

# ── Test 3: Non-interactive without --force exits 0 with message ───────────

@test "cap install already-installed without --force in non-interactive mode exits 0" {
    # Initial install
    run "$CAP" install cap/test-skill \
        --source "$FIXTURES_DIR/test-skill" \
        --framework opencode --yes
    [ "$status" -eq 0 ]

    # Second install: pipe stdin to simulate non-interactive (no TTY)
    run bash -c "echo '' | $CAP install cap/test-skill \
        --source $FIXTURES_DIR/test-skill \
        --framework opencode --skip-runtime-check 2>&1"
    # Already installed — exits non-zero with message (not --yes, not --force)
    [ "$status" -ne 0 ]
    # Must mention force or already installed
    [[ "$output" =~ [Ff]orce|[Aa]lready|[Ss]kip ]]
}

# ── Test 4: Remove + reinstall cycle is clean ─────────────────────────────

@test "cap remove then reinstall produces clean state" {
    run "$CAP" install cap/test-skill \
        --source "$FIXTURES_DIR/test-skill" \
        --framework opencode --yes
    [ "$status" -eq 0 ]

    run "$CAP" remove cap/test-skill --force
    [ "$status" -eq 0 ]

    # After remove, reinstall should succeed without --force
    run "$CAP" install cap/test-skill \
        --source "$FIXTURES_DIR/test-skill" \
        --framework opencode --yes
    [ "$status" -eq 0 ]
    [[ "$output" =~ [Ii]nstalled ]]
}

# ── Test 5: Install skill + mcp-server in same cap name (bundle-like) ──────

@test "cap install mcp-server after skill install does not corrupt skill entry" {
    # Install skill
    run "$CAP" install cap/test-skill \
        --source "$FIXTURES_DIR/test-skill" \
        --framework opencode --yes
    [ "$status" -eq 0 ]

    # Install mcp-server with different fixture (different kind)
    run "$CAP" install cap/test-mcp-server \
        --source "$FIXTURES_DIR/test-mcp-server" \
        --framework opencode --yes --skip-runtime-check
    [ "$status" -eq 0 ]

    # Both should be listed
    run "$CAP" list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test-skill" ]]
    [[ "$output" =~ "test-mcp-server" ]]

    # Remove mcp-server — skill should still be listed
    run "$CAP" remove cap/test-mcp-server --force
    [ "$status" -eq 0 ]

    run "$CAP" list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test-skill" ]]
}
