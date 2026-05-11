; ============================================================
; Docker.ahk — AutoHotkey v2
; CapsLock+D — иерархическое меню docker / docker-compose / swarm-команд.
; ============================================================

CapsLock & d:: ShowDockerMenu()

ShowDockerMenu() {
    ; --- docker ps ---
    psMenu := Menu()
    psMenu.Add("&1. docker ps`tСписок контейнеров", (*) => SendCmdLine("docker ps"))
    psMenu.Add("&2. docker ps | grep ...`tФильтр списка", (*) => SendText("docker ps | grep "))
    psMenu.Add("&3. docker ps | grep nginx`tФильтр с nginx", (*) => SendCmdLine("docker ps | grep nginx"))
    psMenu.Add("&4. docker ps | grep sftpgo`tФильтр с sftpgo", (*) => SendCmdLine("docker ps | grep sftpgo"))
    psMenu.Add()

    ; --- docker-compose ---
    composeMenu := Menu()
    composeMenu.Add("&1. docker-compose up -d --no-deps --build nginx`tПересборка контейнера", DockerComposeUp)
    composeMenu.Add("&2. docker-compose run --rm certbot certonly --webroot ... -d subdomen.example.ru`tLet's Encrypt сертификат",
        (*) => SendText("docker-compose run --rm  certbot certonly --webroot --webroot-path /var/www/certbot/ -d subdomen.example.ru"))
    composeMenu.Add("&3. docker-compose run --rm certbot renew`tОбновить сертификаты",
        (*) => SendText("docker-compose run --rm certbot renew"))
    composeMenu.Add()

    ; --- swarm node ---
    nodeMenu := Menu()
    nodeMenu.Add("&1. Шаг1: Открыть порты`tmanager node", DockerNode1)
    nodeMenu.Add("&2. Шаг1: Открыть порты`tworker node",  DockerNode2)
    nodeMenu.Add("&3. Шаг2: docker swarm init`tОтвет — на все worker node", DockerNode3)
    nodeMenu.Add("&4. docker node ls`tСписок кластеров", (*) => (SendText("docker node ls"), Send("{Enter}")))
    nodeMenu.Add()
    nodeMenu.Add("&5. Убить кластер: docker swarm leave`tВыполнить на кластере",
        (*) => (SendText("docker swarm leave"), Send("{Enter}")))

    ; --- корневое меню ---
    root := Menu()
    root.Add("&0. Исходники`thttps://habr.com/ru/post/659813/",
        (*) => (SendText("https://habr.com/ru/post/659813/"), Send("{Enter}")))
    root.Add("&1. docker ps`tСписок контейнеров", psMenu)
    root.Add("&2. docker-compose ...`tКонсоль", composeMenu)
    root.Add("&3. Создание кластера`tdocker swarm", nodeMenu)
    root.Show()

    SetNumLockState("Off")
    SetCapsLockState("Off")
}

; ----------------------------------------------------------
; manager node: открыть порты
DockerNode1(*) {
    Loop Parse, "2376/tcp,2377/tcp,7946/tcp,7946/udp,4789/udp", "," {
        SendText("firewall-cmd --add-port=" . A_LoopField . " --permanent;")
        Send "{Enter}"
    }
    SendText("firewall-cmd --reload;")
    Send "{Enter}"
    MsgBox("Ждём")
    SendText("systemctl restart docker;")
    Send "{Enter}"
}

; worker node: открыть порты
DockerNode2(*) {
    Loop Parse, "2376/tcp,7946/tcp,7946/udp,4789/udp", "," {
        SendText("firewall-cmd --add-port=" . A_LoopField . " --permanent;")
        Send "{Enter}"
    }
    SendText("firewall-cmd --reload;")
    Send "{Enter}"
    MsgBox("Ждём")
    SendText("systemctl restart docker;")
    Send "{Enter}"
}

; init кластера + пояснение
DockerNode3(*) {
    SendText("docker swarm init")
    Send "{Enter}"
    MsgBox("Если всё успешно, в ответ получим команду вида:`n`ndocker swarm join --token SWMTKN-1-…`n`nЕё надо выполнить на всех worker node, чтобы присоединить их в кластер.")
}

; docker-compose up + всплывающая подсказка
DockerComposeUp(*) {
    SendText("docker-compose up -d --no-deps --build ")
    ToolTip "docker-compose up -d --no-deps --build <nginx>`n=====`n<nginx> — название сервиса в docker-compose"
    SetTimer () => ToolTip(), -3000
}

; ----------------------------------------------------------
; Локальная утилита (своя, чтобы не зависеть от kitty.ahk)
SendCmdLine(cmd) {
    SendText(cmd)
    Send "{Enter}"
}
