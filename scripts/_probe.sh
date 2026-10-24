#!/usr/bin/env bash
set -x
mcp2cli @ctt-digup digup_search --query "test" --code true 2>&1 | tail -4
echo "=== bare --code ==="
mcp2cli @ctt-digup digup_search --query "test" --code 2>&1 | tail -4
echo "=== estimate folders ==="
mcp2cli @ctt-digup digup_estimate --folders "C:/devs/ctt-digup" --folders "C:/Users/enric/Documents" 2>&1 | tail -10
