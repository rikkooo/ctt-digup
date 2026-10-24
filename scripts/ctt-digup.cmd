@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem ctt-digup.cmd - Windows front door for the DigUp MCP server (via mcp2cli).
rem Thin sibling of scripts\ctt-digup (bash). Forwards to mcp2cli @ctt-digup.
rem Docs: docs\MCP2CLI.md

set "BAKE=%CTT_DIGUP_BAKE%"
if not defined BAKE set "BAKE=ctt-digup"

rem ---- DIGUP_BIN default (honored if already set) -------------------------
if defined DIGUP_BIN goto digup_ok
if defined DIGUP_WSL_DISTRO goto digup_ok
if exist "%LOCALAPPDATA%\DigUp\helper\digup.exe" (
  set "DIGUP_BIN=%LOCALAPPDATA%\DigUp\helper\digup.exe"
  goto digup_ok
)
if exist "C:\Program Files\DigUp\helper\digup.exe" (
  set "DIGUP_BIN=C:\Program Files\DigUp\helper\digup.exe"
)
:digup_ok

rem ---- find mcp2cli -------------------------------------------------------
set "MCP2CLI_CMD="
if defined MCP2CLI (
  set "MCP2CLI_CMD=%MCP2CLI%"
  goto have_mcp2cli
)
where mcp2cli.cmd >nul 2>nul
if not errorlevel 1 (
  set "MCP2CLI_CMD=mcp2cli.cmd"
  goto have_mcp2cli
)
where mcp2cli >nul 2>nul
if not errorlevel 1 (
  set "MCP2CLI_CMD=mcp2cli"
  goto have_mcp2cli
)
if exist "%APPDATA%\npm\node_modules\@tronsfey\mcp2cli\bin\mcp2cli" (
  set "MCP2CLI_CMD=node "%APPDATA%\npm\node_modules\@tronsfey\mcp2cli\bin\mcp2cli""
  goto have_mcp2cli
)
echo ctt-digup: mcp2cli not found. Install with: npm install -g @tronsfey/mcp2cli 1>&2
exit /b 1
:have_mcp2cli

rem ---- find the MCP server entry -----------------------------------------
set "SERVER_JS="
if defined CTT_DIGUP_ROOT if exist "%CTT_DIGUP_ROOT%\src\mcp-server\index.js" set "SERVER_JS=%CTT_DIGUP_ROOT%\src\mcp-server\index.js"
if not defined SERVER_JS if exist "%~dp0..\src\mcp-server\index.js" set "SERVER_JS=%~dp0..\src\mcp-server\index.js"
if not defined SERVER_JS if exist "C:\devs\ctt-digup\src\mcp-server\index.js" set "SERVER_JS=C:\devs\ctt-digup\src\mcp-server\index.js"
if not defined SERVER_JS (
  echo ctt-digup: cannot find src\mcp-server\index.js ^(set CTT_DIGUP_ROOT^) 1>&2
  exit /b 1
)

rem ---- ensure the bake exists --------------------------------------------
if exist "%USERPROFILE%\.mcp2cli\bakes.json" (
  findstr /C:"\"%BAKE%\"" "%USERPROFILE%\.mcp2cli\bakes.json" >nul 2>nul
  if not errorlevel 1 goto have_bake
)
%MCP2CLI_CMD% bake create "%BAKE%" --mcp-stdio "node %SERVER_JS%" >nul
echo [ctt-digup] registered mcp2cli bake '%BAKE%' -^> node %SERVER_JS% 1>&2
:have_bake

rem ---- help / no args ----------------------------------------------------
if "%~1"=="" goto help
if /I "%~1"=="help" goto help
if "%~1"=="--help" goto help
if "%~1"=="-h" goto help

rem ---- list-tools --------------------------------------------------------
if /I "%~1"=="list-tools" goto list_tools
if /I "%~1"=="list" goto list_tools
if "%~1"=="--list" goto list_tools

rem ---- map friendly commands to MCP tool names ---------------------------
set "TOOL=%~1"
set "ARGS="
shift
if /I "%TOOL%"=="search" set "TOOL=digup_search"
if /I "%TOOL%"=="index" set "TOOL=digup_index"
if /I "%TOOL%"=="estimate" set "TOOL=digup_estimate"
if /I "%TOOL%"=="status" set "TOOL=digup_status"
if /I "%TOOL%"=="download-model" set "TOOL=digup_download_model"

rem ---- collect args; translate friendly sugar ----------------------------
rem (no pipes inside blocks; delayed expansion; valued flags consume next)
set "QUERY="
:loop
if "%~1"=="" goto run
set "A=%~1"
set "CH=!A:~0,1!"

rem valued mcp2cli passthrough: keep pair intact
if "!A!"=="--jq" goto take_pair
if "!A!"=="--input-json" goto take_pair
if "!A!"=="--describe" goto take_pair
if "!A!"=="--cache-ttl" goto take_pair

rem -n N / --limit N  ->  --limit N  (tool arg)
if "!A!"=="-n" goto take_limit
if "!A!"=="--limit" goto take_limit

rem --kind K,K  ->  repeated --kind (tool arg)
if "!A!"=="--kind" goto take_kind

rem --code [true|false]  ->  --code true|false
if "!A!"=="--code" goto take_code

rem --query S  ->  tool arg
if "!A!"=="--query" goto take_query

rem --folders DIR  ->  tool arg
if "!A!"=="--folders" goto take_pair

rem bare --json / --raw / --pretty / --debug / --no-cache / --list
if "!A!"=="--json" goto take_bare
if "!A!"=="--raw" goto take_bare
if "!A!"=="--pretty" goto take_bare
if "!A!"=="--debug" goto take_bare
if "!A!"=="--no-cache" goto take_bare

rem bare word: query (search) or folder (index/estimate)
if not "!CH!"=="-" if not "!CH!"=="" goto take_word

rem anything else: pass through unchanged
set ARGS=!ARGS! "%A%"
shift
goto loop

:take_pair
set ARGS=!ARGS! "%A%" "%~2"
shift
shift
goto loop

:take_bare
set ARGS=!ARGS! "%A%"
shift
goto loop

:take_limit
set ARGS=!ARGS! --limit %~2
shift
shift
goto loop

:take_kind
call :kinds "%~2"
set ARGS=!ARGS! !KINDOUT!
shift
shift
goto loop

:take_code
if /I "%~2"=="true" (
  set ARGS=!ARGS! --code true
  shift
) else if /I "%~2"=="false" (
  set ARGS=!ARGS! --code false
  shift
) else (
  set ARGS=!ARGS! --code true
)
shift
goto loop

:take_query
set ARGS=!ARGS! --query "%~2"
shift
shift
goto loop

:take_word
if /I "%TOOL%"=="digup_search" (
  if defined QUERY (
    set "QUERY=!QUERY! !A!"
  ) else (
    set "QUERY=!A!"
  )
  shift
  goto loop
)
if /I "%TOOL%"=="digup_index" (
  set ARGS=!ARGS! --folders "!A!"
  shift
  goto loop
)
if /I "%TOOL%"=="digup_estimate" (
  set ARGS=!ARGS! --folders "!A!"
  shift
  goto loop
)
set ARGS=!ARGS! "%A%"
shift
goto loop

:run
if defined QUERY set ARGS=--query "!QUERY!" !ARGS!
call %MCP2CLI_CMD% "@%BAKE%" %TOOL% %ARGS%
exit /b %ERRORLEVEL%

:list_tools
%MCP2CLI_CMD% "@%BAKE%" --list
exit /b %ERRORLEVEL%

:help
echo ctt-digup - DigUp MCP tools from any shell (via mcp2cli)
echo.
echo Usage:
echo   ctt-digup ^<friendly-command^> [args]     human-friendly subcommands
echo   ctt-digup ^<mcp-tool^> [flags]            raw MCP tool names (digup_*)
echo.
echo Friendly commands:
echo   search QUERY... [-n N] [--kind K,K]... [--code] [--json]
echo   index DIR... [--code]
echo   estimate DIR... [--json]
echo   status
echo   download-model
echo   list-tools
echo   help
echo.
echo Mapping (MCP tool ^<-^> ctt-digup ^<-^> digup native):
echo   digup_search         ^<-^> ctt-digup search         ^<-^> digup search QUERY
echo   digup_index          ^<-^> ctt-digup index          ^<-^> digup index DIR...
echo   digup_estimate       ^<-^> ctt-digup estimate       ^<-^> digup estimate DIR...
echo   digup_status         ^<-^> ctt-digup status         ^<-^> digup status
echo   digup_download_model ^<-^> ctt-digup download-model ^<-^> digup download-model
echo.
echo Examples:
echo   ctt-digup list-tools
echo   ctt-digup status
echo   ctt-digup search "zebra in a video" -n 5
echo   ctt-digup digup_search "zebra in a video" --limit 5
echo   ctt-digup estimate "C:\Users\me\Documents"
echo   ctt-digup --describe digup_search
echo.
echo Environment: DIGUP_BIN, DIGUP_WSL_DISTRO, CTT_DIGUP_BAKE, CTT_DIGUP_ROOT, MCP2CLI
echo Docs: docs\MCP2CLI.md
exit /b 0

:kinds
rem append repeated --kind flags for a comma-separated list into KINDOUT
set "KINDOUT="
set "K=%~1"
set "K=!K:,= !"
for %%k in (!K!) do set "KINDOUT=!KINDOUT! --kind %%k"
exit /b 0
