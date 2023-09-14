
; ----------------------------------------------------------
; Сокращения
::м3ч::
Send2("м³/ч")
return
::квт::
Send2("кВт")
return
::ltd::
Send2("dev")
return
::дев::
Send2("dev")
return
::crom::
Send2("cron")
return
:o:GA::
Send2("Google Analitics")
return
:o:дднс::
Send2("Добрый день. Вы на связи?")
return
:o:ДДД::
Send2("Добрый день")
return
:o:ДУ::
Send2("Доброе утро")
return
:o:ДВ::
Send2("Добрый вечер")
return
:o:пож::
Send2("Пожалуйста")
return
:o:кол::
Send2("количество")
return
:*:@@::
Send2("vruzin@ya.ru")
return
#!u::
Send2("?utm_source=yandex&utm_medium=cpc&utm_campaign={campaign_id}&utm_content={ad_id}&utm_term={keyword}")
return
::ДДП::
Send2("Добрый день. Это Рузин Василий по поводу проекта: ")
return
:*:кон1::
Send2("Мои контакты: WhatsApp, Телефон: +79046464626; Skype: vruzin; Telegram: @vruzin (Лучше в Телеграмм)")
return
:*:кон2::
Send2("Мои контакты: WhatsApp, Телефон - в профиле; Skype: vruzin; Telegram: @vruzin (Лучше в Телеграмм)")
return
:*:кон3::
Send2("Я тут не сразу отвечаю, так как не постоянно тут сижу, поэтому если что, пишите в мессенджеры. Мои контакты: WhatsApp, Телефон: +79046464626; Skype: vruzin; Telegram: @vruzin (Лучше в Телеграмм)")
return
:*:зн1::
Send2("На отлично знаю: PHP, Go, MySQL, PgSQL, Vue (+Quasar), JS, CSS, SCSS, Less, Stylus.")
return
:*:qua1::
Send2("Quasar (VueJS) компилируется в PWA приложения, нативные приложения Windows, MacOS, iOS, Android, Linux.")
return

:*:пр1::
Send2("Несколько примеров на Vue:`r1. Самокаты: https://bit.ly/42IrTkR - Vue, Quasar`r2. меню для ресторанов: https://bit.ly/3DJ5ngE - Vue`r3. Лендинг - http://inqoob-main.vruzin.ru - vue`r4. Лендинг - http://levelcrowd.vruzin.ru - vue`r5. http://inqoob-main.vruzin.ru/adm.pdf — Админка — Vue+Golang+Materio`r6. http://inqoob-main.vruzin.ru/app.pdf — Админка — Vue+Golang+Firebase+SCSS`r7. http://inqoob-main.vruzin.ru/lp3.pdf — Лендинг упрощенный — Vue`r8. http://sms.artgroup.ru/prs/ - старенькое")
return



:*:ве1::
Send2("Добрый день.`r`rКоммерческий опыт больше 20 лет. `r`rОбращайтесь. Точную стоимость скажу, когда увижу макет.`r`rПо поводу валидности и всего что связано с этим - всё в лучшем виде. Занимаюсь оптимизацией, поэтому могу еще сделать например картинки спрайтами, это тоже ускоряет. Если есть желание, могу сделать оптимизацию картинок (скрипт делает порядка 20 оптимизаций и выбирает то, что меньше весит). При работе работаю обычно во Vue/Vite. На выходе получаете сжатые CSS и JS. На самом деле все зависит от задачи. И стоимость тоже. Можно даже слайдеры сделать без JS, только на HTML c CSS... Так что тут уже как требуется, так и сделаю.`r`rМои контакты: WhatsApp, Телефон: +79046464626`; Skype: vruzin`; Telegram: @vruzin (Лучше в Телеграмм)")
return

:*:адд1::Ленинградская область, Гатчинский район, д. Малые Колпаны, мкр. Речной, д. 4, кв. 147
:*:адр1::Ленинградская область, Гатчинский район, д. Малые Колпаны, мкр. Речной, д. 4, кв. 147
:*:реьд::HTML
:*:сыы::CSS
:*:пщдфтп::Golang
:*:мкгяшт::Vruzin
:*:знерщт::Python
:*:зрз::PHP
:*:ишекшч::Bitrix
:*:адюкг::fl.ru
:*:нфтвуч::yandex
:*:пщщпду::google
:*:ьмл::mvk
:*:ызи::spb
:*:юкг::.ru
:*:юсщь::.com
:*:ювщс::.doc
::реез::http
:*:реезы::https
:*:реезЖ::https:
:*:ыыр::ssh
:*:фрл::ahk
:*:мгуоы::VueJS
::мгу::Vue
::пшерги::Github
::пше::git
::фзш::API
::апи::API
:*:свт::CDN
:*:шз::IP
:*:вшкусе::Direct
::DO::Digital Ocean
::ВЩ::Digital Ocean
::ггшв::UUID
::шв::id
::тпштч::nginx
:*:ьныйд::MySQL
:*:зпыйд::PgSQL




; ----------------------------------------------------------
; В зависимости от времени суток пишет приветствие
::ДД::
Hello()
return
::LL::
Hello()
return

Hello(){
    if(A_Hour < 5)
      state = Доброй ночи
    else if(A_Hour < 10)
      state = Доброе утро
    else if(A_Hour < 17)
      state = Добрый день
    else
      state = Добрый вечер
    state=%state%.
    Send2(state)
}


#Persistent  ; Выполнять скрипт, пока не закроет пользователь.

; ----------------------------------------------------------

CapsLock & h:: ; горячая клавиша Win+H
; Получаем текущий выделенный текст. Вместо "ControlGet Selected" используется
; буфер обмена, так как он есть в большинстве редакторов
; (т.е. текстовых процессоров).  Сохраняем текущее содержимое буфера обмена,
; чтобы восстановить его позднее. Хотя обрабатывается только простой текст,
; это все же лучше, чем ничего:
SetNumLockState, Off
SetCapsLockState, Off

AutoTrim Off ; Сохраняет любой межстрочный интервал и пробел в конце текстовой строки в буфере обмена.
ClipboardOld = %ClipboardAll%
Clipboard = ; Чтобы обнаружение заработало, нужно начать с пустого значения.
Send ^c
ClipWait 1
if ErrorLevel ; Время ожидания ClipWait вышло.
  return
; Заменяем CRLF и/или LF на `n, чтобы использовать в строке автозамены опцию "send-raw" (R):
; Тоже самое делаем с любыми другими символами, иначе
; могут возникнуть проблемы в "сыром" режиме:
; Делаем эту замену вначале, чтобы избежать помех со стороны тех, которые идут далее.
StringReplace, Hotstring, Clipboard, ``, ````, All
StringReplace, Hotstring, Hotstring, `r`n, ``r, All ; В MS Word...`r работает лучше, чем `n.
StringReplace, Hotstring, Hotstring, `n, ``r, All
StringReplace, Hotstring, Hotstring, %A_Tab%, ``t, All
StringReplace, Hotstring, Hotstring, `;, ```;, All
Clipboard = %ClipboardOld% ; Восстанавливаем предыдущее содержимое буфера обмена.
; Каретка поля ввода (InputBox) устанавливается в более удобную позицию:
SetTimer, MoveCaret, 10
; Показываем поле ввода (InputBox), обеспечивая строку автозамены по умолчанию:
Text1 := "Напечатайте вашу аббревиатуру в указанном месте. "
Text2 := "`n"
Text3 =
(
  Пример: :R:btw`::by the way

  ГДЕ:
  R — опции,
  btw — сокращение (аббревиатура);

  ОПЦИИ:
  * (звездочка): в конце (пробел, точка или перевод строки) не требуется.
  ? (знак вопроса): строка автозамены запустится, даже если находится внутри другого слова.
  B0 (за буквой B идет цифра 0): стирание (автоматический забой) напечатанной вами аббревиатуры не производится.
  C: чувствительность к регистру. Регистр аббревиатуры должен точно совпадать с регистром
  C1: не подчиняется регистру, используемому при наборе текста.
  Kn: задержка нажатия клавиши. 0 рекомендуется; -1 нет задержки
  o (буква): опускает конечный символ (нет пробела в конце)
  R: сырой режим
  Подробно: https://ahk-wiki.ru/hotstrings
)
SetNumLockState, Off
SetCapsLockState, Off
Gui, Font, s48, Arial
InputBox, Hotstring, Новая автозамена, %Text1%%Text2%%Text3%,,757,413,,,,, :R:`::Send2("%Hotstring%")
if ErrorLevel <> 0 ; Пользователь нажал Cancel.
  return
IfInString, Hotstring, :R`:::
{
  MsgBox Вы не напечатали аббревиатуру. Строка автозамены не добавлена.
  return
}
; Иначе, добавляем строку автозамены и перезагружаем скрипт.
; Помещаем `n в начало, в случае, если в конце файла нет пустой строки.
FileAppend, `n%Hotstring%, %A_Scriptdir%\abbreviations.ahk
; FileAppend, `n%Hotstring%, %A_ScriptFullPath%
Reload
; В случае успешного завершения перезагрузка закроет этот экземпляр скрипта в режиме ожидания,
; поэтому строка ниже никогда не будет исполнена.
Sleep 200
Text1 := "Только что добавленная строка неверно отформатирована. "
Text2 := "Открыть файл для форматирования? "
Text3 := "Обратите внимание, что неисправные строки автозамены находятся внизу скрипта."
MsgBox, 4,, %Text1%%Text2%%Text3%
IfMsgBox, Yes, Edit
return

MoveCaret:
IfWinNotActive, Новая автозамена
  return
; Иначе, передвигаем курсор в поле ввода туда, где пользователь напечатает аббревиатуру.
Send {Home}{Right 3}
SetTimer, MoveCaret, Off
return



tt(text){
    ToolTip, %text%
    SetTimer, ttRemove, -2000
    return
}
ttRemove:
ToolTip
return


