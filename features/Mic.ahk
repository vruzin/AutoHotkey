; ============================================================
; features/Mic.ahk — управление микрофоном (mute/unmute).
;
; Работает через Windows Core Audio API:
;   IMMDeviceEnumerator -> GetDefaultAudioEndpoint(eCapture)
;                       -> IMMDevice::Activate(IAudioEndpointVolume)
;                       -> SetMute / GetMute
;
; Управляет устройством записи ПО УМОЛЧАНИЮ — тем микрофоном, что выбран
; в настройках звука Windows. Внешних зависимостей не требует.
;
; Хоткей регистрируется в main.ahk: ^Volume_Mute -> Mic.Toggle().
; ============================================================

class Mic {
    ; GUID-ы Core Audio (как строки — конвертируются в бинарный IID на лету).
    static CLSID_MMDeviceEnumerator := "{BCDE0395-E52F-467C-8E3D-C4579291692E}"
    static IID_IMMDeviceEnumerator  := "{A95664D2-9614-4F35-A746-DE8DB63617E6}"
    static IID_IAudioEndpointVolume := "{5CDF2C82-841E-4546-9722-0CF74078229A}"

    ; Константы Core Audio.
    static EDATAFLOW_CAPTURE := 1     ; eCapture — устройства записи (микрофоны)
    static EROLE_CONSOLE     := 0     ; eConsole — основная роль устройства
    static CLSCTX_INPROC     := 1     ; CLSCTX_INPROC_SERVER

    ; ------------------------------------------------------------
    ; _GetVolumePtr — получить указатель на IAudioEndpointVolume
    ; для устройства записи по умолчанию.
    ; ВАЖНО: вызывающий обязан сделать ObjRelease(ptr) после использования.
    static _GetVolumePtr() {
        ; Создаём энумератор аудио-устройств и сразу запрашиваем нужный интерфейс.
        enumerator := ComObject(Mic.CLSID_MMDeviceEnumerator, Mic.IID_IMMDeviceEnumerator)

        ; GetDefaultAudioEndpoint(dataFlow, role, &ppDevice) — vtable index 4.
        ComCall(4, enumerator,
            "int", Mic.EDATAFLOW_CAPTURE,
            "int", Mic.EROLE_CONSOLE,
            "ptr*", &pDevice := 0)

        ; Бинарный IID интерфейса громкости для Activate().
        iid := Buffer(16)
        DllCall("ole32\CLSIDFromString", "wstr", Mic.IID_IAudioEndpointVolume, "ptr", iid)

        ; IMMDevice::Activate(refIID, clsCtx, pActivationParams, &ppInterface) — vtable index 3.
        ComCall(3, pDevice,
            "ptr", iid,
            "int", Mic.CLSCTX_INPROC,
            "ptr", 0,
            "ptr*", &pVolume := 0)

        ObjRelease(pDevice)     ; устройство больше не нужно — есть указатель на громкость
        return pVolume
    }

    ; ------------------------------------------------------------
    ; GetMute — вернуть 1, если микрофон выключен (mute), иначе 0.
    static GetMute() {
        pVolume := Mic._GetVolumePtr()
        ComCall(15, pVolume, "int*", &muted := 0)   ; GetMute(&pbMute) — vtable index 15
        ObjRelease(pVolume)
        return muted
    }

    ; ------------------------------------------------------------
    ; SetMute — выключить (state=true) или включить (state=false) микрофон.
    static SetMute(state) {
        pVolume := Mic._GetVolumePtr()
        ComCall(14, pVolume, "int", state ? 1 : 0, "ptr", 0)   ; SetMute(bMute, eventCtx) — vtable index 14
        ObjRelease(pVolume)
    }

    ; ------------------------------------------------------------
    ; Toggle — переключить состояние микрофона и показать индикацию.
    static Toggle() {
        nowMuted := !Mic.GetMute()
        Mic.SetMute(nowMuted)
        Mic.Notify(nowMuted)
    }

    ; ------------------------------------------------------------
    ; Notify — обратная связь о новом состоянии: ToolTip + звуковой сигнал.
    ; Звук важен, т.к. ToolTip легко не заметить во время разговора.
    static Notify(muted) {
        if (muted) {
            ToolTip("🎤 Микрофон ВЫКЛ")
            SoundBeep(400, 120)          ; низкий тон — выключили
        } else {
            ToolTip("🎤 Микрофон ВКЛ")
            SoundBeep(900, 120)          ; высокий тон — включили
        }
        SetTimer(() => ToolTip(), -1200)
    }
}
