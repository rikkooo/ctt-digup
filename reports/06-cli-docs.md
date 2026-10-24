# Dual diligence - Card 06

Inspector: kimi cli   Date: 2026-10-24

## Summary

Inspected `man/ctt-digup.1` (405 lines), `docs/MANUAL.md` (622 lines) and `README.md` against every instruction, deliverable and acceptance criterion in `cards/06-cli-docs.md`. The man page contains all 8 required troff sections with 10 EXAMPLES blocks and balanced macros; the manual covers all 7 mandated chapters with a 14-workflow cookbook and zero TODO/TBD/FIXME placeholders; README links to both documents. One item could not be fully proven: `man ctt-digup` could not be executed live because this Windows host has neither `man` nor `groff` installed — the page passed static troff validation (all `.SH` sections present, `.TH` header, `.RS`/`.RE` 14/14, `.nf`/`.fi` 13/13 balanced), but a live render should still be confirmed in WSL. Overall verdict: **PASS with one PARTIAL** (live man render unverified in this environment).

## Deliverable validation

| Deliverable | Result | Evidence |
|---|---|---|
| `man/ctt-digup.1` installs and renders via `man` | PARTIAL | File exists with valid structure: `.TH CTT-DIGUP 1 "October 2026" "ctt-digup 0.1.0" "User Commands"` (man/ctt-digup.1:3); all required `.SH` sections present — NAME:4, SYNOPSIS:6, DESCRIPTION:43, COMMANDS:72, OPTIONS:158, EXAMPLES:249, ENVIRONMENT:336, FILES:358, SEE ALSO:392 (plus OUTPUT:222, EXIT STATUS:384, AUTHORS:404). Macro pairs balanced: `.RS`=14/`.RE`=14, `.nf`=13/`.fi`=13, 51 `.TP` blocks. Install command documented at man/ctt-digup.1:381-383 and docs/MANUAL.md:124-129. NOT proven: live render — `man` and `groff` are not installed on this host (`man -l` and `groff -man -z` both unavailable), so "renders via man" is statically validated only. |
| `docs/MANUAL.md` covers setup + usage + examples (≥10 examples) | PASS | All 7 card-mandated chapters present: §1 Setup (MANUAL.md:21-130 — WSL install 1.1, Windows install 1.2, model download 1.3, PATH/env 1.4, mcp2cli install 1.5, man install 1.6); §2 Indexing (133-241 — Win+WSL folder policy tables, estimate/index/status, code index 2.5, split indexes 2.6); §3 Searching (244-326 — query tips 3.5, kinds 3.2, `code:` syntax 3.3, JSON output 3.4); §4 MCP integration (329-383 — server config 4.1, tool reference 4.2, agent snippets 4.3); §5 CLI reference (386-457 — ctt-digup, digup native, options, mcp2cli options, tool mapping); §6 Examples cookbook (460-555) with **14 numbered copy-paste workflows** (≥10 required), including the card-named ones: find invoice (#1/#2), find clip moment (#3), code symbol (#5), reindex (#10), status check (#11); §7 Troubleshooting (558-605 — model download resume, missing libgomp, WSL `/mnt/c` perf, permission notes). |
| README links to both | PASS | README.md:92 — `**Documentation:** [man page](man/ctt-digup.1) (man ctt-digup after sudo cp …) · [full manual](docs/MANUAL.md) (setup, indexing, searching, MCP, CLI reference, examples cookbook, troubleshooting)`. Both link targets exist at those relative paths. Note: links sit in the "MCP server" section, not literally in "Quick start" as the card's implementation instruction stated (see Gaps). |

Card instruction details verified beyond the checklist:

- Man page COMMANDS covers every mcp2cli/digup-mapped command: mapping table (man/ctt-digup.1:138-145) lists all five MCP tools — `digup_search`, `digup_index`, `digup_estimate`, `digup_status`, `digup_download_model` — cross-checked against the server source `src/mcp-server/index.js:75-142` and `src/mcp-server/digup.js:293-369`; names match exactly.
- Man page EXAMPLES has **10 example blocks** (`.TP` count in lines 249-335 = 10; requirement ≥6), covering download-model, estimate+index from WSL, `--code`, semantic pdf search, video clip with `--json`, `code:` search, split `--index`, status, mcp2cli agent calls, jq pipe.
- ENVIRONMENT (man/ctt-digup.1:336-357) documents `DIGUP_BIN`, `DIGUP_MODELS`, `DIGUP_WORKER_DIR`, `MANPATH`; FILES (358-383) documents `index.sqlite`, `code.sqlite`, `Models/`, `costs.json`, `~/.mcp2cli/bakes.json`, `mcp.json`, `/usr/local/share/man/man1/ctt-digup.1`; SEE ALSO (392-396) includes `digup(1)` and `mcp2cli(1)`.

## Acceptance criteria

| Criterion | Result | Evidence |
|---|---|---|
| `man ctt-digup` displays without errors; manual has no TODO placeholders | PARTIAL | TODO part: PASS — grep for `TODO|TBD|FIXME|XXX` over `docs/MANUAL.md`, `man/ctt-digup.1`, `README.md` returns zero matches. Render part: unverifiable here — `man`/`groff` absent on this Windows host; static troff inspection found well-formed macros throughout (`.TH`, balanced `.RS/.RE` 14/14, `.nf/.fi` 13/13, valid `.BR/.BI/.IR` usage, escaped `\-`), which strongly predicts a clean render, but the live command was not run. |
| Kimi report in `reports/06-cli-docs.md` validates deliverables against this card | PASS | This report: `reports/06-cli-docs.md`, mapping 1:1 to the card's Deliverables and Acceptance criteria with line-referenced evidence. |

## Gaps / follow-ups

- **Live man render unconfirmed**: run `man -l man/ctt-digup.1` (or `groff -man -z man/ctt-digup.1`) inside WSL Ubuntu-26.04, and `sudo cp man/ctt-digup.1 /usr/local/share/man/man1/ && man ctt-digup`, to close the PARTIAL rows above.
- **ENVIRONMENT "index dir vars"**: the card asks the ENVIRONMENT section to include index-dir variables; the man page documents none (DigUp selects the index folder via the `--index DIR` flag, covered under OPTIONS man/ctt-digup.1:189-194 and FILES; no `DIGUP_INDEX`-style variable exists anywhere in repo docs). Additionally, the real MCP-server variables `DIGUP_WSL_DISTRO` and `DIGUP_TIMEOUT_MS` (src/mcp-server/digup.js:15,46; docs/MCP.md:84-86) are absent from both the man page ENVIRONMENT and the manual's §1.4 table — consider adding them for completeness.
- **README link placement**: card instruction said "Link man + manual from README quick start"; the links live in the "MCP server" section (README.md:92), not in "Quick start" (README.md:44-63). Deliverable satisfied; placement deviates from the instruction.
- **Docs reference files shipped by other cards**: MANUAL.md §1.5 (line 115) and the appendix (line 620) reference `scripts/ctt-digup`, and README quick start references `scripts/install-digup.sh`, `index-windows.sh`, `index-wsl.sh`, `link-mcp2cli.sh`; `scripts/` currently contains only `kimi-diligence.sh` and `run-card.sh`. These belong to cards 01/02/03/05 — expected mid-project forward references, but the docs will be inaccurate until those cards land.
