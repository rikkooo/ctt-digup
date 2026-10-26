# Evidence — Index drain & folder coverage (batch A)

Date: 2026-10-26 (UTC)
Workspace: `C:\devs\ctt-digup` (WSL Ubuntu-26.04, digup at `/usr/local/bin/digup`)
Index: `~/.local/share/digup/index/index.sqlite` (docs) + `code.sqlite` (code)
Logs: `/tmp/win-index-drain.log`, `/tmp/code-index-drain.log` (WSL)

## 1. `digup status` — before / after

### Before (2026-10-26T09:44:07Z)

```
index: ~/.local/share/digup/index/index.sqlite
vectors: 1,324 in 1,327 segments
  image           60   57 done · 3 skipped
  pdf              4   4 done
  doc            297   170 done · 2 partial · 125 pending
long files still being read: 2 (143 pages and chunks left)
size: 7.3 MB
```

Code (from prior state; `digup status` does not print a code section — code lives in `code.sqlite`):
47 pending of 298 tracked files.

### After — document pass (2026-10-26T09:52:55Z, ~9 min: 6 min bulk + ~70 s long-file tails)

```
index: ~/.local/share/digup/index/index.sqlite
vectors: 2,576 in 2,579 segments
  image           60   57 done · 3 skipped
  pdf              4   4 done
  doc            297   297 done
long files: (none)
size: 14.2 MB
```

Drain log tail: `done in 6 min: 124 done · 1 partial`, then `the rest of long files in 70 s: 3 done`
(git-config.html 161 chunks, git-log.html 62 chunks, user-manual.html 107 chunks).
**Doc index is fully drained: 297/297 done, 0 pending, 0 partial.**

### After — code pass (2026-10-26T09:57:26Z, ~4 min)

`digup index /home/ubuntu/devs --code` → `done in 4 min: 68 done · 1 skipped`
(sync: 11 new · 11 changed · 0 moved · 0 removed · 287 unchanged; skipped item: `evidence-windows-estimate.txt (not text)`).

`code.sqlite` final state (`files` table):

| state | count |
|---|---|
| done | 304 |
| skipped | 5 |
| **total** | **309** |

2,697 code segments indexed. **Code index fully drained: 0 pending.**

Note: `digup status` reports only the document index; code progress is visible in the index-run
log and in `code.sqlite` (`python3` + `sqlite3` module; `sqlite3` CLI is not installed in WSL).

## 2. `digup estimate` outputs

### `digup estimate /mnt/c/Users/enric/Documents /mnt/c/Users/enric/Downloads --json`

- **Documents**: `readable: true`, `files: {}` (0 indexable), `skipped: 3`, `left_out: {"other type": 3}`,
  `seconds: 0` → **Documents contains 0 indexable documents**; every file is skipped as "other type".
- **Downloads**: `readable: true`, `files: {"doc": 292, "image": 60, "pdf": 4}` = 356 indexable,
  `skipped: 1901` (`code or data file: 1417`, `other type: 413`, `inside a code project: 71`),
  `seconds ≈ 2006` (~33 min first-pass ETA), `long_files: 25`, `pdf_pages: 22/22`.
  Subfolder `Downloads/iss11`: doc 289 + image 59 (bulk of the corpus).

### `digup estimate /home/ubuntu/devs --json` (doc mode)

`readable: true`, `files: {}`, `skipped: 419` (`code or data file: 241`, `inside a code project: 127`,
`other type: 51`), `seconds: 0` → plain document mode indexes nothing here by design; the corpus is
indexed as code via `--code` (see §1, 304 done files / 2,697 segments).

## 3. Desktop / Documents readability

| path | result |
|---|---|
| `/mnt/c/Users/enric/Desktop` | **does not exist** (`ls: No such file or directory`) — classic Desktop is OneDrive-redirected on this machine |
| `/mnt/c/Users/enric/OneDrive/Desktop` | exists and readable; contains 2 PDFs (Conectta NAR1 filings) |
| `/mnt/c/Users/enric/Documents` | readable but 0 indexable docs (all 3 files skipped as "other type") |
| `/mnt/c/Users/enric/Downloads` | readable; the real Windows doc corpus (356 indexable files, all now indexed) |

## 4. Search smoke (`--json`, top-3)

### `digup search "invoice payment document" -n 3`

1. `~/.local/share/ctt-digup-samples/invoice-march.txt` — "Payment terms: net 30… invoice number" (score 10.70)
2. `~/.local/share/ctt-digup-samples/meeting-notes.txt` (score 5.00)
3. **`/mnt/c/Users/enric/Downloads/Conectta HK Limited New BRC 26-27 (1).pdf`** (score 4.73) — `/mnt/c` hit ✓

### `digup search "clause about pets" -n 3`

1. `~/.local/share/ctt-digup-samples/lease-pets.txt` — "Clause 12: Pets… one domestic cat" (score 8.21)
2. **`/tmp/digup-smoke/b.txt`** — "zebra in a video of pets" (score 8.06) ← stray smoke file, see §5
3. `/mnt/c/Users/enric/Downloads/iss11/forge/system/python/LICENSE.txt` (score 3.59) — `/mnt/c` hit ✓

### `digup search "code: retry a failed call with backoff" -n 3`

1. `/home/ubuntu/devs/ctt-digup/reports/09-agent-skill.md` (lines 37–51, score 4.58)
2. `/home/ubuntu/devs/ctt_comm/ctt/comm.py` (lines 1248–1265, score 4.55)
3. `/home/ubuntu/devs/ctt_comm/docs/design/C57-acl-swap-postmortem.md` (score 4.53)

All three smoke queries hit their expected path families (`/home/ubuntu` samples & code, `/mnt/c` docs).
`code:` prefix accepted and restricts to the code index.

## 5. Folder coverage

| Folder | Readable | Indexable files (indexed) | Notes |
|---|---|---|---|
| `/mnt/c/Users/enric/Documents` | yes | 0 | all 3 files skipped as "other type"; nothing to embed |
| `/mnt/c/Users/enric/Downloads` | yes | 356 (doc 292 · image 60 · pdf 4) | fully drained; 1,901 skipped (code/data/other); `iss11/` holds doc 289 + image 59 |
| `/mnt/c/Users/enric/Desktop` | **no** | — | path does not exist (OneDrive redirect) |
| `/mnt/c/Users/enric/OneDrive/Desktop` | yes | 2 PDFs (not indexed in this pass) | not part of the drained folder set |
| `/home/ubuntu/devs` (doc mode) | yes | 0 | everything left out as code/data by design |
| `/home/ubuntu/devs --code` | yes | 304 done · 5 skipped (2,697 segments) | fully drained via `--code` |
| `~/.local/share/ctt-digup-samples` | yes | present | fixture corpus; hits in both doc searches |
| `/tmp/digup-smoke/` | yes | 2 files (`a.txt`, `b.txt`) still indexed | see below — documented, not deleted |

### Stray indexed file: `/tmp/digup-smoke/b.txt`

`/tmp/digup-smoke/{a.txt,b.txt}` were smoke-test fixtures from earlier work. They remain **in the
document index** and surface in search (`clause about pets` → rank 2, score 8.06). The files still
exist on disk (`/tmp` is cleared on WSL restart, but the index rows persist). **Not deleted** per
no-data-loss policy; if a future cleanup is wanted, remove via digup's index-removal affordance
(re-index the folder / prune stale paths), not by hand-editing the SQLite.

## 6. Timeline

| UTC | event |
|---|---|
| 09:44:07 | before status captured; doc drain started (nohup → `/tmp/win-index-drain.log`) |
| 09:51:29 | doc pending 0; 3 long-file partials remaining |
| 09:52:44 | doc drain finished — 297/297 done |
| 09:52:55 | code drain started (nohup → `/tmp/code-index-drain.log`) |
| 09:57:11 | code drain finished — 68 done · 1 skipped this run; code.sqlite 304 done · 5 skipped |
| ~09:57–10:0x | estimates + search smoke executed |

---

## 6. Leftover cleanup (executed 2026-10-26)

All `/tmp` debris has been removed from disk and pruned from the index via
`digup index /tmp` (sync reports `0 removed` on the final pass):

| Artifact | Action |
|---|---|
| `/tmp/digup-smoke/{a,b}.txt` | deleted + rows pruned |
| `/tmp/k3work/` (test fixtures) | deleted + rows pruned |
| `/tmp/c113.2v8rXB/` scratch | deleted + rows pruned |
| `/tmp/{kA,kC,kQ,k1,out1,err1,err2}.txt`, `man_out.txt`, `run-card-*.txt`, `smoke-*.txt`, `fake-kimi-prompt.txt`, `digup-drain/*` | deleted + rows pruned |

Verification (post-cleanup):
- 8-query sweep ? **no `/tmp` paths** in doc-index search results
- `code:` search ? **no `/tmp` paths** in the code index
- Search smoke: pets ? `lease-pets.txt`; invoice ? `invoice-march.txt` + Conectta PDF;
  code backoff ? `ctt-digup`/`ctt_comm`/`DigUp` paths. All hits are user corpora.
- Final: `vectors: 2,578` ? `doc 304 ? 299 done ? 5 skipped` ? nothing pending
