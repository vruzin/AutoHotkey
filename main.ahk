; ----------------------------------------------------------
; Сокращения
::ltd::
Send2("dev")
return
::дев::
Send2("dev")
return
::инкуб::
Send2("inqoob")
return
::crom::
Send2("cron")
return
:o:GA::
Send2("Google Analitics")
return
:o*:дднс::
tt("Добрый день. Вы на связи?")
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
#!u:: ; Для вставки UTM меток 
Send2("?utm_source=yandex&utm_medium=cpc&utm_campaign={campaign_id}&utm_content={ad_id}&utm_term={keyword}")
return
:*:кон1::
Send2("Мои контакты: Viber, WhatsApp, Телефон: +79046464626; Skype: vruzin; Telegram: @vruzin")
return
:*:кон2::
Send2("Мои контакты: Viber, WhatsApp, Телефон - в профиле; Skype: vruzin; Telegram: @vruzin")
return
::ДДП::
Send2("Добрый день. Это Рузин Василий по поводу проекта: ")
return

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

CapsLock & i::
TmpFile=%A_ScriptDir%\-\ip
ExternalIP :=GetUrl("http://7fw.de/ipraw.php")
Send2(ExternalIP)
;  UrlDownloadToFile,http://7fw.de/ipraw.php,%TmpFile%
; FileReadLine,ExternalIP,%TmpFile%,1
ToolTip, %ExternalIP% <- Внешний`n=====`n%A_IPAddress1%`n%A_IPAddress2%`n%A_IPAddress3%`n%A_IPAddress4%`n
SetTimer, RemoveToolTip, -5000
return


GetUrl(url)
{
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr.Open("GET", url, true)
    whr.Send()
    ; Using 'true' above and the call below allows the script to remain responsive.
    whr.WaitForResponse()
    text:=whr.ResponseText
    return (text)
}

#IfWinActive ahk_exe Direct Commander.exe
:o:=ф::
Send2("= Фраза !~ Купить & Фраза !~ недорого & Фраза !~ подбор & Фраза !~ подобрать & Фраза !~ прайс & Фраза !~ рассчет & Фраза !~ цена")
return
#IfWinActive

; ----------------------------------------------------------
;  Автоисправление в GraphCalc запятой на точку
#IfWinActive ahk_exe GrphCalc.exe
NumpadDot::
SendRaw,.
return
#IfWinActive


; ----------------------------------------------------------
; Поверх всех окон. Win+Ctrl+alt+t
;#^!t::  Winset, Alwaysontop, , A 


; Переключение языка кнопкой CapsLock
; 1 нажатие - меняем язык
; 2 нажатия - CapsLock
; 3 нажатия - CapsLock
; 4 нажатия - CapsLock
#UseHook On
CapsLock::
    KeyWait, %A_ThisHotkey%
    KeyWait, %A_ThisHotkey%, D T0.3
    If ErrorLevel
        Send, {Ctrl Down}{Shift Down}{Shift Up}{Ctrl Up} ; 1 нажатие, сама клавиша.
    Else
    {
        KeyWait, %A_ThisHotkey%
        KeyWait, %A_ThisHotkey%, D T0.3
        If ErrorLevel
            ; 2 нажатия.
            SetCapsLockState % !GetKeyState("CapsLock", "T") ; Toggle CapsLock
        Else
        {
            KeyWait, %A_ThisHotkey%
            KeyWait, %A_ThisHotkey%, D T0.3
            If ErrorLevel
                ; 3 нажатия.
                SetCapsLockState % !GetKeyState("CapsLock", "T") ; Toggle CapsLock
            Else
                ; 4 нажатия.
                SetCapsLockState % !GetKeyState("CapsLock", "T") ; Toggle CapsLock
        }
    }
    Return
#UseHook Off


#IfWinActive ahk_exe idea64.exe
CapsLock & x::^+x
#IfWinActive

; ----------------------------------------------------------
; MVK Workspace. Win+Ctrl+Numpad7
#^Numpad7::
SetTitleMatchMode 2
; SublimeText
IfWinNotExist, (MVK) - Sublime Text
{
  Run, M:\Sys\SublimeText3\sublime_text.exe "m:\prg\MVK\MVK.sublime-project"
  WinWait, (MVK) - Sublime Text
}
WinMove, (MVK) - Sublime Text, , -1089, 700, 1101, 1373
; IDEA
if WinExist("mvk-spb.ru ahk_exe idea64.exe")
{
  WinActivate, mvk-spb.ru ahk_exe idea64.exe
  Winset, Top
}
else{
  Run, M:\Sys\IDEA\bin\idea64.exe "m:\prg\MVK\mvk-spb.ru"
  WinWait, "mvk-spb.ru ahk_exe idea64.exe"
}
return


; ----------------------------------------------------------
; MVK Workspace. Win+Ctrl+Numpad8
#^Numpad8::
SetTitleMatchMode 2
; SublimeText
IfWinNotExist, (Maryadi) - Sublime Text
{
  Run, M:\Sys\SublimeText3\sublime_text.exe "m:\prg\Maryadi\Maryadi.sublime-project"
  WinWait, (Maryadi) - Sublime Text
}
WinMove, (Maryadi) - Sublime Text, , -1089, 700, 1101, 1373
; IDEA
if WinExist("igo2london.com ahk_exe idea64.exe")
{
  WinActivate, igo2london.com ahk_exe idea64.exe
  Winset, Top
}
else{
  Run, M:\Sys\IDEA\bin\idea64.exe "m:\prg\Maryadi\igo2london.com\"
  WinWait, "igo2london.com ahk_exe idea64.exe"
}
return

; CapsLock + скобки и разделитель, в любой раскладке правильные
CapsLock & Space:: 
SelectedWord := getSelText()
if (SelectedWord)
{
    SelectedWord = {|%SelectedWord%}
    Send2(SelectedWord)
}
else{
  SendRaw {| }
}
SetNumLockState, Off
return

CapsLock & \::
SendRaw |
SetNumLockState, Off
return

CapsLock & [::
SendRaw {
SetNumLockState, Off
return

CapsLock & ]::
SendRaw }
SetNumLockState, Off
return


; ----------------------------------------------------------
; MVK Vivaldi. Win+Ctrl+Numpad4
; --user-data-dir="M:\Sys\Vivaldi\User Data\Profile 2" - профиль из папки
; #^Numpad4::
; Run, M:\Sys\Vivaldi\Application\vivaldi.exe --profile-directory="Profile 2"
; return

; VR Vivaldi.
CapsLock & 1::
Run, M:\Sys\Vivaldi\Application\vivaldi.exe --profile-directory="Default"
SetNumLockState, Off
return

; Maryadi Vivaldi.
CapsLock & 2::
Run, M:\Sys\Vivaldi\Application\vivaldi.exe --profile-directory="Profile 1"
SetNumLockState, Off
return

; MVK Vivaldi.
CapsLock & 3::
Run, M:\Sys\Vivaldi\Application\vivaldi.exe --profile-directory="Profile 2"
SetNumLockState, Off
return

; FL Vivaldi.
CapsLock & 4::
Run, M:\Sys\Vivaldi\Application\vivaldi.exe --profile-directory="Profile 5"
SetNumLockState, Off
return


; ----------------------------------------------------------
;  Калькулятор Win+C
#c::
IfWinExist, GraphCalc
{ ; Если открыт, то показать, если закрыт, тогда открыть
    WinActivate ; Использует окно, найденное выше.
    Winset, Top
}
else {
	Run, M:\Sys\GraphCalc\GrphCalc.exe
}
return

; ----------------------------------------------------------
;  OBS Win+Insert
#Insert::
IfWinNotExist, OBS
{
    Run, M:\Sys\OBS\bin\64bit\obs64.exe, M:\Sys\OBS\bin\64bit\
}
else{
    Send, #{Insert}
}
return

; ; ----------------------------------------------------------
; ; Распознавание области экрана. Shift+PrintScreen
+PrintScreen::
Run, "c:\ProgramData\Microsoft\Windows\Start Menu\Programs\ABBYY FineReader 15\ABBYY Screenshot Reader.lnk"
Sleep, 500 ;
Send !{Enter}
return

; ----------------------------------------------------------
; Приближение с мышкой. Shift+Alt+Insert
; У меня на клавиатуре это клавиша переключение приложений
+!Insert::
Process, Exist, ZoomIt.exe ;
if %ErrorLevel% = 0
{
  Run, "m:\Sys\ZoomIt\ZoomIt.exe"
}
Send +!{Insert}
return

; ----------------------------------------------------------
; Приближение без мышки. Ctrl+Shift+Alt+Insert
; У меня на клавиатуре это клавиша переключение приложений с зажатой Ctrl
^+!Insert::
Process, Exist, ZoomIt.exe ;
if %ErrorLevel% = 0
{
  Run, "m:\Sys\ZoomIt\ZoomIt.exe"
}
Send ^+!{Insert}
return







; ----------------------------------------------------------
; Выравнивание чатов в правом мониторе. Win+Ctrl+Numpad0
#^Numpad0::
IfWinExist, Viber
{
    WinActivate ; Использует окно, найденное выше.
    Winset, Top
}
else {
  Run, "%userprofile%\AppData\Local\Viber\Viber.exe"
}
IfWinExist, WhatsApp
{
  WinActivate ; Использует окно, найденное выше.
  Winset, Top
}
else {
	Run, "%userprofile%\AppData\Local\WhatsApp\WhatsApp.exe"
}
IfWinExist, Telegram
{
	WinActivate ; Использует окно, найденное выше.
  Winset, Top
}
else {
	Run, "M:\Sys\Telegram\Telegram.exe"
}
IfWinExist, Skype
{
  WinActivate ; Использует окно, найденное выше.
  Winset, Top
}
else {
	Run, "C:\Program Files (x86)\Microsoft\Skype for Desktop\Skype.exe"
}
WinMove, Telegram, , 3840, 314, 799, 1080
WinMove, Viber, , 4632, 776, 914, 625
WinMove, WhatsApp, , 4639, 314, 900, 648
Winset, Top
WinMove, Skype, , 5532, 314, 875, 1088
return

; ----------------------------------------------------------
; Все чаты на фон. Win+Ctrl+Numpad0
#^NumpadDot::  
Winset, Bottom, , WhatsApp
Winset, Bottom, , Telegram
Winset, Bottom, , Viber
Winset, Bottom, , Skype
return












GetInputLangID(window)  {
   if !hWnd := WinExist(window)
      return

   WinGetClass, winClass
   if (winClass != "ConsoleWindowClass") || (b := SubStr(A_OSVersion, 1, 2) = "10")  {
      if b  {
         WinGet, consolePID, PID
         childConhostPID := GetCmdChildConhostPID(consolePID)
         dhw_prev := A_DetectHiddenWindows
         DetectHiddenWindows, On
         hWnd := WinExist("ahk_pid " . childConhostPID)
         DetectHiddenWindows, % dhw_prev
      }
      threadId := DllCall("GetWindowThreadProcessId", Ptr, hWnd, UInt, 0)
      lyt := DllCall("GetKeyboardLayout", Ptr, threadId, UInt)
      langID := Format("{:#x}", lyt & 0x3FFF)
   }
   else  {
      WinGet, consolePID, PID
      DllCall("AttachConsole", Ptr, consolePID)
      VarSetCapacity(lyt, 16)
      DllCall("GetConsoleKeyboardLayoutName", Str, lyt)
      DllCall("FreeConsole")
      langID := "0x" . SubStr(lyt, -4)
   }
   return langID
}

GetCmdChildConhostPID(CmdPID)  {
   static TH32CS_SNAPPROCESS := 0x2, MAX_PATH := 260
   
   h := DllCall("CreateToolhelp32Snapshot", UInt, TH32CS_SNAPPROCESS, UInt, 0, Ptr)
   VarSetCapacity(PROCESSENTRY32, size := 4*7 + A_PtrSize*2 + (MAX_PATH << !!A_IsUnicode), 0)
   NumPut(size, PROCESSENTRY32, "UInt")
   res := DllCall("Process32First", Ptr, h, Ptr, &PROCESSENTRY32)
   while res  {
      parentPid := NumGet(PROCESSENTRY32, 4*4 + A_PtrSize*2, "UInt")
      if (parentPid = CmdPID)  {
         exeName := StrGet(&PROCESSENTRY32 + 4*7 + A_PtrSize*2, "CP0")
         if (exeName = "conhost.exe" && PID := NumGet(PROCESSENTRY32, 4*2, "UInt"))
            break
      }
      res := DllCall("Process32Next", Ptr, h, Ptr, &PROCESSENTRY32)
   }
   DllCall("CloseHandle", Ptr, h)
   Return PID
}
 
GetInputLangName(langId)  {
   static LOCALE_SENGLANGUAGE := 0x1001
   charCount := DllCall("GetLocaleInfo", UInt, langId, UInt, LOCALE_SENGLANGUAGE, UInt, 0, UInt, 0)
   VarSetCapacity(localeSig, size := charCount << !!A_IsUnicode, 0)
   DllCall("GetLocaleInfo", UInt, langId, UInt, LOCALE_SENGLANGUAGE, Str, localeSig, UInt, size)
   return localeSig
}













; ----------------------------------------------------------
; Win+Ctrl+Numpad1
; Смена темной и светлой темы приложений Windows. 
MenuHandler3:
RegRead, OutputVar, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, AppsUseLightTheme
if %OutputVar%=0
{
  RegWrite, REG_DWORD, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, AppsUseLightTheme, 1
} else {
  RegWrite, REG_DWORD, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, AppsUseLightTheme, 0
}
RegRead, OutputVar2, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, AppsUseLightTheme
; MsgBox, Было %OutputVar%, стало %OutputVar2%
return

MenuHandler:
RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, Shell, explorer.exe
return 

MenuHandler2:
RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, Shell, M:\Sys\tc\TotalCmd64.exe /f=y:\TC\wcx_ftp.ini
return 

#z::
Menu, MyMenu, add, Установить Explorer проводником, MenuHandler  ; Добавить новый пункт.
Menu, MyMenu, add, Установить Total Commander проводником, MenuHandler2  ; Добавить новый пункт.
Menu, MyMenu, add  ; Добавить разделитель.
Menu, MyMenu, add, Сменить тему Windows Светлая-Темная, MenuHandler3  ; Добавить новый пункт.
Menu, MyMenu, Show  ; Показывать меню по нажатию Win-Z. 
return

#Persistent  ; Выполнять скрипт, пока не закроет пользователь.




; ----------------------------------------------------------

CapsLock & h:: ; горячая клавиша Win+H
; Получаем текущий выделенный текст. Вместо "ControlGet Selected" используется
; буфер обмена, так как он есть в большинстве редакторов
; (т.е. текстовых процессоров).  Сохраняем текущее содержимое буфера обмена,
; чтобы восстановить его позднее. Хотя обрабатывается только простой текст,
; это все же лучше, чем ничего:
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
InputBox, Hotstring, Новая автозамена, %Text1%%Text2%%Text3%,,757,413,,,,, :R:`::%Hotstring%
if ErrorLevel <> 0 ; Пользователь нажал Cancel.
  return
IfInString, Hotstring, :R`:::
{
  MsgBox Вы не напечатали аббревиатуру. Строка автозамены не добавлена.
  return
}
; Иначе, добавляем строку автозамены и перезагружаем скрипт.
; Помещаем `n в начало, в случае, если в конце файла нет пустой строки.
FileAppend, `n%Hotstring%, %A_ScriptFullPath%
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


; Возвращает выделенный текст
getSelText()
{
    ClipboardOld:=ClipboardAll
    Clipboard:=""
    SendInput, ^{c}
    ClipWait, 0.1
    if(!ErrorLevel)
    {
        selText:=Clipboard
        Clipboard:=ClipboardOld
        StringRight, lastChar, selText, 1
        if(Asc(lastChar)!=10) ;if last char is not line feed
        {
            return selText
        }
    }
    Clipboard:=ClipboardOld
    return
}



Send2(sText) {
    ClipBackup:= ClipboardAll
    Clipboard := sText
    ClipWait
    Send ^v
    Clipboard := ClipBackup
    ClipWait
} ; eofun


; Перезагрузка скрипта горячей клавишей
#SingleInstance Force ;put this at the top of the script
CapsLock & r::run, %A_ScriptFullPath% 




; Генерация пароля
CapsLock & g:: 
length := 12
;possible := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"   
possible1 := "abcdefghijklmnopqrstuvwxyz"   
possible2 := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"   
possible3 := "1234567890"   
possible4 := "?#<>%@/"   
possible5 := "!$%^&*+~`()_=-[]{}\|,.:;"
possible := possible1 possible2 possible3 possible4 possible5
password := ""
; MsgBox, % possible
StringLen, max, possible
Loop {
    Random, rand, 1, max
    StringMid, char, possible, rand, 1
    if !InStr(password, char) 
        password .= char
    if StrLen(password) >= length 
        break
}
Send2(password)
return


tt(text){
    ToolTip, %text%
    SetTimer, ttRemove, -2000
    return
}
ttRemove:
ToolTip
return






#Include GoogleTranslate.ahk
#Include kitty.ahk
#Include main-menu.ahk
#Include dop_menu.ahk
#Include Eval.ahk
#Include build.ahk



CapsLock & =::
ClipBackup:= ClipboardAll
Send ^c
ClipWait
sText := Clipboard
sValue := Eval( sText )
Clipboard := sText+" = "+sValue
ClipWait
Send ^v
Clipboard := ClipBackup
ClipWait
return