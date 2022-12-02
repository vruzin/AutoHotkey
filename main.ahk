SetDefaultKeyboard(0x0409)
SetNumLockState, Off
SetCapsLockState, Off

; Перезагрузка скрипта горячей клавишей
#SingleInstance Force ;put this at the top of the script
CapsLock & r::
SetDefaultKeyboard(0x0409)
SetNumLockState, Off
SetCapsLockState, Off
run, %A_ScriptFullPath% 
return


CapsLock & i::
TmpFile=%A_ScriptDir%\-\ip
ExternalIP :=GetUrl("http://7fw.de/ipraw.php")
Send2(ExternalIP)
;  UrlDownloadToFile,http://7fw.de/ipraw.php,%TmpFile%
; FileReadLine,ExternalIP,%TmpFile%,1
ToolTip, %ExternalIP% <- Внешний`n=====`n%A_IPAddress1%`n%A_IPAddress2%`n%A_IPAddress3%`n%A_IPAddress4%`n
SetTimer, RemoveToolTip, -5000
SetNumLockState, Off
SetCapsLockState, Off
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
; 1 нажатие и если текст выделен, тогда меняю РЕГИСТР букв
#UseHook On
CapsLock::
; ClipSaved := ClipboardAll       ;- save clipboard
; clipboard := ""                 ;- empty clipboard
; Send, ^c                        ;- copy the selected file
; ClipWait,5                      ;- wait for the clipboard to contain data
; Sleep, 200
; txt := ClipboardAll
; MsgBox, >>>%txt%<<<
    KeyWait, %A_ThisHotkey%
    KeyWait, %A_ThisHotkey%, D T0.3
    If ErrorLevel
        ; if txt == "" 
            Send, {Ctrl Down}{Shift Down}{RShift Down}{Shift Up}{Ctrl Up}{RShift Up} ; 1 нажатие, сама клавиша.
        ; else
        ; {
        ;     ; txt := text_in_clipboard
        ;     if txt is upper
        ;         StringLower, txt, txt
        ;     else
        ;         StringUpper, txt, txt
            
        ;     clipboard := txt
        ;     ClipWait
        ;     Sleep, 200
        ;     Send ^v
        ; }
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
            {
                ; 3 нажатия.
                ; SetCapsLockState % !GetKeyState("CapsLock", "T") ; Toggle CapsLock
                SetNumLockState, Off
                SetCapsLockState, Off
            }
            Else
            {
                ; 4 нажатия.
                ; SetCapsLockState % !GetKeyState("CapsLock", "T") ; Toggle CapsLock
                SetNumLockState, Off
                SetCapsLockState, Off
            }
        }
    }
; clipboard := ClipSaved        ;- restore original clipboard
; ClipSaved := ""               ;- free the memory in case the clipboard was very large.

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
SetCapsLockState, Off
return

CapsLock & \::
SendRaw |
SetNumLockState, Off
SetCapsLockState, Off
return

CapsLock & [::
SendRaw {
SetNumLockState, Off
SetCapsLockState, Off
return

CapsLock & ]::
SendRaw }
SetNumLockState, Off
SetCapsLockState, Off
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
SetCapsLockState, Off
return

; Maryadi Vivaldi.
CapsLock & 2::
Run, M:\Sys\Vivaldi\Application\vivaldi.exe --profile-directory="Profile 1"
SetNumLockState, Off
SetCapsLockState, Off
return

; MVK Vivaldi.
CapsLock & 3::
Run, M:\Sys\Vivaldi\Application\vivaldi.exe --profile-directory="Profile 2"
SetNumLockState, Off
SetCapsLockState, Off
return

; FL Vivaldi.
CapsLock & 4::
Run, M:\Sys\Vivaldi\Application\vivaldi.exe --profile-directory="Profile 5"
SetNumLockState, Off
SetCapsLockState, Off
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
^+!ScrollLock::
Process, Exist, ZoomIt.exe ;
if %ErrorLevel% = 0
{
  Run, "m:\Sys\ZoomIt\ZoomIt.exe"
}
Send ^+!{ScrollLock}
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
    Sleep, 200 ;
    Send ^v
    Clipboard := ClipBackup
    ClipWait
} ; eofun







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
SetNumLockState, Off
SetCapsLockState, Off
return












CapsLock & =::
SetNumLockState, Off
SetCapsLockState, Off
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





; ;- keyboardx Capn Odin
; ;https://autohotkey.com/boards/viewtopic.php?f=6&t=18519
; ^0::SetDefaultKeyboard(0x0807) ; swiss-german
; ^1::SetDefaultKeyboard(0x0406) ; Danish
; ^2::SetDefaultKeyboard(0x0409) ; English (USA)
; ^3::SetDefaultKeyboard(0x0411) ; Japanese
; ^4::SetDefaultKeyboard(0x0408) ; Greek
;SetDefaultKeyboard(0x0419) ; Russian
; return
SetDefaultKeyboard(LocaleID){
    Global
    SPI_SETDEFAULTINPUTLANG := 0x005A
    SPIF_SENDWININICHANGE := 2
    Lan := DllCall("LoadKeyboardLayout", "Str", Format("{:08x}", LocaleID), "Int", 0)
    VarSetCapacity(Lan%LocaleID%, 4, 0)
    NumPut(LocaleID, Lan%LocaleID%)
    DllCall("SystemParametersInfo", "UInt", SPI_SETDEFAULTINPUTLANG, "UInt", 0, "UPtr", &Lan%LocaleID%, "UInt", SPIF_SENDWININICHANGE)
    WinGet, windows, List
    Loop %windows% {
        PostMessage 0x50, 0, %Lan%, , % "ahk_id " windows%A_Index%
    }
}
return



OnClipboardChange:
if(A_EventInfo=1)
    {
        text_selected := true
        text_in_clipboard := ClipboardAll
        ; ToolTip text is selected
        ; Sleep 1000
        ; ToolTip
    }
else {
    text_selected := false
    text_in_clipboard := ""
}
return


#Include abbreviations.ahk
#Include GoogleTranslate.ahk
#Include kitty.ahk
#Include main-menu.ahk
#Include dop_menu.ahk
#Include Eval.ahk
#Include build.ahk
#Include Direct.ahk
#Include fl.ahk
#Include Docker.ahk
; #Include Punto.ahk