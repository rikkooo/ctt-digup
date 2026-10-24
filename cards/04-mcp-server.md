# Card 04 — MCP server for DigUp

## Goal
Build an MCP (Model Context Protocol) server that exposes DigUp operations as tools any agent can call.

## Why
Mission channel #1 for "available to every agent".

## Implementation instructions

1. Create `src/mcp-server/` (Node.js + official MCP SDK `@modelcontextprotocol/sdk`):
   ```
   src/mcp-server/
     package.json
     index.js          # stdio MCP server
     digup.js          # thin wrapper around the digup CLI
   ```
2. Expose at least these tools:

   | Tool | Input | Output | Maps to |
   |---|---|---|---|
   | `digup_search` | `{query: string, limit?: number, kind?: string[], code?: boolean}` | JSON result list | `digup search ... --json` |
   | `digup_index` | `{folders: string[], code?: boolean}` | indexing summary | `digup index ...` |
   | `digup_estimate` | `{folders: string[]}` | counts + ETA | `digup estimate ... --json` |
   | `digup_status` | `{}` | index stats | `digup status` |
   | `digup_download_model` | `{}` | download progress / done | `digup download-model` |

3. Wrapper rules (`digup.js`):
   - Always invoke the `digup` binary (path from `DIGUP_BIN` env or `/usr/local/bin/digup`).
   - Pass `--json` where supported and parse NDJSON/JSON lines.
   - Never allow arbitrary shell injection: spawn with argument arrays, never a shell string.
   - Stream or truncate large outputs (cap ~50 KB per tool result).
4. Server config (`mcp.json`):
   ```json
   {
     "mcpServers": {
       "digup": {
         "command": "node",
         "args": ["/home/ubuntu/devs/ctt-digup/src/mcp-server/index.js"],
         "env": { "DIGUP_BIN": "/usr/local/bin/digup" }
       }
     }
   }
   ```
5. Smoke-test with an MCP client (Claude Code / `mcp` inspector / `kimi` MCP config).

## Deliverables
- [ ] `src/mcp-server/` runs as a stdio MCP server
- [ ] All five tools listed and documented
- [ ] `mcp.json` snippet in README/MANUAL
- [ ] At least one tool call verified end-to-end against the real digup binary

## Acceptance criteria
- `initialize` + `tools/list` + one `tools/call` succeed; results match `digup` CLI output.
- Kimi report in `reports/04-mcp-server.md` validates deliverables against this card.
