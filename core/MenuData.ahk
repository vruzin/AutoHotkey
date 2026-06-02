; ============================================================
; core/MenuData.ahk — единый источник для меню (родное AHK Menu + лаунчер).
;
; Меню описывается МАССИВОМ записей (Map). Из одного массива строятся:
;   • родное AHK Menu (MenuData.Build) — для CapsLock+D и т.п.
;   • плоский список (MenuData.Flatten) — для поиска в лаунчере.
;
; Формат записи (Map):
;   Map("label", "docker ps", "hint", "Список", "fn", () => ...)   — пункт
;   Map("label", "compose", "sub", [ ...записи... ])                — подменю
;   Map("sep", true)                                               — разделитель
;
; "hint" — необязательная подсказка (показывается в AHK через `t<hint>).
; ============================================================

class MenuData {
    ; ------------------------------------------------------------
    ; Build — построить родное AHK Menu из массива записей (рекурсивно).
    ; Возвращает объект Menu, готовый к .Show().
    static Build(items) {
        m := Menu()
        idx := 0
        for it in items {
            if (it.Has("sep") && it["sep"]) {
                m.Add()
                continue
            }
            idx++
            label := it["label"]
            ; добавим горячую цифру/букву и подсказку через таб
            text := "&" . idx . ". " . label
            if (it.Has("hint") && it["hint"] != "")
                text .= "`t" . it["hint"]

            if (it.Has("sub")) {
                ; sub может быть массивом записей ИЛИ уже готовым объектом Menu
                ; (например, динамическое systemctl-меню). Готовый Menu — как есть.
                sub := it["sub"]
                m.Add(text, (sub is Menu) ? sub : MenuData.Build(sub))
            } else {
                m.Add(text, it["fn"])
            }
        }
        return m
    }

    ; ------------------------------------------------------------
    ; Flatten — плоский список листовых пунктов для лаунчера.
    ; prefix — префикс пути ("Docker"), складывается через " › ".
    ; Возвращает массив Map("label", "Docker › docker ps", "fn", fn).
    static Flatten(items, prefix := "") {
        out := []
        for it in items {
            if (it.Has("sep") && it["sep"])
                continue
            label := it["label"]
            path := (prefix = "") ? label : (prefix . " › " . label)
            if (it.Has("sub")) {
                ; Готовый Menu (динамический) не разворачиваем в плоский список —
                ; в лаунчере он будет недоступен (это редкие systemctl-команды).
                if (it["sub"] is Menu)
                    continue
                for sub in MenuData.Flatten(it["sub"], path)
                    out.Push(sub)
            } else {
                out.Push(Map("label", path, "fn", it["fn"]))
            }
        }
        return out
    }
}
