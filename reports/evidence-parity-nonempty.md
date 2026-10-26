# Evidence: non-empty parity check (batch B, item 3)

Date: 2026-10-26 (WSL Ubuntu-26.04). Index has >1000 vectors — shared default `~/.local/share/digup/index/index.sqlite`.

## Status comparison (SAME index — WSL shared default)

Both commands run **inside WSL** with `DIGUP_BIN=/usr/local/bin/digup` and `DIGUP_WSL_DISTRO=Ubuntu-26.04` set:

- Native: `digup status`
- Wrapper: `bash /mnt/c/devs/ctt-digup/scripts/ctt-digup status`

```
native:  index: ~/.local/share/digup/index/index.sqlite
         vectors: 1,324 in 1,327 segments
         image 60 (57 done · 3 skipped) | pdf 4/4 done | doc 297 (170 done · 2 partial · 125 pending)
         size: 7.3 MB

ctt-digup (via MCP server): "index: ~/.local/share/digup/index/index.sqlite\nvectors: 1,401 in 1,404 segments\n..."
```

- **Same index path** for both routes (shared default). ✔
- Vector counts differ (1,324 vs 1,401) only because background embedding continued between the two calls (index was still ingesting: `doc ... pending`). Not a routing difference.

Note on paths: when invoked from **Git Bash on Windows** without `DIGUP_WSL_DISTRO`, the wrapper resolves the Windows helper `C:\Users\enric\AppData\Local\DigUp\helper\digup.exe` and would show a *different* (Windows-side) index. Setting `DIGUP_BIN=/usr/local/bin/digup DIGUP_WSL_DISTRO=Ubuntu-26.04` (or running inside WSL, as here) makes both routes hit the WSL shared index.

## Search comparison — query `clause about pets`, limit 3 (SAME index)

- Native: `digup search "clause about pets" -n 3 --json`
- Wrapper: `bash scripts/ctt-digup digup_search "clause about pets" --limit 3`

| # | path | cosine (native / wrapper) | score (native / wrapper) | segment |
|---|---|---|---|---|
| 1 | `/home/ubuntu/.local/share/ctt-digup-samples/lease-pets.txt` | 0.7104291915893555 / 0.7104291915893555 | 8.072368341738088 / 8.16535160512488 | chunk#9, loc 1 |
| 2 | `/tmp/digup-smoke/b.txt` | 0.7361887693405151 / 0.7361887693405151 | 7.920405188492394 / 8.030354163967845 | chunk#3, loc 1 |
| 3 | `/mnt/c/Users/enric/Downloads/iss11/forge/system/git/share/doc/git-doc/git-interpret-trailers.html` | 0.6478903889656067 / 0.6478903889656067 | 3.302431626652349 / 3.354225731973996 | chunk#1323, loc 5 |

- **Hit paths, order, excerpts, cosine values, segments all match exactly** between the ctt-digup CLI route and raw `digup` on the same WSL index. ✔
- `score`/`z` differ by ~0.09 between the two runs: the index grew between the calls (1,324 → 1,401 vectors as pending docs embedded), which shifts the z-gate normalization slightly. Cosine (raw similarity) is byte-identical, confirming identical retrieval.

## Verdict

Parity holds: the ctt-digup wrapper (mcp2cli → MCP server → digup) and native `digup` return the same hits with the same paths and cosines when pointed at the same index. Status shows the same `index:` line. (Exit status 0 for both routes.)
