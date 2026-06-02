/* ============================================================
 * bridge.js — единый JS-мост между Vue и AHK (общий для всех приложений).
 *
 * Подключается обычным <script> (без ES-модулей, чтобы не упираться в
 * ограничения file:// на import). Кладёт глобальный объект window.ahk.
 *
 *   ahk.call(action, payload)  -> Promise<any>   вызвать AHK-обработчик
 *   ahk.getInitData()          -> Promise<any>   начальные данные от AHK
 *   ahk.onPush(handler)                          подписка на push из AHK
 *
 * AHK-сторона: ui/WebApp.ahk (host-объект "ahk": dispatch/getInitData,
 * PostWebMessageAsJson для push).
 * ============================================================ */
(function () {
  'use strict';

  // host-объект асинхронный: каждый вызов метода возвращает Promise.
  function host() {
    return window.chrome.webview.hostObjects.ahk;
  }

  const ahk = {
    /**
     * Вызвать AHK-обработчик, зарегистрированный через WebApp.On(action, fn).
     * Возвращает распарсенные данные (поле data) или бросает при ok:false.
     */
    async call(action, payload = {}) {
      const raw = await host().dispatch(action, JSON.stringify(payload));
      const res = JSON.parse(raw);
      if (!res.ok) throw new Error(res.error || 'AHK call failed');
      return res.data;
    },

    /** Начальные данные, переданные в WebApp.Show(initData). */
    async getInitData() {
      const raw = await host().getInitData();
      return raw ? JSON.parse(raw) : null;
    },

    /**
     * Подписка на push из AHK (WebApp.Push(channel, data)).
     * handler получает объект { channel, data }.
     */
    onPush(handler) {
      window.chrome.webview.addEventListener('message', function (e) {
        handler(e.data);
      });
    }
  };

  window.ahk = ahk;
})();
