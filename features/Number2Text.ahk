; ============================================================
; features/Number2Text.ahk — число прописью (AHK v2)
;
;   PuntoNumber.ToText(123)       → "сто двадцать три"
;   PuntoNumber.ToText(1234567)   → "один миллион двести тридцать четыре тысячи пятьсот шестьдесят семь"
;   PuntoNumber.ToText(0)         → "ноль"
;   PuntoNumber.ToText(-42)       → "минус сорок два"
;
; Учитывает грамматику русского:
;   • род «один/одна» (одна тысяча, один миллион);
;   • склонения «тысяча/тысячи/тысяч»;
;   • разряды до квадриллиона.
;
; ToCurrency(123.45) → "сто двадцать три рубля 45 копеек" (с дробной частью).
; ============================================================

class PuntoNumber {

    static UNITS_M := ["", "один",   "два",   "три",   "четыре", "пять", "шесть", "семь", "восемь", "девять"]
    static UNITS_F := ["", "одна",   "две",   "три",   "четыре", "пять", "шесть", "семь", "восемь", "девять"]
    static TEENS   := ["десять","одиннадцать","двенадцать","тринадцать","четырнадцать","пятнадцать","шестнадцать","семнадцать","восемнадцать","девятнадцать"]
    static TENS    := ["", "", "двадцать","тридцать","сорок","пятьдесят","шестьдесят","семьдесят","восемьдесят","девяносто"]
    static HUNDREDS := ["", "сто","двести","триста","четыреста","пятьсот","шестьсот","семьсот","восемьсот","девятьсот"]

    ; Названия разрядов: [singular, paucal (2-4), plural (5+), gender]
    static ORDERS := [
        ["",        "",         "",         "m"],
        ["тысяча",  "тысячи",   "тысяч",    "f"],
        ["миллион", "миллиона", "миллионов","m"],
        ["миллиард","миллиарда","миллиардов","m"],
        ["триллион","триллиона","триллионов","m"]
    ]

    ; Триада 0..999 → строка ("сто двадцать три") с учётом рода
    static Triad(n, gender) {
        if (n = 0)
            return ""
        out := ""
        h := n // 100
        rest := Mod(n, 100)
        if (h > 0)
            out .= PuntoNumber.HUNDREDS[h + 1] . " "
        if (rest >= 10 && rest < 20) {
            out .= PuntoNumber.TEENS[rest - 9]
        } else {
            t := rest // 10
            u := Mod(rest, 10)
            if (t > 0)
                out .= PuntoNumber.TENS[t + 1] . (u > 0 ? " " : "")
            if (u > 0) {
                if (gender = "f")
                    out .= PuntoNumber.UNITS_F[u + 1]
                else
                    out .= PuntoNumber.UNITS_M[u + 1]
            }
        }
        return Trim(out)
    }

    ; По числу (последние 2 цифры) выбрать форму разряда: 1 тысяча, 2 тысячи, 5 тысяч
    static OrderForm(n, orderIdx) {
        order := PuntoNumber.ORDERS[orderIdx]
        ; Десятки от 11 до 14 → plural
        lastTwo := Mod(n, 100)
        lastOne := Mod(n, 10)
        if (lastTwo >= 11 && lastTwo <= 14)
            return order[3]
        if (lastOne = 1)
            return order[1]
        if (lastOne >= 2 && lastOne <= 4)
            return order[2]
        return order[3]
    }

    static ToText(n) {
        if (n = 0)
            return "ноль"
        if (n < 0)
            return "минус " . PuntoNumber.ToText(-n)

        ; Разбиваем число на триады, обрабатываем от младших к старшим
        triads := []
        x := n
        while (x > 0) {
            triads.Push(Mod(x, 1000))
            x := x // 1000
        }

        parts := []
        orderIdx := 1
        Loop triads.Length {
            i := triads.Length - A_Index + 1   ; от старших к младшим
            triad := triads[i]
            curOrder := i                       ; orderIdx (1 = единицы, 2 = тысячи, ...)
            if (triad > 0) {
                gender := PuntoNumber.ORDERS[curOrder][4]
                txt := PuntoNumber.Triad(triad, gender)
                if (curOrder >= 2)
                    txt .= " " . PuntoNumber.OrderForm(triad, curOrder)
                parts.Push(txt)
            }
        }
        out := ""
        for p in parts
            out .= (out ? " " : "") . p
        return out
    }

    static ToCurrency(amount) {
        ; amount = число, может быть дробным (рубли.копейки)
        rub := Integer(amount)
        kop := Round((amount - rub) * 100)
        rubText := PuntoNumber.ToText(rub)
        rubForm := PuntoNumber.RubleForm(rub)
        kopForm := PuntoNumber.KopeykaForm(kop)
        return rubText . " " . rubForm . " " . Format("{:02d}", kop) . " " . kopForm
    }

    static RubleForm(n) {
        lt := Mod(n, 100)
        lo := Mod(n, 10)
        if (lt >= 11 && lt <= 14)
            return "рублей"
        if (lo = 1)
            return "рубль"
        if (lo >= 2 && lo <= 4)
            return "рубля"
        return "рублей"
    }

    static KopeykaForm(n) {
        lt := Mod(n, 100)
        lo := Mod(n, 10)
        if (lt >= 11 && lt <= 14)
            return "копеек"
        if (lo = 1)
            return "копейка"
        if (lo >= 2 && lo <= 4)
            return "копейки"
        return "копеек"
    }

    ; ---- API ----
    ; Заменяет выделенный текст (если это число) на пропись.
    static SelectionToText() {
        text := PuntoCase.GetSelection()
        if (text = "")
            return
        text := Trim(text)
        if !IsNumber(text)
            return
        result := InStr(text, ".") || InStr(text, ",")
            ? PuntoNumber.ToCurrency(text + 0.0)
            : PuntoNumber.ToText(Integer(text))
        PuntoCase.PutSelection(result)
    }
}
