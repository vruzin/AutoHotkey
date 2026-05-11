@echo off
cd /d "%~dp0"
"M:\Sys\AutoHotkey\bin\v2\AutoHotkey64.exe" test_forcewords.ahk
echo ExitCode=%ERRORLEVEL%
type test_forcewords.log
