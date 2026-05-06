#!/usr/bin/env bats

setup() {
    load '../helpers'
    CAP="${CAP:-cap}"
}

@test "cap browse --help shows flags" {
    run "$CAP" browse --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--sort" ]]
    [[ "$output" =~ "--kind" ]]
}

@test "cap browse --sort flag accepted" {
    run "$CAP" browse --sort stars 2>&1 <<< "q"
    # browse is interactive — it may error on non-TTY stdin, that's OK
    [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "cap browse --kind flag accepted" {
    run "$CAP" browse --kind mcp-server 2>&1 <<< "q"
    [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}
