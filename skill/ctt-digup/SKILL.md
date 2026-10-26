---
name: ctt-digup
description: Semantic file search over Windows 11 and WSL folders via DigUp. Use when the user asks to find files by meaning, meaning search, semantic search, DigUp, index folders, index Windows or WSL paths, query the ctt-digup index/CLI/MCP, locate a document/clip/screenshot by content, or run digup / ctt-digup commands.
---

# ctt-digup skill

Operate DigUp (on-device semantic file search) and the ctt-digup CLI/MCP wrapper from any agent session — index Windows 11 and WSL Ubuntu-26.04 folders, search by meaning or by `code:` query, read status/JSON, and fall back to raw `digup` when mcp2cli is missing.

## When to use

- "Find the file about X" / "where is the invoice from March" / "search by meaning"
- "Index my Documents / Desktop / Downloads / ~/devs"
- "What is in the DigUp index" / "digup status"
- "Search my code for how we retry with backoff" (`code:` query)
- Any request mentioning DigUp, ctt-digup, semantic file search, or meaning search

Do **not** use for exact filename globbing (`find`/`rg`/`dir`) or for web search.

## Setup check

Run these first. Every command below assumes a working `digup` on the WSL bash PATH.

```bash
# 1. digup engine CLI must exist
digup --help
# Expect: "digup: search your files by meaning (DigUp developer CLI)" plus the command list.
# Typical install: /usr/local/bin/digup (symlink to /usr/lib/DigUp/helper/digup)

# 2. ctt-digup (mcp2cli wrapper) — optional
ctt-digup --help
# Expect: tool list (digup_search, digup_index, digup_estimate, digup_status, digup_download_model).
# If "command not found", use raw digup (see "Fallback" below). That is normal before Card 05 lands.

# 3. Embedding model present? (needed for search; ~865 MB, downloaded once)
ls ~/.local/share/digup/Models/embeddinggemma-2-Q8_0.gguf
# If missing or only *.partial: digup download-model   (wait for {"event":"done"})

# 4. What is indexed right now
digup status
```

From **Windows PowerShell / cmd** (no bash on PATH), wrap every digup call:

```powershell
wsl -e bash -lc "digup status"
wsl -e bash -lc "digup search 'invoice from last March' -n 5 --json"
```

From **WSL / Linux bash**, run `digup` directly.

## Commands

### Index folders

**Primary strategy: one shared default index** at `~/.local/share/digup/index`. Omit `--index` and every command (`estimate`, `index`, `search`, `status`) uses it — it holds both the Windows corpora (via `/mnt/c`) and the WSL folders in one place. Only pass `--index DIR` when you deliberately split corpora into separate indexes.

Shared default (recommended):

| Corpus | Index dir | Folders |
|---|---|---|
| Windows 11 (via WSL mount) + WSL Ubuntu-26.04 | default `~/.local/share/digup/index` (omit `--index`) | `/mnt/c/Users/enric/Documents`, `.../Desktop`, `.../Downloads`, `~/devs`, `~/Documents`, `~/Desktop` |

Replace `enric` with the Windows username if different (`WIN_USER`).

```bash
# --- Windows 11 folders (from WSL) → shared default index ---
WIN_USER=enric
MNT=/mnt/c/Users/$WIN_USER

digup estimate "$MNT/Documents" "$MNT/Desktop" "$MNT/Downloads" --json
digup index    "$MNT/Documents" "$MNT/Desktop" "$MNT/Downloads"

# Bound a large first pass / skip noise
digup index "$MNT/Documents" --limit 200
digup index "$MNT/Downloads" --exclude "$MNT/Downloads/node_modules" --exclude-ext "heic,zip"

# --- WSL folders → same shared default index ---
digup estimate "$HOME/devs" --json
digup index    "$HOME/devs" "$HOME/Documents" "$HOME/Desktop"

# Optional: code index for repos under ~/devs (source files, minus what git ignores)
digup index "$HOME/devs" --code
```

Or run the repo scripts (if present) — they default to the same shared index:

```bash
bash ~/devs/ctt-digup/scripts/index-windows.sh   # INDEX_DIR=${DIGUP_INDEX_WIN:-~/.local/share/digup/index}
bash ~/devs/ctt-digup/scripts/index-wsl.sh       # INDEX_DIR=${DIGUP_INDEX_WSL:-~/.local/share/digup/index}
```

Defaults if you omit `--index`: DigUp's own folder (`digup status` prints `index: ~/.local/share/digup/index/index.sqlite`) — this shared default is the primary convention in this skill.

**Optional split alternative** (env-overridable): give each corpus its own index and pass the same `--index DIR` to `estimate`, `index`, `search`, and `status`:

| Corpus | Index dir | Folders |
|---|---|---|
| Windows 11 (via WSL mount) | `${DIGUP_INDEX_WIN:-~/.local/share/digup-index-windows}` | `/mnt/c/Users/enric/Documents`, `.../Desktop`, `.../Downloads` |
| WSL Ubuntu-26.04 | `${DIGUP_INDEX_WSL:-~/.local/share/digup-index-wsl}` | `~/devs`, `~/Documents`, `~/Desktop` |

```bash
WIN_IDX=${DIGUP_INDEX_WIN:-$HOME/.local/share/digup-index-windows}
WSL_IDX=${DIGUP_INDEX_WSL:-$HOME/.local/share/digup-index-wsl}
digup index "$MNT/Documents" "$MNT/Desktop" "$MNT/Downloads" --index "$WIN_IDX"
digup index "$HOME/devs" "$HOME/Documents" "$HOME/Desktop" --index "$WSL_IDX"
```

### Search (natural language)

```bash
# Human-readable ranked list (path, kind, folder, excerpt, score reasons)
# — shared default index (omit --index)
digup search "the clause about pets"
digup search "invoice from last March" -n 5

# JSON (pretty-printed array of hit objects) — use this when reporting to another agent
digup search "screenshot of a whiteboard diagram" -n 5 --json

# Filter by kind: screenshot, image, pdf, doc, audio, video (comma-separated)
digup search "team offsite photo" --kind image,screenshot

# Only if you split indexes: pass the matching --index DIR
digup search "the clause about pets" --index "$WIN_IDX"
```

JSON hit fields (`digup search --json`):

| Field | Always | Meaning |
|---|---|---|
| `path` | yes | absolute file path |
| `kind` | yes | `doc`, `image`, `pdf`, `audio`, `video`, `screenshot`, … |
| `segment` / `segment_id` | yes | which part of the file matched (`page`, `chunk`, `lines`, `frame`, …) |
| `score` | yes | combined ranking score (higher = better) |
| `modified`, `size`, `info` | yes | file metadata / kind-specific info |
| `z` | if meaning match | how far the match stands out (default gate 2.0) |
| `cosine` | if meaning match | raw vector similarity |
| `keyword_rank` | if word match | rank of the keyword hit |
| `loc`, `loc_end`, `focus` | if known | page / timestamp / line range / open-at line |
| `excerpt` | if available | short surrounding text |

Empty result: human mode prints `no good matches`; `--json` prints a pretty-printed empty array (`[` / `]`). Treat either as "nothing found".

### Search (code: queries)

`code: <words>` switches to the **code index** (a separate `code.sqlite`). Without the `code:` prefix a search never sees code.

```bash
# Index code first (once per repo set)
digup index "$HOME/devs" --code

# Find code by what it does
digup search "code: retry a failed call with backoff" -n 5 --json
digup search "code: parse the digup JSON hit rows"
```

Keep the whole query on one argument; the prefix is the literal `code:` (case-insensitive), then free text.

### Status / JSON

```bash
digup status                 # shared default index (primary)
digup status --index "$WIN_IDX"    # only if you split indexes
digup status --index "$WSL_IDX"    # only if you split indexes
```

`status` is human text (no `--json`). Read it as:

```
index: ~/.local/share/digup/index/index.sqlite
vectors: 0 in 0 segments
  doc              2   2 pending
this digup: llama.cpp b11461, vectors 1
size: 57 KB
```

- `index:` — which SQLite index you are looking at
- `vectors: N in M segments` — searchable embeddings (0 = search will find nothing)
- per-kind lines — file counts and states (`pending`, `embedded`, …)
- `long files still being read:` — first pass not finished
- `size:` — index file size

JSON is available on `estimate` and `search` (and `speed`):

```bash
digup estimate "$HOME/devs" --json
# one object per folder: folder, readable, seconds, files{}, pdf_pages, audio_seconds, video_seconds, left_out{}, …
```

### ctt-digup (MCP CLI) when present

```bash
ctt-digup --help
ctt-digup list-tools
ctt-digup digup_status
ctt-digup digup_search "invoice from last March" --limit 5
```

Tool → raw digup mapping:

| ctt-digup / MCP tool | raw digup |
|---|---|
| `digup_search` | `digup search <query> [-n N] [--json]` |
| `digup_index` | `digup index <folder>...` |
| `digup_estimate` | `digup estimate <folder>... --json` |
| `digup_status` | `digup status` |
| `digup_download_model` | `digup download-model` |

### Fallback (mcp2cli missing)

If `ctt-digup` is not on PATH, use raw `digup` exactly as in the tables above. Detection:

```bash
if command -v ctt-digup >/dev/null 2>&1; then
  ctt-digup digup_search "invoice from last March" --limit 5
else
  digup search "invoice from last March" -n 5 --json
fi
```

MCP agents: register the server with

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

then call tools `digup_search`, `digup_index`, `digup_estimate`, `digup_status`, `digup_download_model`. If that server is absent, fall back to `digup`.

## Examples

```bash
# 1. Fresh session health check
digup --help >/dev/null && digup status

# 2. Estimate then index Windows Documents/Desktop/Downloads (shared default index)
digup estimate /mnt/c/Users/enric/Documents /mnt/c/Users/enric/Desktop /mnt/c/Users/enric/Downloads --json
digup index    /mnt/c/Users/enric/Documents /mnt/c/Users/enric/Desktop /mnt/c/Users/enric/Downloads

# 3. Meaning search for a document (JSON, top 5)
digup search "contract clause about pets" -n 5 --json

# 4. Find a screenshot / video moment
digup search "whiteboard architecture drawing" --kind screenshot,image -n 5
digup search "demo of the login flow" --kind video -n 3

# 5. Index WSL projects + search code (same shared default index)
digup index "$HOME/devs" --code
digup search "code: spawn a subagent and collect its report" -n 5 --json

# 6. Check status (shared default holds both corpora)
digup status

# 7. Reindex after model/settings change (expensive)
digup index "$HOME/devs" --reindex

# 8. Windows PowerShell one-liner
# wsl -e bash -lc "digup search 'invoice from last March' -n 5 --json"

# 9. Optional split indexes (only if you chose the split strategy)
# WIN_IDX=$HOME/.local/share/digup-index-windows
# digup search "contract clause about pets" -n 5 --json --index "$WIN_IDX"
```

## Result-reporting template (sub-agents)

Paste this into the report back to the orchestrator. Fill every field; use `(none)` where empty.

```markdown
### digup result report
- tool: digup | ctt-digup | mcp
- command: <exact command line run>
- index: <path from `digup status` "index:" line, or "default">
- query: <user query or code: query>
- hits: <count> (or "no good matches")
- top hits:
  1. <path> — kind=<kind> score=<score> z=<z> loc=<loc>
     excerpt: <first 160 chars>
  2. ...
- next action: none | needs indexing | need model download | widened query | …
- notes: <fallback used? empty index? permission error?>
```

Rules for sub-agents:

1. Always record the **exact** command (including `--index`) so it can be re-run.
2. Prefer `--json` when you must forward structured results; otherwise quote the human list.
3. Do not claim a hit without its `path`. Do not invent paths.
4. If `vectors: 0` in status, say so — the corpus is unindexed; do not report "nothing exists".
5. If the model is still `*.partial`, run `digup download-model` before searching.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `digup: command not found` on Windows | Use `wsl -e bash -lc "digup ..."`; inside WSL confirm `ls -l /usr/local/bin/digup` → `/usr/lib/DigUp/helper/digup`. |
| `digup: command not found` in WSL | `sudo ln -sf /usr/lib/DigUp/helper/digup /usr/local/bin/digup` (package: `DigUp_*.deb`, see `scripts/install-digup.sh`). |
| `libgomp.so.1` missing | `sudo apt-get install -y libgomp1`. |
| `ctt-digup: command not found` | Expected before mcp2cli is wired. Use raw `digup`. Optional: `npm install -g @tronsfey/mcp2cli`. |
| `no good matches` and `vectors: 0` | Index first (`digup index <folders>` — shared default, or `--index DIR` if split); wait for pending docs to embed. |
| Model missing / `*.partial` | `digup download-model` (resumes; ~865 MB). Set `DIGUP_MODELS` to a custom model dir. |
| Search hits wrong corpus | Primary strategy is one shared default index (check the `index:` line in `digup status`). Only if you split indexes: pass the matching `--index DIR` everywhere. |
| `/mnt/c/...` indexing is slow | Expected (drvfs). Use `--limit N` for the first pass; exclude `node_modules`, huge zips via `--exclude` / `--exclude-ext`. |
| `search for what?` | Query argument empty — quote the query: `digup search "words here"`. |
| `code:` finds nothing | Build the code index first: `digup index ~/devs --code`. |
| Need a clean machine | `DIGUP_BIN=/usr/local/bin/digup DIGUP_MODELS=~/.local/share/digup/Models` |

Environment variables: `DIGUP_BIN` (binary path for MCP wrapper), `DIGUP_MODELS` (model dir), `DIGUP_INDEX_WIN` / `DIGUP_INDEX_WSL` (optional split-index dirs — the **default is shared** at `~/.local/share/digup/index` when these are unset), `WIN_USER` (Windows username for `/mnt/c/Users/<user>`), `--index DIR` on every digup command to override the index explicitly.

## Install paths for this skill

Copy `SKILL.md` next to the agent that should load it (see `skill/README.md`):

- Project (Claude Code): `.claude/skills/ctt-digup/SKILL.md`
- Project (in-repo, agent-agnostic): `.agents/skills/ctt-digup/SKILL.md`
- User (all projects): `~/.claude/skills/ctt-digup/SKILL.md`
