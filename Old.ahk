
; Определяем цвет пикселя под курсором и отправляем в буфер
#!c:: ; Win+Alt+C 
MouseGetPos, MouseX, MouseY ; определяем координаты мыши 
PixelGetColor, color, %MouseX%, %MouseY% ; 
color := RegExReplace(color, "0x([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})", "#$3$2$1")
clipboard=%color%
; MsgBox Цвет пикселя на позиции курсора - %color%. 
MouseX := MouseX - 50
MouseY := MouseY - 30
ToolTip, Цвет: %color% , %MouseX%, %MouseY%
SetTimer, RemoveToolTip, -2000
return

RemoveToolTip:
ToolTip
return


^MButton::^!+PrintScreen ; Ctrl+Средняя кнопка мыши = PrintScreen
