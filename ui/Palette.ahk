; ============================================================
; ui/Palette.ahk — командная палитра Punto v2 (AHK v2 Gui)
;
; Ctrl+Pause открывает поиск команд по центру экрана:
;   [    Поле ввода (фильтр)        ]
;   1. UPPER ВЫДЕЛЕННОЕ           ^+!u
;   2. lower выделенное           ^+!l
;   3. Первое предложение         ^+!s
;   4. Заголовок Каждого Слова    ^+!t
;   5. Транслит ru ↔ lat          ^+!j
;   ...
;
; Управление:
;   • Печать         — фильтрует по подстроке (case-insensitive)
;   • ↑/↓            — навигация по списку
;   • Enter          — выполнить выбранное
;   • 1..9 (цифра)   — выполнить N-й видимый пункт
;   • Esc            — закрыть
;
; На этапе 4 этот файл будет заменён на WebView2 + Vue.
; Текущий вариант — рабочий fallback без зависимостей.
; ============================================================

class PuntoPalette {
    static gui := 0
    static editBox := 0
    static listBox := 0
    static allCommands := []
    static filtered := []

    ; ------------------------------------------------------------
    static BuildCommands() {
        PuntoPalette.allCommands := [
            Map("title", "UPPER ВЫДЕЛЕННОЕ",          "hk", "^+!u", "fn", () => PuntoCase.Upper()),
            Map("title", "lower выделенное",          "hk", "^+!l", "fn", () => PuntoCase.Lower()),
            Map("title", "Первое предложение с заглавной", "hk", "^+!s", "fn", () => PuntoCase.Sentence()),
            Map("title", "Каждое Слово С Заглавной",  "hk", "^+!t", "fn", () => PuntoCase.Title()),
            Map("title", "Флип регистра",             "hk", "^+!y", "fn", () => PuntoCase.Toggle()),
            Map("title", "Транслит (ru ↔ lat, авто)", "hk", "^+!j", "fn", () => PuntoTranslit.TranslitSelected()),
            Map("title", "Транслит ГОСТ 7.79-2000",   "hk", "",    "fn", () => (PuntoTranslit.SetSystem("gost"),   PuntoTranslit.TranslitSelected())),
            Map("title", "Транслит МВД (паспорт)",     "hk", "",    "fn", () => (PuntoTranslit.SetSystem("mvd"),    PuntoTranslit.TranslitSelected())),
            Map("title", "Транслит простой (Google)",  "hk", "",    "fn", () => (PuntoTranslit.SetSystem("simple"), PuntoTranslit.TranslitSelected())),
            Map("title", "Число прописью",             "hk", "^+!n", "fn", () => PuntoNumber.SelectionToText()),
            Map("title", "Вставить без форматирования","hk", "^+!v", "fn", () => PuntoPasteRaw.Paste()),
            Map("title", "Открыть Google Translate",   "hk", "CapsLock+T", "fn", () => OpenGoogleTranslate("auto", "ru")),
            Map("title", "Внешний IP в подсказке",     "hk", "CapsLock+I", "fn", () => ShowIpAddresses()),
            Map("title", "─── Punto ───────────",      "hk", "",    "fn", (*) => 0),
            Map("title", "Punto: вкл/выкл (toggle)",   "hk", "Alt+Pause", "fn", () => Punto.Toggle()),
            Map("title", "Откатить/перевернуть слово", "hk", "Pause",     "fn", () => Punto.HandleBreak()),
            Map("title", "Диагностика Punto",          "hk", "Ctrl+Alt+D", "fn", () => Punto.ShowDiagnostics()),
            Map("title", "Сбросить самообучение",      "hk", "^+!r",  "fn", () => Punto.ResetLearning()),
            Map("title", "Запись событий ON/OFF",      "hk", "Ctrl+Alt+L","fn", () => Punto.ToggleDebug()),
            Map("title", "─── Окно ────────────",      "hk", "",    "fn", (*) => 0),
            Map("title", "Исключить текущее окно (полностью)", "hk", "", "fn", () => PuntoPalette.ExcludeCurrent("off")),
            Map("title", "Без автозамены для этого окна",      "hk", "", "fn", () => PuntoPalette.ExcludeCurrent("no_autoswitch")),
            Map("title", "Paste-режим для этого окна",         "hk", "", "fn", () => PuntoPalette.ExcludeCurrent("paste_mode")),
        ]
    }

    static ExcludeCurrent(mode) {
        info := PuntoAppContext.Current()
        if (info["exe"] = "") {
            Punto.Flash("Не получилось определить exe")
            return
        }
        if PuntoAppContext.AddRule(mode, info["exe"])
            Punto.Flash(info["exe"] . " → " . mode)
        else
            Punto.Flash("Уже в списке: " . info["exe"])
    }

    ; ------------------------------------------------------------
    static Show() {
        if PuntoPalette.gui {
            try PuntoPalette.gui.Show()
            return
        }
        PuntoPalette.BuildCommands()
        g := Gui("+AlwaysOnTop -SysMenu +Owner -Caption +ToolWindow")
        g.MarginX := 0
        g.MarginY := 0
        g.BackColor := "1E1E1E"
        g.SetFont("s14 cFFFFFF", "Segoe UI Variable Text")

        edit := g.AddEdit("xm ym w620 h36 Border -E0x200 Background2A2A2A cFFFFFF +0x100")
        edit.SetFont("s14 cFFFFFF")
        edit.OnEvent("Change", (*) => PuntoPalette.Refilter())

        list := g.AddListBox("xm y+0 w620 h420 Background2A2A2A cFFFFFF Choose1")
        list.OnEvent("DoubleClick", (*) => PuntoPalette.Execute())

        PuntoPalette.gui     := g
        PuntoPalette.editBox := edit
        PuntoPalette.listBox := list

        ; Хоткеи внутри окна палитры (контекстные через #HotIf)
        HotIfWinActive("ahk_id " . g.Hwnd)
        Hotkey("Esc",   (*) => PuntoPalette.Hide(),   "On")
        Hotkey("Enter", (*) => PuntoPalette.Execute(),"On")
        Hotkey("Down",  (*) => PuntoPalette.Move(+1), "On")
        Hotkey("Up",    (*) => PuntoPalette.Move(-1), "On")
        Loop 9 {
            n := A_Index
            Hotkey("!" . n, ((idx) => (*) => PuntoPalette.ExecuteIndex(idx))(n), "On")
        }
        HotIf()

        PuntoPalette.Refilter()
        ; По центру активного монитора
        monLeft := 0, monTop := 0, monRight := A_ScreenWidth, monBottom := A_ScreenHeight
        try {
            MonitorGetWorkArea(MonitorGetPrimary(), &monLeft, &monTop, &monRight, &monBottom)
        }
        w := 640, h := 480
        x := monLeft + ((monRight - monLeft) - w) // 2
        y := monTop  + ((monBottom - monTop)  - h) // 3
        g.Show(Format("x{} y{} w{} h{}", x, y, w, h))
        edit.Focus()
    }

    static Hide() {
        if !PuntoPalette.gui
            return
        PuntoPalette.gui.Hide()
    }

    static Refilter() {
        query := PuntoPalette.editBox.Value
        query := StrLower(Trim(query))

        PuntoPalette.filtered := []
        items := []
        for cmd in PuntoPalette.allCommands {
            if (query = "" || InStr(StrLower(cmd["title"]), query)) {
                PuntoPalette.filtered.Push(cmd)
                hk := cmd["hk"] != "" ? "   [" . cmd["hk"] . "]" : ""
                items.Push(cmd["title"] . hk)
            }
        }
        PuntoPalette.listBox.Delete()
        PuntoPalette.listBox.Add(items)
        if (items.Length > 0)
            PuntoPalette.listBox.Choose(1)
    }

    static Move(delta) {
        n := PuntoPalette.listBox.Value
        next := n + delta
        if (next < 1)
            next := 1
        else if (next > PuntoPalette.filtered.Length)
            next := PuntoPalette.filtered.Length
        PuntoPalette.listBox.Choose(next)
    }

    static Execute() {
        idx := PuntoPalette.listBox.Value
        PuntoPalette.ExecuteIndex(idx)
    }

    static ExecuteIndex(idx) {
        if (idx < 1 || idx > PuntoPalette.filtered.Length)
            return
        cmd := PuntoPalette.filtered[idx]
        PuntoPalette.Hide()
        ; Активное окно перед палитрой могло быть Notepad/Sublime —
        ; даём ему фокус назад, чтобы команды-операции работали с ним.
        Sleep 50
        try cmd["fn"].Call()
    }
}
