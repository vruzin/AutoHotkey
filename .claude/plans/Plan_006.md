# Plan_006 — Горячая клавиша Mute/Unmute микрофона

## Задача
Сделать переключение микрофона (вкл/выкл) по `Ctrl + Volume_Mute` (медиа-клавиша Mute с зажатым Ctrl).

## Технический выбор
- Управление через **Windows Core Audio API** (`IMMDeviceEnumerator` →
  `GetDefaultAudioEndpoint(eCapture)` → `IAudioEndpointVolume`) — работает с
  устройством записи **по умолчанию**, то есть с тем микрофоном, что выбран в
  Windows. Без внешних зависимостей (nircmd и т.п.).
- `^Volume_Mute` не конфликтует с обычным `Volume_Mute` (тот продолжит мьютить
  колонки), т.к. перехватывается только комбинация с Ctrl.

## Подзадачи
- [ ] 1. Создать `features/Mic.ahk` — класс `Mic`:
      - [ ] `_GetVolumePtr()` — получить IAudioEndpointVolume default capture device
      - [ ] `GetMute()` / `SetMute(state)` / `Toggle()`
      - [ ] `Notify(muted)` — ToolTip + звуковой сигнал состояния
- [ ] 2. Подключить `#Include features\Mic.ahk` в `main.ahk`
- [ ] 3. Зарегистрировать хоткей `^Volume_Mute` → `Mic.Toggle()`
- [ ] 4. Проверить запуск скрипта (синтаксис) и фактическое переключение
- [ ] 5. Обновить таблицу хоткеев в `CLAUDE.md`
