; ============================================================
; core/Punto.ahk — главный класс-оркестратор Punto v2 (AHK v2)
;
; Связывает все core/-модули и регистрирует хоткеи:
;   Pause       — отмена последней автозамены ИЛИ переключение последнего слова
;   Alt+Pause   — переключение «автоматический переключатель ON/OFF»
;   Ctrl+Pause  — командная палитра (заглушка до этапа 4)
;
; Иконка трея: lightning, всплывающая подсказка "Punto v2 — ON/OFF".
; ============================================================

class Punto {
    static enabled := true
    static initialized := false

    static Init() {
        if Punto.initialized
            return
        ; Все модули — статические; первый вызов их инициализирует лениво,
        ; но мы прогреем кэши заранее для ровного отклика на первом слове.
        PuntoDict.Init()
        PuntoLearning.Init()
        PuntoAppContext.Init()
        PuntoInput.Start()

        ; Хоткеи. Стандартная клавиша PuntoSwitcher — Pause (она же Break без Ctrl).
        Hotkey("Pause",   (*) => Punto.HandleBreak())
        Hotkey("!Pause",  (*) => Punto.Toggle())
        Hotkey("^Pause",  (*) => Punto.OpenPalette())
        Hotkey("^!d",     (*) => Punto.ShowDiagnostics())

        Punto.UpdateTray()
        Punto.initialized := true
    }

    ; ------------------------------------------------------------
    ; HandleBreak — реакция на Pause.
    ; Приоритеты:
    ;   1) Если пользователь сейчас набирает слово (buffer не пуст) — переключить ЕГО.
    ;   2) Иначе — попробовать откатить «свежую» автозамену.
    ;   3) Иначе — конвертировать последнее завершённое слово из истории.
    static HandleBreak() {
        currentWord := PuntoInput.GetBuffer()
        if (currentWord != "" && StrLen(currentWord) >= 1) {
            Punto.ConvertCurrentWord(currentWord)
            return
        }
        if PuntoAutoswitch.UndoLastAutoswitch() {
            Punto.Flash("Откат автозамены")
            return
        }
        if PuntoAutoswitch.ConvertLastWord() {
            Punto.Flash("Раскладка слова переключена")
            return
        }
        Punto.Flash("Нечего отменять")
    }

    ; ------------------------------------------------------------
    ; ConvertCurrentWord — заменить недонабранное слово (без разделителя)
    ; на его эквивалент в перевёрнутой раскладке + переключить раскладку
    ; для дальнейшего ввода.
    static ConvertCurrentWord(word) {
        currentLang := PuntoLayout.GetActiveLang()
        direction   := (currentLang = "ru") ? "cyr2lat" : "lat2cyr"
        converted   := PuntoLayout.Convert(word, direction)
        backspaces  := StrLen(word)
        newLang     := (currentLang = "ru") ? "en" : "ru"

        PuntoInput.SendSilently((*) => Punto.DoConvert(backspaces, converted))

        ; После замены буфер обнуляем — иначе следующий разделитель попытается
        ; обработать комбинированный word + converted как новое слово.
        PuntoInput.ResetBuffer()

        ; Записываем как autoswitch — повторный Pause сразу откатит замену
        ; (через UndoLastAutoswitch), как ожидает пользователь.
        PuntoHistory.Push(Map(
            "type",       "autoswitch",
            "wordTyped",  word,
            "wordFinal",  converted,
            "langBefore", currentLang,
            "langAfter",  newLang,
            "switched",   true,
            "separator",  ""
        ))

        ; Запоминаем как «правильное в новой раскладке» для self-learning.
        PuntoLearning.Record(converted, newLang)
        Punto.Flash("⇋ " . converted)
    }

    static DoConvert(backspaces, converted) {
        Send("{BS " . backspaces . "}")
        PuntoLayout.Toggle()
        Sleep(PuntoAutoswitch.TOGGLE_DELAY_MS)
        SendText(converted)
    }

    ; ------------------------------------------------------------
    ; Toggle — Alt+Pause: включить/выключить автопереключатель.
    static Toggle() {
        Punto.enabled := !Punto.enabled
        if Punto.enabled {
            PuntoInput.Enable()
            Punto.Flash("Punto: ON")
        } else {
            PuntoInput.Disable()
            Punto.Flash("Punto: OFF")
        }
        Punto.UpdateTray()
    }

    ; ------------------------------------------------------------
    ; OpenPalette — Ctrl+Pause: позже это будет WebView2-палитра.
    ; Пока — заглушка с подсказкой.
    static OpenPalette() {
        Punto.Flash("Палитра — будет на этапе 4")
    }

    ; ------------------------------------------------------------
    static UpdateTray() {
        ; ID иконки молнии в shell32.dll
        TraySetIcon("shell32.dll", Punto.enabled ? 41 : 109)
        A_IconTip := "Punto v2 — " . (Punto.enabled ? "ON" : "OFF")
    }

    ; ------------------------------------------------------------
    ; Flash — короткое уведомление около курсора (ToolTip на 1.2 сек).
    static Flash(text) {
        ToolTip(text)
        SetTimer(() => ToolTip(), -1200)
    }

    ; ------------------------------------------------------------
    ; ShowDiagnostics — Ctrl+Alt+D: показать состояние Punto в MsgBox.
    ; Полезно когда автозамена не срабатывает — видно сразу, что не так.
    static ShowDiagnostics() {
        buf  := PuntoInput.GetBuffer()
        lang := PuntoLayout.GetActiveLang()
        hkl  := Format("0x{:08X}", PuntoLayout.GetActiveHKL())
        mode := PuntoAppContext.ModeFor()
        info := PuntoAppContext.Current()
        ds   := PuntoDict.LoadStats

        ; Проверка детектора на текущем буфере
        verdict := ""
        if (buf != "") {
            d := PuntoDict.LooksLikeWrongLayout(buf, lang)
            verdict := d["wrong"]
                ? ("wrong → " . d["suggestion"] . " (" . d["suggestionLang"] . ")")
                : "looks ok"
        }

        last := PuntoHistory.Last()
        lastStr := (last.Count = 0) ? "—"
            : last["type"] . ": " . last["wordTyped"]
              . (last.Has("separator") ? "[" . last["separator"] . "]" : "")

        msg := "Punto v2 — диагностика`n"
            . "==============================`n"
            . "Включено:           " . (Punto.enabled ? "ON" : "OFF") . "`n"
            . "Текущая раскладка:  " . lang . " (" . hkl . ")`n"
            . "Окно:               " . info["exe"] . " [" . info["class"] . "]`n"
            . "Режим для окна:     " . mode . "`n"
            . "`n"
            . "Текущий буфер:      [" . buf . "]`n"
            . "Длина буфера:       " . StrLen(buf) . "`n"
            . "Вердикт детектора:  " . verdict . "`n"
            . "`n"
            . "Словарь ru:         " . (ds.Has("ru") ? ds["ru"] : "0") . " слов`n"
            . "Словарь en:         " . (ds.Has("en") ? ds["en"] : "0") . " слов`n"
            . "Время загрузки:     " . (ds.Has("ms") ? ds["ms"] : "?") . " мс`n"
            . "`n"
            . "Последнее в истории: " . lastStr
        MsgBox(msg, "Punto", "Iconi")
    }
}
