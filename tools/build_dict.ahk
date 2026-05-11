; ============================================================
; tools/build_dict.ahk — сборка словарей ru/en (AHK v2)
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

FileEncoding "UTF-8-RAW"

MIN_FREQ := 100

root := A_ScriptDir . "\.."
srcRu := root . "\lib\Hunspell\ru_50k.txt"
srcEn := root . "\lib\Hunspell\en_50k.txt"
dstRu := root . "\data\dict\ru.bin"
dstEn := root . "\data\dict\en.bin"
logPath := root . "\tools\build_dict.log"

silent := false
for arg in A_Args {
    if (arg = "--silent" || arg = "/silent")
        silent := true
}

result := ""
try {
    result .= BuildOne(srcRu, dstRu, "ru", MIN_FREQ) . "`n"
    result .= BuildOne(srcEn, dstEn, "en", MIN_FREQ) . "`n"
} catch as e {
    result .= "ОШИБКА: " . e.Message . "`nФайл: " . e.File . " строка " . e.Line . "`n" . e.Stack
}

FileAppend(result, logPath)
if !silent
    MsgBox(result, "build_dict — готово")
ExitApp

; ------------------------------------------------------------
BuildOne(src, dst, lang, minFreq) {
    if !FileExist(src)
        return "[" . lang . "] ОШИБКА: не найден " . src

    if (lang = "ru")
        validRe := "^[а-яё\-]+$"
    else
        validRe := "^[a-z\-']+$"

    totalIn := 0
    kept := 0

    out := FileOpen(dst, "w", "UTF-8-RAW")
    if !out
        return "[" . lang . "] ОШИБКА: не открыть на запись " . dst

    Loop Read, src
    {
        totalIn++
        line := Trim(A_LoopReadLine)
        if (line = "")
            continue

        parts := StrSplit(line, " ", , 2)
        if (parts.Length < 2)
            continue
        word := parts[1]
        freq := Integer(parts[2])

        if (freq < minFreq)
            continue
        if (StrLen(word) < 2)
            continue
        if !RegExMatch(word, validRe)
            continue

        out.WriteLine(word)
        kept++
    }
    out.Close()

    return "[" . lang . "] " . kept . " из " . totalIn . " слов сохранены в " . dst
}
