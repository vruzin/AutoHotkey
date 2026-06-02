; ============================================================
; tools/test_settings_ui.ahk — ручной тест окна настроек (WebView2 + Vue).
;
; Запускает минимальный набор: JSON, WebView2, Settings, FeatureRegistry,
; регистрирует пару фейковых хоткеев и сразу открывает окно настроек.
; Не подключает реальные хоткеи/Punto — только проверка UI и моста.
;
; Запуск: tools\test_settings_ui.bat (или AutoHotkey64.exe этот файл).
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, OutputDebug

#Include ..\lib\JSON.ahk
#Include ..\lib\Webview2\WebView2.ahk
#Include ..\core\Settings.ahk
#Include ..\core\FeatureRegistry.ahk
#Include ..\ui\WebApp.ahk

; ---- Заглушка Punto (Settings.ahk обращается к Punto.enabled/SetAutoswitch) ----
class Punto {
    static enabled := true
    static SetAutoswitch(on) {
        Punto.enabled := !!on
        ToolTip("Punto.SetAutoswitch(" . (on ? "ON" : "OFF") . ")")
        SetTimer(() => ToolTip(), -1000)
    }
}

#Include ..\ui\Settings.ahk

; ---- Фейковые обработчики хоткеев (ничего не делают) ----
NoOp(*) {
}

; ---- Регистрация тестовых фич/хоткеев в разных группах ----
R := FeatureRegistry
R.RegisterFeature("punto.autoswitch", "punto", "Автопереключение раскладки (Punto)")
R.RegisterFeature("punto.forcewords", "punto", "ForceWords (HTML/Vue/Golang)")
R.Register("text.upper", "text", "UPPER выделенное", "^+!u", NoOp)
R.Register("text.lower", "text", "lower выделенное", "^+!l", NoOp)
R.Register("mic.toggle", "mic",  "Переключить микрофон", "^Volume_Mute", NoOp)
R.Register("global.ip",  "global","Показать IP",          "CapsLock & i", NoOp)
R.Register("legacy.docker","legacy","Меню Docker",        "CapsLock & d", NoOp)

; ---- Открыть окно настроек сразу ----
SettingsWindow.Show()

; Esc — выход из теста
Esc:: ExitApp()
