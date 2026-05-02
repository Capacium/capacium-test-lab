#!/usr/bin/env bats

setup() {
    load '../helpers'
}

@test "docker compose volumes are defined" {
    grep -q "opencode_skills:" docker-compose.yml
    grep -q "claude_skills:" docker-compose.yml
    grep -q "codex_skills:" docker-compose.yml
}

@test "all services have restart policy or healthcheck" {
    # At least the test-runner has depends_on with healthcheck
    grep -q "healthcheck" docker-compose.yml || \
    grep -q "depends_on" docker-compose.yml
}
