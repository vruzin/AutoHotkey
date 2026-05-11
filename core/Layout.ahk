; ============================================================
; core/Layout.ahk — работа с раскладками клавиатуры (AHK v2)
;
; Задачи:
;   • Узнать активную раскладку с учётом потока окна
;     (включая консоли — там раскладка хранится на процесс, а не на окно).
;   • Переключить раскладку активного окна через PostMessage 0x50.
;   • Сконвертировать текст между Lat↔Cyr с сохранением регистра
;     и знаков препинания (русская ЙЦУКЕН ↔ QWERTY).
;
; Все методы класса — статические, состояние не хранится.
; ============================================================

class PuntoLayout {
    ; Полные таблицы соответствия Lat↔Cyr с учётом верхнего регистра
    ; и пунктуации, которая привязана к раскладке (`.,;:?` и т.д.).
    static LAT := "``qwertyuiop[]asdfghjkl;'zxcvbnm,./~QWERTYUIOP{}ASDFGHJKL:`"ZXCVBNM<>?@#$^&"
    static CYR := "ёйцукенгшщзхъфывапролджэячсмитьбю.ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,`"№;:?"

    static LANG_EN := 0x0409
    static LANG_RU := 0x0419

    ; ------------------------------------------------------------
    ; GetActiveHKL — вернуть полный HKL (handle keyboard layout) активного окна.
    ; Для консоли (ConsoleWindowClass) используем GetConsoleKeyboardLayoutName,
    ; так как обычный GetKeyboardLayout даёт неактуальное значение.
    static GetActiveHKL() {
        hWnd := WinExist("A")
        if !hWnd
            return 0

        cls := WinGetClass("ahk_id " . hWnd)
        if (cls = "ConsoleWindowClass") {
            pid := WinGetPID("ahk_id " . hWnd)
            DllCall("AttachConsole", "UInt", pid)
            buf := Buffer(18, 0)            ; KL_NAMELENGTH = 9 wchars = 18 bytes
            DllCall("GetConsoleKeyboardLayoutName", "Ptr", buf)
            DllCall("FreeConsole")
            ; имя имеет вид "00000419" (8 hex), берём как HKL-low
            name := StrGet(buf, "UTF-16")
            return Integer("0x" . SubStr(name, -3))
        }

        threadId := DllCall("GetWindowThreadProcessId", "Ptr", hWnd, "UInt", 0)
        return DllCall("GetKeyboardLayout", "UInt", threadId, "Ptr")
    }

    ; ------------------------------------------------------------
    ; GetActiveLang — короткий идентификатор раскладки: "ru" или "en"
    ; (по нижним 14 битам HKL — language id Windows).
    ; Russian primary language id = 0x019, sublang 0x01 → 0x0419.
    ; English primary = 0x009 → 0x0409.
    static GetActiveLang() {
        hkl := PuntoLayout.GetActiveHKL()
        primary := hkl & 0x3FF                ; primary language ID (10 bit)
        return (primary = 0x019) ? "ru" : "en"
    }

    ; ------------------------------------------------------------
    ; IsRussian — true, если активна русская раскладка.
    static IsRussian() => PuntoLayout.GetActiveLang() = "ru"

    ; ------------------------------------------------------------
    ; Toggle — переключить активную раскладку (ru ↔ en).
    ; В отличие от PostMessage(0x50, 2, 0) — «next layout», тут мы
    ; явно загружаем нужный HKL и шлём его. Так стабильнее в IDE,
    ; Sublime, Chrome и других не-стандартных окнах.
    static Toggle() {
        hWnd := WinExist("A")
        if !hWnd
            return false
        current := PuntoLayout.GetActiveLang()
        targetLangId := (current = "ru") ? PuntoLayout.LANG_EN : PuntoLayout.LANG_RU
        return PuntoLayout.SwitchTo(targetLangId)
    }

    ; ------------------------------------------------------------
    ; SwitchToLang — переключить на указанный язык-код ("ru"/"en").
    static SwitchToLang(lang) {
        targetLangId := (lang = "ru") ? PuntoLayout.LANG_RU : PuntoLayout.LANG_EN
        return PuntoLayout.SwitchTo(targetLangId)
    }

    ; ------------------------------------------------------------
    ; SwitchTo — переключить на конкретную раскладку (по lang-id, напр. 0x0409).
    ; Шлёт WM_INPUTLANGCHANGEREQUEST окну-владельцу (toplevel) —
    ; так дочерние окна (диалоги IDE, всплывающие меню) подхватывают.
    static SwitchTo(langId) {
        hWnd := WinExist("A")
        if !hWnd
            return false
        hkl := DllCall("LoadKeyboardLayout", "Str", Format("{:08x}", langId), "Int", 1, "Ptr")
        if !hkl
            return false
        owner := DllCall("GetWindow", "Ptr", hWnd, "UInt", 4, "Ptr")   ; GW_OWNER
        target := owner ? owner : hWnd
        ; wParam=0 → switch by HKL; lParam = HKL целевой раскладки
        PostMessage(0x50, 0, hkl, , "ahk_id " . target)
        return true
    }

    ; ------------------------------------------------------------
    ; Convert — переписать текст с одной раскладки на другую.
    ;   text     — исходный текст
    ;   direction — "lat2cyr" или "cyr2lat".
    ; Несоответствующие символы (цифры, пробелы и т.п.) остаются как есть.
    static Convert(text, direction) {
        if (direction = "lat2cyr") {
            from := PuntoLayout.LAT
            to := PuntoLayout.CYR
        } else if (direction = "cyr2lat") {
            from := PuntoLayout.CYR
            to := PuntoLayout.LAT
        } else {
            return text
        }

        out := ""
        Loop Parse, text {
            ch := A_LoopField
            pos := InStr(from, ch, true)            ; точное совпадение по регистру
            out .= pos ? SubStr(to, pos, 1) : ch
        }
        return out
    }

    ; ------------------------------------------------------------
    ; AutoConvert — определить направление по содержимому: какая раскладка
    ; «более вероятна» при разборе побуквенно, и переписать на другую.
    ; Возвращает Map { text, direction, ratio } — ratio > 0 значит,
    ; больше символов в латинской таблице, < 0 — в кириллической.
    static AutoConvert(text) {
        u := 0
        Loop Parse, text {
            ch := A_LoopField
            hasLat := InStr(PuntoLayout.LAT, ch, true)
            hasCyr := InStr(PuntoLayout.CYR, ch, true)
            if (hasLat && !hasCyr)
                u++
            else if (hasCyr && !hasLat)
                u--
        }
        direction := (u >= 0) ? "lat2cyr" : "cyr2lat"
        return Map(
            "text",      PuntoLayout.Convert(text, direction),
            "direction", direction,
            "ratio",     u
        )
    }
}
