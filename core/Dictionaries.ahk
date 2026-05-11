; ============================================================
; core/Dictionaries.ahk — словарная проверка слов (AHK v2)
;
; Загружает data/dict/ru.bin и en.bin (UTF-8, по слову на строку) в Map.
; После инициализации:
;   • HasWord("привет", "ru")           — точное наличие
;   • LooksLikeWrongLayout(word, lang)  — главное решение «нужно ли переключить»
; ============================================================

class PuntoDict {
    static Ru := Map()                  ; word → 1
    static En := Map()
    static Initialized := false
    static LoadStats := Map()           ; диагностика (счётчики, ms)

    ; ------------------------------------------------------------
    ; Init — однократная загрузка обоих словарей.
    ; Не падает при отсутствии файла (сообщает в LoadStats), чтобы Punto
    ; могла стартовать даже без словарей (биграммы продолжат работать).
    static Init() {
        if PuntoDict.Initialized
            return

        root := PuntoDict.Root()
        ruPath := root . "\data\dict\ru.bin"
        enPath := root . "\data\dict\en.bin"

        t0 := A_TickCount
        PuntoDict.Ru := PuntoDict.LoadFile(ruPath)
        PuntoDict.En := PuntoDict.LoadFile(enPath)
        ; CaseSense уже выставлен в LoadFile до заполнения Map.

        PuntoDict.LoadStats["ru"] := PuntoDict.Ru.Count
        PuntoDict.LoadStats["en"] := PuntoDict.En.Count
        PuntoDict.LoadStats["ms"] := A_TickCount - t0
        PuntoDict.Initialized := true
    }

    static Root() {
        ; A_ScriptDir == корень проекта (там main.ahk).
        return A_ScriptDir
    }

    static LoadFile(path) {
        m := Map()
        m.CaseSense := false
        if !FileExist(path)
            return m
        Loop Read, path
        {
            w := Trim(A_LoopReadLine)
            if (w != "")
                m[w] := 1
        }
        return m
    }

    ; ------------------------------------------------------------
    ; HasWord — есть ли слово в общем словаре указанного языка.
    static HasWord(word, lang) {
        if !PuntoDict.Initialized
            PuntoDict.Init()
        if (lang = "ru")
            return PuntoDict.Ru.Has(word)
        if (lang = "en")
            return PuntoDict.En.Has(word)
        return false
    }

    ; ------------------------------------------------------------
    ; LooksLikeWrongLayout — основной детектор «слово введено не в той раскладке».
    ; Возвращает Map с полями:
    ;   wrong          — true/false
    ;   suggestion     — слово, переписанное в правильной раскладке (если wrong)
    ;   suggestionLang — раскладка, в которой это слово существует
    ; Если wrong=false — остальные поля могут отсутствовать.
    ;
    ; Алгоритм:
    ;   1) Если слово существует в текущем словаре — точно НЕ ошибка.
    ;   2) Конвертируем слово в противоположную раскладку.
    ;   3) Если конвертированное СУЩЕСТВУЕТ в словаре противоположного языка
    ;      — это ошибка раскладки, возвращаем suggestion.
    ;   4) Иначе — не уверены, не трогаем.
    static LooksLikeWrongLayout(word, currentLang) {
        if (StrLen(word) < 2)
            return Map("wrong", false)

        if PuntoDict.HasWord(word, currentLang)
            return Map("wrong", false)

        ; Если слово известно как "правильное в этом языке" пользователем
        ; (Learning) — тоже не трогаем; проверка снаружи, не здесь.

        otherLang := (currentLang = "ru") ? "en" : "ru"
        direction := (currentLang = "ru") ? "cyr2lat" : "lat2cyr"
        converted := PuntoLayout.Convert(word, direction)

        if PuntoDict.HasWord(converted, otherLang) {
            return Map(
                "wrong",          true,
                "suggestion",     converted,
                "suggestionLang", otherLang
            )
        }
        return Map("wrong", false)
    }

    ; ------------------------------------------------------------
    ; HasBadBigrams — быстрая эвристика «слово точно не русское»,
    ; без обращения в Map. Используется для дешёвого предварительного фильтра.
    ; Сейчас не используется (словарь точнее), оставлено на расширение.
    static HasBadBigrams(word) {
        ; Слово начинается с ь/ъ/ы — невозможно в русском
        first := SubStr(word, 1, 1)
        if (first = "ь" || first = "ъ" || first = "ы")
            return true
        ; Сдвоенные «странные» буквы
        bad := ["ьь", "ъъ", "ыь", "ьы", "ъь", "ьъ"]
        for b in bad
            if InStr(word, b, true)
                return true
        return false
    }
}
