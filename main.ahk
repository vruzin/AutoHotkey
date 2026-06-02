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
; (регистрируется в RegisterGlobalHotkeys через FeatureRegistry)
ShowIpAddresses(*) {
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
; ВСЕ глобальные хоткеи ниже — именованные функции, принимающие (*),
; чтобы их можно было включать/выключать через FeatureRegistry.
; Сама регистрация — в RegisterGlobalHotkeys() (внизу файла, вызывается
; на старте). Исключение — CapsLock+R (Reload) выше: аварийный, не отключаем.

; ----------------------------------------------------------
; Win+Ctrl+Shift+T — переключить «поверх всех окон» для активного
AlwaysOnTopToggle(*) {
    WinSetAlwaysOnTop(-1, "A")
}

; ----------------------------------------------------------
; CapsLock+Space/[/]/=/\ — вставить кастомные разделители независимо от раскладки
SepInsertSelection(*) {
    sel := getSelText()
    if (sel != "")
        Send2("【┋" . sel . "】")
    else
        SendText("【┋ 】")
    SetNumLockState("Off")
    SetCapsLockState("Off")
}

; Scancode-форма работает физически независимо от раскладки и не вызывает
; предупреждение «hotkey does not exist in the current keyboard layout».
;   SC02B = \   SC01A = [   SC01B = ]   SC00D = =
SepBar(*) {
    SendText("┋")
    SetNumLockState("Off")
    SetCapsLockState("Off")
}

SepBracketOpen(*) {
    SendText("【")
    SetNumLockState("Off")
    SetCapsLockState("Off")
}

SepBracketClose(*) {
    SendText("】")
    SetNumLockState("Off")
    SetCapsLockState("Off")
}

SepEquals(*) {
    SendText("〓")
    SetNumLockState("Off")
    SetCapsLockState("Off")
}

; ----------------------------------------------------------
; CapsLock+1..4 — запуск Vivaldi с разными профилями
RunVivaldi(profile) {
    Run('M:\Sys\Vivaldi\Application\vivaldi.exe --profile-directory="' . profile . '"')
    SetNumLockState("Off")
    SetCapsLockState("Off")
}
VivaldiDefault(*)  => RunVivaldi("Default")     ; VR
VivaldiProfile1(*) => RunVivaldi("Profile 1")    ; Maryadi
VivaldiProfile2(*) => RunVivaldi("Profile 2")    ; MVK
VivaldiProfile5(*) => RunVivaldi("Profile 5")    ; FL

; ----------------------------------------------------------
; Win+C — активировать или запустить GraphCalc
GraphCalcToggle(*) {
    if WinExist("GraphCalc") {
        WinActivate
        WinSetAlwaysOnTop(1)
    } else {
        Run("M:\Sys\GraphCalc\GrphCalc.exe")
    }
}

; ----------------------------------------------------------
; Win+Insert — активировать или запустить OBS Studio
ObsToggle(*) {
    if !WinExist("OBS")
        Run("M:\Sys\OBS\bin\64bit\obs64.exe", "M:\Sys\OBS\bin\64bit\")
    else
        Send "#{Insert}"
}

; ----------------------------------------------------------
; Shift+PrintScreen — ABBYY FineReader ScreenshotReader (распознавание области)
AbbyyScreenshot(*) {
    Run('"C:\Program Files\ABBYY FineReader 16\screenshotreader.exe"')
    Sleep 500
    Send "!{Enter}"
}

; ----------------------------------------------------------
; Ctrl+Shift+Alt+ScrollLock — ZoomIt (приближение с мышкой)
ZoomItMouse(*) {
    if !ProcessExist("ZoomIt.exe")
        Run('"m:\Sys\ZoomIt\ZoomIt.exe"')
    Send "^+!{ScrollLock}"
}

; Ctrl+Shift+Alt+Insert — ZoomIt (приближение без мышки)
ZoomItNoMouse(*) {
    if !ProcessExist("ZoomIt.exe")
        Run('"m:\Sys\ZoomIt\ZoomIt.exe"')
    Send "^+!{Insert}"
}

; ----------------------------------------------------------
; Ctrl + медиа-клавиша Mute — переключить микрофон (вкл/выкл).
; Обычный Volume_Mute по-прежнему мьютит колонки — перехватываем только с Ctrl.
MicToggle(*) {
    Mic.Toggle()
}

; ----------------------------------------------------------
; CapsLock+Shift — открыть лаунчер (поиск команд).
OpenLauncher(*) {
    SettingsWindow.Show()
}

; ----------------------------------------------------------
; Win+Z — меню системных переключателей (Shell, тема Windows)
ShowSystemMenu(*) {
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
; (регистрируется в RegisterGlobalHotkeys через FeatureRegistry)
GeneratePassword(*) {
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
; WebView2.ahk внутри делает #Include ..\ComVar.ahk и ..\Promise.ahk
; (относительно своей папки lib\Webview2 → ожидает их в lib\).
; Поэтому ComVar.ahk и Promise.ahk продублированы в lib\.
#Include lib\Webview2\WebView2.ahk

; Ядро Punto v2 (этап 2)
#Include core\Layout.ahk
#Include core\Dictionaries.ahk
#Include core\AppContext.ahk
#Include core\Learning.ahk
#Include core\History.ahk
#Include core\Settings.ahk
#Include core\FeatureRegistry.ahk
#Include core\MenuData.ahk
#Include core\Abbreviations.ahk

; Фичи поверх ядра (этап 3)
#Include features\ForceWords.ahk
#Include features\Case.ahk
#Include features\Translit.ahk
#Include features\Number2Text.ahk
#Include features\PasteRaw.ahk
#Include features\Mic.ahk
#Include features\HotkeyHuman.ahk

#Include core\Input.ahk
#Include core\Autoswitch.ahk

; UI палитра (этап 4 — пока простая Gui, потом WebView2+Vue)
#Include ui\Palette.ahk

; Фреймворк Vue-приложений в WebView2 + окно настроек
#Include ui\WebApp.ahk
#Include ui\Settings.ahk

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

; Единый список команд для лаунчера (после legacy — зависит от *MenuData).
#Include core\Commands.ahk

; ============================================================
; РЕГИСТРАЦИЯ УПРАВЛЯЕМЫХ ХОТКЕЕВ
; ============================================================
; Все глобальные и legacy-хоткеи регистрируются здесь через FeatureRegistry,
; чтобы окно настроек могло включать/выключать их галочками в рантайме.
; Функции-обработчики определены выше (main.ahk) и в legacy/*.ahk —
; в AHK v2 функции глобальны независимо от порядка #Include.
;
; CapsLock (одиночный, смена раскладки), CapsLock+R (Reload) и контекстные
; #HotIf-хоткеи (CapsLock+X в IDEA, Direct Commander, GraphCalc) НЕ
; регистрируются — это базовые/контекстные, отключать их нельзя.
RegisterGlobalHotkeys() {
    R := FeatureRegistry

    ; --- group: global (глобальные хоткеи поверх всех окон) ---
    R.Register("global.ip",          "global", "Показать внешний и локальные IP",        "CapsLock & i",   ShowIpAddresses)
    R.Register("global.alwaysontop", "global", "Поверх всех окон (toggle)",              "#^+t",           AlwaysOnTopToggle)
    R.Register("global.sep_sel",     "global", "Разделитель 【┋…】 вокруг выделения",     "CapsLock & Space", SepInsertSelection)
    R.Register("global.sep_bar",     "global", "Вставить ┋",                             "CapsLock & SC02B", SepBar)
    R.Register("global.sep_open",    "global", "Вставить 【",                             "CapsLock & SC01A", SepBracketOpen)
    R.Register("global.sep_close",   "global", "Вставить 】",                             "CapsLock & SC01B", SepBracketClose)
    R.Register("global.sep_eq",      "global", "Вставить 〓",                             "CapsLock & SC00D", SepEquals)
    R.Register("global.vivaldi1",    "global", "Vivaldi: профиль VR",                    "CapsLock & 1",   VivaldiDefault)
    R.Register("global.vivaldi2",    "global", "Vivaldi: профиль Maryadi",               "CapsLock & 2",   VivaldiProfile1)
    R.Register("global.vivaldi3",    "global", "Vivaldi: профиль MVK",                   "CapsLock & 3",   VivaldiProfile2)
    R.Register("global.vivaldi4",    "global", "Vivaldi: профиль FL",                    "CapsLock & 4",   VivaldiProfile5)
    R.Register("global.graphcalc",   "global", "GraphCalc (Win+C)",                      "#c",             GraphCalcToggle)
    R.Register("global.obs",         "global", "OBS Studio (Win+Insert)",                "#Insert",        ObsToggle)
    R.Register("global.abbyy",       "global", "ABBYY ScreenshotReader (Shift+PrtSc)",   "+PrintScreen",   AbbyyScreenshot)
    R.Register("global.zoomit",      "global", "ZoomIt с мышкой",                        "^+!ScrollLock",  ZoomItMouse)
    R.Register("global.zoomit_nm",   "global", "ZoomIt без мышки",                       "^+!Insert",      ZoomItNoMouse)
    R.Register("global.sysmenu",     "global", "Системное меню (Win+Z)",                 "#z",             ShowSystemMenu)
    R.Register("global.password",    "global", "Сгенерировать пароль",                   "CapsLock & g",   GeneratePassword)

    ; --- group: global — лаунчер ---
    R.Register("global.launcher",    "global", "Открыть лаунчер",                        "CapsLock & LShift", OpenLauncher)

    ; --- group: mic (микрофон) ---
    R.Register("mic.toggle",         "mic",    "Переключить микрофон (Ctrl+Mute)",       "^Volume_Mute",   MicToggle)

    ; --- group: legacy (меню по CapsLock+буква) ---
    R.Register("legacy.mainmenu",    "legacy", "Меню: тема Windows (CapsLock+A)",        "CapsLock & a",   ShowMainMenu)
    R.Register("legacy.ssh",         "legacy", "Меню: sysadmin/SSH (CapsLock+S)",        "CapsLock & s",   ShowSshMenu)
    R.Register("legacy.docker",      "legacy", "Меню: Docker (CapsLock+D)",              "CapsLock & d",   ShowDockerMenu)
    R.Register("legacy.kitty",       "legacy", "Запуск KiTTY (CapsLock+K)",              "CapsLock & k",   KittyLaunch)
    R.Register("legacy.build",       "legacy", "Меню: build/dev (CapsLock+B)",           "CapsLock & b",   ShowBuildMenu)
    R.Register("legacy.fl",          "legacy", "Меню: шаблоны FL.ru (CapsLock+F)",       "CapsLock & f",   ShowFlMenu)
    R.Register("legacy.direct",      "legacy", "Yandex Direct Find&Replace (CapsLock+W)","CapsLock & w",   DirectFindReplace)
    R.Register("legacy.gtranslate",  "legacy", "Google Translate (CapsLock+T)",          "CapsLock & t",   GoogleTranslateHotkey)
    R.Register("legacy.hotstring",   "legacy", "Добавить автозамену (CapsLock+H)",       "CapsLock & h",   AddHotstringDialog)
    R.Register("legacy.dopmenu",     "legacy", "Меню: сниппеты (CapsLock+Z)",            "CapsLock & z",   ShowDopMenu)
}

; Запуск Punto v2 (после загрузки всех модулей)
Punto.Init()

; Аббревиатуры из data/abbreviations.json (динамические hotstrings).
Abbreviations.Init()

; Регистрация управляемых хоткеев (после Punto.Init — он регистрирует свои).
RegisterGlobalHotkeys()

; Трей: одинарный клик → окно настроек, пункт меню «Настройки…».
SettingsTray_Init()
