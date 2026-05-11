# Plan_001 — Punto v2: миграция на AHK v2 + WebView2/Vue UI

## Цель

Переписать репозиторий на AutoHotkey v2 и реализовать собственный аналог PuntoSwitcher с командной палитрой (WebView2 + Vue 3), самообучающимся словарём, текстовыми преобразованиями и системой автозамен.

## Окружение (зафиксировано)

| Компонент | Статус |
|---|---|
| AHK v2 (system) | `C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe` — **2.0.19** ✓ |
| AHK v1 (system) | `C:\Program Files\AutoHotkey\v1.1.37.02\AutoHotkeyU64.exe` — **1.1.37.02** ✓ |
| AHK v2 portable | `M:\Sys\AutoHotkey\bin\v2\` — **2.0-beta.4** ❌ обновить до 2.0.19 |
| AHK v1 portable | `M:\Sys\AutoHotkey\bin_v1\` — **1.1.34.03** ❌ обновить до 1.1.37.02 |
| WebView2 Runtime | 147.0.3912.98 ✓ |
| Node / pnpm | 22.21.1 / 10.24.0 ✓ |
| PuntoSwitcher | установлен, словари и настройки доступны ✓ |

## Архитектура итогового решения

```
AutoHotkey/
├── main.ahk                       — точка входа v2 (#Include всех модулей)
├── core/
│   ├── Input.ahk                  — низкоуровневый хук клавиатуры (InputHook v2)
│   ├── Layout.ahk                 — Get/Toggle раскладки (PostMessage 0x50, поток-aware)
│   ├── Dictionaries.ahk           — загрузка/проверка ru/en словарей (HashSet)
│   ├── Autoswitch.ahk             — детект ошибочной раскладки + автопереключение
│   ├── Learning.ahk               — самообучение по Break-действиям
│   ├── History.ahk                — стек последних действий (для отмены)
│   └── AppContext.ahk             — текущее окно, проверка исключений
├── features/
│   ├── Case.ahk                   — UPPER/lower/Sentence/Title (учитывает «и т.д.»)
│   ├── Translit.ahk              — ru↔translit (двунаправленно)
│   ├── Number2Text.ahk            — число → пропись (русский)
│   ├── PasteRaw.ahk               — вставка без форматирования
│   ├── Translate.ahk              — обёртка Google Translate
│   ├── Replacements.ahk           — статические + динамические автозамены (ДД→время суток)
│   └── ForceWords.ahk             — слова со «всегда правильным» регистром (HTML, Golang…)
├── ui/
│   ├── Palette.ahk                — хост-Gui + WebView2 (на базе thqby/webview2.ahk)
│   ├── Bridge.ahk                 — JSON-мост AHK↔JS
│   └── webview/
│       ├── package.json, vite.config.ts, tsconfig.json
│       ├── src/
│       │   ├── main.ts
│       │   ├── App.vue            — корневой компонент палитры
│       │   ├── components/
│       │   │   ├── CommandList.vue
│       │   │   ├── SearchInput.vue
│       │   │   ├── DetailPanel.vue
│       │   │   └── SubmenuLayer.vue
│       │   ├── composables/
│       │   │   ├── useBridge.ts
│       │   │   └── useCommands.ts
│       │   └── styles/            — BEM + SCSS
│       └── dist/                  — собранный билд (грузится в WebView2)
├── data/
│   ├── dict/
│   │   ├── ru.bin                 — Hunspell ru_RU → бинарный hashset (~3 МБ)
│   │   └── en.bin                 — top-100k английских слов (~1 МБ)
│   ├── learned_words.json         — самообучаемый словарь
│   ├── replacements.json          — пользовательские автозамены
│   ├── excluded_apps.json         — исключения по ahk_exe
│   ├── force_words.json           — HTML, Golang, PHP…
│   └── settings.json              — глобальные настройки
├── lib/
│   ├── Webview2/                  — thqby/webview2.ahk + ComVar.ahk
│   ├── WebView2Loader.dll         — нативный loader из Microsoft SDK
│   ├── JSON.ahk                   — cocobelgica/JSON (v2-форк)
│   └── Hunspell/                  — словарь-источник (только для билда dict/*.bin)
├── tools/
│   ├── build_dict.ahk             — Hunspell .dic → ru.bin
│   ├── import_punto.ahk           — миграция настроек из PuntoSwitcher
│   └── update_ahk.ps1             — выкачка свежих AHK в M:\Sys\AutoHotkey\
├── legacy/                        — мигрированные старые модули
│   ├── kitty.ahk, Docker.ahk, abbreviations.ahk, GoogleTranslate.ahk,
│   ├── build.ahk, fl.ahk, Direct.ahk, main-menu.ahk, dop_menu.ahk
│   └── CapsLock_double.ahk        — переключение раскладки одной CapsLock
└── .claude/plans/Plan_001.md      — этот файл
```

## Этапы (всё в одной ветке `master`)

### Этап 0. Подготовка инфраструктуры (½ дня)

- [ ] Обновить AHK v2.0.19 в `M:\Sys\AutoHotkey\bin\v2\` (скачать zip с autohotkey.com).
- [ ] Обновить AHK v1.1.37.02 в `M:\Sys\AutoHotkey\bin_v1\` (для совместимости со старыми проектами).
- [ ] Удалить устаревшую папку `M:\Sys\AutoHotkey\bin\v2.0-beta.4\`.
- [ ] Создать структуру каталогов проекта (`core/`, `features/`, `ui/`, `data/`, `lib/`, `tools/`, `legacy/`).
- [ ] Скачать `thqby/webview2.ahk` (latest) → `lib/Webview2/`.
- [ ] Скачать `WebView2Loader.dll` (x64) из NuGet `Microsoft.Web.WebView2` → `lib/`.
- [ ] Скачать `JSON.ahk` v2-форк → `lib/`.
- [ ] Скачать Hunspell `ru_RU.dic`, английский top-100k → `lib/Hunspell/`.

**Блокер?** Нет. Сетевые загрузки.

### Этап 1. Миграция legacy на v2 (1-2 дня)

Механический перевод существующих модулей на синтаксис v2. Каждый модуль — отдельный коммит.

- [ ] `main.ahk` → v2: `Send,`→`Send`, `%var%`→`var`, метки→функции, `Menu, …`→`Menu()` API, `Gui, …`→`Gui()`, `SetTimer label`→`SetTimer Fn`, hotstrings оставляем но макросы в `{}`.
- [ ] `abbreviations.ahk` → v2 (hotstrings без изменений по логике).
- [ ] `GoogleTranslate.ahk` → v2 (WinHttpRequest через `ComObject`).
- [ ] `kitty.ahk` → v2 (динамическое меню через `Menu()` + `Func.Bind`→`ObjBindMethod` v2-стиль).
- [ ] `Docker.ahk` → v2.
- [ ] `main-menu.ahk`, `dop_menu.ahk`, `Direct.ahk`, `build.ahk`, `fl.ahk` → v2.
- [ ] `Eval.ahk` → v2 (большая либа, могут быть нюансы — отложим если не нужна сразу).
- [ ] `CapsLock_double.ahk` → v2.
- [ ] **Удалить из репозитория**: `main1.ahk`, `Old.ahk`, `Punto.ahk`, `Punto2.ahk`, `CapsLock.ahk` — заменены новой архитектурой.
- [ ] Проверить: ярлык `main — ярлык.lnk` запускается через v2, все хоткеи работают.

**Блокер?** `Eval.ahk` (400+ строк, динамическое выполнение) может потребовать существенной правки. Если съест больше дня — оставить v1-копию рядом и подключать через отдельный процесс.

### Этап 2. Ядро Punto v2 (3-4 дня)

#### 2.1. Захват ввода (`core/Input.ahk`)
- [ ] InputHook v2 c полным набором `EndKeys` (как в `Punto.ahk` v1).
- [ ] Буфер «текущее слово» (ресет на Space/Enter/Tab/Esc/punct/стрелки/Backspace/мышь).
- [ ] Стек «последние N слов с координатами» (для Break-операций).

#### 2.2. Раскладка (`core/Layout.ahk`)
- [ ] `GetActiveLayout()` через `GetKeyboardLayout` + workaround для `ConsoleWindowClass`.
- [ ] `ToggleLayout()` через `PostMessage 0x50` (адаптировать из v1-кода).
- [ ] Преобразование текста между Lat/Cyr (словари из `Punto.ahk`).

#### 2.3. Словари (`core/Dictionaries.ahk`)
- [ ] Загрузка `data/dict/ru.bin` и `en.bin` в `Map` при старте.
- [ ] Билд-скрипт `tools/build_dict.ahk`: Hunspell `.dic` → нормализованный `Map`-сериализованный бинарь.
- [ ] Функция `IsWord(text, lang)` — O(1).
- [ ] `LooksLikeWrongLayout(word)` — комбинация:
  - (а) запрещённые биграммы (`ыь`, `жщ`, `яы` в начале и т.д.) — дёшевый фильтр;
  - (б) если в текущей раскладке слово отсутствует и в перевёрнутой существует — точный сигнал.

#### 2.4. Автопереключение (`core/Autoswitch.ahk`)
- [ ] На триггер (Space/Enter/Tab/punct) — взять последнее слово, проверить.
- [ ] Если ошибка — `BackSpace×N` → `ToggleLayout` → `SendInput {Raw}…исправленное…` → восстановить разделитель.
- [ ] Записать действие в `History` для возможного отката.
- [ ] **Триггеры на исследование**: только Space или ещё Enter/Tab/.?,! — оставлю настраиваемым.

#### 2.5. История и отмена (`core/History.ahk`)
- [ ] `Break` (одиночное): откатить последнее автопереключение **либо** переключить раскладку последнего слова, если автопереключения не было. Логика «либо/либо» определяется содержимым `History`.
- [ ] `Alt+Break`: глобальный toggle автопереключения (трей-иконка + popup).
- [ ] `Ctrl+Break`: открыть командную палитру (этап 4).

#### 2.6. Самообучение (`core/Learning.ahk`)
- [ ] Файл `data/learned_words.json`: `{ "слово": { "count": N, "lang": "ru|en", "lastSeen": "..." } }`.
- [ ] При каждом Break-исправлении: инкремент счётчика для слова в **правильной** раскладке.
- [ ] При отмене автопереключения (Break сразу после автозамены): инкремент для слова в **оставленной** раскладке.
- [ ] При `count >= 2`: слово добавляется во вспомогательный whitelist (in-memory), который имеет приоритет над общим словарём.
- [ ] Лимит файла: 50 000 слов, при превышении — выкидываются с минимальным `count` и старым `lastSeen`.

#### 2.7. Контекст приложений (`core/AppContext.ahk`)
- [ ] Текущее окно: `WinGetProcessName`, `WinGetClass`, путь к exe.
- [ ] Чтение `data/excluded_apps.json` — поведения: `off` (полностью выключить), `no_autoswitch` (только автопереключение выкл), `paste_mode` (Send через clipboard).
- [ ] Дефолты импортированы из `default-conf.json` PuntoSwitcher (игры в `unhook`, мессенджеры в `use_paste`, Office в `use_hotkey_switching`).

**Блокер?** Большое тестовое покрытие требуется только для (2.3-2.4) — словари и автопереключение. Тесты проведу вручную на реальном вводе в Sublime/браузере/терминале.

### Этап 3. Текстовые операции и автозамены (1½ дня)

- [ ] `features/Case.ahk` — 4 функции: UPPER, lower, Sentence (с «не-разделителями» `и т.д.`, `т.е.`, `т.п.`, `и т.п.`, `и т.д.`, `др.`, `пр.`, `см.`, …), Title. После применения восстанавливать выделение через `Send +{Right N}` или `+{Left N}` в зависимости от направления.
- [ ] `features/Translit.ahk` — таблица GOST 7.79-2000 (расширенная) + обратное преобразование. Восстановление выделения.
- [ ] `features/Number2Text.ahk` — пропись на русском (через словарь разрядов; рубли/копейки как опция).
- [ ] `features/PasteRaw.ahk` — `Send ^v` после `ClipboardAll`→текст. Сразу.
- [ ] `features/Translate.ahk` — обёртка над уже существующей `GoogleTranslate.ahk` (после миграции на v2).
- [ ] `features/Replacements.ahk` — таблица «ключ→строка|функция». Функции-замены:
  - `ДД` → `Добрый день/вечер/утро/ночь` по `A_Hour`.
  - `сейчас` → текущее время.
  - `дата` → текущая дата.
  - `email` → vruzin@ya.ru / vruzin@proton.me (выбор).
  - …расширяется через UI.
- [ ] `features/ForceWords.ahk` — список «как написано»: `HTML`, `Golang`, `PHP`, `JavaScript`, `TypeScript`, `CSS`, `SCSS`, `HTTP`, `HTTPS`, `JSON`, `XML`, `SQL`, `API`, `URL`, `UUID`, `JWT`, `OAuth`, `REST`, `gRPC`, `Vue`, `React`, `Node`, `Docker`, `Git`, `GitHub`, `GitLab`. Дополняется через UI. Срабатывает даже при выключенном автопереключении.

### Этап 4. Командная палитра (Vue + WebView2) (4-5 дней)

#### 4.1. WebView2 хост (`ui/Palette.ahk`, `ui/Bridge.ahk`)
- [ ] Borderless `Gui` поверх всех окон, по центру активного монитора. Скруглённые углы Win11 через `DwmSetWindowAttribute`.
- [ ] Скрытое WebView2-окно держим прогретым после первого старта.
- [ ] Загружаем `ui/webview/dist/index.html` через `file:///` или встроенный `SetVirtualHostNameToFolderMapping` (быстрее, без проблем с CORS).
- [ ] JSON-мост: AHK→JS через `PostWebMessageAsJson`, JS→AHK через `OnWebMessageReceived`.

#### 4.2. Vue 3 палитра (`ui/webview/`)
- [ ] Vite + Vue 3 + TS, Composition API. Кастомный CSS (BEM+SCSS).
- [ ] Компонент `App.vue`: search input по центру, под ним список команд.
- [ ] Список элементов: `{ shortcut, title, description, hotkey, type, icon? }`. `type`: `replacement | function | submenu | force_word | external`.
- [ ] Фильтрация: fuzzy-match по `shortcut` + `title` (lib: `fuse.js` или ручной алгоритм).
- [ ] **Слои-подменю**: элемент с `type:submenu` при выборе раскрывает следующий уровень (как `kitty.ahk` systemctl-меню), вверху — breadcrumb. Возврат — `Esc` / `Backspace` (при пустой строке).
- [ ] **Hotkey-навигация в подменю**: цифры/буквы из колонки «hotkey» — мгновенное проваливание.
- [ ] Detail-panel справа: при наведении/выборе показывает значение замены, превью функции (например, что вставит `ДД` сейчас), горячую клавишу.

#### 4.3. Команды-источники
- [ ] При показе палитры AHK шлёт в JS список доступных команд (replacements + features + force_words + submenus).
- [ ] При выборе — JS шлёт в AHK `{action: "execute", id: "..."}`. AHK скрывает окно, восстанавливает фокус, выполняет.

#### 4.4. Управление списком автозамен через UI
- [ ] Отдельная «страница» в палитре: список замен с inline-редактированием, кнопка «добавить».
- [ ] Изменения сохраняются в `data/replacements.json`, hot-reload в AHK без рестарта.

**Блокер?** Интероп AHK v2 ↔ WebView2 — самый рискованный момент. Закладываю +1 день буфера. План Б: если `thqby/webview2.ahk` нестабилен — fallback на нативный Gui v2 (вариант A из обсуждения).

### Этап 5. Импорт из PuntoSwitcher (½ дня)

- [ ] `tools/import_punto.ahk`:
  - читать `preferences.xml` → `excluded_apps.json` (поле `ProgramsExceptions`);
  - читать `default-conf.json` → пополнить `excluded_apps.json` дефолтными исключениями (игры/Office/мессенджеры);
  - читать `user.dic` → попытаться декодировать (`_PE` / `_BE` маркеры) и положить в `replacements.json`;
  - попробовать декодировать `replace.dat` (cp1251/UTF-16). Если получится — импортнуть; если нет — пропустить.
- [ ] При импорте — diff и подтверждение пользователем перед записью.

### Этап 6. Финальная сборка и переключение (½ дня)

- [ ] Прогон полного сценария: запуск, ввод текста в разных приложениях, проверка автопереключения, Break, Alt+Break, Ctrl+Break, выделение+регистр, transliterate, автозамены, force-words.
- [ ] Обновить `CLAUDE.md` под новую архитектуру (новые пути, v2 синтаксис).
- [ ] Обновить `README.md`.
- [ ] **Перед стартом — закрыть/удалить PuntoSwitcher**, иначе двойной перехват клавиш.

## Оценка по времени

| Этап | Дни (нетто) |
|---|---|
| 0. Инфраструктура | 0.5 |
| 1. Миграция legacy | 1.5 |
| 2. Ядро Punto | 3.5 |
| 3. Текстовые операции | 1.5 |
| 4. UI (Vue + WebView2) | 5 |
| 5. Импорт из PuntoSwitcher | 0.5 |
| 6. Финал | 0.5 |
| **ИТОГО** | **≈ 13 рабочих дней** |

Самые длинные/блокирующие: **Этап 4** (UI с WebView2) и **Этап 2** (ядро Punto). Этапы 0, 1, 3, 5 — параллелизуемы.

## Открытые вопросы (нужны ответы перед стартом)

1. **PuntoSwitcher**: его деинсталлировать перед запуском нашего Punto v2 или просто временно отключать через трей при тестах? Я **рекомендую закрывать только на время разработки**, удаление — после полной приёмки.
2. **Словари**: подтверждаешь Hunspell `ru_RU` + английский top-100k? Или хочешь другой источник?
3. **Триггеры автопереключения**: только `Space`, или ещё `Enter`/`Tab`/`,.;!?`? Я **по умолчанию беру все**, в UI настройка on/off.
4. **Самообучение порог**: «2 раза» — финально, или сделать настраиваемым (1-5)? Я **по умолчанию ставлю 2 и настраиваемое в UI**.
5. **Translit**: ГОСТ 7.79-2000 (системно), система МВД (паспортная) или Google-style? Я **по умолчанию ставлю ГОСТ + переключатель**.
