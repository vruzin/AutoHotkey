; ============================================================
; core/Abbreviations.ahk — аббревиатуры (hotstrings) как данные.
;
; Раньше hotstrings были «зашиты» в legacy/abbreviations.ahk (::abbr::text).
; Теперь они в data/abbreviations.json и регистрируются динамически через
; Hotstring(), что позволяет добавлять/редактировать/вкл-выкл/удалять их из
; лаунчера без перезапуска скрипта.
;
; Формат записи JSON:
;   { "abbr": "кон1", "text": "...", "opts": "*", "enabled": true }
;     opts — флаги hotstring: "*" (без конечного символа), "O" (опускать
;     конечный символ), "C" (регистрозависимо), "?" (внутри слова) и т.д.
;
; Длинные шаблоны с переводами строк и функции (Hello по времени суток,
; Win+Alt+U) остаются в legacy/abbreviations.ahk — они не текстовые.
;
; Зависит от: lib/JSON.ahk, Send2() (из main.ahk).
; ============================================================

class Abbreviations {
    static list := []          ; массив Map(abbr, text, opts, enabled)
    static path := ""
    static registered := Map()  ; abbr → true (что уже зарегистрировано в этой сессии)

    ; ------------------------------------------------------------
    static Init() {
        Abbreviations.path := A_LineFile . "\..\..\data\abbreviations.json"
        Abbreviations.Load()
        Abbreviations.ApplyAll()
    }

    ; ------------------------------------------------------------
    static Load() {
        Abbreviations.list := []
        if !FileExist(Abbreviations.path)
            return
        txt := FileRead(Abbreviations.path, "UTF-8")
        data := JSON.parse(txt)
        for rec in data {
            Abbreviations.list.Push(Map(
                "abbr",    rec["abbr"],
                "text",    rec["text"],
                "opts",    rec.Has("opts") ? rec["opts"] : "",
                "enabled", rec.Has("enabled") ? !!rec["enabled"] : true
            ))
        }
    }

    ; ------------------------------------------------------------
    static Save() {
        arr := []
        for r in Abbreviations.list
            arr.Push(Map(
                "abbr", r["abbr"], "text", r["text"],
                "opts", r["opts"], "enabled", r["enabled"] ? true : false
            ))
        txt := JSON.stringify(arr, 2)
        f := FileOpen(Abbreviations.path, "w", "UTF-8")
        f.Write(txt)
        f.Close()
    }

    ; ------------------------------------------------------------
    ; ApplyAll — (пере)зарегистрировать все аббревиатуры по текущему состоянию.
    static ApplyAll() {
        for r in Abbreviations.list
            Abbreviations._Apply(r)
    }

    ; _Apply — зарегистрировать/обновить одну аббревиатуру.
    ; Hotstring("On"/"Off") включает или выключает уже созданную.
    ;
    ; Контекст HotIf(Abbr_LauncherInactive): аббревиатуры срабатывают ТОЛЬКО
    ; когда окно лаунчера НЕ в фокусе. Иначе набор «кон1» в поле поиска лаунчера
    ; раскрывался бы прямо там. Контекст-функция одна и та же (важно: разные
    ; объекты-функции создают разные варианты hotstring).
    static _Apply(rec) {
        trigger := ":" . rec["opts"] . ":" . rec["abbr"]
        bound := Abbreviations._MakeHandler(rec["text"])
        try {
            HotIf(Abbr_LauncherInactive)
            Hotstring(trigger, bound, rec["enabled"] ? "On" : "Off")
            HotIf()                       ; сброс контекста
            Abbreviations.registered[rec["abbr"]] := true
        }
    }

    ; Создаёт обработчик-замыкание для конкретного текста.
    static _MakeHandler(text) {
        return (*) => Send2(text)
    }

    ; ------------------------------------------------------------
    ; Find — найти запись по abbr (или 0).
    static Find(abbr) {
        for r in Abbreviations.list
            if (r["abbr"] = abbr)
                return r
        return 0
    }

    ; ------------------------------------------------------------
    ; Add — добавить новую аббревиатуру (или обновить существующую с тем же abbr).
    static Add(abbr, text, opts := "*", enabled := true) {
        if (abbr = "")
            return false
        existing := Abbreviations.Find(abbr)
        if existing {
            existing["text"] := text
            existing["opts"] := opts
            existing["enabled"] := !!enabled
            Abbreviations._Apply(existing)
        } else {
            rec := Map("abbr", abbr, "text", text, "opts", opts, "enabled", !!enabled)
            Abbreviations.list.Push(rec)
            Abbreviations._Apply(rec)
        }
        Abbreviations.Save()
        return true
    }

    ; ------------------------------------------------------------
    ; Edit — изменить текст (и опц. opts) существующей аббревиатуры.
    static Edit(abbr, newText, newOpts := "") {
        rec := Abbreviations.Find(abbr)
        if !rec
            return false
        rec["text"] := newText
        if (newOpts != "")
            rec["opts"] := newOpts
        Abbreviations._Apply(rec)
        Abbreviations.Save()
        return true
    }

    ; ------------------------------------------------------------
    ; SetEnabled — вкл/выкл аббревиатуру в рантайме.
    static SetEnabled(abbr, on) {
        rec := Abbreviations.Find(abbr)
        if !rec
            return false
        rec["enabled"] := !!on
        Abbreviations._Apply(rec)
        Abbreviations.Save()
        return true
    }

    ; ------------------------------------------------------------
    ; Delete — удалить аббревиатуру совсем (и снять регистрацию).
    static Delete(abbr) {
        idx := 0
        for i, r in Abbreviations.list
            if (r["abbr"] = abbr) {
                idx := i
                break
            }
        if !idx
            return false
        ; Снять hotstring (Off + пустой обработчик).
        try Hotstring(":" . Abbreviations.list[idx]["opts"] . ":" . abbr, , "Off")
        Abbreviations.list.RemoveAt(idx)
        Abbreviations.Save()
        return true
    }

    ; ------------------------------------------------------------
    ; Snapshot — данные для лаунчера: массив Map(abbr, text, enabled).
    static Snapshot() {
        out := []
        for r in Abbreviations.list
            out.Push(Map(
                "abbr",    r["abbr"],
                "text",    r["text"],
                "enabled", r["enabled"] ? true : false
            ))
        return out
    }
}

; ------------------------------------------------------------
; Контекст-функция для HotIf: TRUE, когда окно лаунчера НЕ активно.
; Аббревиатуры регистрируются под этим контекстом, поэтому в поле поиска
; лаунчера они не срабатывают. Именованная (не лямбда) — чтобы при каждой
; регистрации использовался ОДИН И ТОТ ЖЕ объект-функция.
Abbr_LauncherInactive(*) {
    return !SettingsWindow.IsActive()
}
