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
    static TRIGGER_SEPS := " .,;:!?)]}>`"'"

    ; Доп. задержка после Toggle, чтобы Windows успела применить раскладку
    ; ко всем потокам до Send. (SendText печатает Unicode-точки и от раскладки
    ; не зависит, но Toggle делается для последующего пользовательского ввода.)
    static TOGGLE_DELAY_MS := 60

    ; ------------------------------------------------------------
    static OnWordEnd(word, separator) {
        if (word = "")
            return

        ; Раскладку слова определяем ТОЛЬКО по его символам, не доверяя
        ; PuntoLayout.GetActiveLang (она может отставать или ошибаться,
        ; особенно в Sublime/Qt-приложениях).
        cls := PuntoDict.ClassifyWord(word)
        if (cls["type"] = "lat")
            inputLang := "en"
        else if (cls["type"] = "cyr")
            inputLang := "ru"
        else
            inputLang := PuntoLayout.GetActiveLang()    ; fallback для пустых/смешанных

        PuntoInput.Log("OnWordEnd: word=[" . word . "] sep=[" . separator . "] type=" . cls["type"] . " inputLang=" . inputLang)

        ; ForceWords проходят независимо от Punto.enabled/no_autoswitch.
        ; Только при mode="off" не трогаем (игры, fullscreen).
        forceMode := PuntoAppContext.ModeFor()
        if (forceMode != "off") {
            canonical := PuntoForceWords.Find(word)
            if (canonical != "" && canonical != word
                    && InStr(PuntoAutoswitch.TRIGGER_SEPS, separator, true)) {
                PuntoInput.Log("  → FORCE: " . word . " → " . canonical)
                PuntoAutoswitch.ApplyForceWord(word, canonical, separator)
                return
            }
        }

        ; Если Punto выключена (Alt+Pause) — дальше не идём (только историю
        ; обновим, чтобы Break мог откатить ввод вручную).
        if !PuntoInput.enabled {
            PuntoHistory.Push(Map(
                "type",       "userType",
                "wordTyped",  word,
                "wordFinal",  word,
                "langBefore", inputLang,
                "langAfter",  inputLang,
                "switched",   false,
                "separator",  separator
            ))
            return
        }

        if (StrLen(word) < 2) {
            PuntoHistory.Push(Map(
                "type",       "userType",
                "wordTyped",  word,
                "wordFinal",  word,
                "langBefore", inputLang,
                "langAfter",  inputLang,
                "switched",   false,
                "separator",  separator
            ))
            return
        }

        mode := PuntoAppContext.ModeFor()
        PuntoInput.Log("  mode=" . mode)
        if (mode = "off")
            return

        ; Слово известно пользователю — доверяем
        if PuntoLearning.IsKnown(word, inputLang) {
            PuntoInput.Log("  → known to user, skip")
            PuntoHistory.Push(Map(
                "type",       "userType",
                "wordTyped",  word,
                "wordFinal",  word,
                "langBefore", inputLang,
                "langAfter",  inputLang,
                "switched",   false,
                "separator",  separator
            ))
            return
        }

        decision := PuntoDict.LooksLikeWrongLayout(word)
        PuntoInput.Log("  detector: wrong=" . (decision["wrong"] ? "Y" : "N")
            . " suggestion=[" . (decision.Has("suggestion") ? decision["suggestion"] : "") . "]"
            . " reason=" . decision["reason"])
        if !decision["wrong"] {
            PuntoHistory.Push(Map(
                "type",       "userType",
                "wordTyped",  word,
                "wordFinal",  word,
                "langBefore", inputLang,
                "langAfter",  inputLang,
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
                "langBefore", inputLang,
                "langAfter",  inputLang,
                "switched",   false,
                "separator",  separator,
                "suggestion",     decision["suggestion"],
                "suggestionLang", decision["suggestionLang"]
            ))
            return
        }

        ; Делаем автозамену
        PuntoInput.Log("  → APPLY: " . word . " → " . decision["suggestion"] . " (sep=" . separator . ")")
        PuntoAutoswitch.ApplyReplacement(word, decision["suggestion"], separator,
                                          inputLang, decision["suggestionLang"])
    }

    ; ------------------------------------------------------------
    ; ApplyReplacement — фактическая правка текста.
    static ApplyReplacement(wordTyped, suggestion, separator, langBefore, langAfter) {
        backspaces := StrLen(wordTyped) + StrLen(separator)

        PuntoInput.SendSilently(
            (*) => PuntoAutoswitch.DoReplacement(backspaces, separator, suggestion, langAfter))

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

    static DoReplacement(backspaces, separator, suggestion, targetLang := "") {
        Send("{BS " . backspaces . "}")
        if (targetLang != "")
            PuntoLayout.SwitchToLang(targetLang)
        else
            PuntoLayout.Toggle()
        Sleep(PuntoAutoswitch.TOGGLE_DELAY_MS)
        SendText(suggestion . separator)
    }

    ; ------------------------------------------------------------
    ; ApplyForceWord — замена слова на его «канонический» вариант
    ; из ForceWords. Раскладка после замены — EN (предполагаем, что
    ; force-слова обычно технические и латинские).
    static ApplyForceWord(wordTyped, canonical, separator) {
        backspaces := StrLen(wordTyped) + StrLen(separator)
        PuntoInput.SendSilently(
            (*) => PuntoAutoswitch.DoReplacement(backspaces, separator, canonical, "en"))
        PuntoHistory.Push(Map(
            "type",       "forceword",
            "wordTyped",  wordTyped,
            "wordFinal",  canonical,
            "langBefore", "",
            "langAfter",  "en",
            "switched",   true,
            "separator",  separator
        ))
    }

    ; ------------------------------------------------------------
    ; UndoLastAutoswitch — откатить последнюю автозамену (Break).
    ; Возвращает true, если откат произошёл.
    static UndoLastAutoswitch() {
        if !PuntoHistory.LastAutoswitchFresh()
            return false

        last := PuntoHistory.Pop()
        backspaces := StrLen(last["wordFinal"]) + StrLen(last["separator"])

        PuntoInput.SendSilently((*) => PuntoAutoswitch.DoReplacement(
            backspaces, last["separator"], last["wordTyped"], last["langBefore"]
        ))

        ; Запомнить, что пользователь не хочет автозамены этого слова
        PuntoLearning.Record(last["wordTyped"], last["langBefore"])
        return true
    }

    ; ------------------------------------------------------------
    ; ConvertLastWord — Break-режим «переключить последнее слово».
    ; Используется, когда автозамены не было (или она уже устарела).
    static ConvertLastWord() {
        last := PuntoHistory.Last()
        if (last.Count = 0)
            return false
        word := last["wordTyped"]
        sep := last.Has("separator") ? last["separator"] : ""
        if (word = "")
            return false

        ; Определяем направление по символам — не по сохранённому lang.
        cls := PuntoDict.ClassifyWord(word)
        if (cls["type"] = "lat") {
            direction := "lat2cyr"
            newLang   := "ru"
        } else if (cls["type"] = "cyr") {
            direction := "cyr2lat"
            newLang   := "en"
        } else {
            return false
        }
        converted := PuntoLayout.Convert(word, direction)

        backspaces := StrLen(word) + StrLen(sep)
        PuntoInput.SendSilently(
            (*) => PuntoAutoswitch.DoReplacement(backspaces, sep, converted, newLang))

        PuntoLearning.Record(converted, newLang)
        ; Обновляем последнюю запись истории, чтобы повторный Break не циклил
        last["wordTyped"]  := converted
        last["wordFinal"]  := converted
        last["langBefore"] := newLang
        last["langAfter"]  := newLang
        last["switched"]   := true
        last["timestamp"]  := A_TickCount
        return true
    }
}
