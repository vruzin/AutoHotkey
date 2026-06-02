# Plan_007 — Универсальная система активации фич + фреймворк Vue-SPA в WebView2

## Цель

Две связанные подсистемы:

1. **FeatureRegistry** — единый реестр. Все модули по-прежнему подключаются через
   `#Include` (ничего не «вырезается» из сборки), но каждый хоткей/функция
   срабатывает **только если активна**. Включение/выключение — в рантайме, без
   `Reload`. Состояние хранится в `data/settings.json`.

2. **WebApp** — переиспользуемый фреймворк для запуска приложений с интерфейсом
   на Vue внутри WebView2. Требования заказчика:
   - Код Vue/CSS/JS **не пишется внутри AHK** — лежит в отдельных файлах
     (`ui/apps/<имя>/`).
   - Vue-приложение при показе может **получать начальные данные из AHK**.
   - Из Vue можно **вызывать функции AHK** (с возвратом результата).
   - Приложений на Vue будет **несколько** (SPA) — фреймворк должен делать их
     добавление удобным и единообразным.

Первый потребитель фреймворка — **окно настроек** (галочки вкл/выкл всех
скриптов), открывается по одинарному клику на иконку в трее.

## Подход (философия)

- **Include-all, activate-selectively.** Модульность файлов уже есть
  (`features/`, `legacy/`, `core/`). Реестр не трогает загрузку — он управляет
  *активностью*. Для хоткеев это `Hotkey(key, fn, "On"/"Off")` (реально
  освобождает клавишу). Для не-хоткейных фич — флаг `active`, проверяемый в начале
  функции. Простаивающий выключенный хоткей стоит 0 ресурсов, поэтому Reload не
  нужен.

- **Разделение AHK и web.** AHK отвечает за логику и данные; Vue — только за
  представление. Между ними — тонкий типизированный мост (bridge), общий для всех
  приложений. Ни строки HTML/CSS/JS в `.ahk`.

- **Одно приложение = одна папка.** `ui/apps/<name>/{index.html, app.js,
  style.css}`. Общие ресурсы (Vue, bridge.js, базовые стили) — в `ui/apps/_shared/`
  и `lib/`. Добавить новое Vue-приложение = создать папку + одну строку
  регистрации в AHK.

## Архитектура

```
core/
  FeatureRegistry.ahk    ; реестр хоткеев/фич: Register/SetEnabled/Snapshot/persist
ui/
  WebApp.ahk             ; класс-обёртка WebView2: окно, навигация, мост, lifecycle
  apps/
    _shared/
      bridge.js          ; JS-обёртка моста: ahk.call(action,payload)->Promise,
                         ; ahk.onPush(cb), ahk.getInitData()
      base.css           ; тёмная тема, общие переменные/токены (опц.)
    settings/            ; ПЕРВОЕ приложение
      index.html         ; подключает vue + bridge.js + app.js + style.css
      app.js             ; Vue 3 SPA: дерево групп->хоткеи, чекбоксы
      style.css          ; стили окна настроек (BEM)
lib/
  vue.global.prod.js     ; Vue 3 локально (офлайн), общий для всех приложений
  Webview2/Promise.ahk   ; зависимость WebView2.ahk (#Include внутри WebView2.ahk)
  Webview2/WebView2.ahk  ; уже есть
  Webview2/ComVar.ahk    ; уже есть
  WebView2Loader.dll     ; уже есть (путь передаём явно в WebApp)
```

### FeatureRegistry — модель данных

Запись хоткея: `{ id, group, label, key, fn, enabled, default }`.
Запись фичи без клавиши (напр. ForceWords): `{ id, group, label, fn?, enabled }` —
активность проверяется самим модулем через `FeatureRegistry.IsActive(id)`.

Группы (для UI): `punto`, `text`, `mic`, `global`, `legacy`, `palette`, `apps`.

API:
- `Register(id, group, label, key, fn, default:=true)` — хоткей; сразу применяет
  сохранённое состояние.
- `RegisterFeature(id, group, label, default:=true)` — флаг без клавиши.
- `IsActive(id)` — для проверок внутри модулей (ForceWords и т.п.).
- `SetEnabled(id, on)` — рантайм On/Off + сохранение + учёт состояния группы.
- `SetGroupEnabled(group, on)` — каскад на дочерние (индивидуальные флаги
  сохраняются для восстановления).
- `Snapshot()` — дерево групп→элементы для передачи в Vue.

Эффективная активность = `hotkey.enabled && group.enabled`.

### settings.json — новая секция

```json
"features": {
  "groups":  { "mic": {"enabled": true}, "legacy": {"enabled": true} },
  "hotkeys": { "mic.toggle": {"enabled": true}, "legacy.docker": {"enabled": false} }
}
```

### WebApp — фреймворк (ключевая часть)

Класс `WebApp` (экземпляры, не статика — приложений несколько):

- `__New(name, opts)` — `name` = папка в `ui/apps/`. opts: размеры, заголовок,
  `frameless`, `centered`, `hideOnBlur` (для Alfred-подобных в будущем).
- `On(action, fn)` — зарегистрировать AHK-обработчик вызова из Vue. `fn`
  принимает распарсенный payload, возвращает значение (сериализуется в JSON).
- `Show(initData := "")` — создать (если нужно) окно + WebView2, навигировать на
  `ui/apps/<name>/index.html`, передать `initData` как стартовые данные.
  Повторный вызов — показ существующего окна (не пересоздаём).
- `Push(channel, data)` — отправить данные в Vue в любой момент
  (`PostWebMessageAsJson`).
- `Hide()` / `Close()` — lifecycle.

Мост (единый для всех приложений):
- **Vue → AHK (с возвратом):** `AddHostObjectToScript("ahk", handler)`, где
  `handler.dispatch(action, argsJson)` маршрутизирует в обработчики, зарег. через
  `On(...)`, и возвращает JSON-результат. hostObjects асинхронны → в JS это
  `await`.
- **AHK → Vue (push):** `PostWebMessageAsJson(...)` → в JS
  `window.chrome.webview.addEventListener("message", ...)`.
- **Начальные данные:** при `Show(initData)` сохраняем JSON; Vue на старте зовёт
  `ahk.getInitData()`.

`bridge.js` прячет это за чистым API:
```js
// ui/apps/_shared/bridge.js
export const ahk = {
  async call(action, payload = {}) { /* dispatch -> JSON.parse */ },
  async getInitData() { /* -> JSON.parse */ },
  onPush(handler) { /* addEventListener('message', ...) */ }
}
```

Добавление нового Vue-приложения:
1. Папка `ui/apps/<new>/` с `index.html`, `app.js`, `style.css`.
2. В AHK: `app := WebApp("<new>")`, `app.On("...", fn)`, открыть `app.Show(data)`.

## Этапы реализации

### Этап 0 — Зависимости
- [ ] 0.1 Скачать `Promise.ahk` → `lib/Webview2/Promise.ahk` (нужен WebView2.ahk).
- [ ] 0.2 Скачать `vue.global.prod.js` → `lib/vue.global.prod.js` (офлайн).
- [ ] 0.3 Проверить путь к `WebView2Loader.dll` (лежит в `lib/`, код по умолчанию
      ищет в `lib/Webview2/64bit/` — передавать путь явно).

### Этап 1 — FeatureRegistry
- [ ] 1.1 `core/FeatureRegistry.ahk`: items/groups, Register/RegisterFeature,
      IsActive, SetEnabled/SetGroupEnabled, Snapshot.
- [ ] 1.2 Persist через PuntoSettings: чтение/запись `features.*`.
- [ ] 1.3 `#Include core\FeatureRegistry.ahk` в main.ahk (после Settings).
- [ ] 1.4 В `PuntoSettings.Defaults()` добавить пустую секцию `features`.

### Этап 2 — Перенос хоткеев в реестр
- [ ] 2.1 Глобальные (main.ahk): IP, Vivaldi 1-4, разделители, пароль, Win+C,
      Win+Insert, ABBYY, ZoomIt x2, Win+Z, AlwaysOnTop, Mic — директивные `::`
      превратить в именованные функции `(*)` + `Register(...)`.
- [ ] 2.2 Legacy CapsLock-меню (A/S/D/K/B/F/W/T/H/Z) — обернуть в Register.
- [ ] 2.3 Текстовые (Case/Translit/Number/PasteRaw) и Punto-команды из Punto.Init
      перевести с `Hotkey()` на `Register()`.
- [ ] 2.4 ForceWords: ввести проверку `FeatureRegistry.IsActive("punto.forcewords")`
      в Autoswitch (сейчас флаг enabled не проверяется нигде).
- [ ] 2.5 Контекстные `#HotIf` (Direct Commander/GraphCalc/IDEA) НЕ трогаем.
- [ ] 2.6 После каждого подэтапа — `/validate` (риск регрессий хоткеев).

### Этап 3 — Фреймворк WebApp
- [ ] 3.1 `ui/WebApp.ahk`: класс, создание Gui+WebView2, Navigate, lifecycle.
- [ ] 3.2 Мост: AddHostObjectToScript + dispatch(action,args)->JSON; getInitData.
- [ ] 3.3 Push: PostWebMessageAsJson.
- [ ] 3.4 `ui/apps/_shared/bridge.js` — JS-обёртка (call/getInitData/onPush).
- [ ] 3.5 `ui/apps/_shared/base.css` — тёмная тема, токены (опц.).
- [ ] 3.6 Мини-проверка моста на тестовой странице (echo-вызов AHK<->Vue).

### Этап 4 — Приложение «Настройки» (первый потребитель)
- [ ] 4.1 `ui/apps/settings/index.html` — подключает vue, bridge.js, app.js, css.
- [ ] 4.2 `ui/apps/settings/app.js` — Vue 3 SPA: группы с чекбоксом + список
      хоткеев с чекбоксами и подписью клавиши; клик → `ahk.call('toggle', ...)`.
- [ ] 4.3 `ui/apps/settings/style.css` — тёмная тема, BEM.
- [ ] 4.4 AHK-сторона: `SettingsApp` поверх WebApp, обработчики
      `getData`→Snapshot, `toggle`→SetEnabled, `toggleGroup`→SetGroupEnabled;
      после изменения — Push обновлённого Snapshot (для каскада групп в UI).

### Этап 5 — Трей
- [ ] 5.1 `OnMessage(0x404, TrayClick)`: левый клик (WM_LBUTTONUP) →
      `SettingsApp.Show()`; правый клик не перехватываем (меню AHK Reload/Exit).
- [ ] 5.2 Пункт «Настройки…» в меню трея (запасной путь).

### Этап 6 — Проверка и документация
- [ ] 6.1 `/validate` + фактический клик в трее, проверка toggle и каскада.
- [ ] 6.2 Обновить `CLAUDE.md`: архитектура (FeatureRegistry, ui/WebApp, ui/apps),
      трей, как добавлять новое Vue-приложение.

## Ключевые технические решения

- **Без Go-обёртки.** WebView2 даёт Vue прямо из AHK; пересборка `#Include`
  заменена рантайм-активацией. Отдельный бинарник и IPC не нужны.
- **Без Reload при переключении.** `Hotkey On/Off` освобождает клавишу мгновенно;
  состояние пишется в settings.json. Reload остаётся только для CapsLock+R.
- **Мост hostObject + postMessage.** hostObject — для вызовов Vue→AHK с возвратом
  (асинхронно); postMessage — для push AHK→Vue. Это покрывает все три требования
  (initData, вызов AHK из Vue, передача данных в Vue).
- **Экземпляры WebApp, не статика.** Приложений несколько → каждый сам себе окно,
  набор обработчиков и состояние.
- **Vue 3 global build локально.** Офлайн, без сборщика; SPA на Composition API
  через `createApp`. При росте сложности отдельного приложения можно позже ввести
  Vite-сборку для него, не ломая остальные.

## Открытые вопросы (решаются по ходу, не блокируют старт)

- Нужен ли каждому Vue-приложению свой пользовательский data-dir WebView2, или
  общий. По умолчанию — общий профиль в `data/webview2/`.
- `hideOnBlur`/frameless понадобятся для будущего Alfred-лаунчера — заложить опции
  в WebApp сразу, реализацию отложить.
- Горячая клавиша для открытия настроек помимо трея — пока не делаем (нет запроса).
```
