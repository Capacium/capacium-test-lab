# Cursor Framework

Cursor is a GUI-only application and does **not** have a Docker container in agent-test-env.

## Testing Cursor

Cursor uses `~/.cursor/mcp.json` for MCP server configuration, not skill directories.

### Lifecycle scripts

| Script | Behavior |
|--------|----------|
| `install.sh` | No-op — Cursor runs on the host, not in Docker |
| `verify.sh` | Checks for `~/.cursor/` directory existence (non-fatal) |
| `test.sh` | Writes a test MCP server config to `~/.cursor/mcp.json` |
| `clean.sh` | Removes `~/.cursor/mcp.json` |

### Limitations

- Cursor cannot be fully automated for skill testing since it's GUI-only
- MCP server testing is supported via config-file manipulation
- Skill symlink testing is not applicable (Cursor doesn't use skill directories)

Run Cursor tests on the host machine:

```bash
bash frameworks/cursor/scripts/test.sh test-mcp-server
```
