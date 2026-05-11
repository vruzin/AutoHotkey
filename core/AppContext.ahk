; ============================================================
; core/AppContext.ahk — контекст активного окна и исключения (AHK v2)
;
; Назначение:
;   • Понять, какое сейчас приложение активно (exe / class / title).
;   • Определить, как Punto должна себя в нём вести:
;       "normal"        — обычный режим (по умолчанию)
;       "no_autoswitch" — Break-операции работают, автопереключение выключено
;       "paste_mode"    — все вставки через clipboard, без прямого Send
;       "off"           — полностью выключить (игры, fullscreen-приложения)
;
; Источник исключений:
;   1) data/excluded_apps.json — пользовательский, читается при старте.
;   2) Если файла нет — создаётся с дефолтами, импортированными
;      из default-conf.json PuntoSwitcher и preferences.xml пользователя.
;
; Зависит от: JSON.ahk (подключается в main.ahk до этого файла).
; ============================================================

class PuntoAppContext {
    static rules := Map()           ; mode → массив подстрок exe-имени
    static Initialized := false
    static ConfigPath := ""

    ; ------------------------------------------------------------
    ; Init — загрузить excluded_apps.json (или создать с дефолтами).
    static Init() {
        if PuntoAppContext.Initialized
            return
        PuntoAppContext.ConfigPath := A_ScriptDir . "\data\excluded_apps.json"

        if FileExist(PuntoAppContext.ConfigPath) {
            try {
                txt := FileRead(PuntoAppContext.ConfigPath, "UTF-8")
                data := JSON.parse(txt)
                PuntoAppContext.rules := PuntoAppContext.NormalizeRules(data)
            } catch as e {
                ; повреждённый JSON — на дефолты и сохранить копию .bak
                FileCopy(PuntoAppContext.ConfigPath, PuntoAppContext.ConfigPath . ".bak", 1)
                PuntoAppContext.rules := PuntoAppContext.DefaultRules()
                PuntoAppContext.Save()
            }
        } else {
            PuntoAppContext.rules := PuntoAppContext.DefaultRules()
            PuntoAppContext.Save()
        }
        PuntoAppContext.Initialized := true
    }

    static NormalizeRules(data) {
        out := Map()
        for mode in ["off", "no_autoswitch", "paste_mode"] {
            list := []
            if data.Has(mode) {
                for item in data[mode]
                    list.Push(StrLower(item))
            }
            out[mode] := list
        }
        return out
    }

    ; ------------------------------------------------------------
    ; DefaultRules — встроенные дефолты, импортированные из PuntoSwitcher
    ; (default-conf.json + preferences.xml пользователя).
    static DefaultRules() {
        return Map(
            "off", [
                ; Игры — полная блокировка хука
                "gta_sa.exe", "gtaiv.exe", "gta-vc.exe", "gta-sa.exe", "gta5.exe",
                "starcraft.exe", "sc2.exe", "hearthstone.exe", "syberia3.exe",
                "crysis3.exe", "frozen throne.exe", "war3.exe",
                "wow.exe", "wow-64.exe", "sirus.exe", "warcraft"
            ],
            "no_autoswitch", [
                ; Программы, в которых смена раскладки требует другой подход
                ; или мешает работе пользователя.
                "photoshop.exe",            ; персональное (preferences.xml)
                "warp.exe",                 ; персональное
                "devenv.exe",               ; Visual Studio
                "winword.exe", "excel.exe", "outlook.exe", "powerpnt.exe",
                "communicator.exe", "lync.exe", "skype.exe", "thunderbird.exe",
                "premiere", "after effects", "aftereffects", "panotour",
                "phped.exe", "jitsi", "hipchat"
            ],
            "paste_mode", [
                "icq.exe", "lingvo", "telegram", "viber", "whatsapp"
            ]
        )
    }

    ; ------------------------------------------------------------
    ; Save — записать текущие правила в excluded_apps.json (UTF-8, indented).
    static Save() {
        obj := Map()
        for mode, list in PuntoAppContext.rules
            obj[mode] := list
        json := JSON.stringify(obj, 2)
        ; Гарантируем существование папки
        dir := A_ScriptDir . "\data"
        if !DirExist(dir)
            DirCreate(dir)
        f := FileOpen(PuntoAppContext.ConfigPath, "w", "UTF-8")
        if !f
            return false
        f.Write(json)
        f.Close()
        return true
    }

    ; ------------------------------------------------------------
    ; Current — Map с информацией об активном окне:
    ;   { exe, class, title, path }
    static Current() {
        info := Map("exe", "", "class", "", "title", "", "path", "")
        try {
            info["exe"]   := StrLower(WinGetProcessName("A"))
            info["class"] := WinGetClass("A")
            info["title"] := WinGetTitle("A")
            info["path"]  := WinGetProcessPath("A")
        } catch {
            ; нет активного окна / нет прав
        }
        return info
    }

    ; ------------------------------------------------------------
    ; ModeFor — текущий режим для активного окна.
    ; Возвращает "off" | "no_autoswitch" | "paste_mode" | "normal".
    static ModeFor() {
        if !PuntoAppContext.Initialized
            PuntoAppContext.Init()
        info := PuntoAppContext.Current()
        exe := info["exe"]
        if (exe = "")
            return "normal"
        ; Порядок приоритета: off > no_autoswitch > paste_mode > normal
        for mode in ["off", "no_autoswitch", "paste_mode"] {
            for pattern in PuntoAppContext.rules[mode] {
                if InStr(exe, pattern, false)
                    return mode
            }
        }
        return "normal"
    }

    ; ------------------------------------------------------------
    ; Управление списками во время работы (вызовы из UI палитры).
    static AddRule(mode, pattern) {
        PuntoAppContext.Init()
        if !PuntoAppContext.rules.Has(mode)
            return false
        pattern := StrLower(pattern)
        for existing in PuntoAppContext.rules[mode]
            if (existing = pattern)
                return false
        PuntoAppContext.rules[mode].Push(pattern)
        return PuntoAppContext.Save()
    }

    static RemoveRule(mode, pattern) {
        PuntoAppContext.Init()
        if !PuntoAppContext.rules.Has(mode)
            return false
        list := PuntoAppContext.rules[mode]
        pattern := StrLower(pattern)
        Loop list.Length {
            if (list[A_Index] = pattern) {
                list.RemoveAt(A_Index)
                return PuntoAppContext.Save()
            }
        }
        return false
    }
}
