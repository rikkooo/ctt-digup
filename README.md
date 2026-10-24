# ctt-digup

**Mission:** Make DigUp's on-device semantic file search available to every agent and every shell — on Windows 11 and WSL Ubuntu-26.04 — through a first-class MCP server and a well-documented CLI, with each requirement shipped as a verifiable card, executed by a sub-agent and dual-checked by Kimi.

## Why

DigUp ([ARahim3/DigUp](https://github.com/ARahim3/DigUp)) finds files by *meaning* (EmbeddingGemma 2), not just by name. That power is locked inside a desktop app and a developer CLI. ctt-digup turns it into:

1. **Indexed corpora** — Windows 11 user folders and WSL Ubuntu home/dev folders, kept fresh.
2. **An MCP server** — so any MCP-capable agent can `digup_search`, `digup_index`, `digup_status`.
3. **A CLI via mcp2cli** — the same tools as ordinary commands, for scripts and bash man pages.
4. **Proof of delivery** — every requirement is a GitHub issue (card), implemented by a sub-agent, and validated by a Kimi dual-diligence report against the card instructions.

## What this repo contains

| Path | Purpose |
|---|---|
| `README.md` | Mission, architecture, quick start |
| `ROADMAP.md` | Mission-stated roadmap; each milestone = one card |
| `cards/` | One markdown file per requirement card (implementation instructions) |
| `src/mcp-server/` | MCP server wrapping the DigUp CLI |
| `scripts/` | Install, index, mcp2cli wiring, kimi diligence runner |
| `man/` | bash man page + comprehensive manual |
| `docs/` | Manual, setup, usage, examples |
| `reports/` | Kimi dual-diligence reports (one per card) |
| `skill/` | Agent skill package consumable by any agent |

## Architecture

```
Windows 11 folders ──► digup index ──► SQLite vector index ──┐
WSL Ubuntu folders ──► digup index ──► SQLite vector index ──┤
                                                             ▼
                                              MCP server (digup-mcp)
                                                             │
                                              mcp2cli → `ctt-digup` CLI
                                                             │
                                    ┌─────────────────────────┼──────────────┐
                                    ▼                         ▼              ▼
                              agents (MCP)              bash / scripts    man/manual
```

## Quick start

```bash
# 1. Install DigUp (WSL)
./scripts/install-digup.sh

# 2. Download the embedding model (once, ~865 MB)
digup download-model

# 3. Index the folders
./scripts/index-windows.sh
./scripts/index-wsl.sh

# 4. Start the MCP server / CLI
npm install -g @tronsfey/mcp2cli
./scripts/link-mcp2cli.sh

# 5. Search
ctt-digup search "invoice from last March"
```

## Delivery model

Every roadmap requirement is a **card** (`cards/NN-*.md`) with:

- Goal and acceptance criteria
- Step-by-step implementation instructions
- Deliverables checklist

Cards are registered as **GitHub issues**. Each issue is executed by a **sub-agent**. At the end of each card, **Kimi** (`kimi -p ...`) runs a dual diligence inspection and writes `reports/NN-*.md` validating deliverables against the card instructions.

## License

MIT (project). DigUp itself is MIT (ARahim3/DigUp).
