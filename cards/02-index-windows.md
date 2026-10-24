# Card 02 — Index Windows 11 folders

## Goal
Index the Windows 11 user folders with DigUp so they are searchable by meaning.

## Why
"Index both Windows 11 folders and Wsl:Ubuntu-26.04 folders" is a core mission requirement.

## Implementation instructions

1. Decide folder set (defaults):
   - `C:\Users\<user>\Documents`
   - `C:\Users\<user>\Desktop`
   - `C:\Users\<user>\Downloads`
   - `C:\Users\<user>\Pictures` (optional — slower, vision-heavy)
2. Prefer one of these paths:
   - **A (native Windows DigUp):** add the folders in DigUp UI (tray → Settings → Folders) and wait for the first pass.
   - **B (WSL CLI over `/mnt/c`):** from WSL, use the DigUp CLI on the mounted paths:
     ```bash
     digup estimate /mnt/c/Users/enric/Documents /mnt/c/Users/enric/Desktop /mnt/c/Users/enric/Downloads
     digup index   /mnt/c/Users/enric/Documents /mnt/c/Users/enric/Desktop /mnt/c/Users/enric/Downloads
     ```
3. Keep indexing bounded if needed: `--limit N`, `--exclude DIR`, `--exclude-ext EXT`.
4. Record index location (`digup status`, default Application Support / `--index DIR`).
5. Smoke-test search:
   ```bash
   digup search "the clause about pets" --json | head
   digup status
   ```

## Deliverables
- [ ] Windows user folders estimated (`digup estimate` output captured)
- [ ] Index non-empty (`digup status` shows files/vectors)
- [ ] At least one semantic search returns results from Windows folders
- [ ] Commands and folder list documented in `docs/MANUAL.md`

## Acceptance criteria
- `digup status` reflects the Windows folder set; search hits include `/mnt/c/...` or Windows paths.
- Kimi report in `reports/02-index-windows.md` validates deliverables against this card.
