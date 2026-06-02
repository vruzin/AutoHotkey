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
                "w", 720, "h", 520,
                "title", "Launcher",
                "frameless", true,
                "hideOnBlur", true
            ))
            a.On("getData", (p) => SettingsWindow.OnGetData(p))
            a.On("run",     (p) => SettingsWindow.OnRun(p))
            a.On("toggle",  (p) => SettingsWindow.OnToggle(p))
            a.On("hide",    (p) => SettingsWindow.OnHide(p))
            SettingsWindow.app := a
        }
        SettingsWindow.app.Show(SettingsWindow._Data())
    }

    static Hide() {
        if SettingsWindow.app
            SettingsWindow.app.Hide()
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
            FeatureRegistry.SetEnabled(id, on)
        return SettingsWindow._Data()
    }

    static OnHide(payload) {
        SettingsWindow.Hide()
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
