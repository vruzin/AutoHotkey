; ============================================================
; main.ahk — AutoHotkey v2 (требует 2.0+)
;
; Точка входа: подключается через ярлык "main — ярлык.lnk".
; Содержит:
;   • глобальные хоткеи поверх всех окон (CapsLock+i, CapsLock+1..4, Win+C, …)
;   • общие утилиты (Send2, Send3, getSelText)
;   • контекстные хоткеи через #HotIf (для GraphCalc, IDEA, Direct Commander)
;   • #Include всех модулей из legacy/
;
; Большая часть фич живёт в подключённых файлах. Здесь — то, что было в
; корневом main.ahk до миграции на v2.
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, OutputDebug             ; предупреждения не блокируют выполнение, пишутся в OutputDebug

; Старт скрипта: только сброс залипшего CapsLock/NumLock.
; Раскладку насильно не меняем — иначе Windows показывает плашки
; «раскладка изменилась», и пользователю приходится их закрывать.
SetNumLockState("Off")
SetCapsLockState("Off")

; ----------------------------------------------------------
; CapsLock+R — перезагрузить скрипт
CapsLock & r:: {
    SetNumLockState("Off")
    SetCapsLockState("Off")
    Reload
}

; ----------------------------------------------------------
; CapsLock+I — показать внешний и локальные IP в ToolTip
CapsLock & i:: ShowIpAddresses()

ShowIpAddresses() {
    extIP := GetUrl("http://7fw.de/ipraw.php")
    Send2(extIP)

    text := extIP . " <- Внешний`n=====`n"
    for ip in GetLocalIPv4()
        text .= ip . "`n"
    ToolTip text

    SetTimer () => ToolTip(), -5000
    SetNumLockState("Off")
    SetCapsLockState("Off")
}

; В AHK v2 нет A_IPAddress1..4 (v1-only). Получаем IPv4-адреса через WMI.
GetLocalIPv4() {
    ips := []
    try {
        for adapter in ComObjGet("winmgmts:").ExecQuery(
                "Select * from Win32_NetworkAdapterConfiguration WHERE IPEnabled = TRUE") {
            if !adapter.IPAddress
                continue
            for ip in adapter.IPAddress
                if InStr(ip, ".")        ; IPv4
                    ips.Push(ip)
        }
    }
    return ips
}

GetUrl(url) {
    whr := ComObject("WinHttp.WinHttpRequest.5.1")
    whr.Open("GET", url, true)
    whr.Send()
    whr.WaitForResponse()
    return whr.ResponseText
}

; ----------------------------------------------------------
; Контекстные хоткеи: Direct Commander — фильтр-исключения
#HotIf WinActive("ahk_exe Direct Commander.exe")
:o:=ф::
{
    Send2("= Фраза !~ Купить & Фраза !~ недорого & Фраза !~ подбор & Фраза !~ подобрать & Фраза !~ прайс & Фраза !~ рассчет & Фраза !~ цена")
}
#HotIf

; GraphCalc — десятичный разделитель: Numpad точка вместо запятой
#HotIf WinActive("ahk_exe GrphCalc.exe")
NumpadDot:: SendText(".")
#HotIf

; IntelliJ IDEA — CapsLock+X = Ctrl+Shift+X (cut line или нужная команда)
#HotIf WinActive("ahk_exe idea64.exe")
CapsLock & x:: Send "^+x"
#HotIf

; ----------------------------------------------------------
; Win+Ctrl+Shift+T — переключить «поверх всех окон» для активного
#^+t:: WinSetAlwaysOnTop(-1, "A")

; ----------------------------------------------------------
; CapsLock+Space/[/]/=/\ — вставить кастомные разделители независимо от раскладки
CapsLock & Space:: {
    sel := getSelText()
    if (sel != "")
        Send2("【┋" . sel . "】")
    else
        SendText("【┋ 】")
    SetNumLockState("Off")
    SetCapsLockState("Off")
}

CapsLock & \:: {
    SendText("┋")
    SetNumLockState("Off")
    SetCapsLockState("Off")
}

CapsLock & [:: {
    SendText("【")
    SetNumLockState("Off")
    SetCapsLockState("Off")
}

CapsLock & ]:: {
    SendText("】")
    SetNumLockState("Off")
    SetCapsLockState("Off")
}

CapsLock & =:: {
    SendText("〓")
    SetNumLockState("Off")
    SetCapsLockState("Off")
}

; ----------------------------------------------------------
; CapsLock+1..4 — запуск Vivaldi с разными профилями
CapsLock & 1:: RunVivaldi("Default")        ; VR
CapsLock & 2:: RunVivaldi("Profile 1")       ; Maryadi
CapsLock & 3:: RunVivaldi("Profile 2")       ; MVK
CapsLock & 4:: RunVivaldi("Profile 5")       ; FL

RunVivaldi(profile) {
    Run('M:\Sys\Vivaldi\Application\vivaldi.exe --profile-directory="' . profile . '"')
    SetNumLockState("Off")
    SetCapsLockState("Off")
}

; ----------------------------------------------------------
; Win+C — активировать или запустить GraphCalc
#c:: {
    if WinExist("GraphCalc") {
        WinActivate
        WinSetAlwaysOnTop(1)
    } else {
        Run("M:\Sys\GraphCalc\GrphCalc.exe")
    }
}

; ----------------------------------------------------------
; Win+Insert — активировать или запустить OBS Studio
#Insert:: {
    if !WinExist("OBS")
        Run("M:\Sys\OBS\bin\64bit\obs64.exe", "M:\Sys\OBS\bin\64bit\")
    else
        Send "#{Insert}"
}

; ----------------------------------------------------------
; Shift+PrintScreen — ABBYY FineReader ScreenshotReader (распознавание области)
+PrintScreen:: {
    Run('"C:\Program Files\ABBYY FineReader 16\screenshotreader.exe"')
    Sleep 500
    Send "!{Enter}"
}

; ----------------------------------------------------------
; Ctrl+Shift+Alt+ScrollLock — ZoomIt (приближение с мышкой)
^+!ScrollLock:: {
    if !ProcessExist("ZoomIt.exe")
        Run('"m:\Sys\ZoomIt\ZoomIt.exe"')
    Send "^+!{ScrollLock}"
}

; Ctrl+Shift+Alt+Insert — ZoomIt (приближение без мышки)
^+!Insert:: {
    if !ProcessExist("ZoomIt.exe")
        Run('"m:\Sys\ZoomIt\ZoomIt.exe"')
    Send "^+!{Insert}"
}

; ----------------------------------------------------------
; Win+Z — меню системных переключателей (Shell, тема Windows)
#z:: ShowSystemMenu()

ShowSystemMenu() {
    m := Menu()
    m.Add("Установить Explorer проводником", SetShellExplorer)
    m.Add("Установить Total Commander проводником", SetShellTotalCmd)
    m.Add()
    m.Add("Сменить тему Windows Светлая-Темная", ToggleWindowsTheme)
    m.Show()
}

SetShellExplorer(*) {
    RegWrite("explorer.exe", "REG_SZ",
        "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "Shell")
}

SetShellTotalCmd(*) {
    RegWrite("M:\Sys\tc\TotalCmd64.exe /f=y:\TC\wcx_ftp.ini", "REG_SZ",
        "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "Shell")
}

ToggleWindowsTheme(*) {
    key := "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    cur := RegRead(key, "AppsUseLightTheme", 1)
    RegWrite(1 - cur, "REG_DWORD", key, "AppsUseLightTheme")
}

; ----------------------------------------------------------
; CapsLock+G — генерация пароля длиной 12 символов
CapsLock & g:: GeneratePassword()

GeneratePassword() {
    pools := [
        "abcdefghijklmnopqrstuvwxyz",
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        "1234567890",
        "?#<>%@/",
        "!$%^&*+~`()_=-[]{}\|,.:;"
    ]
    all := ""
    for p in pools
        all .= p

    length := 12
    password := ""
    maxLen := StrLen(all)
    Loop {
        ch := SubStr(all, Random(1, maxLen), 1)
        if !InStr(password, ch)
            password .= ch
        if (StrLen(password) >= length)
            break
    }

    Send2(password)
    SetNumLockState("Off")
    SetCapsLockState("Off")
}

; ============================================================
; ОБЩИЕ УТИЛИТЫ (видны из всех подключаемых модулей)
; ============================================================

; ----------------------------------------------------------
; Send2 — основная функция ввода через буфер обмена.
; Используется для всех русских/Unicode/многострочных вставок, потому что
; прямой Send не работает корректно в части приложений (Telegram, OBS и др.).
Send2(sText) {
    clipBak := ClipboardAll()
    A_Clipboard := sText
    ClipWait()
    Sleep 400
    Send "^v"
    A_Clipboard := clipBak
    ClipWait()
}

; Send3 — то же, но с меньшей задержкой (200мс).
; Используется в kitty.ahk и fl.ahk, где Send2 слишком медленный.
Send3(sText) {
    clipBak := ClipboardAll()
    A_Clipboard := sText
    ClipWait()
    Sleep 200
    Send "^v"
    A_Clipboard := clipBak
    ClipWait()
}

; ----------------------------------------------------------
; getSelText — получить выделенный текст через временный Ctrl+C.
; Сохраняет и восстанавливает буфер обмена. Возвращает "" при таймауте.
getSelText() {
    clipBak := ClipboardAll()
    A_Clipboard := ""
    SendInput "^c"
    if !ClipWait(0.1) {
        A_Clipboard := clipBak
        return ""
    }
    sel := A_Clipboard
    A_Clipboard := clipBak
    ; Отсекаем хвостовой перевод строки, если он есть
    if (sel != "" && Ord(SubStr(sel, -1)) = 10)
        return sel
    return sel
}

; ----------------------------------------------------------
; SetDefaultKeyboard — установить раскладку для всех окон системы.
SetDefaultKeyboard(localeId) {
    SPI_SETDEFAULTINPUTLANG := 0x005A
    SPIF_SENDWININICHANGE := 2

    DllCall("LoadKeyboardLayout", "Str", Format("{:08x}", localeId), "Int", 0)

    buf := Buffer(4, 0)
    NumPut("UInt", localeId, buf)
    DllCall("SystemParametersInfo",
        "UInt", SPI_SETDEFAULTINPUTLANG,
        "UInt", 0,
        "Ptr",  buf,
        "UInt", SPIF_SENDWININICHANGE)

    ; Разослать WM_INPUTLANGCHANGEREQUEST всем окнам
    ids := WinGetList()
    for hwnd in ids
        PostMessage(0x50, 0, localeId, , "ahk_id " . hwnd)
}

; ============================================================
; ПОДКЛЮЧЕНИЕ МОДУЛЕЙ
; ============================================================

; Внешние библиотеки
#Include lib\JSON.ahk

; Ядро Punto v2 (этап 2)
#Include core\Layout.ahk
#Include core\Dictionaries.ahk
#Include core\AppContext.ahk
#Include core\Learning.ahk
#Include core\History.ahk
#Include core\Input.ahk
#Include core\Autoswitch.ahk
#Include core\Punto.ahk

; Legacy-модули (мигрированные хоткеи и сниппеты)
#Include legacy\abbreviations.ahk
#Include legacy\GoogleTranslate.ahk
#Include legacy\kitty.ahk
#Include legacy\main-menu.ahk
#Include legacy\dop_menu.ahk
#Include legacy\build.ahk
#Include legacy\Direct.ahk
#Include legacy\fl.ahk
#Include legacy\Docker.ahk
#Include legacy\CapsLock_double.ahk

; Запуск Punto v2 (после загрузки всех модулей)
Punto.Init()
