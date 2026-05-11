; ============================================================
; features/Translit.ahk — транслитерация ru ↔ латиница (AHK v2)
;
; Системы:
;   "gost"   — ГОСТ 7.79-2000 система Б (для дорожных знаков, виз и т.д.)
;   "mvd"    — МВД (паспортный, по приказу МВД 2014)
;   "simple" — упрощённая (Google/Yandex-style, без диакритики)
;
; Прямое: ru → lat ; обратное: попытка lat → ru (только simple).
; Применяется к выделенному тексту, выделение сохраняется.
; ============================================================

class PuntoTranslit {
    static system := "gost"          ; настраиваемо

    ; ---- Таблицы (lowercase, добавляется автоматический uppercase) ----
    static MAP_GOST := Map(
        "а","a", "б","b", "в","v", "г","g", "д","d", "е","e", "ё","yo",
        "ж","zh","з","z", "и","i", "й","j", "к","k", "л","l", "м","m",
        "н","n", "о","o", "п","p", "р","r", "с","s", "т","t", "у","u",
        "ф","f", "х","x", "ц","cz","ч","ch","ш","sh","щ","shh",
        "ъ","``","ы","y`'","ь","`'", "э","e`'","ю","yu","я","ya"
    )
    static MAP_MVD := Map(
        "а","a", "б","b", "в","v", "г","g", "д","d", "е","e", "ё","e",
        "ж","zh","з","z", "и","i", "й","i", "к","k", "л","l", "м","m",
        "н","n", "о","o", "п","p", "р","r", "с","s", "т","t", "у","u",
        "ф","f", "х","kh","ц","ts","ч","ch","ш","sh","щ","shch",
        "ъ","ie","ы","y", "ь","",  "э","e", "ю","iu","я","ia"
    )
    static MAP_SIMPLE := Map(
        "а","a", "б","b", "в","v", "г","g", "д","d", "е","e", "ё","yo",
        "ж","zh","з","z", "и","i", "й","y", "к","k", "л","l", "м","m",
        "н","n", "о","o", "п","p", "р","r", "с","s", "т","t", "у","u",
        "ф","f", "х","h", "ц","ts","ч","ch","ш","sh","щ","sch",
        "ъ","", "ы","y", "ь","", "э","e", "ю","yu","я","ya"
    )

    static SetSystem(name) {
        if (name = "gost" || name = "mvd" || name = "simple")
            PuntoTranslit.system := name
    }

    static GetMap() {
        if (PuntoTranslit.system = "mvd")
            return PuntoTranslit.MAP_MVD
        if (PuntoTranslit.system = "simple")
            return PuntoTranslit.MAP_SIMPLE
        return PuntoTranslit.MAP_GOST
    }

    ; ru → lat: проходим по символам, для каждого ищем замену в Map.
    ; Если символ был в верхнем регистре, поднимаем результат.
    static Forward(text) {
        m := PuntoTranslit.GetMap()
        out := ""
        Loop Parse, text {
            ch := A_LoopField
            low := StrLower(ch)
            if m.Has(low) {
                rep := m[low]
                ; uppercase: ОПЕРАТОРЫ = и != в AHK v2 case-insensitive,
                ; нужно ==/!== для проверки регистра.
                if (ch == StrUpper(ch) && ch !== StrLower(ch)) {
                    if (StrLen(rep) > 1)
                        out .= StrUpper(SubStr(rep, 1, 1)) . SubStr(rep, 2)
                    else
                        out .= StrUpper(rep)
                } else {
                    out .= rep
                }
            } else {
                out .= ch
            }
        }
        return out
    }

    ; lat → ru (приблизительно, только simple-таблица: yo→ё, zh→ж, и т.д.)
    static Backward(text) {
        ; Делаем обратную таблицу через нормированные ключи
        rev := Map()
        rev.CaseSense := false                  ; ДО заполнения (иначе Map.CaseSense вылетит)
        rev["yo"] := "ё"
        rev["zh"] := "ж"
        rev["kh"] := "х"
        rev["ts"] := "ц"
        rev["ch"] := "ч"
        rev["sh"] := "ш"
        rev["sch"] := "щ"
        rev["yu"] := "ю"
        rev["ya"] := "я"
        rev["e"] := "е", rev["a"] := "а", rev["b"] := "б", rev["v"] := "в"
        rev["g"] := "г", rev["d"] := "д", rev["z"] := "з", rev["i"] := "и"
        rev["y"] := "ы", rev["k"] := "к", rev["l"] := "л", rev["m"] := "м"
        rev["n"] := "н", rev["o"] := "о", rev["p"] := "п", rev["r"] := "р"
        rev["s"] := "с", rev["t"] := "т", rev["u"] := "у", rev["f"] := "ф"
        rev["h"] := "х", rev["c"] := "ц", rev["j"] := "й"

        out := ""
        i := 1
        L := StrLen(text)
        while (i <= L) {
            matched := false
            nList := [3, 2, 1]
            for n in nList {
                if (i + n - 1 > L)
                    continue
                src := SubStr(text, i, n)
                chunk := StrLower(src)
                if rev.Has(chunk) {
                    rep := rev[chunk]
                    first := SubStr(src, 1, 1)
                    firstLow := StrLower(first)
                    firstUp  := StrUpper(first)
                    ; == / !== — case-sensitive в AHK v2
                    if (first == firstUp && first !== firstLow) {
                        if (StrLen(rep) > 1)
                            rep := StrUpper(SubStr(rep, 1, 1)) . SubStr(rep, 2)
                        else
                            rep := StrUpper(rep)
                    }
                    out .= rep
                    i += n
                    matched := true
                    break
                }
            }
            if !matched {
                out .= SubStr(text, i, 1)
                i++
            }
        }
        return out
    }

    ; ----- API для хоткеев -----
    static TranslitSelected() {
        text := PuntoCase.GetSelection()
        if (text = "")
            return
        ; Авто-направление: если в тексте больше кириллицы — Forward, иначе Backward
        cnt := Map("cyr", 0, "lat", 0)
        Loop Parse, text {
            code := Ord(A_LoopField)
            if ((code >= 0x0410 && code <= 0x044F) || code = 0x0451 || code = 0x0401)
                cnt["cyr"]++
            else if ((code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A))
                cnt["lat"]++
        }
        result := (cnt["cyr"] >= cnt["lat"])
            ? PuntoTranslit.Forward(text)
            : PuntoTranslit.Backward(text)
        PuntoCase.PutSelection(result)
    }
}
