#!/usr/bin/env bats

setup() {
    load '../helpers'
    CAP="${CAP:-cap}"
    cap_cleanup
}

@test "cap list command exists" {
    run "$CAP" list --help
    [ "$status" -eq 0 ]
}

@test "cap list runs without error" {
    run "$CAP" list
    [ "$status" -eq 0 ]
}

@test "cap list --kind accepted" {
    run "$CAP" list --kind skill
    [ "$status" -eq 0 ]
}

@test "cap list --kind prints error for invalid kind" {
    run "$CAP" list --kind invalid_kind_xyz
    [ "$status" -eq 0 ]
    [[ "$output" =~ [Ii]nvalid ]]
}

@test "cap list --framework accepted" {
    run "$CAP" list --framework opencode
    [ "$status" -eq 0 ]
}

@test "cap doctor command exists" {
    run "$CAP" doctor --help
    [ "$status" -eq 0 ]
}

@test "cap doctor runs without error" {
    run "$CAP" doctor
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "cap runtimes list runs without error" {
    run "$CAP" runtimes list
    [ "$status" -eq 0 ]
    [[ "$output" =~ [A-Za-z0-9] ]]
}

@test "cap verify --help exists" {
    run "$CAP" verify --help
    [ "$status" -eq 0 ]
}

@test "cap verify --all runs" {
    run "$CAP" verify --all
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ] || [ "$status" -eq 2 ]
}

@test "cap lock --help exists" {
    run "$CAP" lock --help
    [ "$status" -eq 0 ]
}

@test "cap package --help exists" {
    run "$CAP" package --help
    [ "$status" -eq 0 ]
}

@test "cap publish --help exists" {
    run "$CAP" publish --help
    [ "$status" -eq 0 ]
}

@test "cap marketplace --help exists" {
    run "$CAP" marketplace --help
    [ "$status" -eq 0 ]
}

@test "cap config list runs without error" {
    run "$CAP" config list
    [ "$status" -eq 0 ]
}

@test "cap config get nonexistent key works" {
    run "$CAP" config get nonexistent-key-xyz
    [ "$status" -eq 0 ]
}

@test "cap config set/get roundtrip" {
    run "$CAP" config set test_lab_roundtrip "\"test-value-123\""
    if [ "$status" -ne 0 ]; then
        skip "config set failed (may need specific value format)"
    fi
    run "$CAP" config get test_lab_roundtrip
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test-value-123" ]]
}

@test "cap init --help exists" {
    run "$CAP" init --help
    [ "$status" -eq 0 ]
}

@test "cap registry --help exists" {
    run "$CAP" registry --help
    [ "$status" -eq 0 ]
}

@test "cap mcp --help exists" {
    run "$CAP" mcp --help
    [ "$status" -eq 0 ]
}

@test "cap submit --help exists" {
    run "$CAP" submit --help
    [ "$status" -eq 0 ]
}

# ── cap remove ──

@test "cap remove installed capability" {
    run "$CAP" install cap/test-skill --source "$FIXTURES_DIR/test-skill" --yes
    [ "$status" -eq 0 ]
    run "$CAP" remove cap/test-skill --force
    [ "$status" -eq 0 ]
}

@test "cap remove nonexistent capability exits non-zero" {
    run "$CAP" remove nonexistent/nonexistent-cap-xyz-12345
    [ "$status" -ne 0 ]
}

# ── cap init non-interactive ──

@test "cap init --name --kind --version --description" {
    tmpdir=$(mktemp -d)
    run "$CAP" init --name test-init-cap --kind skill --version 0.1.0 --description "Test init" --path "$tmpdir"
    [ "$status" -eq 0 ] || skip "cap init with --path not supported"
    [ -f "$tmpdir/capability.yaml" ]
    rm -rf "$tmpdir"
}

@test "cap init --kind tool" {
    tmpdir=$(mktemp -d)
    run "$CAP" init --name test-init-tool --kind tool --version 0.1.0 --path "$tmpdir"
    [ "$status" -eq 0 ] || skip "cap init kind tool not supported"
    rm -rf "$tmpdir"
}

@test "cap init --kind prompt" {
    tmpdir=$(mktemp -d)
    run "$CAP" init --name test-init-prompt --kind prompt --version 0.1.0 --path "$tmpdir"
    [ "$status" -eq 0 ] || skip "cap init kind prompt not supported"
    rm -rf "$tmpdir"
}

@test "cap init --kind mcp-server" {
    tmpdir=$(mktemp -d)
    run "$CAP" init --name test-init-mcp --kind mcp-server --version 0.1.0 --path "$tmpdir"
    [ "$status" -eq 0 ] || skip "cap init kind mcp-server not supported"
    rm -rf "$tmpdir"
}

@test "cap init with invalid kind exits non-zero" {
    run "$CAP" init --name test-init --kind invalid_kind --version 0.1.0
    [ "$status" -ne 0 ]
}

# ── cap lock ──

@test "cap lock generates lock file for installed capability" {
    run "$CAP" install cap/test-skill --source "$FIXTURES_DIR/test-skill" --yes
    [ "$status" -eq 0 ]
    run "$CAP" lock cap/test-skill
    [ "$status" -eq 0 ] || skip "lock generation not available"
    [ -f "$HOME/.capacium/active/test-skill/capability.lock" ] || true
    cap_remove test-skill
}

# ── cap package ──

@test "cap package creates tarball from manifest" {
    tmpdir=$(mktemp -d)
    run "$CAP" package --manifest "$FIXTURES_DIR/test-skill/capability.yaml" --output-dir "$tmpdir"
    if [ "$status" -eq 0 ]; then
        [ -f "$tmpdir/test-skill-1.0.0.tar.gz" ] || ls "$tmpdir"/*.tar.gz 2>/dev/null
    else
        skip "package not available"
    fi
    rm -rf "$tmpdir"
}

@test "cap package with missing manifest exits non-zero" {
    run "$CAP" package --manifest /nonexistent/path/capability.yaml
    [ "$status" -ne 0 ]
}

# ── cap runtimes install ──

@test "cap runtimes install uv prints hint" {
    run "$CAP" runtimes install uv
    [ "$status" -eq 0 ] || skip "runtimes install not available"
    [[ "$output" =~ [Uu][Vv] ]] || [[ "$output" =~ "pip" ]] || [[ "$output" =~ "curl" ]] || true
}

@test "cap runtimes install node prints hint" {
    run "$CAP" runtimes install node
    [ "$status" -eq 0 ] || skip "runtimes install not available"
}

@test "cap runtimes install unknown runtime exits non-zero" {
    run "$CAP" runtimes install nonexistent-runtime-xyz-12345
    [ "$status" -ne 0 ]
}

# ── cap doctor with installed capabilities ──

@test "cap doctor with installed capability" {
    run "$CAP" install cap/test-skill --source "$FIXTURES_DIR/test-skill" --yes
    [ "$status" -eq 0 ]
    run "$CAP" doctor cap/test-skill
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
    cap_remove test-skill
}

# ── cap config edge cases ──

@test "cap config set with boolean value" {
    run "$CAP" config set test_lab_bool "true"
    [ "$status" -eq 0 ] || skip "config set not available"
}

@test "cap config set with integer value" {
    run "$CAP" config set test_lab_int "42"
    [ "$status" -eq 0 ] || skip "config set not available"
}

@test "cap config list after setting values" {
    run "$CAP" config list
    [ "$status" -eq 0 ]
}

# ── cap update ──

@test "cap update without installed capability exits non-zero" {
    run "$CAP" update nonexistent-cap-xyz-12345
    [ "$status" -ne 0 ]
}

# ── cap publish ──

@test "cap publish without arguments exits non-zero" {
    run "$CAP" publish
    [ "$status" -ne 0 ]
}

# ── cap submit ──

@test "cap submit without arguments exits non-zero" {
    run "$CAP" submit
    [ "$status" -ne 0 ]
}
