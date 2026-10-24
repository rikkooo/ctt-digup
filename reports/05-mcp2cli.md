# Dual diligence - Card 05

Inspector: kimi cli   Date: 2026-10-24

## Summary

Verdict: **PASS**. All four deliverables from `cards/05-mcp2cli.md` were verified
live on this machine: `@tronsfey/mcp2cli@1.3.2` is installed globally with the
`ctt-digup` (and `digup` alias) bakes registered; the `ctt-digup` command works
from bash (PATH copy byte-identical to `scripts/ctt-digup`) and its `.cmd`
sibling works from cmd; the wrapper help lists tools, mapping and examples; the
mapping table is documented in `docs/MANUAL.md` §5.4 with full detail in
`docs/MCP2CLI.md`. Both acceptance spot-checks show the CLI returning the same
data as the native engine. Only caveat: the index currently holds 0 vectors, so
search parity is proven on the empty-result shape only.

## Deliverable validation

| Deliverable | Result | Evidence |
|---|---|---|
| `@tronsfey/mcp2cli` installed and configured for the DigUp MCP server | PASS | `npm ls -g @tronsfey/mcp2cli` → `@tronsfey/mcp2cli@1.3.2` (prefix `C:\Users\enric\AppData\Roaming\npm`). `~/.mcp2cli/bakes.json` contains `"ctt-digup"` → `node C:/devs/ctt-digup/src/mcp-server/index.js` (createdAt 2026-10-24T07:42:16Z) plus the `digup` alias bake; server entry exists at `src/mcp-server/index.js`. |
| `ctt-digup` command works from bash | PASS | `which ctt-digup` → `/c/Users/enric/AppData/Roaming/npm/ctt-digup`; `diff` vs `scripts/ctt-digup` → identical (also for `.cmd`). Bare `ctt-digup search "zebra in a video" -n 5` run from `/tmp` → exit 0, `{"ok":true,"mode":"json","data":[]}`. `scripts/ctt-digup list-tools` → exit 0, lists all 5 tools (`digup_search`, `digup_index`, `digup_estimate`, `digup_status`, `digup_download_model`) with schemas. Windows sibling: `cmd /c scripts\ctt-digup.cmd status` → exit 0, same JSON payload. |
| Wrapper help text lists tools + examples | PASS | `scripts/ctt-digup --help` (exit 0) prints: friendly commands (`search`, `index`, `estimate`, `status`, `download-model`, `list-tools`), raw MCP tool parameter flags, the MCP ↔ CLI ↔ digup mapping table, 9 examples including `ctt-digup digup_search "zebra in a video" --limit 5`, passthrough mcp2cli flags, and env vars (`scripts/ctt-digup:154-211`). |
| Mapping documented in the manual | PASS | `docs/MANUAL.md:451-459` (§5.4) holds the MCP tool ↔ `ctt-digup` ↔ `digup` native table; §4.2 tool reference (`MANUAL.md:353-359`), §1.5 install/wiring (`MANUAL.md:101-123`). Full mapping incl. per-parameter table in `docs/MCP2CLI.md:78-98` (§4). |

## Acceptance criteria

| Criterion | Result | Evidence |
|---|---|---|
| CLI calls return the same data as MCP tool calls (spot-check `digup_status` and one search) | PASS | `scripts/ctt-digup digup_status` → `output` = `index: ~/AppData/Local/DigUp/index/index.sqlite` / `vectors: 0 in 0 segments` / `this digup: llama.cpp b11461, vectors 1` / `size: 57 KB` — byte-identical to native `digup.exe status` run the same minute. `scripts/ctt-digup digup_search "zebra in a video" --limit 5` → `{"ok":true,"mode":"json","data":[],"truncated":false}`, matching native `digup.exe search "zebra in a video" -n 5 --json` → `[]`. Consistent with the recorded parity table in `docs/MCP2CLI.md:131-140` (§6, dated 2026-10-24). |
| Kimi report in `reports/05-mcp2cli.md` validates deliverables against this card | PASS | This file. |

## Gaps / follow-ups

- **Search parity proven on empty index only.** `digup status` reports `vectors: 0 in 0 segments`, so both CLI and native search return `[]`. Parity of the wrapper/bridge is demonstrated (both sides agree, exit 0), but a non-empty hit-list comparison should be re-run after cards 02/03 populate an index.
- **Wrapper installed into the npm global prefix** (`AppData\Roaming\npm\ctt-digup[.cmd]`) as a hand-copied PATH location rather than via an npm package. Works today; if the npm prefix changes, the copies are orphaned and must be re-installed (re-run the `install` step from `docs/MCP2CLI.md` §3).
- **`ctt-digup.cmd` help is a subset** of the bash help (no raw-tool flags / env-var sections). Cosmetic; functional parity (friendly commands, sugar, exit codes) verified.
- **Card checklist unticked.** `cards/05-mcp2cli.md` deliverables still show `- [ ]`; can be ticked now that this inspection passes (not done here — inspection only).
