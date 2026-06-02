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
; (регистрируется в RegisterGlobalHotkeys через FeatureRegistry)
KittyLaunch(*) {
    Run('m:\Sys\Kitty\kitty_portable.exe')
    WinWait("KiTTY Configuration")
    Sleep 300
    Send "{TAB 5}{Down 5}"
}

; ----------------------------------------------------------
; CapsLock+S — большое sysadmin-меню
; (регистрируется в RegisterGlobalHotkeys через FeatureRegistry)
ShowSshMenu(*) {
    MenuData.Build(SshMenuData()).Show()
    SetNumLockState("Off")
    SetCapsLockState("Off")
}

; Данные sysadmin-меню (единый источник для AHK-меню и лаунчера).
; systemctl остаётся динамическим подменю (BuildSystemctlMenu возвращает Menu) —
; MenuData.Build вставит его как готовый объект; в лаунчер он не разворачивается.
SshMenuData() {
    nginxSub := [
        Map("label", "nginx -t",        "fn", (*) => SendCmd("nginx -t")),
        Map("label", "nginx -s reload", "fn", (*) => SendCmd("nginx -s reload")),
        Map("label", "nginx -v",        "fn", (*) => SendCmd("nginx -v"))
    ]
    chmodSub := [
        Map("label", "chown -R bitrix:bitrix .../vruzin/", "hint", "Владелец рекурсивно",
            "fn", (*) => SendText("chown -R bitrix:bitrix /home/bitrix/ext_www/mvk-spb.ru/vruzin/")),
        Map("label", "chmod -R 755 .", "hint", "Права 755 рекурсивно",
            "fn", (*) => (SendText("chmod -R 755 ."), Send("{Enter}")))
    ]
    gitSub := [
        Map("label", "git submodule update --init --merge --remote --recursive", "hint", "Субмодули",
            "fn", (*) => SendCmd("git submodule update --init --merge --remote --recursive")),
        Map("label", "git config --global user.name", "hint", "Git Авторизация", "fn", DoGitConfig),
        Map("label", "git config --list --show-origin", "hint", "настройки и где заданы. Q-выход",
            "fn", (*) => SendCmd("git config --list --show-origin")),
        Map("label", "git branch --sort=-committerdate", "hint", "сортировка веток по дате",
            "fn", (*) => SendCmd("git branch --sort=-committerdate"))
    ]
    powershellSub := [
        Map("label", '(dir */*.go | select-string "github.com" | Get-Unique)', "hint", "подключаемые github-модули",
            "fn", (*) => Send('(dir */*.go | select-string "github.com" | Get-Unique){Enter}'))
    ]
    mvkSub := [
        Map("label", "rm -rf (весь кеш Bitrix)", "hint", "Удалить весь кеш",
            "fn", (*) => Send("rm -rf /home/bitrix/ext_www/mvk-spb.ru/bitrix/managed_cache/MYSQL/* /home/bitrix/ext_www/mvk-spb.ru/bitrix/cache/*{Enter}"))
    ]
    sshSub := [
        Map("label", "ТУННЕЛЬ", "hint", "запустить в powershell", "fn", Ssh0),
        Map("label", "ssh => копировать ключ на удалённый сервер", "fn", Ssh4),
        Map("label", "ssh => копировать ключ в .ssh/authorized_keys", "fn", Ssh7),
        Map("label", "ssh туннель => через удалённый порт", "fn", Ssh5),
        Map("label", "ssh скрипт => локальный скрипт на сервере", "fn", Ssh6),
        Map("label", "ls -l",  "hint", "Список директории подробно", "fn", (*) => (SendText("ls -l"), Send("{Enter}"))),
        Map("label", "ls -al", "hint", "Список директории подробно", "fn", (*) => (SendText("ls -al"), Send("{Enter}"))),
        Map("label", "ssh user@ip", "hint", "Подключение ssh", "fn", (*) => (SendText("ssh user@ip"), Send("{Enter}")))
    ]
    curlSub := [
        Map("label", "curl --resolve 'domain.ru:80:127.0.0.1' http://domain.ru/link", "hint", "запрос по IP",
            "fn", (*) => SendText("curl --resolve 'domain.ru:80:127.0.0.1' http://domain.ru/link"))
    ]
    backupSub := [
        Map("label", "mysqldump -u root -p dbname > db-YYYY-MM-DD.sql", "hint", "Бэкап MySQL", "fn", DoBackupSql),
        Map("label", "tar -cvf public_YYYY-MM-DD.tar.gz /var/www/vruzin/domen.ru", "hint", "Архивация папки", "fn", DoBackupTar)
    ]
    ispSub := [
        Map("label", "/usr/local/mgr5/sbin/mgrctl -m ispmgr exit", "hint", "перегрузить ISP",
            "fn", (*) => SendText("/usr/local/mgr5/sbin/mgrctl -m ispmgr exit"))
    ]
    return [
        Map("label", "nginx", "sub", nginxSub),
        Map("label", "chown/chmod", "hint", "Права и Владельцы", "sub", chmodSub),
        Map("label", "systemctl", "sub", BuildSystemctlMenu()),   ; динамическое подменю (Menu)
        Map("label", "git", "sub", gitSub),
        Map("label", "PowerShell", "sub", powershellSub),
        Map("label", "MVK", "sub", mvkSub),
        Map("label", "ssh", "sub", sshSub),
        Map("label", "curl", "sub", curlSub),
        Map("label", "Бекап", "sub", backupSub),
        Map("label", "ISPmanager 6", "sub", ispSub),
        Map("sep", true),
        Map("label", "cd /var/www/www-root/data/ + ls -la", "fn", (*) => Send("cd /var/www/www-root/data/{Enter}ls -la{Enter}")),
        Map("label", "df", "hint", "Сколько места занято", "fn", (*) => Send("df{Enter}")),
        Map("label", "cat /proc/version", "hint", "Версия системы", "fn", (*) => Send("cat /proc/version{Enter}")),
        Map("label", "cat /etc/*-release", "hint", "Всё о системе", "fn", (*) => Send("cat /etc/*-release{Enter}")),
        Map("label", 'nginx -T | grep "server_name "', "hint", "Список доменов", "fn", (*) => Send('nginx -T | grep "server_name "{Enter}')),
        Map("label", "netstat -ano | findstr :9303", "hint", "порт 9303", "fn", (*) => Send("netstat -ano | findstr :9303{Enter}"))
    ]
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
