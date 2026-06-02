; ============================================================
; features/HotkeyHuman.ahk — перевод хоткея из синтаксиса AHK в читаемый вид.
;
;   ^+!u            → Ctrl+Shift+Alt+U
;   CapsLock & i    → CapsLock+I
;   #c              → Win+C
;   ^Volume_Mute    → Ctrl+Mute
;   +PrintScreen    → Shift+PrintScreen
;   ^+!ScrollLock   → Ctrl+Shift+Alt+ScrollLock
;
; Чистая функция (без побочных эффектов) — покрыта tools/test_hotkey_human.ahk.
; ============================================================

; Карта спец-имён клавиш AHK → человекочитаемое имя.
; Глобальная статическая, строится один раз.
HotkeyHuman_Names() {
    static m := ""
    if (m != "")
        return m
    m := Map()
    m.CaseSense := false
    m["Volume_Mute"] := "Mute"
    m["Volume_Up"]   := "Vol+"
    m["Volume_Down"] := "Vol-"
    m["PrintScreen"] := "PrintScreen"
    m["ScrollLock"]  := "ScrollLock"
    m["CapsLock"]    := "CapsLock"
    m["NumLock"]     := "NumLock"
    m["LShift"]      := "Shift"
    m["RShift"]      := "Shift"
    m["LCtrl"]       := "Ctrl"
    m["RCtrl"]       := "Ctrl"
    m["LAlt"]        := "Alt"
    m["RAlt"]        := "Alt"
    m["Space"]       := "Space"
    m["Enter"]       := "Enter"
    m["Esc"]         := "Esc"
    m["Tab"]         := "Tab"
    m["Insert"]      := "Insert"
    m["Delete"]      := "Delete"
    m["Home"]        := "Home"
    m["End"]         := "End"
    m["PgUp"]        := "PgUp"
    m["PgDn"]        := "PgDn"
    m["Up"]          := "Up"
    m["Down"]        := "Down"
    m["Left"]        := "Left"
    m["Right"]       := "Right"
    m["Pause"]       := "Pause"
    return m
}

; HotkeyToHuman — основная функция.
HotkeyToHuman(key) {
    if (key = "")
        return ""

    mods := []           ; собранные модификаторы по порядку Ctrl, Shift, Alt, Win
    rest := key

    ; --- Форма "CapsLock & x" (кастомный префикс-модификатор) ---
    if InStr(rest, " & ") {
        parts := StrSplit(rest, " & ")
        out := []
        for p in parts
            out.Push(HotkeyHuman_Key(Trim(p)))
        return HotkeyHuman_Join(out)
    }

    ; --- Символьные модификаторы в начале: ^ + ! # (и уточнения < >) ---
    ; Срезаем их слева, пока встречаются. Остаток rest — основная клавиша.
    hasCtrl := false, hasShift := false, hasAlt := false, hasWin := false
    while (rest != "") {
        c := SubStr(rest, 1, 1)
        if (c = "^")
            hasCtrl := true, rest := SubStr(rest, 2)
        else if (c = "+")
            hasShift := true, rest := SubStr(rest, 2)
        else if (c = "!")
            hasAlt := true, rest := SubStr(rest, 2)
        else if (c = "#")
            hasWin := true, rest := SubStr(rest, 2)
        else if (c = "<" || c = ">")
            rest := SubStr(rest, 2)
        else
            break
    }

    if (hasCtrl)
        mods.Push("Ctrl")
    if (hasShift)
        mods.Push("Shift")
    if (hasAlt)
        mods.Push("Alt")
    if (hasWin)
        mods.Push("Win")

    mods.Push(HotkeyHuman_Key(rest))
    return HotkeyHuman_Join(mods)
}

; Привести имя одной клавиши к читаемому виду.
HotkeyHuman_Key(k) {
    k := Trim(k)
    if (k = "")
        return ""
    names := HotkeyHuman_Names()
    if names.Has(k)
        return names[k]
    ; scancode SCxxx — оставляем как есть (редкие кейсы разделителей)
    if (StrLen(k) = 1)
        return StrUpper(k)
    ; Слова вроде F1..F12, Numpad0 — с заглавной первой буквы как есть
    return k
}

HotkeyHuman_Join(arr) {
    out := ""
    for part in arr {
        if (part = "")
            continue
        out .= (out = "" ? "" : "+") . part
    }
    return out
}
