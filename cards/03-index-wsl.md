# Card 03 — Index WSL Ubuntu-26.04 folders

## Goal
Index the WSL Ubuntu-26.04 folders with DigUp so they are searchable by meaning.

## Why
Second half of the dual-corpus mission requirement.

## Implementation instructions

1. Decide folder set (defaults):
   - `~/devs` (projects, including ctt-digup and DigUp)
   - `~/Documents` (if present)
   - `~/.local/share/ctt-digup-samples` (test fixtures, create if needed)
2. Estimate then index:
   ```bash
   digup estimate ~/devs
   digup index ~/devs
   ```
3. Optionally enable the code index for repos:
   ```bash
   digup index ~/devs --code
   ```
   - Search code with: `digup search "code: retry a failed call with backoff"`
4. Smoke-test:
   ```bash
   digup search "project mission roadmap" --json | head
   digup status
   ```
5. If Windows and WSL corpora share one index, document that; otherwise use two `--index` folders (e.g. `--index ~/indexes/windows` vs `--index ~/indexes/wsl`) and show both in `docs/MANUAL.md`.

## Deliverables
- [ ] WSL folders estimated and indexed
- [ ] `digup status` non-empty
- [ ] Semantic search returns results from WSL paths
- [ ] Index strategy (shared vs split) documented

## Acceptance criteria
- Search results include WSL file paths; indexing completed without unhandled errors.
- Kimi report in `reports/03-index-wsl.md` validates deliverables against this card.
