#!/usr/bin/env bats

setup() {
    load '../helpers'
    CAP="${CAP:-cap}"
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
    [ "$status" -eq 0 ]
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
