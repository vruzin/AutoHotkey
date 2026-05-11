; ============================================================
; kitty.ahk — AutoHotkey v2
; CapsLock+K  — запуск KiTTY с авто-навигацией по сохранённым сессиям.
; CapsLock+S  — иерархическое меню sysadmin-команд (systemctl, nginx, git, ssh, …).
;
; Динамическое меню systemctl строится из строки-схемы со спец-разделителями:
;   "|"  — пункты внутри сервиса
;   "^"  — между группами сервисов
;   ":"  — имя меню : шаблон команды
;   "&X" — назначает горячую букву для пункта
; ============================================================

; ----------------------------------------------------------
; CapsLock+K — запуск KiTTY и навигация: TABx5, Downx5 (выбор сохранённой сессии)
CapsLock & k:: {
    Run('m:\Sys\Kitty\kitty_portable.exe')
    WinWait("KiTTY Configuration")
    Sleep 300
    Send "{TAB 5}{Down 5}"
}

; ----------------------------------------------------------
; CapsLock+S — большое sysadmin-меню
CapsLock & s:: ShowSshMenu()

ShowSshMenu() {
    ; --- nginx ---
    nginxMenu := Menu()
    nginxMenu.Add("&1. nginx -t", (*) => SendCmd("nginx -t"))
    nginxMenu.Add("&2. nginx -s reload", (*) => SendCmd("nginx -s reload"))
    nginxMenu.Add("&3. nginx -v", (*) => SendCmd("nginx -v"))

    ; --- chmod / chown ---
    chmodMenu := Menu()
    chmodMenu.Add("&1. chown -R bitrix:bitrix /home/bitrix/ext_www/mvk-spb.ru/vruzin/`t(Владелец рекурсивно)",
        (*) => SendText("chown -R bitrix:bitrix /home/bitrix/ext_www/mvk-spb.ru/vruzin/"))
    chmodMenu.Add("&2. chmod -R 755 .`t(Права 755 рекурсивно)",
        (*) => (SendText("chmod -R 755 ."), Send("{Enter}")))

    ; --- systemctl (динамически) ---
    systemctlMenu := BuildSystemctlMenu()

    ; --- git ---
    gitMenu := Menu()
    gitMenu.Add("&1. git submodule update --init --merge --remote --recursive`t(Субмодули)",
        (*) => SendCmd("git submodule update --init --merge --remote --recursive"))
    gitMenu.Add("&2. git config --global user.name`t(Git Авторизация)", DoGitConfig)
    gitMenu.Add("&3. git config --list --show-origin`t(настройки и где заданы. Q-выход)",
        (*) => SendCmd("git config --list --show-origin"))
    gitMenu.Add("&4. git branch --sort=-committerdate`t(сортировка веток по дате)",
        (*) => SendCmd("git branch --sort=-committerdate"))

    ; --- powershell ---
    powershellMenu := Menu()
    powershellMenu.Add('&1. (dir */*.go | select-string "github.com" | Get-Unique)`t(подключаемые github-модули)',
        (*) => Send('(dir */*.go | select-string "github.com" | Get-Unique){Enter}'))

    ; --- MVK ---
    mvkMenu := Menu()
    mvkMenu.Add("&1. rm -rf`t(Удалить весь кеш)",
        (*) => Send("rm -rf /home/bitrix/ext_www/mvk-spb.ru/bitrix/managed_cache/MYSQL/* /home/bitrix/ext_www/mvk-spb.ru/bitrix/cache/*{Enter}"))

    ; --- ssh ---
    sshMenu := Menu()
    sshMenu.Add("&T. ТУННЕЛЬ`t(запустить в powershell)", Ssh0)
    sshMenu.Add("&1. ssh =>`t(копировать ключ на удалённый сервер)", Ssh4)
    sshMenu.Add("&2. ssh =>`t(копировать ключ в .ssh/authorized_keys)", Ssh7)
    sshMenu.Add("&3. ssh туннель =>`t(тунель через удалённый порт)", Ssh5)
    sshMenu.Add("&4. ssh скрипт =>`t(локальный скрипт на удалённом сервере)", Ssh6)
    sshMenu.Add("&5. ls -l`t(Список директории подробно)", (*) => (SendText("ls -l"), Send("{Enter}")))
    sshMenu.Add("&6. ls -al`t(Список директории подробно)", (*) => (SendText("ls -al"), Send("{Enter}")))
    sshMenu.Add("&7. ssh user@ip`t(Подключение ssh)", (*) => (SendText("ssh user@ip"), Send("{Enter}")))

    ; --- curl ---
    curlMenu := Menu()
    curlMenu.Add("&1. curl --resolve 'domain.ru:80:127.0.0.1' http://domain.ru/link`t(запрос по IP)",
        (*) => SendText("curl --resolve 'domain.ru:80:127.0.0.1' http://domain.ru/link"))

    ; --- backup ---
    backupMenu := Menu()
    backupMenu.Add("&1. mysqldump -u root -p dbname > db-YYYY-MM-DD.sql`t(Бэкап MySQL)", DoBackupSql)
    backupMenu.Add("&2. tar -cvf public_YYYY-MM-DD.tar.gz /var/www/vruzin/domen.ru`t(Архивация папки)", DoBackupTar)

    ; --- ISPmanager ---
    ispMenu := Menu()
    ispMenu.Add("&1. /usr/local/mgr5/sbin/mgrctl -m ispmgr exit`t(перегрузить ISP)",
        (*) => SendText("/usr/local/mgr5/sbin/mgrctl -m ispmgr exit"))

    ; --- сборка корневого меню ---
    root := Menu()
    root.Add("&1. nginx", nginxMenu)
    root.Add("&2. chown/chmod`t(Права и Владельцы)", chmodMenu)
    root.Add("&3. systemctl", systemctlMenu)
    root.Add("&4. git", gitMenu)
    root.Add("&5. PowerShell", powershellMenu)
    root.Add("&6. MVK", mvkMenu)
    root.Add("&7. ssh", sshMenu)
    root.Add("&8. curl", curlMenu)
    root.Add("&9. Бекап", backupMenu)
    root.Add("&a. ISPmanager 6", ispMenu)
    root.Add()  ; разделитель
    root.Add("&cd /var/www/www-root/data/", (*) => Send("cd /var/www/www-root/data/{Enter}ls -la{Enter}"))
    root.Add("&df`t(Сколько места занято)", (*) => Send("df{Enter}"))
    root.Add("c&at /proc/version`t(Версия системы)", (*) => Send("cat /proc/version{Enter}"))
    root.Add("ca&t /etc/*-release`t(Всё о системе)", (*) => Send("cat /etc/*-release{Enter}"))
    root.Add('n&ginx -T | grep "server_name "`t(Список доменов)',
        (*) => Send('nginx -T | grep "server_name "{Enter}'))
    root.Add("n&etstat -ano | findstr :9303`t(порт 9303)",
        (*) => Send("netstat -ano | findstr :9303{Enter}"))

    root.Show()
    SetNumLockState("Off")
    SetCapsLockState("Off")
}

; ----------------------------------------------------------
; Динамическое построение меню systemctl из строки-схемы
BuildSystemctlMenu() {
    cmds := "status|stop|start|enable|disable"
    services := "inqoob-&v:inqoob-v{TAB 2}^inqoob-v&6:inqoob-v6{TAB 2}|inqoob-v6-cm|inqoob-v6-constructor|inqoob-v6-tg^inqoob-v&7:inqoob-v7{TAB 2}|inqoob-v7-cm|inqoob-v7-constructor|inqoob-v7-tg"

    rootMenu := Menu()

    Loop Parse, cmds, "|" {
        cmdIdx := A_Index
        cmdText := A_LoopField
        cmdMenu := Menu()

        Loop Parse, services, "^" {
            groupIdx := A_Index
            group := A_LoopField
            name := RegExReplace(group, "^(.+):(.+)$", "$1")
            sub  := RegExReplace(group, "^(.+):(.+)$", "$2")

            groupMenu := Menu()
            Loop Parse, sub, "|" {
                subIdx := A_Index
                svc := A_LoopField
                ; Bind замораживает значения cmdText и svc, иначе все будут указывать на последнее
                groupMenu.Add("&" subIdx ". " svc, Systemctl.Bind(cmdText, svc))
            }
            cmdMenu.Add("&" groupIdx ". " name, groupMenu)
        }
        rootMenu.Add("&" cmdIdx ". " cmdText, cmdMenu)
    }

    rootMenu.Add("&systemctl -a | grep inqoob", Systemctl.Bind("-a | grep", "inqoob"))
    return rootMenu
}

Systemctl(cmd, serv, *) {
    SendText("systemctl " . cmd . " " . serv)
    if !InStr(serv, "{TAB")
        Send "{Enter}"
    if (cmd = "start") {
        SendText("systemctl status " . serv)
        Send "{Enter}"
    }
}

; ----------------------------------------------------------
; ssh-шаблоны (требуют Send3 — общая функция из main.ahk)
Ssh0(*) {
    Send3("ssh -D 9999 root@206.189.105.106")
    Send "{Enter}"
}
Ssh4(*) {
    Send3('type $env:USERPROFILE\.ssh\id_rsa.pub | ssh root@ "cat >> .ssh/authorized_keys"')
    Send "{Left 30}"
}
Ssh5(*) {
    SendText("ssh -L 8080:remoteserver.org:80 ssh-server")
    Send "{Left 14}"
}
Ssh6(*) {
    Send3("ssh root@IP 'bash -s' < local_script.sh")
    Send "{Left 28}"
}
Ssh7(*) {
    Send3('echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC74zFURucisFnCko4zOR4mKWPB/Qf8sphp+xNJVN6mHU2PmvASFkj1CIvkWFWzfT0pN2HdG0fgDFHBCBzplJ3aKadceFOwULyoZ9wcCxB5+8X3CNc01EDeRNSOxGtJWiykFcvC7mkfwCufpFz9xgCeuSyh9FopBGgv6Ods9coMjxYDtllNVOzqP5/PPBFyaPh8NMJrhjkgp5OZPPYACoomkyqKEOZhw2RXGaZDHgbPIs6DrcBKQtmktZaZoYeO6nGr498A7QvU1eGSrhFKNW6tf9RXUcammTKz8IvAsfg/Vu3srAxnp7SRXUGwSQHzdRomDGfJTOzvdBNvUMaooN9/VD6fEBZ0lIvDM96LxBmP6fvd1L7CqDLQNbdYTG9jSpor9f24aDFGYgQ9NumfwA/Gu8e6ivxAmlszntrpE5sfPr8m8lsqas4OQA7IRSkel2Npy3yKvV/1I2nvX5Ot5uqoU8vYF6eHFTfqPCV/9MdlJ1nfn5rLOVofWHTJ9BEKH6s= user@vr" >> ~/.ssh/authorized_keys')
}

; ----------------------------------------------------------
; вспомогательные
DoGitConfig(*) {
    Send 'git config --global user.name "vruzin"{Enter}'
    Send 'git config --global user.email "vruzin@ya.ru"{Enter}'
}

DoBackupSql(*) {
    date := FormatTime(, "yyyy-MM-dd")
    SendText("mysqldump -u root -p dbname > db-" . date . ".sql")
}

DoBackupTar(*) {
    date := FormatTime(, "yyyy-MM-dd")
    SendText("tar -cvf public_" . date . ".tar.gz /var/www/vruzin/domen.ru")
}

; Команда + Enter (короткая обёртка)
SendCmd(cmd) {
    SendText(cmd)
    Send "{Enter}"
}
