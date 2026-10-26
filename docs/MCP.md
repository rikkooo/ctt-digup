# DigUp MCP server

`digup-mcp` is a [Model Context Protocol](https://modelcontextprotocol.io) **stdio** server that
exposes the DigUp semantic file-search CLI as tools any MCP-capable agent can call.

| | |
|---|---|
| Location | `src/mcp-server/` |
| Entry point | `src/mcp-server/index.js` (`node index.js`) |
| CLI wrapper | `src/mcp-server/digup.js` |
| Sample config | [`mcp.json`](../mcp.json) |
| Protocol | MCP over stdio (newline-delimited JSON-RPC) |
| Engine | `digup` CLI — path from `DIGUP_BIN`, else platform default |

## Quick start

```bash
# 1. Install dependencies (once)
cd src/mcp-server && npm install

# 2. Point your MCP client at the server (see mcp.json below)

# 3. Or smoke-test without a client:
npm run smoke        # initialize + tools/list + digup_status
npm run smoke -- --full   # also estimate + search
```

### Sample `mcp.json`

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

### Windows host, digup inside WSL

If the digup binary lives in WSL (this project's default engine install), set
`DIGUP_WSL_DISTRO` and the server will invoke `wsl.exe -d <distro> -- /usr/local/bin/digup …`
with an argument array (still no shell interpolation):

```json
{
  "mcpServers": {
    "digup": {
      "command": "node",
      "args": ["C:\\devs\\ctt-digup\\src\\mcp-server\\index.js"],
      "env": {
        "DIGUP_WSL_DISTRO": "Ubuntu-26.04",
        "DIGUP_BIN": "/usr/local/bin/digup"
      }
    }
  }
}
```

### Windows native digup

If DigUp is installed natively on Windows, leave `DIGUP_WSL_DISTRO` unset and either set
`DIGUP_BIN` explicitly or rely on the fallback search order (first existing wins):

1. `%LOCALAPPDATA%\DigUp\helper\digup.exe`
2. `C:\Program Files\DigUp\helper\digup.exe`
3. `C:\Program Files (x86)\DigUp\helper\digup.exe`
4. `%LOCALAPPDATA%\Programs\DigUp\helper\digup.exe`

The developer CLI lives in the install's **`helper\`** subdirectory. Do **not** point
`DIGUP_BIN` at the top-level `digup.exe` beside `DigUp.exe` — that binary is the app's
internal `digup-shell` and does not implement `search`/`index`/`estimate`/`status`.

(If no candidate exists, the server reports a spawn error naming
`%LOCALAPPDATA%\DigUp\helper\digup.exe` — the documented Windows default.)

## Environment variables

| Variable | Default | Purpose |
|---|---|---|
| `DIGUP_BIN` | `/usr/local/bin/digup` (POSIX) / `%LOCALAPPDATA%\DigUp\helper\digup.exe` (Windows fallback) | Absolute path of the digup CLI |
| `DIGUP_WSL_DISTRO` | unset | When set on Windows, run `DIGUP_BIN` inside this WSL distro via `wsl.exe` |
| `DIGUP_TIMEOUT_MS` | 120000 (900000 for `index` / `download-model`) | Per-invocation timeout for the digup CLI |

## Safety rules

- Every digup invocation uses `child_process.spawn(file, argvArray, { shell: false })`.
  **No shell string is ever built**, so folder names, queries, and kinds cannot inject commands.
- Tool output (stdout/stderr) is capped at **~50 KB** per call (`OUTPUT_CAP_BYTES`); longer
  output is truncated and flagged `"truncated": true`.
- stdout of the server carries MCP protocol messages only; diagnostics go to stderr.

---

## Tool reference

All tools return MCP `content: [{ type: "text", text: "<json or text>" }]`.
Failures return `isError: true` with a JSON body `{ "error": "...", ... }`.

---

### `digup_search`

Semantic search over the indexed corpus.

| | |
|---|---|
| Maps to | `digup search <query> [-n N] [--kind K,K] --json` |
| Output | JSON result list (array of hits) |

**Input schema**

| Field | Type | Required | Description |
|---|---|---|---|
| `query` | string | yes | Natural-language query. Prefix `code: ` (or set `code: true`) to search the code index. |
| `limit` | integer 1–200 | no | Max results (`-n`). CLI default is 10. |
| `kind` | string[] | no | Subset of `screenshot, image, pdf, doc, audio, video` (`--kind`). |
| `code` | boolean | no | Prepends `code: ` to the query when true. |

**Example call**

```json
{ "query": "invoice from last March", "limit": 5, "kind": ["pdf", "doc"] }
```

**Example response** (shape produced by `digup … --json`; an empty index returns `[]`)

```json
{
  "ok": true,
  "mode": "json",
  "data": [],
  "truncated": false
}
```

With hits (from a populated index — field set owned by DigUp's searcher):

```json
{
  "ok": true,
  "mode": "json",
  "data": [
    {
      "path": "/mnt/c/Users/enric/Documents/invoice-2026-03.pdf",
      "score": 2.41,
      "kind": "pdf",
      "snippet": "Invoice #4412 — March 3, 2026 …"
    }
  ],
  "truncated": false
}
```

Code search:

```json
{ "query": "retry a failed call with backoff", "code": true, "limit": 5 }
```

---

### `digup_index`

Sync the index with folders: discover new/changed files, embed what's new.

| | |
|---|---|
| Maps to | `digup index <folder>... [--code]` |
| Output | Human-readable indexing summary (digup has no `--json` for index) |

**Input schema**

| Field | Type | Required | Description |
|---|---|---|---|
| `folders` | string[] (min 1) | yes | Absolute folder paths to index. |
| `code` | boolean | no | Also build/update the code index (`--code`). |

**Example call**

```json
{ "folders": ["/home/ubuntu/devs"], "code": true }
```

**Example response**

```json
{
  "ok": true,
  "output": "index: ~/.local/share/digup/index/index.sqlite\nsync: 2 new · 0 changed · 0 moved · 0 removed · 0 unchanged\n",
  "truncated": false
}
```

Notes: long-running (embedding). When the embedding model is missing, digup prints an error
telling you to run `digup download-model` first; the tool surfaces that stderr.

---

### `digup_estimate`

What would be indexed, and roughly how long the first pass takes.

| | |
|---|---|
| Maps to | `digup estimate <folder>... --json` |
| Output | One JSON object per folder (NDJSON when several folders) |

**Input schema**

| Field | Type | Required | Description |
|---|---|---|---|
| `folders` | string[] (min 1) | yes | Absolute folder paths to estimate. |

**Example call**

```json
{ "folders": ["/mnt/c/Users/enric/Documents", "/mnt/c/Users/enric/Desktop"] }
```

**Example response** (real output; captured from
`digup estimate /home/ubuntu/.local/share/ctt-digup-samples --json` — the `data`
object below is the CLI's object, wrapped by the server envelope. Exact field
sets vary with folder content and digup version.)

```json
{
  "ok": true,
  "mode": "json",
  "data": {
    "audio_seconds": 0,
    "bytes": 0,
    "calibrated": true,
    "code_stretches": 0,
    "datasets": 0,
    "files": { "doc": 3 },
    "folder": "/home/ubuntu/.local/share/ctt-digup-samples",
    "kind_seconds": { "doc": 0.135 },
    "later_seconds": 0,
    "left_out": {},
    "long_files": 0,
    "ms": 1,
    "pdf_pages": 0,
    "pdf_pages_total": 0,
    "readable": true,
    "seconds": 0.135,
    "skipped": 0,
    "subfolders": [],
    "video_seconds": 0
  },
  "truncated": false
}
```

With multiple folders, `mode` is `"ndjson"` and `data` is an array of the objects above.

---

### `digup_status`

What's in the index right now.

| | |
|---|---|
| Maps to | `digup status` |
| Output | Human text (digup has no `--json` for status) |

**Input schema** — empty `{}`.

**Example call**

```json
{}
```

**Example response** (real output)

```json
{
  "ok": true,
  "output": "index: ~/.local/share/digup/index/index.sqlite\nvectors: 0 in 0 segments\nthis digup: llama.cpp b11461, vectors 1\nsize: 57 KB\n",
  "truncated": false
}
```

---

### `digup_download_model`

Download the EmbeddingGemma 2 embedding model (~865 MB) with resume.

| | |
|---|---|
| Maps to | `digup download-model` |
| Output | Summary of the NDJSON event stream |

**Input schema** — empty `{}`.

**Example call**

```json
{}
```

**Example response** (summary shape; digup streams `{"event":"file"|"progress"|"done", …}` lines)

```json
{
  "ok": true,
  "mode": "ndjson",
  "data": {
    "events": [
      { "event": "file", "from": "download", "name": "embeddinggemma-2-Q8_0.gguf", "bytes": 309855456 },
      { "event": "done" }
    ],
    "progress_events": 128,
    "last_progress": {
      "event": "progress",
      "name": "embeddinggemma-2-Q8_0.gguf",
      "bytes": 309855456,
      "total": 309855456,
      "all_bytes": 864676480,
      "all_total": 864676480
    },
    "exitCode": 0,
    "timedOut": false,
    "truncated": false
  },
  "truncated": false
}
```

Notes: long-running; default timeout 15 minutes (`DIGUP_TIMEOUT_MS` overrides). Intermediate
`progress` events are collapsed into a count + last snapshot so the 50 KB cap cannot be hit by
a long download.

---

## Error shape

Every tool returns `isError: true` with:

```json
{
  "error": "digup exited with code 1",
  "args": ["search", "…", "--json"],
  "exitCode": 1,
  "stdout": "",
  "stderr": "error: worker not found: … run digup download-model"
}
```

Spawn failures (missing binary) look like:

```json
{
  "error": "failed to spawn digup (C:\\Users\\…\\AppData\\Local\\DigUp\\helper\\digup.exe): spawn … ENOENT",
  "args": ["status"],
  "durationMs": 12
}
```

---

## Verification

`src/mcp-server/smoke-test.js` speaks MCP over stdio and checks `initialize`,
`tools/list` (all five tools), and one or more `tools/call`s against the real
`digup` binary:

```bash
cd src/mcp-server
npm run smoke            # digup_status
npm run smoke -- --full  # + digup_estimate + digup_search
```
