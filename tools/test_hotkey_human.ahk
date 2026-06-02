; ============================================================
; tools/test_hotkey_human.ahk — юнит-тест HotkeyToHuman.
; Запуск: tools\test_hotkey_human.bat. Лог: tools\test_hotkey_human.log.
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, OutputDebug

#Include ..\features\HotkeyHuman.ahk

global gLog := "", gPass := 0, gFail := 0

Check(input, expected) {
    global gPass, gFail, gLog
    got := HotkeyToHuman(input)
    if (got == expected) {
        gPass++
        gLog .= "PASS: [" . input . "] -> " . got . "`n"
    } else {
        gFail++
        gLog .= "FAIL: [" . input . "] -> got [" . got . "] expected [" . expected . "]`n"
    }
}

Check("^+!u",          "Ctrl+Shift+Alt+U")
Check("^+!l",          "Ctrl+Shift+Alt+L")
Check("^+!j",          "Ctrl+Shift+Alt+J")
Check("CapsLock & i",  "CapsLock+I")
Check("CapsLock & g",  "CapsLock+G")
Check("CapsLock & 1",  "CapsLock+1")
Check("#c",            "Win+C")
Check("#Insert",       "Win+Insert")
Check("#z",            "Win+Z")
Check("^Volume_Mute",  "Ctrl+Mute")
Check("+PrintScreen",  "Shift+PrintScreen")
Check("^+!ScrollLock", "Ctrl+Shift+Alt+ScrollLock")
Check("^+!Insert",     "Ctrl+Shift+Alt+Insert")
Check("#^+t",          "Ctrl+Shift+Win+T")    ; канонический порядок Ctrl+Shift+Alt+Win
Check("Pause",         "Pause")
Check("!Pause",        "Alt+Pause")
Check("^Pause",        "Ctrl+Pause")
Check("CapsLock & Space", "CapsLock+Space")

gLog .= "`nRESULT: " . gPass . " passed, " . gFail . " failed`n"
try FileDelete(A_ScriptDir . "\test_hotkey_human.log")
FileAppend(gLog, A_ScriptDir . "\test_hotkey_human.log", "UTF-8")
ExitApp(gFail = 0 ? 0 : 1)
