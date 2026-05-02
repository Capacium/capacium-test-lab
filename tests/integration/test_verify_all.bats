#!/usr/bin/env bats

setup() {
    load '../helpers'
}

@test "test-framework.sh exists and is executable" {
    [ -f "scripts/test-framework.sh" ]
    [ -x "scripts/test-framework.sh" ]
}

@test "test-framework.sh shows usage without args" {
    run bash scripts/test-framework.sh
    [ "$status" -eq 1 ]
}

@test "provision.sh exists and is executable" {
    [ -f "scripts/provision.sh" ]
    [ -x "scripts/provision.sh" ]
}

@test "ci-entrypoint.sh exists and is executable" {
    [ -f "scripts/ci-entrypoint.sh" ]
    [ -x "scripts/ci-entrypoint.sh" ]
}
