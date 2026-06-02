# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Общее

**AutoHotkey v2.0** проект — собственный аналог Punto Switcher + горячие клавиши автора. Был мигрирован с v1 на v2. Требует **AHK 2.0.19+**.

Точка входа — `main.ahk` (в корне). Запускается через ярлык `main — ярлык.lnk` → `M:\Sys\AutoHotkey\bin\v2\AutoHotkey64.exe main.ahk`. Для отладки: `run.bat` (с `/ErrorStdOut`). Перезагрузка из работающего скрипта — `CapsLock+R`.

## Архитектура

```
main.ahk                      ; точка входа: глобальные хоткеи + утилиты, потом #Include
├── core/                     ; ядро Punto v2 + инфраструктура
│   ├── Layout.ahk            ; Lat↔Cyr таблицы, GetActiveLang/Toggle/Convert/SwitchToLang
│   ├── Dictionaries.ahk      ; загрузка ru.bin/en.bin, HasWord, LooksLikeWrongLayout, ClassifyWord
│   ├── AppContext.ahk        ; режим окна (off/no_autoswitch/paste_mode/normal), excluded_apps.json
│   ├── Learning.ahk          ; самообучаемый словарь learned_words.json, threshold
│   ├── History.ahk           ; стек последних действий для Pause/Alt+Pause
│   ├── Input.ahk             ; InputHook v2, буфер слова, SendSilently, debug-log
│   ├── Autoswitch.ahk        ; OnWordEnd → детект → ApplyReplacement / ApplyForceWord
│   ├── Punto.ahk             ; оркестратор + регистрация Pause/Alt+Pause/Ctrl+Pause/text.*
│   ├── Settings.ahk          ; PuntoSettings — пользовательские настройки (settings.json)
│   ├── FeatureRegistry.ahk   ; реестр управляемых хоткеев/фич: On/Off в рантайме + persist
│   ├── MenuData.ahk          ; меню как данные: Build (AHK Menu) + Flatten (для лаунчера)
│   └── Commands.ahk          ; единый список команд лаунчера (хоткеи + пункты меню)
├── features/                 ; функции поверх ядра
│   ├── ForceWords.ahk        ; список слов с фикс. регистром (HTML/Vue/Golang/…)
│   ├── Case.ahk              ; UPPER/lower/Title/Sentence/Toggle над выделением
│   ├── Translit.ahk          ; ru ↔ lat по ГОСТ/МВД/Simple, авто-направление
│   ├── Number2Text.ahk       ; число прописью (с грамматикой)
│   ├── PasteRaw.ahk          ; вставка без RTF/HTML-форматирования
│   ├── Mic.ahk               ; mute/unmute микрофона (Core Audio API), Ctrl+Volume_Mute
│   └── HotkeyHuman.ahk       ; HotkeyToHuman: ^+!u → Ctrl+Shift+Alt+U и т.п.
├── ui/
│   ├── Palette.ahk           ; командная палитра Ctrl+Pause (AHK Gui, fallback)
│   ├── WebApp.ahk            ; фреймворк Vue-приложений в WebView2 (мост AHK↔JS, frameless, hideOnBlur)
│   ├── Settings.ahk          ; лаунчер (Alfred-стиль) + интеграция с треем
│   └── apps/                 ; Vue-приложения (HTML/CSS/JS отдельно от AHK)
│       ├── _shared/bridge.js ; единый JS-мост: ahk.call / getInitData / onPush
│       └── settings/         ; index.html + app.js + style.css лаунчера
├── data/                     ; пользовательское состояние (gitignore для личных)
│   ├── dict/{ru,en}.bin      ; частотные словари 50к слов (UTF-8 текст)
│   ├── excluded_apps.json    ; список исключений по exe
│   ├── force_words.json      ; список форс-слов
│   ├── learned_words.json    ; самообучение (gitignored)
│   ├── settings.json         ; настройки + features.{groups,hotkeys}
│   └── webview2/             ; профиль WebView2 (gitignored)
├── lib/                      ; внешние зависимости
│   ├── Webview2/             ; thqby/WebView2.ahk + ComVar.ahk + Promise.ahk
│   ├── ComVar.ahk            ; дубль для относит. #Include внутри WebView2.ahk
│   ├── Promise.ahk           ; дубль (WebView2.ahk делает #Include ..\Promise.ahk)
│   ├── WebView2Loader.dll    ; x64 loader от Microsoft
│   ├── vue.global.prod.js    ; Vue 3 (global build) локально, офлайн
│   ├── JSON.ahk              ; парсер JSON (thqby)
│   └── Hunspell/             ; исходные частотные словари ru_50k.txt / en_50k.txt
├── tools/
│   ├── build_dict.ahk        ; пересборка data/dict/*.bin из lib/Hunspell/*.txt
│   ├── test_detect.ahk       ; юнит-тест детектора (14/14)
│   ├── test_forcewords.ahk   ; юнит-тест ForceWords (15/15)
│   ├── test_features.ahk     ; юнит-тест Case/Translit/Number2Text (36/36)
│   ├── test_registry.ahk     ; юнит-тест FeatureRegistry (12/12)
│   ├── test_hotkey_human.ahk ; юнит-тест HotkeyToHuman (18/18)
│   ├── integration_test.ahk  ; end-to-end в Notepad
│   └── *.bat                 ; обёртки запуска тестов через cmd
├── legacy/                   ; мигрированные на v2 пользовательские модули
│   ├── abbreviations.ahk     ; hotstrings (::квт::kВт и т.д.)
│   ├── GoogleTranslate.ahk   ; открытие translate.google.com (inline-API закрыт)
│   ├── kitty.ahk             ; sysadmin-меню по CapsLock+S (SshMenuData)
│   ├── Docker.ahk            ; docker/compose/swarm меню CapsLock+D (DockerMenuData)
│   ├── … (build/fl/Direct/main-menu/dop_menu/CapsLock_double)
│   └── v1_backup/            ; оригинал на v1 как точка отката (Eval, Punto, Punto2, …)
└── .claude/plans/            ; планы реализации (Plan_001 — миграция и Punto v2)
```

## Хоткеи (актуальные)

| Клавиша | Что делает |
|---|---|
| `CapsLock+R` | Перезагрузить скрипт |
| `CapsLock+Shift` | Открыть лаунчер (поиск команд) |
| `CapsLock+I` | Внешний + локальные IP в ToolTip |
| `CapsLock+1..4` | Vivaldi с разными профилями |
| `CapsLock+A/S/D/K/Z/B/F/W/H/G` | Меню (Punto/sysadmin/Docker/KiTTY/git/build/FL/Yandex Direct/InputBox/пароль) |
| `Pause` | Punto: откатить автозамену или конвертировать раскладку текущего слова |
| `Alt+Pause` | Punto: ON/OFF |
| `Ctrl+Pause` | Открыть командную палитру |
| `Ctrl+Alt+D` | Диагностика Punto (MsgBox со снимком состояния) |
| `Ctrl+Alt+L` | Включить/выключить запись событий в `data/punto_events.log` |
| `Ctrl+Shift+Alt+U/L/S/T/Y` | UPPER / lower / Sentence / Title / Toggle case |
| `Ctrl+Shift+Alt+J` | Транслит ru↔lat (авто-направление) |
| `Ctrl+Shift+Alt+N` | Число в текст прописью |
| `Ctrl+Shift+Alt+V` | Вставить без форматирования |
| `Ctrl+Shift+Alt+R` | Сбросить самообучаемый словарь |
| `Ctrl+Volume_Mute` | Переключить микрофон вкл/выкл (default capture device) |
| `Win+C` | GraphCalc |
| `Win+Insert` | OBS |
| `Shift+PrintScreen` | ABBYY FineReader ScreenshotReader |
| **Клик по иконке в трее** | **Открыть лаунчер** |

> Большинство хоткеев регистрируются через `FeatureRegistry` и могут быть
> отключены в лаунчере (режим настроек по шестерёнке). Базовые `CapsLock`
> (смена раскладки), `CapsLock+R` (Reload), Pause-группа Punto и контекстные
> `#HotIf` — не отключаются.

## Лаунчер (WebView2 + Vue, Alfred-стиль)

Открывается одинарным левым кликом по иконке в трее и хоткеем `CapsLock+Shift`.
Безрамочное окно по центру, прячется по `Esc` и при потере фокуса (hideOnBlur).

- **Режим «Запуск»** (по умолчанию): поле поиска сверху, фаззи-фильтр по всем
  функциям И пунктам меню (`Docker › docker ps`). `↑↓` — навигация, `Enter` —
  выполнить, окно прячется. Клавиши показываются по-человечески (`Ctrl+Shift+Alt+U`).
- **Режим «Настройки»** (шестерёнка ⚙ справа внизу): те же отфильтрованные строки
  с галочками. Клик по галочке вкл/выкл хоткея в рантайме (через `FeatureRegistry`,
  сохраняется в `settings.json`). Пункты меню (`menuitem`) галочкой не управляются.

**Как устроено:**

- `core/FeatureRegistry.ahk` — реестр хоткеев/фич. `Register(id, group, label, key,
  fn)` для хоткея (реальное `Hotkey On/Off`), `RegisterFeature` для фичи без
  клавиши (модуль сам зовёт `IsActive(id)` — так для `punto.forcewords`). `id`
  содержат точки (`text.upper`) → состояние хранится ПЛОСКИМИ ключами в под-Map
  `features.hotkeys`/`features.groups` (не через точечные пути PuntoSettings).
- `core/MenuData.ahk` — меню как данные. `Build(массив)` строит родное AHK Menu
  (рекурсивно; `sub` может быть готовым `Menu`, напр. динамический systemctl);
  `Flatten(массив, prefix)` даёт плоский список `Map(label "Группа › пункт", fn)`
  для лаунчера. Все legacy-меню теперь data-driven: `XxxMenuData()` возвращает
  массив, `ShowXxxMenu(*)` делает `MenuData.Build(XxxMenuData()).Show()`.
- `core/Commands.ahk` — `Snapshot()` = хоткеи/фичи из FeatureRegistry (клавиша
  через `HotkeyToHuman`) + пункты меню через `MenuData.Flatten` по `MenuSources()`
  (docker/ssh/build/fl/dop/main; id вида `menu.docker.3`). `Run(id)` выполняет fn.
- `ui/WebApp.ahk` — фреймворк. Опции `frameless` (Gui `-Caption`) и `hideOnBlur`
  (таймер сверяет foreground-окно через `GetAncestor`/`GA_ROOT`, т.к. фокус уходит
  в дочернее окно WebView2). `MoveFocus(0)` после показа — чтобы поле поиска ловило
  ввод. Пути от `A_LineFile` (корень проекта), не `A_ScriptDir`.
- `ui/Settings.ahk` — `SettingsWindow` (лаунчер) поверх WebApp: обработчики
  `getData`→Commands.Snapshot, `run`→Commands.Run, `toggle`→FeatureRegistry,
  `hide`. `SettingsTray_Init()` — перехват `OnMessage(0x404)`, левый клик
  `WM_LBUTTONUP=0x202` → окно.
- `ui/apps/settings/` — Vue 3 SPA (`app.js` с фаззи-поиском), `index.html`,
  `style.css` (тёмная тема). Общий мост — `ui/apps/_shared/bridge.js`.

**Добавить новое Vue-приложение:** создать `ui/apps/<имя>/{index.html, app.js,
style.css}` (index подключает `../../../lib/vue.global.prod.js` и
`../_shared/bridge.js`), затем в AHK: `a := WebApp("<имя>")`, `a.On(...)`,
`a.Show(data)`. В Vue: `await ahk.call(action, payload)`, `ahk.getInitData()`,
`ahk.onPush(cb)`.

## Логика автопереключения

1. `core/Input.ahk` через `InputHook` копит **буфер** текущего слова (буквы лат/кир, дефис, апостроф). Не-буквенный символ → финализация слова.
2. `core/Autoswitch.OnWordEnd(word, sep)`:
   - **ClassifyWord** определяет язык слова **по символам** (а не по системной раскладке — она часто врёт).
   - Проверка `AppContext.ModeFor()` (off / no_autoswitch / paste_mode / normal).
   - **ForceWords** имеет приоритет: HTML / Vue / Golang всегда в правильном регистре (даже при выключенной Punto); проверяется `FeatureRegistry.IsActive("punto.forcewords")`.
   - **Learning.IsKnown** — если пользователь ≥2 раз Pause-исправлял это слово, доверяем.
   - **Dict.LooksLikeWrongLayout**: слово отсутствует в своём словаре И существует после конвертации в противоположный — wrong.
   - При `wrong=true` и триггер-сепараторе (` .,;:!?)]}>"'`) — BS×(len+sep) → SwitchToLang → SendText.
   - Запись в `History`.
3. `Pause` (`HandleBreak`):
   - Если буфер не пуст → конвертировать текущее слово (`ConvertCurrentWord`).
   - Иначе если есть «свежая» автозамена (≤3 сек) → откат (`UndoLastAutoswitch`).
   - Иначе конвертировать последнее слово из истории (`ConvertLastWord`).

## Правила-ловушки AHK v2

- **Имена переменных case-insensitive.** `json := JSON.stringify(...)` ломается («json не присвоен»). Переименовывать локальные.
- **Операторы `=` и `!=` тоже case-insensitive.** Для проверки регистра — `==` и `!==`. Без этого Translit Backward не сохраняет регистр.
- **`Map.CaseSense := false` только на пустом Map.** Ставить **до** заполнения.
- **AHK v2 ругается на unset variables** через `#Warn All, MsgBox`. У нас в main.ahk стоит `#Warn All, OutputDebug` — warnings уходят в DebugView, не блокируют выполнение.
- **`A_IPAddress1..4`** в v2 НЕТ. Используем WMI (см. `GetLocalIPv4()` в main.ahk).
- **Однострочное `static M() { body }`** не парсится. Только многострочное тело.
- **`SetDefaultKeyboard` при старте** некоторые приложения показывают плашку «раскладка изменилась». В Punto v2 со старта не вызываем.
- **`ObjBindMethod(Class, "StaticMethod")`** в качестве InputHook callback ненадёжно. Используем явные функции-обёртки (см. `PuntoInput_OnChar`).
- **Чтение текстовых файлов** через `Loop Read` по умолчанию идёт в системной кодировке. Для UTF-8 — явный `FileOpen(path, "r", "UTF-8")`.
- **Управляемые хоткеи — только через `FeatureRegistry.Register(...)`**, не директивной формой `key::`. Обработчик — именованная функция с `(*)` (годится для `Hotkey()`). Директивные `key::` нельзя вкл/выкл из лаунчера.
- **`PuntoSettings.Get/Set` трактуют `.` как разделитель пути.** Для ключей с точкой внутри (id хоткеев `text.upper`) — плоские ключи в под-Map (см. `FeatureRegistry._Section`).
- **`#Include` относителен папке включающего файла.** `WebView2.ahk` делает `#Include ..\ComVar.ahk` и `..\Promise.ahk` → ожидает их в `lib\`. Поэтому в `lib\` лежат дубли (оригиналы — в `lib\Webview2\`).
- **Пути в `ui/WebApp.ahk` — от `A_LineFile`, не `A_ScriptDir`.** Иначе при запуске вспомогательного скрипта из `tools\` WebView2 ищет loader/html в `tools\…` и падает «Failed to load DLL».
- **`WebView2Loader.dll` лежит в `lib\`**, а библиотека по умолчанию ищет в `lib\Webview2\64bit\`. Путь к loader передаётся в `CreateControllerAsync(...)` явно.
- **SendKeys/автоматизация не доходит до поля ввода WebView2** (оно в отдельном процессе). Тестировать ввод в лаунчере — вручную.
- **Меню — единый источник данных.** Не добавлять пункты императивно в `ShowXxxMenu`; редактировать `XxxMenuData()` — оттуда строится и AHK-меню, и лаунчер.

## Тесты

```
tools/test_detect.bat        ; детектор: 14/14 PASS
tools/test_forcewords.bat    ; force-words: 15/15 PASS
tools/test_features.bat      ; Case+Translit+Number2Text: 36/36 PASS
tools/test_registry.bat      ; FeatureRegistry: 12/12 PASS
tools/test_hotkey_human.bat  ; HotkeyToHuman: 18/18 PASS
tools/integration_test.bat   ; e2e в Notepad — проверяет фактическую автозамену
```

Все `.bat` — обёртки над `AutoHotkey64.exe` через `cmd` (вызов из bash напрямую часто пропускает аргументы). Лог пишется в `tools/<name>.log` (gitignored).

Если меняешь логику детектора/конвертации/раскладки/реестра — **обязательно прогнать соответствующий тест** перед коммитом.

## Зависимости

- `lib/JSON.ahk` (thqby/HotKeyIt) — парсер JSON
- `lib/Webview2/` (`WebView2.ahk` + `ComVar.ahk` + `Promise.ahk`) + `lib/WebView2Loader.dll` — WebView2 для лаунчера
- `lib/vue.global.prod.js` — Vue 3 (global build) локально, офлайн
- `lib/Hunspell/{ru,en}_50k.txt` — частотные списки от hermitdave/FrequencyWords (CC-BY-SA, OpenSubtitles 2018)

## Не-AHK файлы

`answer_history.gcs`, `default.gcl`, `graphcalc.ini` — конфиги внешнего калькулятора GraphCalc (запускается по `Win+C`). Изменяются им автоматически.

## Стиль правок

- **Pure-функции и тесты.** Все нетривиальные алгоритмы (детектор, конвертация, пропись, HotkeyToHuman) разделять на чистую логику + GUI-обёртку. Чистая логика — в test'ах.
- **Комментарии на русском**, как в существующем коде.
- **При добавлении новых классов** — статические методы, никакого `new Class()`. State — статические поля. (Исключение: `WebApp` — экземпляры, т.к. приложений несколько.)
- **Новые модули** подключать через `#Include` в `main.ahk` в правильном порядке: `lib/` → `core/` → `features/` → `ui/` → `legacy/`. `core/Commands.ahk` — после legacy (зависит от `*MenuData`).
- **При срабатывании warning'а** в коде — **не глушить через `#Warn ... Off`**, а исправлять. Глобальный `#Warn All, OutputDebug` стоит только в main.ahk для разработки.
- **PuntoForceWords и legacy/abbreviations** — два разных подхода: первое всегда срабатывает (включая выключенную Punto), второе только когда пользователь набрал точное совпадение hotstring. Не путать.
