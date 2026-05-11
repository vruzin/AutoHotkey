; ============================================================
; features/Case.ahk — преобразования регистра выделенного текста (AHK v2)
;
;   PuntoCase.Upper()     — ВСЁ ЗАГЛАВНЫМИ
;   PuntoCase.Lower()     — всё строчными
;   PuntoCase.Sentence()  — Первая буква каждого предложения большая
;                            (учитывает «и т.д.», «и т.п.», «т.е.», инициалы)
;   PuntoCase.Title()     — Каждое Слово С Большой Буквы
;   PuntoCase.Toggle()    — флип регистра каждого символа
;
; Все методы:
;   1) копируют выделенный текст (Ctrl+C);
;   2) преобразуют;
;   3) вставляют (Ctrl+V) — обычно текстовые редакторы сохраняют выделение
;      от Shift+Left после Send. Дополнительно восстанавливаем через
;      +{Left N} чтобы выделение точно осталось.
; ============================================================

class PuntoCase {

    ; Список «сокращений» которые НЕ закрывают предложение.
    static ABBREV := [
        "т.д", "т.п", "т.е", "т.к", "т.ч", "т.н",
        "и т.д", "и т.п", "и др", "и пр",
        "см", "сн", "стр", "напр", "т",
        "г", "ул", "д", "кв",      ; "г. Москва", "ул. ...", "д. 5", "кв. 12"
        "руб", "коп",
        "тыс", "млн", "млрд",
        "мин", "сек", "ч"
    ]

    ; ---- Pure-функции (только текст-в-текст, без clipboard) ----
    static UpperText(text) => StrUpper(text)
    static LowerText(text) => StrLower(text)

    static TitleText(text) {
        result := ""
        atWordStart := true
        Loop Parse, text {
            ch := A_LoopField
            if (ch = " " || ch = "`t" || ch = "`n" || ch = "`r"
                    || ch = "-" || ch = "_" || ch = "/" || ch = "(" || ch = "[") {
                result .= ch
                atWordStart := true
            } else if atWordStart {
                result .= StrUpper(ch)
                atWordStart := false
            } else {
                result .= StrLower(ch)
            }
        }
        return result
    }

    static SentenceText(text) {
        text := StrLower(text)
        result := ""
        capitalize := true
        i := 1
        L := StrLen(text)
        while (i <= L) {
            ch := SubStr(text, i, 1)
            if capitalize && PuntoCase.IsLetter(ch) {
                result .= StrUpper(ch)
                capitalize := false
            } else {
                result .= ch
            }
            if (ch = "." || ch = "!" || ch = "?") {
                tail := PuntoCase.LastWord(result, 1)
                isAbbrev := false
                for ab in PuntoCase.ABBREV {
                    if (tail = ab) {
                        isAbbrev := true
                        break
                    }
                }
                if !isAbbrev
                    capitalize := true
            } else if (ch = "`n" || ch = "`r") {
                capitalize := true
            }
            i++
        }
        return result
    }

    static ToggleText(text) {
        result := ""
        Loop Parse, text {
            ch := A_LoopField
            up := StrUpper(ch)
            lo := StrLower(ch)
            if (ch = up && ch != lo)
                result .= lo
            else if (ch = lo && ch != up)
                result .= up
            else
                result .= ch
        }
        return result
    }

    ; ---- Wrapper'ы для хоткеев: получают выделение и заменяют ----
    static Upper()    => PuntoCase.Apply(PuntoCase.UpperText.Bind(PuntoCase))
    static Lower()    => PuntoCase.Apply(PuntoCase.LowerText.Bind(PuntoCase))
    static Title()    => PuntoCase.Apply(PuntoCase.TitleText.Bind(PuntoCase))
    static Sentence() => PuntoCase.Apply(PuntoCase.SentenceText.Bind(PuntoCase))
    static Toggle()   => PuntoCase.Apply(PuntoCase.ToggleText.Bind(PuntoCase))

    static Apply(transformFn) {
        text := PuntoCase.GetSelection()
        if (text = "")
            return
        PuntoCase.PutSelection(transformFn.Call(text))
    }

    ; ------------------------------------------------------------
    ; Вспомогательные
    static IsLetter(ch) {
        code := Ord(ch)
        if ((code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A))
            return true
        if ((code >= 0x0410 && code <= 0x044F) || code = 0x0451 || code = 0x0401)
            return true
        return false
    }

    ; LastWord: последовательность из букв в конце строки (без последнего символа,
    ; который — точка или знак препинания). Возвращает «слово» (lower).
    static LastWord(s, skipFromEnd := 0) {
        n := StrLen(s) - skipFromEnd
        out := ""
        i := n
        while (i >= 1) {
            ch := SubStr(s, i, 1)
            if !PuntoCase.IsLetter(ch)
                break
            out := ch . out
            i--
        }
        return out
    }

    static GetSelection() {
        bak := ClipboardAll()
        A_Clipboard := ""
        Send "^c"
        if !ClipWait(0.4) {
            A_Clipboard := bak
            return ""
        }
        sel := A_Clipboard
        A_Clipboard := bak
        return sel
    }

    static PutSelection(text) {
        bak := ClipboardAll()
        A_Clipboard := text
        ClipWait(0.4)
        Send "^v"
        Sleep 80
        ; Восстановить выделение «назад» от текущего курсора на длину текста
        Send "+{Left " . StrLen(text) . "}"
        Sleep 30
        A_Clipboard := bak
    }
}
