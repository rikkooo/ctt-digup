# Card 06 — CLI documentation (man + manual)

## Goal
Ship a standard bash man page and a comprehensive manual with setup and usage of the CLI, with examples of the main commands.

## Why
"The CLI must be very well documented, with a standard bash man and a comprehensive manual with the setup and usage of the CLI, with examples of the main commands."

## Implementation instructions

### Man page (`man/ctt-digup.1`)
Write a troff man page with sections:
- `NAME`, `SYNOPSIS`, `DESCRIPTION`
- `OPTIONS`
- `COMMANDS` (every mcp2cli/digup-mapped command)
- `EXAMPLES` (at least 6 realistic examples)
- `ENVIRONMENT` (`DIGUP_BIN`, `DIGUP_MODELS`, index dir vars)
- `FILES` (index locations, config)
- `SEE ALSO` (`digup(1)`, `mcp2cli`)

Install:
```bash
sudo cp man/ctt-digup.1 /usr/local/share/man/man1/
man ctt-digup
```

### Manual (`docs/MANUAL.md`)
Chapters:
1. **Setup** — WSL install, Windows install, model download, PATH, mcp2cli install
2. **Indexing** — folder policy for Windows + WSL, estimate/index/status, code index
3. **Searching** — query tips, kinds, `code:` syntax, JSON output
4. **MCP** — server config, tool reference, agent integration snippet
5. **CLI reference** — every command with flags and examples
6. **Examples cookbook** — 10+ copy-paste workflows (find invoice, find clip moment, code symbol, reindex, status check)
7. **Troubleshooting** — model download resume, missing libgomp, WSL `/mnt/c` perf, permission notes

### README
Link man + manual from README quick start.

## Deliverables
- [ ] `man/ctt-digup.1` installs and renders via `man`
- [ ] `docs/MANUAL.md` covers setup + usage + examples (≥10 examples)
- [ ] README links to both

## Acceptance criteria
- `man ctt-digup` displays without errors; manual has no TODO placeholders.
- Kimi report in `reports/06-cli-docs.md` validates deliverables against this card.
