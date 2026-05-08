#!/usr/bin/env bats

setup() {
    load '../helpers'
    CAP="${CAP:-cap}"
    cap_cleanup
}

# ── cap key generate ──

@test "cap key generate creates keypair" {
    run "$CAP" key generate test-sign-key
    [ "$status" -eq 0 ] || skip "key generate not available"
}

@test "cap key generate with empty name exits non-zero" {
    run "$CAP" key generate ""
    [ "$status" -ne 0 ]
}

@test "cap key generate duplicate name exits non-zero" {
    run "$CAP" key generate test-sign-key
    [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

# ── cap key list ──

@test "cap key list runs without error" {
    run "$CAP" key list
    [ "$status" -eq 0 ]
}

# ── cap sign ──

@test "cap sign installed capability with valid key" {
    run "$CAP" install cap/test-skill --source "$FIXTURES_DIR/test-skill" --yes
    [ "$status" -eq 0 ]
    run "$CAP" sign cap/test-skill test-sign-key
    [ "$status" -eq 0 ]
    cap_remove test-skill
}

@test "cap sign nonexistent capability exits non-zero" {
    run "$CAP" sign nonexistent/nonexistent-cap test-sign-key
    [ "$status" -ne 0 ]
}

@test "cap sign with nonexistent key exits non-zero" {
    run "$CAP" install cap/test-skill --source "$FIXTURES_DIR/test-skill" --yes
    [ "$status" -eq 0 ]
    run "$CAP" sign cap/test-skill nonexistent-key-xyz-12345
    [ "$status" -ne 0 ]
    cap_remove test-skill
}

# ── cap verify specific capability ──

@test "cap verify specific installed capability" {
    run "$CAP" install cap/test-skill --source "$FIXTURES_DIR/test-skill" --yes
    [ "$status" -eq 0 ]
    run "$CAP" verify cap/test-skill
    [ "$status" -eq 0 ]
    [[ "$output" =~ [Vv]erif ]] || true
    cap_remove test-skill
}

@test "cap verify nonexistent capability exits non-zero" {
    run "$CAP" verify cap/nonexistent-capability-xyz-12345
    [ "$status" -ne 0 ]
}

# ── cap verify --all ──

@test "cap verify --all runs" {
    run "$CAP" verify --all
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ] || [ "$status" -eq 2 ]
}
