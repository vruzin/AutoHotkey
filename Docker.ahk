CapsLock & d::
Menu, dockerMenu, Add, &0. Исходники`thttps://habr.com/ru/post/659813/, doc0
Menu, dockerMenu_ps, Add, &1. docker ps`tСписок контейнеров, doc1
Menu, dockerMenu_ps, Add, &2. docker ps | grep ... `tФильтр списка контейнеров ..., doc2
Menu, dockerMenu_ps, Add, &3. docker ps | grep nginx `tФильтр списка контейнеров c nginx, doc3
Menu, dockerMenu_ps, Add, &4. docker ps | grep sftpgo `tФильтр списка контейнеров c sftpgo, doc4
Menu, dockerMenu_ps, Add
Menu, dockerMenu, Add, &1. docker ps`tСписок контейнеров, :dockerMenu_ps

Menu, dockerComposeMenu, Add, &1. docker-compose up -d --no-deps --build nginx `tПерезапустить сборку контейнера с образом, comp1
Menu, dockerComposeMenu, Add, &2. docker-compose run --rm  certbot certonly --webroot --webroot-path /var/www/certbot/ -d subdomen.example.ru `tСоздать Let's Encrypt сертификат для домена, comp2
Menu, dockerComposeMenu, Add, &3. docker-compose run --rm certbot renew `tОбновить все сертификаты Let's Encrypt, comp3
Menu, dockerComposeMenu, Add
Menu, dockerMenu, Add, &2. docker-compose ...`tКонсоль, :dockerComposeMenu

Menu, dockerMenu_node, Add, &1. Шаг1: Открыть порты`tmanager node, docNode1
Menu, dockerMenu_node, Add, &2. Шаг1: Открыть порты`tworker node, docNode2
Menu, dockerMenu_node, Add, &3. Шаг2: На manager node: docker swarm init`tОтвет выполнить на всех worker node, docNode3
Menu, dockerMenu_node, Add, &4. На manager node:docker node ls`tСписок кластеров, docNode4
Menu, dockerMenu_node, Add
Menu, dockerMenu_node, Add, &5. Убить кластер: docker swarm leave `tВыполнить на кластере, docNode5
Menu, dockerMenu, Add, &3. Создание кластера `tdocker swarm, :dockerMenu_node


; Menu, dockerMenu_stack, Add, &1. Шаг1: Открыть порты`tmanager node, docStack1
; Menu, dockerMenu_stack, Add, &2. Шаг1: Открыть порты`tworker node, docStack2
; Menu, dockerMenu_stack, Add, &3. Шаг2: На manager node: docker swarm init`tОтвет выполнить на всех worker node, docStack3
; Menu, dockerMenu_stack, Add, &4. На manager node:docker node ls`tСписок кластеров, docStack4
; Menu, dockerMenu_stack, Add
; Menu, dockerMenu_stack, Add, &5. Убить кластер: docker swarm leave`tВыполнить на кластере, docStack5
; Menu, dockerMenu, Add, &2. Создание кластера`tdocker swarm, :dockerMenu_node


Menu, dockerMenu, Show
Menu, dockerMenu, DeleteAll
SetNumLockState, Off
SetCapsLockState, Off
return

docNode1:
SendRaw, firewall-cmd --add-port=2376/tcp --permanent;
Send, {Enter}
SendRaw, firewall-cmd --add-port=2377/tcp --permanent;
Send, {Enter}
SendRaw, firewall-cmd --add-port=7946/tcp --permanent;
Send, {Enter}
SendRaw, firewall-cmd --add-port=7946/udp --permanent;
Send, {Enter}
SendRaw, firewall-cmd --add-port=4789/udp --permanent;
Send, {Enter}
SendRaw, firewall-cmd --reload;
Send, {Enter}
MsgBox, Ждем
SendRaw, systemctl restart docker;
Send, {Enter}
return

docNode2:
SendRaw, firewall-cmd --add-port=2376/tcp --permanent;
Send, {Enter}
SendRaw, firewall-cmd --add-port=7946/tcp --permanent;
Send, {Enter}
SendRaw, firewall-cmd --add-port=7946/udp --permanent;
Send, {Enter}
SendRaw, firewall-cmd --add-port=4789/udp --permanent;
Send, {Enter}
SendRaw, firewall-cmd --reload;
Send, {Enter}
MsgBox, Ждем
SendRaw, systemctl restart docker;
Send, {Enter}
return

docNode3:
SendRaw, docker swarm init
Send, {Enter}
MsgBox, Если все успешно, то в ответ вы получим команду вида:`n`n`ndocker swarm join --token SWMTKN-1-54k2k418tw2j0juwm3inq6crp4ow6xogswihcc5azg7oq5qo7e-a3rfeyfwo7d93heq0y5vhyzod 172.31.245.104:2377`n`n`nЕе будет необходимо выполнить на всех worker node, чтобы присоединить их в только что созданный кластер.
return

docNode4:
SendRaw, docker node ls
Send, {Enter}
return

docNode5:
SendRaw, docker swarm leave
Send, {Enter}
return



comp1:
SendRaw, docker-compose up -d --no-deps --build 
ToolTip, docker-compose up -d --no-deps --build <nginx>`n=====`n<nginx> - Название сервиса в docker-compose
SetTimer, RemoveToolTipDocker, -3000
return

comp2:
SendRaw, docker-compose run --rm  certbot certonly --webroot --webroot-path /var/www/certbot/ -d subdomen.example.ru
return
comp3:
SendRaw, docker-compose run --rm certbot renew
return






doc0:
SendRaw, https://habr.com/ru/post/659813/
Send, {Enter}
return

doc1:
SendRaw, docker ps
Send, {Enter}
return

doc2:
SendRaw, docker ps | grep 
return

doc3:
SendRaw, docker ps | grep nginx
Send, {Enter}
return

doc4:
SendRaw, docker ps | grep sftpgo
Send, {Enter}
return




RemoveToolTipDocker:
ToolTip
return