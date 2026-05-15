#!/usr/bin/env node
// Minimal stdio MCP stub for bundle testing
// Responds to initialize and tools/list; exits cleanly on SIGTERM/EOF
const rl = require('readline').createInterface({ input: process.stdin });
rl.on('line', line => {
  try {
    const req = JSON.parse(line);
    if (req.method === 'initialize') {
      process.stdout.write(JSON.stringify({ jsonrpc:'2.0', id:req.id,
        result:{ protocolVersion:'2024-11-05', capabilities:{},
          serverInfo:{ name:'sub-mcp-server', version:'1.0.0' }}}) + '\n');
    } else if (req.method === 'tools/list') {
      process.stdout.write(JSON.stringify({ jsonrpc:'2.0', id:req.id,
        result:{ tools:[{ name:'bundle_test_tool', description:'Bundle test tool',
          inputSchema:{ type:'object', properties:{} }}]}}) + '\n');
    }
  } catch {}
});
process.on('SIGTERM', () => process.exit(0));
process.on('SIGHUP',  () => process.exit(0));
