; ============================================================
; Direct.ahk — AutoHotkey v2
; CapsLock+W: макрос Find&Replace для Yandex Direct Commander.
; Логика: копируем выделенное, вставляем, открываем замену, отправляем Enter.
; ============================================================

CapsLock & w:: {
    Send "^c"
    Sleep 300
    Send "^v"
    Sleep 300
    Send "^h"
    Sleep 300
    Send "+{Tab}+{Tab}{Enter}"
}
