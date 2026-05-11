; ============================================================
; core/Input.ahk — глобальный захват ввода через InputHook (AHK v2)
;
; Поддерживает текущее «слово» — последовательность букв с момента
; последнего разделителя. Когда пользователь нажимает пробел / Enter /
; пунктуацию / стрелку, слово передаётся в PuntoAutoswitch для проверки.
;
; Состояние:
;   buffer   — текущее набираемое слово (UTF-8)
;   enabled  — глобальный флаг (Alt+Break)
;   suppress — true, когда Punto сама шлёт текст (чтобы не зациклиться)
; ============================================================

class PuntoInput {
    static buffer := ""
    static hook := 0
    static enabled := true
    static suppress := false

    ; Класс символа: 1 — буква, 0 — разделитель, -1 — управляющий
    ; Кеш-таблица для частых символов: word-character (a..z, а..я, -, ').
    ; Прочие считаем разделителями.

    static IsWordChar(ch) {
        if (ch = "")
            return false
        code := Ord(ch)
        ; ASCII буквы
        if ((code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A))
            return true
        ; Кириллица а..я / А..Я
        if ((code >= 0x0410 && code <= 0x044F))
            return true
        ; ё / Ё
        if (code = 0x0451 || code = 0x0401)
            return true
        ; дефис и апостроф (часть составных слов)
        if (ch = "-" || ch = "'")
            return true
        return false
    }

    ; ------------------------------------------------------------
    static Start() {
        if PuntoInput.hook
            return
        ; V — visible (пропускать символы дальше), L0 — без лимита по длине,
        ; I 1 — игнорировать наши собственные Send (которые мы шлём с SendLevel >= 1),
        ; T0 — без таймаута.
        ih := InputHook("V L0 I1 T0")
        ih.NotifyNonText := true
        ih.OnChar    := PuntoInput_OnChar
        ih.OnKeyDown := PuntoInput_OnKeyDown
        ih.KeyOpt("{All}", "N")
        ih.Start()
        PuntoInput.hook := ih
    }

    static Stop() {
        if !PuntoInput.hook
            return
        PuntoInput.hook.Stop()
        PuntoInput.hook := 0
        PuntoInput.buffer := ""
    }

    ; ------------------------------------------------------------
    ; OnChar — вызывается для каждого видимого набранного символа,
    ; уже после применения раскладки и Shift.
    static OnChar(ih, char) {
        if PuntoInput.suppress
            return
        if !PuntoInput.enabled
            return

        if PuntoInput.IsWordChar(char) {
            PuntoInput.buffer .= char
            return
        }

        ; Не-буква → завершить текущее слово (если есть) и сбросить буфер.
        ; Передаём в Autoswitch вместе с символом-разделителем.
        if (PuntoInput.buffer != "") {
            word := PuntoInput.buffer
            PuntoInput.buffer := ""
            PuntoAutoswitch.OnWordEnd(word, char)
        }
    }

    ; ------------------------------------------------------------
    ; OnKeyDown — вызывается для всех клавиш, включая не-печатные.
    ; Нас интересуют: Backspace, стрелки, Esc, Tab/Enter (для Enter/Tab
    ; в OnChar тоже придёт), Delete.
    static OnKeyDown(ih, vk, sc) {
        if PuntoInput.suppress
            return
        if !PuntoInput.enabled
            return

        switch vk {
            case 0x08:                                   ; Backspace
                if (StrLen(PuntoInput.buffer) > 0)
                    PuntoInput.buffer := SubStr(PuntoInput.buffer, 1, StrLen(PuntoInput.buffer) - 1)
            case 0x1B,                                   ; Escape
                 0x25, 0x26, 0x27, 0x28,                 ; стрелки ←↑→↓
                 0x21, 0x22, 0x23, 0x24,                 ; PgUp/PgDn/End/Home
                 0x2E:                                   ; Delete
                ; Пользователь редактирует текст в другом месте — сбрасываем буфер.
                PuntoInput.buffer := ""
        }
    }

    ; ------------------------------------------------------------
    ; Public API ------------------------------------------------------------
    static GetBuffer() => PuntoInput.buffer
    static ResetBuffer() {
        PuntoInput.buffer := ""
    }

    static Enable() {
        PuntoInput.enabled := true
        PuntoInput.buffer := ""
    }
    static Disable() {
        PuntoInput.enabled := false
        PuntoInput.buffer := ""
    }
    static IsEnabled() => PuntoInput.enabled

    ; SendSilently — отправить текст, временно отключив реакцию на собственный ввод.
    ; Использует SendLevel = 1, чтобы InputHook (с опцией I1) автоматически
    ; игнорировал эти события.
    static SendSilently(action) {
        wasSuppress := PuntoInput.suppress
        prevSendLevel := A_SendLevel
        PuntoInput.suppress := true
        SendLevel(1)
        try {
            action.Call()
        }
        SendLevel(prevSendLevel)
        PuntoInput.suppress := wasSuppress
    }
}

; Глобальные обёртки, которые InputHook принимает в OnChar/OnKeyDown.
; Прямо передавать статический метод класса через `ih.OnChar := Class.Method`
; в v2 работает не во всех редакциях — используем явные функции.
PuntoInput_OnChar(ih, char) {
    PuntoInput.OnChar(ih, char)
}
PuntoInput_OnKeyDown(ih, vk, sc) {
    PuntoInput.OnKeyDown(ih, vk, sc)
}
