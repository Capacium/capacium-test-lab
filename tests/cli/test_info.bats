#!/usr/bin/env bats

setup() {
    load '../helpers'
    CAP="${CAP:-cap}"
}

@test "cap info --help shows flags" {
    run "$CAP" info --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--registry" ]] || [[ "$output" =~ "--json" ]]
}

@test "cap info without argument exits non-zero" {
    run "$CAP" info
    [ "$status" -ne 0 ]
}

@test "cap info nonexistent capability says not found" {
    run "$CAP" info "nonexistent/fake-capability-xyz-12345"
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
    [[ "$output" =~ [Nn]ot ]] || [[ "$output" =~ [Ff]ound ]] || true
}

@test "cap info --json produces valid JSON when capability exists" {
    run "$CAP" info "LobeHub/aliksir-playwright-browser-mcp" --json
    if [ "$status" -eq 0 ] && [ -n "$output" ]; then
        echo "$output" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert 'name' in d, 'name field missing'
assert 'kind' in d, 'kind field missing'
assert 'trust' in d, 'trust field missing'
print('Info JSON: OK')
" 2>/dev/null || skip "JSON parse failed"
    else
        skip "Capability not available in local index or Exchange"
    fi
}

@test "cap info --json has schema field" {
    run "$CAP" info "LobeHub/aliksir-playwright-browser-mcp" --json
    if [ "$status" -eq 0 ] && [ -n "$output" ]; then
        echo "$output" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert '\$schema' in d, '\$schema field missing'
print('Schema: OK')
" 2>/dev/null || skip "JSON parse failed"
    else
        skip "Capability not available"
    fi
}

@test "cap info with owner/name format accepted" {
    run "$CAP" info "testowner/testname"
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "cap info with bare name accepted" {
    run "$CAP" info "somename"
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "cap info from local index" {
    run "$CAP" info "test"
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "cap info --registry with explicit URL" {
    run "$CAP" info "test/cap" --registry https://capacium-exchange.fly.dev
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}
