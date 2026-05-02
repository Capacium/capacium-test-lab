#!/usr/bin/env bats

setup() {
    load '../helpers'
}

@test "claude-code framework directory exists" {
    [ -d "frameworks/claude-code" ]
}

@test "claude-code Dockerfile exists and is valid" {
    [ -f "frameworks/claude-code/Dockerfile" ]
    grep -q "FROM" "frameworks/claude-code/Dockerfile"
}

@test "claude-code lifecycle scripts exist" {
    for script in install verify test clean _lib; do
        [ -f "frameworks/claude-code/scripts/${script}.sh" ]
        [ -x "frameworks/claude-code/scripts/${script}.sh" ]
    done
}

@test "claude-code scripts have no syntax errors" {
    for script in install verify test clean; do
        bash -n "frameworks/claude-code/scripts/${script}.sh"
    done
}
