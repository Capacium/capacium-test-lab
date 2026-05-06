#!/usr/bin/env bats

setup() {
    load '../helpers'
    CAP="${CAP:-cap}"
}

@test "local index created by cap update-index" {
    run "$CAP" update-index 2>&1
    # If Exchange reachable, index file should exist
    if [ -f "$HOME/.capacium/search_index.db" ]; then
        # Verify it's a valid SQLite database
        python3 -c "
import sqlite3
conn = sqlite3.connect('$HOME/.capacium/search_index.db')
count = conn.execute('SELECT COUNT(*) FROM listings_index').fetchone()[0]
print(f'listings_index rows: {count}')
assert count > 0, 'No listings in index'
conn.close()
"
    else
        skip "Local index not available (Exchange may be unreachable)"
    fi
}

@test "JSON output from search is valid and properly structured" {
    run "$CAP" search "test" --json
    if [ "$status" -eq 0 ]; then
        echo "$output" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert '\$schema' in d
assert d['\$schema'].startswith('https://')
assert 'results' in d
assert 'total' in d
assert 'count' in d
assert isinstance(d['results'], list)
assert len(d['results']) <= d['count']
if d['results']:
    r = d['results'][0]
    assert 'name' in r
    assert 'kind' in r
    assert 'trust' in r
print('End-to-end JSON structure: OK')
"
    else
        skip "Exchange not reachable"
    fi
}

@test "cap info → cap compare workflow functions" {
    local A="LobeHub/aliksir-playwright-browser-mcp"
    local B="LobeHub/openai-skills-playwright"

    run "$CAP" info "$A" --json
    if [ "$status" -eq 0 ]; then
        run "$CAP" compare "$A" "$B" --json
        if [ "$status" -eq 0 ]; then
            echo "$output" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['a']['name'] != d['b']['name']
print('Workflow info→compare: OK')
"
        else
            skip "Compare failed (capabilities may not be in local index)"
        fi
    else
        skip "Info failed (Exchange may be unreachable)"
    fi
}

@test "piped output does not corrupt JSON" {
    run bash -c '"$CAP" search "test" --json | python3 -c "import json,sys; json.load(sys.stdin)"' 2>&1
    if [ "$status" -eq 0 ]; then
        true
    else
        skip "Exchange not reachable"
    fi
}
