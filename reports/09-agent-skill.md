# Dual diligence - Card 09

Inspector: kimi cli   Date: 2026-10-24

## Summary

Inspected `skill/ctt-digup/SKILL.md` (308 lines), `skill/README.md` (80 lines) and `.agents/skills/ctt-digup/SKILL.md` against every instruction, deliverable and acceptance criterion in `cards/09-agent-skill.md`. The skill file carries valid frontmatter, all five mandated sections, the sub-agent reporting template and both install paths, with zero TODOs; the `.agents/skills/` copy is byte-identical to the source and is demonstrably discoverable — it is listed as a Project-scope skill in this very (fresh) inspector session. Every read-only command the skill teaches was executed live through WSL and behaved exactly as documented: `digup --help`, `digup status` (output byte-identical to the skill's sample), `digup search --json` (pretty-printed empty array), human-mode `no good matches`, `code:` queries, and the `ctt-digup`-missing fallback. One item is PARTIAL: the section "Using the skill from other agents" exists verbatim in `skill/README.md:44-62` but is absent from the project manual `docs/MANUAL.md` (zero case-insensitive matches for "skill"). Overall verdict: **PASS with one PARTIAL**.

## Deliverable validation

| Deliverable | Result | Evidence |
|---|---|---|
| `skill/ctt-digup/SKILL.md` complete (no TODOs) | PASS | 308 lines. Frontmatter present and well-formed: `name: ctt-digup` (line 2), `description: Semantic file search over Windows 11 and WSL folders via DigUp. Use when the user asks to find files by meaning, …` (line 3). All 5 card-mandated sections present: `## When to use` (line 10), `## Setup check` (20), `## Commands` (52), `## Examples` (223), `## Troubleshooting` (284). All card item-2 teachings present: verify install `digup --help` / `ctt-digup --help` (24-33), index Windows `/mnt/c/...` and WSL `~/devs` (54-88), natural-language and `code:` search (99-143), `status` / JSON reading (145-174), raw-`digup` fallback when mcp2cli missing (195-205). Sub-agent prompt template: `## Result-reporting template (sub-agents)` (257-282) with 5 reporting rules. Install paths documented for both scopes (302-308). `grep -rn -i "TODO\|FIXME\|TBD\|XXX" skill/ .agents/skills/` → zero matches. |
| Skill copied to a discoverable skills directory | PASS | `.agents/skills/ctt-digup/SKILL.md` exists (12396 bytes, dated Oct 24 15:11) and `diff skill/ctt-digup/SKILL.md .agents/skills/ctt-digup/SKILL.md` → byte-identical. Discoverability proven live: this fresh inspector session's skill listing contains `ctt-digup` at **Project** scope, path `C:/devs/ctt-digup/.agents/skills/ctt-digup/SKILL.md` — i.e. an agent with no prior context found and parsed the installed copy. Card allows `.claude/skills/...` **or** `.agents/skills/...`; the latter is satisfied. User-scope copy `~/.claude/skills/ctt-digup/SKILL.md` is documented (SKILL.md:308, README install table + one-shot `cp` commands, skill/README.md:9-40) but not required to exist. |
| Manual section "Using the skill from other agents" | PARTIAL | The exact-titled section exists with full content — `skill/README.md:44-62`: 6 numbered steps (load, setup check, corpus/`--index` guidance, reporting template, paste-able sub-agent prompt, MCP tool note). However `grep -i "skill" docs/MANUAL.md` → **zero matches**: the project manual (622 lines, per reports/06-cli-docs.md) has no such section and no link to `skill/README.md`. If "Manual" in the card means `docs/MANUAL.md`, this deliverable is not met there; the content itself is complete and correct in the skill package's README. |
| Smoke-test evidence in the Kimi report | PASS | Live transcript below, run 2026-10-24 from this fresh session (Git Bash → `wsl -e bash -lc`), with only the skill's own content as context — matching the card's validation step ("fresh agent session can load the skill and run `digup status` + one search") and the smoke test scripted in skill/README.md:64-80. |

Smoke-test transcript (all exit 0):

```
$ wsl -e bash -lc "digup --help"
digup: search your files by meaning (DigUp developer CLI)      ← matches SKILL.md:27 prediction
  digup estimate|index|search|status|speed|eval|index-service|worker|search-service|download-model …

$ wsl -e bash -lc "digup status"
index: ~/.local/share/digup/index/index.sqlite                 ← byte-identical to the sample
vectors: 0 in 0 segments                                          documented at SKILL.md:155-161
  doc              2   2 pending
this digup: llama.cpp b11461, vectors 1
size: 57 KB

$ wsl -e bash -lc "digup search 'invoice from last March' -n 5 --json"
[

]                                                            ← pretty-printed empty array, as documented (SKILL.md:128)

$ wsl -e bash -lc "digup search 'invoice from last March' -n 5"
no good matches                                              ← human-mode empty message, as documented (SKILL.md:128)
(0 vectors · query encoder 0.00 s incl. start-up · search 0 ms)

$ wsl -e bash -lc "digup search 'code: retry a failed call with backoff' -n 5 --json"
[

]                                                            ← code: prefix accepted; empty because no code index built (SKILL.md:132,297)

$ wsl -e bash -lc "ctt-digup --help"
bash: line 1: ctt-digup: command not found                   ← fallback path is the live one, exactly as
                                                               the skill states (SKILL.md:33,291)
```

## Acceptance criteria

| Criterion | Result | Evidence |
|---|---|---|
| Skill description triggers correctly; commands in the skill work as written | PASS | Trigger: the description frontmatter (SKILL.md:3) is what this session's Project-scope skill listing shows, loaded from `.agents/skills/ctt-digup/SKILL.md` with no extra context — the discovery mechanism works end-to-end. Commands: every read-only command taught by the skill was executed live (transcript above) and every predicted output matched verbatim — help banner, the documented `status` sample, empty-JSON-array vs `no good matches` behavior, `code:` handling, and the `ctt-digup`-absent fallback. Path accuracy also verified: `/mnt/c/Users/enric` exists (matches the `WIN_USER=enric` examples, SKILL.md:60-77), `~/devs/ctt-digup` exists in WSL Ubuntu (matches SKILL.md:93-94), and the MCP config block (SKILL.md:209-219, `/home/ubuntu/devs/ctt-digup/src/mcp-server/index.js`) matches the repo's own `mcp.json` byte-for-byte and the real WSL filesystem (`/home/ubuntu/devs/ctt-digup` confirmed; `src/mcp-server/index.js` exists). Scope note: write commands (`digup index`, `estimate` on real folders, `download-model`) were verified against `--help` syntax only, not executed — inspect-only mandate; the empty index (`vectors: 0`) is itself consistent with everything the skill says about the unindexed state. |
| Kimi report in `reports/09-agent-skill.md` validates deliverables against this card | PASS | This report: maps 1:1 to the card's 4 Deliverables and 2 Acceptance criteria with line-referenced and command-output evidence, per `reports/TEMPLATE.md`. |

## Gaps / follow-ups

- **Manual section location**: "Using the skill from other agents" lives only in `skill/README.md:44-62`. To satisfy the strictest reading of the card, add the section (or a prominent link to `skill/README.md`) to `docs/MANUAL.md` — e.g. a short §8 or a paragraph in §4 MCP integration.
- **Dangling script references**: SKILL.md troubleshooting (line 289) points to `scripts/install-digup.sh`, and lines 92-95 to `scripts/index-windows.sh` / `scripts/index-wsl.sh` (the latter hedged "if present"); `scripts/` currently contains only `kimi-diligence.sh` and `run-card.sh`. Same forward-reference pattern already flagged in `reports/06-cli-docs.md` — these files belong to cards 01/02/03 and the skill's troubleshooting row will be inaccurate until they land.
- **Optional install scopes not populated**: `.claude/skills/ctt-digup/` does not exist in the repo and `~/.claude/skills/ctt-digup/SKILL.md` was not checked/installed; only the `.agents/skills/` project copy is in place. The card requires just one discoverable project location (satisfied), but per `skill/README.md:42`, any future edit to `skill/ctt-digup/SKILL.md` must be re-copied to `.agents/skills/ctt-digup/SKILL.md` — the two files are identical today (diff verified), so drift is the risk to watch.
- **Write-path commands unexecuted**: `digup index …`, `digup estimate …`, and `digup download-model` were validated against `--help` syntax and the skill's tables only. A full end-to-end index-and-search run (card 02/03 territory) would close the last mile of "commands work as written".
