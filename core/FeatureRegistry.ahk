; ============================================================
; core/FeatureRegistry.ahk — единый реестр управляемых фич и хоткеев.
;
; Зачем: чтобы окно настроек (ui/apps/settings) могло включать/выключать
; любой хоткей или фичу галочкой В РАНТАЙМЕ, без Reload.
;   • Хоткеи: реальное On/Off через Hotkey(key, fn, "On"/"Off") —
;     выключенная клавиша освобождается полностью.
;   • Фичи без клавиши (напр. ForceWords): флаг active, который сам модуль
;     проверяет через FeatureRegistry.IsActive(id).
;
; Все модули по-прежнему подключаются через #Include — реестр НЕ управляет
; загрузкой, только активностью. Простаивающий выключенный хоткей стоит 0.
;
; Контекстные #HotIf-хоткеи (Direct Commander, GraphCalc, IDEA) в реестр
; НЕ входят — их выключать смысла нет.
;
; Состояние хранится в data/settings.json → секция "features":
;   "features": {
;     "groups":  { "mic": {"enabled": true}, ... },
;     "hotkeys": { "mic.toggle": {"enabled": true}, ... }
;   }
;
; Зависит от: PuntoSettings (Get/Set).
; ============================================================

class FeatureRegistry {
    static items  := Map()     ; id → Map(id,group,label,key,fn,enabled,default,kind)
    static order  := []        ; порядок id для стабильного вывода
    static groups := Map()     ; group → Map(id,label,enabled)
    static gOrder := []        ; порядок групп

    ; Человекочитаемые названия групп (для UI).
    static GroupLabels := Map(
        "punto",   "Punto — автопереключение раскладки",
        "text",    "Текстовые операции (регистр, транслит, число)",
        "mic",     "Микрофон",
        "global",  "Глобальные хоткеи",
        "legacy",  "Меню (CapsLock+…)",
        "palette", "Командная палитра"
    )

    ; ------------------------------------------------------------
    ; EnsureGroup — создать группу, если ещё не зарегистрирована.
    static EnsureGroup(group) {
        if FeatureRegistry.groups.Has(group)
            return
        label := FeatureRegistry.GroupLabels.Has(group)
            ? FeatureRegistry.GroupLabels[group]
            : group
        grEnabled := FeatureRegistry._GetSavedGroup(group, true)
        FeatureRegistry.groups[group] := Map(
            "id", group, "label", label, "enabled", grEnabled
        )
        FeatureRegistry.gOrder.Push(group)
    }

    ; ------------------------------------------------------------
    ; Register — управляемый ХОТКЕЙ. Сразу применяет сохранённое состояние.
    ;   id      — уникальный ключ ("mic.toggle")
    ;   group   — группа ("mic")
    ;   label   — подпись для UI ("Переключить микрофон")
    ;   key     — клавиша в синтаксисе Hotkey() ("^Volume_Mute")
    ;   fn      — вызываемый объект, ДОЛЖЕН принимать параметры ((*) => ...)
    ;   default — состояние по умолчанию (true)
    static Register(id, group, label, key, fn, default := true) {
        FeatureRegistry.EnsureGroup(group)
        hkEnabled := FeatureRegistry._GetSavedHotkey(id, default)

        ; Оверрайд клавиши из settings (пользователь переназначил из лаунчера).
        ov := FeatureRegistry._GetOverride(id)
        effKey := (ov.Has("key") && ov["key"] != "") ? ov["key"] : key
        trigger := ov.Has("trigger") ? ov["trigger"] : ""

        item := Map(
            "id", id, "group", group, "label", label,
            "key", effKey, "defaultKey", key, "fn", fn, "kind", "hotkey",
            "enabled", hkEnabled, "default", default, "trigger", trigger
        )
        FeatureRegistry._Store(id, item)

        grOn := FeatureRegistry.groups[group]["enabled"]
        FeatureRegistry._Apply(item, hkEnabled && grOn)
    }

    ; ------------------------------------------------------------
    ; RegisterFeature — управляемая ФИЧА без клавиши. Активность модуль
    ; проверяет сам через IsActive(id). Применять нечего — только флаг.
    static RegisterFeature(id, group, label, default := true) {
        FeatureRegistry.EnsureGroup(group)
        enabled := FeatureRegistry._GetSavedHotkey(id, default)
        item := Map(
            "id", id, "group", group, "label", label,
            "key", "", "fn", 0, "kind", "feature",
            "enabled", enabled, "default", default
        )
        FeatureRegistry._Store(id, item)
    }

    ; ------------------------------------------------------------
    ; IsActive — эффективная активность (сама фича вкл И её группа вкл).
    ; Если id не зарегистрирован — считаем активным (обратная совместимость).
    static IsActive(id) {
        if !FeatureRegistry.items.Has(id)
            return true
        item := FeatureRegistry.items[id]
        grOn := FeatureRegistry.groups[item["group"]]["enabled"]
        return item["enabled"] && grOn
    }

    ; ------------------------------------------------------------
    ; SetEnabled — переключить отдельный элемент (из UI). Сохраняет в settings.
    static SetEnabled(id, on) {
        if !FeatureRegistry.items.Has(id)
            return false
        item := FeatureRegistry.items[id]
        item["enabled"] := !!on
        grOn := FeatureRegistry.groups[item["group"]]["enabled"]
        if (item["kind"] = "hotkey")
            FeatureRegistry._Apply(item, item["enabled"] && grOn)
        FeatureRegistry._SaveHotkey(id, item["enabled"])
        return true
    }

    ; ------------------------------------------------------------
    ; SetKey — переназначить клавишу хоткея (захват комбинации из лаунчера).
    ; newKey — в синтаксисе AHK ("^+!u"). Снимает старый Hotkey, ставит новый,
    ; сохраняет в features.overrides. Возвращает Map(ok, error?).
    static SetKey(id, newKey) {
        if !FeatureRegistry.items.Has(id)
            return Map("ok", false, "error", "нет такого хоткея")
        item := FeatureRegistry.items[id]
        if (item["kind"] != "hotkey")
            return Map("ok", false, "error", "это не хоткей")
        if (newKey = "")
            return Map("ok", false, "error", "пустая комбинация")

        ; Конфликт: та же клавиша у другого включённого хоткея.
        for otherId in FeatureRegistry.order {
            if (otherId = id)
                continue
            other := FeatureRegistry.items[otherId]
            if (other["kind"] = "hotkey" && other["key"] = newKey)
                return Map("ok", false, "error", "занято: " . other["label"])
        }

        ; Снять старую привязку.
        try Hotkey(item["key"], item["fn"], "Off")
        item["key"] := newKey
        grOn := FeatureRegistry.groups[item["group"]]["enabled"]
        FeatureRegistry._Apply(item, item["enabled"] && grOn)
        FeatureRegistry._SaveOverride(id, "key", newKey)
        return Map("ok", true)
    }

    ; ------------------------------------------------------------
    ; SetTrigger — задать «горячее сокращение» (dp → docker ps) для команды.
    ; Триггер срабатывает только в лаунчере (точное совпадение). "" — снять.
    static SetTrigger(id, trigger) {
        if !FeatureRegistry.items.Has(id)
            return Map("ok", false, "error", "нет такой команды")
        FeatureRegistry.items[id]["trigger"] := trigger
        FeatureRegistry._SaveOverride(id, "trigger", trigger)
        return Map("ok", true)
    }

    ; ------------------------------------------------------------
    ; SetGroupEnabled — переключить всю группу (каскад на дочерние).
    ; Индивидуальные флаги сохраняются — при включении группы восстановятся.
    static SetGroupEnabled(group, on) {
        if !FeatureRegistry.groups.Has(group)
            return false
        FeatureRegistry.groups[group]["enabled"] := !!on
        for id in FeatureRegistry.order {
            item := FeatureRegistry.items[id]
            if (item["group"] != group || item["kind"] != "hotkey")
                continue
            FeatureRegistry._Apply(item, item["enabled"] && on)
        }
        FeatureRegistry._SaveGroup(group, !!on)
        return true
    }

    ; ------------------------------------------------------------
    ; Snapshot — дерево групп→элементы для передачи в Vue.
    static Snapshot() {
        result := []
        for group in FeatureRegistry.gOrder {
            g := FeatureRegistry.groups[group]
            list := []
            for id in FeatureRegistry.order {
                item := FeatureRegistry.items[id]
                if (item["group"] != group)
                    continue
                list.Push(Map(
                    "id", item["id"],
                    "label", item["label"],
                    "key", item["key"],
                    "kind", item["kind"],
                    "enabled", item["enabled"],
                    "trigger", item.Has("trigger") ? item["trigger"] : ""
                ))
            }
            result.Push(Map(
                "id", g["id"],
                "label", g["label"],
                "enabled", g["enabled"],
                "items", list
            ))
        }
        return result
    }

    ; ------------------------------------------------------------
    ; Внутреннее.
    static _Store(id, item) {
        if !FeatureRegistry.items.Has(id)
            FeatureRegistry.order.Push(id)
        FeatureRegistry.items[id] := item
    }

    static _Apply(item, on) {
        try Hotkey(item["key"], item["fn"], on ? "On" : "Off")
    }

    ; ВАЖНО: id хоткеев содержат точки ("punto.forcewords"), а PuntoSettings.Get/Set
    ; трактуют точку как разделитель пути → кривая вложенность. Поэтому работаем
    ; с под-Map features.hotkeys/features.groups напрямую, а id/group кладём как
    ; ПЛОСКИЕ ключи внутри них.

    ; _Section — вернуть под-Map features.<which> (hotkeys|groups), создав при нужде.
    static _Section(which) {
        PuntoSettings.Init()
        d := PuntoSettings.data
        if !d.Has("features") || !IsObject(d["features"])
            d["features"] := Map("groups", Map(), "hotkeys", Map())
        f := d["features"]
        if !f.Has(which) || !IsObject(f[which])
            f[which] := Map()
        return f[which]
    }

    static _Read(section, key, default) {
        m := FeatureRegistry._Section(section)
        if !m.Has(key)
            return !!default
        rec := m[key]
        if IsObject(rec) && rec.Has("enabled")
            return !!rec["enabled"]
        return !!rec
    }

    static _GetSavedHotkey(id, default) {
        return FeatureRegistry._Read("hotkeys", id, default)
    }
    static _GetSavedGroup(group, default) {
        return FeatureRegistry._Read("groups", group, default)
    }
    static _SaveHotkey(id, on) {
        m := FeatureRegistry._Section("hotkeys")
        m[id] := Map("enabled", on ? 1 : 0)
        PuntoSettings.Save()
    }
    static _SaveGroup(group, on) {
        m := FeatureRegistry._Section("groups")
        m[group] := Map("enabled", on ? 1 : 0)
        PuntoSettings.Save()
    }

    ; --- Оверрайды (переназначенные клавиши и триггеры-сокращения). ---
    ; Хранятся в features.overrides[id] = Map(key?, trigger?). Плоские id-ключи.
    static _GetOverride(id) {
        m := FeatureRegistry._Section("overrides")
        if (m.Has(id) && IsObject(m[id]))
            return m[id]
        return Map()
    }
    static _SaveOverride(id, field, value) {
        m := FeatureRegistry._Section("overrides")
        if !(m.Has(id) && IsObject(m[id]))
            m[id] := Map()
        m[id][field] := value
        PuntoSettings.Save()
    }
}
