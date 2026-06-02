; ============================================================
; Docker.ahk — AutoHotkey v2
; CapsLock+D — иерархическое меню docker / docker-compose / swarm-команд.
; ============================================================

; CapsLock+D — регистрируется в RegisterGlobalHotkeys через FeatureRegistry.
ShowDockerMenu(*) {
    MenuData.Build(DockerMenuData()).Show()
    SetNumLockState("Off")
    SetCapsLockState("Off")
}

; Данные меню (единый источник для AHK-меню и лаунчера).
DockerMenuData() {
    psSub := [
        Map("label", "docker ps", "hint", "Список контейнеров", "fn", (*) => SendCmdLine("docker ps")),
        Map("label", "docker ps | grep ...", "hint", "Фильтр списка", "fn", (*) => SendText("docker ps | grep ")),
        Map("label", "docker ps | grep nginx", "hint", "Фильтр с nginx", "fn", (*) => SendCmdLine("docker ps | grep nginx")),
        Map("label", "docker ps | grep sftpgo", "hint", "Фильтр с sftpgo", "fn", (*) => SendCmdLine("docker ps | grep sftpgo"))
    ]
    composeSub := [
        Map("label", "docker-compose up -d --no-deps --build nginx", "hint", "Пересборка контейнера", "fn", DockerComposeUp),
        Map("label", "docker-compose run --rm certbot certonly ... -d subdomen.example.ru", "hint", "Let's Encrypt сертификат",
            "fn", (*) => SendText("docker-compose run --rm  certbot certonly --webroot --webroot-path /var/www/certbot/ -d subdomen.example.ru")),
        Map("label", "docker-compose run --rm certbot renew", "hint", "Обновить сертификаты",
            "fn", (*) => SendText("docker-compose run --rm certbot renew"))
    ]
    nodeSub := [
        Map("label", "Шаг1: Открыть порты (manager node)", "fn", DockerNode1),
        Map("label", "Шаг1: Открыть порты (worker node)",  "fn", DockerNode2),
        Map("label", "Шаг2: docker swarm init", "hint", "Ответ — на все worker node", "fn", DockerNode3),
        Map("label", "docker node ls", "hint", "Список кластеров", "fn", (*) => (SendText("docker node ls"), Send("{Enter}"))),
        Map("sep", true),
        Map("label", "Убить кластер: docker swarm leave", "hint", "Выполнить на кластере",
            "fn", (*) => (SendText("docker swarm leave"), Send("{Enter}")))
    ]
    return [
        Map("label", "Исходники", "hint", "https://habr.com/ru/post/659813/",
            "fn", (*) => (SendText("https://habr.com/ru/post/659813/"), Send("{Enter}"))),
        Map("label", "docker ps", "hint", "Список контейнеров", "sub", psSub),
        Map("label", "docker-compose ...", "hint", "Консоль", "sub", composeSub),
        Map("label", "Создание кластера", "hint", "docker swarm", "sub", nodeSub)
    ]
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
