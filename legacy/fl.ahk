; ============================================================
; fl.ahk — AutoHotkey v2
; CapsLock+F: меню шаблонов для откликов на FL.ru.
; Использует общую Send3 (clipboard-paste с меньшей задержкой) из main.ahk.
; ============================================================

; CapsLock+F — регистрируется в RegisterGlobalHotkeys через FeatureRegistry.
ShowFlMenu(*) {
    MenuData.Build(FlMenuData()).Show()
    SetNumLockState("Off")
    SetCapsLockState("Off")
}

; Данные меню (единый источник для AHK-меню и лаунчера).
FlMenuData() {
    return [
        Map("label", "Опыт",     "fn", Fl1),
        Map("label", "Опыт Vue", "fn", Fl2)
    ]
}

Fl1(*) {
    Send3("Коммерческий опыт больше 20 лет. А программирую с 6 лет. Больше 2000 сайтов сделал.`n")
    SetNumLockState("Off")
    SetCapsLockState("Off")
}

Fl2(*) {
    text := "JS, Vue - отлично`n"
    text .= "TS и Nuxt - на моем опыте не часто использовали, в основном для себя использовал... ибо удобно.`n"
    text .= "PWA - для себя делал, коммерческие нет, по сути ничего особенного`n"
    text .= "JWT и OAuth - без проблем, нюансы только в подходах на бек`n"
    text .= "REST - никогда проблем не был`n"
    text .= "Git, Github - много, GitLab - мало... на своём TrueNAS Scale сервере использую`n"
    text .= "CI/CD - на GitLab не ставил, на GitHub - да. Плюс Docker."
    Send3(text)
    Send "{Enter}"
    SetNumLockState("Off")
    SetCapsLockState("Off")
}

