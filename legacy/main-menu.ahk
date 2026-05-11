; ============================================================
; main-menu.ahk — AutoHotkey v2
; CapsLock+A: главное меню (переключение темы Windows Light/Dark).
; Иконка трея — лампочка из shell32.dll.
; ============================================================

A_IconTip := "Light/Dark Mode Switch (AHK)"
TraySetIcon("shell32.dll", 175)

CapsLock & a:: ShowMainMenu()

ShowMainMenu() {
    m := Menu()
    m.Add("&1. Тема Windows Light/Dark", ToggleWinTheme)
    m.Show()
}

ToggleWinTheme(*) {
    key := "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    cur := RegRead(key, "AppsUseLightTheme", 1)
    RegWrite(1 - cur, "REG_DWORD", key, "AppsUseLightTheme")
}
