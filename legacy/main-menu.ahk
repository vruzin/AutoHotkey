; ============================================================
; main-menu.ahk — AutoHotkey v2
; CapsLock+A: главное меню (переключение темы Windows Light/Dark).
; Иконка трея — лампочка из shell32.dll.
; ============================================================

A_IconTip := "Light/Dark Mode Switch (AHK)"
TraySetIcon("shell32.dll", 175)

; CapsLock+A — регистрируется в RegisterGlobalHotkeys через FeatureRegistry.
ShowMainMenu(*) {
    MenuData.Build(MainMenuData()).Show()
}

; Данные меню (единый источник для AHK-меню и лаунчера).
MainMenuData() {
    return [
        Map("label", "Тема Windows Light/Dark", "fn", ToggleWinTheme)
    ]
}

ToggleWinTheme(*) {
    key := "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    cur := RegRead(key, "AppsUseLightTheme", 1)
    RegWrite(1 - cur, "REG_DWORD", key, "AppsUseLightTheme")
}
