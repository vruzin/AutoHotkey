; ============================================================
; tools/test_registry.ahk — юнит-тест FeatureRegistry (без UI).
;
; Проверяет: регистрацию, IsActive, SetEnabled, каскад групп,
; Snapshot и persist в settings.json (плоские ключи с точками в id).
;
; Запуск: tools\test_registry.bat. Лог: tools\test_registry.log.
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, OutputDebug

#Include ..\lib\JSON.ahk
#Include ..\core\Settings.ahk
#Include ..\core\FeatureRegistry.ahk

global gLog := ""
global gPass := 0
global gFail := 0

Log(s) {
    global gLog
    gLog .= s . "`n"
}

Assert(name, cond) {
    global gPass, gFail
    if (cond) {
        gPass++
        Log("PASS: " . name)
    } else {
        gFail++
        Log("FAIL: " . name)
    }
}

NoOp(*) {
}

; --- Используем временный конфиг, чтобы не трогать рабочий settings.json ---
PuntoSettings.ConfigPath := A_ScriptDir . "\_test_settings.json"
try FileDelete(PuntoSettings.ConfigPath)
PuntoSettings.data := PuntoSettings.Defaults()
PuntoSettings.Initialized := true

R := FeatureRegistry

; --- Регистрация ---
R.RegisterFeature("punto.forcewords", "punto", "ForceWords")
R.Register("text.upper", "text", "UPPER", "^+!u", NoOp)
R.Register("mic.toggle", "mic",  "Mic",   "^Volume_Mute", NoOp)

; --- По умолчанию всё активно ---
Assert("default forcewords active", R.IsActive("punto.forcewords"))
Assert("default text.upper active", R.IsActive("text.upper"))

; --- Выключаем отдельный хоткей ---
R.SetEnabled("text.upper", false)
Assert("text.upper off after SetEnabled", !R.IsActive("text.upper"))

; --- Persist: плоский ключ с точками сохранился корректно ---
saved := R._GetSavedHotkey("text.upper", true)
Assert("text.upper persisted as false", !saved)

; --- id с точкой не создал вложенность punto→forcewords ---
sect := R._Section("hotkeys")
Assert("flat key 'text.upper' exists in hotkeys", sect.Has("text.upper"))
Assert("no nested 'text' key", !sect.Has("text"))

; --- Каскад группы: выключаем mic → mic.toggle неактивен, но флаг хоткея цел ---
R.SetGroupEnabled("mic", false)
Assert("mic.toggle inactive when group off", !R.IsActive("mic.toggle"))
Assert("mic.toggle own flag still on", R.items["mic.toggle"]["enabled"])
R.SetGroupEnabled("mic", true)
Assert("mic.toggle active again when group on", R.IsActive("mic.toggle"))

; --- Snapshot: структура групп ---
snap := R.Snapshot()
foundText := false
for g in snap {
    if (g["id"] = "text") {
        foundText := true
        Assert("text group has items", g["items"].Length >= 1)
    }
}
Assert("snapshot has text group", foundText)

; --- Перечитать из файла напрямую (Init жёстко ставит рабочий путь, поэтому
;     читаем временный конфиг сами) ---
txt := FileRead(PuntoSettings.ConfigPath, "UTF-8")
parsed := JSON.parse(txt)
diskVal := parsed["features"]["hotkeys"]["text.upper"]["enabled"]
Assert("text.upper=0 on disk after save", diskVal = 0)

; --- Итог ---
Log("")
Log("RESULT: " . gPass . " passed, " . gFail . " failed")
try FileDelete(A_ScriptDir . "\test_registry.log")
FileAppend(gLog, A_ScriptDir . "\test_registry.log", "UTF-8")
try FileDelete(PuntoSettings.ConfigPath)
ExitApp(gFail = 0 ? 0 : 1)
