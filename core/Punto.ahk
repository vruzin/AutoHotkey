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

        Punto.UpdateTray()
        Punto.initialized := true
    }

    ; ------------------------------------------------------------
    ; HandleBreak — реакция на Pause.
    ; Сначала пробуем откатить «свежую» автозамену; если её нет —
    ; конвертируем последнее введённое слово.
    static HandleBreak() {
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
}
