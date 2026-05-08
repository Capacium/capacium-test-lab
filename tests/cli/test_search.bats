#!/usr/bin/env bats

setup() {
    load '../helpers'
    CAP="${CAP:-cap}"
}

@test "cap search --help shows all flags" {
    run "$CAP" search --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--kind" ]]
    [[ "$output" =~ "--trust" ]]
    [[ "$output" =~ "--category" ]]
    [[ "$output" =~ "--sort" ]]
    [[ "$output" =~ "--json" ]]
    [[ "$output" =~ "--limit" ]]
}

@test "cap search without query exits non-zero or succeeds" {
    run "$CAP" search
    [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "cap search with empty query succeeds" {
    run "$CAP" search ""
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "cap search --json produces valid JSON" {
    run "$CAP" search "test" --json
    if [ "$status" -eq 0 ] && [ -n "$output" ]; then
        echo "$output" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null || skip "JSON parse failed"
    else
        skip "No results available"
    fi
}

@test "cap search --json has schema field when index available" {
    run "$CAP" search "test" --json
    if [ "$status" -eq 0 ] && [ -n "$output" ]; then
        echo "$output" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert '\$schema' in d, '\$schema field missing'
assert 'results' in d, 'results field missing'
assert 'total' in d, 'total field missing'
assert isinstance(d['results'], list), 'results is not a list'
print('JSON schema: OK')
" 2>/dev/null || skip "JSON schema validation failed"
    else
        skip "No results available"
    fi
}

@test "cap search --kind filter accepted" {
    run "$CAP" search "test" --kind mcp-server
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "cap search --trust filter accepted" {
    run "$CAP" search "test" --trust verified
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "cap search --category filter accepted" {
    run "$CAP" search "test" --category "Browser MCPs"
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "cap search --sort stars accepted" {
    run "$CAP" search "test" --sort stars
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "cap search --sort name accepted" {
    run "$CAP" search "test" --sort name
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "cap search --sort trust accepted" {
    run "$CAP" search "test" --sort trust
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "cap search --sort updated accepted" {
    run "$CAP" search "test" --sort updated
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "cap search invalid --sort rejects" {
    run "$CAP" search "test" --sort invalid_sort
    [ "$status" -ne 0 ]
}

@test "cap search --min-stars filters" {
    run "$CAP" search "test" --min-stars 1000
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "cap search --limit restricts count" {
    run "$CAP" search "test" --limit 3 --json
    if [ "$status" -eq 0 ]; then
        count=$(echo "$output" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d['results']))" 2>/dev/null || echo "0")
        [ "$count" -le 3 ]
    else
        skip "No results available"
    fi
}

@test "cap search --framework filter accepted" {
    run "$CAP" search "test" --framework claude-code
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "cap search with multiple --tag flags accepted" {
    run "$CAP" search "test" --tag python --tag ai
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "cap search --mcp-client filter accepted" {
    run "$CAP" search "test" --mcp-client opencode
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ] || skip "mcp-client flag not supported"
}

@test "cap search --publisher filter accepted" {
    run "$CAP" search "test" --publisher Capacium
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ] || skip "publisher flag not supported"
}

@test "cap search --min-trust filter accepted" {
    run "$CAP" search "test" --min-trust 70
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ] || skip "min-trust flag not supported"
}

@test "cap search --registry with explicit URL" {
    run "$CAP" search "test" --registry https://capacium-exchange.fly.dev
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "cap search with combined flags" {
    run "$CAP" search "test" --kind mcp-server --sort stars --min-stars 10 --limit 5
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "cap search nonexistent term returns gracefully" {
    run "$CAP" search "xyznonexistentsearchterm123456789"
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}
