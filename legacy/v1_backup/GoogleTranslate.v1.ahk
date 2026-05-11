;MsgBox, % GoogleTranslate("Hello, World!")



CapsLock & t::
if GetKeyState("Shift") {
    GoogleTranslateSelected("ru", "en")
}else{
    GoogleTranslateSelected("auto", "ru")
}
return


GoogleTranslateSelected(from := "", to := ""){
    text:=getSelText()
    old:=text
    if (text="")
        text := Clipboard
    text := GoogleTranslate(text, "en", "ru")
    Clipboard:=text
    if (old!="")
        Send, ^v
    text:= from "->" to ":`n=================`n" old "`n=================`n" text
    ;text:= text
    ToolTip, %text%
    SetTimer, RemoveToolTip, -5000
}

RemoveToolTip:
ToolTip
return

; ; Возвращает выделенный текст
; getSelText()
; {
;     ClipboardOld:=ClipboardAll
;     Clipboard:=""
;     SendInput, ^{c}
;     ClipWait, 0.1
;     if(!ErrorLevel)
;     {
;         selText:=Clipboard
;         Clipboard:=ClipboardOld
;         StringRight, lastChar, selText, 1
;         if(Asc(lastChar)!=10) ;if last char is not line feed
;         {
;             return selText
;         }
;     }
;     Clipboard:=ClipboardOld
;     return
; }



; Send2(sText) {
;     ClipBackup:= ClipboardAll
;     Clipboard := sText
;     ClipWait
;     Send ^v
;     Clipboard := ClipBackup
;     ClipWait
; } ; eofun

GoogleTranslate(str, from := "", to := "")  {
   if (from = "")
      from := RegExMatch(str, "[а-яёА-ЯЁ]") ? "ru" : "auto"
   if (to = "")
      to := from = "ru" ? "en" : "ru"
   
   json := SendRequest(str, to, from, proxy:="")
   JS := new ActiveScript("JScript")
   JS.eval("delete ActiveXObject; delete GetObject;")
   oJSON := JS.eval("(" . JSON . ")")

   if !IsObject(oJSON[1])
      Loop % oJSON[0].length
         trans .= oJSON[0][A_Index - 1][0]
   else  {
      MainTransText := oJSON[0][0][0]
      Loop % oJSON[1].length  {
         trans .= "`n+"
         obj := oJSON[1][A_Index-1][1]
         Loop % obj.length  {
            txt := obj[A_Index - 1]
            trans .= (MainTransText = txt ? "" : "`n" txt)
         }
      }
   }
   if !IsObject(oJSON[1])
      MainTransText := trans := Trim(trans, ",+`n ")
   else
      trans := MainTransText . "`n+`n" . Trim(trans, ",+`n ")

   from := oJSON[2]
   trans := Trim(trans, ",+`n ")
   Return trans
}

SendRequest(str, tl, sl, proxy) {
   ComObjError(false)
   http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
   ( proxy && http.SetProxy(2, proxy) )
   http.open( "POST", "https://translate.google.com/translate_a/single?client=webapp&sl="
      . sl . "&tl=" . tl . "&hl=" . tl
      . "&dt=at&dt=bd&dt=ex&dt=ld&dt=md&dt=qca&dt=rw&dt=rm&dt=ss&dt=t&ie=UTF-8&oe=UTF-8&otf=0&ssel=0&tsel=0&pc=1&kc=1"
      . "&tk=" . TK(str), 1 )

   http.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded;charset=utf-8")
   http.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0")
   http.send("q=" . URIEncode(str))
   http.WaitForResponse(-1)
   Return http.responsetext
}

TK(string)  {
   js := new ActiveScript("JScript")
   js.Exec(GetJScript())
   Return js.tk(string)
}

URIEncode(str, encoding := "UTF-8")  {
   VarSetCapacity(var, StrPut(str, encoding))
   StrPut(str, &var, encoding)

   While code := NumGet(Var, A_Index - 1, "UChar")  {
      bool := (code > 0x7F || code < 0x30 || code = 0x3D)
      UrlStr .= bool ? "%" . Format("{:02X}", code) : Chr(code)
   }
   Return UrlStr
}

GetJScript()
{
   script =
   (
      var TKK = ((function() {
        var a = 561666268;
        var b = 1526272306;
        return 406398 + '.' + (a + b);
      })());

      function b(a, b) {
        for (var d = 0; d < b.length - 2; d += 3) {
            var c = b.charAt(d + 2),
                c = "a" <= c ? c.charCodeAt(0) - 87 : Number(c),
                c = "+" == b.charAt(d + 1) ? a >>> c : a << c;
            a = "+" == b.charAt(d) ? a + c & 4294967295 : a ^ c
        }
        return a
      }

      function tk(a) {
          for (var e = TKK.split("."), h = Number(e[0]) || 0, g = [], d = 0, f = 0; f < a.length; f++) {
              var c = a.charCodeAt(f);
              128 > c ? g[d++] = c : (2048 > c ? g[d++] = c >> 6 | 192 : (55296 == (c & 64512) && f + 1 < a.length && 56320 == (a.charCodeAt(f + 1) & 64512) ?
              (c = 65536 + ((c & 1023) << 10) + (a.charCodeAt(++f) & 1023), g[d++] = c >> 18 | 240,
              g[d++] = c >> 12 & 63 | 128) : g[d++] = c >> 12 | 224, g[d++] = c >> 6 & 63 | 128), g[d++] = c & 63 | 128)
          }
          a = h;
          for (d = 0; d < g.length; d++) a += g[d], a = b(a, "+-a^+6");
          a = b(a, "+-3^+b+-f");
          a ^= Number(e[1]) || 0;
          0 > a && (a = (a & 2147483647) + 2147483648);
          a `%= 1E6;
          return a.toString() + "." + (a ^ h)
      }
   )
   Return script
}

class ActiveScript extends ActiveScript._base
{
    __New(Language)
    {
        if this._script := ComObjCreate(Language, ActiveScript.IID)
            this._scriptParse := ComObjQuery(this._script, ActiveScript.IID_Parse)
        if !this._scriptParse
            throw Exception("Invalid language", -1, Language)
        this._site := new ActiveScriptSite(this)
        this._SetScriptSite(this._site.ptr)
        this._InitNew()
        this._objects := {}
        this.Error := ""
        this._dsp := this._GetScriptDispatch()  ; Must be done last.
        try
            if this.ScriptEngine() = "JScript"
                this.SetJScript58()
    }

    SetJScript58()
    {
        static IID_IActiveScriptProperty := "{4954E0D0-FBC7-11D1-8410-006008C3FBFC}"
        if !prop := ComObjQuery(this._script, IID_IActiveScriptProperty)
            return false
        VarSetCapacity(var, 24, 0), NumPut(2, NumPut(3, var, "short") + 6)
        hr := DllCall(NumGet(NumGet(prop+0)+4*A_PtrSize), "ptr", prop, "uint", 0x4000
            , "ptr", 0, "ptr", &var), ObjRelease(prop)
        return hr >= 0
    }

    Eval(Code)
    {
        pvar := NumGet(ComObjValue(arr:=ComObjArray(0xC,1)) + 8+A_PtrSize)
        this._ParseScriptText(Code, 0x20, pvar)  ; SCRIPTTEXT_ISEXPRESSION := 0x20
        return arr[0]
    }

    Exec(Code)
    {
        this._ParseScriptText(Code, 0x42, 0)  ; SCRIPTTEXT_ISVISIBLE := 2, SCRIPTTEXT_ISPERSISTENT := 0x40
        this._SetScriptState(2)  ; SCRIPTSTATE_CONNECTED := 2
    }

    AddObject(Name, DispObj, AddMembers := false)
    {
        static a, supports_dispatch ; Test for built-in IDispatch support.
            := a := ((a:=ComObjArray(0xC,1))[0]:=[42]) && a[0][1]=42
        if IsObject(DispObj) && !(supports_dispatch || ComObjType(DispObj))
            throw Exception("Adding a non-COM object requires AutoHotkey v1.1.17+", -1)
        this._objects[Name] := DispObj
        this._AddNamedItem(Name, AddMembers ? 8 : 2)  ; SCRIPTITEM_ISVISIBLE := 2, SCRIPTITEM_GLOBALMEMBERS := 8
    }

    _GetObjectUnk(Name)
    {
        return !IsObject(dsp := this._objects[Name]) ? dsp  ; Pointer
            : ComObjValue(dsp) ? ComObjValue(dsp)  ; ComObject
            : &dsp  ; AutoHotkey object
    }

    class _base
    {
        __Call(Method, Params*)
        {
            if ObjHasKey(this, "_dsp")
                try
                    return (this._dsp)[Method](Params*)
                catch e
                    throw Exception(e.Message, -1, e.Extra)
        }

        __Get(Property, Params*)
        {
            if ObjHasKey(this, "_dsp")
                try
                    return (this._dsp)[Property, Params*]
                catch e
                    throw Exception(e.Message, -1, e.Extra)
        }

        __Set(Property, Params*)
        {
            if ObjHasKey(this, "_dsp")
            {
                Value := Params.Pop()
                try
                    return (this._dsp)[Property, Params*] := Value
                catch e
                    throw Exception(e.Message, -1, e.Extra)
            }
        }
    }

    _SetScriptSite(Site)
    {
        hr := DllCall(NumGet(NumGet((p:=this._script)+0)+3*A_PtrSize), "ptr", p, "ptr", Site)
        if (hr < 0)
            this._HRFail(hr, "IActiveScript::SetScriptSite")
    }

    _SetScriptState(State)
    {
        hr := DllCall(NumGet(NumGet((p:=this._script)+0)+5*A_PtrSize), "ptr", p, "int", State)
        if (hr < 0)
            this._HRFail(hr, "IActiveScript::SetScriptState")
    }

    _AddNamedItem(Name, Flags)
    {
        hr := DllCall(NumGet(NumGet((p:=this._script)+0)+8*A_PtrSize), "ptr", p, "wstr", Name, "uint", Flags)
        if (hr < 0)
            this._HRFail(hr, "IActiveScript::AddNamedItem")
    }

    _GetScriptDispatch()
    {
        hr := DllCall(NumGet(NumGet((p:=this._script)+0)+10*A_PtrSize), "ptr", p, "ptr", 0, "ptr*", pdsp)
        if (hr < 0)
            this._HRFail(hr, "IActiveScript::GetScriptDispatch")
        return ComObject(9, pdsp, 1)
    }

    _InitNew()
    {
        hr := DllCall(NumGet(NumGet((p:=this._scriptParse)+0)+3*A_PtrSize), "ptr", p)
        if (hr < 0)
            this._HRFail(hr, "IActiveScriptParse::InitNew")
    }

    _ParseScriptText(Code, Flags, pvarResult)
    {
        VarSetCapacity(excp, 8 * A_PtrSize, 0)
        hr := DllCall(NumGet(NumGet((p:=this._scriptParse)+0)+5*A_PtrSize), "ptr", p
            , "wstr", Code, "ptr", 0, "ptr", 0, "ptr", 0, "uptr", 0, "uint", 1
            , "uint", Flags, "ptr", pvarResult, "ptr", 0)
        if (hr < 0)
            this._HRFail(hr, "IActiveScriptParse::ParseScriptText")
    }

    _HRFail(hr, what)
    {
        if e := this.Error
        {
            this.Error := ""
            throw Exception("`nError code:`t" this._HRFormat(e.HRESULT)
                . "`nSource:`t`t" e.Source "`nDescription:`t" e.Description
                . "`nLine:`t`t" e.Line "`nColumn:`t`t" e.Column
                . "`nLine text:`t`t" e.LineText, -3)
        }
        throw Exception(what " failed with code " this._HRFormat(hr), -2)
    }

    _HRFormat(hr)
    {
        return Format("0x{1:X}", hr & 0xFFFFFFFF)
    }

    _OnScriptError(err) ; IActiveScriptError err
    {
        VarSetCapacity(excp, 8 * A_PtrSize, 0)
        DllCall(NumGet(NumGet(err+0)+3*A_PtrSize), "ptr", err, "ptr", &excp) ; GetExceptionInfo
        DllCall(NumGet(NumGet(err+0)+4*A_PtrSize), "ptr", err, "uint*", srcctx, "uint*", srcline, "int*", srccol) ; GetSourcePosition
        DllCall(NumGet(NumGet(err+0)+5*A_PtrSize), "ptr", err, "ptr*", pbstrcode) ; GetSourceLineText
        code := StrGet(pbstrcode, "UTF-16"), DllCall("OleAut32\SysFreeString", "ptr", pbstrcode)
        if fn := NumGet(excp, 6 * A_PtrSize) ; pfnDeferredFillIn
            DllCall(fn, "ptr", &excp)
        wcode := NumGet(excp, 0, "ushort")
        hr := wcode ? 0x80040200 + wcode : NumGet(excp, 7 * A_PtrSize, "uint")
        this.Error := {HRESULT: hr, Line: srcline, Column: srccol, LineText: code}
        static Infos := "Source,Description,HelpFile"
        Loop Parse, % Infos, `,
            if pbstr := NumGet(excp, A_Index * A_PtrSize)
                this.Error[A_LoopField] := StrGet(pbstr, "UTF-16"), DllCall("OleAut32\SysFreeString", "ptr", pbstr)
        return 0x80004001 ; E_NOTIMPL (let Exec/Eval get a fail result)
    }

    __Delete()
    {
        if this._script
        {
            DllCall(NumGet(NumGet((p:=this._script)+0)+7*A_PtrSize), "ptr", p)  ; Close
            ObjRelease(this._script)
        }
        if this._scriptParse
            ObjRelease(this._scriptParse)
    }

    static IID := "{BB1A2AE1-A4F9-11cf-8F20-00805F2CD064}"
    static IID_Parse := A_PtrSize=8 ? "{C7EF7658-E1EE-480E-97EA-D52CB4D76D17}" : "{BB1A2AE2-A4F9-11cf-8F20-00805F2CD064}"
}

class ActiveScriptSite
{
    __New(Script)
    {
        ObjSetCapacity(this, "_site", 3 * A_PtrSize)
        NumPut(&Script
        , NumPut(ActiveScriptSite._vftable("_vft_w", "31122", 0x100)
        , NumPut(ActiveScriptSite._vftable("_vft", "31125232211", 0)
            , this.ptr := ObjGetAddress(this, "_site"))))
    }

    _vftable(Name, PrmCounts, EIBase)
    {
        if p := ObjGetAddress(this, Name)
            return p
        ObjSetCapacity(this, Name, StrLen(PrmCounts) * A_PtrSize)
        p := ObjGetAddress(this, Name)
        Loop Parse, % PrmCounts
        {
            cb := RegisterCallback("_ActiveScriptSite", "F", A_LoopField, A_Index + EIBase)
            NumPut(cb, p + (A_Index-1) * A_PtrSize)
        }
        return p
    }
}

_ActiveScriptSite(this, a1:=0, a2:=0, a3:=0, a4:=0, a5:=0)
{
    Method := A_EventInfo & 0xFF
    if A_EventInfo >= 0x100  ; IActiveScriptSiteWindow
    {
        if Method = 4  ; GetWindow
        {
            NumPut(0, a1+0) ; *phwnd := 0
            return 0 ; S_OK
        }
        if Method = 5  ; EnableModeless
        {
            return 0 ; S_OK
        }
        this -= A_PtrSize     ; Cast to IActiveScriptSite
    }
    ;else: IActiveScriptSite
    if Method = 1  ; QueryInterface
    {
        iid := _AS_GUIDToString(a1)
        if (iid = "{00000000-0000-0000-C000-000000000046}"  ; IUnknown
         || iid = "{DB01A1E3-A42B-11cf-8F20-00805F2CD064}") ; IActiveScriptSite
        {
            NumPut(this, a2+0)
            return 0 ; S_OK
        }
        if (iid = "{D10F6761-83E9-11cf-8F20-00805F2CD064}") ; IActiveScriptSiteWindow
        {
            NumPut(this + A_PtrSize, a2+0)
            return 0 ; S_OK
        }
        NumPut(0, a2+0)
        return 0x80004002 ; E_NOINTERFACE
    }
    if Method = 5  ; GetItemInfo
    {
        a1 := StrGet(a1, "UTF-16")
        , (a3 && NumPut(0, a3+0))  ; *ppiunkItem := NULL
        , (a4 && NumPut(0, a4+0))  ; *ppti := NULL
        if (a2 & 1) ; SCRIPTINFO_IUNKNOWN
        {
            if !(unk := Object(NumGet(this + A_PtrSize*2))._GetObjectUnk(a1))
                return 0x8002802B ; TYPE_E_ELEMENTNOTFOUND
            ObjAddRef(unk), NumPut(unk, a3+0)
        }
        return 0 ; S_OK
    }
    if Method = 9  ; OnScriptError
        return Object(NumGet(this + A_PtrSize*2))._OnScriptError(a1)

    ; AddRef and Release don't do anything because we want to avoid circular references.
    ; The site and IActiveScript are both released when the AHK script releases its last
    ; reference to the ActiveScript object.

    ; All of the other methods don't require implementations.
    return 0x80004001 ; E_NOTIMPL
}

_AS_GUIDToString(pGUID)
{
    VarSetCapacity(String, 38*2)
    DllCall("ole32\StringFromGUID2", "ptr", pGUID, "str", String, "int", 39)
    return String
}