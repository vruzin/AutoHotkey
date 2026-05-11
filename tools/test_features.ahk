; ============================================================
; tools/test_features.ahk — юнит-тесты для features/* без GUI.
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, OutputDebug

#Include ..\features\Case.ahk
#Include ..\features\Translit.ahk
#Include ..\features\Number2Text.ahk

logPath := A_ScriptDir . "\test_features.log"
try FileDelete(logPath)
Out(line) {
    global logPath
    FileAppend(line . "`n", logPath, "UTF-8")
}

passed := 0
failed := 0

Assert(name, got, want) {
    global passed, failed
    ok := (got = want)
    if ok
        passed++
    else
        failed++
    Out(Format("[{:5}]  {} : got='{}' want='{}'", ok ? "OK" : "FAIL", name, got, want))
}

Out("=== Case ===")
Assert("Upper",       PuntoCase.UpperText("Hello, Мир"),    "HELLO, МИР")
Assert("Lower",       PuntoCase.LowerText("Hello, МИР"),    "hello, мир")
Assert("Title",       PuntoCase.TitleText("hello world"),   "Hello World")
Assert("Title-RU",    PuntoCase.TitleText("привет мир"),    "Привет Мир")
Assert("Toggle",      PuntoCase.ToggleText("Hello"),        "hELLO")
Assert("Sentence-1",  PuntoCase.SentenceText("hello. world."),       "Hello. World.")
Assert("Sentence-RU", PuntoCase.SentenceText("привет. мир."),         "Привет. Мир.")
Assert("Sentence-abbrev",
    PuntoCase.SentenceText("это и т.д. конец."),     "Это и т.д. конец.")
Assert("Sentence-newline",
    PuntoCase.SentenceText("первая.`nвторая."),      "Первая.`nВторая.")

Out("")
Out("=== Translit ===")
PuntoTranslit.SetSystem("gost")
Assert("Translit GOST",   PuntoTranslit.Forward("Привет"),  "Privet")
PuntoTranslit.SetSystem("mvd")
Assert("Translit MVD-1",  PuntoTranslit.Forward("Привет"),  "Privet")
Assert("Translit MVD-2",  PuntoTranslit.Forward("Шамиль"),  "Shamil")
PuntoTranslit.SetSystem("simple")
Assert("Translit Simple", PuntoTranslit.Forward("Привет"),  "Privet")
Assert("Translit Yu",     PuntoTranslit.Forward("юг"),      "yug")
Assert("Translit Ya",     PuntoTranslit.Forward("яблоко"),  "yabloko")
Assert("Translit Zh",     PuntoTranslit.Forward("жук"),     "zhuk")
Assert("Translit back-1", PuntoTranslit.Backward("Privet"), "Привет")
Assert("Translit back-2", PuntoTranslit.Backward("Hello"),  "Хелло")

Out("")
Out("=== Number2Text ===")
Assert("N 0",       PuntoNumber.ToText(0),         "ноль")
Assert("N 1",       PuntoNumber.ToText(1),         "один")
Assert("N 21",      PuntoNumber.ToText(21),        "двадцать один")
Assert("N 100",     PuntoNumber.ToText(100),       "сто")
Assert("N 234",     PuntoNumber.ToText(234),       "двести тридцать четыре")
Assert("N 1000",    PuntoNumber.ToText(1000),      "одна тысяча")
Assert("N 1001",    PuntoNumber.ToText(1001),      "одна тысяча один")
Assert("N 2000",    PuntoNumber.ToText(2000),      "две тысячи")
Assert("N 5000",    PuntoNumber.ToText(5000),      "пять тысяч")
Assert("N 1000000", PuntoNumber.ToText(1000000),   "один миллион")
Assert("N 2000000", PuntoNumber.ToText(2000000),   "два миллиона")
Assert("N -5",      PuntoNumber.ToText(-5),        "минус пять")
Assert("N 1234567", PuntoNumber.ToText(1234567),
    "один миллион двести тридцать четыре тысячи пятьсот шестьдесят семь")
Assert("Ruble 1",   PuntoNumber.RubleForm(1),       "рубль")
Assert("Ruble 2",   PuntoNumber.RubleForm(2),       "рубля")
Assert("Ruble 5",   PuntoNumber.RubleForm(5),       "рублей")
Assert("Ruble 11",  PuntoNumber.RubleForm(11),      "рублей")
Assert("Ruble 21",  PuntoNumber.RubleForm(21),      "рубль")

Out("")
Out("PASSED: " . passed)
Out("FAILED: " . failed)
ExitApp (failed = 0) ? 0 : 1
