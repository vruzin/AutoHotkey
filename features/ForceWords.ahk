; ============================================================
; features/ForceWords.ahk — слова с фиксированным регистром (AHK v2)
;
; Идея: некоторые технические слова должны быть набраны в строго
; определённом регистре независимо от того, как набрал пользователь.
;   html, HTML, Html, hTML, реьд (в EN), РЕЬД  →  HTML
;
; Срабатывает даже если автозамена выключена (Alt+Pause) — это
; отдельная сущность поверх Punto.
;
; Файл: data/force_words.json
; Формат:
;   [ "HTML", "Golang", "Vue", "JavaScript", ... ]
;
; Зависит от: JSON.ahk, PuntoDict (ClassifyWord), PuntoLayout (Convert).
; ============================================================

class PuntoForceWords {
    static lookup := Map()              ; lower(word) → properCase
    static Initialized := false
    static ConfigPath := ""

    static Init() {
        if PuntoForceWords.Initialized
            return
        PuntoForceWords.lookup := Map()
        PuntoForceWords.lookup.CaseSense := false
        PuntoForceWords.ConfigPath := A_ScriptDir . "\data\force_words.json"

        list := []
        if FileExist(PuntoForceWords.ConfigPath) {
            try {
                txt := FileRead(PuntoForceWords.ConfigPath, "UTF-8")
                arr := JSON.parse(txt)
                for w in arr
                    list.Push(w)
            } catch {
                list := PuntoForceWords.Defaults()
                PuntoForceWords.Save()
            }
        } else {
            list := PuntoForceWords.Defaults()
            PuntoForceWords.Save()
        }
        for w in list
            PuntoForceWords.lookup[StrLower(w)] := w
        PuntoForceWords.Initialized := true
    }

    static Defaults() {
        return [
            "HTML", "CSS", "SCSS", "Sass", "Less", "Stylus",
            "JavaScript", "TypeScript", "Node", "NodeJS",
            "Vue", "VueJS", "Nuxt", "React", "Angular", "Svelte",
            "Golang", "PHP", "Python", "Ruby", "Rust", "Java", "Kotlin", "Swift",
            "Docker", "Kubernetes", "Nginx", "Apache",
            "Git", "GitHub", "GitLab", "Bitbucket",
            "HTTP", "HTTPS", "TCP", "UDP", "DNS", "CDN",
            "JSON", "XML", "YAML", "Markdown", "CSV",
            "SQL", "MySQL", "PgSQL", "PostgreSQL", "SQLite", "Redis", "MongoDB",
            "API", "REST", "GraphQL", "gRPC", "WebSocket",
            "URL", "URI", "UUID", "GUID", "ID",
            "JWT", "OAuth", "SSO", "SSL", "TLS", "SSH",
            "OS", "CPU", "GPU", "RAM", "ROM", "SSD", "HDD",
            "IDE", "CLI", "GUI", "SDK", "API",
            "NPM", "Yarn", "PNPM",
            "VS", "VSCode", "WebStorm", "IntelliJ", "PyCharm", "Sublime"
        ]
    }

    static Save() {
        list := []
        for k, v in PuntoForceWords.lookup
            list.Push(v)
        ; Если пустой — записать дефолты (например, при первом запуске)
        if (list.Length = 0)
            list := PuntoForceWords.Defaults()
        dir := A_ScriptDir . "\data"
        if !DirExist(dir)
            DirCreate(dir)
        try {
            f := FileOpen(PuntoForceWords.ConfigPath, "w", "UTF-8")
            if !f
                return false
            f.Write(JSON.stringify(list, 2))
            f.Close()
            return true
        }
        return false
    }

    ; ------------------------------------------------------------
    ; Find — для слова любой раскладки/регистра вернуть «канонический»
    ; вариант, если найден в списке. Иначе пустую строку.
    ; ВАЖНО: явно нормализуем регистр (Map.CaseSense не надёжен для
    ; кириллицы вне ru-локали).
    static Find(word) {
        PuntoForceWords.Init()
        if (word = "")
            return ""

        low := StrLower(word)
        if PuntoForceWords.lookup.Has(low)
            return PuntoForceWords.lookup[low]

        cls := PuntoDict.ClassifyWord(word)
        if (cls["type"] = "cyr") {
            asLat := StrLower(PuntoLayout.Convert(word, "cyr2lat"))
            if PuntoForceWords.lookup.Has(asLat)
                return PuntoForceWords.lookup[asLat]
        }
        return ""
    }

    ; ------------------------------------------------------------
    ; Add / Remove — управление списком через UI (палитра, этап 4).
    static Add(word) {
        PuntoForceWords.Init()
        if (word = "")
            return false
        PuntoForceWords.lookup[StrLower(word)] := word
        return PuntoForceWords.Save()
    }

    static Remove(word) {
        PuntoForceWords.Init()
        key := StrLower(word)
        if !PuntoForceWords.lookup.Has(key)
            return false
        PuntoForceWords.lookup.Delete(key)
        return PuntoForceWords.Save()
    }

    static All() {
        PuntoForceWords.Init()
        arr := []
        for k, v in PuntoForceWords.lookup
            arr.Push(v)
        return arr
    }
}
