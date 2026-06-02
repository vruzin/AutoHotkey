; ============================================================
; dop_menu.ahk — AutoHotkey v2
; CapsLock+Z: служебные сниппеты (пути, git config).
; ============================================================

; CapsLock+Z — регистрируется в RegisterGlobalHotkeys через FeatureRegistry.
ShowDopMenu(*) {
    MenuData.Build(DopMenuData()).Show()
}

; Данные меню (единый источник для AHK-меню и лаунчера).
DopMenuData() {
    return [
        Map("label", ".prg / inqoob",        "fn", DopIq1),
        Map("label", "Git / global vruzin",  "fn", DopIq2),
        Map("sep", true),
        Map("label", "Надо сделать: {|Купить|Подобрать|Подбор|Цена|Рассчитать|Расчет|Прайс|Прайслист|Недорого}", "fn", DopEmpty)
    ]
}

DopIq1(*) {
    SendText("m:\.prg\inqoob\")
}

DopIq2(*) {
    SendText('git config --global user.name "vruzin"')
    Send "{Enter}"
    SendText("git config --global user.email vruzin@ya.ru")
}

DopEmpty(*) {
    ; заметка-разделитель, ничего не делает
}
