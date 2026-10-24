# DigUp MCP → CLI bridge (mcp2cli)

`ctt-digup` exposes the DigUp MCP server (`src/mcp-server/index.js`) to any
shell through [`@tronsfey/mcp2cli`](https://www.npmjs.com/package/@tronsfey/mcp2cli)
— a command-line proxy for MCP servers. This is mission channel #2
("available to every shell"): no MCP client required.

```
shell  →  ctt-digup wrapper  →  mcp2cli @ctt-digup  →  MCP server (stdio)  →  digup CLI
```

## 1. Install

```bash
# Node.js 18+ required
npm install -g @tronsfey/mcp2cli
```

On Windows PowerShell the npm shim may be blocked by execution policy
(`mcp2cli.ps1 cannot be loaded`). Use `cmd /c mcp2cli.cmd …`, or run the
bash wrapper under Git Bash / WSL, which invokes the JS entry with `node`.

Bakes (saved server shortcuts) live in `~/.mcp2cli/bakes.json` **per OS
user and per shell environment** — the Windows profile and each WSL distro
have their own store.

## 2. Register the server ("bake")

```bash
# Windows (Git Bash / cmd) — runs the Windows digup.exe helper
mcp2cli bake create ctt-digup \
  --mcp-stdio "node C:/devs/ctt-digup/src/mcp-server/index.js"
mcp2cli bake create digup \
  --mcp-stdio "node C:/devs/ctt-digup/src/mcp-server/index.js"

# WSL — runs /usr/local/bin/digup
mcp2cli bake create ctt-digup \
  --mcp-stdio "node /mnt/c/devs/ctt-digup/src/mcp-server/index.js"
mcp2cli bake create digup \
  --mcp-stdio "node /mnt/c/devs/ctt-digup/src/mcp-server/index.js"
```

Two names, one server: `ctt-digup` is the wrapper's default bake;
`digup` is the short alias used in `docs/MANUAL.md` examples
(`mcp2cli @digup …`).

The `scripts/ctt-digup` wrapper auto-creates the `ctt-digup` bake on first
run if it is missing or points at a different server entry.

> **Do not bake `--env` values.** mcp2cli's `--env <KEY=VALUE...>` is
> variadic: when a bake with `env` is expanded back into argv, `--env`
> swallows the tool name that follows (`digup_status` becomes a bogus env
> var). Export `DIGUP_BIN` in the shell instead — the stdio child inherits
> the parent environment.

## 3. The `ctt-digup` wrapper

```bash
# Linux / macOS / WSL / Git Bash
install -m 0755 scripts/ctt-digup /usr/local/bin/ctt-digup   # or ~/bin

# Windows (cmd / PowerShell): already available as scripts\ctt-digup.cmd
```

What it does:

1. Sets `DIGUP_BIN` if unset (Windows: `%LOCALAPPDATA%\DigUp\helper\digup.exe`;
   WSL/Linux: `/usr/local/bin/digup`).
2. Ensures the `ctt-digup` bake exists (see above).
3. Translates friendly subcommands and positional sugar into mcp2cli calls.
4. Forwards everything to `mcp2cli @ctt-digup …` (override with
   `CTT_DIGUP_BAKE`).

```bash
ctt-digup --help          # mapping table + examples
```

## 4. Mapping table

MCP tool ↔ CLI subcommand ↔ digup native:

| MCP tool | `ctt-digup` friendly | raw tool call | `digup` native | Notes |
|---|---|---|---|---|
| `digup_search` | `ctt-digup search QUERY... [-n N] [--kind K,K] [--code]` | `ctt-digup digup_search --query S [--limit N] [--kind K ...] [--code true]` | `digup search QUERY -n N --kind K,K --json` | `--kind` comma-list is split into repeated `--kind` flags; `code:true` prepends `code: ` to the query |
| `digup_index` | `ctt-digup index DIR... [--code]` | `ctt-digup digup_index --folders DIR [--folders DIR ...] [--code true]` | `digup index DIR... [--code]` | long-running; stdout returned as text (no `--json` in the CLI) |
| `digup_estimate` | `ctt-digup estimate DIR...` | `ctt-digup digup_estimate --folders DIR [... ]` | `digup estimate DIR... --json` | one JSON object per folder |
| `digup_status` | `ctt-digup status` | `ctt-digup digup_status` | `digup status` | no parameters |
| `digup_download_model` | `ctt-digup download-model` | `ctt-digup digup_download_model` | `digup download-model` | long-running (~865 MB), resumable |

Tool parameters ↔ digup flags:

| MCP parameter | ctt-digup flag | digup flag | Type |
|---|---|---|---|
| `query` | `QUERY...` / `--query` | positional query | string (required) |
| `limit` | `-n N` / `--limit N` | `-n N` | int 1–200, default 10 |
| `kind` | `--kind K,K` | `--kind K,K` | enum list: screenshot, image, pdf, doc, audio, video |
| `code` | `--code` | `--code` (via `code: ` query prefix) | boolean |
| `folders` | `DIR...` / `--folders` | positional folders | string array (required for index/estimate) |

mcp2cli output flags (pass through `ctt-digup` unchanged):

| Flag | Meaning |
|---|---|
| `--list` / `list-tools` | list available tools |
| `--describe TOOL` | tool schema as JSON |
| `--input-json JSON` | all tool arguments as one JSON object |
| `--json` / `--raw` / `--pretty` | output shape |
| `--jq EXPR` | JMESPath filter over the result |
| `--debug`, `--no-cache`, `--cache-ttl S` | connection / cache control |

## 5. Examples

```bash
ctt-digup list-tools
ctt-digup status
ctt-digup search "zebra in a video" -n 5
ctt-digup search invoice --kind pdf,doc --json
ctt-digup estimate "C:/Users/me/Documents"
ctt-digup index "C:/Users/me/Documents" --code

# raw tool names work the same (positional sugar included)
ctt-digup digup_search "zebra in a video" --limit 5
ctt-digup digup_search --input-json '{"query":"invoice","limit":3}' --jq 'data[*].path'

# or call mcp2cli directly
mcp2cli @ctt-digup digup_status
mcp2cli @digup --list
mcp2cli @digup digup_search --query "zebra in a video" --limit 5
```

## 6. Parity with the engine

CLI results are exactly what the MCP tool returns, which is exactly what
`digup` prints (wrapped in `{ok, output|mode/data, truncated}` and capped
at ~50 KB). Spot-check on 2026-10-24:

| Call | digup native | `ctt-digup` (CLI) | `mcp2cli @ctt-digup` (raw) |
|---|---|---|---|
| status | `index: ~/AppData/Local/DigUp/index/index.sqlite` `vectors: 0 in 0 segments` `this digup: llama.cpp b11461, vectors 1` `size: 57 KB` | identical text in `output` | identical |
| search "zebra in a video" -n 5 | `[]` | `{"ok":true,"mode":"json","data":[],...}` | identical |

## 7. Environment variables

| Variable | Default | Meaning |
|---|---|---|
| `DIGUP_BIN` | platform helper (see `docs/MCP.md`) | digup CLI binary |
| `DIGUP_WSL_DISTRO` | unset | on Windows, run the engine inside this WSL distro |
| `DIGUP_TIMEOUT_MS` | 120 000 / 900 000 | digup spawn timeout |
| `CTT_DIGUP_BAKE` | `ctt-digup` | which mcp2cli bake the wrapper uses |
| `CTT_DIGUP_ROOT` | script's parent dir | repo root when the wrapper is installed outside the checkout |
| `MCP2CLI` | auto-detected | mcp2cli executable override |

## 8. Gotchas (Windows / WSL)

- **PowerShell splatting eats `@bake`.** `@digup` is splatting syntax when
  the name is a valid PS variable; `@ctt-digup` (hyphen) is not. Always
  quote: `mcp2cli '@digup' --list`, or run under cmd / bash.
- **WSL + Windows PATH interop.** `command -v mcp2cli` inside WSL may find
  the Windows npm shim, which runs `node.exe` and mangles POSIX server
  paths (`C:\mnt\c\...`). The wrapper avoids this by invoking
  `node <mcp2cli JS bin>` with the distro's own node under WSL/Linux.
- **Bakes are per home directory.** A bake created on Windows does not
  exist in WSL and vice versa. The wrapper creates its bake on first run
  in whichever environment it is invoked.
- **No baked `--env`.** See §2.
