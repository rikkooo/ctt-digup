# Card 01 — Install DigUp engine + CLI

## Goal
Install DigUp (v0.7.0-beta.3 or newer) so that the `digup` CLI works on **WSL Ubuntu-26.04** and DigUp is available on **Windows 11**.

## Why
Everything else (indexing, MCP, CLI) depends on a working DigUp engine.

## Implementation instructions

### WSL Ubuntu-26.04
1. Clone or download DigUp:
   ```bash
   git clone https://github.com/ARahim3/DigUp ~/devs/DigUp
   ```
2. Download the Linux `.deb` from the beta release (`v0.7.0-beta.3`):
   ```bash
   curl -L -o /tmp/digup.deb \
     https://github.com/ARahim3/DigUp/releases/download/v0.7.0-beta.3/DigUp_0.7.0-beta.3_amd64.deb
   ```
3. Install system libs and the package:
   ```bash
   sudo DEBIAN_FRONTEND=noninteractive apt-get install -y libgomp1
   sudo dpkg -i /tmp/digup.deb || sudo apt-get install -y -f
   ```
4. Expose the engine CLI on PATH (the package installs it as a helper):
   ```bash
   sudo ln -sf /usr/lib/DigUp/helper/digup /usr/local/bin/digup
   digup --help
   ```
5. Download the embedding model (once, ~865 MB):
   ```bash
   digup download-model
   ```
   - Wait until `{"event":"done"}` appears in the log.

### Windows 11
1. Copy `DigUp_0.7.0-beta.3_x64-setup.exe` (fetched via WSL if Windows cannot reach GitHub) to `C:\devs\`.
2. Run the per-user installer silently or interactively:
   ```powershell
   C:\devs\DigUp_0.7.0-beta.3_x64-setup.exe
   ```
   - If SmartScreen blocks: More info → Run anyway (installer is unsigned beta).
3. Verify DigUp appears in the Start menu / tray and that its data folder exists under `%LOCALAPPDATA%`.
4. Optional CLI path: the Windows install ships `digup` helper next to the app; document its absolute path in `docs/MANUAL.md`.

## Deliverables
- [ ] `digup --help` prints usage on WSL
- [ ] `digup download-model` completed (model files present)
- [ ] DigUp installed on Windows 11 (Start menu entry or install dir present)
- [ ] Paths documented in `docs/MANUAL.md` § Setup

## Acceptance criteria
- Commands above run without error; model folder non-empty.
- Kimi report in `reports/01-install-digup.md` confirms each deliverable.
