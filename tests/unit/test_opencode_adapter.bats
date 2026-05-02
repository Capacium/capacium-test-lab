#!/usr/bin/env bats

setup() {
    load '../helpers'
}

@test "opencode framework directory exists" {
    [ -d "frameworks/opencode" ]
}

@test "opencode Dockerfile exists and is valid" {
    [ -f "frameworks/opencode/Dockerfile" ]
    grep -q "FROM" "frameworks/opencode/Dockerfile"
}

@test "opencode lifecycle scripts exist" {
    for script in install verify test clean _lib; do
        [ -f "frameworks/opencode/scripts/${script}.sh" ]
        [ -x "frameworks/opencode/scripts/${script}.sh" ]
    done
}

@test "opencode scripts have no syntax errors" {
    for script in install verify test clean; do
        bash -n "frameworks/opencode/scripts/${script}.sh"
    done
}
