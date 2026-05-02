// Test MCP Server — minimal stdio JSON-RPC responder
// Validates: process starts, accepts tools/list, returns empty toolset

const readline = require('readline');

const rl = readline.createInterface({ input: process.stdin });

rl.on('line', (line) => {
  try {
    const req = JSON.parse(line);
    if (req.method === 'tools/list') {
      process.stdout.write(JSON.stringify({
        jsonrpc: '2.0',
        id: req.id,
        result: { tools: [] }
      }) + '\n');
    } else if (req.method === 'initialize') {
      process.stdout.write(JSON.stringify({
        jsonrpc: '2.0',
        id: req.id,
        result: { protocolVersion: '2024-11-05', capabilities: {}, serverInfo: { name: 'test-mcp-server', version: '1.0.0' } }
      }) + '\n');
    }
  } catch (e) {}
});
