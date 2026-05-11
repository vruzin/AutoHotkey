@echo off
cd /d "%~dp0"
"M:\Sys\AutoHotkey\bin\v2\AutoHotkey64.exe" integration_test.ahk
echo ExitCode=%ERRORLEVEL%
echo ============= integration_test.log =============
type integration_test.log
