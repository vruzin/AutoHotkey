; ============================================================
; core/History.ahk — стек последних действий Punto (AHK v2)
;
; Используется для:
;   • undo последнего автопереключения (Break сразу после автозамены)
;   • «переключить раскладку последнего слова» (Break когда автозамены не было)
;   • самообучения (Learning записывает, какие слова пользователь
;     раз за разом исправляет вручную)
;
; Запись содержит:
;   type        — "autoswitch" (сделано Punto) | "userType" (просто ввод)
;   wordTyped   — что пользователь физически набрал
;   wordFinal   — что сейчас в поле ввода после возможной автозамены
;   langBefore  — раскладка до возможного переключения
;   langAfter   — раскладка после
;   switched    — было ли изменение раскладки
;   timestamp   — A_TickCount
; ============================================================

class PuntoHistory {
    static stack := []
    static MAX_SIZE := 50

    ; ------------------------------------------------------------
    static Push(entry) {
        if !entry.Has("timestamp")
            entry["timestamp"] := A_TickCount
        PuntoHistory.stack.Push(entry)
        while PuntoHistory.stack.Length > PuntoHistory.MAX_SIZE
            PuntoHistory.stack.RemoveAt(1)
    }

    ; ------------------------------------------------------------
    ; Last — самая последняя запись (нет — вернуть пустой Map).
    static Last() {
        if PuntoHistory.stack.Length = 0
            return Map()
        return PuntoHistory.stack[PuntoHistory.stack.Length]
    }

    ; ------------------------------------------------------------
    ; Pop — удалить и вернуть последнюю запись.
    static Pop() {
        if PuntoHistory.stack.Length = 0
            return Map()
        return PuntoHistory.stack.Pop()
    }

    ; ------------------------------------------------------------
    ; Clear — сбросить стек (например, при переключении окна).
    static Clear() {
        PuntoHistory.stack := []
    }

    ; ------------------------------------------------------------
    ; LastAutoswitchFresh — была ли последняя запись автопереключением,
    ; случившимся не более N миллисекунд назад. Используется в логике Break:
    ; если только что сработала автозамена — Break её отменяет,
    ; иначе — конвертирует последнее введённое слово.
    static LastAutoswitchFresh(maxAgeMs := 3000) {
        last := PuntoHistory.Last()
        if (last.Count = 0)
            return false
        if (last["type"] != "autoswitch")
            return false
        if (A_TickCount - last["timestamp"] > maxAgeMs)
            return false
        return true
    }
}
