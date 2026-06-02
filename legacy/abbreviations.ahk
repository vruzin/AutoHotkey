; ============================================================
; abbreviations.ahk — AutoHotkey v2
; Текстовые автозамены (hotstrings) и инструмент добавления новых.
; Зависит от Send2() — определена в главном скрипте.
; ============================================================

; ----------------------------------------------------------
; ПРОСТЫЕ ТЕКСТОВЫЕ СОКРАЩЕНИЯ перенесены в data/abbreviations.json и
; регистрируются динамически через core/Abbreviations.ahk (их можно
; редактировать/вкл-выкл/удалять из лаунчера без перезапуска).
; Здесь остаются только то, что не является простой подстановкой текста:
; длинные шаблоны через Send2, функции по времени суток, Win+Alt+U.

; ----------------------------------------------------------
; Длинные шаблоны (через Send2 — clipboard-paste, поддерживает Unicode и переводы строк)
:*:пр1::
{
    Send2("Несколько примеров на Vue:`r1. Самокаты: https://bit.ly/42IrTkR - Vue, Quasar`r2. меню для ресторанов: https://bit.ly/3DJ5ngE - Vue`r3. Лендинг - http://inqoob-main.vruzin.ru - vue`r4. Лендинг - http://levelcrowd.vruzin.ru - vue`r5. http://inqoob-main.vruzin.ru/adm.pdf — Админка — Vue+Golang+Materio`r6. http://inqoob-main.vruzin.ru/app.pdf — Админка — Vue+Golang+Firebase+SCSS`r7. http://inqoob-main.vruzin.ru/lp3.pdf — Лендинг упрощенный — Vue`r8. http://sms.artgroup.ru/prs/ - старенькое")
}

:*:ве1::
{
    Send2("Добрый день.`r`rКоммерческий опыт больше 20 лет. `r`rОбращайтесь. Точную стоимость скажу, когда увижу макет.`r`rПо поводу валидности и всего что связано с этим - всё в лучшем виде. Занимаюсь оптимизацией, поэтому могу еще сделать например картинки спрайтами, это тоже ускоряет. Если есть желание, могу сделать оптимизацию картинок (скрипт делает порядка 20 оптимизаций и выбирает то, что меньше весит). При работе работаю обычно во Vue/Vite. На выходе получаете сжатые CSS и JS. На самом деле все зависит от задачи. И стоимость тоже. Можно даже слайдеры сделать без JS, только на HTML c CSS... Так что тут уже как требуется, так и сделаю.`r`rМои контакты: WhatsApp, Телефон: +79046464626; Skype: vruzin; Telegram: @vruzin (Лучше в Телеграмм)")
}

; ----------------------------------------------------------
; Win+Alt+U — UTM-шаблон для Yandex Direct
#!u:: Send2("?utm_source=yandex&utm_medium=cpc&utm_campaign={campaign_id}&utm_content={ad_id}&utm_term={keyword}")

; ----------------------------------------------------------
; В зависимости от времени суток. В AHK v2 hotstring без X-флага
; выполняет ТОЛЬКО подстановку текста; чтобы вызвать функцию — нужен
; либо :X: префикс (execute), либо блочное тело {…}.
; C-флаг = case-sensitive: иначе ::LL:: ловит «ll», «Ll», «lL».
:C:ДД::
{
    Hello()
}
:C:LL::
{
    Hello()
}

Hello() {
    if (A_Hour < 5)
        state := "Доброй ночи"
    else if (A_Hour < 10)
        state := "Доброе утро"
    else if (A_Hour < 17)
        state := "Добрый день"
    else
        state := "Добрый вечер"
    Send2(state . ".")
}

; ----------------------------------------------------------
; CapsLock+H — мастер добавления новой автозамены
; (регистрируется в RegisterGlobalHotkeys через FeatureRegistry)
AddHotstringDialog(*) {
    SetNumLockState("Off")
    SetCapsLockState("Off")

    ; Получаем выделенный текст через буфер обмена
    clipBak := ClipboardAll()
    A_Clipboard := ""
    Send "^c"
    if !ClipWait(1)
        return  ; таймаут — ничего не выделено

    ; Экранируем спецсимволы AHK для использования в hotstring
    hs := A_Clipboard
    hs := StrReplace(hs, "``", "````")           ; обратные кавычки
    hs := StrReplace(hs, "`r`n", "``r")           ; CRLF → ``r
    hs := StrReplace(hs, "`n", "``r")             ; LF → ``r
    hs := StrReplace(hs, A_Tab, "``t")            ; табы
    hs := StrReplace(hs, ";", "```;")             ; точка с запятой

    A_Clipboard := clipBak                        ; вернуть буфер

    prompt := "Напечатайте вашу аббревиатуру в указанном месте.`n`n"
    prompt .= "Пример: :R:btw::by the way`n`n"
    prompt .= "ГДЕ:`n"
    prompt .= "  R — опции, btw — сокращение (аббревиатура)`n`n"
    prompt .= "ОПЦИИ:`n"
    prompt .= "  * — конечный пробел/точка/перевод строки не требуется`n"
    prompt .= "  ? — срабатывает внутри другого слова`n"
    prompt .= "  B0 — без автоматического стирания аббревиатуры`n"
    prompt .= "  C  — чувствительность к регистру`n"
    prompt .= "  C1 — не подчиняется регистру набора`n"
    prompt .= "  Kn — задержка нажатия клавиши (0 / -1)`n"
    prompt .= "  o  — опускает конечный символ`n"
    prompt .= "  R  — сырой режим`n`n"
    prompt .= "Подробно: https://ahk-wiki.ru/hotstrings"

    defaultLine := ":R:::Send2(`"" . hs . "`")"
    ib := InputBox(prompt, "Новая автозамена", "W757 H413", defaultLine)
    if (ib.Result != "OK")
        return

    if InStr(ib.Value, ":R:::") {
        MsgBox("Вы не напечатали аббревиатуру. Строка автозамены не добавлена.")
        return
    }

    FileAppend("`n" . ib.Value, A_ScriptDir . "\legacy\abbreviations.ahk")
    Reload
}
