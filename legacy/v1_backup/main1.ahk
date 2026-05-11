
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
}else{
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
}else{
  Run, M:\Sys\IDEA\bin\idea64.exe "m:\prg\Maryadi\igo2london.com\"
  WinWait, "igo2london.com ahk_exe idea64.exe"
}
return

; ----------------------------------------------------------
; MVK Vivaldi. Win+Ctrl+Numpad4
#^Numpad4::
Run, M:\Sys\Vivaldi\Application\vivaldi.exe --profile-directory="Profile 2"
return


; ----------------------------------------------------------
; Maryadi Vivaldi. Win+Ctrl+Numpad4
#^Numpad5::
Run, M:\Sys\Vivaldi\Application\vivaldi.exe --profile-directory="Profile 1"
return

; Копирует одну ячейку из одной таблицы, в другой файл
#+n:: ; Горячая клавиша Win+Shift+N
Send ^c ; Горячая клавиша Ctrl+C
Sleep, 300 ;
Send !{Tab} ; Горячая клавиша AltTab
Sleep, 300 ;
Send ^v ; Горячая клавиша Ctrl+V
Sleep, 300 ;
Send {Down} ; Горячая клавиша Вниз
Sleep, 300 ;
Send !{Tab} ; Горячая клавиша AltTab
Sleep, 300 ;
Send {Down} ; Горячая клавиша Вниз
return

; Копирует много ячеек из одного файла в другой.
#+!n:: ; Горячая клавиша Win+Shift+N
Loop, 74
{
  Send ^c ; Горячая клавиша Ctrl+C
  Sleep, 400 ;
  Send !{Tab} ; Горячая клавиша AltTab
  Sleep, 500 ;
  Send ^v ; Горячая клавиша Ctrl+V
  Sleep, 400 ;
  Send {Down} ; Горячая клавиша Вниз
  Sleep, 400 ;
  Send !{Tab} ; Горячая клавиша AltTab
  Sleep, 500 ;
  Send {Down} ; Горячая клавиша Вниз
  Sleep, 400 ;
}
return






; ----------------------------------------------------------
; Сокращения
::GA::Google Analitics ;
::дднс::Добрый день. Вы на связи+7 ;
::ДДД::Добрый день ;
::ДУ::Доброе утро ;
::ДВ::Добрый вечер ;
::пжл::Пожалуйста. ;
::пож::Пожалуйста ;
::кол::количество ;
::vru::vruzin@ya.ru ;
; ::ДДП::Добрый день. Это Рузин Василий по поводу проекта:  ;

; ----------------------------------------------------------
; В зависимости от времени суток пишет приветствие
::ДД::
if(A_Hour < 5)
  state = Доброй ночи
else if(A_Hour < 10)
  state = Доброе утро
else if(A_Hour < 17)
  state = Добрый день
else
  state = Добрый вечер
Send %state%. ;
return



; ----------------------------------------------------------
; Поверх всех окон. Win+Ctrl+alt+t
#^!t::  Winset, Alwaysontop, , A 


; ----------------------------------------------------------
;  Калькулятор Win+C
#c::
; Если открыт, то показать, если закрыт, тогда открыть
IfWinExist, GraphCalc
{
    WinActivate ; Использует окно, найденное выше.
    Winset, Top
}
else
{
  Run, M:\Sys\GraphCalc\GrphCalc.exe
}
return

; ----------------------------------------------------------
; Все чаты на фон. Win+Ctrl+Numpad0
#^NumpadDot::  
Winset, Bottom, , WhatsApp
Winset, Bottom, , Telegram
Winset, Bottom, , Viber
Winset, Bottom, , Skype
return




; ----------------------------------------------------------
; Распознавание области экрана. Ctrl+PrintScreen
^PrintScreen::
Run, "c:\ProgramData\Microsoft\Windows\Start Menu\Programs\ABBYY FineReader 15\ABBYY Screenshot Reader.lnk"
Sleep, 300 ;
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
; Смена темной и светлой темы приложений Windows. Win+Ctrl+Numpad1
#^Numpad1::  
RegRead, OutputVar, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, AppsUseLightTheme
if %OutputVar%=0 
{
  RegWrite, REG_DWORD, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, AppsUseLightTheme, 1
}
else
{
  RegWrite, REG_DWORD, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, AppsUseLightTheme, 0
}
RegRead, OutputVar2, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, AppsUseLightTheme
; MsgBox, Было %OutputVar%, стало %OutputVar2%
return



; ----------------------------------------------------------
; Выравнивание чатов в правом мониторе. Win+Ctrl+Numpad0
#^Numpad0::  
IfWinExist, WhatsApp
{
    WinActivate ; Использует окно, найденное выше.
    Winset, Top
}else{
  Run, "C:\Users\HomeServer\AppData\Local\WhatsApp\WhatsApp.exe"
}
IfWinExist, Telegram
{
  WinActivate ; Использует окно, найденное выше.
    Winset, Top
}else{
  Run, "M:\Sys\Telegram\Telegram.exe"
}
IfWinExist, Viber
{
    WinActivate ; Использует окно, найденное выше.
    Winset, Top
}else{
  Run, "C:\Users\HomeServer\AppData\Local\Viber\Viber.exe"
}
IfWinExist, Skype
{
    WinActivate ; Использует окно, найденное выше.
    Winset, Top
}else{
  Run, "C:\Program Files (x86)\Microsoft\Skype for Desktop\Skype.exe"
}
WinMove, WhatsApp, , 2561, 0, 854, 540
WinMove, Telegram, , 2561, 541, 854, 539
WinMove, Viber, , 3407, 0, 854, 1088
WinMove, Skype, , 4245, 0, 883, 1088
return


; ----------------------------------------------------------
;  Автоисправление в GraphCalc запятой на точку
NumpadDot::
; Если открыт, то показать, если закрыт, тогда открыть
IfWinActive, GraphCalc
{
    Send, .{Left}{Right} ;
}else{
  if (GetInputLangName(GetInputLangID("A"))=="Russian")
  {
    Send, ,{Left}{Right}
  }else{
    Send, .{Left}{Right}
  }
}
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





















; ПРИМЕР №1: Этот скрипт добавляет новый пункт внизу меню в трее.

; #Persistent  ; Выполнять скрипт, пока не закроет пользователь.

; return

MenuHandler:
RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, Shell, "explorer.exe"
return 

MenuHandler2:
RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, Shell, "M:\Sys\tc\TotalCmd64.exe /f=y:\TC\wcx_ftp.ini"
return 

#NumpadMult::
; Menu, MyMenu, add  ; Добавить разделитель.
Menu, MyMenu, add, Установить Explorer проводником, MenuHandler  ; Добавить новый пункт.
Menu, MyMenu, add, Установить Total Commander проводником, MenuHandler2  ; Добавить новый пункт.
Menu, MyMenu, Show  ; Показывать меню по нажатию Win-Z. 
return

#Persistent  ; Выполнять скрипт, пока не закроет пользователь.