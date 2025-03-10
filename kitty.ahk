﻿; psql -U postgres -h 127.0.0.1 -a -f ./sftpgo_init_postgres.sql
CapsLock & k::
Run, m:\Sys\Kitty\kitty_portable.exe
WinWait, KiTTY Configuration
Sleep, 300
Send, {TAB 5}{Down 5}
return

CapsLock & s::
Menu, sshMenu_nginx, Add, &1. nginx -t, mp2_1
Menu, sshMenu_nginx, Add, &2. nginx -s reload, mp2_2
Menu, sshMenu_nginx, Add, &3. nginx -v, mp2_3
Menu, sshMenu, Add, &1. nginx, :sshMenu_nginx

Menu, sshMenu_chmod, Add, &1. chown -R bitrix:bitrix /home/bitrix/ext_www/mvk-spb.ru/vruzin/`t(Сменить пользователя и группу для папки Рекурсивно), mp8
Menu, sshMenu_chmod, Add, &2. chmod -R 755 .`t(Права 755 для папки Рекурсивно), mp9
Menu, sshMenu, Add, &2. chown/chmod `t(Права и Владельцы), :sshMenu_chmod

Systemctl_comands := "status|stop|start|enable|disable"
; Systemctl_services := "inqoob-v{TAB 2}|inqoob-v7-cm|inqoob-v7-constructor|inqoob-v7-tg"
Systemctl_services := "inqoob-&v:inqoob-v{TAB 2}^inqoob-v&6:inqoob-v6{TAB 2}|inqoob-v6-cm|inqoob-v6-constructor|inqoob-v6-tg^inqoob-v&7:inqoob-v7{TAB 2}|inqoob-v7-cm|inqoob-v7-constructor|inqoob-v7-tg"
; Systemctl_services := Systemctl_services."^inqoob-v&6:inqoob-v6{TAB 2}|inqoob-v6-cm|inqoob-v6-constructor|inqoob-v6-tg"
; Systemctl_services := Systemctl_services."^inqoob-v&7:inqoob-v7{TAB 2}|inqoob-v7-cm|inqoob-v7-constructor|inqoob-v7-tg"


Loop, parse, Systemctl_comands, `|
{
	i1:=A_Index
	e1:=A_LoopField
	Loop, parse, Systemctl_services, `^
	{
		i2:=A_Index
		e2:=A_LoopField
		menu_name    := RegExReplace(e2, "^(.+):(.+)$", "$1")
		submenu_name := RegExReplace(e2, "^(.+):(.+)$", "$2")

		Loop, parse, submenu_name, `|
		{
			i3:=A_Index
			e3:=A_LoopField
			systemctl_%i1%_%i2%_%i3% := Func("Systemctl").Bind(e1,e3)
			Menu, Systemctl_%i1%_%i2%, Add, &%i3%. %e3%, % systemctl_%i1%_%i2%_%i3%
		}
		Menu, Systemctl_%i1%, Add, &%i2%. %menu_name%, :Systemctl_%i1%_%i2%
	}
	Menu, Systemctl_, Add, &%i1%. %e1%, :Systemctl_%i1%
}


; Loop, parse, Systemctl_comands, `|
; {
; 	i1:=A_Index
; 	e1:=A_LoopField
; 	Loop, parse, Systemctl_services, `|
; 	{
; 		i2:=A_Index
; 		e2:=A_LoopField
; 		systemctl_%i1%_%i2% := Func("Systemctl").Bind(e1,e2)
; 		Menu, Systemctl_%i1%, Add, &%i2%. %e2%, % systemctl_%i1%_%i2%
; 	}
; 	Menu, Systemctl_, Add, &%i1%. %e1%, :Systemctl_%i1%
; }
systemctl_z := Func("Systemctl").Bind("-a | grep","inqoob")
Menu, Systemctl_, Add, &systemctl -a | grep inqoob, % systemctl_z
Menu, sshMenu, Add, &3. systemctl, :Systemctl_



Menu, sshMenu_git, Add, &1. git submodule update --init --merge --remote --recursive `t(Подгрузить и обновить субмодули), mgit_1
Menu, sshMenu_git, Add, &2. git config --global user.name `t(Git Авторизация), mgit_2
Menu, sshMenu_git, Add, &3. git config --list --show-origin `t(Git настройки и где заданы. Q - выход), mgit_3
Menu, sshMenu_git, Add, &4. git branch --sort=-committerdate `t(Сортировка веток по дате), mgit_4
Menu, sshMenu, Add, &4. git, :sshMenu_git


Menu, sshMenu_powershell, Add, &1. (dir */*.go | select-string "github.com" | Get-Unique)`t(Список всех подключаемых модулей Github), mpowershell_1
Menu, sshMenu, Add, &5. PowerShell, :sshMenu_powershell

Menu, sshMenu_mvk, Add, &1. rm -rf `t(Удалить весь кеш), mvk_1
Menu, sshMenu, Add, &6. MVK, :sshMenu_mvk

Menu, sshMenu_ssh, Add, &1. ssh => `t(копировать мой ключ на удаленный сервер),ssh_4
Menu, sshMenu_ssh, Add, &2. ssh туннель => `t(Создать тунель через удаленный порт),ssh_5
Menu, sshMenu_ssh, Add, &3. ssh скрипт => `t(Запустить локальный скрипт на удаленном сервере),ssh_6
Menu, sshMenu_ssh, Add, &4. ls -l `t(Список директории подробно),ssh_2
Menu, sshMenu_ssh, Add, &5. ls -al `t(Список директории подробно),ssh_3
Menu, sshMenu_ssh, Add, &6. ssh user@ip `t(Подключение ssh),ssh_1
Menu, sshMenu, Add, &7. ssh, :sshMenu_ssh

Menu, sshMenu_curl, Add, &1. curl --resolve 'domain.ru:80:127.0.0.1' http://domain.ru/link `t(Запрос по сайту на сервере по IP),curl_1
Menu, sshMenu, Add, &8. curl, :sshMenu_curl

Menu, sshMenu_backup, Add, &1. mysqldump -u root -p dbname > db-2023-01-18.sql `t(Бекап базы MySQL. Ввести пароль),backup_1
Menu, sshMenu_backup, Add, &2. tar -cvf public_2023-01-18.tar.gz /var/www/vruzin/domen.ru `t(Архивация папки),backup_2
Menu, sshMenu, Add, &9. Бекап, :sshMenu_backup

Menu, sshMenu_isp, Add, &1. /usr/local/mgr5/sbin/mgrctl -m ispmgr exit `t(Перегрузить ISP. Помогает в сбоях CRON),isp_1
Menu, sshMenu, Add, &a. ISPmanager 6, :sshMenu_isp

; Cmds := [
; 	["ssh user@ip","ssh user@ip",],
; ]
; Loop, parse, Systemctl_comands, `|
; {
; 	i1:=A_Index
; 	e1:=A_LoopField
; 	Loop, parse, Systemctl_services, `^
; 	{
; 		i2:=A_Index
; 		e2:=A_LoopField
; 		menu_name    := RegExReplace(e2, "^(.+):(.+)$", "$1")
; 		submenu_name := RegExReplace(e2, "^(.+):(.+)$", "$2")

; 		Loop, parse, submenu_name, `|
; 		{
; 			i3:=A_Index
; 			e3:=A_LoopField
; 			systemctl_%i1%_%i2%_%i3% := Func("Systemctl").Bind(e1,e3)
; 			Menu, Systemctl_%i1%_%i2%, Add, &%i3%. %e3%, % systemctl_%i1%_%i2%_%i3%
; 		}
; 		Menu, Systemctl_%i1%, Add, &%i2%. %menu_name%, :Systemctl_%i1%_%i2%
; 	}
; 	Menu, Systemctl_, Add, &%i1%. %e1%, :Systemctl_%i1%
; }



Menu, sshMenu, Add ; Add a separator line.
Menu, sshMenu, Add, &cd /var/www/www-root/data/, mp3
Menu, sshMenu, Add, &df`t(Сколько места занято), mp4
Menu, sshMenu, Add, c&at /proc/version`t(Версия системы), mp5
Menu, sshMenu, Add, ca&t /etc/*-release`t(Всё о системе), mp6
Menu, sshMenu, Add, n&ginx -T | grep "server_name " `t(Список всех доменов), mp7
Menu, sshMenu, Add, n&etstat -ano | findstr :9303 `t(Открытые порты с фильтром по порту 9303), mp10

Menu, sshMenu, Show
Menu, sshMenu, DeleteAll
SetNumLockState, Off
SetCapsLockState, Off
return

ssh_1:
SendRaw, ssh user@ip
Send, {Enter}
return

ssh_2:
SendRaw, ls -l
Send, {Enter}
return

ssh_3:
SendRaw, ls -al
Send, {Enter}
return

ssh_4:
SendRaw, type $env:USERPROFILE\.ssh\id_rsa.pub | ssh root@ "cat >> .ssh/authorized_keys"
Send, {Left 30}
return

ssh_5:
SendRaw, ssh -L 8080:remoteserver.org:80 ssh-server
Send, {Left 14}
return

ssh_6:
SendRaw, ssh root@IP 'bash -s' < local_script.sh
Send, {Left 28}
return



mpowershell_1:
Send, (dir */*.go | select-string "github.com" | Get-Unique){Enter}
return
mvk_1:
Send, rm -rf /home/bitrix/ext_www/mvk-spb.ru/bitrix/managed_cache/MYSQL/* /home/bitrix/ext_www/mvk-spb.ru/bitrix/cache/*{Enter}
return
mgit_1:
Send, git submodule update --init --merge --remote --recursive{Enter}
return
mgit_2:
Send, git config --global user.name "vruzin"{Enter}
Send, git config --global user.email "vruzin@ya.ru"{Enter}
return
mgit_3:
Send, git config --list --show-origin{Enter}
return
mgit_4:
Send, git branch --sort=-committerdate{Enter}
return
mp10:
Send, netstat -ano | findstr :9303{Enter}
return
mp2_1:
Send, nginx -t{Enter}
return
mp2_2:
Send, nginx -s reload{Enter}
return
mp2_3:
Send, nginx -v{Enter}
return

mp3:
Send, cd /var/www/www-root/data/{Enter}ls -la{Enter}
return

mp4:
Send, df{Enter}
return

mp5:
Send, cat /proc/version{Enter}

mp6:
Send, cat /etc/*-release{Enter}
return

mp7:
Send, nginx -T | grep "server_name "{Enter}
return

mp8:
SendRaw, chown -R bitrix:bitrix /home/bitrix/ext_www/mvk-spb.ru/vruzin/
; Send, {Enter}
return

mp9:
SendRaw, chmod -R 755 .
Send, {Enter}
return

curl_1:
SendRaw, curl --resolve 'domain.ru:80:127.0.0.1' http://domain.ru/link
return

isp_1:
SendRaw, /usr/local/mgr5/sbin/mgrctl -m ispmgr exit
return

backup_1:
FormatTime, TimeString,, yyyy-MM-dd
SendRaw, mysqldump -u root -p dbname > db-
Send, %TimeString%
SendRaw, .sql
return

backup_2:
FormatTime, TimeString,, yyyy-MM-dd
SendRaw, tar -cvf public_
Send, %TimeString%
SendRaw, .tar.gz /var/www/vruzin/domen.ru
return


;Systemctl_1_2 := Func("Systemctl").Bind("status","inqoob-v")
Systemctl(cmd,serv)
{
	SendRaw, systemctl %cmd% %serv%
	If !InStr(serv, "{TAB")
		Send, {Enter}
	if (cmd="start") {
		SendRaw, systemctl status %serv%
		Send, {Enter}
	}
}

DblSend(asRaw,asSend)
{
	SendRaw, %asRaw%
	Send, asSend
}