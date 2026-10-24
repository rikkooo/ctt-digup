#!/usr/bin/env bash
set -euo pipefail
MC=(node /mnt/c/Users/enric/AppData/Roaming/npm/node_modules/@tronsfey/mcp2cli/bin/mcp2cli)
"${MC[@]}" bake delete digup 2>/dev/null || true
"${MC[@]}" bake create digup --mcp-stdio "node /mnt/c/devs/ctt-digup/src/mcp-server/index.js"
"${MC[@]}" bake list
echo "=== smoke: @digup digup_status ==="
"${MC[@]}" @digup digup_status
echo "=== smoke: @ctt-digup digup_search ==="
"${MC[@]}" @ctt-digup digup_search --query "zebra in a video" --limit 5
