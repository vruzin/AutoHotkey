CapsLock & z::
Menu, dop_menu, Add, .prg / inqoob, iq1
Menu, dop_menu, Add, &Git / global vruzin, iq2
Menu, dop_menu, Add
Menu, dop_menu, Add, Надо сделать: {|Купить|Подобрать|Подбор|Цена|Рассчитать|Расчет|Прайс|Прайслист|Недорого}, empty
Menu, dop_menu, Show
Menu, dop_menu, DeleteAll
return


iq1:
SendRaw, m:\.prg\inqoob\
return

iq2:
SendRaw, git config --global user.name "vruzin"
Send, {Enter}
SendRaw, git config --global user.email vruzin@ya.ru
return


empty:
return