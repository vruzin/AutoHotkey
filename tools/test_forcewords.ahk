; ============================================================
; tools/test_forcewords.ahk — юнит-тест PuntoForceWords
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

#Include ..\lib\JSON.ahk
#Include ..\core\Layout.ahk
#Include ..\core\Dictionaries.ahk
#Include ..\features\ForceWords.ahk

logPath := A_ScriptDir . "\test_forcewords.log"
try FileDelete(logPath)
Out(line) {
    global logPath
    FileAppend(line . "`n", logPath, "UTF-8")
}

PuntoDict.Init()
PuntoForceWords.Init()
Out("=== test_forcewords ===")
Out("force-words loaded: " . PuntoForceWords.All().Length)
Out("")

cases := [
    Map("input", "html",     "expected", "HTML"),
    Map("input", "HTML",     "expected", "HTML"),     ; уже правильно — ожидаем тоже HTML
    Map("input", "Html",     "expected", "HTML"),
    Map("input", "hTmL",     "expected", "HTML"),
    Map("input", "vue",      "expected", "Vue"),
    Map("input", "vuejs",    "expected", "VueJS"),
    Map("input", "golang",   "expected", "Golang"),
    Map("input", "PHP",      "expected", "PHP"),
    Map("input", "php",      "expected", "PHP"),
    Map("input", "javascript", "expected", "JavaScript"),
    Map("input", "github",   "expected", "GitHub"),
    ; Набрано в неправильной раскладке (RU когда хотел EN)
    Map("input", "реьд",     "expected", "HTML"),     ; html → реьд в EN→RU
    Map("input", "пше",      "expected", "Git"),      ; git → пше
    ; Не в списке — пустая строка
    Map("input", "hello",    "expected", ""),
    Map("input", "привет",   "expected", ""),
]

passed := 0
failed := 0

for tc in cases {
    inp := tc["input"]
    want := tc["expected"]
    got := PuntoForceWords.Find(inp)
    ok := (got = want)
    if ok
        passed++
    else
        failed++
    mark := ok ? "OK" : "FAIL"
    Out(Format("[{:5}]  '{}' → '{}' (expected '{}')", mark, inp, got, want))
}

Out("")
Out("PASSED: " . passed)
Out("FAILED: " . failed)
ExitApp (failed = 0) ? 0 : 1
