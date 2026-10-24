@echo off
setlocal
set BIN=C:\Users\enric\AppData\Roaming\npm\node_modules\@tronsfey\mcp2cli\bin\mcp2cli
echo === ctt-digup ===
node "%BIN%" @ctt-digup digup_status >nul 2>&1
echo exit=%ERRORLEVEL%
echo === digupy ===
node "%BIN%" @digupy digup_status >nul 2>&1
echo exit=%ERRORLEVEL%
echo === digupx ===
node "%BIN%" @digupx digup_status >nul 2>&1
echo exit=%ERRORLEVEL%
echo === explicit stdio forward ===
node "%BIN%" --mcp-stdio "node C:/devs/ctt-digup/src/mcp-server/index.js" digup_status >nul 2>&1
echo exit=%ERRORLEVEL%
echo === explicit stdio backslash ===
node "%BIN%" --mcp-stdio "node C:\devs\ctt-digup\src\mcp-server\index.js" digup_status >nul 2>&1
echo exit=%ERRORLEVEL%
