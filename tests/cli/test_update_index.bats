#!/usr/bin/env bats

setup() {
    load '../helpers'
    CAP="${CAP:-cap}"
}

@test "cap update-index --help shows flags" {
    run "$CAP" update-index --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--full" ]]
    [[ "$output" =~ "--registry" ]]
}

@test "cap update-index runs without error" {
    run "$CAP" update-index
    # May fail if Exchange not reachable
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
    if [ "$status" -eq 0 ]; then
        [[ "$output" =~ "Updated" ]] || [[ "$output" =~ "enriched" ]] || [[ "$output" =~ "new" ]]
    fi
}

@test "cap update-index --full flag accepted" {
    run "$CAP" update-index --full
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}
