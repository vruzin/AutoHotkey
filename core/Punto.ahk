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
        PuntoForceWords.Init()
        PuntoSettings.Apply()              ; перетирает дефолты пользовательскими
        PuntoInput.Start()

        ; --- Базовые Pause-хоткеи Punto (сердце автопереключателя). ---
        ; Не выносим в FeatureRegistry: это управление самим Punto, оно есть
        ; в группе "punto" через флаг автозамены (Alt+Pause / окно настроек).
        Hotkey("Pause",   (*) => Punto.HandleBreak())
        Hotkey("+Pause",  (*) => Punto.ConvertSelection())
        Hotkey("!Pause",  (*) => Punto.Toggle())
        Hotkey("^Pause",  (*) => Punto.OpenPalette())
        Hotkey("^!d",     (*) => Punto.ShowDiagnostics())
        Hotkey("^!l",     (*) => Punto.ToggleDebug())

        ; --- Управляемые хоткеи через FeatureRegistry (можно вкл/выкл в окне). ---
        R := FeatureRegistry

        ; group: punto — фичи автопереключения, проверяются в Autoswitch через
        ; FeatureRegistry.IsActive(...). Это флаги без своей клавиши.
        R.RegisterFeature("punto.autoswitch", "punto", "Автопереключение раскладки (Punto)")
        R.RegisterFeature("punto.forcewords", "punto", "ForceWords (HTML/Vue/Golang в нужном регистре)")
        ; Мастер-состояние автозамены — Punto.enabled (из punto.autoswitch_enabled).
        ; Зеркалим его в флаг фичи, чтобы окно настроек показывало верное значение.
        R.SetEnabled("punto.autoswitch", Punto.enabled)

        ; group: text — текстовые операции (Ctrl+Shift+Alt+letter).
        R.Register("text.upper",    "text", "UPPER выделенное",                 "^+!u", (*) => PuntoCase.Upper())
        R.Register("text.lower",    "text", "lower выделенное",                 "^+!l", (*) => PuntoCase.Lower())
        R.Register("text.sentence", "text", "Первое предложение с заглавной",   "^+!s", (*) => PuntoCase.Sentence())
        R.Register("text.title",    "text", "Каждое Слово С Заглавной",         "^+!t", (*) => PuntoCase.Title())
        R.Register("text.toggle",   "text", "Флип регистра",                    "^+!y", (*) => PuntoCase.Toggle())
        R.Register("text.translit", "text", "Транслит ru↔lat (авто)",           "^+!j", (*) => PuntoTranslit.TranslitSelected())
        R.Register("text.number",   "text", "Число прописью",                   "^+!n", (*) => PuntoNumber.SelectionToText())
        R.Register("text.pasteraw", "text", "Вставить без форматирования",      "^+!v", (*) => PuntoPasteRaw.Paste())
        R.Register("text.reset",    "text", "Сбросить самообучаемый словарь",   "^+!r", (*) => Punto.ResetLearning())

        Punto.UpdateTray()
        Punto.initialized := true
    }

    ; ------------------------------------------------------------
    ; HandleBreak — реакция на Pause.
    ;
    ; Унифицированная toggle-логика: каждое нажатие переключает
    ; раскладку ТОГО ЖЕ места на экране туда-обратно.
    ;   1) Если в буфере набирается слово → конвертировать его
    ;      и положить в History как «текущее».
    ;   2) Иначе → конвертировать последнюю запись истории, ОБНОВЛЯЯ её
    ;      на новое состояние (не Pop). Поэтому повторное Pause переключит
    ;      её обратно, и так далее.
    static HandleBreak() {
        currentWord := PuntoInput.GetBuffer()
        if (currentWord != "" && StrLen(currentWord) >= 1) {
            Punto.ConvertCurrentWord(currentWord)
            return
        }

        last := PuntoHistory.Last()
        if (last.Count = 0) {
            Punto.Flash("Нечего переключать")
            return
        }
        if !Punto.ConvertHistoryEntry(last)
            Punto.Flash("Нечего переключать (смешанный регистр)")
    }

    ; ------------------------------------------------------------
    ; ConvertHistoryEntry — конвертировать слово из записи истории
    ; на ЕЁ месте на экране. ВАЖНО: обновляет запись in-place, не pop.
    ; Возвращает true, если конвертация произошла.
    static ConvertHistoryEntry(entry) {
        word := entry["wordFinal"]
        sep  := entry.Has("separator") ? entry["separator"] : ""
        if (word = "")
            return false

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
        converted  := PuntoLayout.Convert(word, direction)
        backspaces := StrLen(word) + StrLen(sep)

        PuntoInput.SendSilently(
            (*) => PuntoAutoswitch.DoReplacement(backspaces, sep, converted, newLang))

        ; Обновляем запись in-place: следующее Pause снова конвертирует.
        entry["wordTyped"]  := word
        entry["wordFinal"]  := converted
        entry["langBefore"] := (newLang = "ru") ? "en" : "ru"
        entry["langAfter"]  := newLang
        entry["switched"]   := true
        entry["timestamp"]  := A_TickCount

        PuntoLearning.Record(converted, newLang)
        Punto.Flash("⇋ " . converted)
        return true
    }

    ; ------------------------------------------------------------
    ; ConvertSelection — Shift+Pause: переключить раскладку выделенного
    ; текста, не сбивая выделение.
    static ConvertSelection() {
        text := PuntoCase.GetSelection()
        if (text = "") {
            Punto.Flash("Ничего не выделено")
            return
        }
        ; Используем AutoConvert — он сам решает направление по содержимому
        info := PuntoLayout.AutoConvert(text)
        converted := info["text"]
        PuntoCase.PutSelection(converted)
        ; Переключим системную раскладку под результат, для дальнейшего ввода
        targetLang := (info["direction"] = "cyr2lat") ? "en" : "ru"
        PuntoLayout.SwitchToLang(targetLang)
        Punto.Flash("⇋ выделение → " . targetLang)
    }

    ; ------------------------------------------------------------
    ; ConvertCurrentWord — заменить недонабранное слово (без разделителя)
    ; на его эквивалент в перевёрнутой раскладке + переключить раскладку
    ; для дальнейшего ввода. Раскладка слова определяется по его символам,
    ; не по системной раскладке.
    static ConvertCurrentWord(word) {
        cls := PuntoDict.ClassifyWord(word)
        if (cls["type"] = "lat") {
            direction := "lat2cyr"
            fromLang  := "en"
            toLang    := "ru"
        } else if (cls["type"] = "cyr") {
            direction := "cyr2lat"
            fromLang  := "ru"
            toLang    := "en"
        } else {
            Punto.Flash("Не могу определить раскладку слова")
            return
        }
        converted  := PuntoLayout.Convert(word, direction)
        backspaces := StrLen(word)

        PuntoInput.SendSilently((*) => Punto.DoConvert(backspaces, converted, toLang))

        PuntoInput.ResetBuffer()

        PuntoHistory.Push(Map(
            "type",       "autoswitch",
            "wordTyped",  word,
            "wordFinal",  converted,
            "langBefore", fromLang,
            "langAfter",  toLang,
            "switched",   true,
            "separator",  ""
        ))

        PuntoLearning.Record(converted, toLang)
        Punto.Flash("⇋ " . converted)
    }

    static DoConvert(backspaces, converted, targetLang) {
        Send("{BS " . backspaces . "}")
        PuntoLayout.SwitchToLang(targetLang)
        Sleep(PuntoAutoswitch.TOGGLE_DELAY_MS)
        SendText(converted)
    }

    ; ------------------------------------------------------------
    ; Toggle — Alt+Pause: включить/выключить автопереключатель.
    static Toggle() {
        Punto.SetAutoswitch(!Punto.enabled)
        Punto.Flash("Punto: " . (Punto.enabled ? "ON" : "OFF"))
    }

    ; ------------------------------------------------------------
    ; SetAutoswitch — явно задать состояние автозамены (из окна настроек
    ; или Alt+Pause). Синхронизирует Punto.enabled, InputHook, settings.json
    ; (мастер-ключ punto.autoswitch_enabled) и флаг фичи в FeatureRegistry.
    static SetAutoswitch(on) {
        Punto.enabled := !!on
        if Punto.enabled
            PuntoInput.Enable()
        else
            PuntoInput.Disable()
        PuntoSettings.Set("punto.autoswitch_enabled", on ? 1 : 0)
        try FeatureRegistry.SetEnabled("punto.autoswitch", on)
        Punto.UpdateTray()
    }

    ; ------------------------------------------------------------
    ; OpenPalette — Ctrl+Pause: командная палитра.
    ; Сейчас простая AHK Gui (ui/Palette.ahk); на этапе 4 заменим на
    ; WebView2 + Vue с современным интерфейсом.
    static OpenPalette() {
        PuntoPalette.Show()
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
    ; ResetLearning — Ctrl+Shift+Alt+R: сбросить самообучаемый словарь.
    static ResetLearning() {
        ans := MsgBox("Сбросить самообучаемый словарь?`n`nВсе слова,"
            . " которые Punto запомнила после Pause-исправлений, будут забыты.",
            "Punto", "YesNo Icon? Default2")
        if (ans != "Yes")
            return
        try FileDelete(A_ScriptDir . "\data\learned_words.json")
        PuntoLearning.words := Map()
        PuntoLearning.words.CaseSense := false
        PuntoLearning.dirty := false
        Punto.Flash("Самообучение сброшено")
    }

    ; ------------------------------------------------------------
    ; ToggleDebug — Ctrl+Alt+L: включить/выключить запись событий в
    ; data/punto_events.log. После включения каждый OnChar, OnWordEnd,
    ; вердикт детектора и автозамена пишутся в файл — удобно отлаживать,
    ; не запуская AHK-отладчик.
    static ToggleDebug() {
        if PuntoInput.debug {
            PuntoInput.DisableDebug()
            Punto.Flash("Debug OFF")
        } else {
            PuntoInput.EnableDebug()
            Punto.Flash("Debug ON → data\punto_events.log")
        }
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
