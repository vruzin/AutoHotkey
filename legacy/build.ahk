; ============================================================
; build.ahk — AutoHotkey v2
; CapsLock+B: меню запуска dev-окружения для конкретных проектов.
; Проект определяется по пути в заголовке активного окна.
; ============================================================

CapsLock & b:: ShowBuildMenu()

ShowBuildMenu() {
    m := Menu()
    m.Add("npm run dev", BuildNpm1)
    m.Show()
}

BuildNpm1(*) {
    title := StrLower(WinGetTitle("A"))
    if InStr(title, "m:\.prg\!maryadi\study-tube.com\new2022-vue\")
        Run('m:\Sys\cmber\Cmder.exe -run "{new2022-vue - DEV}"')
    ; иначе — текущее окно не подходит, тихо игнорируем
}
