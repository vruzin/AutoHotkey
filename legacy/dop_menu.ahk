; ============================================================
; dop_menu.ahk — AutoHotkey v2
; CapsLock+Z: служебные сниппеты (пути, git config).
; ============================================================

CapsLock & z:: ShowDopMenu()

ShowDopMenu() {
    m := Menu()
    m.Add(".prg / inqoob", DopIq1)
    m.Add("&Git / global vruzin", DopIq2)
    m.Add()  ; разделитель
    m.Add("Надо сделать: {|Купить|Подобрать|Подбор|Цена|Рассчитать|Расчет|Прайс|Прайслист|Недорого}", DopEmpty)
    m.Show()
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
