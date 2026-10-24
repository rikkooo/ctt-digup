#!/usr/bin/env bash
# Index WSL Ubuntu-26.04 folders with DigUp.
set -euo pipefail

INDEX_DIR="${DIGUP_INDEX_WSL:-$HOME/.local/share/digup/index}"

FOLDERS=()
for d in "$HOME/devs" "$HOME/Documents" "$HOME/Desktop" "$HOME/.local/share/ctt-digup-samples"; do
  [ -d "$d" ] && FOLDERS+=("$d")
done
[ ${#FOLDERS[@]} -gt 0 ] || { echo "No folders to index"; exit 1; }

echo "==> WSL folders to index:"
printf '  %s\n' "${FOLDERS[@]}"
echo "==> Index dir: $INDEX_DIR"

echo "==> Estimate"
digup estimate "${FOLDERS[@]}" --index "$INDEX_DIR" --json || digup estimate "${FOLDERS[@]}" --index "$INDEX_DIR"

echo "==> Index"
digup index "${FOLDERS[@]}" --index "$INDEX_DIR" "$@"

if [ -d "$HOME/devs" ]; then
  echo "==> Code index (optional, --code)"
  digup index "$HOME/devs" --index "$INDEX_DIR" --code || true
fi

echo "==> Status"
digup status --index "$INDEX_DIR"

echo "Done. Search with: digup search 'your words' --index $INDEX_DIR"
echo "Code search:        digup search 'code: symbol or behavior' --index $INDEX_DIR --code"
