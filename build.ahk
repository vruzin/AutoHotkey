CapsLock & b::
Menu, buildMenu, Add, npm run dev, npm1
Menu, buildMenu, Show
Menu, buildMenu, DeleteAll
return


npm1:
WinGetTitle, Title, A
StringLower, Title, Title
IfInString, Title, m:\.prg\!maryadi\study-tube.com\new2022-vue\
{
	Run, m:\Sys\cmber\Cmder.exe -run "{new2022-vue - DEV}"
}else{
	; MsgBox, Это НЕ new2022-vue "%Title%".
}

return