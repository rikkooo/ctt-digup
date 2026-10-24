# Dual diligence — Card 04

Inspector: kimi cli   Date: 2026-10-24

## Summary

**Overall verdict: PASS.** All four deliverables and both acceptance criteria of
`cards/04-mcp-server.md` are satisfied with concrete, reproducible evidence. The
server in `src/mcp-server/` was exercised live during this inspection:
`node smoke-test.js --full` spawned the real stdio server, completed
`initialize` + `tools/list` (all five tools) + three `tools/call`s
(`digup_status`, `digup_estimate`, `digup_search`) against the real digup binary
(`C:\Users\enric\AppData\Local\DigUp\helper\digup.exe`), exit code 0. The
`digup_status` tool output matches a direct CLI run of `digup status` byte-for-byte
(modulo CRLF). Wrapper rules hold: argv-array spawning with `shell: false`, a 50 KB
output cap, and `--json`/NDJSON parsing. Only minor follow-ups remain (doc example
fidelity, sample-config path is Linux/WSL-specific); none block the card.

## Deliverable validation

| Deliverable | Result | Evidence |
|---|---|---|
| `src/mcp-server/` runs as a stdio MCP server | PASS | `node smoke-test.js --full` (run by inspector, exit 0): server logs `[digup-mcp] v0.1.0 starting; digup=C:\Users\enric\AppData\Local\DigUp\helper\digup.exe` then `connected on stdio`; `initialize` → `serverInfo {name:"digup-mcp", version:"0.1.0"}`. Entry `src/mcp-server/index.js:156-165` uses `StdioServerTransport`; deps installed (`node_modules/@modelcontextprotocol` present, SDK `^1.32.2` in `package.json:25`). |
| All five tools listed and documented | PASS | `tools/list` returned exactly `digup_download_model, digup_estimate, digup_index, digup_search, digup_status` (smoke-test PASS line). Registered in `src/mcp-server/index.js:74-152`; documented one section each in `docs/MCP.md` (`digup_search` L105, `digup_index` L166, `digup_estimate` L203, `digup_status` L259, `digup_download_model` L288). Input schemas match the card table: search `{query, limit?, kind?, code?}` (`index.js:83-94`), index `{folders, code?}` (L107-110), estimate `{folders}` (L122-124), status/download `{}` (L136, L149). |
| `mcp.json` snippet in README/MANUAL | PASS | Root `mcp.json:1-9` matches the card's snippet verbatim (`mcpServers.digup`, `command: "node"`, args → `src/mcp-server/index.js`, `env.DIGUP_BIN=/usr/local/bin/digup`). Snippet also embedded in `README.md:72-81` and `docs/MANUAL.md:331-341` (§4.1), plus a full copy in `docs/MCP.md:30-40`. |
| At least one tool call verified end-to-end against the real digup binary | PASS | Inspector ran `node smoke-test.js --full`: `tools/call digup_status` → `isError=false`, `{"ok":true,"output":"index: ~/AppData/Local/DigUp/index/index.sqlite\r\nvectors: 0 in 0 segments\r\nthis digup: llama.cpp b11461, vectors 1\r\nsize: 57 KB\r\n"}`. Direct run of `"$LOCALAPPDATA/DigUp/helper/digup.exe" status` produced the identical four lines (exit 0). Also verified: `digup_estimate` → `mode:"json"` object with `folder:"/tmp/digup-smoke"`; `digup_search` → `mode:"json", data:[]` (empty index, correct). |

Wrapper rules from card §3 (supporting evidence):

- **Spawn-safety:** `src/mcp-server/digup.js:102-107` — `spawn(file, argv, { stdio:["ignore","pipe","pipe"], shell:false })`, argv assembled as arrays only (`index.js` handlers → `digupSearch`/`digupIndex`/… build `["search", query, "-n", n, "--json"]` style arrays, e.g. `digup.js:298-333`). Grep over `src/mcp-server/*.js` finds **no** `exec(`, `execSync`, `execFile`, or `shell: true`. Input validation adds a second layer: kind whitelist (`SEARCH_KINDS`, `digup.js:291,322-328`), `limit` integer 1–200 (`digup.js:309-315`), folders non-empty strings (`digup.js:338-343,352-357`).
- **Binary resolution:** `DIGUP_BIN` honored first (`digup.js:63-65`); POSIX default `/usr/local/bin/digup` (`digup.js:28,78`); Windows fallback list `digup.js:39-44` correctly targets `helper\digup.exe` (the CLI), not the app shell; optional `DIGUP_WSL_DISTRO` routing via `wsl.exe -d <distro> -- <bin>` still argv-only (`digup.js:57-61`).
- **50 KB cap:** `OUTPUT_CAP_BYTES = 50 * 1024` (`digup.js:25`); enforced at capture time (`appendCapped`, `digup.js:120-134`), at serialization (`capText`, `digup.js:223-230` with `"…[truncated at ~50 KB]"` marker), and per tool result (`textResult`, `index.js:38-43`). `digup_download_model` additionally collapses progress events into count + last snapshot (`digup.js:373-393`) so long downloads cannot hit the cap.
- **`--json` + NDJSON parsing:** `--json` passed for `search` (`digup.js:332`) and `estimate` (`digup.js:359`); `parseDigupOutput` (`digup.js:194-220`) handles single-JSON, NDJSON, and raw text. `index`/`status` have no `--json` in the CLI and are correctly returned as text (`docs/MCP.md:173,266`).

## Acceptance criteria

| Criterion | Result | Evidence |
|---|---|---|
| `initialize` + `tools/list` + one `tools/call` succeed; results match `digup` CLI output | PASS | Inspector-run `node smoke-test.js --full`, exit 0: (1) `initialize` → `serverInfo.name === "digup-mcp"` asserted PASS; (2) `tools/list` → all five expected names asserted PASS; (3) `tools/call digup_status` → `isError=false` with output identical to direct CLI `digup status` run (`index: ~/AppData/Local/DigUp/index/index.sqlite`, `vectors: 0 in 0 segments`, `llama.cpp b11461`, `size: 57 KB`). Two further calls (`digup_estimate`, `digup_search`) also succeeded against the real binary. |
| Kimi report in `reports/04-mcp-server.md` validates deliverables against this card | PASS | This file, written by kimi cli after live inspection on 2026-10-24. |

## Gaps / follow-ups

- **`docs/MCP.md` estimate example is richer than this host's real output.** Doc
  (`docs/MCP.md:224-253`) shows a ~20-field `digup estimate --json` object
  (`bytes`, `calibrated`, `kind_seconds`, `files:{doc:2}`, `readable:true`, …);
  the live Windows-CLI call here returned a 7-field object
  (`audio_seconds, files:{}, folder, pdf_pages, readable:false, seconds, video_seconds`).
  Likely a CLI-version and/or empty-folder difference, not a server bug — the server
  passes the object through faithfully. Follow-up: regenerate the doc example from
  the current binary on a populated folder, or note the field set is version-dependent.
- **Root `mcp.json` args path is Linux/WSL-specific** (`/home/ubuntu/devs/...`),
  verbatim from the card; it does not exist on this Windows host. Mitigated in docs:
  `docs/MCP.md:42-78` provides Windows-native and Windows→WSL variants. Follow-up:
  consider a comment or second file (e.g. `mcp.windows.json`) so copy-paste works on
  Windows hosts.
- **`digup_download_model` not exercised end-to-end** (would download ~865 MB).
  Card requires only one verified call, so this is informational; its NDJSON
  summarization logic (`digup.js:373-421`) is covered by code review only.
- **Cosmetic:** `capText` (`digup.js:226-228`) can split a UTF-8 multibyte sequence
  at the 50 KB boundary, yielding a trailing U+FFFD. Harmless for JSON text; could
  back off to the last complete code point if it ever matters.
