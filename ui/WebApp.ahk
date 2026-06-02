; ============================================================
; ui/WebApp.ahk — переиспользуемый фреймворк для Vue-приложений в WebView2.
;
; Идея: Vue/HTML/CSS/JS живут в отдельных файлах (ui/apps/<имя>/), а AHK
; только запускает окно и обслуживает мост. Приложений может быть несколько —
; поэтому WebApp это ЭКЗЕМПЛЯРЫ (не статика): у каждого своё окно, свои
; обработчики и состояние.
;
; Возможности моста:
;   • Vue → AHK с возвратом:  ahk.call(action, payload)  (JS) →
;     обработчик, зарегистрированный через On(action, fn) (AHK), → результат.
;   • AHK → Vue (push):       app.Push(channel, data)  → window 'message'.
;   • Начальные данные:       Show(initData) → Vue зовёт ahk.getInitData().
;
; Зависит от: lib/Webview2/WebView2.ahk (тянет ComVar.ahk + Promise.ahk),
;             lib/WebView2Loader.dll, lib/JSON.ahk.
;
; Добавить новое приложение: создать папку ui/apps/<new>/{index.html,app.js,
; style.css}, затем  app := WebApp("<new>"),  app.On(...),  app.Show(data).
; ============================================================

class WebApp {
    name      := ""
    gui       := 0
    wvc       := 0          ; WebView2 controller
    wv        := 0          ; CoreWebView2
    handlers  := 0          ; Map(action → fn)
    initJson  := ""         ; начальные данные (уже JSON-строка)
    opts      := 0
    _w        := 780        ; запомненные размеры окна для центрирования
    _h        := 640
    _blurTimer := 0         ; таймер проверки потери фокуса (hideOnBlur)
    _blurGraceUntil := 0    ; A_TickCount, до которого окно не прячется по blur

    ; ------------------------------------------------------------
    ; __New(name, opts) — name = папка приложения в ui/apps/.
    ; opts (Map, опц.): w, h, title, resizable (1/0).
    __New(name, opts := 0) {
        this.name     := name
        this.opts     := IsObject(opts) ? opts : Map()
        this.handlers := Map()
    }

    ; ------------------------------------------------------------
    ; On(action, fn) — зарегистрировать AHK-обработчик вызова из Vue.
    ; fn принимает распарсенный payload (Map/Array), возвращает значение
    ; (будет сериализовано в JSON и отдано в Vue).
    On(action, fn) {
        this.handlers[action] := fn
        return this
    }

    ; ------------------------------------------------------------
    ; Show(initData) — показать окно (создать при первом вызове).
    ; initData — объект (Map/Array) или готовая JSON-строка.
    Show(initData := "") {
        this.initJson := IsObject(initData) ? JSON.stringify(initData)
            : (initData != "" ? initData : "null")

        if this.gui {
            this._ShowCentered()
            try this.wvc.Fill()
            try WinActivate("ahk_id " . this.gui.Hwnd)
            this._ArmBlur()
            ; окно уже создано — обновим начальные данные на стороне Vue
            this.Push("init", this.initJson)
            return
        }
        this._Create()
    }

    ; ------------------------------------------------------------
    ; Push(channel, data) — отправить данные в Vue в любой момент.
    ; В JS придёт объект { channel, data } в событии 'message'.
    Push(channel, data) {
        if !this.wv
            return
        dataJson := IsObject(data) ? JSON.stringify(data) : data
        ; channel в кавычках, data — как есть (это валидный JSON-фрагмент)
        msg := '{"channel":"' . channel . '","data":' . dataJson . '}'
        try this.wv.PostWebMessageAsJson(msg)
    }

    ; ------------------------------------------------------------
    Hide() {
        if this._blurTimer {
            SetTimer(this._blurTimer, 0)      ; остановить проверку фокуса
            this._blurTimer := 0
        }
        if this.gui
            this.gui.Hide()
    }

    ; Перезапустить таймер потери фокуса при повторном показе.
    ; _blurGraceUntil — окно не прячется первые ~700мс после показа (чтобы не
    ; закрылось до того, как Windows отдаст ему фокус: при программном/трейном
    ; открытии активация приходит с задержкой).
    _ArmBlur() {
        if (this.opts.Has("hideOnBlur") && this.opts["hideOnBlur"]) {
            this._blurGraceUntil := A_TickCount + 700
            if (!this._blurTimer) {
                this._blurTimer := ObjBindMethod(this, "_CheckBlur")
                SetTimer(this._blurTimer, 250)
            }
        }
    }

    ; Проверка: активно ли наше окно (или дочернее окно WebView2).
    ; Если фокус ушёл в чужое окно — прячемся.
    _CheckBlur() {
        if !this.gui
            return
        if (A_TickCount < this._blurGraceUntil)   ; grace-период после показа
            return
        fg := DllCall("GetForegroundWindow", "ptr")
        if (fg = this.gui.Hwnd)
            return
        ; Проверим, не является ли активное окно потомком нашего Gui
        ; (WebView2 создаёт дочерние окна — фокус может быть на них).
        root := DllCall("GetAncestor", "ptr", fg, "uint", 2, "ptr")  ; GA_ROOT
        if (root = this.gui.Hwnd)
            return
        this.Hide()
    }

    ; ============================================================
    ; ВНУТРЕННЕЕ
    ; ============================================================

    _Create() {
        w     := this.opts.Has("w")     ? this.opts["w"]     : 780
        h     := this.opts.Has("h")     ? this.opts["h"]     : 640
        title := this.opts.Has("title") ? this.opts["title"] : this.name

        ; frameless — безрамочное окно (без шапки), как у Alfred-лаунчера.
        frameless := this.opts.Has("frameless") && this.opts["frameless"]
        if (frameless)
            guiOpts := "-Caption +Border +AlwaysOnTop"
        else
            guiOpts := this.opts.Has("resizable") && !this.opts["resizable"] ? "" : "+Resize"

        this.gui := Gui(guiOpts, title)
        this.gui.MarginX := this.gui.MarginY := 0
        this.gui.BackColor := "1E1E1E"
        this.gui.OnEvent("Close", (*) => this.Hide())
        this.gui.OnEvent("Size",  (g, mm, gw, gh) => this._OnSize(mm))
        this._w := w, this._h := h
        this._ShowCentered()
        try WinActivate("ahk_id " . this.gui.Hwnd)

        ; Все пути считаем от КОРНЯ ПРОЕКТА, а не A_ScriptDir: иначе при запуске
        ; вспомогательного скрипта из tools\ пути ломаются. Корень = папка над ui\.
        root := WebApp._Root()

        ; WebView2: путь к loader указываем явно (он в lib\, а не в lib\Webview2\64bit\).
        loader  := root . "\lib\WebView2Loader.dll"
        dataDir := root . "\data\webview2"
        this.wvc := WebView2.CreateControllerAsync(this.gui.Hwnd, 0, dataDir, "", loader).await2()
        this.wv  := this.wvc.CoreWebView2

        ; Мост Vue → AHK: host-объект "ahk" с методами dispatch/getInitData.
        host := {
            dispatch:    ObjBindMethod(this, "_Dispatch"),
            getInitData: ObjBindMethod(this, "_GetInitData")
        }
        this.wv.AddHostObjectToScript("ahk", host)

        ; Навигация на локальный index.html приложения.
        path := root . "\ui\apps\" . this.name . "\index.html"
        url  := "file:///" . StrReplace(path, "\", "/")
        this.wv.Navigate(url)

        ; Фокус полю поиска даёт сам Vue (searchInput.focus() в onMounted).

        ; hideOnBlur — после полного создания окна и навигации (не раньше:
        ; await2 выше качает очередь сообщений, преждевременный таймер мог бы
        ; спрятать ещё не активированное окно).
        this._ArmBlur()
    }

    ; Корень проекта = папка на уровень выше ui\ (где лежит этот файл).
    ; A_LineFile указывает на ui\WebApp.ahk независимо от запущенного скрипта.
    static _Root() {
        SplitPath(A_LineFile, , &uiDir)        ; uiDir = ...\ui
        SplitPath(uiDir, , &root)              ; root  = ...\ (корень проекта)
        return root
    }

    ; Показать окно по центру рабочей области основного монитора.
    _ShowCentered() {
        w := this.HasOwnProp("_w") ? this._w : 780
        h := this.HasOwnProp("_h") ? this._h : 640
        mLeft := 0, mTop := 0, mRight := A_ScreenWidth, mBottom := A_ScreenHeight
        try MonitorGetWorkArea(MonitorGetPrimary(), &mLeft, &mTop, &mRight, &mBottom)
        x := mLeft + ((mRight - mLeft) - w) // 2
        y := mTop  + ((mBottom - mTop)  - h) // 2
        this.gui.Show(Format("x{} y{} w{} h{}", x, y, w, h))
    }

    _OnSize(minMax) {
        if (minMax = -1)            ; свёрнуто — не трогаем
            return
        try this.wvc.Fill()
    }

    ; Мост: вызов из Vue. action — строка, argsJson — JSON-строка payload.
    ; Возврат — JSON-строка { ok, data } или { ok:false, error }.
    _Dispatch(action, argsJson := "") {
        if !this.handlers.Has(action)
            return '{"ok":false,"error":"unknown action: ' . action . '"}'
        try {
            payload := (argsJson != "" && argsJson != "undefined")
                ? JSON.parse(argsJson) : Map()
            result := this.handlers[action].Call(payload)
            return JSON.stringify(Map("ok", true, "data", result))
        } catch as e {
            return JSON.stringify(Map("ok", false, "error", e.Message))
        }
    }

    _GetInitData() {
        return this.initJson
    }
}
