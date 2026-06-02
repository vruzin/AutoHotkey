# Plan_008 — Лаунчер (Alfred-стиль): поиск, человекочитаемые клавиши, меню в поиске

## Цель
Превратить окно настроек в безрамочный лаунчер:
- Безрамочное окно (без шапки), по центру сверху, прячется по Esc/потере фокуса.
- Поиск по мере ввода (фаззи) по всем функциям и пунктам меню.
- Enter — запускает функцию/пункт меню. Окно прячется.
- Шестерёнка справа внизу → режим настроек: тот же отфильтрованный список, но
  с галочками (вкл/выкл через FeatureRegistry, в рантайме).
- Клавиши пишутся по-человечески: Ctrl+Shift+Alt+U, CapsLock+I, Win+C, Ctrl+Mute.
- Пункты меню (Docker/SSH/build/fl/dop/main) попадают в поиск плоско:
  «Docker › docker ps», и их можно запускать прямо из лаунчера.
- Открытие: клик по трею + CapsLock+Shift.

## Архитектура
- **features/HotkeyHuman.ahk** — `HotkeyToHuman(ahkKey)`: ^+!u→Ctrl+Shift+Alt+U и т.п.
- **core/MenuData.ahk** — единый источник для меню:
  - `MenuData.Build(dataArray)` → строит родное AHK Menu (рекурсивно, подменю).
  - `MenuData.Flatten(dataArray, groupLabel)` → плоский список
    [{label:"Docker › docker ps", hint, fn}] для лаунчера.
  - Запись данных: Map("label",..,"hint",..,"fn",..) | Map("label",..,"sub",[..]) | Map("sep",true)
- **legacy/*.ahk** — рефактор: данные пунктов в функцию XxxMenuData(),
  ShowXxxMenu использует MenuData.Build, регистрация лаунчера — Flatten.
- **core/Commands.ahk** — собирает все команды лаунчера: из FeatureRegistry
  (хоткеи/фичи) + из MenuData.Flatten каждого меню. Отдаёт Snapshot для UI.
- **ui/Launcher.ahk** (вместо Settings.ahk) — WebApp + обработчики
  getData / run(id) / toggle / toggleGroup. Трей + хоткей.
- **ui/apps/launcher/** — Vue SPA: поиск, список, режим (запуск/настройки), шестерёнка.
- **ui/WebApp.ahk** — добавить опции frameless (-Caption) и hideOnBlur.

## Подзадачи

### Этап 1 — HotkeyToHuman
- [ ] 1.1 features/HotkeyHuman.ahk: HotkeyToHuman(key)
- [ ] 1.2 tools/test_hotkey_human.ahk + .bat (~15 кейсов)
- [ ] 1.3 #Include в main.ahk

### Этап 2 — MenuData + рефактор меню в данные
- [ ] 2.1 core/MenuData.ahk: Build + Flatten + sep/sub
- [ ] 2.2 Рефактор Docker.ahk → DockerMenuData()
- [ ] 2.3 Рефактор kitty.ahk (SSH + systemctl) → SshMenuData()
- [ ] 2.4 Рефактор build/fl/dop_menu/main-menu → *MenuData()
- [ ] 2.5 ShowXxxMenu используют MenuData.Build; проверка родных меню /validate

### Этап 3 — Commands (единый список для лаунчера)
- [ ] 3.1 core/Commands.ahk: Snapshot() = хоткеи (FeatureRegistry) + пункты меню (Flatten)
- [ ] 3.2 run(id) — выполнить команду по id (хоткей fn / menuitem fn)
- [ ] 3.3 Клавиши через HotkeyToHuman в Snapshot

### Этап 4 — WebApp frameless + hideOnBlur
- [ ] 4.1 опция frameless: Gui -Caption +Border
- [ ] 4.2 опция hideOnBlur: ловить деактивацию → Hide()
- [ ] 4.3 drag за верхнюю зону (опц.)

### Этап 5 — Лаунчер Vue
- [ ] 5.1 ui/apps/launcher/{index.html, app.js, style.css}
- [ ] 5.2 Фаззи-поиск (subsequence + скоринг) на стороне Vue
- [ ] 5.3 Режим «Запуск»: ↑↓, Enter → ahk.call('run', {id}), окно прячется
- [ ] 5.4 Шестерёнка → режим «Настройки»: галочки → ahk.call('toggle'/'toggleGroup')
- [ ] 5.5 Клавиши справа в строке (человекочитаемые)

### Этап 6 — Трей + хоткей + интеграция
- [ ] 6.1 ui/Launcher.ahk: SettingsTray_Init → LauncherTray, клик открывает лаунчер
- [ ] 6.2 CapsLock+Shift → лаунчер (Register в FeatureRegistry, группа global)
- [ ] 6.3 Заменить SettingsWindow на Launcher в main.ahk
- [ ] 6.4 Закрыть старый ui/apps/settings (оставить или удалить)

### Этап 7 — Проверка и документация
- [ ] 7.1 /validate, юнит-тесты, боевой запуск + скриншот
- [ ] 7.2 Обновить CLAUDE.md

## Решения
- Единый источник: меню строятся из данных (MenuData), лаунчер берёт те же данные.
- fn пунктов остаются прежними лямбдами/функциями — переносятся в массивы, не переписываются.
- Фаззи-поиск в JS (Vue), не в AHK — быстрее и проще.
- hideOnBlur: фокус внутри WebView2 уходит в дочернее окно браузера, поэтому
  ориентируемся на WM_ACTIVATE/проверку foreground окна, не на простой KILLFOCUS.

## Риски
- SSH-меню (kitty) — самый большой рефактор (systemctl динамический + ssh с позиц. курсора).
- hideOnBlur с WebView2 — фокус-нюансы.
- frameless drag/позиционирование.
