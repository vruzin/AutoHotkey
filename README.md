# Punto v2 + личные хоткеи

Замена Punto Switcher + персональные хоткеи на AutoHotkey 2.0.

## Что есть

**Punto v2** — собственный автопереключатель раскладки:
- Автоматическое исправление слов в неправильной раскладке (`ghbdtn` → `привет`).
- Самообучаемый словарь (Pause-исправления запоминаются).
- Per-app исключения (игры, Office, Photoshop, Warp).
- Force-words: HTML, Vue, Golang, JWT, gRPC и др. всегда в правильном регистре.
- Текстовые операции: UPPER/lower/Title/Sentence, транслит (ГОСТ/МВД/Simple), число прописью, paste-raw.
- Командная палитра по `Ctrl+Pause`.

**Legacy-хоткеи** (личные): CapsLock+ {A,B,D,F,H,I,K,R,S,W,Z,1-4} — меню Docker/Kitty/Vivaldi/IDE и т.д.

## Запуск

1. Установить AutoHotkey 2.0+ в `M:\Sys\AutoHotkey\bin\v2\` (или системно).
2. Запустить через ярлык `main — ярлык.lnk` (или `run.bat` для отладки).
3. В трее появится иконка-молния — Punto работает.
4. **Перед запуском** закрыть PuntoSwitcher через трей (если установлен).

## Основные горячие клавиши

| Клавиша | Что делает |
|---|---|
| `Pause` | Откат автозамены / конвертация текущего слова |
| `Alt+Pause` | Punto: ON/OFF (иконка трея меняется) |
| `Ctrl+Pause` | **Открыть командную палитру** |
| `Ctrl+Alt+D` | Диагностика Punto |
| `Ctrl+Alt+L` | Запись событий в `data/punto_events.log` (для отладки) |
| `Ctrl+Shift+Alt+U/L/S/T/Y` | UPPER / lower / Sentence / Title / Toggle |
| `Ctrl+Shift+Alt+J` | Транслит ru↔lat |
| `Ctrl+Shift+Alt+N` | Число прописью |
| `Ctrl+Shift+Alt+V` | Paste без форматирования |
| `Ctrl+Shift+Alt+R` | Сбросить самообучение |

Полный список — `CLAUDE.md` и в самой палитре.

## Структура

См. `CLAUDE.md` — там подробно описана архитектура `core/ features/ ui/ data/ lib/ tools/ legacy/`.

## Тесты

```
tools\test_detect.bat
tools\test_forcewords.bat
tools\test_features.bat
tools\integration_test.bat
```

## Если что-то не работает

- **Автозамена не срабатывает**: нажми `Ctrl+Alt+L` (включить лог), набери проблемное слово, открой `data/punto_events.log` — увидишь почему детектор пропустил.
- **«Известное» слово не заменяется**: сбрось `Ctrl+Shift+Alt+R`, либо вручную удали `data/learned_words.json`.
- **Раскладка не переключается в каком-то приложении**: открой палитру `Ctrl+Pause` → «Без автозамены для этого окна» — Punto не будет туда лезть.

Подробнее в `CLAUDE.md`.
