/* ============================================================
 * app.js — Vue 3 лаунчер (Alfred-стиль).
 *
 * Режим «Запуск» (по умолчанию): поиск по мере ввода (фаззи) по всем
 * функциям и пунктам меню; ↑↓ навигация; Enter — выполнить; Esc — скрыть.
 * Шестерёнка ⚙ → режим «Настройки»: те же отфильтрованные строки с галочками
 * (вкл/выкл хоткеев). Пункты меню (kind=menuitem) галочкой не управляются.
 *
 * Использует глобальные Vue (vue.global.prod.js) и ahk (bridge.js).
 * ============================================================ */
(function () {
  'use strict';
  const { createApp, ref, computed, onMounted, nextTick } = Vue;

  // --- Фаззи-поиск: subsequence-match со скорингом. ---
  // Возвращает score (больше — лучше) или -1 если не совпало.
  function fuzzyScore(query, text) {
    if (!query) return 0;
    const q = query.toLowerCase();
    const t = text.toLowerCase();
    let qi = 0, score = 0, streak = 0, prevIdx = -1;
    for (let ti = 0; ti < t.length && qi < q.length; ti++) {
      if (t[ti] === q[qi]) {
        score += 10;
        if (prevIdx === ti - 1) { streak++; score += streak * 5; }
        else streak = 0;
        // бонус за начало слова
        if (ti === 0 || t[ti - 1] === ' ' || t[ti - 1] === '›') score += 8;
        prevIdx = ti;
        qi++;
      }
    }
    if (qi < q.length) return -1;           // не все символы запроса найдены
    score -= (t.length - q.length) * 0.1;   // короче совпадение — чуть выше
    return score;
  }

  createApp({
    setup() {
      const query = ref('');
      const items = ref([]);
      const mode = ref('run');     // 'run' | 'settings'
      const selected = ref(0);
      const error = ref('');
      const searchInput = ref(null);
      const launcherKey = ref('');   // горячая клавиша вызова лаунчера (для подвала)

      function applySnapshot(snap) {
        items.value = (snap && snap.items) ? snap.items : [];
        if (snap && snap.launcherKey) launcherKey.value = snap.launcherKey;
      }

      async function load() {
        try {
          applySnapshot(await ahk.call('getData'));
        } catch (e) {
          error.value = String(e);
        }
      }

      // Отфильтрованный и отсортированный список.
      const filtered = computed(() => {
        const q = query.value.trim();
        let list;
        if (!q) {
          list = items.value.map(it => ({ it, score: 0 }));
        } else {
          list = [];
          for (const it of items.value) {
            const s = fuzzyScore(q, it.label + ' ' + (it.group || ''));
            if (s >= 0) list.push({ it, score: s });
          }
          list.sort((a, b) => b.score - a.score);
        }
        return list.map(x => x.it);
      });

      function clampSelected() {
        if (selected.value >= filtered.value.length) selected.value = filtered.value.length - 1;
        if (selected.value < 0) selected.value = 0;
      }

      async function runItem(it) {
        if (!it) return;
        try { await ahk.call('run', { id: it.id }); } catch (e) { error.value = String(e); }
      }

      async function toggleItem(it) {
        if (it.kind === 'menuitem') return;       // пункты меню не отключаются
        try {
          applySnapshot(await ahk.call('toggle', { id: it.id, value: !it.enabled }));
        } catch (e) { error.value = String(e); }
      }

      function onKeydown(e) {
        if (e.key === 'Escape') { ahk.call('hide', {}); return; }
        if (e.key === 'ArrowDown') { selected.value++; clampSelected(); e.preventDefault(); scrollToSel(); }
        else if (e.key === 'ArrowUp') { selected.value--; clampSelected(); e.preventDefault(); scrollToSel(); }
        else if (e.key === 'Enter') {
          const it = filtered.value[selected.value];
          if (mode.value === 'run') runItem(it);
          else toggleItem(it);
          e.preventDefault();
        }
      }

      function scrollToSel() {
        nextTick(() => {
          const el = document.querySelector('.row--sel');
          if (el) el.scrollIntoView({ block: 'nearest' });
        });
      }

      function toggleMode() {
        mode.value = mode.value === 'run' ? 'settings' : 'run';
      }

      // Сбрасываем выбор при изменении фильтра.
      function onInput() { selected.value = 0; }

      // Перезагрузка данных при повторном показе окна (push 'init' из AHK).
      ahk.onPush((msg) => {
        if (msg.channel === 'init') {
          query.value = '';
          selected.value = 0;
          load();
          nextTick(() => { if (searchInput.value) searchInput.value.focus(); });
        }
      });

      onMounted(async () => {
        await load();
        nextTick(() => { if (searchInput.value) searchInput.value.focus(); });
      });

      function rowChecked(it) { return it.enabled && it.groupOn; }

      return {
        query, items, mode, selected, error, searchInput, launcherKey,
        filtered, runItem, toggleItem, toggleMode, onKeydown, onInput, rowChecked
      };
    },

    template: `
      <div class="launcher" :class="'launcher--' + mode">
        <div class="search">
          <span class="search__icon">🔍</span>
          <input
            ref="searchInput"
            class="search__input"
            v-model="query"
            @input="onInput"
            @keydown="onKeydown"
            :placeholder="mode === 'run' ? 'Поиск команды…' : 'Поиск для настройки…'"
            spellcheck="false"
          >
        </div>

        <p v-if="error" class="launcher__error">{{ error }}</p>

        <ul class="rows">
          <li
            v-for="(it, i) in filtered"
            :key="it.id"
            class="row"
            :class="{ 'row--sel': i === selected, 'row--off': mode==='settings' && !rowChecked(it) }"
            @mouseenter="selected = i"
            @click="mode === 'run' ? runItem(it) : toggleItem(it)"
          >
            <input
              v-if="mode === 'settings'"
              class="row__check"
              type="checkbox"
              :checked="rowChecked(it)"
              :disabled="it.kind === 'menuitem'"
              @click.stop="toggleItem(it)"
            >
            <span class="row__label">{{ it.label }}</span>
            <span class="row__group">{{ it.group }}</span>
            <kbd v-if="it.key" class="row__key">{{ it.key }}</kbd>
          </li>
          <li v-if="filtered.length === 0" class="rows__empty">Ничего не найдено</li>
        </ul>

        <div class="footer">
          <span class="footer__hint">
            {{ mode === 'run' ? 'Enter — запустить · Esc — скрыть' : 'Галочка — вкл/выкл · Esc — скрыть' }}
          </span>
          <span v-if="launcherKey" class="footer__call">
            Вызов: <kbd class="footer__key">{{ launcherKey }}</kbd>
          </span>
          <button class="gear" :class="{ 'gear--on': mode === 'settings' }" @click="toggleMode" title="Настройки">⚙</button>
        </div>
      </div>
    `
  }).mount('#app');
})();
