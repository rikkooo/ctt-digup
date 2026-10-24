# ctt-digup Manual

Semantic file search for every agent and every shell — DigUp on Windows 11 and WSL Ubuntu-26.04, through an MCP server and a documented CLI.

- Man page: [`man/ctt-digup.1`](../man/ctt-digup.1) — install with `sudo cp man/ctt-digup.1 /usr/local/share/man/man1/` then `man ctt-digup`
- Engine: [ARahim3/DigUp](https://github.com/ARahim3/DigUp) (`digup` CLI, EmbeddingGemma 2)
- CLI bridge: [`@tronsfey/mcp2cli`](https://www.npmjs.com/package/@tronsfey/mcp2cli)

**Contents**

1. [Setup](#1-setup)
2. [Indexing](#2-indexing)
3. [Searching](#3-searching)
4. [MCP integration](#4-mcp-integration)
5. [CLI reference](#5-cli-reference)
6. [Examples cookbook](#6-examples-cookbook)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. Setup

### 1.1 WSL Ubuntu-26.04

Install the DigUp engine (v0.7.0-beta.3 or newer) and expose the `digup` CLI:

```bash
# Source tree (optional, for building from source)
git clone https://github.com/ARahim3/DigUp ~/devs/DigUp

# Linux .deb from the beta release
curl -L -o /tmp/digup.deb \
  https://github.com/ARahim3/DigUp/releases/download/v0.7.0-beta.3/DigUp_0.7.0-beta.3_amd64.deb

# System libs + package (the Debian package is called "dig-up")
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y libgomp1
sudo dpkg -i /tmp/digup.deb || sudo apt-get install -y -f

# Put the engine CLI on PATH (the package installs it as a helper)
sudo ln -sf /usr/lib/DigUp/helper/digup /usr/local/bin/digup
digup --help
```

Expected: `digup --help` prints the usage banner (`digup estimate | index | search | status | download-model | …`).

### 1.2 Windows 11

1. Copy `DigUp_0.7.0-beta.3_x64-setup.exe` to `C:\devs\` (fetch it from WSL if Windows cannot reach GitHub).
2. Run the per-user installer (no admin rights needed):

   ```powershell
   C:\devs\DigUp_0.7.0-beta.3_x64-setup.exe
   ```

   If SmartScreen blocks it: **More info → Run anyway** (the beta installer is unsigned).
3. Verify DigUp appears in the Start menu / tray. Its data folder lives under `%LOCALAPPDATA%`.
4. The Windows install ships the `digup` helper next to the app. Find it and note the absolute path (add it to `PATH` if you want `digup` in PowerShell):

   ```powershell
   Get-ChildItem "$env:LOCALAPPDATA" -Recurse -Filter digup.exe -ErrorAction SilentlyContinue | Select-Object -First 3 FullName
   ```

WSL can drive the Windows corpora through `/mnt/c` (see [Indexing](#2-indexing)), so a Windows-side `digup` is optional.

### 1.3 Model download (once, ~865 MB)

EmbeddingGemma 2 (text part 310 MB + image/audio encoders 555 MB) must be on disk before the first index or search:

```bash
digup download-model
```

- Progress arrives as JSON lines; wait until `{"event":"done"}`.
- The download resumes if interrupted — run the same command again (see [Troubleshooting](#7-troubleshooting)).
- Model location: `DIGUP_MODELS` if set, else the Hugging Face cache or DigUp's data folder (`~/.local/share/digup/Models` on Linux/WSL).

To place the model somewhere shared:

```bash
digup download-model --to ~/.local/share/digup/Models
export DIGUP_MODELS=~/.local/share/digup/Models   # digup will look only there
```

### 1.4 PATH and environment variables

| Variable / flag | Meaning | Default |
|---|---|---|
| `DIGUP_BIN` | Path to the `digup` binary used by the MCP server and the `ctt-digup` wrapper | `/usr/local/bin/digup` on Linux/WSL |
| `DIGUP_MODELS` | Directory holding the EmbeddingGemma 2 model files. When set, digup looks for the model **only** there | Hugging Face cache / DigUp data folder |
| `DIGUP_WORKER_DIR` | `worker` selects the mlx-lm reference worker (evals only) | unset (llama.cpp) |
| `--index DIR` | Flag selecting the index folder (see [Indexing](#2-indexing)) | DigUp's Application Support folder, e.g. `~/.local/share/digup/index` |

Put persistent values in `~/.bashrc` (WSL) or the PowerShell profile (Windows):

```bash
# ~/.bashrc
export DIGUP_BIN=/usr/local/bin/digup
export DIGUP_MODELS=$HOME/.local/share/digup/Models
```

### 1.5 mcp2cli install and `ctt-digup` wiring

`ctt-digup` is a thin wrapper over `mcp2cli`, which calls the DigUp MCP server (`src/mcp-server/index.js`):

```bash
# Node.js 18+ required
npm install -g @tronsfey/mcp2cli

# Register the DigUp MCP server as a saved shortcut ("bake")
mcp2cli bake create ctt-digup \
  --mcp-stdio "node $HOME/devs/ctt-digup/src/mcp-server/index.js"
mcp2cli bake create digup \
  --mcp-stdio "node $HOME/devs/ctt-digup/src/mcp-server/index.js"

# Wrapper on PATH (forwards args to mcp2cli, sets DIGUP_BIN if unset)
install -m 0755 scripts/ctt-digup /usr/local/bin/ctt-digup   # or ~/bin

# Smoke test
ctt-digup list-tools
ctt-digup status
```

Bakes are stored in `~/.mcp2cli/bakes.json` (per OS user — Windows and each WSL distro have their own). Check them with `mcp2cli bake list`. Do **not** add `--env` to a bake: mcp2cli's variadic `--env` swallows the tool name at call time — export `DIGUP_BIN` in the shell instead. Full bridge docs: [`docs/MCP2CLI.md`](MCP2CLI.md).

### 1.6 Install the man page

```bash
sudo cp man/ctt-digup.1 /usr/local/share/man/man1/
man ctt-digup
```

---

## 2. Indexing

### 2.1 Folder policy

Pick the folders you actually search. Defaults used by this project:

**Windows 11 (via WSL `/mnt/c`):**

| Folder | Notes |
|---|---|
| `/mnt/c/Users/<user>/Documents` | contracts, invoices, notes |
| `/mnt/c/Users/<user>/Desktop` | current work |
| `/mnt/c/Users/<user>/Downloads` | can be large — estimate first |
| `/mnt/c/Users/<user>/Pictures` | optional; vision-heavy and slow |

**WSL Ubuntu-26.04:**

| Folder | Notes |
|---|---|
| `~/devs` | projects (ctt-digup, DigUp, …) |
| `~/Documents` | if present |
| `~/.local/share/ctt-digup-samples` | test fixtures |

Two indexing routes for Windows folders:

- **A — native Windows DigUp:** add the folders in DigUp UI (tray → Settings → Folders).
- **B — WSL CLI over `/mnt/c`:** the commands below. Prefer this when you want one scripting surface.

### 2.2 Estimate first

```bash
digup estimate /mnt/c/Users/enric/Documents /mnt/c/Users/enric/Desktop /mnt/c/Users/enric/Downloads
```

Human output shows the first-pass time per folder and a per-kind breakdown (PDFs/pages, audio duration, video duration, images). JSON form emits one object per folder:

```bash
digup estimate ~/devs --json
```

Key fields: `folder`, `seconds`, `files` (counts per kind), `pdf_pages` / `pdf_pages_total`, `audio_seconds`, `video_seconds`, `long_files`, `later_seconds`, `bytes`, `subfolders`, `calibrated`.

### 2.3 Index

```bash
# Windows corpus from WSL
digup index /mnt/c/Users/enric/Documents /mnt/c/Users/enric/Desktop /mnt/c/Users/enric/Downloads

# WSL corpus
digup index ~/devs
```

Notes:

- The first pass embeds everything new, then finishes long PDFs/documents (their tail pages arrive after the bulk).
- `--limit N` bounds the pass to N files (useful for a quick first taste).
- `--exclude DIR` (repeatable) and `--exclude-ext EXT` (e.g. `--exclude-ext heic,txt`) cut noise.
- `--include-code` also indexes loose source files as documents; `--include-datasets` disables the dataset-folder heuristic.
- `--reindex` drops vectors and embeds everything again (after a model or settings change).
- New files are picked up continuously after the first pass.

### 2.4 Status

```bash
ctt-digup status
# or the engine directly
digup status
```

Example output:

```
index: ~/.local/share/digup/index/index.sqlite
vectors: 12480 in 3921 segments
  screenshot     210   new 0 · embedded 210
  image         1832   new 0 · embedded 1832
  pdf            214   new 0 · embedded 198 · later 16
  ...
this digup: llama.cpp b11461, vectors 1
size: 214 MB
```

`vectors: 0` means nothing is indexed yet (or you are pointing at the wrong `--index` folder).

### 2.5 Code index

Code search is a **separate index** (`code.sqlite`), off until you ask for it:

```bash
digup index ~/devs --code
```

It reads source files, notebooks (without outputs) and a repo's own docs, minus what git ignores. Search it with the `code:` prefix (see [Searching](#3-searching)). `digup estimate ~/devs --code` sizes it first.

### 2.6 One index or two (`--index DIR`)

Default: one index per machine/user. Split corpora with separate index folders:

```bash
digup index    /mnt/c/Users/enric/Documents /mnt/c/Users/enric/Desktop /mnt/c/Users/enric/Downloads --index ~/indexes/windows
digup index    ~/devs ~/Documents --index ~/indexes/wsl

digup search "invoice" --index ~/indexes/windows --json
digup search "roadmap" --index ~/indexes/wsl --json
digup status   --index ~/indexes/windows
```

Every command that touches the index accepts `--index DIR` (including `search`, `status`, `estimate`, `download-model` via `--to`). Keep the model shared with `DIGUP_MODELS` regardless of how many indexes you keep.

---

## 3. Searching

### 3.1 Basic search

```bash
digup search "the clause about pets in the lease"
ctt-digup search "invoice from last March" -n 5
```

Describe **what you are looking for in your own words**. Meaning matches are ranked by how far a segment stands out (`z`, gate default 2.0); exact words (invoice numbers, error codes, names) get a keyword boost and are matched as written.

### 3.2 Kinds

`--kind K,K` restricts to: `screenshot`, `image`, `pdf`, `doc`, `audio`, `video`.

```bash
digup search "zebra in a video" --kind video
digup search "payment declined error" --kind screenshot
digup search "the clause about pets" --kind pdf,doc
```

### 3.3 Code search (`code:` syntax)

```bash
digup search "code: retry a failed call with backoff"
digup search "code: refreshAccessToken"
digup search "code: plot how many examples each class has"
```

The `code:` prefix routes the query to the code index (equivalent to `--code` for search). Hits carry `loc`/`loc_end` (the stretch) and `focus` (the line to open at — the definition of a looked-up name, or the first line with the query's words).

### 3.4 JSON output

`--json` prints a JSON array of hits (pretty-printed, sorted keys). Each hit:

| Field | Always? | Meaning |
|---|---|---|
| `path` | yes | absolute file path |
| `kind` | yes | `screenshot` \| `image` \| `pdf` \| `doc` \| `audio` \| `video` |
| `segment` / `segment_id` | yes | the matched segment (page, frame, window, …) |
| `score` | yes | fused rank score (ordering only) |
| `modified`, `size`, `info` | yes | file mtime (epoch s), bytes, metadata (`pages`, `duration`, `width`, …) |
| `z` | when meaning-matched | how far the best segment stands out |
| `cosine` | when meaning-matched | raw model similarity |
| `keyword_rank` | when word-matched | 1-based rank among keyword matches |
| `loc` / `loc_end` | when positioned | PDF page, or seconds into audio/video, or code stretch |
| `focus` | code hits | line to open at |
| `excerpt` | when available | short text snippet |

Example (abridged):

```json
[
  {
    "excerpt": "...tenant may keep one pet with written consent...",
    "info": { "pages": "24" },
    "kind": "pdf",
    "loc": 7,
    "path": "/mnt/c/Users/enric/Documents/lease.pdf",
    "score": 12.4,
    "segment": "page",
    "segment_id": 412,
    "size": 184320,
    "z": 3.1
  }
]
```

Pipe it into `jq`:

```bash
digup search "invoice from last March" --json | jq -r '.[] | "\(.score)\t\(.path)"'
```

### 3.5 Query tips

- Be concrete: `"the clause about pets in the lease"` beats `"pets"`.
- Exact strings work: `"INV-2026-0314"`, `"ECONNREFUSED"`, a person's name.
- Cross-lingual: a query in English finds files in Bengali, Arabic and 100+ languages, and back.
- Filter early with `--kind` — less noise, faster to read.
- A search over an empty or wrong index returns `[]` / "no good matches" — check `digup status` first.
- Tuning (rarely needed): `--zgate Z` (how far a meaning match must stand out, default 2.0), `--word-weight W` (bonus for containing all query words, default 2.0).

---

## 4. MCP integration

### 4.1 Server config (`mcp.json`)

The DigUp MCP server is a Node stdio server (`src/mcp-server/index.js`) that wraps the `digup` binary:

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

- `DIGUP_BIN` points at the engine CLI (default `/usr/local/bin/digup`).
- The server spawns `digup` with argument arrays (no shell strings) and returns JSON, truncated to ~50 KB per result.

### 4.2 Tool reference

| Tool | Input | Output | Maps to |
|---|---|---|---|
| `digup_search` | `{query: string, limit?: number, kind?: string[], code?: boolean}` | JSON hit list | `digup search … --json` |
| `digup_index` | `{folders: string[], code?: boolean}` | indexing summary | `digup index …` |
| `digup_estimate` | `{folders: string[]}` | counts + ETA | `digup estimate … --json` |
| `digup_status` | `{}` | index stats | `digup status` |
| `digup_download_model` | `{}` | download progress / done | `digup download-model` |

### 4.3 Agent integration snippets

Claude Code / any MCP client — add the `mcp.json` block above to the client's MCP config and call `digup_search` with `{query, limit, kind, code}`.

From a shell or an agent that prefers the CLI (mcp2cli):

```bash
# Discover tools
mcp2cli @digup --list
mcp2cli @digup --describe digup_search --json

# Call tools
mcp2cli @digup digup_status
mcp2cli @digup digup_search --query "zebra in a video" --limit 5
mcp2cli @digup digup_search --input-json '{"query":"invoice","limit":3,"kind":["pdf"]}' --json
mcp2cli @digup digup_estimate --input-json '{"folders":["/mnt/c/Users/enric/Documents"]}' --raw
mcp2cli @digup digup_index --input-json '{"folders":["/home/ubuntu/devs"],"code":true}'

# Filter with JMESPath
mcp2cli @digup digup_search --query "payment declined" --jq 'hits[*].path'
```

The `ctt-digup` wrapper sets `DIGUP_BIN` if unset and forwards everything else to `mcp2cli @ctt-digup` (the `digup` bake is a short alias for the same server), so `ctt-digup search …` and `mcp2cli @digup digup_search --query …` are the same pipeline. Mapping details: [`docs/MCP2CLI.md`](MCP2CLI.md).

---

## 5. CLI reference

### 5.1 `ctt-digup` — friendly commands

| Command | Synopsis | Description |
|---|---|---|
| `search` | `ctt-digup search QUERY... [-n N] [--kind K,K] [--code] [--json]` | semantic + keyword search |
| `index` | `ctt-digup index DIR... [--code]` | sync + embed folders |
| `estimate` | `ctt-digup estimate DIR... [--json]` | counts + first-pass ETA |
| `status` | `ctt-digup status [--json]` | index stats |
| `download-model` | `ctt-digup download-model` | fetch EmbeddingGemma 2 (resumable) |
| `list-tools` | `ctt-digup list-tools` | list MCP tools (mcp2cli `--list`) |
| `help` | `ctt-digup help` | wrapper help + mapping + examples |

### 5.2 `digup` — native engine commands

| Command | Synopsis | Description |
|---|---|---|
| `estimate` | `digup estimate DIR... [--json]` | what would be indexed, first-pass time |
| `index` | `digup index DIR... [--limit N] [--code] [--reindex]` | sync index, embed what's new |
| `search` | `digup search WORDS... [--kind K,K] [-n N] [--json]` | search by meaning; `code:` prefix for code |
| `status` | `digup status` | what's in the index (prints index path) |
| `download-model` | `digup download-model [--to DIR]` | model files, resumable, JSON lines |
| `speed` | `digup speed [--model]` | this machine's speed vs the estimate baseline |
| `eval` | `digup eval QUERIES.json [-n N]` | recall of known answers (see `evals/`) |
| `index-service` | `digup index-service DIR... [limits]` | app's indexing helper (JSON lines) |
| `search-service` | `digup search-service DIR...` | long-lived searcher process (JSON lines) |
| `worker` | `digup worker [--text-only]` | the model as a process (query encoder) |

### 5.3 `digup` options

| Flag | Applies to | Meaning |
|---|---|---|
| `--index DIR` | all | index folder (default: DigUp's Application Support folder; see `digup status`) |
| `--code` | estimate/index/search | use the code index (`code.sqlite`) |
| `--kind K,K` | search | `screenshot, image, pdf, doc, audio, video` |
| `--limit N` / `-n N` | index / search | max files this pass / max hits (default 10) |
| `--include-code` | index/estimate | also index loose source/data files as documents |
| `--include-datasets` | index/estimate | don't skip dataset-looking folders |
| `--exclude DIR` | index/estimate | don't index this folder (repeatable) |
| `--exclude-ext EXT` | index/estimate | don't index this extension (`heic,txt`) |
| `--reindex` | index | drop vectors and embed everything again |
| `--to DIR` | download-model | model destination directory |
| `--json` | estimate/search | machine-readable output |
| `--zgate Z` | search | meaning-match standout threshold (default 2.0) |
| `--word-weight W` | search | bonus for containing all query words (default 2.0) |
| `--shot-tokens N` | index | vision tokens per screenshot (default 280) |
| `--code-stretch N` | index | max chars per code stretch (default 1800) |

### 5.4 mcp2cli options (through `ctt-digup`)

Full bridge documentation (bakes, wrapper install, parity evidence, Windows/WSL gotchas): [`docs/MCP2CLI.md`](MCP2CLI.md).

| Flag | Meaning |
|---|---|
| `--list` / `list-tools` | list available tools |
| `--describe TOOL` | tool schema (parameters, types) |
| `--json` | machine-readable tool output |
| `--input-json JSON` | pass tool arguments as one JSON object |
| `--raw` | raw JSON (no pretty-print) |
| `--jq EXPR` | JMESPath filter over the result |
| `--debug` | connection/execution debug trace |
| `--no-cache`, `--cache-ttl S` | tool-list cache control |

Tool mapping (MCP tool ↔ `ctt-digup` ↔ `digup`):

| MCP tool | `ctt-digup` / `mcp2cli @digup` | `digup` native |
|---|---|---|
| `digup_search` | `ctt-digup search` / `digup_search --query …` | `digup search …` |
| `digup_index` | `ctt-digup index` / `digup_index --input-json …` | `digup index …` |
| `digup_estimate` | `ctt-digup estimate` / `digup_estimate --input-json …` | `digup estimate …` |
| `digup_status` | `ctt-digup status` / `digup_status` | `digup status` |
| `digup_download_model` | `ctt-digup download-model` / `digup_download_model` | `digup download-model` |

---

## 6. Examples cookbook

Copy-paste workflows. Adjust the user (`enric`) and folders to your machine.

**1. Find an invoice by meaning**

```bash
digup search "invoice from last March" --kind pdf,doc -n 5
```

**2. Find an invoice by its exact number (keyword rescue)**

```bash
digup search "INV-2026-0314" --json | jq -r '.[0].path'
```

**3. Find the moment a zebra shows up in a video (clip moment)**

```bash
digup search "zebra in a video" --kind video --json \
  | jq -r '.[0] | "\(.path)  at \(.loc)s"'
```

**4. Find the pets clause in a lease (PDF page)**

```bash
digup search "the clause about pets in the lease" --kind pdf
# → opens at the page; JSON form gives "loc": page number
```

**5. Find a code symbol by what it does**

```bash
digup search "code: retry a failed call with backoff"
digup search "code: refreshAccessToken"
```

**6. Search only the Windows corpus (split index)**

```bash
digup search "payment declined error" --index ~/indexes/windows --json
```

**7. Estimate a big folder before indexing it**

```bash
digup estimate /mnt/c/Users/enric/Downloads --json \
  | jq '{folder, seconds, files, bytes}'
```

**8. First index of the Windows user folders**

```bash
digup index /mnt/c/Users/enric/Documents /mnt/c/Users/enric/Desktop /mnt/c/Users/enric/Downloads
```

**9. Index WSL projects with code search on**

```bash
digup index ~/devs --code
```

**10. Reindex after a model or settings change**

```bash
digup index ~/devs --reindex --code
```

**11. Status check (health of the index)**

```bash
ctt-digup status
digup status --index ~/indexes/wsl
```

**12. Keep the index fresh on a schedule (cron)**

```bash
# crontab -e
17 3 * * * /usr/local/bin/digup index /mnt/c/Users/enric/Documents /mnt/c/Users/enric/Desktop /mnt/c/Users/enric/Downloads >> ~/.digup-index.log 2>&1
```

**13. Agent-style tool call via mcp2cli**

```bash
mcp2cli @digup digup_search --query "zebra in a video" --limit 5 --json
mcp2cli @digup digup_status
```

**14. Feed hits into a shell loop**

```bash
digup search "contracts about rent" --kind pdf --json \
  | jq -r '.[].path' | while read -r f; do echo "==> $f"; done
```

---

## 7. Troubleshooting

### Model download interrupted or slow

`digup download-model` **resumes**. Re-run the same command; progress is JSON lines and the final event is `{"event":"done"}`. If it restarts from zero, check free disk space (~1 GB needed) and point the destination explicitly: `digup download-model --to ~/.local/share/digup/Models`, then set `DIGUP_MODELS` to that folder.

### `digup: error while loading shared libraries: libgomp.so.1`

The OpenMP runtime is missing:

```bash
sudo apt-get install -y libgomp1
```

### WSL `/mnt/c` is slow

Plan 9 filesystem access is several times slower than ext4. Mitigations:

- Run `digup estimate` first and index in bounded passes (`--limit N`) so a huge `Downloads` doesn't stall.
- Keep the **index** on ext4 (the default `~/.local/share/digup` is fine); only the *files* live on `/mnt/c`.
- Exclude heavy, useless trees: `--exclude /mnt/c/Users/enric/Downloads/node_modules --exclude-ext heic`.
- Consider native Windows DigUp (Setup §1.2) for the Windows corpus and WSL digup for `~/devs`, with two `--index` folders.

### `no good matches` / empty JSON `[]`

1. `digup status` — is anything indexed? (`vectors: 0` = empty)
2. Are you on the right index? (`--index DIR` / `DIGUP_BIN` confusion)
3. Did you filter too hard? Drop `--kind`, raise `-n`.
4. For code: did you index with `--code`, and does the query start with `code:`?

### Permission notes

- Reading `/mnt/c/Users/...` from WSL normally works out of the box; if a folder is denied, check Windows ACLs for the WSL user.
- `digup` only reads files — it never moves, changes or uploads them. Hidden folders (`.ssh` and the like), keys, certificates and password files are never read.
- Installing the man page to `/usr/local/share/man/man1/` needs `sudo`; without it, use `man -l man/ctt-digup.1`.
- `mcp2cli` bakes live in `~/.mcp2cli/bakes.json` (user-owned; no root needed).

### `ctt-digup` not found / tools not listed

1. `npm install -g @tronsfey/mcp2cli` (Node 18+).
2. `mcp2cli bake list` — is the `digup` bake there? Re-create it (Setup §1.5).
3. `DIGUP_BIN` must point at a working `digup`: `DIGUP_BIN=/usr/local/bin/digup digup status`.
4. Debug the bridge: `mcp2cli @digup --list --debug`.

### `libvulkan` / GPU notes

DigUp runs the model on the GPU (Vulkan) when that is faster, and on the CPU otherwise. A missing Vulkan driver just means CPU inference (slower first pass, same results). `digup speed --model` times the model on this machine and keeps the result beside the index.

---

## 8. Using the skill from other agents

The repo ships a skill package at [`skill/ctt-digup/SKILL.md`](../skill/ctt-digup/SKILL.md) (mirror: [`.agents/skills/ctt-digup/SKILL.md`](../.agents/skills/ctt-digup/SKILL.md)) so any agent can operate ctt-digup without extra context.

### Install paths

| Scope | Path |
|---|---|
| Project (in-repo) | `.agents/skills/ctt-digup/SKILL.md` (already present) |
| Project (Claude Code) | `.claude/skills/ctt-digup/SKILL.md` |
| User (all projects) | `~/.claude/skills/ctt-digup/SKILL.md` |

```bash
# copy into a discoverable location
mkdir -p ~/.claude/skills/ctt-digup
cp skill/ctt-digup/SKILL.md ~/.claude/skills/ctt-digup/
```

### How another agent uses it

1. Agent notices a request about semantic file search / DigUp / indexing folders.
2. Loads the skill (`ctt-digup`) and runs the setup check (`digup --help`, `digup status`).
3. Indexes if needed (`scripts/index-windows.sh`, `scripts/index-wsl.sh`), then searches.
4. Reports results with the skill's result-reporting template (path, kind, score, excerpt).

Paste-ready sub-agent prompt:

```text
Use the ctt-digup skill. Verify digup is installed, run digup status,
then run: digup search "<query>" -n 10 --json. Report hits with path/kind/excerpt.
If ctt-digup CLI is missing, fall back to raw digup.
```

More detail: [`skill/README.md`](../skill/README.md) — "Using the skill from other agents".

---

## Appendix: file map

| Path | What |
|---|---|
| `~/.local/share/digup/index/index.sqlite` | main vector + keyword index (Linux/WSL default) |
| `~/.local/share/digup/index/code.sqlite` | code index (with `--code`) |
| `~/.local/share/digup/Models/` | EmbeddingGemma 2 model files (override: `DIGUP_MODELS`) |
| `~/.local/share/digup/index/costs.json` | measured indexing costs (feeds `estimate`) |
| `%LOCALAPPDATA%\…\DigUp` | Windows DigUp data (model + index) |
| `~/Library/Application Support/DigUp/` | macOS DigUp data |
| `~/.mcp2cli/bakes.json` | mcp2cli saved servers |
| `src/mcp-server/index.js` | DigUp MCP server |
| `scripts/ctt-digup` | CLI wrapper (sets `DIGUP_BIN`, forwards to mcp2cli) |
| `man/ctt-digup.1` | this project's man page |
| `docs/MANUAL.md` | this manual |
