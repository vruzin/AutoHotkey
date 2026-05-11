; ============================================================
; GoogleTranslate.ahk — AutoHotkey v2
;
; CapsLock+T        — открыть Google Translate с выделенным текстом (auto → ru)
; Shift+CapsLock+T  — то же, направление ru → en
;
; ПОЧЕМУ браузер, а не inline:
; Старая реализация (ActiveScript + computed TK-токен) использовала
; недокументированный приватный endpoint translate.google.com/translate_a/single.
; Google закрыл этот путь, инлайн-перевод перестал работать.
; В новом Punto-UI (этап 3) будет настоящий API: DeepL / Yandex / Google Cloud,
; с пользовательским ключом и опцией inline-вставки. До тех пор — открытие
; страницы перевода с предзаполненным текстом, что надёжно и не зависит от API.
;
; Оригинальный v1-код сохранён в legacy/v1_backup/GoogleTranslate.v1.ahk.
; ============================================================

CapsLock & t:: {
    if GetKeyState("Shift")
        OpenGoogleTranslate("ru", "en")
    else
        OpenGoogleTranslate("auto", "ru")
}

OpenGoogleTranslate(fromLang, toLang) {
    text := getSelText()
    if (text = "")
        text := A_Clipboard
    if (text = "") {
        ToolTip "Нечего переводить: ни выделения, ни буфера обмена"
        SetTimer () => ToolTip(), -2000
        return
    }

    ; URI-encode UTF-8: Google Translate сам нормализует, но кодировать обязательно
    encoded := UriEncodeUtf8(text)
    url := "https://translate.google.com/?sl=" . fromLang . "&tl=" . toLang
        . "&text=" . encoded . "&op=translate"
    Run(url)
}

; ----------------------------------------------------------
; URI-кодирование UTF-8 без зависимости от внешних либ.
UriEncodeUtf8(str) {
    static safe := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.~"
    ; Сначала переводим в байты UTF-8 (StrPut записывает в Buffer)
    bufSize := StrPut(str, "UTF-8")
    buf := Buffer(bufSize, 0)
    StrPut(str, buf, "UTF-8")

    out := ""
    Loop bufSize - 1 {
        code := NumGet(buf, A_Index - 1, "UChar")
        if (code = 0)
            break
        ch := Chr(code)
        if InStr(safe, ch, true)
            out .= ch
        else
            out .= "%" . Format("{:02X}", code)
    }
    return out
}
