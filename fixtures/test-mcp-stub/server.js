#!/usr/bin/env node
/**
 * test-mcp-stub/server.js
 *
 * Minimal stdio MCP server for Capacium Test Lab E2E tests.
 *
 * Implements the minimum MCP surface needed for CI verification:
 *   - initialize  → returns server info + capabilities
 *   - tools/list  → returns 1 tool (cap_test)
 *
 * Exits cleanly on SIGTERM, SIGHUP, and EOF so Docker containers
 * don't hang after the test probe completes.
 *
 * No external dependencies — pure Node.js built-ins only.
 * Requires Node.js >= 16.
 */

'use strict';

const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  terminal: false,
});

rl.on('line', (line) => {
  const trimmed = line.trim();
  if (!trimmed) return;

  let req;
  try {
    req = JSON.parse(trimmed);
  } catch {
    // Ignore non-JSON lines (e.g. MCP Inspector probe metadata)
    return;
  }

  const { method, id } = req;

  if (method === 'initialize') {
    respond(id, {
      protocolVersion: '2024-11-05',
      capabilities: {
        tools: {},
      },
      serverInfo: {
        name: 'test-mcp-stub',
        version: '1.0.0',
      },
    });
  } else if (method === 'tools/list') {
    respond(id, {
      tools: [
        {
          name: 'cap_test',
          description: 'Capacium test tool — verifies MCP server is reachable',
          inputSchema: {
            type: 'object',
            properties: {
              message: {
                type: 'string',
                description: 'Optional test message',
              },
            },
            required: [],
          },
        },
      ],
    });
  } else if (method === 'tools/call') {
    // Support basic tool invocation for deep E2E tests
    respond(id, {
      content: [
        {
          type: 'text',
          text: `cap_test called: ${JSON.stringify(req.params?.arguments ?? {})}`,
        },
      ],
    });
  } else if (method === 'notifications/initialized') {
    // Notification — no response expected
  } else {
    // Unknown method — return method-not-found
    respondError(id, -32601, `Method not found: ${method}`);
  }
});

rl.on('close', () => {
  // EOF — exit cleanly
  process.exit(0);
});

process.on('SIGTERM', () => process.exit(0));
process.on('SIGHUP',  () => process.exit(0));

function respond(id, result) {
  const msg = JSON.stringify({ jsonrpc: '2.0', id, result });
  process.stdout.write(msg + '\n');
}

function respondError(id, code, message) {
  const msg = JSON.stringify({ jsonrpc: '2.0', id, error: { code, message } });
  process.stdout.write(msg + '\n');
}
