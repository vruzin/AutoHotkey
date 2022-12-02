CapsLock & f::
Menu, flMenu, Add, &1. Опыт, fl1
Menu, flMenu, Add, &2. Опыт Vue, fl2

Menu, flMenu, Show
Menu, flMenu, DeleteAll
SetNumLockState, Off
SetCapsLockState, Off
return

fl1:
Send3("Коммерческий опыт больше 20 лет. А программирую с 6 лет. Больше 2000 сайтов сделал.`n")
SetNumLockState, Off
SetCapsLockState, Off
return

fl2:
Send3("JS, Vue - отлично`nTS и Nuxt - на моем опыте не часто использовали, в основном для себя использовал... ибо удобно.`nPWA - для себя делал, коммерческие нет, по сути ничего особенного `nJWT и OAuth - без проблем, нюансы только в подходах на бек`nREST - никогда проблем не был`nGit, Github - много, GitLab - мало... на своём TrueNAS Scale сервере использую`nCI/CD - на GitLab не ставил, на GitHub - да. Плюс Docker.")
Send, {Enter}
SetNumLockState, Off
SetCapsLockState, Off
return

Send3(sText) {
    ClipBackup:= ClipboardAll
    Clipboard := sText
    ClipWait
    Sleep, 200 ;
    Send ^v
    Clipboard := ClipBackup
    ClipWait
} ; eofun