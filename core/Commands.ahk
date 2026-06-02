; ============================================================
; core/Commands.ahk — единый список команд для лаунчера.
;
; Собирает в один плоский список:
;   • хоткеи и фичи из FeatureRegistry (с человекочитаемой клавишей);
;   • пункты меню из *MenuData() через MenuData.Flatten (Docker › docker ps …).
;
; Лаунчер (ui/Launcher.ahk) зовёт:
;   Commands.Snapshot()  → массив команд для Vue (поиск/запуск/галочки);
;   Commands.Run(id)     → выполнить команду по id;
;   Commands.SetEnabled(id, on) / SetGroupEnabled — для режима настроек.
;
; id команд меню: "menu.<group>.<N>" (например menu.docker.3). fn хранится
; в Commands.menuFns[id]. Хоткеи используют свои id из FeatureRegistry.
;
; Зависит от: FeatureRegistry, MenuData, HotkeyHuman, *MenuData() из legacy.
; ============================================================

class Commands {
    static menuFns := Map()      ; id пункта меню → fn
    static built   := false

    ; Описание меню для лаунчера: ключ группы, человекочитаемое имя,
    ; функция-источник данных. Имя группы используется как префикс пути.
    static MenuSources() {
        return [
            Map("group", "docker", "label", "Docker", "data", DockerMenuData),
            Map("group", "ssh",    "label", "SSH",    "data", SshMenuData),
            Map("group", "build",  "label", "Build",  "data", BuildMenuData),
            Map("group", "fl",     "label", "FL.ru",  "data", FlMenuData),
            Map("group", "dop",    "label", "Сниппеты", "data", DopMenuData),
            Map("group", "main",   "label", "Windows", "data", MainMenuData)
        ]
    }

    ; ------------------------------------------------------------
    ; Snapshot — собрать все команды для UI.
    ; Возвращает Map("items", [ Map(id,label,key,enabled,kind,group) ... ]).
    ; kind: "hotkey" | "feature" | "menuitem". Для menuitem enabled=true всегда
    ; (пункты меню не отключаются — отключается родительский хоткей меню).
    static Snapshot() {
        Commands._BuildMenuFns()
        items := []

        ; 1) Хоткеи и фичи из FeatureRegistry (через групповой Snapshot).
        for g in FeatureRegistry.Snapshot() {
            for it in g["items"] {
                items.Push(Map(
                    "id",        it["id"],
                    "label",     it["label"],
                    "key",       it["key"] != "" ? HotkeyToHuman(it["key"]) : "",
                    "enabled",   it["enabled"],
                    "groupOn",   g["enabled"],
                    "kind",      it["kind"],
                    "group",     g["label"],
                    "scope",     Commands._ScopeOf(it["id"], "command"),
                    ; toggle-команды (фичи И хоткеи) рисуем с иконкой ●/○ и
                    ; неактивным цветом когда выключены — Alt+O работает на любой
                    ; вкладке и сразу виден результат.
                    "toggleable", (it["kind"] = "feature" || it["kind"] = "hotkey"),
                    ; триггер-сокращение (dp → docker ps) и можно ли менять клавишу.
                    "trigger",   it.Has("trigger") ? it["trigger"] : "",
                    "rebindable", it["kind"] = "hotkey"
                ))
            }
        }

        ; 2) Пункты меню (плоско) — запускаемые, без галочки.
        for src in Commands.MenuSources() {
            flat := MenuData.Flatten(src["data"].Call(), src["label"])
            i := 0
            for entry in flat {
                i++
                id := "menu." . src["group"] . "." . i
                items.Push(Map(
                    "id",        id,
                    "label",     entry["label"],
                    "key",       "",
                    "enabled",   true,
                    "groupOn",   true,
                    "kind",      "menuitem",
                    "group",     src["label"],
                    "scope",     "command",
                    "toggleable", false,
                    "trigger",   "",
                    "rebindable", false
                ))
            }
        }

        ; 3) Аббревиатуры (scope=abbr) — вкладка «Абревиатуры».
        for ab in Abbreviations.Snapshot() {
            items.Push(Map(
                "id",        "abbr." . ab["abbr"],
                "label",     ab["abbr"] . " → " . ab["text"],
                "key",       "",
                "enabled",   ab["enabled"],
                "groupOn",   true,
                "kind",      "abbr",
                "group",     "Аббревиатуры",
                "scope",     "abbr",
                "toggleable", true,
                "trigger",   "",
                "rebindable", false,
                "abbr",      ab["abbr"],
                "text",      ab["text"]
            ))
        }

        ; Клавиша вызова самого лаунчера — для подсказки в подвале окна.
        launcherKey := ""
        if FeatureRegistry.items.Has("global.launcher")
            launcherKey := HotkeyToHuman(FeatureRegistry.items["global.launcher"]["key"])

        return Map("items", items, "launcherKey", launcherKey, "history", Commands.GetHistory())
    }

    ; ------------------------------------------------------------
    ; _ScopeOf — определить «область действия» команды для тега в UI:
    ;   "selection" — работает с выделенным текстом (Выделенное)
    ;   "command"   — обычная команда (Команда)
    ;   "abbr"      — аббревиатура (заполняется в фазе 3)
    ; text.* (UPPER/lower/транслит/число/вставка) — над выделением.
    static _ScopeOf(id, default) {
        if (SubStr(id, 1, 5) = "text.")
            return "selection"
        return default
    }

    ; ------------------------------------------------------------
    ; _BuildMenuFns — построить карту id→fn для всех пунктов меню.
    ; Вызывается при каждом Snapshot (данные меню могут меняться, напр. systemctl).
    static _BuildMenuFns() {
        Commands.menuFns := Map()
        for src in Commands.MenuSources() {
            flat := MenuData.Flatten(src["data"].Call(), src["label"])
            i := 0
            for entry in flat {
                i++
                id := "menu." . src["group"] . "." . i
                Commands.menuFns[id] := entry["fn"]
            }
        }
    }

    ; ------------------------------------------------------------
    ; Run — выполнить команду по id (хоткей/фича/пункт меню/аббревиатура).
    static Run(id) {
        ; Пункт меню?
        if (SubStr(id, 1, 5) = "menu.") {
            if !Commands.menuFns.Has(id)
                Commands._BuildMenuFns()
            if Commands.menuFns.Has(id) {
                fn := Commands.menuFns[id]
                try fn.Call()
            }
            return true
        }
        ; Аббревиатура — вставить её текст в активное окно.
        if (SubStr(id, 1, 5) = "abbr.") {
            abbr := SubStr(id, 6)
            rec := Abbreviations.Find(abbr)
            if rec
                try Send2(rec["text"])
            return true
        }
        ; Хоткей из реестра — вызвать его fn напрямую.
        if FeatureRegistry.items.Has(id) {
            item := FeatureRegistry.items[id]
            if (item["kind"] = "hotkey" && item["fn"]) {
                try item["fn"].Call()
            }
            return true
        }
        return false
    }

    ; ------------------------------------------------------------
    ; SetEnabled — вкл/выкл по id (хоткей/фича через FeatureRegistry,
    ; аббревиатура через Abbreviations).
    static SetEnabled(id, on) {
        if (SubStr(id, 1, 5) = "abbr.")
            return Abbreviations.SetEnabled(SubStr(id, 6), on)
        return FeatureRegistry.SetEnabled(id, on)
    }

    ; ------------------------------------------------------------
    ; История ввода лаунчера (фаза 5). Хранится в data/launcher_history.json.
    static historyPath := ""
    static _HistoryPath() {
        if (Commands.historyPath = "")
            Commands.historyPath := A_LineFile . "\..\..\data\launcher_history.json"
        return Commands.historyPath
    }
    static GetHistory() {
        path := Commands._HistoryPath()
        if !FileExist(path)
            return []
        try {
            arr := JSON.parse(FileRead(path, "UTF-8"))
            return arr
        }
        return []
    }
    ; AddHistory — добавить запрос в начало, убрать дубли, ограничить 30.
    static AddHistory(q) {
        q := Trim(q)
        if (q = "")
            return Commands.GetHistory()
        hist := Commands.GetHistory()
        out := [q]
        for h in hist {
            if (StrLower(h) != StrLower(q) && out.Length < 30)
                out.Push(h)
        }
        f := FileOpen(Commands._HistoryPath(), "w", "UTF-8")
        f.Write(JSON.stringify(out, 2))
        f.Close()
        return out
    }

    ; ------------------------------------------------------------
    ; Переназначение клавиши / триггера-сокращения (фаза 4).
    static SetHotkey(id, comboAhk) {
        return FeatureRegistry.SetKey(id, comboAhk)
    }
    static SetTrigger(id, trigger) {
        return FeatureRegistry.SetTrigger(id, trigger)
    }

    ; ------------------------------------------------------------
    ; Аббревиатуры: прокси для лаунчера (вкладка «Абревиатуры»).
    static AbbrAdd(abbr, text, opts := "*") {
        return Abbreviations.Add(abbr, text, opts)
    }
    static AbbrEdit(abbr, text) {
        return Abbreviations.Edit(abbr, text)
    }
    static AbbrDelete(abbr) {
        return Abbreviations.Delete(abbr)
    }
}
