#!/usr/bin/env bash
# Install DigUp engine + CLI on WSL Ubuntu-26.04 (and print Windows hint).
set -euo pipefail

TAG="${DIGUP_TAG:-v0.7.0-beta.3}"
DEB="DigUp_0.7.0-beta.3_amd64.deb"
URL="https://github.com/ARahim3/DigUp/releases/download/${TAG}/${DEB}"

echo "==> DigUp ${TAG} installer (WSL)"
if ! command -v digup >/dev/null 2>&1; then
  echo "==> Fetching ${DEB}"
  curl -fL -o "/tmp/${DEB}" "$URL"
  echo "==> Installing system libs"
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y libgomp1 || true
  echo "==> Installing package"
  sudo dpkg -i "/tmp/${DEB}" || sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -f
  sudo ln -sf /usr/lib/DigUp/helper/digup /usr/local/bin/digup
fi

echo "==> digup CLI"
digup --help | head -5

if [ ! -f "${HOME}/.local/share/digup/Models/embeddinggemma-2-Q8_0.gguf" ]; then
  echo "==> Downloading embedding model (~865 MB, once)"
  digup download-model
else
  echo "==> Model already present"
fi

echo "==> Windows 11: install DigUp_0.7.0-beta.3_x64-setup.exe (per-user)."
echo "    CLI helper: %LOCALAPPDATA%\\DigUp\\helper\\digup.exe"
echo "Done."
