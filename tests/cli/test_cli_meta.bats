#!/usr/bin/env bats

setup() {
    load '../helpers'
    CAP="${CAP:-cap}"
}

@test "cap --version outputs semver" {
    run "$CAP" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "cap --help lists commands" {
    run "$CAP" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "search" ]]
    [[ "$output" =~ "install" ]]
    [[ "$output" =~ "browse" ]]
    [[ "$output" =~ "compare" ]]
    [[ "$output" =~ "update-index" ]]
}

@test "cap (no args) prints help and exits 0" {
    run "$CAP"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "usage" ]] || [[ "$output" =~ "Capacium" ]]
}

@test "cap invalid-command exits non-zero" {
    run "$CAP" nonexistent-command-xyz
    [ "$status" -ne 0 ]
}

@test "cap install without arguments exits non-zero" {
    run "$CAP" install
    [ "$status" -ne 0 ]
}

@test "cap update without arguments exits non-zero" {
    run "$CAP" update
    [ "$status" -ne 0 ]
}

@test "cap remove without arguments exits non-zero" {
    run "$CAP" remove
    [ "$status" -ne 0 ]
}
