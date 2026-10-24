#!/usr/bin/env bash
# Index Windows 11 user folders via WSL /mnt/c mounts (works without Windows UI).
set -euo pipefail

WIN_USER="${WIN_USER:-enric}"
MNT="${WIN_PREFIX:-/mnt/c/Users/${WIN_USER}}"
INDEX_DIR="${DIGUP_INDEX_WIN:-$HOME/.local/share/digup/index}"

FOLDERS=()
for d in "$MNT/Documents" "$MNT/Desktop" "$MNT/Downloads"; do
  [ -d "$d" ] && FOLDERS+=("$d")
done
[ ${#FOLDERS[@]} -gt 0 ] || { echo "No Windows folders found under $MNT"; exit 1; }

echo "==> Windows folders to index:"
printf '  %s\n' "${FOLDERS[@]}"
echo "==> Index dir: $INDEX_DIR"

echo "==> Estimate"
digup estimate "${FOLDERS[@]}" --index "$INDEX_DIR" --json || digup estimate "${FOLDERS[@]}" --index "$INDEX_DIR"

echo "==> Index"
digup index "${FOLDERS[@]}" --index "$INDEX_DIR" "$@"

echo "==> Status"
digup status --index "$INDEX_DIR"

echo "Done. Search with: digup search 'your words' --index $INDEX_DIR"
