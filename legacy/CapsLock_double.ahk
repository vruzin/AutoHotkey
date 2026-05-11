; ============================================================
; CapsLock_double.ahk — AutoHotkey v2
; Многократное нажатие CapsLock:
;   1 нажатие  — сменить раскладку (Ctrl+Shift)
;   2 нажатия  — переключить CapsLock (Toggle)
;   3 нажатия  — сбросить состояние CapsLock и NumLock
;   4 нажатия  — то же (страховка)
;
; В будущем будет заменён на core/Layout.ahk с интеграцией в Punto.
; ============================================================

#UseHook
CapsLock:: HandleCapsLockMulti()
#UseHook False

HandleCapsLockMulti() {
    KeyWait "CapsLock"                       ; ждём отпускания
    if !KeyWait("CapsLock", "D T0.3") {      ; нет второго нажатия за 0.3с → одинарное
        Send "{Ctrl Down}{Shift Down}{RShift Down}{Shift Up}{Ctrl Up}{RShift Up}"
        return
    }
    KeyWait "CapsLock"
    if !KeyWait("CapsLock", "D T0.3") {      ; нет третьего → двойное
        SetCapsLockState(GetKeyState("CapsLock", "T") ? "Off" : "On")
        return
    }
    KeyWait "CapsLock"
    if !KeyWait("CapsLock", "D T0.3") {      ; нет четвёртого → тройное
        SetNumLockState "Off"
        SetCapsLockState "Off"
        return
    }
    ; четыре нажатия — то же, что три
    SetNumLockState "Off"
    SetCapsLockState "Off"
}
