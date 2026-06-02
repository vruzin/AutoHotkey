@echo off
cd /d "%~dp0"
"M:\Sys\AutoHotkey\bin\v2\AutoHotkey64.exe" test_hotkey_human.ahk
echo ExitCode=%ERRORLEVEL%
type test_hotkey_human.log
