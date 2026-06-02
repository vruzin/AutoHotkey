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
                    "id",      it["id"],
                    "label",   it["label"],
                    "key",     it["key"] != "" ? HotkeyToHuman(it["key"]) : "",
                    "enabled", it["enabled"],
                    "groupOn", g["enabled"],
                    "kind",    it["kind"],
                    "group",   g["label"]
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
                    "id",      id,
                    "label",   entry["label"],
                    "key",     "",
                    "enabled", true,
                    "groupOn", true,
                    "kind",    "menuitem",
                    "group",   src["label"]
                ))
            }
        }

        ; Клавиша вызова самого лаунчера — для подсказки в подвале окна.
        launcherKey := ""
        if FeatureRegistry.items.Has("global.launcher")
            launcherKey := HotkeyToHuman(FeatureRegistry.items["global.launcher"]["key"])

        return Map("items", items, "launcherKey", launcherKey)
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
    ; Run — выполнить команду по id (хоткей/фича/пункт меню).
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
    ; SetEnabled / SetGroupEnabled — прокси к FeatureRegistry (режим настроек).
    static SetEnabled(id, on) {
        return FeatureRegistry.SetEnabled(id, on)
    }
}
