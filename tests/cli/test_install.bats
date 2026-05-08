#!/usr/bin/env bats

setup() {
    load '../helpers'
    CAP="${CAP:-cap}"
    cap_cleanup
}

# ── Happy path: install from local path ──

@test "cap install from local path (test-skill)" {
    run "$CAP" install cap/test-skill --source "$FIXTURES_DIR/test-skill" --yes --all-frameworks
    [ "$status" -eq 0 ]
    [[ "$output" =~ [Ii]nstalled ]]
    run "$CAP" list
    [[ "$output" =~ "test-skill" ]]
    cap_remove test-skill
}

@test "cap install from local path (test-mcp-server)" {
    run "$CAP" install cap/test-mcp-server --source "$FIXTURES_DIR/test-mcp-server" --yes --skip-runtime-check
    [ "$status" -eq 0 ]
    cap_remove test-mcp-server
}

# ── Framework filtering ──

@test "cap install --framework opencode" {
    run "$CAP" install cap/test-skill --source "$FIXTURES_DIR/test-skill" --framework opencode --yes
    [ "$status" -eq 0 ]
    cap_remove test-skill
}

@test "cap install --framework claude-code" {
    run "$CAP" install cap/test-skill --source "$FIXTURES_DIR/test-skill" --framework claude-code --yes
    [ "$status" -eq 0 ]
    cap_remove test-skill
}

# ── Flags ──

@test "cap install --all-frameworks" {
    run "$CAP" install cap/test-skill --source "$FIXTURES_DIR/test-skill" --all-frameworks --yes
    [ "$status" -eq 0 ]
    cap_remove test-skill
}

@test "cap install --skip-runtime-check" {
    run "$CAP" install cap/test-runtimes-skill --source "$FIXTURES_DIR/test-runtimes-skill" --yes --skip-runtime-check
    [ "$status" -eq 0 ]
    cap_remove test-runtimes-skill
}

@test "cap install --no-lock" {
    run "$CAP" install cap/test-skill --source "$FIXTURES_DIR/test-skill" --yes --no-lock
    [ "$status" -eq 0 ]
    cap_remove test-skill
}

@test "cap install --yes non-interactive" {
    run "$CAP" install cap/test-skill --source "$FIXTURES_DIR/test-skill" --yes
    [ "$status" -eq 0 ]
    cap_remove test-skill
}

# ── Error paths ──

@test "cap install without arguments exits non-zero" {
    run "$CAP" install
    [ "$status" -ne 0 ]
}

@test "cap install with invalid source path exits non-zero" {
    run "$CAP" install cap/nonexistent --source "/nonexistent/path/xyz" --yes
    [ "$status" -ne 0 ]
}

@test "cap install with missing capability.yaml exits non-zero" {
    run "$CAP" install cap/nonexistent --source "/nonexistent/path/no-manifest-here" --yes
    [ "$status" -ne 0 ]
}

@test "cap install from tarball root fixture" {
    run "$CAP" install cap/nonexistent --source "/tmp/nonexistent-dir-no-manifest-here-xyz" --yes
    [ "$status" -ne 0 ]
}

# ── cap list verification after install ──

@test "cap list shows installed capability after install" {
    run "$CAP" install cap/test-skill --source "$FIXTURES_DIR/test-skill" --yes
    [ "$status" -eq 0 ]
    run "$CAP" list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test-skill" ]]
    cap_remove test-skill
}

# ── Multi-kind installs ──

@test "cap install tool kind" {
    run "$CAP" install cap/test-tool --source "$FIXTURES_DIR/test-tool" --yes
    [ "$status" -eq 0 ]
    cap_remove test-tool
}

@test "cap install prompt kind" {
    run "$CAP" install cap/test-prompt --source "$FIXTURES_DIR/test-prompt" --yes
    [ "$status" -eq 0 ]
    cap_remove test-prompt
}

@test "cap install template kind" {
    run "$CAP" install cap/test-template --source "$FIXTURES_DIR/test-template" --yes
    [ "$status" -eq 0 ]
    cap_remove test-template
}

@test "cap install workflow kind" {
    run "$CAP" install cap/test-workflow --source "$FIXTURES_DIR/test-workflow" --yes
    [ "$status" -eq 0 ]
    cap_remove test-workflow
}

@test "cap install connector-pack kind" {
    run "$CAP" install cap/test-connector-pack --source "$FIXTURES_DIR/test-connector-pack" --yes
    [ "$status" -eq 0 ]
    cap_remove test-connector-pack
}
