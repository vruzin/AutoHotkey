; ============================================================
; tools/test_detect.ahk — юнит-тест детектора ошибочной раскладки.
; Запуск:  AutoHotkey64.exe tools/test_detect.ahk
; Лог:     tools/test_detect.log
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

#Include ..\core\Layout.ahk
#Include ..\core\Dictionaries.ahk

logPath := A_ScriptDir . "\test_detect.log"
try FileDelete(logPath)

Out(line) {
    global logPath
    FileAppend(line . "`n", logPath, "UTF-8")
}

PuntoDict.Init()
Out("=== test_detect ===")
Out("ru-loaded: " . PuntoDict.LoadStats["ru"])
Out("en-loaded: " . PuntoDict.LoadStats["en"])
Out("load-ms:   " . PuntoDict.LoadStats["ms"])
Out("")

; Тест-кейсы: { word, expectedWrong, expectedSuggestion (если wrong) }
cases := [
    Map("word", "ghbdtn",       "wrong", true,  "sugg", "привет"),
    Map("word", "привет",       "wrong", false, "sugg", ""),
    Map("word", "hello",        "wrong", false, "sugg", ""),
    Map("word", "руддщ",        "wrong", true,  "sugg", "hello"),
    Map("word", "ghbdfghbdtnf", "wrong", false, "sugg", ""),
    Map("word", "world",        "wrong", false, "sugg", ""),
    Map("word", "цщкдв",        "wrong", true,  "sugg", "world"),
    Map("word", "asdfg",        "wrong", false, "sugg", ""),
    Map("word", "пше",          "wrong", true,  "sugg", "git"),
    Map("word", "git",          "wrong", false, "sugg", ""),
    Map("word", "VueJS",        "wrong", false, "sugg", ""),
    Map("word", "ьыл",          "wrong", false, "sugg", ""),       ; msl — не слово в en
    Map("word", "ab",           "wrong", false, "sugg", ""),
    Map("word", "a",            "wrong", false, "sugg", ""),
    ; Регистр кириллицы — частая ловушка (Map.CaseSense на не-ru локали)
    Map("word", "При",          "wrong", false, "sugg", ""),
    Map("word", "ПРИВЕТ",       "wrong", false, "sugg", ""),
    Map("word", "Привет",       "wrong", false, "sugg", ""),
    Map("word", "ГдЕ",          "wrong", false, "sugg", ""),
    ; Слова, набранные в EN-раскладке с использованием [ ] ; '
    ; (которые в RU-раскладке = х ъ ж э).
    Map("word", "cby[hjafpfnhjy", "wrong", false, "sugg", ""),  ; синхрофазатрон — нет в топ-50к
    Map("word", "vfh[",          "wrong", false, "sugg", ""),   ; марх — мусор
]

passed := 0
failed := 0

for tc in cases {
    word    := tc["word"]
    expW    := tc["wrong"]
    expSugg := tc["sugg"]
    res     := PuntoDict.LooksLikeWrongLayout(word, "auto")

    got := res.Has("wrong") && res["wrong"]
    sugg := res.Has("suggestion") ? res["suggestion"] : ""
    reason := res.Has("reason") ? res["reason"] : ""

    ; «expected wrong но мы не уверены в suggestion» — мягкая проверка
    ok := (got = expW)
    if (got && expSugg != "" && sugg != expSugg)
        ok := false

    mark := ok ? "OK" : "FAIL"
    if ok
        passed++
    else
        failed++

    Out(Format("[{:5}]  word={:15}  → wrong={}  sugg={:10}  reason={}",
        mark, "'" word "'", got ? "Y" : "N", "'" sugg "'", reason))
}

Out("")
Out("PASSED: " . passed)
Out("FAILED: " . failed)
ExitApp (failed = 0) ? 0 : 1
