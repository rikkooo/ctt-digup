# Dual diligence — Card 01

Inspector: kimi cli   Date: 2026-10-24

## Summary

Overall verdict: **PASS**. Card 01 (Install DigUp engine + CLI) is fully satisfied: the `digup` CLI works on WSL Ubuntu-26.04 (package `dig-up 0.7.0~beta.3` installed via dpkg, symlinked to `/usr/local/bin/digup`, `digup --help` exits 0 with the full usage banner), both EmbeddingGemma 2 model files are present at the expected sizes, and DigUp is installed on Windows 11 with both an install directory and a Start menu entry. Paths are documented in `docs/MANUAL.md` § 1 Setup. The only follow-ups are minor: `scripts/install-digup.sh` does not exist (install steps live only in the card and the manual), and the manual gives a discovery command for the Windows `digup.exe` helper rather than its literal absolute path.

## Deliverable validation

| Deliverable | Result | Evidence |
|---|---|---|
| `digup --help` prints usage on WSL | PASS | `wsl.exe -- digup --help` → exit 0, prints full banner: "digup: search your files by meaning (DigUp developer CLI)" with `estimate / index / search / status / speed / eval / index-service / worker / search-service / download-model` subcommands and options. `which digup` → `/usr/local/bin/digup`; symlink `lrwxrwxrwx … /usr/local/bin/digup -> /usr/lib/DigUp/helper/digup`. Distro check: `PRETTY_NAME="Ubuntu 26.04.1 LTS"`. Package: `dpkg -l` → `ii dig-up 0.7.0~beta.3 amd64` (meets "v0.7.0-beta.3 or newer"). |
| `digup download-model` completed (model files present) | PASS | `~/.local/share/digup/Models/` (i.e. `/home/ubuntu/.local/share/digup/Models/`) contains exactly the two expected files with byte-exact sizes: `embeddinggemma-2-Q8_0.gguf` = **309855456** bytes and `mmproj-embeddinggemma-2-Q8_0.gguf` = **554821024** bytes (stat output). Total 864,676,480 B ≈ 865 MB, matching the card's "~865 MB" and the manual's "310 MB + 555 MB". Folder is non-empty. |
| DigUp installed on Windows 11 (Start menu entry or install dir present) | PASS | Both forms of evidence present. Install dir: `C:\Users\enric\AppData\Local\DigUp\` contains `DigUp.exe` (5,902,336 B), `uninstall.exe`, `THIRD-PARTY-NOTICES.txt`, `helper\` and `index\` subfolders. Helper CLI works: `C:\Users\enric\AppData\Local\DigUp\helper\digup.exe --help` → exit 0, same usage banner (binary 10,506,752 B, alongside llama.cpp/ggml/pdfium/ffmpeg runtime DLLs). Start menu entry: `DigUp.lnk` found in `C:\Users\enric\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\`. |
| Paths documented in `docs/MANUAL.md` § Setup | PASS | `docs/MANUAL.md` § 1 Setup: § 1.1 documents WSL install including `sudo ln -sf /usr/lib/DigUp/helper/digup /usr/local/bin/digup` (lines 39–41); § 1.2 documents the Windows installer and states the data folder lives under `%LOCALAPPDATA%` with a `Get-ChildItem` command to locate `digup.exe` (lines 57–61); § 1.3 documents the model path `~/.local/share/digup/Models` and `DIGUP_MODELS` (lines 65–82); § 1.4 documents `DIGUP_BIN` default `/usr/local/bin/digup` (lines 84–99). |

## Acceptance criteria

| Criterion | Result | Evidence |
|---|---|---|
| Commands above run without error; model folder non-empty | PASS | End state verifies the install commands ran cleanly: `dpkg -l` shows `dig-up 0.7.0~beta.3` in state `ii` (installed, no half-configured state); `digup --help` exits 0 on WSL (no `libgomp.so.1` error, so the `libgomp1` step succeeded); Windows `helper\digup.exe --help` exits 0. Model folder non-empty: two `.gguf` files totalling ~865 MB (see deliverable 2). Note: install commands were not re-executed (inspect-only diligence); verification is of the resulting system state. |
| Kimi report in `reports/01-install-digup.md` confirms each deliverable | PASS | This file: `reports/01-install-digup.md`, following `reports/TEMPLATE.md`, one row per card deliverable and criterion, each with quoted command output / paths. |

## Gaps / follow-ups

- `scripts/install-digup.sh` does not exist — `scripts/` contains only `ctt-digup`, `ctt-digup.cmd`, `kimi-diligence.sh`, `run-card.sh`. The card does not list this script as a deliverable (install steps live in the card and in `docs/MANUAL.md` § 1.1–1.3), so this is not a card failure; if a reproducible install script is wanted, it would be a small follow-up.
- Windows helper absolute path not spelled out: card step Windows-4 says "document its absolute path in `docs/MANUAL.md`", but § 1.2 step 4 gives a `Get-ChildItem` discovery command instead of the literal path. The verified absolute path on this machine is `C:\Users\enric\AppData\Local\DigUp\helper\digup.exe` — adding that one line to the manual would close this nuance.
