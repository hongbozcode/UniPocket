'use strict';
(() => {
  const data = JSON.parse(document.getElementById('handbook-data').textContent);
  const $ = selector => document.querySelector(selector);
  const all = selector => [...document.querySelectorAll(selector)];
  const viewer = $('#viewer');
  const escape = value => String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  let pageFilter = 'all', assetFilter = 'all', toastTimer, disposeDemo;

  function notify(text) {
    $('#toast').textContent = text;
    $('#toast').classList.add('visible');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => $('#toast').classList.remove('visible'), 2300);
  }

  function filter(which) {
    const pages = which === 'page';
    const search = $(`#${which}-search`).value.trim().toLocaleLowerCase();
    const selected = pages ? pageFilter : assetFilter;
    let count = 0;
    all(pages ? '.page-card' : '.asset-card').forEach(card => {
      const matches = (selected === 'all' || card.dataset[pages ? 'group' : 'kind'] === selected) && card.dataset.search.toLocaleLowerCase().includes(search);
      card.hidden = !matches;
      if (matches) count++;
    });
    $(`#${which}-count`).textContent = `显示 ${count} 个${pages ? '页面' : '素材'}`;
    $(`#${which}-empty`).hidden = count !== 0;
  }

  function show(title, content) {
    disposeDemo?.();
    disposeDemo = null;
    viewer.classList.remove('motion-viewer');
    $('#viewer-title').textContent = title;
    $('#viewer-content').innerHTML = content;
    if (!viewer.open) viewer.showModal();
    viewer.scrollTop = 0;
    $('#viewer-close').focus();
  }

  function comparison(id) {
    const page = data.pages.find(p => p.id === id);
    const ref = data.references[page.ref];
    show(`${page.name} · 图稿与运行截图`, `<div class="comparison"><figure><figcaption>当前效果图${ref.id.startsWith('core-') && ref.id !== 'core-settings' ? ' · 双页组合' : ''}</figcaption><img src="${escape(ref.url)}" alt="${escape(ref.name)}效果图" data-zoom="${escape(ref.url)}" data-title="${escape(ref.name)}"></figure><figure><figcaption>${escape(page.shotLabel)} · 采集时状态</figcaption><img src="${escape(page.shotUrl)}" alt="${escape(page.name)} ${escape(page.shotLabel)}截图" data-zoom="${escape(page.shotUrl)}" data-title="${escape(page.name)} ${escape(page.shotLabel)}截图"></figure></div><div class="viewer-actions">${page.demoUrl ? `<button data-demo="${id}">播放动效</button>` : ''}<a href="${escape(ref.url)}" target="_blank" rel="noopener">效果图原图 ↗</a><a href="${escape(page.shotUrl)}" target="_blank" rel="noopener">截图原图 ↗</a></div><div class="page-guidance"><p><strong>内容顺序：</strong>${escape(page.content)}</p><p><strong>${escape(page.actionsLabel)}：</strong>${escape(page.actions)}</p>${page.demoUrl ? '' : '<p>原完整应用样板源码未纳入仓库，所列操作仅作历史记录，当前无法运行复核。</p>'}<p><strong>应用待补设计：</strong>${escape(page.pending)}</p></div>`);
  }

  document.addEventListener('click', async event => {
    const pageButton = event.target.closest('[data-page-filter]');
    const assetButton = event.target.closest('[data-asset-filter]');
    const compare = event.target.closest('[data-compare]');
    const demo = event.target.closest('[data-demo]');
    const zoom = event.target.closest('[data-zoom]');
    const copy = event.target.closest('[data-copy]');
    if (pageButton || assetButton) {
      const which = pageButton ? 'page' : 'asset';
      const button = pageButton || assetButton;
      if (pageButton) pageFilter = button.dataset.pageFilter;
      else assetFilter = button.dataset.assetFilter;
      all(`[data-${which}-filter]`).forEach(el => {
        const active = el === button;
        el.classList.toggle('active', active);
        el.setAttribute('aria-pressed', String(active));
      });
      filter(which);
    } else if (compare) comparison(compare.dataset.compare);
    else if (demo) {
      const page = data.pages.find(p => p.id === demo.dataset.demo);
      show(`${page.name} · 交互动效`, `<div id="motion-demo-host"></div><div class="viewer-actions"><a href="${escape(page.demoUrl)}" target="_blank" rel="noopener">独立打开样板 ↗</a></div>`);
      viewer.classList.add('motion-viewer');
      disposeDemo = window.mountMotionDemo($('#motion-demo-host'), page.id);
    } else if (zoom) show(zoom.dataset.title || '原图预览', `<img class="zoom-image" src="${escape(zoom.dataset.zoom)}" alt="${escape(zoom.dataset.title || '放大图')}">`);
    else if (copy) {
      try { await navigator.clipboard.writeText(copy.dataset.copy); notify(`已复制 ${copy.dataset.copy}`); }
      catch { notify(`色值：${copy.dataset.copy}（可手动选择复制）`); }
    }
  });
  $('#page-search').addEventListener('input', () => filter('page'));
  $('#asset-search').addEventListener('input', () => filter('asset'));
  $('#viewer-close').addEventListener('click', () => viewer.close());
  viewer.addEventListener('click', event => { if (event.target === viewer) { const r = viewer.getBoundingClientRect(); if (event.clientX < r.left || event.clientX > r.right || event.clientY < r.top || event.clientY > r.bottom) viewer.close(); } });
  viewer.addEventListener('close', () => { disposeDemo?.(); disposeDemo = null; $('#viewer-content').replaceChildren(); });
  const nav = all('.sidebar nav a');
  if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver(entries => {
      const visible = entries.filter(entry => entry.isIntersecting).sort((a,b) => b.intersectionRatio - a.intersectionRatio)[0];
      if (!visible) return;
      nav.forEach(a => { const active = a.hash === '#' + visible.target.id; a.classList.toggle('active', active); if (active) a.setAttribute('aria-current', 'location'); else a.removeAttribute('aria-current'); });
    }, {rootMargin:'-5% 0px -55% 0px', threshold:0});
    all('.chapter').forEach(section => observer.observe(section));
  }
})();
