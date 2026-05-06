#!/usr/bin/env bash
set -euo pipefail

SERVER_NAME="${1:-perplexity-ai}"
TIMEOUT="${2:-15}"
EXIT_CODE=0

echo "=== Capacium MCP Live Test ==="
echo "Server:    $SERVER_NAME"
echo "Timeout:   ${TIMEOUT}s"
echo "=============================="

CONFIG_PATH="$HOME/.config/opencode/opencode.json"

python3 << PYEOF
import json, subprocess, sys

config_path = "$CONFIG_PATH"
server_name = "$SERVER_NAME"
timeout_s = int("$TIMEOUT")

with open(config_path) as f:
    cfg = json.load(f)
mcp = cfg.get("mcp", {})
entry = mcp.get(server_name)
if not entry:
    print(f"✗ Server '{server_name}' not found in {config_path}")
    sys.exit(1)

command = entry.get("command", [])
print(f"→ Command: {' '.join(command)}")

# Full MCP handshake in one session
msgs = [
    '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"capacium-test-lab","version":"1.0.0"}}}',
    '{"jsonrpc":"2.0","method":"notifications/initialized"}',
    '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}',
]
payload = "\n".join(msgs) + "\n"

print("\n→ Full MCP handshake (initialize + list tools)...")
proc = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
try:
    stdout, _ = proc.communicate(input=payload.encode(), timeout=timeout_s)
except subprocess.TimeoutExpired:
    proc.kill()
    print("✗ MCP server timed out")
    sys.exit(1)

lines = stdout.decode().strip().split("\n")
json_lines = [l for l in lines if l.strip().startswith("{")]
if not json_lines:
    print("✗ No JSON response from MCP server")
    sys.exit(1)

# Parse initialize response
init_resp = json.loads(json_lines[0])
if "result" not in init_resp:
    print("✗ initialize failed:", json_lines[0])
    sys.exit(1)

info = init_resp["result"].get("serverInfo", {})
print(f"  Server: {info.get('name','?')} v{info.get('version','?')}")
print("✓ initialize succeeded")

# Parse tools/list response (it should be the last JSON line)
tools_resp = json.loads(json_lines[-1])
if "result" not in tools_resp:
    print("✗ tools/list failed:", json.dumps(tools_resp))
    sys.exit(1)

tools = tools_resp["result"].get("tools", [])
print(f"  Tools found: {len(tools)}")
for t in tools:
    desc = (t.get("description","") or "")[:80]
    print(f"    - {t.get('name', '?')}: {desc}")
print("✓ tools/list succeeded")

print("\n=== RESULT: PASS ===")
PYEOF

if [ $? -ne 0 ]; then
    EXIT_CODE=1
fi

exit $EXIT_CODE
