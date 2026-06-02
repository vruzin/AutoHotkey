/* ============================================================
 * app.js — Vue 3 лаунчер (IntelliJ "Search Everywhere" стиль).
 *
 * Фаза 1: SVG-иконка, навигация по кругу + PageUp/Down, подсветка совпавших
 * букв, чипы клавиш, поиск без учёта раскладки, теги типа команды, toggle-иконки.
 * Фаза 2: вкладки Все/Команды/Абревиатуры/Выделенное/Настройки, Alt+←/→,
 * Alt+1..0, цифры-бейджи, контекстная панель хоткеев внизу.
 *
 * Использует глобальные Vue (vue.global.prod.js) и ahk (bridge.js).
 * ============================================================ */
(function () {
  'use strict';
  const { createApp, ref, computed, onMounted, nextTick } = Vue;

  // --- Раскладочная карта ru↔en (поиск независимо от раскладки). ---
  const RU = 'йцукенгшщзхъфывапролджэячсмитьбю.ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,';
  const EN = "qwertyuiop[]asdfghjkl;'zxcvbnm,./QWERTYUIOP{}ASDFGHJKL:\"ZXCVBNM<>?";
  const ru2en = {}, en2ru = {};
  for (let i = 0; i < RU.length; i++) { ru2en[RU[i]] = EN[i]; en2ru[EN[i]] = RU[i]; }
  function convLayout(s, map) { let o = ''; for (const ch of s) o += (map[ch] || ch); return o; }

  // --- Фаззи-поиск со скорингом и позициями совпавших символов. ---
  function fuzzyMatch(query, text) {
    if (!query) return { score: 0, positions: [] };
    const q = query.toLowerCase(), t = text.toLowerCase();
    let qi = 0, score = 0, streak = 0, prevIdx = -1;
    const positions = [];
    for (let ti = 0; ti < t.length && qi < q.length; ti++) {
      if (t[ti] === q[qi]) {
        score += 10;
        if (prevIdx === ti - 1) { streak++; score += streak * 5; } else streak = 0;
        if (ti === 0 || t[ti - 1] === ' ' || t[ti - 1] === '›') score += 8;
        positions.push(ti); prevIdx = ti; qi++;
      }
    }
    if (qi < q.length) return null;
    score -= (t.length - q.length) * 0.1;
    return { score, positions };
  }
  function bestMatch(query, text) {
    const variants = [query];
    const a = convLayout(query, ru2en); if (a !== query) variants.push(a);
    const b = convLayout(query, en2ru); if (b !== query) variants.push(b);
    let best = null;
    for (const v of variants) { const m = fuzzyMatch(v, text); if (m && (!best || m.score > best.score)) best = m; }
    return best;
  }
  function highlight(label, positions) {
    if (!positions || !positions.length) return [{ t: label, hit: false }];
    const set = new Set(positions);
    const segs = []; let buf = '', bufHit = set.has(0);
    for (let i = 0; i < label.length; i++) {
      const hit = set.has(i);
      if (hit !== bufHit) { if (buf) segs.push({ t: buf, hit: bufHit }); buf = ''; bufHit = hit; }
      buf += label[i];
    }
    if (buf) segs.push({ t: buf, hit: bufHit });
    return segs;
  }
  function keyChips(key) { return key ? key.split('+').map(s => s.trim()).filter(Boolean) : []; }

  const SCOPE_LABEL = { selection: 'выд', command: 'ком', abbr: 'абр' };

  // --- Monaco Editor: ленивая загрузка через AMD-загрузчик. ---
  // Возвращает Promise<monaco>. Воркеры кросс-хостовые, поэтому проксируем их
  // через Blob (иначе WebView2 ругается на разные origin lib.local/app.local).
  let _monacoPromise = null;
  function loadMonaco() {
    if (_monacoPromise) return _monacoPromise;
    _monacoPromise = new Promise((resolve, reject) => {
      if (!window.require) { reject(new Error('loader.js не загружен')); return; }
      const base = 'https://lib.local/monaco/vs';
      window.require.config({ paths: { vs: base } });
      // Прокси для web-воркера: грузим воркер-скрипт через importScripts из Blob.
      window.MonacoEnvironment = {
        getWorkerUrl: function () {
          const code = 'self.MonacoEnvironment={baseUrl:"' + 'https://lib.local/monaco/"};' +
                       'importScripts("' + base + '/base/worker/workerMain.js");';
          return URL.createObjectURL(new Blob([code], { type: 'text/javascript' }));
        }
      };
      window.require(['vs/editor/editor.main'], () => resolve(window.monaco),
        (err) => reject(err));
    });
    return _monacoPromise;
  }

  // --- Вкладки. id 'settings' — особый (режим галочек). ---
  const TABS = [
    { id: 'all',       label: 'Все',         num: 1 },
    { id: 'command',   label: 'Команды',     num: 2 },
    { id: 'abbr',      label: 'Абревиатуры', num: 3 },
    { id: 'selection', label: 'Выделенное',  num: 4 },
    { id: 'settings',  label: '⚙',           num: 5, gear: true }
  ];

  createApp({
    setup() {
      const query = ref('');
      const items = ref([]);
      const tab = ref('all');
      const selected = ref(0);
      const error = ref('');
      const searchInput = ref(null);
      const launcherKey = ref('');

      // Диалог добавления/редактирования аббревиатуры.
      const dialog = ref(null);   // null | { mode:'add'|'edit', abbr, text }
      let monacoEditor = null;    // экземпляр Monaco для поля «Текст»
      // Режим захвата комбинации клавиш: { id, label, combo }.
      const capture = ref(null);
      // Диалог триггера-сокращения: { id, label, trigger }.
      const trigDialog = ref(null);
      // История ввода (фаза 5).
      const history = ref([]);
      const histOpen = ref(false);
      const histSel = ref(0);

      const isSettings = computed(() => tab.value === 'settings');
      const isAbbrTab = computed(() => tab.value === 'abbr');

      function applySnapshot(snap) {
        items.value = (snap && snap.items) ? snap.items : [];
        if (snap && snap.launcherKey) launcherKey.value = snap.launcherKey;
        if (snap && snap.history) history.value = snap.history;
      }
      async function load() {
        try { applySnapshot(await ahk.call('getData')); } catch (e) { error.value = String(e); }
      }

      // Сначала отбор по вкладке, затем фаззи-фильтр.
      function matchesTab(it) {
        switch (tab.value) {
          case 'all':       return true;
          case 'settings':  return true;            // настройки — все, но с галочками
          case 'command':   return it.scope === 'command';
          case 'selection': return it.scope === 'selection';
          case 'abbr':      return it.scope === 'abbr';
        }
        return true;
      }

      const filtered = computed(() => {
        const q = query.value.trim();
        const ql = q.toLowerCase();
        // Варианты запроса в другой раскладке — для сравнения с триггером.
        const qVariants = [ql, convLayout(ql, ru2en), convLayout(ql, en2ru)];
        const out = [];
        for (const it of items.value) {
          if (!matchesTab(it)) continue;
          // Точное совпадение триггера-сокращения (dp → docker ps) — наверх.
          if (it.trigger && qVariants.includes(it.trigger.toLowerCase())) {
            out.push({ it, score: 100000, positions: [] });
            continue;
          }
          // Поиск ТОЛЬКО по названию команды, не по группе/подсказке
          // (иначе «регистр», «число» и т.п. из названия группы ловят запрос).
          const m = bestMatch(q, it.label);
          if (m) out.push({ it, score: m.score, positions: m.positions });
        }
        if (q) out.sort((a, b) => b.score - a.score);
        return out.map(x => {
          const o = { ...x.it, _segs: highlight(x.it.label, x.positions) };
          // Для аббревиатур подсвечиваем совпадения отдельно в её имени.
          if (x.it.kind === 'abbr' && x.it.abbr) {
            const am = bestMatch(q, x.it.abbr);
            o._abbrSegs = highlight(x.it.abbr, am ? am.positions : []);
          }
          return o;
        });
      });

      function clamp(n) { const l = filtered.value.length; return l ? (n % l + l) % l : 0; }
      function move(d) { if (filtered.value.length) { selected.value = clamp(selected.value + d); scrollToSel(); } }

      function setTab(id) { tab.value = id; selected.value = 0; scrollToSel(); }
      function cycleTab(d) {
        const i = TABS.findIndex(t => t.id === tab.value);
        const n = (i + d % TABS.length + TABS.length) % TABS.length;
        setTab(TABS[n].id);
      }
      function tabByNum(num) { const t = TABS.find(t => t.num === num); if (t) setTab(t.id); }

      async function runItem(it) {
        if (!it) return;
        // Сохраняем запрос в историю (если был ввод).
        const q = query.value.trim();
        if (q) { try { history.value = await ahk.call('addHistory', { q }); } catch (e) {} }
        try { await ahk.call('run', { id: it.id }); } catch (e) { error.value = String(e); }
      }

      // --- История ввода (Tab). ---
      function openHistory() {
        if (!history.value.length) return;
        histOpen.value = true; histSel.value = 0;
      }
      function closeHistory() { histOpen.value = false; }
      function pickHistory(idx) {
        const h = history.value[idx];
        if (h != null) { query.value = h; selected.value = 0; }
        histOpen.value = false;
        nextTick(() => { if (searchInput.value) searchInput.value.focus(); });
      }
      async function toggleItem(it) {
        if (!it || it.kind === 'menuitem') return;
        try { applySnapshot(await ahk.call('toggle', { id: it.id, value: !it.enabled })); }
        catch (e) { error.value = String(e); }
      }

      // --- Аббревиатуры: CRUD через мост. ---
      function curItem() { return filtered.value[selected.value]; }
      function openAddDialog() { dialog.value = { mode: 'add', abbr: '', text: '' }; mountEditor(''); focusFirstField(); }
      function openEditDialog(it) {
        if (!it || it.kind !== 'abbr') return;
        // origAbbr — исходное имя; если пользователь его изменит, переименуем.
        dialog.value = { mode: 'edit', abbr: it.abbr, text: it.text, origAbbr: it.abbr };
        mountEditor(it.text);
        focusFirstField();
      }
      function closeDialog() { disposeEditor(); dialog.value = null; focusSearch(); }

      // Текст берём из Monaco (если поднялся) либо из textarea-фоллбэка.
      function readDialogText() {
        if (monacoEditor) return monacoEditor.getValue();
        return dialog.value ? dialog.value.text : '';
      }
      async function submitDialog() {
        const d = dialog.value; if (!d || !d.abbr.trim()) return;
        const abbr = d.abbr.trim();
        const text = readDialogText();
        try {
          if (d.mode === 'edit') {
            // Имя поменялось → переименование: добавить новую, удалить старую.
            if (d.origAbbr && d.origAbbr !== abbr) {
              await ahk.call('abbrAdd', { abbr, text });
              applySnapshot(await ahk.call('abbrDelete', { abbr: d.origAbbr }));
            } else {
              applySnapshot(await ahk.call('abbrEdit', { abbr, text }));
            }
          } else {
            applySnapshot(await ahk.call('abbrAdd', { abbr, text }));
          }
        } catch (e) { error.value = String(e); }
        disposeEditor(); dialog.value = null; focusSearch();
      }

      // Поднять Monaco в контейнере модалки (#abbr-editor). Если не загрузился —
      // остаётся textarea-фоллбэк (v-if в шаблоне).
      function mountEditor(initial) {
        nextTick(async () => {
          try {
            const monaco = await loadMonaco();
            const host = document.getElementById('abbr-editor');
            if (!host || !dialog.value) return;
            disposeEditor();
            monacoEditor = monaco.editor.create(host, {
              value: initial || '',
              language: 'plaintext',
              theme: 'vs-dark',
              minimap: { enabled: false },
              lineNumbers: 'off',
              wordWrap: 'on',
              scrollBeyondLastLine: false,
              fontSize: 13,
              automaticLayout: true,
              padding: { top: 8, bottom: 8 }
            });
            // Esc внутри Monaco — закрыть модалку (иначе редактор глотает клавишу).
            monacoEditor.addCommand(monaco.KeyCode.Escape, () => closeDialog());
            // Ctrl+Enter — сохранить.
            monacoEditor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.Enter, () => submitDialog());
          } catch (e) {
            error.value = 'Monaco: ' + String(e);   // покажем, но textarea-фоллбэк работает
          }
        });
      }
      function disposeEditor() {
        if (monacoEditor) { try { monacoEditor.dispose(); } catch (e) {} monacoEditor = null; }
      }

      // Навигация ←/→ между кнопками «Отмена»/«Сохранить» в модалке, когда
      // фокус уже на одной из кнопок (Tab переводит на них штатно).
      function onActionsNav(e) {
        if (e.key !== 'ArrowLeft' && e.key !== 'ArrowRight') return;
        const ae = document.activeElement;
        if (!ae || ae.tagName !== 'BUTTON') return;
        const btns = Array.from(e.currentTarget.querySelectorAll('.modal__actions .btn'));
        const i = btns.indexOf(ae);
        if (i < 0) return;
        const next = e.key === 'ArrowRight'
          ? btns[(i + 1) % btns.length]
          : btns[(i - 1 + btns.length) % btns.length];
        next.focus();
        e.preventDefault();
      }
      async function deleteAbbr(it) {
        if (!it || it.kind !== 'abbr') return;
        try { applySnapshot(await ahk.call('abbrDelete', { abbr: it.abbr })); }
        catch (e) { error.value = String(e); }
      }

      // --- Захват комбинации клавиш (Alt+E на команде-хоткее). ---
      // Преобразует событие клавиатуры в AHK-синтаксис: ^ Ctrl, + Shift, ! Alt, # Win.
      const MOD_KEYS = new Set(['Control','Shift','Alt','Meta','CapsLock']);
      // Имя клавиши события → имя клавиши AHK.
      function keyName(e) {
        const map = { ' ': 'Space', 'ArrowUp': 'Up', 'ArrowDown': 'Down',
          'ArrowLeft': 'Left', 'ArrowRight': 'Right', 'Escape': 'Esc',
          'Delete': 'Delete', 'Insert': 'Insert', 'Enter': 'Enter', 'Tab': 'Tab' };
        let k = e.key;
        if (map[k]) return map[k];
        if (k.length === 1) return k.toUpperCase();
        return k;
      }
      // Событие → AHK-комбинация. capsPrefix=true → клавиша-префикс CapsLock,
      // тогда результат вида "CapsLock & X" (CapsLock в JS не модификатор-флаг,
      // поэтому ловим его отдельным нажатием — см. onKeydown).
      function eventToAhk(e, capsPrefix) {
        if (MOD_KEYS.has(e.key)) return null;   // ждём не-модификатор
        const k = keyName(e);
        if (capsPrefix) {
          // CapsLock-префикс совмещаем с обычными модификаторами, если зажаты.
          let mods = '';
          if (e.ctrlKey)  mods += '^';
          if (e.shiftKey) mods += '+';
          if (e.altKey)   mods += '!';
          return 'CapsLock & ' + mods + k;
        }
        let combo = '';
        if (e.ctrlKey)  combo += '^';
        if (e.shiftKey) combo += '+';
        if (e.altKey)   combo += '!';
        if (e.metaKey)  combo += '#';
        return combo + k;
      }
      // Человекочитаемый вид собранной комбинации (для отображения в окне захвата).
      function ahkToHuman(combo) {
        if (!combo) return '';
        // Форма "CapsLock & X" / "CapsLock & ^X".
        if (combo.indexOf(' & ') >= 0) {
          const parts = combo.split(' & ');
          return parts.map(p => ahkToHuman(p)).join('+');
        }
        const m = { '^': 'Ctrl', '+': 'Shift', '!': 'Alt', '#': 'Win' };
        let out = [], rest = combo;
        while (rest && m[rest[0]]) { out.push(m[rest[0]]); rest = rest.slice(1); }
        if (rest === 'CapsLock') return 'CapsLock';
        if (rest) out.push(rest);
        return out.join('+');
      }
      async function startCapture(it) {
        if (!it || !it.rebindable) return;
        capture.value = { id: it.id, label: it.label, combo: '', capsPrefix: false };
        // Приостанавливаем глобальные хоткеи, чтобы набираемая комбинация
        // не выполнила свою команду во время записи.
        try { await ahk.call('captureStart', {}); } catch (e) {}
      }
      async function endCaptureSuspend() {
        try { await ahk.call('captureEnd', {}); } catch (e) {}
      }
      async function cancelCapture() { capture.value = null; await endCaptureSuspend(); }
      async function applyCapture() {
        const c = capture.value; if (!c || !c.combo) { await cancelCapture(); return; }
        try {
          const r = await ahk.call('setHotkey', { id: c.id, combo: c.combo });
          if (r.result && !r.result.ok) error.value = 'Не удалось: ' + r.result.error;
          else error.value = '';
          applySnapshot(r.data);
        } catch (e) { error.value = String(e); }
        capture.value = null;
        await endCaptureSuspend();
      }

      // --- Триггер-сокращение (Alt+T на команде). ---
      function openTrigDialog(it) {
        if (!it) return;
        trigDialog.value = { id: it.id, label: it.label, trigger: it.trigger || '' };
        focusFirstField();
      }
      function closeTrigDialog() { trigDialog.value = null; focusSearch(); }
      async function submitTrigDialog() {
        const d = trigDialog.value; if (!d) return;
        try { const r = await ahk.call('setTrigger', { id: d.id, trigger: d.trigger.trim() }); applySnapshot(r.data); }
        catch (e) { error.value = String(e); }
        trigDialog.value = null; focusSearch();
      }

      function onKeydown(e) {
        // Режим захвата комбинации — ловим ВСЁ.
        if (capture.value) {
          e.preventDefault(); e.stopPropagation();
          if (e.key === 'Escape') { cancelCapture(); return; }
          // CapsLock: становится клавишей-префиксом (CapsLock & …). В JS он не
          // приходит как модификатор-флаг, поэтому ловим его отдельным нажатием.
          if (e.key === 'CapsLock') {
            capture.value.capsPrefix = true;
            capture.value.combo = 'CapsLock';   // предпросмотр «CapsLock + …»
            return;
          }
          const ahkCombo = eventToAhk(e, capture.value.capsPrefix);
          if (ahkCombo) { capture.value.combo = ahkCombo; capture.value.capsPrefix = false; }
          return;
        }
        // Открыт диалог аббревиатуры — Esc/ Ctrl+Enter.
        if (dialog.value) {
          if (e.key === 'Escape') { closeDialog(); e.preventDefault(); }
          else if (e.key === 'Enter' && e.ctrlKey) { submitDialog(); e.preventDefault(); }
          return;
        }
        // Открыт диалог триггера — Esc/ Enter.
        if (trigDialog.value) {
          if (e.key === 'Escape') { closeTrigDialog(); e.preventDefault(); }
          else if (e.key === 'Enter') { submitTrigDialog(); e.preventDefault(); }
          return;
        }
        // Tab — открыть/закрыть список истории.
        if (e.key === 'Tab') {
          e.preventDefault();
          if (histOpen.value) closeHistory(); else openHistory();
          return;
        }
        // Навигация по списку истории: стрелки сразу подставляют запрос
        // в основной поиск (live preview), Enter фиксирует и закрывает список.
        if (histOpen.value) {
          const n = history.value.length;
          if (e.key === 'Escape')    { closeHistory(); e.preventDefault(); return; }
          if (e.key === 'ArrowDown') { histSel.value = (histSel.value + 1) % n; query.value = history.value[histSel.value]; selected.value = 0; e.preventDefault(); return; }
          if (e.key === 'ArrowUp')   { histSel.value = (histSel.value - 1 + n) % n; query.value = history.value[histSel.value]; selected.value = 0; e.preventDefault(); return; }
          if (e.key === 'Enter')     { pickHistory(histSel.value); e.preventDefault(); return; }
        }
        // Alt+навигация по вкладкам + функц-клавиши.
        // ВАЖНО: используем e.code (физическая клавиша), а не e.key — иначе в
        // русской раскладке Alt+O приходит как «щ» и не срабатывает.
        if (e.altKey) {
          if (e.key === 'ArrowLeft'  || e.code === 'KeyZ') { cycleTab(-1); e.preventDefault(); return; }
          if (e.key === 'ArrowRight' || e.code === 'KeyX') { cycleTab(+1); e.preventDefault(); return; }
          const digit = e.code.startsWith('Digit') ? e.code.slice(5) : '';
          if (digit >= '1' && digit <= '9') { tabByNum(+digit); e.preventDefault(); return; }
          if (digit === '0') { tabByNum(10); e.preventDefault(); return; }
          // Alt+O — вкл/выкл команду под курсором НА ЛЮБОЙ вкладке.
          if (e.code === 'KeyO') { toggleItem(curItem()); e.preventDefault(); return; }
          if (isAbbrTab.value) {
            if (e.code === 'KeyE')                      { openEditDialog(curItem()); e.preventDefault(); return; }
            if (e.code === 'KeyS' || e.code === 'KeyA') { openAddDialog();           e.preventDefault(); return; }
            if (e.key === 'Delete')                     { deleteAbbr(curItem());     e.preventDefault(); return; }
          } else {
            // Команды/Все: Alt+E — переназначить клавишу, Alt+T — триггер-сокращение.
            if (e.code === 'KeyE') { startCapture(curItem());   e.preventDefault(); return; }
            if (e.code === 'KeyT') { openTrigDialog(curItem()); e.preventDefault(); return; }
          }
        }
        if (e.key === 'Escape') { ahk.call('hide', {}); return; }
        if (e.key === 'ArrowDown')      { move(+1);  e.preventDefault(); }
        else if (e.key === 'ArrowUp')   { move(-1);  e.preventDefault(); }
        else if (e.key === 'PageDown')  { move(+10); e.preventDefault(); }
        else if (e.key === 'PageUp')    { move(-10); e.preventDefault(); }
        else if (e.key === 'Home')      { selected.value = 0; scrollToSel(); e.preventDefault(); }
        else if (e.key === 'End')       { selected.value = filtered.value.length - 1; scrollToSel(); e.preventDefault(); }
        else if (e.key === 'Enter') {
          const it = filtered.value[selected.value];
          if (isSettings.value) toggleItem(it); else runItem(it);
          e.preventDefault();
        }
      }

      function scrollToSel() {
        nextTick(() => { const el = document.querySelector('.row--sel'); if (el) el.scrollIntoView({ block: 'nearest' }); });
      }
      function onInput() { selected.value = 0; }

      // Надёжно вернуть фокус в поле поиска (несколько попыток — WebView2 при
      // первом показе может не сразу принять фокус).
      function focusSearch() {
        const tries = [0, 60, 160, 320];
        for (const t of tries) setTimeout(() => {
          if (searchInput.value && !dialog.value && !trigDialog.value)
            searchInput.value.focus();
        }, t);
      }
      // Фокус в первое поле модалки после её появления (несколько попыток —
      // модалка и Monaco поднимаются асинхронно).
      function focusFirstField() {
        for (const t of [30, 120, 260]) setTimeout(() => {
          const el = document.querySelector('.modal__box .js-first')
                  || document.querySelector('.modal__box input, .modal__box textarea');
          if (el && document.activeElement !== el) { el.focus(); el.select && el.select(); }
        }, t);
      }

      // Глобальный обработчик клавиш для МОДАЛОК: фокус внутри их инпутов, и
      // keydown поля поиска туда не доходит. Esc закрывает любую модалку,
      // Ctrl+Enter / Enter — подтверждает.
      function onGlobalKey(e) {
        if (capture.value) {
          // в режиме захвата всё ловит onKeydown поля; здесь лишь подстрахуем Esc
          if (e.key === 'Escape') { cancelCapture(); e.preventDefault(); e.stopPropagation(); }
          return;
        }
        if (dialog.value) {
          if (e.key === 'Escape') { closeDialog(); e.preventDefault(); e.stopPropagation(); }
          else if (e.key === 'Enter' && e.ctrlKey) { submitDialog(); e.preventDefault(); }
        } else if (trigDialog.value) {
          if (e.key === 'Escape') { closeTrigDialog(); e.preventDefault(); e.stopPropagation(); }
          else if (e.key === 'Enter') { submitTrigDialog(); e.preventDefault(); }
        }
      }

      ahk.onPush((msg) => {
        if (msg.channel === 'init') {
          query.value = ''; selected.value = 0; load();
          focusSearch();
        }
      });
      onMounted(async () => {
        await load();
        focusSearch();
        document.addEventListener('keydown', onGlobalKey, true);  // capture-фаза
      });

      function rowChecked(it) { return it.enabled && it.groupOn; }
      function scopeLabel(it) { return SCOPE_LABEL[it.scope] || 'ком'; }
      function isDimmed(it) {
        if (it.toggleable && !it.enabled) return true;
        if (isSettings.value && !rowChecked(it)) return true;
        return false;
      }

      // Контекстная панель хоткеев внизу (зависит от вкладки).
      const footerHints = computed(() => {
        const base = [
          { k: '↑↓', d: 'выбор' },
          { k: 'PgUp/PgDn', d: '±10' },
          { k: 'Enter', d: isSettings.value ? 'вкл/выкл' : 'запуск' },
          { k: 'Tab', d: 'история' },
          { k: 'Alt+O', d: 'вкл/выкл' },
          { k: 'Esc', d: 'скрыть' },
          { k: 'Alt+←/→', d: 'вкладки' },
          { k: 'Alt+1…5', d: 'вкладка' }
        ];
        // Функц-клавиши аббревиатур — только на вкладке «Абревиатуры».
        if (isAbbrTab.value) {
          base.push({ k: 'Alt+E', d: 'правка' });
          base.push({ k: 'Alt+A', d: 'добавить' });
          base.push({ k: 'Alt+Del', d: 'удалить' });
        } else {
          base.push({ k: 'Alt+E', d: 'клавиша' });
          base.push({ k: 'Alt+T', d: 'сокращение' });
        }
        return base;
      });

      return {
        query, items, tab, TABS, selected, error, searchInput, launcherKey,
        isSettings, isAbbrTab, dialog, capture, trigDialog,
        history, histOpen, histSel,
        filtered, runItem, toggleItem, setTab, onKeydown, onInput,
        rowChecked, scopeLabel, isDimmed, keyChips, footerHints,
        openAddDialog, openEditDialog, closeDialog, submitDialog, deleteAbbr,
        cancelCapture, applyCapture, ahkToHuman, onActionsNav,
        closeTrigDialog, submitTrigDialog,
        openHistory, pickHistory
      };
    },

    template: `
      <div class="launcher">
        <div class="search">
          <button class="search__hist" title="История ввода (Tab)" @click="openHistory">
            <svg class="search__icon" viewBox="0 0 24 24" width="20" height="20" aria-hidden="true">
              <circle cx="11" cy="11" r="7" fill="none" stroke="currentColor" stroke-width="2"/>
              <line x1="16.5" y1="16.5" x2="21" y2="21" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
            </svg>
            <svg class="search__caret" viewBox="0 0 12 12" width="10" height="10" aria-hidden="true">
              <path d="M2 4 L6 8 L10 4" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </button>
          <input
            ref="searchInput" class="search__input" v-model="query"
            @input="onInput" @keydown="onKeydown"
            :placeholder="isSettings ? 'Поиск для настройки…' : 'Поиск команды…'"
            spellcheck="false"
          >

          <!-- Выпадающий список истории (Tab) -->
          <ul v-if="histOpen && history.length" class="hist">
            <li
              v-for="(h, hi) in history" :key="hi"
              class="hist__item" :class="{ 'hist__item--sel': hi === histSel }"
              @mouseenter="histSel = hi" @click="pickHistory(hi)"
            >{{ h }}</li>
          </ul>
        </div>

        <div class="tabs">
          <button
            v-for="t in TABS" :key="t.id"
            class="tab" :class="{ 'tab--on': tab === t.id, 'tab--gear': t.gear }"
            :title="'Alt+' + t.num"
            @click="setTab(t.id)"
          >
            <span class="tab__label">{{ t.label }}</span>
            <span class="tab__num">{{ t.num }}</span>
          </button>
        </div>

        <p v-if="error" class="launcher__error">{{ error }}</p>

        <ul class="rows">
          <li
            v-for="(it, i) in filtered" :key="it.id"
            class="row"
            :class="{ 'row--sel': i === selected, 'row--off': isDimmed(it) }"
            @mouseenter="selected = i"
            @click="isSettings ? toggleItem(it) : runItem(it)"
          >
            <input
              v-if="isSettings" class="row__check" type="checkbox"
              :checked="rowChecked(it)" :disabled="it.kind === 'menuitem'"
              @click.stop="toggleItem(it)"
            >
            <span v-if="it.toggleable" class="row__toggle" :class="{ 'row__toggle--on': it.enabled }">
              {{ it.enabled ? '●' : '○' }}
            </span>
            <span class="row__scope" :class="'row__scope--' + it.scope">{{ scopeLabel(it) }}</span>
            <!-- Аббревиатура: имя цветом (с подсветкой совпадений) + текст -->
            <template v-if="it.kind === 'abbr'">
              <b class="row__abbr"><template v-for="(seg, si) in (it._abbrSegs || [{t: it.abbr, hit:false}])" :key="si"><mark v-if="seg.hit" class="hit">{{ seg.t }}</mark><span v-else>{{ seg.t }}</span></template></b>
              <span class="row__abbrtext">
                <span class="row__abbrtext-short">{{ it.text }}</span>
                <span class="row__abbrtext-full">{{ it.text }}</span>
              </span>
            </template>
            <!-- Обычная команда: название с подсветкой совпадений -->
            <span v-else class="row__label">
              <template v-for="(seg, si) in it._segs" :key="si"><mark v-if="seg.hit" class="hit">{{ seg.t }}</mark><span v-else>{{ seg.t }}</span></template>
            </span>
            <span class="row__group">{{ it.group }}</span>
            <span v-if="it.trigger" class="row__trigger" title="Горячее сокращение">{{ it.trigger }}</span>
            <span v-if="it.key" class="row__keys">
              <span v-for="(c, ci) in keyChips(it.key)" :key="ci" class="chip">{{ c }}</span>
            </span>
          </li>
          <li v-if="filtered.length === 0" class="rows__empty">Ничего не найдено</li>
        </ul>

        <div class="footer">
          <span class="footer__hints">
            <span v-for="(h, hi) in footerHints" :key="hi" class="footer__hint">
              <span class="chip chip--sm">{{ h.k }}</span> {{ h.d }}
            </span>
          </span>
          <span v-if="launcherKey" class="footer__call">
            Вызов <span class="chip">{{ launcherKey }}</span>
          </span>
        </div>

        <!-- Диалог добавления/редактирования аббревиатуры (Monaco Editor) -->
        <div v-if="dialog" class="modal" @click.self="closeDialog">
          <div class="modal__box" @keydown="onActionsNav">
            <h3 class="modal__title">{{ dialog.mode === 'add' ? 'Новая аббревиатура' : 'Редактирование аббревиатуры' }}</h3>
            <label class="modal__field">
              <span class="modal__lbl">Аббревиатура</span>
              <input class="modal__input js-first" v-model="dialog.abbr" spellcheck="false">
            </label>
            <div class="modal__field">
              <span class="modal__lbl">Текст</span>
              <div id="abbr-editor" class="modal__editor"></div>
              <!-- Фоллбэк, если Monaco не загрузился -->
              <textarea v-if="false" class="modal__input modal__input--area" v-model="dialog.text" rows="4"></textarea>
            </div>
            <div class="modal__actions">
              <button class="btn" @click="closeDialog">Отмена <span class="chip chip--sm">Esc</span></button>
              <button class="btn btn--primary" @click="submitDialog">Сохранить <span class="chip chip--sm">Ctrl+Enter</span></button>
            </div>
          </div>
        </div>

        <!-- Захват комбинации клавиш -->
        <div v-if="capture" class="modal" @click.self="cancelCapture">
          <div class="modal__box modal__box--narrow">
            <h3 class="modal__title">Новая клавиша для «{{ capture.label }}»</h3>
            <div class="capture">
              <span v-if="capture.combo" class="capture__combo">
                <span v-for="(c, ci) in keyChips(ahkToHuman(capture.combo))" :key="ci" class="chip">{{ c }}</span>
              </span>
              <span v-else class="capture__hint">Нажмите комбинацию клавиш…</span>
            </div>
            <div class="modal__actions">
              <button class="btn" @click="cancelCapture">Отмена <span class="chip chip--sm">Esc</span></button>
              <button class="btn btn--primary" :disabled="!capture.combo" @click="applyCapture">Применить</button>
            </div>
          </div>
        </div>

        <!-- Триггер-сокращение -->
        <div v-if="trigDialog" class="modal" @click.self="closeTrigDialog">
          <div class="modal__box modal__box--narrow" @keydown="onActionsNav">
            <h3 class="modal__title">Сокращение для «{{ trigDialog.label }}»</h3>
            <label class="modal__field">
              <span class="modal__lbl">Например «dp» — наберёшь в лаунчере, команда первой</span>
              <input class="modal__input js-first" v-model="trigDialog.trigger" spellcheck="false">
            </label>
            <div class="modal__actions">
              <button class="btn" @click="closeTrigDialog">Отмена <span class="chip chip--sm">Esc</span></button>
              <button class="btn btn--primary" @click="submitTrigDialog">Сохранить <span class="chip chip--sm">Enter</span></button>
            </div>
          </div>
        </div>
      </div>
    `
  }).mount('#app');
})();
