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
    ; Параметр rootDir можно передать в скриптах, которые запускаются
    ; не из корня проекта (например, из tools/). По умолчанию берётся
    ; PuntoDict.Root() — A_ScriptDir, что подходит когда main.ahk в корне.
    ; Не падает при отсутствии файла (сообщает в LoadStats).
    static Init(rootDir := "") {
        if PuntoDict.Initialized
            return

        if (rootDir = "")
            rootDir := PuntoDict.Root()
        ruPath := rootDir . "\data\dict\ru.bin"
        enPath := rootDir . "\data\dict\en.bin"

        t0 := A_TickCount
        PuntoDict.Ru := PuntoDict.LoadFile(ruPath)
        PuntoDict.En := PuntoDict.LoadFile(enPath)
        ; CaseSense уже выставлен в LoadFile до заполнения Map.

        PuntoDict.LoadStats["ru"] := PuntoDict.Ru.Count
        PuntoDict.LoadStats["en"] := PuntoDict.En.Count
        PuntoDict.LoadStats["ms"] := A_TickCount - t0
        PuntoDict.Initialized := true
    }

    ; Root — корневой каталог проекта (где лежит main.ahk и data/).
    ; Авто-определение: если рядом со скриптом есть data\dict\ru.bin — это корень.
    ; Иначе поднимаемся на уровень вверх (для скриптов из tools/).
    static Root() {
        if FileExist(A_ScriptDir . "\data\dict\ru.bin")
            return A_ScriptDir
        parent := A_ScriptDir . "\.."
        if FileExist(parent . "\data\dict\ru.bin")
            return parent
        return A_ScriptDir
    }

    static LoadFile(path) {
        m := Map()
        m.CaseSense := false
        if !FileExist(path)
            return m
        ; ВАЖНО: открываем явно в UTF-8 (если использовать глобальный
        ; FileEncoding или Loop Read — AHK v2 по умолчанию читает в
        ; системной кодировке, и кириллица превращается в мусор).
        f := FileOpen(path, "r", "UTF-8")
        if !f
            return m
        while !f.AtEOF {
            w := Trim(f.ReadLine())
            if (w != "")
                m[w] := 1
        }
        f.Close()
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
    ; ClassifyWord — анализ типа символов слова.
    ; Возвращает Map { latin: N, cyrillic: N, other: N, type: "lat"|"cyr"|"mixed"|"empty" }.
    ; "lat" — слово целиком из латиницы (с дефисом/апострофом), таких > 0, cyr = 0.
    ; "cyr" — то же для кириллицы.
    ; "mixed" — есть символы обеих категорий.
    static ClassifyWord(word) {
        lat := 0, cyr := 0, oth := 0
        Loop Parse, word {
            code := Ord(A_LoopField)
            if ((code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A))
                lat++
            else if ((code >= 0x0410 && code <= 0x044F) || code = 0x0451 || code = 0x0401)
                cyr++
            else
                oth++
        }
        if (lat = 0 && cyr = 0)
            type := "empty"
        else if (lat > 0 && cyr = 0)
            type := "lat"
        else if (cyr > 0 && lat = 0)
            type := "cyr"
        else
            type := "mixed"
        return Map("latin", lat, "cyrillic", cyr, "other", oth, "type", type)
    }

    ; ------------------------------------------------------------
    ; LooksLikeWrongLayout — главный детектор.
    ; НЕ полагается на текущую раскладку Windows (она часто врёт или
    ; запаздывает). Решение принимается ТОЛЬКО на основе символов слова:
    ;   • Слово из латиницы (a-z): есть в en.bin → OK. Иначе конвертируем
    ;     lat2cyr и смотрим в ru.bin — если есть, это была wrong layout.
    ;   • Слово из кириллицы (а-я): аналогично с ru.bin → cyr2lat → en.bin.
    ;   • Смешанные (намеренные `привОт`, цифры с буквами, идентификаторы)
    ;     — не трогаем.
    ; Параметр currentLang оставлен для совместимости (используется
    ; только в Punto.HandleBreak); сам детектор его игнорирует.
    static LooksLikeWrongLayout(word, currentLang := "") {
        if (StrLen(word) < 2)
            return Map("wrong", false, "reason", "too_short")

        cls := PuntoDict.ClassifyWord(word)

        if (cls["type"] = "lat") {
            if PuntoDict.HasWord(word, "en")
                return Map("wrong", false, "reason", "in_en_dict")
            converted := PuntoLayout.Convert(word, "lat2cyr")
            if PuntoDict.HasWord(converted, "ru") {
                return Map(
                    "wrong",          true,
                    "suggestion",     converted,
                    "suggestionLang", "ru",
                    "fromLang",       "en",
                    "reason",         "lat_word_is_ru_in_other_layout"
                )
            }
            return Map("wrong", false, "reason", "unknown_lat")
        }

        if (cls["type"] = "cyr") {
            if PuntoDict.HasWord(word, "ru")
                return Map("wrong", false, "reason", "in_ru_dict")
            converted := PuntoLayout.Convert(word, "cyr2lat")
            if PuntoDict.HasWord(converted, "en") {
                return Map(
                    "wrong",          true,
                    "suggestion",     converted,
                    "suggestionLang", "en",
                    "fromLang",       "ru",
                    "reason",         "cyr_word_is_en_in_other_layout"
                )
            }
            return Map("wrong", false, "reason", "unknown_cyr")
        }

        ; смешанное / пустое
        return Map("wrong", false, "reason", "mixed_or_empty")
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
