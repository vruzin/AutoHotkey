; ============================================================
; core/Learning.ahk — самообучаемый словарь слов (AHK v2)
;
; Идея: если пользователь >= THRESHOLD раз нажал Break, чтобы исправить
; раскладку конкретного слова, или наоборот — отменил автозамену Punto
; на этом слове — мы запоминаем это слово как «точно правильное в этом
; языке» и больше не пытаемся его автоматически переключать.
;
; Файл: data/learned_words.json
; Формат:
;   {
;     "приёмов": { "lang": "ru", "count": 3, "lastSeen": 12345 },
;     "Vue":     { "lang": "en", "count": 5, "lastSeen": 67890 }
;   }
; Запись на диск — debounced (после простоя в 5 сек), чтобы не дёргать
; диск на каждое слово.
;
; Зависит от: JSON.ahk (подключается в main.ahk).
; ============================================================

class PuntoLearning {
    static words := Map()
    static Initialized := false
    static threshold := 2               ; настраивается из settings.json
    static MAX_SIZE := 50000
    static SAVE_DELAY_MS := 5000
    static ConfigPath := ""
    static dirty := false
    static saveTimer := 0

    ; ------------------------------------------------------------
    static Init(threshold := 2) {
        if PuntoLearning.Initialized
            return
        PuntoLearning.threshold := threshold
        PuntoLearning.ConfigPath := A_ScriptDir . "\data\learned_words.json"
        PuntoLearning.Load()
        PuntoLearning.Initialized := true
    }

    static Load() {
        m := Map()
        m.CaseSense := false
        if FileExist(PuntoLearning.ConfigPath) {
            try {
                txt := FileRead(PuntoLearning.ConfigPath, "UTF-8")
                data := JSON.parse(txt)
                ; ожидаем объект-словарь word -> meta
                for k, v in data
                    m[k] := v
            } catch {
                ; повреждённый JSON — стартуем с пустого, оригинал сохраняем как .bak
                try FileCopy(PuntoLearning.ConfigPath, PuntoLearning.ConfigPath . ".bak", 1)
            }
        }
        PuntoLearning.words := m
    }

    ; ------------------------------------------------------------
    ; Record — пользователь подтвердил, что слово правильное в данной раскладке.
    ; Инкрементирует счётчик, обновляет lastSeen, планирует отложенное сохранение.
    static Record(word, lang) {
        PuntoLearning.Init()
        if (word = "" || StrLen(word) < 2)
            return

        if PuntoLearning.words.Has(word) {
            entry := PuntoLearning.words[word]
            ; если язык не совпал — записываем как новый (странный случай, но возможен)
            if (entry["lang"] != lang)
                entry := Map("lang", lang, "count", 0, "lastSeen", 0)
            entry["count"] := entry["count"] + 1
            entry["lastSeen"] := A_TickCount
            PuntoLearning.words[word] := entry
        } else {
            PuntoLearning.words[word] := Map(
                "lang",     lang,
                "count",    1,
                "lastSeen", A_TickCount
            )
        }

        PuntoLearning.EnforceLimit()
        PuntoLearning.ScheduleSave()
    }

    ; ------------------------------------------------------------
    ; IsKnown — слово известно как правильное в указанной раскладке.
    static IsKnown(word, lang) {
        PuntoLearning.Init()
        if !PuntoLearning.words.Has(word)
            return false
        entry := PuntoLearning.words[word]
        return (entry["lang"] = lang) && (entry["count"] >= PuntoLearning.threshold)
    }

    ; ------------------------------------------------------------
    ; EnforceLimit — при превышении MAX_SIZE удаляем слова с минимальным
    ; count, среди равных — самые старые (по lastSeen).
    static EnforceLimit() {
        if PuntoLearning.words.Count <= PuntoLearning.MAX_SIZE
            return
        ; Собираем пары [word, score], сортируем по возрастанию score
        ; (низкий score — кандидат на удаление). score = count*1e9 + lastSeen.
        arr := []
        for w, meta in PuntoLearning.words
            arr.Push([w, meta["count"] * 1000000000 + meta["lastSeen"]])
        ; простой Insertion sort — нам нужно удалить только Count - MAX штук
        toRemove := PuntoLearning.words.Count - PuntoLearning.MAX_SIZE
        ; Берём приблизительный нижний слой: всё с count=1 и старейшим lastSeen
        ; (полная сортировка 50к элементов в AHK — медленно, делаем выборку)
        removed := 0
        for pair in arr {
            if (removed >= toRemove)
                break
            w := pair[1]
            entry := PuntoLearning.words[w]
            if (entry["count"] = 1) {
                PuntoLearning.words.Delete(w)
                removed++
            }
        }
    }

    ; ------------------------------------------------------------
    ; Debounced save: накопить изменения, сохранить через SAVE_DELAY_MS
    ; после последней правки.
    static ScheduleSave() {
        PuntoLearning.dirty := true
        if PuntoLearning.saveTimer
            SetTimer(PuntoLearning.saveTimer, 0)
        PuntoLearning.saveTimer := ObjBindMethod(PuntoLearning, "Save")
        SetTimer(PuntoLearning.saveTimer, -PuntoLearning.SAVE_DELAY_MS)
    }

    static Save() {
        if !PuntoLearning.dirty
            return
        obj := Map()
        for w, meta in PuntoLearning.words
            obj[w] := meta
        try {
            dir := A_ScriptDir . "\data"
            if !DirExist(dir)
                DirCreate(dir)
            f := FileOpen(PuntoLearning.ConfigPath, "w", "UTF-8")
            if !f
                return
            f.Write(JSON.stringify(obj, 2))
            f.Close()
            PuntoLearning.dirty := false
        }
    }

    ; ------------------------------------------------------------
    ; SetThreshold — изменить порог в runtime (из UI).
    static SetThreshold(n) {
        if (n < 1)
            n := 1
        PuntoLearning.threshold := n
    }

    ; ------------------------------------------------------------
    ; Stats — диагностика (для палитры / debug-overlay).
    static Stats() {
        PuntoLearning.Init()
        return Map(
            "total",     PuntoLearning.words.Count,
            "threshold", PuntoLearning.threshold,
            "dirty",     PuntoLearning.dirty
        )
    }
}
