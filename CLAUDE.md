# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Общее

**AutoHotkey v2.0** проект — собственный аналог Punto Switcher + горячие клавиши автора. Был мигрирован с v1 на v2. Требует **AHK 2.0.19+**.

Точка входа — `main.ahk` (в корне). Запускается через ярлык `main — ярлык.lnk` → `M:\Sys\AutoHotkey\bin\v2\AutoHotkey64.exe main.ahk`. Для отладки: `run.bat` (с `/ErrorStdOut`). Перезагрузка из работающего скрипта — `CapsLock+R`.

## Архитектура

```
main.ahk                      ; точка входа: глобальные хоткеи + утилиты, потом #Include
├── core/                     ; ядро Punto v2
│   ├── Layout.ahk            ; Lat↔Cyr таблицы, GetActiveLang/Toggle/Convert/SwitchToLang
│   ├── Dictionaries.ahk      ; загрузка ru.bin/en.bin, HasWord, LooksLikeWrongLayout, ClassifyWord
│   ├── AppContext.ahk        ; режим окна (off/no_autoswitch/paste_mode/normal), excluded_apps.json
│   ├── Learning.ahk          ; самообучаемый словарь learned_words.json, threshold
│   ├── History.ahk           ; стек последних действий для Pause/Alt+Pause
│   ├── Input.ahk             ; InputHook v2, буфер слова, SendSilently, debug-log
│   ├── Autoswitch.ahk        ; OnWordEnd → детект → ApplyReplacement / ApplyForceWord
│   └── Punto.ahk             ; оркестратор + регистрация хоткеев Pause/Alt+Pause/Ctrl+Pause/Ctrl+Alt+*
├── features/                 ; функции поверх ядра
│   ├── ForceWords.ahk        ; список слов с фикс. регистром (HTML/Vue/Golang/…)
│   ├── Case.ahk              ; UPPER/lower/Title/Sentence/Toggle над выделением
│   ├── Translit.ahk          ; ru ↔ lat по ГОСТ/МВД/Simple, авто-направление
│   ├── Number2Text.ahk       ; число прописью (с грамматикой)
│   └── PasteRaw.ahk          ; вставка без RTF/HTML-форматирования
├── ui/
│   └── Palette.ahk           ; командная палитра Ctrl+Pause (AHK Gui, fallback)
│                             ; на этапе 4 будет заменено на WebView2 + Vue
├── data/                     ; пользовательское состояние (gitignore для личных)
│   ├── dict/{ru,en}.bin      ; частотные словари 50к слов (UTF-8 текст)
│   ├── excluded_apps.json    ; список исключений по exe
│   ├── force_words.json      ; список форс-слов
│   └── learned_words.json    ; самообучение (gitignored)
├── lib/                      ; внешние зависимости
│   ├── Webview2/             ; thqby/webview2.ahk + ComVar.ahk (для этапа 4)
│   ├── WebView2Loader.dll    ; x64 loader от Microsoft
│   ├── JSON.ahk              ; парсер JSON (thqby)
│   └── Hunspell/             ; исходные частотные словари ru_50k.txt / en_50k.txt
├── tools/
│   ├── build_dict.ahk        ; пересборка data/dict/*.bin из lib/Hunspell/*.txt
│   ├── test_detect.ahk       ; юнит-тест детектора (14/14)
│   ├── test_forcewords.ahk   ; юнит-тест ForceWords (15/15)
│   ├── test_features.ahk     ; юнит-тест Case/Translit/Number2Text (36/36)
│   ├── integration_test.ahk  ; end-to-end в Notepad
│   └── *.bat                 ; обёртки запуска тестов через cmd
├── legacy/                   ; мигрированные на v2 пользовательские модули
│   ├── abbreviations.ahk     ; hotstrings (::квт::kВт и т.д.)
│   ├── GoogleTranslate.ahk   ; открытие translate.google.com (inline-API закрыт)
│   ├── kitty.ahk             ; sysadmin-меню по CapsLock+S
│   ├── Docker.ahk            ; docker/compose/swarm меню CapsLock+D
│   └── … (build/fl/Direct/main-menu/dop_menu/CapsLock_double)
│   └── v1_backup/            ; оригинал на v1 как точка отката (Eval, Punto, Punto2, …)
└── .claude/plans/            ; планы реализации (Plan_001 — миграция и Punto v2)
```

## Хоткеи (актуальные)

| Клавиша | Что делает |
|---|---|
| `CapsLock+R` | Перезагрузить скрипт |
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
| `Win+C` | GraphCalc |
| `Win+Insert` | OBS |
| `Shift+PrintScreen` | ABBYY FineReader ScreenshotReader |

## Логика автопереключения

1. `core/Input.ahk` через `InputHook` копит **буфер** текущего слова (буквы лат/кир, дефис, апостроф). Не-буквенный символ → финализация слова.
2. `core/Autoswitch.OnWordEnd(word, sep)`:
   - **ClassifyWord** определяет язык слова **по символам** (а не по системной раскладке — она часто врёт).
   - Проверка `AppContext.ModeFor()` (off / no_autoswitch / paste_mode / normal).
   - **ForceWords** имеет приоритет: HTML / Vue / Golang всегда в правильном регистре (даже при выключенной Punto).
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
- **AHK v2 ругается на unset variables** через `#Warn All, MsgBox`. У нас в main.ahk поставлено `#Warn All, OutputDebug` — warnings уходят в DebugView, не блокируют выполнение.
- **`A_IPAddress1..4`** в v2 НЕТ. Используем WMI (см. `GetLocalIPv4()` в main.ahk).
- **Однострочное `static M() { body }`** не парсится. Только многострочное тело.
- **`SetDefaultKeyboard` при старте** некоторые приложения показывают плашку «раскладка изменилась». В Punto v2 со старта не вызываем.
- **`ObjBindMethod(Class, "StaticMethod")`** в качестве InputHook callback ненадёжно. Используем явные функции-обёртки (см. `PuntoInput_OnChar`).
- **Чтение текстовых файлов** через `Loop Read` по умолчанию идёт в системной кодировке. Для UTF-8 — явный `FileOpen(path, "r", "UTF-8")`.

## Тесты

```
tools/test_detect.bat       ; детектор: 14/14 PASS
tools/test_forcewords.bat   ; force-words: 15/15 PASS
tools/test_features.bat     ; Case+Translit+Number2Text: 36/36 PASS
tools/integration_test.bat  ; e2e в Notepad — проверяет фактическую автозамену
```

Все `.bat` — обёртки над `AutoHotkey64.exe` через `cmd` (вызов из bash напрямую часто пропускает аргументы). Лог пишется в `tools/<name>.log` (gitignored).

Если меняешь логику детектора/конвертации/раскладки — **обязательно прогнать соответствующий тест** перед коммитом.

## Зависимости

- `lib/JSON.ahk` (thqby/HotKeyIt) — парсер JSON
- `lib/Webview2/` + `lib/WebView2Loader.dll` — для этапа 4 (Vue-палитра)
- `lib/Hunspell/{ru,en}_50k.txt` — частотные списки от hermitdave/FrequencyWords (CC-BY-SA, OpenSubtitles 2018)

## Не-AHK файлы

`answer_history.gcs`, `default.gcl`, `graphcalc.ini` — конфиги внешнего калькулятора GraphCalc (запускается по `Win+C`). Изменяются им автоматически.

## Стиль правок

- **Pure-функции и тесты.** Все нетривиальные алгоритмы (детектор, конвертация, пропись) разделять на чистую логику + GUI-обёртку. Чистая логика — в test'ах.
- **Комментарии на русском**, как в существующем коде.
- **При добавлении новых классов** — статические методы, никакого `new Class()`. State — статические поля.
- **Новые модули** подключать через `#Include` в `main.ahk` в правильном порядке: `lib/` → `core/` → `features/` → `ui/` → `legacy/`.
- **При срабатывании warning'а** в коде — **не глушить через `#Warn ... Off`**, а исправлять. Глобальный `#Warn All, OutputDebug` стоит только в main.ahk для разработки.
- **PuntoForceWords и legacy/abbreviations** — два разных подхода: первое всегда срабатывает (включая выключенную Punto), второе только когда пользователь набрал точное совпадение hotstring. Не путать.
