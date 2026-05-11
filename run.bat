@echo off
REM Запуск main.ahk через AHK v2 (портативный).
REM Полезно для отладки: окно cmd останется открытым, ошибки уйдут в stdout.
"M:\Sys\AutoHotkey\bin\v2\AutoHotkey64.exe" /ErrorStdOut "%~dp0main.ahk"
