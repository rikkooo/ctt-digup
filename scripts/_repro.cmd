@echo off
setlocal EnableExtensions DisableDelayedExpansion
echo === call + percent ARGS ===
set ARGS=--query "zebra in a video" --limit 5
call mcp2cli.cmd "@ctt-digup" digup_search %ARGS%
echo errorlevel=%ERRORLEVEL%
