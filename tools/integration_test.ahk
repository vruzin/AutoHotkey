; ============================================================
; tools/integration_test.ahk — реальная проверка автозамены:
;   1. Запускает main.ahk в фоне (Punto).
;   2. Открывает Notepad, активирует.
;   3. Включает Punto debug-log через Ctrl+Alt+L.
;   4. Эмулирует физический ввод "ghbdtn " через keybd_event.
;   5. Копирует содержимое Notepad в Clipboard и сравнивает с "привет ".
;   6. Прикладывает punto_events.log в результат.
;
; Запускать строго ПОСЛЕ закрытия других экземпляров main.ahk.
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

testRoot := A_ScriptDir . "\.."
logPath  := A_ScriptDir . "\integration_test.log"
puntoLog := testRoot . "\data\punto_events.log"
mainExe  := "M:\Sys\AutoHotkey\bin\v2\AutoHotkey64.exe"
mainAhk  := testRoot . "\main.ahk"

try FileDelete(logPath)
try FileDelete(puntoLog)

Out(line) {
    global logPath
    FileAppend(line . "`n", logPath, "UTF-8")
}

Out("=== integration test " . FormatTime(, "yyyy-MM-dd HH:mm:ss") . " ===")

; NB: предыдущие экземпляры Punto нужно прикрыть ВНЕ этого скрипта
; (taskkill /IM AutoHotkey64 убил бы и нас самих).

; Запускаем main.ahk в фоне
Run('"' . mainExe . '" "' . mainAhk . '"',, , &mainPid)
Out("Started main.ahk pid=" . mainPid)
Sleep 4000   ; ждём загрузку словарей (~700 мс) + регистрацию хоткеев

; Открываем Notepad
Run("notepad.exe")
if !WinWait("ahk_class Notepad",, 5) {
    if !WinWait("ahk_exe Notepad.exe",, 3) {
        Out("FAIL: Notepad не открылся")
        try ProcessClose(mainPid)
        ExitApp 1
    }
}
Sleep 800
WinActivate
Sleep 500
Out("Notepad активен: " . WinGetTitle("A"))

; Переключаем на EN-раскладку (через PostMessage активному окну)
hwnd := WinExist("A")
hkl := DllCall("LoadKeyboardLayout", "Str", "00000409", "Int", 1, "Ptr")
PostMessage(0x50, 0, hkl, , "ahk_id " . hwnd)
Sleep 300

; Включаем Punto debug
Send "^!l"
Sleep 400

; Эмулируем физический ввод g h b d t n (VK 0x47, 0x48, 0x42, 0x44, 0x54, 0x4E)
keys := [0x47, 0x48, 0x42, 0x44, 0x54, 0x4E]
for vk in keys {
    DllCall("keybd_event", "UChar", vk, "UChar", 0, "UInt", 0, "UPtr", 0)
    Sleep 30
    DllCall("keybd_event", "UChar", vk, "UChar", 0, "UInt", 2, "UPtr", 0)
    Sleep 40
}
; Пробел — VK 0x20
DllCall("keybd_event", "UChar", 0x20, "UChar", 0, "UInt", 0, "UPtr", 0)
Sleep 30
DllCall("keybd_event", "UChar", 0x20, "UChar", 0, "UInt", 2, "UPtr", 0)

; Ждём чтобы Punto успела сделать автозамену
Sleep 2000

; Активируем Notepad заново (Flash ToolTip мог отнять фокус)
WinActivate("ahk_class Notepad")
Sleep 500

; Копируем содержимое Notepad
A_Clipboard := ""
Send "^a"
Sleep 250
Send "^c"
ok := ClipWait(3)
result := ok ? A_Clipboard : "<ClipWait timeout>"

Out("Result: [" . result . "]")
Out("Expected: [привет ]")
pass := (result = "привет ")
Out("PASS: " . (pass ? "YES" : "NO"))

; Прикладываем Punto-лог
Out("")
Out("=== punto_events.log ===")
if FileExist(puntoLog) {
    try {
        text := FileRead(puntoLog, "UTF-8")
        FileAppend(text, logPath, "UTF-8")
    }
} else {
    Out("(не создан)")
}

; Закрываем Notepad без сохранения
try {
    WinClose("ahk_class Notepad")
    Sleep 300
    Send "{Tab}{Enter}"     ; "Не сохранять"
}

; Закрываем именно наш Punto, не себя
try ProcessClose(mainPid)
ExitApp 0
