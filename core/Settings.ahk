; ============================================================
; core/Settings.ahk — единая точка пользовательских настроек.
;
; Файл: data/settings.json
; При первом запуске создаётся с дефолтами. После — читается каждый запуск.
; Изменения через UI палитру (этап 4) записываются обратно через Save().
;
; Применяется в Punto.Init() ПОСЛЕ инициализации всех модулей,
; чтобы перетереть статические значения по умолчанию.
; ============================================================

class PuntoSettings {
    static data := Map()
    static Initialized := false
    static ConfigPath := ""

    static Init() {
        if PuntoSettings.Initialized
            return
        PuntoSettings.ConfigPath := A_ScriptDir . "\data\settings.json"

        if FileExist(PuntoSettings.ConfigPath) {
            try {
                txt := FileRead(PuntoSettings.ConfigPath, "UTF-8")
                PuntoSettings.data := JSON.parse(txt)
            } catch {
                try FileCopy(PuntoSettings.ConfigPath, PuntoSettings.ConfigPath . ".bak", 1)
                PuntoSettings.data := PuntoSettings.Defaults()
                PuntoSettings.Save()
            }
        } else {
            PuntoSettings.data := PuntoSettings.Defaults()
            PuntoSettings.Save()
        }
        PuntoSettings.Initialized := true
    }

    static Defaults() {
        d := Map()
        d["learning"]   := Map("threshold", 2)
        d["autoswitch"] := Map(
            "triggers", " .,;:!?)]}>`"'",
            "toggle_delay_ms", 60
        )
        d["translit"]   := Map("system", "gost")
        d["input"]      := Map("debug_on_start", false)
        d["palette"]    := Map("hotkey", "^Pause")
        d["forcewords"] := Map("enabled", true)
        return d
    }

    static Save() {
        dir := A_ScriptDir . "\data"
        if !DirExist(dir)
            DirCreate(dir)
        try {
            f := FileOpen(PuntoSettings.ConfigPath, "w", "UTF-8")
            if !f
                return false
            f.Write(JSON.stringify(PuntoSettings.data, 2))
            f.Close()
            return true
        }
        return false
    }

    ; ------------------------------------------------------------
    ; Apply — применить настройки к статическим полям модулей.
    ; Вызывается из Punto.Init() ПОСЛЕ инициализации всех модулей.
    static Apply() {
        PuntoSettings.Init()
        d := PuntoSettings.data

        if d.Has("learning") && d["learning"].Has("threshold")
            PuntoLearning.SetThreshold(Integer(d["learning"]["threshold"]))

        if d.Has("autoswitch") {
            a := d["autoswitch"]
            if a.Has("triggers")
                PuntoAutoswitch.TRIGGER_SEPS := a["triggers"]
            if a.Has("toggle_delay_ms")
                PuntoAutoswitch.TOGGLE_DELAY_MS := Integer(a["toggle_delay_ms"])
        }

        if d.Has("translit") && d["translit"].Has("system")
            PuntoTranslit.SetSystem(d["translit"]["system"])

        if d.Has("input") && d["input"].Has("debug_on_start")
                && d["input"]["debug_on_start"]
            PuntoInput.EnableDebug()
    }

    ; ------------------------------------------------------------
    ; Get/Set — доступ по точечному пути ("learning.threshold").
    static Get(path, default := "") {
        PuntoSettings.Init()
        parts := StrSplit(path, ".")
        m := PuntoSettings.data
        for p in parts {
            if !IsObject(m) || !m.Has(p)
                return default
            m := m[p]
        }
        return m
    }

    static Set(path, value) {
        PuntoSettings.Init()
        parts := StrSplit(path, ".")
        m := PuntoSettings.data
        Loop parts.Length - 1 {
            p := parts[A_Index]
            if !m.Has(p) || !IsObject(m[p])
                m[p] := Map()
            m := m[p]
        }
        m[parts[parts.Length]] := value
        return PuntoSettings.Save()
    }
}
