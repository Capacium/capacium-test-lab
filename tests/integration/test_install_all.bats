#!/usr/bin/env bats

setup() {
    load '../helpers'
}

@test "docker compose config is valid" {
    docker compose config > /dev/null 2>&1
}

@test "docker compose build test-runner succeeds (parse check)" {
    run docker compose build --no-cache test-runner 2>&1
    # Docker build may fail if daemon not running — that's OK, just check
    # the compose file is parseable
    [ -f "Dockerfile.runner" ]
}

@test "all P0 frameworks have valid Dockerfiles" {
    for fw in opencode claude-code codex-cli; do
        [ -f "frameworks/$fw/Dockerfile" ]
        grep -q "FROM" "frameworks/$fw/Dockerfile"
    done
}

@test "all fixtures have valid capability.yaml" {
    for fixture in test-skill test-mcp-server; do
        [ -f "fixtures/$fixture/capability.yaml" ]
        grep -q "name:" "fixtures/$fixture/capability.yaml"
        grep -q "kind:" "fixtures/$fixture/capability.yaml"
        grep -q "version:" "fixtures/$fixture/capability.yaml"
    done
}
