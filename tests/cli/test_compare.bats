#!/usr/bin/env bats

setup() {
    load '../helpers'
    CAP="${CAP:-cap}"
}

@test "cap compare --help shows flags" {
    run "$CAP" compare --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--registry" ]] || [[ "$output" =~ "--json" ]]
}

@test "cap compare without arguments exits non-zero" {
    run "$CAP" compare
    [ "$status" -ne 0 ]
}

@test "cap compare with one argument exits non-zero" {
    run "$CAP" compare "only-one"
    [ "$status" -ne 0 ]
}

@test "cap compare two nonexistent capabilities exits 1 or prints error" {
    run "$CAP" compare "nonexistent/a" "nonexistent/b"
    [ "$status" -eq 1 ]
}

@test "cap compare --json produces valid flat output" {
    run "$CAP" compare "LobeHub/aliksir-playwright-browser-mcp" "LobeHub/openai-skills-playwright" --json
    if [ "$status" -eq 0 ]; then
        echo "$output" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert 'a' in d, 'a field missing'
assert 'b' in d, 'b field missing'
print('Compare JSON: OK')
"
    else
        skip "Capabilities not available locally"
    fi
}

@test "cap compare --json has schema field" {
    run "$CAP" compare "LobeHub/aliksir-playwright-browser-mcp" "LobeHub/openai-skills-playwright" --json
    if [ "$status" -eq 0 ]; then
        echo "$output" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert '\$schema' in d, '\$schema field missing'
print('Schema: OK')
"
    else
        skip "Capabilities not available"
    fi
}
