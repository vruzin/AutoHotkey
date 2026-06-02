; ============================================================
; ui/Settings.ahk — лаунчер (Alfred-стиль) поверх фреймворка WebApp.
;
; Безрамочное окно с поиском по мере ввода:
;   • Режим «Запуск»: фильтр по всем функциям И пунктам меню (Docker › docker ps),
;     Enter — выполнить, окно прячется.
;   • Шестерёнка → режим «Настройки»: те же строки с галочками, вкл/выкл хоткеев
;     в рантайме (FeatureRegistry). Пункты меню не отключаются.
; Открывается кликом по иконке в трее и хоткеем (CapsLock+Shift).
; Прячется по Esc и при потере фокуса (hideOnBlur).
;
; Vue/HTML/CSS — в ui/apps/settings/. Здесь только AHK-логика и мост:
;   getData → Commands.Snapshot()  |  run → Commands.Run(id)  |  toggle → FeatureRegistry
;
; Зависит от: ui/WebApp.ahk, core/Commands.ahk, core/FeatureRegistry.ahk, core/Punto.ahk.
; ============================================================

class SettingsWindow {
    static app := 0

    ; ------------------------------------------------------------
    ; Show — открыть/показать лаунчер.
    static Show() {
        if !SettingsWindow.app {
            a := WebApp("settings", Map(
                "w", 920, "h", 600,
                "title", "Launcher",
                "frameless", true,
                "hideOnBlur", true
            ))
            a.On("getData",    (p) => SettingsWindow.OnGetData(p))
            a.On("run",        (p) => SettingsWindow.OnRun(p))
            a.On("toggle",     (p) => SettingsWindow.OnToggle(p))
            a.On("hide",       (p) => SettingsWindow.OnHide(p))
            a.On("abbrAdd",    (p) => SettingsWindow.OnAbbrAdd(p))
            a.On("abbrEdit",   (p) => SettingsWindow.OnAbbrEdit(p))
            a.On("abbrDelete", (p) => SettingsWindow.OnAbbrDelete(p))
            a.On("setHotkey",   (p) => SettingsWindow.OnSetHotkey(p))
            a.On("setTrigger",  (p) => SettingsWindow.OnSetTrigger(p))
            a.On("addHistory",  (p) => SettingsWindow.OnAddHistory(p))
            a.On("captureStart",(p) => SettingsWindow.OnCaptureStart(p))
            a.On("captureEnd",  (p) => SettingsWindow.OnCaptureEnd(p))
            SettingsWindow.app := a
        }
        SettingsWindow.app.Show(SettingsWindow._Data())
    }

    static Hide() {
        if SettingsWindow.app
            SettingsWindow.app.Hide()
    }

    ; ------------------------------------------------------------
    ; IsActive — окно лаунчера сейчас на переднем плане?
    ; Используется как контекст HotIf, чтобы аббревиатуры (глобальные
    ; hotstrings) НЕ срабатывали внутри поля поиска лаунчера. Фокус уходит
    ; в дочернее окно WebView2, поэтому сверяем корень активного окна.
    static IsActive() {
        if (!SettingsWindow.app || !SettingsWindow.app.gui)
            return false
        hwnd := SettingsWindow.app.gui.Hwnd
        fg := DllCall("GetForegroundWindow", "ptr")
        if (fg = hwnd)
            return true
        root := DllCall("GetAncestor", "ptr", fg, "uint", 2, "ptr")  ; GA_ROOT
        return (root = hwnd)
    }

    ; ------------------------------------------------------------
    ; _Data — снимок всех команд для лаунчера. Перед снимком синхронизируем
    ; флаг punto.autoswitch с мастер-состоянием Punto.enabled.
    static _Data() {
        try FeatureRegistry.SetEnabled("punto.autoswitch", Punto.enabled)
        return Commands.Snapshot()
    }

    ; ------------------------------------------------------------
    ; Обработчики моста (вызываются из Vue через ahk.call).
    static OnGetData(payload) {
        return SettingsWindow._Data()
    }

    ; Запуск команды: прячем окно, потом выполняем (чтобы фокус вернулся в
    ; целевое приложение — команды меню печатают в активное окно).
    static OnRun(payload) {
        id := payload.Has("id") ? payload["id"] : ""
        if (id = "")
            return ""
        SettingsWindow.Hide()
        Sleep 80
        try Commands.Run(id)
        return ""
    }

    static OnToggle(payload) {
        id := payload.Has("id") ? payload["id"] : ""
        on := payload.Has("value") ? !!payload["value"] : false
        if (id = "")
            return SettingsWindow._Data()
        ; punto.autoswitch — мастер-состояние в Punto.
        if (id = "punto.autoswitch")
            Punto.SetAutoswitch(on)
        else
            Commands.SetEnabled(id, on)        ; abbr.* → Abbreviations, остальное → FeatureRegistry
        return SettingsWindow._Data()
    }

    static OnHide(payload) {
        Suspend(false)              ; страховка: снять возможный Suspend от захвата
        SettingsWindow.Hide()
        return ""
    }

    ; ------------------------------------------------------------
    ; Аббревиатуры (вкладка «Абревиатуры» в лаунчере).
    static OnAbbrAdd(payload) {
        abbr := payload.Has("abbr") ? Trim(payload["abbr"]) : ""
        text := payload.Has("text") ? payload["text"] : ""
        if (abbr != "")
            Commands.AbbrAdd(abbr, text)
        return SettingsWindow._Data()
    }
    static OnAbbrEdit(payload) {
        abbr := payload.Has("abbr") ? payload["abbr"] : ""
        text := payload.Has("text") ? payload["text"] : ""
        if (abbr != "")
            Commands.AbbrEdit(abbr, text)
        return SettingsWindow._Data()
    }
    static OnAbbrDelete(payload) {
        abbr := payload.Has("abbr") ? payload["abbr"] : ""
        if (abbr != "")
            Commands.AbbrDelete(abbr)
        return SettingsWindow._Data()
    }

    ; ------------------------------------------------------------
    ; Переназначение клавиши (захват комбинации) и триггера-сокращения.
    ; Возвращает Map(data, result) — UI покажет ошибку при конфликте.
    static OnSetHotkey(payload) {
        id    := payload.Has("id") ? payload["id"] : ""
        combo := payload.Has("combo") ? payload["combo"] : ""
        res := (id != "") ? Commands.SetHotkey(id, combo) : Map("ok", false, "error", "нет id")
        return Map("data", SettingsWindow._Data(), "result", res)
    }
    static OnSetTrigger(payload) {
        id  := payload.Has("id") ? payload["id"] : ""
        trg := payload.Has("trigger") ? payload["trigger"] : ""
        res := (id != "") ? Commands.SetTrigger(id, trg) : Map("ok", false, "error", "нет id")
        return Map("data", SettingsWindow._Data(), "result", res)
    }

    ; История ввода (фаза 5): добавить запрос, вернуть обновлённый список.
    static OnAddHistory(payload) {
        q := payload.Has("q") ? payload["q"] : ""
        return Commands.AddHistory(q)
    }

    ; ------------------------------------------------------------
    ; Захват комбинации: на время записи приостанавливаем ВСЕ хоткеи скрипта,
    ; иначе нажатие уже занятой комбинации выполнит её команду. Ввод в WebView2
    ; идёт мимо AHK-хоткеев, поэтому Suspend не мешает самому захвату.
    ; HSuspend исключает hotstrings, но их и так глушит контекст лаунчера.
    static OnCaptureStart(payload) {
        Suspend(true)
        return ""
    }
    static OnCaptureEnd(payload) {
        Suspend(false)
        return ""
    }
}

; ============================================================
; ИНТЕГРАЦИЯ С ТРЕЕМ
; ============================================================
; Одинарный левый клик по иконке открывает лаунчер.
; Правый клик не перехватываем — остаётся стандартное меню AHK (Reload/Exit).
; 0x404 = AHK_NOTIFYICON, lParam = WM_LBUTTONUP(0x202) при левом клике.
SettingsTray_Init() {
    OnMessage(0x404, SettingsTray_OnIconMessage)
    try {
        A_TrayMenu.Insert("1&", "Лаунчер…", (*) => SettingsWindow.Show())
        A_TrayMenu.Insert("2&")          ; разделитель
        A_TrayMenu.Default := "Лаунчер…"
    }
}

SettingsTray_OnIconMessage(wParam, lParam, msg, hwnd) {
    if (lParam = 0x202)                  ; WM_LBUTTONUP — одинарный левый клик
        SettingsWindow.Show()
}
