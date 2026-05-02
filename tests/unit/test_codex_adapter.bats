#!/usr/bin/env bats

setup() {
    load '../helpers'
}

@test "codex-cli framework directory exists" {
    [ -d "frameworks/codex-cli" ]
}

@test "codex-cli Dockerfile exists and is valid" {
    [ -f "frameworks/codex-cli/Dockerfile" ]
    grep -q "FROM" "frameworks/codex-cli/Dockerfile"
}

@test "codex-cli lifecycle scripts exist" {
    for script in install verify test clean _lib; do
        [ -f "frameworks/codex-cli/scripts/${script}.sh" ]
        [ -x "frameworks/codex-cli/scripts/${script}.sh" ]
    done
}

@test "codex-cli scripts have no syntax errors" {
    for script in install verify test clean; do
        bash -n "frameworks/codex-cli/scripts/${script}.sh"
    done
}
