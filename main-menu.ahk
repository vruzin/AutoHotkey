Menu, Tray, Tip, % "Light/Dark Mode Switch (AHK)"
Menu, Tray, Icon, % "shell32.dll", 175


CapsLock & a::

Menu, main_menu, Add, &1. Тема Windows Light/Dark, mm1
Menu, main_menu, Show
Menu, main_menu, DeleteAll
return

mm1:
RegRead, CurrentTheme, % "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", % "AppsUseLightTheme" ; read current theme
; MsgBox, %CurrentTheme%
RegWrite, REG_DWORD, % "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", % "AppsUseLightTheme", % 1 - CurrentTheme ; toggle between themes
return
