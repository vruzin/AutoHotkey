#SingleInstance, force
#NoEnv
; #NoTrayIcon
P := new Punto
corr := ObjBindMethod(P, "CorrectionEnteredText")
Hotkey % "Pause", % corr
; togg := ObjBindMethod(P, "ToggleLayout")
; Hotkey % "!" Format("vk{:02x}", GetKeyVK("R")), % corr
Return

Class Punto {
  __New() {
    ; Workaround for include mouse button in Input EndKeys
      _InputFn := ObjBindMethod(this, "_Input")
      _InputModFn := ObjBindMethod(this, "_Input", keyModifier := true)
      Hotkey ~*LButton, % _InputFn
      Hotkey ~*RButton, % _InputFn
      Hotkey ~*MButton, % _InputFn
    ; Workaround for run CorrectionEnteredText() from hotkey including modifier keys:
    ; you can't put LAlt in EndKeys if you run correction method by hotkey contain Alt (!R).
      Hotkey ~*LControl, % _InputModFn
      Hotkey ~*RControl, % _InputModFn
      Hotkey ~*LAlt, % _InputModFn
      Hotkey ~*RAlt, % _InputModFn
      Hotkey ~*LWin, % _InputModFn
      Hotkey ~*RWin, % _InputModFn
    timer := ObjBindMethod(this, "_GetInputText")
    SetTimer % timer, -1
  }
  _Input(keyModifier:=false) {
    If keyModifier ; Workaround because bug with using Hotkey ~*LAlt Up,
      KeyWait, % LTrim(A_ThisHotkey, "~*")
    Input
  }
  _GetInputText() {
    Input text, i v, {Enter}{NumpadEnter}{Tab}{Backspace}{Escape}{Space}{AppsKey}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{Capslock}{Numlock}{PrintScreen}{Pause}
    this.ReplaceAfter := this.ReplaceAfter ? this._ReplaceText(text) :
    timer := ObjBindMethod(this, "_GetInputText")
    SetTimer % timer, -1
  }

  CorrectionEnteredText() {
    this.ReplaceAfter:=true
    Input
  }

  _ReplaceText(text) {
    StringLen count, text
    if (count>0)  ; если вводился текст
      SendInput {BS %count%}
    else {        ; если выделен текст (при выделении используются кнопки мыши или шифт с навигационными кл. => text="" => count=0)
      cliptmp:=Clipboard
      Clipboard =
      SendPlay ^{Ins}
      Send ^{vk43}
      ClipWait .7, 1
      clipNew:=Clipboard
      if (clipNew != "") {
        text:=Clipboard
        fromClip:=true
      } else {
        Tooltip Выделите текст для исправления, A_CaretX+20, A_CaretY-3
        SetTimer TToff, -1000
        Return

        TToff:
          ToolTip
          Return
      }
      Clipboard:=cliptmp
    }

    substituteText := this._GetTextInOppositeLayout(text, fromClip, LayoutNeedToggle)
    (!fromClip || LayoutNeedToggle)  ?  this.ToggleLayout()
    Sleep 50 ; без задержки появляются баги со знаками пунктуации
    SetKeyDelay 50, 50
    SendInput {Raw}%substituteText%
    Return
  }
  _GetTextInOppositeLayout(text, fromClip, ByRef LayoutNeedToggle) {
    static Lat:="~QWERTYUIOP{}ASDFGHJKL:""ZXCVBNM<>``qwertyuiop[]asdfghjkl;'zxcvbnm,./|?@#$^&"
    , Cyr:="ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮёйцукенгшщзхъфывапролджэячсмитьбю./,""№;:?"

    En := (this.GetInputHKL() = 0x04090409)
    If fromClip {
      ; для выделенного текста определяем принадлежность большинства символов к той или иной раскладке
      u := 0
      Loop, parse, text
      {
        OutputDebug % (A_LoopField = "`n") " " (A_LoopField = "`r")
        LatSym := InStr(Lat, A_LoopField), CyrSym := InStr(Cyr, A_LoopField)
        if (LatSym && !CyrSym)
          ++u
        else if (CyrSym && !LatSym)
          --u
      }

      failureLayout:= (u>0) ? Lat : Cyr
      correctLayout := (u>0) ? Cyr : Lat
      LayoutNeedToggle := En ^ (u<=0)
    }
    Else {
      ; для простого переключения основываемся на тек. раскладке
      failureLayout:= En ? Lat : Cyr
      correctLayout := En ? Cyr : Lat
    }

    Loop, parse, text,, `r ; `r — hack for Send command, because it regards `r`n as separate \n
    {
      if (symbolNum := InStr(failureLayout, A_LoopField, CaseSensitive:=true))
        substituteText .= SubStr(correctLayout, symbolNum, 1)
      else
        substituteText .= A_LoopField
    }
    Return substituteText
  }
  ToggleLayout() {
    PostMessage, 0x50, 2,,, % (hWndOwn := DllCall("GetWindow", Ptr, hWnd:=WinActive("A"), UInt, GW_OWNER := 4, Ptr)) ? "ahk_id" hWndOwn : "ahk_id" hWnd
  }
  GetInputHKL() {
    hWnd := WinExist("A")
    WinGetClass, Class
    if (Class == "ConsoleWindowClass") {
        WinGet, consolePID, PID
        DllCall("AttachConsole", Ptr, consolePID)
        VarSetCapacity(buff, 16)
        DllCall("GetConsoleKeyboardLayoutName", Str, buff)
        DllCall("FreeConsole")
        HKL := "0x" . SubStr(buff, -3)
    } else
      HKL := DllCall("GetKeyboardLayout", Ptr, DllCall("GetWindowThreadProcessId", Ptr, hWnd, UInt, 0, Ptr), Ptr)
    return HKL
  }
}