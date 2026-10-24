# Card 05 — Convert MCP to CLI with mcp2cli

## Goal
Expose the DigUp MCP server as a shell CLI using `mcp2cli` (`@tronsfey/mcp2cli`).

## Why
Mission channel #2: "available to every shell".

## Implementation instructions

1. Install mcp2cli:
   ```bash
   npm install -g @tronsfey/mcp2cli
   ```
2. Register the DigUp MCP server with mcp2cli (per its README: config file listing MCP servers).
   - Point it at `src/mcp-server/index.js` via `node`.
   - Name the CLI entry `ctt-digup` (symlink/wrapper is fine).
3. Verify tool → command mapping:
   ```bash
   ctt-digup list-tools
   ctt-digup digup_status
   ctt-digup digup_search "zebra in a video" --limit 5
   ```
4. Thin convenience wrapper `scripts/ctt-digup` that:
   - forwards all args to mcp2cli
   - sets `DIGUP_BIN` if unset
   - prints `--help` listing the mapped tools with examples
5. Document mapping table in `docs/MANUAL.md` (MCP tool ↔ CLI subcommand ↔ digup native).

## Deliverables
- [ ] `@tronsfey/mcp2cli` installed and configured for the DigUp MCP server
- [ ] `ctt-digup` command works from bash
- [ ] Wrapper help text lists tools + examples
- [ ] Mapping documented in the manual

## Acceptance criteria
- CLI calls return the same data as MCP tool calls (spot-check `digup_status` and one search).
- Kimi report in `reports/05-mcp2cli.md` validates deliverables against this card.
