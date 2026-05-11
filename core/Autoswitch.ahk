; ============================================================
; core/Autoswitch.ahk — детект ошибочной раскладки и автозамена (AHK v2)
;
; Получает на вход слово, законченное пользователем (Input.OnWordEnd),
; и решает: оставить как есть или переписать в другой раскладке.
;
; Решение:
;   1) Текущий режим (AppContext.ModeFor):
;        "off"           — Punto не трогает ввод вообще
;        "no_autoswitch" — слово запоминается в History (для Break),
;                          но автозамена не делается
;        "paste_mode"    — то же поведение, что normal (clipboard будет
;                          использоваться сценариями ввода Send2/Send3)
;        "normal"        — полный автопереключатель
;   2) Learning.IsKnown(word, lang) — пользователь уже подтвердил, что
;      слово правильное в этой раскладке. Не трогаем.
;   3) PuntoDict.LooksLikeWrongLayout — если словарь даёт suggestion,
;      делаем замену.
;
; Замена делает: BS×(len(word)+len(sep)) → Toggle → SendText(suggestion+sep).
; Записываем в History.
; ============================================================

class PuntoAutoswitch {
    ; Разделители, при которых выполняется автозамена (а не только запись).
    ; Enter/Tab не входят — после них поздно отменять (форма уже отправлена).
    static TRIGGER_SEPS := " .,;:!?"

    ; Доп. задержка после Toggle, чтобы Windows успела применить раскладку
    ; ко всем потокам до Send.
    static TOGGLE_DELAY_MS := 30

    ; ------------------------------------------------------------
    static OnWordEnd(word, separator) {
        if (word = "")
            return
        if (StrLen(word) < 2) {
            PuntoHistory.Push(Map(
                "type",       "userType",
                "wordTyped",  word,
                "wordFinal",  word,
                "langBefore", PuntoLayout.GetActiveLang(),
                "langAfter",  PuntoLayout.GetActiveLang(),
                "switched",   false,
                "separator",  separator
            ))
            return
        }

        mode := PuntoAppContext.ModeFor()
        if (mode = "off")
            return

        currentLang := PuntoLayout.GetActiveLang()

        ; Слово известно пользователю — доверяем
        if PuntoLearning.IsKnown(word, currentLang) {
            PuntoHistory.Push(Map(
                "type",       "userType",
                "wordTyped",  word,
                "wordFinal",  word,
                "langBefore", currentLang,
                "langAfter",  currentLang,
                "switched",   false,
                "separator",  separator
            ))
            return
        }

        decision := PuntoDict.LooksLikeWrongLayout(word, currentLang)
        if !decision["wrong"] {
            PuntoHistory.Push(Map(
                "type",       "userType",
                "wordTyped",  word,
                "wordFinal",  word,
                "langBefore", currentLang,
                "langAfter",  currentLang,
                "switched",   false,
                "separator",  separator
            ))
            return
        }

        ; «Wrong» — но автозамена только при triggering-separator и normal-режиме
        if (mode = "no_autoswitch" || !InStr(PuntoAutoswitch.TRIGGER_SEPS, separator, true)) {
            PuntoHistory.Push(Map(
                "type",       "userType",
                "wordTyped",  word,
                "wordFinal",  word,
                "langBefore", currentLang,
                "langAfter",  currentLang,
                "switched",   false,
                "separator",  separator,
                "suggestion",     decision["suggestion"],
                "suggestionLang", decision["suggestionLang"]
            ))
            return
        }

        ; Делаем автозамену
        PuntoAutoswitch.ApplyReplacement(word, decision["suggestion"], separator,
                                          currentLang, decision["suggestionLang"])
    }

    ; ------------------------------------------------------------
    ; ApplyReplacement — фактическая правка текста.
    static ApplyReplacement(wordTyped, suggestion, separator, langBefore, langAfter) {
        backspaces := StrLen(wordTyped) + StrLen(separator)

        PuntoInput.SendSilently(() => PuntoAutoswitch.DoReplacement(backspaces, separator, suggestion))

        PuntoHistory.Push(Map(
            "type",       "autoswitch",
            "wordTyped",  wordTyped,
            "wordFinal",  suggestion,
            "langBefore", langBefore,
            "langAfter",  langAfter,
            "switched",   true,
            "separator",  separator
        ))
    }

    static DoReplacement(backspaces, separator, suggestion) {
        Send("{BS " . backspaces . "}")
        PuntoLayout.Toggle()
        Sleep(PuntoAutoswitch.TOGGLE_DELAY_MS)
        SendText(suggestion . separator)
    }

    ; ------------------------------------------------------------
    ; UndoLastAutoswitch — откатить последнюю автозамену (Break).
    ; Возвращает true, если откат произошёл.
    static UndoLastAutoswitch() {
        if !PuntoHistory.LastAutoswitchFresh()
            return false

        last := PuntoHistory.Pop()
        backspaces := StrLen(last["wordFinal"]) + StrLen(last["separator"])

        PuntoInput.SendSilently(() => PuntoAutoswitch.DoReplacement(
            backspaces, last["separator"], last["wordTyped"]
        ))

        ; Запомнить, что пользователь не хочет автозамены этого слова
        PuntoLearning.Record(last["wordTyped"], last["langBefore"])
        return true
    }

    ; ------------------------------------------------------------
    ; ConvertLastWord — Break-режим «переключить последнее слово».
    ; Используется, когда автозамены не было (или она уже устарела).
    ; Слово, его раскладка, итоговая раскладка после переключения.
    static ConvertLastWord() {
        last := PuntoHistory.Last()
        if (last.Count = 0)
            return false
        word := last["wordTyped"]
        sep := last.Has("separator") ? last["separator"] : ""
        if (word = "")
            return false

        lang := last["langBefore"]
        direction := (lang = "ru") ? "cyr2lat" : "lat2cyr"
        converted := PuntoLayout.Convert(word, direction)

        backspaces := StrLen(word) + StrLen(sep)
        PuntoInput.SendSilently(() => PuntoAutoswitch.DoReplacement(backspaces, sep, converted))

        ; Слово теперь в правильной (для пользователя) раскладке — учим
        newLang := (lang = "ru") ? "en" : "ru"
        PuntoLearning.Record(converted, newLang)
        ; Обновляем последнюю запись истории, чтобы повторный Break не циклил
        last["wordTyped"] := converted
        last["wordFinal"] := converted
        last["langBefore"] := newLang
        last["langAfter"] := newLang
        last["switched"] := true
        last["timestamp"] := A_TickCount
        return true
    }
}
