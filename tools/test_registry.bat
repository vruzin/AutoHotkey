@echo off
cd /d "%~dp0"
"M:\Sys\AutoHotkey\bin\v2\AutoHotkey64.exe" test_registry.ahk
echo ExitCode=%ERRORLEVEL%
type test_registry.log
